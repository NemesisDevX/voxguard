// Submission screenshot capture — renders REAL app screens at the
// Shipaton-required 1179×2556 portrait size into
// `submission/screenshots/`. Not a stretched upscale: each frame is
// laid out natively at the target resolution.
//
// Run explicitly (skipped in normal `flutter test` runs):
//   flutter test test/screenshot_capture_test.dart --update-goldens
//     --dart-define=CAPTURE_SHOTS=true
//
// Loads Roboto from the Flutter SDK material_fonts cache so golden
// output uses real glyphs instead of the Ahem test font.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_alert_screen.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/presentation/screens/incident_detail_screen.dart';
import 'package:voxguard/features/home/presentation/screens/home_screen.dart';
import 'package:voxguard/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:voxguard/features/paywall/domain/services/mock_sandbox_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/purchase_service_locator.dart';
import 'package:voxguard/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/domain/models/transcript_snippet.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_bloc.dart';
import 'package:voxguard/features/protection/presentation/screens/safecall_screen.dart';
import 'package:voxguard/features/recording/presentation/screens/analyze_recording_screen.dart';

const _enabled = bool.fromEnvironment('CAPTURE_SHOTS');
const _shotSize = Size(1179, 2556); // Shipaton-required, no frame

Future<void> _loadRoboto() async {
  // flutter_tester lives under <sdk>/bin/cache/artifacts/engine/… —
  // climb until the material_fonts directory is found.
  var dir = File(Platform.resolvedExecutable).parent;
  Directory? fontsDir;
  for (var i = 0; i < 8; i++) {
    final candidate = Directory('${dir.path}/material_fonts');
    if (candidate.existsSync()) {
      fontsDir = candidate;
      break;
    }
    dir = dir.parent;
  }
  if (fontsDir == null) return;
  final loader = FontLoader('Roboto');
  for (final name in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-italic.ttf',
  ]) {
    final f = File('${fontsDir.path}/$name');
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
  }
  await loader.load();
  // The demo transcript is Egyptian Arabic and Roboto has no Arabic
  // coverage. Noto Naskh Arabic (SIL OFL 1.1, see tool/fonts/) is
  // registered under its own family and reached through the ambient
  // fontFamilyFallback wired in _shell.
  final arabic = File('tool/fonts/NotoNaskhArabic.ttf');
  if (arabic.existsSync()) {
    final arabicLoader = FontLoader('NotoNaskh')
      ..addFont(
          Future.value(ByteData.view(arabic.readAsBytesSync().buffer)));
    await arabicLoader.load();
  }
  // Icons.* resolve to the MaterialIcons family — without it every
  // icon paints as a hollow box.
  final iconFont = File('${fontsDir.path}/materialicons-regular.otf');
  if (iconFont.existsSync()) {
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(iconFont.readAsBytesSync().buffer)));
    await iconLoader.load();
  }
}

