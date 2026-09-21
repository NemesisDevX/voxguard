import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/core/services/alerts/family_alert_service.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/alerts/family_shield_alert_service.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'helpers/fake_product_access.dart';

String vg(String ch) => 'vg_${ch * 32}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PersistedFamilyContactRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = PersistedFamilyContactRepository(prefs: prefs);
  });

  final incident = IncidentReport(
    id: 'INC-2026-9001',
    timestamp: DateTime(2026, 9, 20),
    callerLabel: 'Unknown Caller',
    callDurationSeconds: 60,
    audioDigestSha256: 'ff' * 32,
    audioSourceLabel: 'Microphone',
    transcriptionSourceLabel: 'AssemblyAI Streaming',
    peakRiskScore: 0.9,
    riskLevel: ThreatRiskLevel.highRisk,
    threatReasons: const ['x'],
    acousticMetrics: const AudioForensicMetrics(
      spectralFlux: 0,
      spectralRolloffRatio: 0,
      zeroCrossingRate: 0,
      syntheticVoiceScore: 0,
    ),
    semanticSignals: const SemanticThreatSignals.empty(),
    transcriptSnippets: const [],
    recommendedActions: const [],
  );

  group('PersistedFamilyContactRepository', () {
    test('add works and rejects empty name / malformed id', () async {
      final c = await repo.add(
        name: 'Aunt Maya',
        externalId: vg('a'),
        trustedPhone: '+20 100 123 4567',
      );
      expect(c.id, startsWith('fc_'));
      expect((await repo.getFamilyContacts()).single.name, 'Aunt Maya');

      expect(
        () => repo.add(name: '   ', externalId: vg('b')),
        throwsA(isA<FamilyContactException>()),
      );
      for (final bad in [
        'vg_123',
        'notvg',
        'vg_${'A' * 32}',
        'vg_${'a' * 31}',
        '+201001234567',
        'aunt.maya@mail.com',
      ]) {
        expect(
          () => repo.add(name: 'X', externalId: bad),
          throwsA(isA<FamilyContactException>()),
          reason: bad,
        );
      }
    });

    test('duplicate external id is rejected', () async {
      await repo.add(name: 'Maya', externalId: vg('a'));
      expect(
        () => repo.add(name: 'Maya2', externalId: vg('a')),
        throwsA(isA<FamilyContactException>()),
      );
    });

    test('sixth contact is rejected', () async {
      for (var i = 0; i < FamilyContactRules.maxContacts; i++) {
        await repo.add(name: 'P$i', externalId: vg('$i'));
      }
      expect(
        () => repo.add(name: 'Sixth', externalId: vg('f')),
        throwsA(isA<FamilyContactException>()),
      );
    });

    test('persists across repository recreation', () async {
      await repo.add(
        name: 'Omar',
        externalId: vg('b'),
        trustedPhone: '+20 111 222 3333',
      );
      // New instance over the same store — simulates app restart.
      final reloaded = PersistedFamilyContactRepository(prefs: prefs);
      final contacts = await reloaded.getFamilyContacts();
      expect(contacts, hasLength(1));
      expect(contacts.single.name, 'Omar');
      expect(contacts.single.externalId, vg('b'));
      // Optional trusted phone survives persistence.
      expect(contacts.single.trustedPhone, '+20 111 222 3333');
      expect(contacts.single.trustedPhone, isNot(contains('vg_')));
    });

    test('edit and remove work and survive recreation', () async {
      final c = await repo.add(name: 'Maya', externalId: vg('a'));
      await repo.update(
        c.id,
        name: 'Maya Ahmed',
        trustedPhone: '+20 100 999 8888',
      );
      var contacts = await repo.getFamilyContacts();
      expect(contacts.single.name, 'Maya Ahmed');
      expect(contacts.single.trustedPhone, '+20 100 999 8888');

      // Editing to an existing external id is rejected.
      final other = await repo.add(name: 'Omar', externalId: vg('b'));
      expect(
        () => repo.update(other.id, externalId: vg('a')),
        throwsA(isA<FamilyContactException>()),
      );

      await repo.remove(c.id);
      contacts = await repo.getFamilyContacts();
      expect(contacts.single.externalId, vg('b'));

      final reloaded = PersistedFamilyContactRepository(prefs: prefs);
      expect((await reloaded.getFamilyContacts()), hasLength(1));
    });

    test('contacts listenable reflects changes', () async {
      final seen = <int>[];
      repo.contacts.addListener(() => seen.add(repo.contacts.value.length));
      final c = await repo.add(name: 'M', externalId: vg('a'));
      await repo.remove(c.id);
      expect(seen, containsAllInOrder([1, 0]));
    });
  });

  group('Real-mode dispatch', () {
    http.Request? captured;
    FamilyShieldAlertService realService() => FamilyShieldAlertService(
          httpClient: http_testing.MockClient((req) async {
            captured = req;
            return http.Response('{"ok":true}', 202);
          }),
          relayUrl: 'https://relay.example.com/alert',
          senderIdentity: () async => vg('9'),
          productAccess: FakeProductAccess(TierId.familyVault),
        );

    setUp(() => captured = null);

    test('empty Trusted Circle sends nothing — no relay call', () async {
      final result = await realService().triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: const [],
      );
      expect(result.status, AlertDispatchStatus.noRecipients);
      expect(result.attempted, isFalse);
      expect(result.detail, contains('Trusted Circle'));
      expect(captured, isNull);
    });

    test('real mode targets saved contacts — never demo ids', () async {
      await repo.add(name: 'Maya', externalId: vg('a'));
      await repo.add(name: 'Omar', externalId: vg('b'));
      final contacts = await repo.getFamilyContacts();
      final ids = [for (final c in contacts) c.externalId];

      final result = await realService().triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: ids,
      );

      expect(result.status, AlertDispatchStatus.accepted);
      final body =
          jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['family_external_ids'], [vg('a'), vg('b')]);
      expect(captured!.body.contains('demo_family'), isFalse);
      // Sender identity present + valid format; no contact PII.
      expect(body['sender_external_id'], vg('9'));
      expect(
        RegExp(r'^vg_[0-9a-f]{32}$')
            .hasMatch(body['sender_external_id'] as String),
        isTrue,
      );
      expect(captured!.body.contains('Maya'), isFalse);
      expect(captured!.body.contains('Omar'), isFalse);
      expect(captured!.body.contains('phone'), isFalse);
    });
  });

  group('Demo Mode stays simulated', () {
    test('demo contacts are labelled and nothing leaves the device',
        () async {
      final contacts =
          await const DemoFamilyContactRepository().getFamilyContacts();
      expect(contacts.every((c) => c.name.contains('Demo')), isTrue);

      var hit = false;
      final service = FamilyShieldAlertService(
        httpClient: http_testing.MockClient((_) async {
          hit = true;
          return http.Response('{}', 200);
        }),
        relayUrl: '',
        senderIdentity: () async => vg('9'),
      );
      expect(service.isDemoMode, isTrue);
      final result = await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: [for (final c in contacts) c.externalId],
      );
      expect(result.simulated, isTrue);
      expect(hit, isFalse);
    });
  });
}
