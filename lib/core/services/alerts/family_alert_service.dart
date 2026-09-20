import 'package:flutter/foundation.dart';

import '../../../features/forensics/domain/models/incident_report.dart';

/// Coarse outcome of a family-shield broadcast attempt — what the UI
/// may truthfully tell the user.
enum AlertDispatchStatus {
  /// Relay + OneSignal API accepted the alert for delivery. This is
  /// NOT confirmed receipt — a device actually displaying the push is
  /// only observable on the receiving device.
  accepted,

  /// Explicit Demo Mode — nothing left the device.
  simulated,

  /// The relay rejected the request (bad auth or payload).
  rejected,

  /// Relay unreachable, upstream failed, or network error.
  unavailable,

  /// Family Shield is toggled off — nothing attempted.
  disabled,

  /// Real relay configured but the Trusted Circle is empty — nothing
  /// was sent and nothing should pretend otherwise.
  noRecipients,
}

/// Outcome of a family-shield broadcast attempt.
final class AlertDispatchResult {
  const AlertDispatchResult({
    required this.status,
    required this.detail,
  });

  /// The broadcast pipeline attempted the dispatch — the relay
  /// accepted it, or Demo Mode simulated it. This is NOT confirmed
  /// delivery: no signal here proves a device received the push.
  bool get attempted =>
      status == AlertDispatchStatus.accepted ||
      status == AlertDispatchStatus.simulated;

  /// True when the broadcast ran in simulated mode (no relay).
  bool get simulated => status == AlertDispatchStatus.simulated;

  /// Human-readable detail for UI feedback.
  final String detail;
  final AlertDispatchStatus status;
}

/// Contract for the Family Shield emergency broadcast pipeline.
///
/// `FamilyShieldAlertService` posts alert requests to a server-side
/// relay that owns the OneSignal credentials; the same interface could
/// later back FCM topics, SMS gateways, etc.
abstract interface class IFamilyAlertService {
  /// Whether family broadcasts are armed. Family members only get
  /// alerts while this is on.
  ValueListenable<bool> get isFamilyShieldEnabled;

  /// True when no production relay is configured and broadcasts run
  /// as explicit Demo Mode simulations.
  bool get isDemoMode;

  /// Arms/disarms the broadcast pipeline.
  void toggleFamilyShield(bool enabled);

  /// Sends an emergency alert to [familyMemberIds] about [incident].
  Future<AlertDispatchResult> triggerFamilyEmergencyAlert({
    required IncidentReport incident,
    required List<String> familyMemberIds,
  });
}
