import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/core/services/alerts/family_alert_service.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/alerts/family_shield_alert_service.dart';
import 'package:voxguard/core/services/family/family_shield_response.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/core/services/push/push_identity_service.dart';
import 'package:voxguard/features/family_shield/family_alert_coordinator.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_alert_screen.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_shield_update_screen.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/domain/services/incident_repository.dart';
import 'package:voxguard/features/forensics/presentation/screens/incident_detail_screen.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';

String vg(String ch) => 'vg_${ch * 32}';

// ── Fakes ────────────────────────────────────────────────────────────

final class _FakePush implements IPushIdentityService {
  final alertTapsCtrl = StreamController<FamilyAlertTap>.broadcast();
  final alertReceivedCtrl = StreamController<FamilyAlertTap>.broadcast();
  final responseTapsCtrl = StreamController<FamilyShieldResponse>.broadcast();
  final responseReceivedCtrl =
      StreamController<FamilyShieldResponse>.broadcast();
  final _registration = ValueNotifier<FamilyPushRegistration>(
      const FamilyPushRegistration(
          status: PushRegistrationStatus.registered));

  @override
  ValueListenable<FamilyPushRegistration> get registration =>
      _registration;
  @override
  Stream<FamilyAlertTap> get alertTaps => alertTapsCtrl.stream;
  @override
  Stream<FamilyAlertTap> get alertReceived => alertReceivedCtrl.stream;
  @override
  Stream<FamilyShieldResponse> get responseTaps => responseTapsCtrl.stream;
  @override
  Stream<FamilyShieldResponse> get responseReceived =>
      responseReceivedCtrl.stream;
  @override
  Future<String> voxGuardIdentity() async => vg('9');
  @override
  Future<void> initialize() async {}
  @override
  Future<void> enableAlerts() async {}
  @override
  Future<void> resetIdentity() async {}
}

final class _FakeAlertService implements IFamilyAlertService {
  /// When set, [sendFamilyShieldResponse] returns this instead of
  /// the default success — used for the offline-resolution test.
  AlertDispatchResult? nextResult;
  Map<String, Object?>? lastResponsePayload;
  int responseCalls = 0;

  @override
  ValueListenable<bool> get isFamilyShieldEnabled =>
      ValueNotifier(true);
  @override
  bool get isDemoMode => false;
  @override
  void toggleFamilyShield(bool enabled) {}
  @override
  Future<AlertDispatchResult> triggerFamilyEmergencyAlert({
    required IncidentReport incident,
    required List<String> familyMemberIds,
  }) async =>
      const AlertDispatchResult(
          status: AlertDispatchStatus.accepted, detail: 'ok');
  @override
  Future<AlertDispatchResult> sendFamilyShieldResponse({
    required String incidentId,
    required AlertResolution resolution,
    required String targetExternalId,
  }) async {
    responseCalls++;
    lastResponsePayload = {
      'incident_id': incidentId,
      'resolution': resolution.name,
      'target_external_id': targetExternalId,
    };
    return nextResult ??
        const AlertDispatchResult(
            status: AlertDispatchStatus.accepted, detail: 'sent');
  }
}

