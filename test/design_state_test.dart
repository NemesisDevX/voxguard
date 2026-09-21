import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/audio/audio_stream_source.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_alert_screen.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_bloc.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_state.dart';
import 'package:voxguard/features/protection/presentation/screens/safecall_screen.dart';
import 'package:voxguard/features/protection/presentation/widgets/post_call_safety_sheet.dart';
import 'package:voxguard/features/protection/presentation/widgets/signal_lens.dart';

/// Focused design-state coverage for the Signal Lens overhaul —
/// partial/full lens, risk-band labels, reduced motion, the
/// high-risk verification CTA, human-vs-AI separation, and
/// large-text overflow safety.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const acoustic = AudioForensicMetrics(
    spectralFlux: 0.3,
    spectralRolloffRatio: 0.6,
    zeroCrossingRate: 0.2,
    syntheticVoiceScore: 0.8,
  );

  IncidentReport highRiskIncident() => IncidentReport(
        id: 'INC-2026-0001',
        timestamp: DateTime(2026, 9, 20, 14, 30),
        callerLabel: 'Unknown Caller',
        callDurationSeconds: 120,
        audioDigestSha256: 'ab' * 32,
        audioSourceLabel: 'Generated Demo Audio',
        transcriptionSourceLabel: 'Local Demo Transcript',
        peakRiskScore: 0.9,
        riskLevel: ThreatRiskLevel.highRisk,
        threatReasons: const ['Urgent money demand detected'],
        acousticMetrics: acoustic,
        semanticSignals: const SemanticThreatSignals(
          urgencyScore: 0.9,
          financialDemandScore: 1.0,
          secrecyScore: 0.8,
          detectedKeywords: ['transfer'],
          impersonationClaims: ['أنا أخوك'],
        ),
        transcriptSnippets: const [],
        recommendedActions: const ['Verify the speaker'],
      );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool disableAnimations = false,
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      // The override must live INSIDE MaterialApp — an outer
      // MediaQuery is shadowed by the app's own from-view query.
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: appChild!,
      ),
      home: Scaffold(body: child),
    ));
  }

  /// Bounded pumps — the lens breathes forever when animations are
  /// enabled, so pumpAndSettle would hang.
  Future<void> settle(WidgetTester tester, [int frames = 6]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  group('Signal Lens', () {
    test('risk-state labels follow the score bands', () {
      expect(SignalLens.stateLabel(0.0), 'SAFE');
      expect(SignalLens.stateLabel(0.39), 'SAFE');
      expect(SignalLens.stateLabel(0.40), 'CAUTION');
      expect(SignalLens.stateLabel(0.74), 'CAUTION');
      expect(SignalLens.stateLabel(0.75), 'HIGH RISK');
      expect(SignalLens.stateLabel(1.0), 'HIGH RISK');
    });

    test('interpretation leads with a human message, not a verdict',
        () {
      expect(SignalLens.interpretation(0.9), 'Pause before acting.');
      expect(SignalLens.interpretation(0.9),
          isNot(contains('probability')));
      expect(SignalLens.interpretation(0.9),
          isNot(contains('%')));
    });

    testWidgets('partial lens — missing conversation layer is '
        'visibly absent, never fabricated', (tester) async {
      await pump(
        tester,
        const SignalLens(score: 0.5, acousticScore: 0.4),
        disableAnimations: true,
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();
      expect(find.text('NOT ANALYZED'), findsOneWidget);
      expect(find.textContaining('Conversation'), findsOneWidget);
      // The acoustic layer still reports its real evidence.
      expect(find.text('40'), findsOneWidget);
      expect(find.text('CAUTION'), findsOneWidget);
    });

    testWidgets('full lens — both layers report their evidence',
        (tester) async {
      await pump(
        tester,
        const SignalLens(
          score: 0.8,
          acousticScore: 0.7,
          semanticScore: 0.6,
        ),
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('NOT ANALYZED'), findsNothing);
      expect(find.text('60'), findsOneWidget); // conversation layer
      expect(find.text('70'), findsOneWidget); // acoustic layer
      expect(find.text('HIGH RISK'), findsOneWidget);
    });

    testWidgets('reduced motion — the lens settles instantly, state '
        'still renders', (tester) async {
      await pump(
        tester,
        const SignalLens(score: 0.85, acousticScore: 0.8,
            semanticScore: 0.9),
        disableAnimations: true,
      );
      // pumpAndSettle completing proves the breathing controller is
      // stopped — no infinite ambient animation under reduced motion.
      await tester.pumpAndSettle();
      expect(find.text('HIGH RISK'), findsOneWidget);
    });
  });

  group('high-risk verification moment', () {
    testWidgets('live session — pause message and verify-first CTA',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(
          bloc: SafeCallBloc.seeded(const SafeCallMonitoring(
            acoustic: acoustic,
            semantic: SemanticThreatSignals(
              urgencyScore: 0.9,
              financialDemandScore: 1.0,
              secrecyScore: 0.8,
              detectedKeywords: ['transfer'],
              impersonationClaims: ['أنا أخوك'],
            ),
            report: CompositeThreatReport(
              compositeRiskScore: 0.9,
              riskLevel: ThreatRiskLevel.highRisk,
              primaryThreatReasons: ['Urgent money demand detected'],
              recommendedAction: 'End the call',
            ),
            transcript: [],
            audioSourceType: AudioSourceType.demo,
          )),
        ),
      ));
      await settle(tester);
      expect(find.text('Pause before acting.'), findsWidgets);
      expect(find.text('End call & verify'), findsOneWidget);
      expect(find.textContaining('number you already trust'),
          findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('post-call sheet — high risk opens with Pause, not '
        'an alarm', (tester) async {
      await pump(
        tester,
        PostCallSafetySheet(
          result: SafeCallEnded(
            peakRiskLevel: ThreatRiskLevel.highRisk,
            incident: highRiskIncident(),
          ),
        ),
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Pause.'), findsOneWidget);
      // Header subtitle + verify card title both carry the message.
      expect(find.textContaining('Verify before you act.'),
          findsWidgets);
      // Independent verification is present before any family action.
      expect(find.textContaining('number you already trust'),
          findsWidgets);
    });

    testWidgets('post-call sheet — safe session stays quiet',
        (tester) async {
      await pump(
        tester,
        const PostCallSafetySheet(
          result:
              SafeCallEnded(peakRiskLevel: ThreatRiskLevel.safe),
        ),
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Protection session ended'), findsOneWidget);
      expect(find.text('Pause.'), findsNothing);
    });
  });

  group('Family Shield human-vs-AI separation', () {
    testWidgets('receiver surface labels judgment as human, separate '
        'from the analysis', (tester) async {
      final alert = ReceivedFamilyAlert(
        incidentId: 'INC-2026-4821',
        senderExternalId: 'vg_${'0' * 32}',
        riskLevel: 'highRisk',
        receivedAt: DateTime(2026, 8, 14, 21, 37),
      );
      final sender = FamilyContact(
        id: 'fc_1',
        name: 'Dad',
        externalId: alert.senderExternalId,
        trustedPhone: '+20 100 000 0042',
        updatedAt: DateTime(2026, 8, 10),
      );
      await pump(
        tester,
        FamilyAlertScreen(alert: alert, sender: sender),
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('YOUR JUDGMENT'), findsOneWidget);
      expect(
        find.textContaining('does not change the risk analysis'),
        findsOneWidget,
      );
      // Human framing leads — not an emergency dispatch banner.
      expect(
        find.textContaining('second set of eyes'),
        findsOneWidget,
      );
      expect(find.text('Mark Safe'), findsOneWidget);
      expect(find.text('Still Suspicious'), findsOneWidget);
    });
  });

  group('large-text overflow protection', () {
    testWidgets('post-call sheet holds at 1.5× text scale on a '
        'narrow device', (tester) async {
      await pump(
        tester,
        PostCallSafetySheet(
          result: SafeCallEnded(
            peakRiskLevel: ThreatRiskLevel.highRisk,
            incident: highRiskIncident(),
          ),
        ),
        disableAnimations: true,
        size: const Size(320, 700),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();
      expect(find.text('Pause.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Signal Lens holds at 1.5× text scale on 320 px',
        (tester) async {
      await pump(
        tester,
        const SignalLens(score: 0.9, acousticScore: 0.8,
            semanticScore: 0.85),
        disableAnimations: true,
        size: const Size(320, 700),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
