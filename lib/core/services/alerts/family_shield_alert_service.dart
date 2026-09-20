import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../features/forensics/domain/models/incident_report.dart';
import 'family_alert_service.dart';

/// Family Shield broadcast client.
///
/// **Security boundary:** the OneSignal REST API key must live on a
/// server-side relay — never inside the Flutter client. This service
/// POSTs a compact alert request to a minimal backend/edge endpoint
/// (`--dart-define=VOXGUARD_ALERT_RELAY_URL=https://…`), which owns the
/// OneSignal credentials and fans the notification out to family
/// `external_id` aliases.
///
/// Without a configured relay the service runs in explicit **Demo
/// Mode**: the payload is built and logged identically but never
/// leaves the device, so the full Family Shield journey stays
/// demoable for judging without shipping secrets.
final class FamilyShieldAlertService implements IFamilyAlertService {
  FamilyShieldAlertService({http.Client? httpClient, String? relayUrl})
      : _client = httpClient ?? http.Client(),
        _relayUrl = relayUrl ??
            const String.fromEnvironment(
              'VOXGUARD_ALERT_RELAY_URL',
              defaultValue: '',
            );

  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String _relayUrl;

  final ValueNotifier<bool> _enabled = ValueNotifier<bool>(true);

  /// Whether a real relay endpoint is configured. When false the
  /// service simulates broadcasts instead of hitting the network.
  bool get isRelayConfigured => _relayUrl.isNotEmpty;

  @override
  ValueListenable<bool> get isFamilyShieldEnabled => _enabled;

  @override
  bool get isDemoMode => !isRelayConfigured;

  @override
  void toggleFamilyShield(bool enabled) => _enabled.value = enabled;

  @override
  Future<AlertDispatchResult> triggerFamilyEmergencyAlert({
    required IncidentReport incident,
    required List<String> familyMemberIds,
  }) async {
    if (!_enabled.value) {
      return const AlertDispatchResult(
        delivered: false,
        simulated: false,
        detail: 'Family Shield is disabled.',
      );
    }

    final payload = _buildPayload(incident, familyMemberIds);

    if (!isRelayConfigured) {
      // Demo Mode broadcast — deterministic, offline-safe.
      debugPrint('[FamilyShield·demo] ${jsonEncode(payload)}');
      return AlertDispatchResult(
        delivered: true,
        simulated: true,
        detail:
            'Demo alert broadcast to ${familyMemberIds.length} family member(s).',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_relayUrl),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 202) {
        return AlertDispatchResult(
          delivered: true,
          simulated: false,
          detail:
              'Alert sent to ${familyMemberIds.length} family member(s).',
        );
      }
      return AlertDispatchResult(
        delivered: false,
        simulated: false,
        detail: 'Relay error ${response.statusCode}.',
      );
    } on Exception {
      return const AlertDispatchResult(
        delivered: false,
        simulated: false,
        detail: 'Network error — alert could not be sent.',
      );
    }
  }

  /// Compact, privacy-minimal alert request the relay fans out via
  /// OneSignal. Contains no user audio, transcript, or credentials —
  /// just the incident reference and target aliases.
  Map<String, Object?> _buildPayload(
    IncidentReport incident,
    List<String> familyMemberIds,
  ) {
    return {
      'kind': 'family_shield_alert',
      'incident_id': incident.id,
      'risk_level': incident.riskLevel.name,
      'family_external_ids': familyMemberIds,
      'title': '🚨 VoxGuard Family Shield Alert',
      'body': 'A high-risk call was flagged on a protected device. '
          'Verify directly with your relative before any funds move.',
    };
  }
}

/// Process-wide accessor for the alert service.
final class FamilyAlertLocator {
  FamilyAlertLocator._();

  static IFamilyAlertService? _instance;

  static IFamilyAlertService get instance =>
      _instance ??= FamilyShieldAlertService();

  @visibleForTesting
  static set instance(IFamilyAlertService service) => _instance = service;
}