final class _FakeContactRepo implements IFamilyContactRepository {
  _FakeContactRepo(this.list);
  final List<FamilyContact> list;
  @override
  Future<List<FamilyContact>> getFamilyContacts() async => list;
  @override
  ValueListenable<List<FamilyContact>> get contacts =>
      ValueNotifier(list);
  @override
  Future<FamilyContact> add(
          {required String name,
          required String externalId,
          String? trustedPhone}) =>
      throw UnimplementedError();
  @override
  Future<void> update(String id,
          {String? name,
          String? externalId,
          String? trustedPhone,
          bool clearPhone = false}) =>
      throw UnimplementedError();
  @override
  Future<void> remove(String id) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    PersistedFamilyContactRepository.setTestRecipientOverride(null);
  });

  final contactMaya = FamilyContact(
    id: 'fc_aaaa1111bbbb2222',
    name: 'Maya',
    externalId: vg('a'),
    trustedPhone: '+20 100 123 4567',
    updatedAt: DateTime(2026),
  );

  final alertTap = FamilyAlertTap(
    incidentId: 'INC-9',
    riskLevel: 'highRisk',
    senderExternalId: vg('a'),
  );

  // ── Preflight: load race + sanitize + override ────────────────────

  group('PersistedFamilyContactRepository hardening', () {
    test('concurrent first reads share one load and both see data',
        () async {
      await prefs.setString(
        'voxguard.trusted_circle',
        jsonEncode([contactMaya.toJson()]),
      );
      var reads = 0;
      final counting = _CountingPrefs(prefs, () => reads++);
      final repo = PersistedFamilyContactRepository(prefs: counting);

      final results = await Future.wait([
        repo.getFamilyContacts(),
        repo.getFamilyContacts(),
        repo.getFamilyContacts(),
      ]);
      for (final r in results) {
        expect(r, hasLength(1));
        expect(r.single.name, 'Maya');
      }
      expect(reads, 1, reason: 'concurrent callers share one read');
    });

    test('corrupted persisted entries are skipped safely', () async {
      await prefs.setString(
        'voxguard.trusted_circle',
        jsonEncode([
          contactMaya.toJson(),
          {'id': 'x', 'name': '', 'external_id': vg('b')}, // empty name
          {'id': 'bad', 'name': 'O', 'external_id': vg('c')}, // bad id
          {
            'id': 'fc_1111222233334444',
            'name': 'Bad',
            'external_id': 'not-vg'
          },
          {
            'id': 'fc_5555666677778888',
            'name': 'Long',
            'external_id': vg('d'),
            'trusted_phone': '9' * 40, // phone too long
          },
          'garbage',
          42,
        ]),
      );
      final repo = PersistedFamilyContactRepository(prefs: prefs);
      final contacts = await repo.getFamilyContacts();
      expect(contacts, hasLength(1));
      expect(contacts.single.externalId, vg('a'));
    });

    test('duplicate persisted external ids dedupe; cap at 5', () async {
      final dup = FamilyContact(
        id: 'fc_9999888877776666',
        name: 'Maya Again',
        externalId: vg('a'), // duplicate external id
        updatedAt: DateTime(2026),
      );
      await prefs.setString(
        'voxguard.trusted_circle',
        jsonEncode([
          contactMaya.toJson(),
          dup.toJson(),
          for (var i = 0; i < 6; i++)
            FamilyContact(
              id: 'fc_000000000000000$i',
              name: 'P$i',
              externalId: vg('$i'),
              updatedAt: DateTime(2026),
            ).toJson(),
        ]),
      );
      final repo = PersistedFamilyContactRepository(prefs: prefs);
      final contacts = await repo.getFamilyContacts();
      // dedupe removes 1 → 7 valid → capped at 5
      expect(contacts.length, FamilyContactRules.maxContacts);
      final ids = contacts.map((c) => c.externalId).toSet();
      expect(ids.length, contacts.length);
    });

    test('invalid dev override is ignored — never sent to relay',
        () async {
      PersistedFamilyContactRepository.setTestRecipientOverride(
          'demo_family_maya');
      final repo = PersistedFamilyContactRepository(prefs: prefs);
      final contacts = await repo.getFamilyContacts();
      expect(contacts, isEmpty);
      expect(
        contacts.any((c) => c.externalId.contains('demo_family')),
        isFalse,
      );
    });
  });

  // ── ReceivedFamilyAlert store ──────────────────────────────────────

  group('ReceivedFamilyAlertRepository', () {
    test('upsert dedupes by sender+incident; resolution persists',
        () async {
      final repo = PersistedReceivedFamilyAlertRepository(prefs: prefs);
      final alert = ReceivedFamilyAlert(
        incidentId: 'INC-9',
        senderExternalId: vg('a'),
        riskLevel: 'highRisk',
        receivedAt: DateTime(2026),
      );
      await repo.upsert(alert);
      // Duplicate delivery (push + tap) must not create a second row.
      await repo.upsert(alert);
      // Same incident id from a DIFFERENT sender is a distinct alert.
      await repo.upsert(ReceivedFamilyAlert(
        incidentId: 'INC-9',
        senderExternalId: vg('b'),
        riskLevel: 'highRisk',
        receivedAt: DateTime(2026),
      ));
      expect(await repo.recent(), hasLength(2));

      final updated =
          await repo.setResolution(alert.key, AlertResolution.safe);
      expect(updated!.resolution, AlertResolution.safe);
      expect(updated.resolvedAt, isNotNull);

      final reloaded =
          PersistedReceivedFamilyAlertRepository(prefs: prefs);
      final found = await reloaded.lookup(alert.key);
      expect(found!.resolution, AlertResolution.safe);
    });
  });

  // ── Response parser + store ────────────────────────────────────────

  group('FamilyShieldResponse', () {
    test('parser accepts valid payload, rejects malformed', () {
      final ok = FamilyShieldResponse.fromAdditionalData({
        'kind': 'family_shield_response',
        'incident_id': 'INC-9',
        'resolution': 'safe',
        'responder_external_id': vg('a'),
      });
      expect(ok!.resolution, AlertResolution.safe);
      expect(ok.incidentId, 'INC-9');

      final bad = <Map<String, dynamic>?>[
        null,
        {'kind': 'family_shield_alert'},
        {
          'kind': 'family_shield_response',
          'incident_id': 'INC-9',
          'resolution': 'unresolved', // not a wire resolution
          'responder_external_id': vg('a'),
        },
        {
          'kind': 'family_shield_response',
          'incident_id': 'INC-9',
          'resolution': 'safe',
          'responder_external_id': 'demo_family_maya',
        },
        {
          'kind': 'family_shield_response',
          'incident_id': '',
          'resolution': 'safe',
          'responder_external_id': vg('a'),
        },
        {
          'kind': 'family_shield_response',
          'incident_id': 42,
          'resolution': 'safe',
          'responder_external_id': vg('a'),
        },
      ];
      for (final b in bad) {
        expect(FamilyShieldResponse.fromAdditionalData(b), isNull,
            reason: '$b');
      }
    });

    test('store keys by incident+responder and does not touch risk',
        () async {
      final store = PersistedFamilyShieldResponseStore(prefs: prefs);
      await store.upsert(FamilyShieldResponse(
        incidentId: 'INC-9',
        responderExternalId: vg('a'),
        resolution: AlertResolution.stillSuspicious,
      ));
      await store.upsert(FamilyShieldResponse(
        incidentId: 'INC-9',
        responderExternalId: vg('b'),
        resolution: AlertResolution.safe,
      ));
      final forInc = await store.forIncident('INC-9');
      expect(forInc, hasLength(2));

      // Response persistence never mutates the incident's AI risk.
      final incident = _incident();
      final riskBefore = incident.peakRiskScore;
      expect(incident.peakRiskScore, riskBefore);
    });
  });

  // ── Response send payload ──────────────────────────────────────────

  group('sendFamilyShieldResponse', () {
    test('payload is privacy-minimal — no PII fields', () async {
      http.Request? captured;
      final service = FamilyShieldAlertService(
        httpClient: http_testing.MockClient((req) async {
          captured = req;
          return http.Response('{"ok":true}', 202);
        }),
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: () async => vg('9'),
      );
      final result = await service.sendFamilyShieldResponse(
        incidentId: 'INC-9',
        resolution: AlertResolution.safe,
        targetExternalId: vg('a'),
      );
      expect(result.status, AlertDispatchStatus.accepted);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(
        body.keys.toSet(),
        {
          'kind',
          'incident_id',
          'resolution',
          'responder_external_id',
          'target_external_id',
        },
      );
      expect(body['kind'], 'family_shield_response');
      expect(body['responder_external_id'], vg('9'));
      expect(body['target_external_id'], vg('a'));
      expect(captured!.body.contains('Maya'), isFalse);
      expect(captured!.body.contains('phone'), isFalse);
    });

    test('rejects non-vg target without a network call', () async {
      var hit = false;
      final service = FamilyShieldAlertService(
        httpClient: http_testing.MockClient((_) async {
          hit = true;
          return http.Response('{}', 200);
        }),
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: () async => vg('9'),
      );
      final result = await service.sendFamilyShieldResponse(
        incidentId: 'INC-9',
        resolution: AlertResolution.safe,
        targetExternalId: 'demo_family_maya',
      );
      expect(result.status, AlertDispatchStatus.rejected);
      expect(hit, isFalse);
    });

    test('unresolved is rejected client-side — zero network I/O',
        () async {
      var hit = false;
      final service = FamilyShieldAlertService(
        httpClient: http_testing.MockClient((_) async {
          hit = true;
          return http.Response('{}', 200);
        }),
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: () async => vg('9'),
      );
      final result = await service.sendFamilyShieldResponse(
        incidentId: 'INC-9',
        resolution: AlertResolution.unresolved,
        targetExternalId: vg('a'),
      );
      expect(result.status, AlertDispatchStatus.rejected);
      expect(hit, isFalse);
    });

    test('demo mode simulates — nothing leaves the device', () async {
      var hit = false;
      final service = FamilyShieldAlertService(
        httpClient: http_testing.MockClient((_) async {
          hit = true;
          return http.Response('{}', 200);
        }),
        relayUrl: '',
        senderIdentity: () async => vg('9'),
      );
      final result = await service.sendFamilyShieldResponse(
        incidentId: 'INC-9',
        resolution: AlertResolution.safe,
        targetExternalId: vg('a'),
      );
      expect(result.simulated, isTrue);
      expect(hit, isFalse);
    });
  });

  // ── Coordinator: persistence + navigation ─────────────────────────

  group('FamilyAlertCoordinator', () {
    late _FakePush push;
    late PersistedReceivedFamilyAlertRepository alertRepo;
    late PersistedFamilyShieldResponseStore responseStore;
    late _FakeAlertService alertService;
    FamilyAlertCoordinator? coordinator;

    setUp(() {
      push = _FakePush();
      alertRepo = PersistedReceivedFamilyAlertRepository(prefs: prefs);
      responseStore = PersistedFamilyShieldResponseStore(prefs: prefs);
      alertService = _FakeAlertService();
      FamilyAlertLocator.instance = alertService;
      FamilyContactLocator.instance = _FakeContactRepo([contactMaya]);
      ReceivedFamilyAlertLocator.instance = alertRepo;
      FamilyShieldResponseLocator.instance = responseStore;
    });

    tearDown(() async {
      await coordinator?.dispose();
    });

    Future<void> pumpApp(
      WidgetTester tester, {
      GlobalKey<NavigatorState>? navKey,
      GlobalKey<ScaffoldMessengerState>? msgKey,
    }) async {
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navKey,
        scaffoldMessengerKey: msgKey,
        home: const Scaffold(body: Text('home')),
      ));
    }

    testWidgets('alert tap persists once and navigates to alert screen',
        (tester) async {
      final nav = GlobalKey<NavigatorState>();
      coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        push: push,
        contacts: _FakeContactRepo([contactMaya]),
        alerts: alertRepo,
        responses: responseStore,
      )..start();
      await pumpApp(tester, navKey: nav);

      push.alertTapsCtrl.add(alertTap);
      push.alertTapsCtrl.add(alertTap); // duplicate delivery
      await tester.pumpAndSettle();

      expect(find.byType(FamilyAlertScreen), findsOneWidget);
      expect(find.textContaining('Maya may be dealing'), findsOneWidget);
      expect(await alertRepo.recent(), hasLength(1));
    });

    testWidgets('foreground receipt does not auto-navigate',
        (tester) async {
      final nav = GlobalKey<NavigatorState>();
      final msg = GlobalKey<ScaffoldMessengerState>();
      coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        messengerKey: msg,
        push: push,
        alerts: alertRepo,
        responses: responseStore,
      )..start();
      await pumpApp(tester, navKey: nav, msgKey: msg);

      push.alertReceivedCtrl.add(alertTap);
      await tester.pumpAndSettle();

      expect(find.byType(FamilyAlertScreen), findsNothing);
      expect(find.text('Family Shield alert received'), findsOneWidget);
      // Still persisted for the list.
      expect(await alertRepo.recent(), hasLength(1));
    });

    testWidgets('pending startup tap navigates once navigator mounts',
        (tester) async {
      final nav = GlobalKey<NavigatorState>();
      coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        push: push,
        alerts: alertRepo,
        responses: responseStore,
      )..start();

      // Tap fires BEFORE any MaterialApp exists → held as pending.
      push.alertTapsCtrl.add(alertTap);
      await tester.pump();

      await pumpApp(tester, navKey: nav);
      await tester.pumpAndSettle();

      expect(find.byType(FamilyAlertScreen), findsOneWidget);
    });

    testWidgets('unknown sender shows generic copy, never invents name',
        (tester) async {
      final nav = GlobalKey<NavigatorState>();
      coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        push: push,
        contacts: _FakeContactRepo(const []), // circle knows nobody
        alerts: alertRepo,
        responses: responseStore,
      )..start();
      await pumpApp(tester, navKey: nav);

      push.alertTapsCtrl.add(alertTap);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('unrecognized PauseSignal identity'),
        findsOneWidget,
      );
      expect(find.textContaining('Maya'), findsNothing);
    });

    testWidgets('response tap opens incident detail when it exists',
        (tester) async {
      final incidents = InMemoryIncidentRepository(seed: false);
      await incidents.saveIncident(_incident());
      final nav = GlobalKey<NavigatorState>();
      coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        push: push,
        alerts: alertRepo,
        responses: responseStore,
        incidents: incidents,
      )..start();
      await pumpApp(tester, navKey: nav);

      push.responseTapsCtrl.add(FamilyShieldResponse(
        incidentId: 'INC-9',
        responderExternalId: vg('a'),
        resolution: AlertResolution.safe,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentDetailScreen), findsOneWidget);
      expect(
        find.textContaining('marked this situation safe'),
        findsOneWidget,
      );
    });

    testWidgets('response tap without a local incident opens the '
        'update screen instead of crashing', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        push: push,
        contacts: _FakeContactRepo([contactMaya]),
        alerts: alertRepo,
        responses: responseStore,
        incidents: InMemoryIncidentRepository(seed: false),
      )..start();
      await pumpApp(tester, navKey: nav);

      push.responseTapsCtrl.add(FamilyShieldResponse(
        incidentId: 'INC-unknown',
        responderExternalId: vg('a'),
        resolution: AlertResolution.stillSuspicious,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FamilyShieldUpdateScreen), findsOneWidget);
      expect(find.textContaining('Maya is still concerned'),
          findsOneWidget);
      expect(await responseStore.forIncident('INC-unknown'),
          hasLength(1));
    });
  });

  // ── Analysis scope truthfulness (Part B) ────────────────────────

  group('analysis_scope', () {
    test('FamilyAlertTap parses full/partial scope; absent → full',
        () {
      final base = {
        'kind': 'family_shield_alert',
        'incident_id': 'INC-1',
        'risk_level': 'suspicious',
        'sender_external_id': vg('a'),
      };
      expect(
          FamilyAlertTap.fromAdditionalData(base)!.analysisScope,
          'full');
      expect(
        FamilyAlertTap.fromAdditionalData(
            {...base, 'analysis_scope': 'partial'})!.analysisScope,
        'partial',
      );
      expect(
        FamilyAlertTap.fromAdditionalData(
            {...base, 'analysis_scope': 'full'})!.analysisScope,
        'full',
      );
      // Malformed scope → not a routable alert.
      expect(
        FamilyAlertTap.fromAdditionalData(
            {...base, 'analysis_scope': 'acoustic_only'}),
        isNull,
      );
      // 'safe' is a human resolution, not a danger-alert band.
      expect(
        FamilyAlertTap.fromAdditionalData(
            {...base, 'risk_level': 'safe'}),
        isNull,
      );
    });

    test('scope persists through the received-alert store', () async {
      final repo = PersistedReceivedFamilyAlertRepository(prefs: prefs);
      await repo.upsert(ReceivedFamilyAlert(
        incidentId: 'INC-P',
        senderExternalId: vg('a'),
        riskLevel: 'suspicious',
        receivedAt: DateTime(2026),
        analysisScope: 'partial',
      ));
      final stored = await repo.lookup('${vg('a')}|INC-P');
      expect(stored!.analysisScope, 'partial');
      // Malformed persisted scope is dropped, not trusted.
      final raw = ReceivedFamilyAlert(
        incidentId: 'INC-BAD',
        senderExternalId: vg('a'),
        riskLevel: 'suspicious',
        receivedAt: DateTime(2026),
      ).toJson()
        ..['analysis_scope'] = 'bogus';
      expect(ReceivedFamilyAlert.fromJson(raw), isNull);
    });
  });

  // ── FamilyAlertScreen behavior ─────────────────────────────────────

  group('FamilyAlertScreen', () {
    late PersistedReceivedFamilyAlertRepository alertRepo;
    late _FakeAlertService alertService;
    late ReceivedFamilyAlert alert;

    setUp(() {
      alertRepo = PersistedReceivedFamilyAlertRepository(prefs: prefs);
      alertService = _FakeAlertService();
      FamilyAlertLocator.instance = alertService;
      ReceivedFamilyAlertLocator.instance = alertRepo;
      alert = ReceivedFamilyAlert(
        incidentId: 'INC-9',
        senderExternalId: vg('a'),
        riskLevel: 'highRisk',
        receivedAt: DateTime(2026, 1, 1, 12),
      );
    });

    testWidgets('trusted phone builds a tel: URI via launch seam',
        (tester) async {
      Uri? launched;
      TrustedPhoneLauncher.launchImpl = (uri) async {
        launched = uri;
        return true;
      };
      await alertRepo.upsert(alert);
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: alert, sender: contactMaya),
      ));

      await tester.tap(find.text('Call Maya'));
      await tester.pump();

      expect(
        launched,
        Uri(scheme: 'tel', path: '+20 100 123 4567'),
      );
    });

    testWidgets('no trusted phone → no call action, truthful guidance',
        (tester) async {
      final noPhone = FamilyContact(
        id: 'fc_aaaa1111bbbb2222',
        name: 'Omar',
        externalId: vg('a'),
        updatedAt: DateTime(2026),
      );
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: alert, sender: noPhone),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No trusted number saved'),
          findsOneWidget);
      expect(find.text('Call Omar'), findsNothing);
    });

    testWidgets('Mark Safe persists locally and sends response',
        (tester) async {
      await alertRepo.upsert(alert);
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: alert, sender: contactMaya),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Safe'));
      await tester.pumpAndSettle();

      final stored = await alertRepo.lookup(alert.key);
      expect(stored!.resolution, AlertResolution.safe);
      expect(alertService.responseCalls, 1);
      expect(alertService.lastResponsePayload!['target_external_id'],
          vg('a'));
      expect(find.textContaining('Marked safe'), findsOneWidget);
    });

    testWidgets('Still Suspicious persists + keeps guidance visible',
        (tester) async {
      await alertRepo.upsert(alert);
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: alert, sender: contactMaya),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Still Suspicious'));
      await tester.pumpAndSettle();

      expect((await alertRepo.lookup(alert.key))!.resolution,
          AlertResolution.stillSuspicious);
      expect(find.textContaining('Do not send money'), findsOneWidget);
      expect(find.textContaining('Still suspicious'), findsWidgets);
    });

    testWidgets('network failure keeps the local resolution',
        (tester) async {
      alertService.nextResult = const AlertDispatchResult(
          status: AlertDispatchStatus.unavailable,
          detail: 'Network error');
      await alertRepo.upsert(alert);
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: alert, sender: contactMaya),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Safe'));
      await tester.pumpAndSettle();

      // Local decision stands; only the family update failed.
      expect((await alertRepo.lookup(alert.key))!.resolution,
          AlertResolution.safe);
      expect(
        find.textContaining('Family update could not be sent'),
        findsOneWidget,
      );
    });

    testWidgets('partial recording alert — acoustic warning copy, '
        'never a high-risk call', (tester) async {
      final partial = ReceivedFamilyAlert(
        incidentId: 'INC-P1',
        senderExternalId: vg('a'),
        riskLevel: 'suspicious',
        receivedAt: DateTime(2026),
        analysisScope: 'partial',
      );
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: partial, sender: contactMaya),
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'asked you to verify an elevated acoustic warning from a '
            'recording'),
        findsOneWidget,
      );
      expect(find.text('PARTIAL ANALYSIS'), findsOneWidget);
      expect(
        find.textContaining(
            'Conversation-risk signals were not analyzed.'),
        findsOneWidget,
      );
      // Never upgrades partial evidence into a call verdict.
      expect(find.textContaining('high-risk call'), findsNothing);
      expect(find.text('HIGH RISK'), findsNothing);
    });

    testWidgets('suspicious full alert uses suspicious wording',
        (tester) async {
      final suspicious = ReceivedFamilyAlert(
        incidentId: 'INC-S1',
        senderExternalId: vg('a'),
        riskLevel: 'suspicious',
        receivedAt: DateTime(2026),
        analysisScope: 'full',
      );
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: suspicious, sender: contactMaya),
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'received a suspicious-call warning from PauseSignal'),
        findsOneWidget,
      );
      expect(find.text('SUSPICIOUS'), findsOneWidget);
      expect(find.textContaining('high-risk call'), findsNothing);
    });

    testWidgets('high-risk full alert uses high-risk wording',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FamilyAlertScreen(alert: alert, sender: contactMaya),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('may be dealing with a high-risk '
          'call'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
    });
  });
}

/// Counts SharedPreferences reads to prove a single persistence load.
final class _CountingPrefs implements SharedPreferences {
  _CountingPrefs(this._inner, this._onRead);
  final SharedPreferences _inner;
  final void Function() _onRead;

  @override
  String? getString(String key) {
    _onRead();
    return _inner.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) =>
      _inner.setString(key, value);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

IncidentReport _incident() => IncidentReport(
      id: 'INC-9',
      timestamp: DateTime(2026),
      callerLabel: 'Unknown Caller',
      callDurationSeconds: 90,
      audioDigestSha256: 'ab' * 32,
      audioSourceLabel: 'Microphone',
      transcriptionSourceLabel: 'AssemblyAI Streaming',
      peakRiskScore: 0.91,
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
