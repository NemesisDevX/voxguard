import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lifecycle of this device's Family Shield push registration.
enum PushRegistrationStatus {
  /// No `ONESIGNAL_APP_ID` configured — receiver setup unavailable.
  notConfigured,

  /// Platform cannot receive OneSignal push (e.g. web demo).
  unsupported,

  /// Configured but the user has not granted/requested permission.
  permissionRequired,

  /// A permission request / SDK registration is in flight.
  registering,

  /// Permission granted, External ID linked, subscription live.
  registered,

  /// The user declined — or can no longer be prompted.
  permissionDenied,

  /// SDK/registration failure.
  error,
}

/// Truthful, non-sensitive snapshot of this device's push
/// registration. Never contains the raw FCM/APNs token.
final class FamilyPushRegistration {
  const FamilyPushRegistration({
    required this.status,
    this.voxguardExternalId,
    this.pushSubscriptionId,
    this.optedIn = false,
    this.errorDetail,
  });

  final PushRegistrationStatus status;

  /// The opaque `vg_…` identity the relay targets via
  /// `include_aliases.external_id`. Not an account — a locally
  /// generated identifier.
  final String? voxguardExternalId;

  /// OneSignal push subscription ID (diagnostic — NOT the raw push
  /// token, which is never surfaced).
  final String? pushSubscriptionId;

  /// Whether the device is currently opted in to push.
  final bool optedIn;

  final String? errorDetail;
}

/// Minimal metadata extracted from a Family Shield notification —
/// routing data only, never the full payload. Used for both taps
/// ([IPushIdentityService.alertTaps]) and foreground arrivals
/// ([IPushIdentityService.alertReceived]).
final class FamilyAlertTap {
  const FamilyAlertTap({
    required this.incidentId,
    required this.riskLevel,
    required this.senderExternalId,
  });

  final String incidentId;
  final String riskLevel;

  /// The sender's opaque `vg_…` identity — which trusted contact
  /// raised the alert. P0.2C uses this for the resolution screen.
  final String senderExternalId;

  /// Risk bands shared with the relay contract — anything else is
  /// not a routable Family Shield event.
  static const _validRiskLevels = {'safe', 'suspicious', 'highRisk'};

  static final _externalIdPattern = RegExp(r'^vg_[0-9a-f]{32}$');

  /// Parses a notification's `additionalData`; returns null unless
  /// ALL required routing metadata is valid — kind, a non-empty
  /// string incident id, a recognized risk level, and a well-formed
  /// `vg_…` sender identity. Malformed or unrelated payloads produce
  /// no event and never throw.
  static FamilyAlertTap? fromAdditionalData(Map<String, dynamic>? data) {
    if (data == null || data['kind'] != 'family_shield_alert') {
      return null;
    }
    final incidentId = data['incident_id'];
    final riskLevel = data['risk_level'];
    final sender = data['sender_external_id'];
    if (incidentId is! String || incidentId.isEmpty) return null;
    if (riskLevel is! String || !_validRiskLevels.contains(riskLevel)) {
      return null;
    }
    if (sender is! String || !_externalIdPattern.hasMatch(sender)) {
      return null;
    }
    return FamilyAlertTap(
      incidentId: incidentId,
      riskLevel: riskLevel,
      senderExternalId: sender,
    );
  }
}

/// VoxGuard-owned abstraction over the push provider (OneSignal).
///
/// Keeps three distinct identifiers un-confused:
///  - **VoxGuard External ID** (`vg_…`): our opaque, locally generated
///    family identity — what the relay targets.
///  - **OneSignal push subscription ID**: the provider's routing handle
///    for this device's push channel.
///  - **Raw FCM/APNs token**: provider internals — never exposed.
abstract interface class IPushIdentityService {
  /// Live registration state — drives the receiver card.
  ValueListenable<FamilyPushRegistration> get registration;

  /// Notification taps carrying Family Shield metadata — user
  /// interaction only. P0.2C deep-link navigation must hook this
  /// stream, never [alertReceived].
  Stream<FamilyAlertTap> get alertTaps;

  /// Family Shield notifications received while the app was in the
  /// foreground. Diagnostics/state only — receiving a notification is
  /// NOT a user interaction and must never trigger navigation.
  Stream<FamilyAlertTap> get alertReceived;

  /// This device's `vg_…` identity (created on first use, persisted).
  /// Available even when push itself isn't configured.
  Future<String> voxGuardIdentity();

  /// Initializes the SDK if configured. Safe to call with no App ID —
  /// resolves to `notConfigured` instead of crashing.
  Future<void> initialize();

  /// User-intentional enable flow: requests notification permission,
  /// then links the VoxGuard External ID via `OneSignal.login`.
  Future<void> enableAlerts();

  /// Regenerates the `vg_…` identity (testing/debug path).
  Future<void> resetIdentity();
}
