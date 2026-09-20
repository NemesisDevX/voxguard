import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:voxguard/core/services/alerts/family_alert_service.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/alerts/family_shield_alert_service.dart';
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
    audioDigestSha256: 'ff' * 32,
    audioSourceLabel: 'Generated Demo Audio',
    transcriptionSourceLabel: 'Local Demo Transcript',
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

  const members = ['demo_family_maya', 'demo_family_omar'];

  group('FamilyShieldAlertService', () {
    test('runs in Demo Mode when no relay is configured', () async {
      final service = FamilyShieldAlertService(relayUrl: '');
      expect(service.isRelayConfigured, isFalse);
      expect(service.isDemoMode, isTrue);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isTrue);
      expect(result.simulated, isTrue);
      expect(result.detail, contains('Demo'));
    });

    test('does not send when Family Shield is disabled', () async {
      final service = FamilyShieldAlertService(relayUrl: '');
      service.toggleFamilyShield(false);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isFalse);
      expect(service.isFamilyShieldEnabled.value, isFalse);
    });

    test('posts a privacy-minimal payload to the relay endpoint', () async {
      http.Request? captured;
      final client = http_testing.MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 202);
      });
      final service = FamilyShieldAlertService(
        httpClient: client,
        relayUrl: 'https://relay.example.com/alert',
      );
      expect(service.isRelayConfigured, isTrue);
      expect(service.isDemoMode, isFalse);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isTrue);
      expect(result.simulated, isFalse);

      expect(captured, isNotNull);
      expect(captured!.url.toString(), 'https://relay.example.com/alert');
      // No relay token configured → no auth header. The OneSignal
      // REST key is never present client-side regardless.
      expect(captured!.headers.containsKey('Authorization'), isFalse);

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['kind'], 'family_shield_alert');
      expect(body['family_external_ids'], members);
      expect(body['incident_id'], 'INC-2026-9001');
      expect(body['risk_level'], 'highRisk');
      // No transcript or audio data leaves the device.
      expect(body.containsKey('transcript'), isFalse);
    });

    test('reports failure on non-2xx responses', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response('{"errors":["bad request"]}', 400),
      );
      final service = FamilyShieldAlertService(
        httpClient: client,
        relayUrl: 'https://relay.example.com/alert',
      );

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.delivered, isFalse);
      expect(result.simulated, isFalse);
      expect(result.status, AlertDispatchStatus.rejected);
    });

    test('sends the shared relay token as Bearer auth when configured',
        () async {
      http.Request? captured;
      final client = http_testing.MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 202);
      });
      final service = FamilyShieldAlertService(
        httpClient: client,
        relayUrl: 'https://relay.example.com/alert',
        relayToken: 'relay-tok',
      );

      await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(captured!.headers['Authorization'], 'Bearer relay-tok');
      // Still no provider secret — the OneSignal key is server-side.
      expect(captured!.body.contains('onesignal'), isFalse);
    });

    test('distinguishes rejected vs unavailable relay outcomes',
        () async {
      final rejected = FamilyShieldAlertService(
        httpClient: http_testing.MockClient(
          (_) async => http.Response('{}', 401),
        ),
        relayUrl: 'https://relay.example.com/alert',
      );
      final unavailable = FamilyShieldAlertService(
        httpClient: http_testing.MockClient(
          (_) async => http.Response('{}', 502),
        ),
        relayUrl: 'https://relay.example.com/alert',
      );

      final r1 = await rejected.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );
      final r2 = await unavailable.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(r1.status, AlertDispatchStatus.rejected);
      expect(r2.status, AlertDispatchStatus.unavailable);
    });
  });

  group('DemoFamilyContactRepository', () {
    test('returns explicitly-labelled demo contacts', () async {
      final contacts =
          await const DemoFamilyContactRepository().getFamilyContacts();

      expect(contacts, isNotEmpty);
      for (final c in contacts) {
        expect(c.name, contains('Demo'));
        expect(c.externalId, startsWith('demo_family_'));
      }
    });
  });
}
