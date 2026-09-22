// Personalization & localization foundation — preferences, l10n
// integrity, Welcome Setup, theme/accent/text-size/motion/haptics
// behavior, Guided Mode presentation, and the Family Shield
// payload privacy contract (display name never leaves the device).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voxguard/l10n/generated/app_localizations.dart';
import 'package:voxguard/core/l10n/l10n.dart';
import 'package:voxguard/core/services/alerts/family_shield_alert_service.dart';
import 'package:voxguard/core/services/haptics/app_haptics.dart';
import 'package:voxguard/core/services/preferences/app_preferences.dart';
import 'package:voxguard/core/theme/app_palette.dart';
import 'package:voxguard/core/theme/app_theme.dart';
import 'package:voxguard/features/home/presentation/screens/home_screen.dart';
import 'package:voxguard/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:voxguard/features/onboarding/presentation/screens/welcome_setup_screen.dart';
import 'package:voxguard/features/protection/presentation/screens/safecall_screen.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'package:voxguard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'helpers/fake_product_access.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferences prefs;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferences.inMemory(setupCompleted: true);
    AppPreferencesLocator.instance = prefs;
  });

  /// Minimal shell with the real delegates + theme — enough for
  /// localized screens without dragging in the whole app bootstrap.
  Widget localizedShell(Widget child,
      {Locale? locale, ThemeData? theme}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme ?? AppTheme.dark(),
      home: child,
    );
  }

  group('ARB integrity', () {
    Map<String, Object?> loadArb(String code) {
      final raw = File('lib/l10n/arb/app_$code.arb').readAsStringSync();
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      // Keep only message keys — '@key' entries are metadata.
      return Map.fromEntries(
          decoded.entries.where((e) => !e.key.startsWith('@')));
    }

    test('all four locales exist and carry the same message keys', () {
      final en = loadArb('en');
      expect(en.keys.length, greaterThan(100));
      for (final code in ['ar', 'es', 'fr']) {
        final other = loadArb(code);
        final missing = en.keys.toSet().difference(other.keys.toSet());
        final extra = other.keys.toSet().difference(en.keys.toSet());
        expect(missing, isEmpty, reason: '$code missing keys: $missing');
        expect(extra, isEmpty, reason: '$code extra keys: $extra');
        for (final k in en.keys) {
          expect((other[k] as String).trim(), isNotEmpty,
              reason: '$code.$k is empty');
        }
      }
    });

    test('translations preserve product truth — no deepfake claims', () {
      for (final code in ['en', 'ar', 'es', 'fr']) {
        final arb = loadArb(code);
        for (final entry in arb.entries) {
          final value = entry.value as String;
          expect(value.toLowerCase(), isNot(contains('deepfake')),
              reason: '$code.${entry.key}');
          expect(value.toLowerCase(), isNot(contains('100%')),
              reason: '$code.${entry.key}');
        }
      }
    });
  });

  group('AppPreferences persistence', () {
    test('defaults are safe on an empty store', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await AppPreferences.load();
      await p.init();
      expect(p.setupCompleted, isFalse);
      expect(p.displayName, isNull);
      expect(p.localeOption, AppLocaleOption.system);
      expect(p.themeMode, AppThemeMode.system);
      expect(p.accent, AppAccent.periwinkle);
      expect(p.textSize, AppTextSize.system);
      expect(p.motion, AppMotionPref.system);
      expect(p.haptics, AppHapticsPref.on);
      expect(p.experienceMode, ExperienceMode.standard);
    });

    test('setters round-trip through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await AppPreferences.load();
      await p.init();
      await p.completeSetup();
      await p.setDisplayName('Maya');
      await p.setLocale(AppLocaleOption.ar);
      await p.setThemeMode(AppThemeMode.light);
      await p.setAccent(AppAccent.softViolet);
      await p.setTextSize(AppTextSize.extraLarge);
      await p.setMotion(AppMotionPref.reduced);
      await p.setHaptics(AppHapticsPref.off);
      await p.setExperienceMode(ExperienceMode.guided);

      // A fresh instance over the same store sees everything.
      final reloaded = await AppPreferences.load();
      await reloaded.init();
      expect(reloaded.setupCompleted, isTrue);
      expect(reloaded.displayName, 'Maya');
      expect(reloaded.localeOption, AppLocaleOption.ar);
      expect(reloaded.themeMode, AppThemeMode.light);
      expect(reloaded.accent, AppAccent.softViolet);
      expect(reloaded.textSize, AppTextSize.extraLarge);
      expect(reloaded.motion, AppMotionPref.reduced);
      expect(reloaded.haptics, AppHapticsPref.off);
      expect(reloaded.experienceMode, ExperienceMode.guided);
    });

    test('corrupt persisted values fall back to safe defaults', () async {
      SharedPreferences.setMockInitialValues({
        'vg.pref.locale': 'klingon',
        'vg.pref.theme_mode': 'neon',
        'vg.pref.accent': 'rainbow',
        'vg.pref.text_size': 'gigantic',
        'vg.pref.motion': 'warp',
        'vg.pref.haptics': 'loud',
        'vg.pref.experience_mode': 'chaos',
        'vg.pref.display_name': '   ',
      });
      final p = await AppPreferences.load();
      await p.init();
      expect(p.localeOption, AppLocaleOption.system);
      expect(p.themeMode, AppThemeMode.system);
      expect(p.accent, AppAccent.periwinkle);
      expect(p.textSize, AppTextSize.system);
      expect(p.motion, AppMotionPref.system);
      expect(p.haptics, AppHapticsPref.on);
      expect(p.experienceMode, ExperienceMode.standard);
      expect(p.displayName, isNull);
    });

    test('display name trims whitespace and caps at 32 chars', () async {
      await prefs.setDisplayName('  Maya  ');
      expect(prefs.displayName, 'Maya');
      await prefs.setDisplayName('X' * 40);
      expect(prefs.displayName!.length,
          AppPreferences.maxDisplayNameLength);
      await prefs.setDisplayName('   ');
      expect(prefs.displayName, isNull);
    });
  });

  group('Welcome Setup', () {
    testWidgets('fresh install shows Welcome Setup; skip continues '
        'without a name', (tester) async {
      prefs = AppPreferences.inMemory(); // setup not completed
      AppPreferencesLocator.instance = prefs;
      tester.view.physicalSize = const Size(900, 1900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeSetupScreen), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(prefs.setupCompleted, isTrue);
      expect(prefs.displayName, isNull);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('entered name is trimmed, persisted, local-only',
        (tester) async {
      prefs = AppPreferences.inMemory();
      AppPreferencesLocator.instance = prefs;
      tester.view.physicalSize = const Size(900, 1900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Maya  ');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(prefs.displayName, 'Maya');
      expect(prefs.setupCompleted, isTrue);
    });

    testWidgets('language choice applies immediately — Arabic flips '
        'the UI to RTL on the welcome screen itself', (tester) async {
      prefs = AppPreferences.inMemory();
      AppPreferencesLocator.instance = prefs;
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect(prefs.localeOption, AppLocaleOption.ar);
      final context =
          tester.element(find.byType(WelcomeSetupScreen));
      expect(Directionality.of(context), TextDirection.rtl);
      // The Arabic welcome title is rendered, not the English one.
      expect(find.text('Welcome to VoxGuard'), findsNothing);
    });

    testWidgets('no microphone or notification permission is '
        'requested during Welcome Setup', (tester) async {
      var permissionCalls = 0;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          permissionCalls++;
          return null;
        },
      );
      prefs = AppPreferences.inMemory();
      AppPreferencesLocator.instance = prefs;
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeSetupScreen), findsOneWidget);
      expect(permissionCalls, 0);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel(
                  'flutter.baseflow.com/permissions/methods'),
              null);
    });
  });

  group('Theme, accent, text size', () {
    test('theme modes resolve; every accent works in both brightnesses',
        () {
      for (final accent in AppAccent.values) {
        for (final theme in [AppTheme.light(accent), AppTheme.dark(accent)]) {
          final p = theme.extension<AppPalette>()!;
          expect(p.accent,
              AppPalette.accentFor(accent, p.brightness));
        }
      }
    });

    test('semantic safety colors are identical across all accents', () {
      final palettes = [
        for (final a in AppAccent.values) ...[
          AppTheme.light(a).extension<AppPalette>()!,
          AppTheme.dark(a).extension<AppPalette>()!,
        ],
      ];
      for (final p in palettes) {
        for (final q in palettes) {
          if (p.brightness != q.brightness) continue;
          expect(p.statusSafe, q.statusSafe);
          expect(p.statusWarning, q.statusWarning);
          expect(p.statusDanger, q.statusDanger);
          expect(p.signalSemantic, q.signalSemantic);
          expect(p.signalAcoustic, q.signalAcoustic);
        }
      }
    });

    testWidgets('app text-size is a floor — a larger OS scale wins',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(
          tester.platformDispatcher.clearTextScaleFactorTestValue);
      prefs = AppPreferences.inMemory(
          setupCompleted: true, textSize: AppTextSize.large);
      AppPreferencesLocator.instance = prefs;
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();

      final context =
          tester.element(find.byType(Scaffold).first);
      // OS 1.5 > app floor 1.18 → OS wins; never shrunk.
      expect(MediaQuery.textScalerOf(context).scale(1.0), 1.5);
    });

    testWidgets('app text-size floor applies when OS is smaller',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.0;
      addTearDown(
          tester.platformDispatcher.clearTextScaleFactorTestValue);
      prefs = AppPreferences.inMemory(
          setupCompleted: true, textSize: AppTextSize.extraLarge);
      AppPreferencesLocator.instance = prefs;
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();

      final context =
          tester.element(find.byType(Scaffold).first);
      expect(MediaQuery.textScalerOf(context).scale(1.0), 1.35);
    });
  });

  group('Motion and haptics', () {
    testWidgets('app reduced-motion preference sets disableAnimations',
        (tester) async {
      prefs = AppPreferences.inMemory(
          setupCompleted: true, motion: AppMotionPref.reduced);
      AppPreferencesLocator.instance = prefs;
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();
      final context =
          tester.element(find.byType(Scaffold).first);
      expect(MediaQuery.of(context).disableAnimations, isTrue);
    });

    testWidgets('OS reduced-motion wins even with app pref on system',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(const VoxGuardApp());
      await tester.pumpAndSettle();
      final context =
          tester.element(find.byType(Scaffold).first);
      expect(MediaQuery.of(context).disableAnimations, isTrue);
    });

    testWidgets('haptics off suppresses every wrapper call', (tester) async {
      var calls = 0;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls++;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      final off = AppPreferences.inMemory(haptics: AppHapticsPref.off);
      AppHaptics.confirm(off);
      AppHaptics.tap(off);
      AppHaptics.alert(off);
      await tester.pump();
      expect(calls, 0);

      final on = AppPreferences.inMemory(haptics: AppHapticsPref.on);
      AppHaptics.confirm(on);
      await tester.pump();
      expect(calls, 1);
    });
  });

  group('Guided Mode', () {
    testWidgets('guided enlarges SafeCall mode-card affordances; risk '
        'behavior unchanged', (tester) async {
      Future<double> iconBoxSize(ExperienceMode mode) async {
        AppPreferencesLocator.instance = AppPreferences.inMemory(
            setupCompleted: true, experienceMode: mode);
        await tester.pumpWidget(
            localizedShell(const SafeCallScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final iconBox = find.byWidgetPredicate((w) =>
            w is Container &&
            w.constraints != null &&
            (w.constraints!.maxWidth == 50 ||
                w.constraints!.maxWidth == 60));
        expect(iconBox, findsWidgets);
        return tester.getSize(iconBox.first).width;
      }

      final standard = await iconBoxSize(ExperienceMode.standard);
      final guided = await iconBoxSize(ExperienceMode.guided);
      expect(standard, 50);
      expect(guided, 60);
    });
  });

  group('Family Shield payload privacy', () {
    test('local display name never enters the alert payload', () async {
      AppPreferencesLocator.instance =
          AppPreferences.inMemory(displayName: 'Maya Secret');

      http.Request? captured;
      final client = http_testing.MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 202);
      });
      final service = FamilyShieldAlertService(
        httpClient: client,
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: () async => 'vg_${'0'*32}',
        productAccess: FakeProductAccess(TierId.familyVault),
      );

      final incident = IncidentReport(
        id: 'INC-PRIV',
        timestamp: DateTime(2026, 9, 20),
        callerLabel: 'Unknown Caller',
        callDurationSeconds: 60,
        audioDigestSha256: 'ff' * 32,
        audioSourceLabel: 'Test',
        transcriptionSourceLabel: 'Test',
        peakRiskScore: 0.9,
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
        recommendedActions: const [],
      );
      await service.triggerFamilyEmergencyAlert(
        incident: incident,
        familyMemberIds: ['vg_${'1'*32}'],
      );

      expect(captured, isNotNull);
      expect(captured!.body, isNot(contains('Maya')));
      expect(captured!.body, isNot(contains('display_name')));
    });
  });

  group('Locale rendering', () {
    testWidgets('Home renders in each supported locale at 360px + 1.5x '
        'without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      for (final code in ['en', 'ar', 'es', 'fr']) {
        AppPreferencesLocator.instance =
            AppPreferences.inMemory(setupCompleted: true);
        await tester.pumpWidget(
            localizedShell(const HomeScreen(), locale: Locale(code)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull,
            reason: 'locale $code overflowed');
      }
    });

    testWidgets('Arabic home directionality is RTL', (tester) async {
      await tester.pumpWidget(localizedShell(const HomeScreen(),
          locale: const Locale('ar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final context = tester.element(find.byType(HomeScreen));
      expect(Directionality.of(context), TextDirection.rtl);
    });
  });
}
