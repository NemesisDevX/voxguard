import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/family/family_shield_response.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/core/services/onboarding/onboarding_state_store.dart';
import 'package:voxguard/core/services/push/push_identity_service.dart';
import 'package:voxguard/features/family_shield/family_alert_coordinator.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_alert_screen.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_shield_update_screen.dart';
import 'package:voxguard/features/forensics/domain/services/incident_repository.dart';
import 'package:voxguard/features/home/presentation/screens/home_screen.dart';
import 'package:voxguard/core/services/preferences/app_preferences.dart';
import 'package:voxguard/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:voxguard/features/onboarding/presentation/screens/startup_gate.dart';
import 'package:voxguard/features/onboarding/presentation/screens/welcome_setup_screen.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_state.dart';
import 'package:voxguard/features/protection/presentation/screens/safecall_screen.dart';
import 'package:voxguard/features/protection/presentation/widgets/post_call_safety_sheet.dart';

String vg(String ch) => 'vg_${ch * 32}';

final class _FakeStore implements IOnboardingStateStore {
  _FakeStore(this.completed);
  bool completed;
  int markCalls = 0;

  /// Optional barrier — when set, `markCompleted` waits on it so tests
  /// can observe the in-flight write.
  Completer<void>? markBarrier;

  /// When set, `markCompleted` throws to simulate a failed write.
  Object? markError;

  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> markCompleted() async {
    markCalls++;
    final barrier = markBarrier;
    if (barrier != null) await barrier.future;
    final error = markError;
    if (error != null) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    completed = true;
  }
}

final class _FakePush implements IPushIdentityService {
  _FakePush([PushRegistrationStatus status =
      PushRegistrationStatus.notConfigured])
      : registration = ValueNotifier(FamilyPushRegistration(
            status: status, voxguardExternalId: vg('9')));

  int enableCalls = 0;
  @override
  final ValueNotifier<FamilyPushRegistration> registration;

  final _taps = StreamController<FamilyAlertTap>.broadcast();
  final _received = StreamController<FamilyAlertTap>.broadcast();
  final _respTaps = StreamController<FamilyShieldResponse>.broadcast();
  final _respReceived =
      StreamController<FamilyShieldResponse>.broadcast();

