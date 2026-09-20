import 'package:flutter/foundation.dart';

import '../../../features/forensics/domain/models/incident_report.dart';

/// Outcome of a family-shield broadcast attempt.
final class AlertDispatchResult {
  const AlertDispatchResult({
    required this.delivered,
    required this.simulated,
    required this.detail,
  });

  /// Dispatch accepted (real API call or simulated broadcast).
  final bool delivered;

  /// True when the broadcast ran in simulated mode (no credentials).
  final bool simulated;

  /// Human-readable detail for UI feedback.
  final String detail;
}

/// Contract for the Family Shield emergency broadcast pipeline.
///
/// `OneSignalAlertService` targets the OneSignal REST API; the same
/// interface could later back FCM topics, SMS gateways, etc.
abstract interface class IFamilyAlertService {
  /// Whether family broadcasts are armed. Family members only get
  /// alerts while this is on.
  ValueListenable<bool> get isFamilyShieldEnabled;

  /// Arms/disarms the broadcast pipeline.
  void toggleFamilyShield(bool enabled);

  /// Sends an emergency alert to [familyMemberIds] about [incident].
  Future<AlertDispatchResult> triggerFamilyEmergencyAlert({
    required IncidentReport incident,
    required List<String> familyMemberIds,
  });
}
