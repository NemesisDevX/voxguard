import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/audio/audio_stream_source.dart';
import 'package:voxguard/core/services/audio/demo_audio_source.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_alert_screen.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/domain/models/transcript_snippet.dart';
import 'package:voxguard/features/protection/domain/services/semantic_threat_service.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_bloc.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_event.dart';
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
        const SignalLens(
          score: 0.5,
          acousticScore: 0.4,
          conversationAnalyzed: false,
        ),
        disableAnimations: true,
        size: const Size(320, 700),
      );
      await tester.pumpAndSettle();
      expect(find.text('NOT ANALYZED'), findsOneWidget);
      expect(find.textContaining('Conversation'), findsOneWidget);
      // The acoustic layer still reports its real evidence.
      expect(find.text('40'), findsWidgets);
      // Missing signal ≠ safe — the lens is explicitly incomplete.
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);
      expect(find.text('CAUTION'), findsNothing);
      expect(find.text('SAFE'), findsNothing);
    });

    testWidgets('full lens — both layers report their evidence',
        (tester) async {
      await pump(
        tester,
        const SignalLens(
          score: 0.8,
          acousticScore: 0.7,
          semanticScore: 0.6,
          conversationAnalyzed: true,
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
            semanticScore: 0.9, conversationAnalyzed: true),
        disableAnimations: true,
      );
      // pumpAndSettle completing proves the breathing controller is
      // stopped — no infinite ambient animation under reduced motion.
      await tester.pumpAndSettle();
      expect(find.text('HIGH RISK'), findsOneWidget);
    });
  });

  group('acoustic-only truthfulness', () {
    // Regression: fusion weights semantic × 0.65, so an acoustic-only
    // composite is capped at 0.35 — below CAUTION. Rendering that as
    // a band label would let a strongly elevated voice anomaly read
    // as SAFE. The lens must stay explicitly incomplete instead.
    testWidgets('acoustic 1.0 without conversation — never SAFE, '
        'no fused verdict', (tester) async {
      await pump(
        tester,
        const SignalLens(
          // What the fused composite actually reports for acoustic
          // 1.0 with no semantic evidence: 0.35.
          score: 0.35,
          acousticScore: 1.0,
          conversationAnalyzed: false,
        ),
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      for (final band in ['SAFE', 'CAUTION', 'HIGH RISK']) {
        expect(find.text(band), findsNothing, reason: '$band shown');
      }
      // No fused risk-signal verdict…
      expect(find.text('RISK SIGNAL'), findsNothing);
      expect(find.text('35'), findsNothing);
      // …but the acoustic evidence that exists is displayed.
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);
      expect(find.text('ACOUSTIC ANOMALY'), findsOneWidget);
      expect(find.text('100'), findsWidgets);
      // Accessibility announces the missing layer too.
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            (w.properties.label ?? '')
                .contains('Conversation analysis not run')),
        findsWidgets,
      );
    });

    testWidgets('acoustic-only with low anomaly — incomplete, '
        'never SAFE', (tester) async {
      await pump(
        tester,
        const SignalLens(
          score: 0.05,
          acousticScore: 0.15,
          conversationAnalyzed: false,
        ),
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);
      expect(find.text('ACOUSTIC ANOMALY'), findsOneWidget);
      for (final band in ['SAFE', 'CAUTION', 'HIGH RISK']) {
        expect(find.text(band), findsNothing, reason: '$band shown');
      }
    });
  });

  group('high-risk verification moment', () {
    testWidgets('live session — pause message and verify-first CTA',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(
          // Non-const: TranscriptSnippet carries a DateTime.
          bloc: SafeCallBloc.seeded(SafeCallMonitoring(
            acoustic: acoustic,
            semantic: const SemanticThreatSignals(
              urgencyScore: 0.9,
              financialDemandScore: 1.0,
              secrecyScore: 0.8,
              detectedKeywords: ['transfer'],
              impersonationClaims: ['أنا أخوك'],
            ),
            report: const CompositeThreatReport(
              compositeRiskScore: 0.9,
              riskLevel: ThreatRiskLevel.highRisk,
              primaryThreatReasons: ['Urgent money demand detected'],
              recommendedAction: 'End the call',
            ),
            // A high composite requires completed conversation
            // analysis — provenance + transcript keep scope truthful.
            semanticAnalysisHasRun: true,
            transcript: [
              TranscriptSnippet(
                speaker: 'Caller',
                text: 'Transfer the money now',
                timestamp: DateTime(2026, 9, 20, 14, 31),
              ),
            ],
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
            semanticScore: 0.85, conversationAnalyzed: true),
        disableAnimations: true,
        size: const Size(320, 700),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SafeCall acoustic-only session', () {
    SafeCallMonitoring acousticOnly({
      bool entitled = false,
      bool sttLive = false,
    }) =>
        SafeCallMonitoring(
          acoustic: const AudioForensicMetrics(
            spectralFlux: 0.3,
            spectralRolloffRatio: 0.6,
            zeroCrossingRate: 0.2,
            syntheticVoiceScore: 0.9, // elevated — fusion caps at 0.315
          ),
          semantic: const SemanticThreatSignals.empty(),
          report: const CompositeThreatReport(
            compositeRiskScore: 0.315,
            riskLevel: ThreatRiskLevel.safe,
            primaryThreatReasons: [
              'Acoustic anomaly indicators elevated'
            ],
            recommendedAction: 'Continue monitoring',
          ),
          transcript: const [],
          audioSourceType: AudioSourceType.microphone,
          isTranscriptionLive: sttLive,
          cloudTranscriptionEntitled: entitled,
        );

    testWidgets('free Live Mic without STT — incomplete, never '
        'SAFE, explains the plan gate', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(
          bloc: SafeCallBloc.seeded(acousticOnly()),
        ),
      ));
      await settle(tester);
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);
      expect(find.text('ACOUSTIC ANOMALY'), findsOneWidget);
      expect(
        find.textContaining('Conversation analysis requires '
            'transcription'),
        findsOneWidget,
      );
      for (final band in ['SAFE', 'CAUTION', 'HIGH RISK']) {
        expect(find.text(band), findsNothing, reason: '$band shown');
      }
      expect(find.text('RISK SIGNAL'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('entitled Live Mic, transcription unavailable, no '
        'transcript yet — no false full verdict', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(
          bloc: SafeCallBloc.seeded(
              acousticOnly(entitled: true, sttLive: false)),
        ),
      ));
      await settle(tester);
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);
      expect(
        find.textContaining(
            'Conversation-risk signals were not analyzed'),
        findsOneWidget,
      );
      for (final band in ['SAFE', 'CAUTION', 'HIGH RISK']) {
        expect(find.text(band), findsNothing, reason: '$band shown');
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('semantic evidence arrival flips the lens to full '
        'fused mode', (tester) async {
      final bloc = SafeCallBloc.seeded(
          acousticOnly(entitled: true, sttLive: true));
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(bloc: bloc),
      ));
      await settle(tester);
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);

      // Real caller text arrives → conversation engine runs.
      bloc.add(const IncomingTranscriptSnippetEvent(
          speaker: 'Caller', text: 'hello, can you hear me'));
      await settle(tester, 10);

      expect(find.text('ACOUSTIC ONLY'), findsNothing);
      expect(find.text('RISK SIGNAL'), findsOneWidget);
      expect(find.text('NOT ANALYZED'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('semantic-analysis provenance', () {
    // Regression: the first streaming partial arrives ~1200 ms BEFORE
    // the debounced semantic pass completes. Deriving scope from text
    // presence flipped the lens to a fused verdict whose semantic
    // layer was still the zero baseline. Scope must follow analysis
    // completion only.
    SafeCallMonitoring monitoring() => SafeCallMonitoring(
          acoustic: const AudioForensicMetrics(
            spectralFlux: 0.3,
            spectralRolloffRatio: 0.6,
            zeroCrossingRate: 0.2,
            syntheticVoiceScore: 0.9,
          ),
          semantic: const SemanticThreatSignals.empty(),
          report: const CompositeThreatReport(
            compositeRiskScore: 0.315,
            riskLevel: ThreatRiskLevel.safe,
            primaryThreatReasons: [],
            recommendedAction: 'Continue monitoring',
          ),
          transcript: const [],
          audioSourceType: AudioSourceType.microphone,
          isTranscriptionLive: true,
          cloudTranscriptionEntitled: true,
        );

    void expectAcousticOnly() {
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);
      for (final band in ['SAFE', 'CAUTION', 'HIGH RISK']) {
        expect(find.text(band), findsNothing, reason: '$band shown');
      }
      expect(find.text('RISK SIGNAL'), findsNothing);
    }

    testWidgets('STT live → first partial → debounce → analyzed — '
        'scope follows analysis completion only', (tester) async {
      final bloc = SafeCallBloc.seeded(monitoring());
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(bloc: bloc),
      ));
      await settle(tester);
      // STT confirmed live — connection is not analysis.
      bloc.add(const TranscriptionStatusChangedEvent(true));
      await tester.pump(const Duration(milliseconds: 60));
      expectAcousticOnly();

      // First partial arrives and renders in the feed — the lens
      // must NOT flip to a fused verdict yet.
      bloc.add(const IncomingTranscriptPartialEvent(
          'hello, can you hear me'));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.textContaining('hello, can you hear me'),
          findsWidgets);
      expectAcousticOnly();

      // Inside the debounce window — still acoustic-only.
      await tester.pump(const Duration(milliseconds: 800));
      expectAcousticOnly();

      // Debounce elapses → analysis runs over the partial context →
      // full fused mode appears (benign text → a real, analyzed SAFE).
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester, 4);
      expect(find.text('ACOUSTIC ONLY'), findsNothing);
      expect(find.text('RISK SIGNAL'), findsOneWidget);
      expect(find.text('SAFE'), findsOneWidget);

      // Later partials do not regress the lens while their own
      // debounce is pending — analysis already ran this session.
      bloc.add(const IncomingTranscriptPartialEvent(
          'and how are you today'));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('RISK SIGNAL'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('benign transcript — zero semantic scores still '
        'count as analyzed', (tester) async {
      final bloc = SafeCallBloc.seeded(monitoring());
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(bloc: bloc),
      ));
      await settle(tester);
      expectAcousticOnly();

      bloc.add(const IncomingTranscriptSnippetEvent(
          speaker: 'Caller',
          text: 'the weather is lovely this morning'));
      await settle(tester, 10);

      // The engine ran and found nothing — an analyzed SAFE, not an
      // incomplete one.
      expect(find.text('ACOUSTIC ONLY'), findsNothing);
      expect(find.text('RISK SIGNAL'), findsOneWidget);
      expect(find.text('SAFE'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('session reset returns scope to acoustic-only',
        (tester) async {
      // Silent demo source — the session starts without the
      // generated-PCM timer so the test ends with no pending timers.
      final bloc = SafeCallBloc(
        demoSource: _SilentDemoSource(),
        initialState: monitoring(),
      );
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(bloc: bloc),
      ));
      await settle(tester);
      bloc.add(const IncomingTranscriptSnippetEvent(
          speaker: 'Caller', text: 'hello there'));
      await settle(tester, 10);
      expect(find.text('RISK SIGNAL'), findsOneWidget);

      bloc.add(const ResetCallEvent());
      await settle(tester);

      // A new session starts unanalyzed regardless of what the last
      // session proved.
      bloc.add(const StartDemoSessionEvent());
      await settle(tester);
      expectAcousticOnly();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('stale semantic results', () {
    // Regression: analysis is async (the dev-remote path can take
    // seconds). A Future captured under session A must commit nothing
    // to session B, and a superseded in-session request must never
    // overwrite fresher evidence.
    SafeCallMonitoring monitoring() => SafeCallMonitoring(
          acoustic: const AudioForensicMetrics(
            spectralFlux: 0.3,
            spectralRolloffRatio: 0.6,
            zeroCrossingRate: 0.2,
            syntheticVoiceScore: 0.9,
          ),
          semantic: const SemanticThreatSignals.empty(),
          report: const CompositeThreatReport(
            compositeRiskScore: 0.315,
            riskLevel: ThreatRiskLevel.safe,
            primaryThreatReasons: [],
            recommendedAction: 'Continue monitoring',
          ),
          transcript: const [],
          audioSourceType: AudioSourceType.microphone,
          isTranscriptionLive: true,
          cloudTranscriptionEntitled: true,
        );

    testWidgets('in-flight analysis across reset — the old result '
        'commits nothing to the new session', (tester) async {
      final semantic = _ControlledSemanticAnalyzer();
      final bloc = SafeCallBloc(
        demoSource: _SilentDemoSource(),
        semanticService: semantic,
        initialState: monitoring(),
      );
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(bloc: bloc),
      ));
      await settle(tester);
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);

      // Session A: analysis begins and stays in flight.
      bloc.add(const IncomingTranscriptSnippetEvent(
          speaker: 'Caller', text: 'send the money now'));
      await tester.pump(const Duration(milliseconds: 60));
      expect(semantic.pending, hasLength(1));

      // Session torn down and restarted before the Future resolves.
      bloc.add(const ResetCallEvent());
      await settle(tester);
      bloc.add(const StartDemoSessionEvent());
      await settle(tester);
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);

      // Session A's result lands late — zero observable effect:
      // no verdict, no provenance, no mutation of the new session's
      // semantic evidence.
      semantic.pending.single.complete(const SemanticThreatSignals(
        urgencyScore: 1.0,
        financialDemandScore: 1.0,
        secrecyScore: 1.0,
        detectedKeywords: ['transfer'],
        impersonationClaims: [],
      ));
      await settle(tester);
      expect(find.text('ACOUSTIC ONLY'), findsOneWidget);
      final s = bloc.state as SafeCallMonitoring;
      expect(s.semanticAnalysisHasRun, isFalse);
      expect(s.semantic.urgencyScore, 0.0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('overlapping analyses — newest request wins even '
        'when the older Future resolves last', (tester) async {
      final semantic = _ControlledSemanticAnalyzer();
      final bloc = SafeCallBloc(
        demoSource: _SilentDemoSource(),
        semanticService: semantic,
        initialState: monitoring(),
      );
      await tester.pumpWidget(MaterialApp(
        home: SafeCallScreen(bloc: bloc),
      ));
      await settle(tester);

      // Partial → debounce elapses → request 1 begins.
      bloc.add(const IncomingTranscriptPartialEvent(
          'first partial hypothesis'));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump();
      expect(semantic.pending, hasLength(1));

      // A committed snippet starts request 2 while 1 is in flight.
      bloc.add(const IncomingTranscriptSnippetEvent(
          speaker: 'Caller', text: 'urgent: send money now'));
      await tester.pump(const Duration(milliseconds: 60));
      expect(semantic.pending, hasLength(2));

      // Newer request resolves first — it commits.
      semantic.pending[1].complete(const SemanticThreatSignals(
        urgencyScore: 0.9,
        financialDemandScore: 0,
        secrecyScore: 0,
        detectedKeywords: [],
        impersonationClaims: [],
      ));
      await settle(tester);
      expect(find.text('RISK SIGNAL'), findsOneWidget);
      var s = bloc.state as SafeCallMonitoring;
      expect(s.semantic.urgencyScore, 0.9);
      expect(s.semanticAnalysisHasRun, isTrue);

      // Older request resolves late — dropped; the newer evidence
      // and the full fused lens are untouched.
      semantic.pending[0].complete(const SemanticThreatSignals(
        urgencyScore: 0,
        financialDemandScore: 0,
        secrecyScore: 0.99,
        detectedKeywords: [],
        impersonationClaims: [],
      ));
      await settle(tester);
      s = bloc.state as SafeCallMonitoring;
      expect(s.semantic.urgencyScore, 0.9);
      expect(s.semantic.secrecyScore, 0.0);
      expect(find.text('RISK SIGNAL'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

/// Demo source without the chunk-generation timer — sessions start
/// and emit monitoring snapshots while staying silent, so tests end
/// with no pending periodic timers.
final class _SilentDemoSource extends DemoAudioSource {
  @override
  Future<void> start() async {}

  @override
  Future<void> dispose() async {}
}

/// Semantic analyzer gated on test-controlled Completers — each call
/// parks until the test resolves it, so in-flight ordering is fully
/// deterministic with no real delays.
final class _ControlledSemanticAnalyzer implements ISemanticThreatAnalyzer {
  final List<Completer<SemanticThreatSignals>> pending = [];

  @override
  Future<SemanticThreatSignals> analyze(String transcript) {
    final c = Completer<SemanticThreatSignals>();
    pending.add(c);
    return c.future;
  }
}
