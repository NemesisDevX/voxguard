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
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'helpers/fake_product_access.dart';

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

  /// Real-mode recipients must be `vg_…` identities — the relay and
  /// client both reject anything else.
  final members = ['vg_${'1' * 32}', 'vg_${'2' * 32}'];

  /// Injectable sender identity — tests never touch the real
  /// OneSignal locator.
  Future<String> testSender() async => 'vg_${'0' * 32}';

  group('FamilyShieldAlertService', () {
    test('runs in Demo Mode when no relay is configured', () async {
      final service = FamilyShieldAlertService(relayUrl: '', senderIdentity: testSender);
      expect(service.isRelayConfigured, isFalse);
      expect(service.isDemoMode, isTrue);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.attempted, isTrue);
      expect(result.simulated, isTrue);
      expect(result.detail, contains('Demo'));
    });

    test('does not send when Family Shield is disabled', () async {
      final service = FamilyShieldAlertService(relayUrl: '', senderIdentity: testSender);
      service.toggleFamilyShield(false);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.attempted, isFalse);
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
        senderIdentity: testSender,
        productAccess: FakeProductAccess(TierId.familyVault),
      );
      expect(service.isRelayConfigured, isTrue);
      expect(service.isDemoMode, isFalse);

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.attempted, isTrue);
      expect(result.simulated, isFalse);

      expect(captured, isNotNull);
      expect(captured!.url.toString(), 'https://relay.example.com/alert');
      // No relay token configured → no auth header. The OneSignal
      // REST key is never present client-side regardless.
      expect(captured!.headers.containsKey('Authorization'), isFalse);

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['kind'], 'family_shield_alert');
      expect(body['family_external_ids'], members);
      expect(body['sender_external_id'], 'vg_${'0' * 32}');
      // Names/phones never cross the boundary — only opaque ids.
      expect(body.containsKey('sender_name'), isFalse);
      expect(body.containsKey('phone'), isFalse);
      expect(body['incident_id'], 'INC-2026-9001');
      expect(body['risk_level'], 'highRisk');
      // Full fused analysis → 'full' scope for receiver copy.
      expect(body['analysis_scope'], 'full');
      // No transcript or audio data leaves the device.
      expect(body.containsKey('transcript'), isFalse);
    });

    test('partial incident sends analysis_scope partial + honest body',
        () async {
      http.Request? captured;
      final client = http_testing.MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 202);
      });
      final service = FamilyShieldAlertService(
        httpClient: client,
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: testSender,
        productAccess: FakeProductAccess(TierId.familyVault),
      );
      // An acoustic-only uploaded recording — persisted as partial.
      final partial = IncidentReport(
        id: 'INC-2026-9002',
        timestamp: DateTime(2026, 9, 20),
        callerLabel: 'Uploaded Recording',
        callDurationSeconds: 40,
        audioDigestSha256: 'aa' * 32,
        audioSourceLabel: 'Uploaded Recording',
        transcriptionSourceLabel: 'None — acoustic analysis only',
        peakRiskScore: 0.8,
        riskLevel: ThreatRiskLevel.suspicious,
        threatReasons: const ['Elevated acoustic anomalies'],
        acousticMetrics: const AudioForensicMetrics(
          spectralFlux: 0.05,
          spectralRolloffRatio: 0.08,
          zeroCrossingRate: 0.03,
          syntheticVoiceScore: 0.8,
        ),
        semanticSignals: const SemanticThreatSignals.empty(),
        transcriptSnippets: const [],
        recommendedActions: const ['Verify the speaker'],
        analysisIsPartial: true,
      );
      await service.triggerFamilyEmergencyAlert(
        incident: partial,
        familyMemberIds: members,
      );
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['analysis_scope'], 'partial');
      expect(body['risk_level'], 'suspicious');
      // Partial evidence is described as an acoustic warning — never
      // a "high-risk call".
      expect(body['body'] as String, contains('acoustic'));
      expect(body['body'] as String, isNot(contains('high-risk call')));
    });

    test('suspicious full incident uses suspicious-call wording',
        () async {
      http.Request? captured;
      final client = http_testing.MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 202);
      });
      final service = FamilyShieldAlertService(
        httpClient: client,
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: testSender,
        productAccess: FakeProductAccess(TierId.familyVault),
      );
      final suspicious = IncidentReport(
        id: 'INC-2026-9003',
        timestamp: DateTime(2026, 9, 20),
        callerLabel: 'Unknown Caller',
        callDurationSeconds: 60,
        audioDigestSha256: 'bb' * 32,
        audioSourceLabel: 'Live Microphone',
        transcriptionSourceLabel: 'AssemblyAI Streaming',
        peakRiskScore: 0.6,
        riskLevel: ThreatRiskLevel.suspicious,
        threatReasons: const ['Urgency cues detected'],
        acousticMetrics: const AudioForensicMetrics(
          spectralFlux: 0.05,
          spectralRolloffRatio: 0.08,
          zeroCrossingRate: 0.03,
          syntheticVoiceScore: 0.4,
        ),
        semanticSignals: const SemanticThreatSignals.empty(),
        transcriptSnippets: const [],
        recommendedActions: const ['Verify the caller'],
      );
      await service.triggerFamilyEmergencyAlert(
        incident: suspicious,
        familyMemberIds: members,
      );
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['analysis_scope'], 'full');
      expect(body['body'] as String, contains('suspicious-call'));
      expect(body['body'] as String, isNot(contains('high-risk')));
    });

    test('reports failure on non-2xx responses', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response('{"errors":["bad request"]}', 400),
      );
      final service = FamilyShieldAlertService(
        httpClient: client,
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: testSender,
        productAccess: FakeProductAccess(TierId.familyVault),
      );

      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: members,
      );

      expect(result.attempted, isFalse);
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
        senderIdentity: testSender,
        productAccess: FakeProductAccess(TierId.familyVault),
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
        senderIdentity: testSender,
        productAccess: FakeProductAccess(TierId.familyVault),
      );
      final unavailable = FamilyShieldAlertService(
        httpClient: http_testing.MockClient(
          (_) async => http.Response('{}', 502),
        ),
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: testSender,
        productAccess: FakeProductAccess(TierId.familyVault),
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