  @override
  Stream<FamilyAlertTap> get alertTaps => _taps.stream;
  @override
  Stream<FamilyAlertTap> get alertReceived => _received.stream;
  @override
  Stream<FamilyShieldResponse> get responseTaps => _respTaps.stream;
  @override
  Stream<FamilyShieldResponse> get responseReceived =>
      _respReceived.stream;
  @override
  Future<String> voxGuardIdentity() async => vg('9');
  @override
  Future<void> initialize() async {}
  @override
  Future<void> enableAlerts() async => enableCalls++;
  @override
  Future<void> resetIdentity() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    // Tests in this file exercise the post-setup gate: Welcome Setup
    // is already done unless a test explicitly re-arms it.
    AppPreferencesLocator.instance =
        AppPreferences.inMemory(setupCompleted: true);
  });

  Future<void> pumpGate(
    WidgetTester tester,
    IOnboardingStateStore store, {
    bool setupCompleted = true,
  }) async {
    AppPreferencesLocator.instance =
        AppPreferences.inMemory(setupCompleted: setupCompleted);
    await tester.pumpWidget(MaterialApp(home: StartupGate(
      onboardingStore: store,
    )));
    await tester.pumpAndSettle();
  }

  Future<void> walkToLastPage(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
  }

  group('startup gate', () {
    testWidgets('fresh install shows Welcome Setup before onboarding',
        (tester) async {
      await pumpGate(tester, _FakeStore(false), setupCompleted: false);
      expect(find.byType(WelcomeSetupScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('first launch after setup shows onboarding',
        (tester) async {
      await pumpGate(tester, _FakeStore(false));
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('completed onboarding opens Home directly',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: StartupGate(onboardingStore: _FakeStore(true))));
      await tester.pump(); // store read resolves → rebuild
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    test('completion persists across store recreation', () async {
      final s1 = PrefsOnboardingStateStore(prefs: prefs);
      expect(await s1.isCompleted(), isFalse);
      await s1.markCompleted();
      final s2 = PrefsOnboardingStateStore(prefs: prefs);
      expect(await s2.isCompleted(), isTrue);
    });

    testWidgets('Skip marks complete and enters Home', (tester) async {
      final store = _FakeStore(false);
      await pumpGate(tester, store);
      await tester.tap(find.text('Skip for now'));
      await tester.pump();
      await tester.pump();
      expect(store.markCalls, 1);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('completion write is awaited — gate stays on '
        'onboarding until it resolves', (tester) async {
      final store = _FakeStore(false)
        ..markBarrier = Completer<void>();
      await pumpGate(tester, store);
      await tester.tap(find.text('Skip for now'));
      await tester.pump();
      // Write is in flight — no premature Home swap.
      expect(store.markCalls, 1);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      store.markBarrier!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('double completion taps cannot race the write',
        (tester) async {
      final store = _FakeStore(false)
        ..markBarrier = Completer<void>();
      await pumpGate(tester, store);
      await tester.tap(find.text('Skip for now'));
      await tester.tap(find.text('Skip for now'));
      await tester.pump();
      expect(store.markCalls, 1);
      store.markBarrier!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('failed completion write stays usable — user enters '
        'Home with an honest note', (tester) async {
      final store = _FakeStore(false)
        ..markError = StateError('disk full');
      await pumpGate(tester, store);
      await tester.tap(find.text('Skip for now'));
      await tester.pump();
      await tester.pump();
      // No crash, no false durable-completion claim — the user still
      // gets in and is told the save failed.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.textContaining('onboarding will show again next launch'),
        findsOneWidget,
      );
    });

    testWidgets('review mode never touches completion state',
        (tester) async {
      final store = _FakeStore(true);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingScreen(
                    reviewMode: true,
                    onCompleted: () {},
                    pushService: _FakePush()),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      // Review mode hides Skip — no completion shortcut.
      expect(find.text('Skip for now'), findsNothing);
      await walkToLastPage(tester);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(store.markCalls, 0);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('Settings exposes the review entry', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: HomeScreen()));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // The subscription card now tops the tab — Trusted Circle sits
      // below the fold, so scroll the settings ListView to it.
      await tester.dragUntilVisible(
        find.text('Trusted Circle'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      expect(find.text('Trusted Circle'), findsOneWidget);
      // The entry sits below the fold — drag the settings ListView
      // itself (a second, nested Scrollable exists in the cards).
      await tester.dragUntilVisible(
        find.text('How VoxGuard Works'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.tap(find.text('How VoxGuard Works'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });

  group('permission safety', () {
    testWidgets(
        'onboarding never requests notification permission without '
        'an explicit tap; mic is never touched', (tester) async {
      final push = _FakePush();
      await tester.pumpWidget(MaterialApp(
        home: OnboardingScreen(
            onCompleted: () {}, pushService: push),
      ));
      await tester.pumpAndSettle();
      await walkToLastPage(tester);
      await tester.tap(find.text('Explore VoxGuard'));
      await tester.pumpAndSettle();
      // Zero prompts through the whole flow — microphone is simply
      // never invoked (no code path), notifications only on tap.
      expect(push.enableCalls, 0);
    });

    testWidgets('explicit Enable Family Alerts uses the push service',
        (tester) async {
      final push =
          _FakePush(PushRegistrationStatus.permissionRequired);
      await tester.pumpWidget(MaterialApp(
        home: OnboardingScreen(
            onCompleted: () {}, pushService: push),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable Family Alerts'));
      await tester.pumpAndSettle();
      expect(push.enableCalls, 1);
    });

    testWidgets('Enable Family Alerts disabled when push is '
        'notConfigured/unsupported/denied', (tester) async {
      for (final (status, expectedCopy) in [
        (PushRegistrationStatus.notConfigured,
            'Push alerts aren\'t configured in this build'),
        (PushRegistrationStatus.unsupported,
            'Push alerts aren\'t supported on this platform'),
        (PushRegistrationStatus.permissionDenied,
            'enable them later from your device\'s Settings app'),
      ]) {
        final push = _FakePush(status);
        await tester.pumpWidget(MaterialApp(
          home: OnboardingScreen(
              key: UniqueKey(),
              onCompleted: () {},
              pushService: push),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        final button =
            tester.widget<OutlinedButton>(find.byType(OutlinedButton));
        expect(button.onPressed, isNull, reason: 'status=$status');
        expect(find.textContaining(expectedCopy), findsOneWidget,
            reason: 'status=$status');
        // No permission request fired — impossible states never call.
        expect(push.enableCalls, 0, reason: 'status=$status');
      }
    });

    testWidgets('denied/unconfigured push does not block onboarding',
        (tester) async {
      for (final status in [
        PushRegistrationStatus.permissionDenied,
        PushRegistrationStatus.notConfigured,
      ]) {
        var done = false;
        await tester.pumpWidget(MaterialApp(
          home: OnboardingScreen(
              key: UniqueKey(),
              onCompleted: () => done = true,
              pushService: _FakePush(status)),
        ));
        await tester.pumpAndSettle();
        await walkToLastPage(tester);
        await tester.tap(find.text('Explore VoxGuard'));
        await tester.pumpAndSettle();
        expect(done, isTrue, reason: 'status=$status');
      }
    });
  });

  group('SafeCall handoff + safety tap', () {
    testWidgets('Start SafeCall reaches the real mode picker',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: OnboardingScreen(
            onCompleted: () {}, pushService: _FakePush()),
      ));
      await tester.pumpAndSettle();
      await walkToLastPage(tester);
      await tester.tap(find.text('Start SafeCall'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SafeCallScreen), findsOneWidget);
      // Tear down cleanly — the screen owns repeating animations.
      tester.state<NavigatorState>(
              find.byType(Navigator).last)
          .pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('Start SafeCall → end session → post-call sheet '
        'survives onboarding unmount', (tester) async {
      // Wire the same root navigator key production uses — the
      // launcher anchors the post-call flow to a context below it.
      final nav = FamilyAlertNavigator.key;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: StartupGate(onboardingStore: _FakeStore(false)),
      ));
      await tester.pumpAndSettle();
      await walkToLastPage(tester);
      await tester.tap(find.text('Start SafeCall'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SafeCallScreen), findsOneWidget);
      // The onboarding widget is now unmounted (gate swapped to Home)
      // — ending the session must still produce the sheet.
      nav.currentState!.pop(const SafeCallEnded(
          peakRiskLevel: ThreatRiskLevel.safe));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PostCallSafetySheet), findsOneWidget);
    });

    testWidgets('cold-start Family Shield tap navigates above '
        'onboarding', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      final nav = GlobalKey<NavigatorState>();
      final push = _FakePush();
      final coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        push: push,
        alerts: PersistedReceivedFamilyAlertRepository(prefs: p),
        responses: PersistedFamilyShieldResponseStore(prefs: p),
        // Per-test repo — the shared FamilyContactLocator caches a
        // _loadFuture bound to whichever test touched it first, which
        // never resumes under a later test's FakeAsync zone.
        contacts: PersistedFamilyContactRepository(prefs: p),
        incidents: InMemoryIncidentRepository(seed: false),
      )..start();
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: StartupGate(onboardingStore: _FakeStore(false)),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      push._taps.add(FamilyAlertTap(
        incidentId: 'INC-1',
        riskLevel: 'highRisk',
        senderExternalId: vg('a'),
      ));
      await tester.pumpAndSettle();

      // The safety tap pushes its screen ABOVE onboarding — the
      // gate must not swallow it.
      expect(find.byType(FamilyAlertScreen), findsOneWidget);
    });
  });

  group('response navigation + copy fixes', () {
    testWidgets('changed resolution re-navigates; identical duplicate '
        'does not', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      final push = _FakePush();
      final store = PersistedFamilyShieldResponseStore(prefs: prefs);
      final coordinator = FamilyAlertCoordinator(
        navigatorKey: nav,
        push: push,
        alerts: PersistedReceivedFamilyAlertRepository(prefs: prefs),
        responses: store,
        contacts: PersistedFamilyContactRepository(prefs: prefs),
        incidents: InMemoryIncidentRepository(seed: false),
      )..start();
      addTearDown(coordinator.dispose);
      await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: Text('home')),
      ));
      await tester.pumpAndSettle();

      FamilyShieldResponse resp(AlertResolution r) =>
          FamilyShieldResponse(
            incidentId: 'INC-9',
            responderExternalId: vg('a'),
            resolution: r,
          );

      push._respTaps.add(resp(AlertResolution.safe));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyShieldUpdateScreen), findsOneWidget);

      // Same responder+incident+resolution again → deduped.
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      push._respTaps.add(resp(AlertResolution.safe));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyShieldUpdateScreen), findsNothing);

      // A CHANGED resolution is a new event → navigates again.
      push._respTaps.add(resp(AlertResolution.stillSuspicious));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyShieldUpdateScreen), findsOneWidget);
      // Store keeps the latest resolution for the responder+incident.
      expect((await store.forIncident('INC-9')).single.resolution,
          AlertResolution.stillSuspicious);

      // safe → suspicious → safe: the third event flips BACK to a
      // previously-seen resolution — still a genuine change, not a
      // consecutive duplicate, so it must surface.
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      push._respTaps.add(resp(AlertResolution.safe));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyShieldUpdateScreen), findsOneWidget);
      expect((await store.forIncident('INC-9')).single.resolution,
          AlertResolution.safe);

      // And the immediate redelivery of that new state dedupes.
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      push._respTaps.add(resp(AlertResolution.safe));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyShieldUpdateScreen), findsNothing);
    });

    testWidgets('unknown responder is never labelled trusted',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: FamilyShieldUpdateScreen(
          response: FamilyShieldResponse(
            incidentId: 'INC-9',
            responderExternalId: vg('a'),
            resolution: AlertResolution.safe,
          ),
          responderName: null,
        ),
      ));
      expect(find.textContaining('unrecognized VoxGuard identity'),
          findsOneWidget);
      expect(find.textContaining('trusted'), findsNothing);
    });
  });

  group('persistence sanitization', () {
    test('corrupted received-alert rows are skipped', () async {
      await prefs.setString(
        'voxguard.received_family_alerts',
        jsonEncode([
          {
            'incident_id': 'INC-1',
            'sender_external_id': vg('a'),
            'risk_level': 'highRisk',
            'received_at': '2026-01-01T00:00:00.000',
            'resolution': 'unresolved',
          },
          // corrupted rows — every one skipped
          {'incident_id': 'INC-2', 'sender_external_id': 'nope',
              'risk_level': 'highRisk', 'received_at': '2026-01-01',
              'resolution': 'unresolved'},
          {'incident_id': 'INC-3', 'sender_external_id': vg('b'),
              'risk_level': 'extreme', 'received_at': '2026-01-01',
              'resolution': 'unresolved'},
          {'incident_id': 'INC-4', 'sender_external_id': vg('c'),
              'risk_level': 'safe', 'received_at': 'not-a-date',
              'resolution': 'unresolved'},
          {'incident_id': 'INC-5', 'sender_external_id': vg('d'),
              'risk_level': 'safe', 'received_at': '2026-01-01',
              'resolution': 'bogus'},
          'garbage',
        ]),
      );
      final repo = PersistedReceivedFamilyAlertRepository(prefs: prefs);
      final alerts = await repo.recent();
      expect(alerts, hasLength(1));
      expect(alerts.single.incidentId, 'INC-1');
    });

    test('corrupted response rows are skipped', () async {
      await prefs.setString(
        'voxguard.family_shield_responses',
        jsonEncode([
          {
            'incident_id': 'INC-1',
            'responder_external_id': vg('a'),
            'resolution': 'safe',
          },
          {'incident_id': 'INC-2', 'responder_external_id': 'bad',
              'resolution': 'safe'},
          {'incident_id': 'INC-3', 'responder_external_id': vg('b'),
              'resolution': 'unresolved'},
          {'incident_id': 'INC-3', 'responder_external_id': vg('b'),
              'resolution': 'safe'}, // duplicate key → deduped
        ]),
      );
      final store = PersistedFamilyShieldResponseStore(prefs: prefs);
      final all = await store.forIncident('INC-1');
      expect(all, hasLength(1));
      expect(all.single.resolution, AlertResolution.safe);
    });
  });
}