Widget _shell(Widget child) {
  final base = ThemeData(
      brightness: Brightness.dark,
      platform: TargetPlatform.android);
  const fallback = ['NotoNaskh'];
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    // Explicit families: test-rendered text otherwise resolves to
    // the hollow Ahem box font; the fallback covers Arabic glyphs.
    theme: base.copyWith(
      textTheme: base.textTheme
          .apply(fontFamily: 'Roboto', fontFamilyFallback: fallback),
      primaryTextTheme: base.primaryTextTheme
          .apply(fontFamily: 'Roboto', fontFamilyFallback: fallback),
    ),
    // MaterialApp's ambient DefaultTextStyle derives from the themed
    // textTheme — transcript bubbles (Text.rich) merge it, so the
    // fontFamilyFallback reaches Arabic spans with no explicit family.
    home: child,
  );
}

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  // Bounded pumps — ambient animations never fully settle.
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  if (!_enabled) return;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadRoboto();
    // The `record` plugin has no test-side implementation — answer
    // its channel with harmless defaults so screens that merely
    // construct an AudioRecorder don't fail.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (call) async => switch (call.method) {
        'hasPermission' => true,
        'isPaused' || 'isRecording' => false,
        _ => null,
      },
    );
  });
  setUp(() => PurchaseServiceLocator.reset());
  tearDown(() => PurchaseServiceLocator.reset());

  Future<void> shot(WidgetTester tester, Widget child, String name,
      [int frames = 8]) async {
    tester.view.physicalSize = _shotSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_shell(child));
    await _settle(tester, frames);
    await expectLater(
      find.byWidget(child),
      matchesGoldenFile('../submission/screenshots/$name.png'),
    );
  }

  testWidgets('capture submission screens', (tester) async {
    SharedPreferences.setMockInitialValues(
        const {'voxguard.onboarding_version': 1});
    PurchaseServiceLocator.instance = MockSandboxPurchaseService(
        networkDelay: Duration.zero, checkoutDelay: Duration.zero);

    // 1 — Home / readiness hero
    await shot(tester, const HomeScreen(), '01_home_threatcore');

    // 2 — Onboarding (privacy-first trust flow)
    await shot(tester, const OnboardingScreen(), '07_onboarding');

    // 3 — Paywall (Demo Store labelled)
    await shot(tester, const PaywallScreen(), '06_paywall');

    // 4 — Analyze Recording
    await shot(
        tester, const AnalyzeRecordingScreen(), '05_analyze_recording');

    // 5 — Incident detail (constructed high-risk report)
    final incident = IncidentReport(
      id: 'INC-2026-4821',
      timestamp: DateTime(2026, 8, 14, 21, 37),
      callerLabel: 'Unknown Caller (+20 10 ••• ••42)',
      callDurationSeconds: 142,
      audioDigestSha256:
          'a3f1c9e7b2046d85f7e1a0c3b9d4e6f80123456789abcdef0123456789abcdef',
      audioSourceLabel: 'Generated Demo Audio',
      transcriptionSourceLabel: 'Local Demo Transcript',
      peakRiskScore: 0.87,
      riskLevel: ThreatRiskLevel.highRisk,
      threatReasons: const [
        'Caller claimed to be a family member',
        'Urgent money demand detected',
        'Acoustic indicators elevated',
      ],
      acousticMetrics: const AudioForensicMetrics(
        spectralFlux: 0.31,
        spectralRolloffRatio: 0.62,
        zeroCrossingRate: 0.18,
        syntheticVoiceScore: 0.74,
      ),
      semanticSignals: const SemanticThreatSignals(
        urgencyScore: 0.9,
        financialDemandScore: 0.85,
        secrecyScore: 0.7,
        detectedKeywords: ['urgent', 'transfer', 'gift card'],
        impersonationClaims: ['family member'],
      ),
      transcriptSnippets: [
        TranscriptSnippet(
          speaker: 'Caller',
          text: 'It is me, your son. I am in trouble and I need '
              'you to transfer money right now.',
          timestamp: DateTime(2026, 8, 14, 21, 36, 4),
        ),
        TranscriptSnippet(
          speaker: 'Caller',
          text: 'Do not tell anyone. Buy gift cards and send me '
              'the codes urgently.',
          timestamp: DateTime(2026, 8, 14, 21, 36, 41),
        ),
      ],
      recommendedActions: const [
        'Hang up and call your family member on their saved number',
        'Never share codes or transfer money under pressure',
        'Report the incident if money was sent',
      ],
    );
    await shot(tester, IncidentDetailScreen(incident: incident),
        '03_incident_detail');

    // 6 — Family Shield alert (receiver side, known sender)
    final alert = ReceivedFamilyAlert(
      incidentId: 'INC-2026-4821',
      senderExternalId: 'vg_0123456789abcdef0123456789abcdef',
      riskLevel: 'highRisk',
      receivedAt: DateTime(2026, 8, 14, 21, 37),
      analysisScope: 'full',
    );
    final sender = FamilyContact(
      id: 'fc_1',
      name: 'Dad',
      externalId: alert.senderExternalId,
      trustedPhone: '+20 100 000 0042',
      updatedAt: DateTime(2026, 8, 10),
    );
    await shot(
      tester,
      FamilyAlertScreen(alert: alert, sender: sender),
      '04_family_shield_alert',
    );
  });

  testWidgets('capture SafeCall demo attack', (tester) async {
    SharedPreferences.setMockInitialValues(
        const {'voxguard.onboarding_version': 1});
    tester.view.physicalSize = _shotSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_shell(const SafeCallScreen()));
    await _settle(tester);

    // Mode picker → Demo Attack session.
    final demoCard = find.text('Demo Attack');
    if (demoCard.evaluate().isEmpty) return;
    await tester.tap(demoCard);
    await _settle(tester, 12);

    // Trigger the scripted attack; lines land every ~1.4 s.
    // Target the FAB specifically — the mode card uses the same icon.
    final fab =
        find.widgetWithIcon(FloatingActionButton, Icons.science_outlined);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }
    await expectLater(
      find.byType(SafeCallScreen),
      matchesGoldenFile('../submission/screenshots/02_safecall_demo.png'),
    );
    // Close the bloc directly — provider disposal doesn't await the
    // async teardown, and its demo-audio timer would otherwise still
    // be pending when the test invariant check runs.
    final ctx = tester.element(find.descendant(
        of: find.byType(SafeCallScreen),
        matching: find.byType(Scaffold)));
    try {
      await tester.runAsync(() => ctx.read<SafeCallBloc>().close());
    } catch (_) {}
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
