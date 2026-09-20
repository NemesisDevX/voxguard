import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../features/forensics/domain/models/incident_report.dart';
import 'family_alert_service.dart';

/// Family Shield broadcast backed by the OneSignal REST API.
///
/// Pure Dart/`http` — identical behaviour on Android, iOS and Web.
///
/// Credentials are injected at build time:
/// `--dart-define=ONESIGNAL_APP_ID=... --dart-define=ONESIGNAL_API_KEY=...`
///
/// Without credentials the service automatically runs in *simulated
/// mode*: payloads are built and logged identically but never leave the
/// device — the full Family Shield lifecycle stays demoable offline.
final class OneSignalAlertService implements IFamilyAlertService {
  OneSignalAlertService({http.Client? httpClient, String? appId, String? apiKey})
      : _client = httpClient ?? http.Client(),
        _appId = appId ??
            const String.fromEnvironment('ONESIGNAL_APP_ID', defaultValue: ''),
        _apiKey = apiKey ??
            const String.fromEnvironment('ONESIGNAL_API_KEY', defaultValue: '');

  static const _endpoint = 'https://api.onesignal.com/notifications';
  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String _appId;
  final String _apiKey;

  final ValueNotifier<bool> _enabled = ValueNotifier<bool>(true);

  /// Whether real OneSignal credentials are configured. When false the
  /// service simulates broadcasts instead of hitting the network.
  bool get isRemoteConfigured => _appId.isNotEmpty && _apiKey.isNotEmpty;

  @override
  ValueListenable<bool> get isFamilyShieldEnabled => _enabled;

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

    if (!isRemoteConfigured) {
      // Simulated broadcast — deterministic, offline-safe.
      debugPrint(
        '[FamilyShield·simulated] ${jsonEncode(payload)}',
      );
      return AlertDispatchResult(
        delivered: true,
        simulated: true,
        detail:
            'Simulated broadcast to ${familyMemberIds.length} family member(s).',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Basic $_apiKey',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return AlertDispatchResult(
          delivered: true,
          simulated: false,
          detail:
              'Alert broadcast to ${familyMemberIds.length} family member(s).',
        );
      }
      return AlertDispatchResult(
        delivered: false,
        simulated: false,
        detail: 'OneSignal error ${response.statusCode}.',
      );
    } on Exception {
      return const AlertDispatchResult(
        delivered: false,
        simulated: false,
        detail: 'Network error — alert could not be sent.',
      );
    }
  }

  /// OneSignal REST payload targeting tagged family segments by
  /// `external_id` alias.
  Map<String, Object?> _buildPayload(
    IncidentReport incident,
    List<String> familyMemberIds,
  ) {
    return {
      'app_id': _appId,
      'target_channel': 'push',
      'include_aliases': {'external_id': familyMemberIds},
      'headings': {'en': '🚨 VoxGuard Family Shield Alert'},
      'contents': {
        'en': "Potential scam call intercepted on Abdo's device. "
            'Financial transfer & impersonation pattern detected. '
            'Verify directly before sending funds.',
      },
      'data': {
        'incident_id': incident.id,
        'risk_level': incident.riskLevel.name,
      },
    };
  }
}

/// Process-wide accessor for the alert service.
final class FamilyAlertLocator {
  FamilyAlertLocator._();

  static IFamilyAlertService? _instance;

  static IFamilyAlertService get instance =>
      _instance ??= OneSignalAlertService();

  @visibleForTesting
  static set instance(IFamilyAlertService service) => _instance = service;
}
