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

/// Minimal metadata captured when a Family Shield notification is
/// tapped. Routing data only — never the full payload.
final class FamilyAlertTap {
  const FamilyAlertTap({
    required this.incidentId,
    required this.riskLevel,
  });

  final String? incidentId;
  final String? riskLevel;

  /// Parses a notification's `additionalData`; returns null for
  /// unrelated payloads so callers can ignore them safely.
  static FamilyAlertTap? fromAdditionalData(Map<String, dynamic>? data) {
    if (data == null || data['kind'] != 'family_shield_alert') {
      return null;
    }
    return FamilyAlertTap(
      incidentId: data['incident_id'] as String?,
      riskLevel: data['risk_level'] as String?,
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

  /// Notification taps carrying Family Shield metadata.
  Stream<FamilyAlertTap> get alertTaps;

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
