import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:voxguard/core/services/alerts/onesignal_alert_service.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';

void main() {
  final incident = IncidentReport(
    id: 'INC-2026-9001',
    timestamp: DateTime(2026, 9, 20),
    callerLabel: 'Unknown Caller',
    callDurationSeconds: 120,
    audioSha256: 'ff' * 32,
    peakRiskScore: 0.95,
    riskLevel: ThreatRiskLevel.highRisk,
    threatReasons: const ['Financial transfer demand detected'],
    acousticMetrics: const AudioForensicMetrics(
      spectralFlux: 0.05,
      spectralRolloffRatio: 0.08,
      zeroCrossingRate: 0.03,
      syntheticVoiceScore: 0.8,
    ),
    semanticSignals: const SemanticThreatSignals.empty(),
    transcriptSnippets: const [],
    recommendedActions: const ['End the call immediately'],
  );

  const members = ['family_member_1', 'family_member_2'];

  group('OneSignalAlertService', () {
    test('simulates broadcast when no credentials are configured', () async {
      final service = OneSignalAlertService(appId: '', apiKey: '');
      expect(service.isRemoteConfigured, isFalse);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isTrue);
      expect(result.simulated, isTrue);
    });

    test('does not send when Family Shield is disabled', () async {
      final service = OneSignalAlertService(appId: '', apiKey: '');
      service.toggleFamilyShield(false);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isFalse);
      expect(service.isFamilyShieldEnabled.value, isFalse);
    });

    test('posts a well-formed payload to the OneSignal REST API', () async {
      http.Request? captured;
      final client = http_testing.MockClient((request) async {
        captured = request;
        return http.Response('{"id":"notif-1"}', 200);
      });
      final service = OneSignalAlertService(
        httpClient: client,
        appId: 'test-app-id',
        apiKey: 'test-rest-key',
      );
      expect(service.isRemoteConfigured, isTrue);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isTrue);
      expect(result.simulated, isFalse);

      expect(captured, isNotNull);
      expect(captured!.url.toString(), 'https://api.onesignal.com/notifications');
      expect(captured!.headers['Authorization'], 'Basic test-rest-key');

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['app_id'], 'test-app-id');
      expect(
        (body['include_aliases'] as Map)['external_id'],
        members,
      );
      expect(
        (body['data'] as Map)['incident_id'],
        'INC-2026-9001',
      );
      expect(
        (body['headings'] as Map)['en'],
        '🚨 VoxGuard Family Shield Alert',
      );
    });

    test('reports failure on non-200 responses', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response('{"errors":["bad request"]}', 400),
      );
      final service = OneSignalAlertService(
        httpClient: client,
        appId: 'test-app-id',
        apiKey: 'test-rest-key',
      );

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isFalse);
      expect(result.simulated, isFalse);
    });
  });
}
