// Localization consistency — source audit plus behavioral coverage:
// no consumer-facing literal bypasses ARB, share reports localize
// fully per current locale, Home reacts to display-name edits, and
// preference writes never claim persistence they did not earn.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voxguard/l10n/generated/app_localizations.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/core/services/preferences/app_preferences.dart';
import 'package:voxguard/core/theme/app_theme.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_alert_screen.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/presentation/screens/incident_detail_screen.dart';
import 'package:voxguard/features/home/presentation/screens/home_screen.dart';
import 'package:voxguard/features/onboarding/presentation/screens/welcome_setup_screen.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_state.dart';
import 'package:voxguard/features/protection/presentation/widgets/post_call_safety_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferences prefs;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferences.inMemory(setupCompleted: true);
    AppPreferencesLocator.instance = prefs;
  });

  /// Mirrors production wiring: `MaterialApp.locale` is driven by the
  /// pinned preference, so context-free `l10n` reads (domain getters,
  /// service strings) agree with the widget tree.
  void pinLocale(String code) {
    prefs = AppPreferences.inMemory(
      setupCompleted: true,
      locale: AppLocaleOption.values.byName(code),
    );
    AppPreferencesLocator.instance = prefs;
  }

  Widget localizedShell(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.dark(),
      home: child,
    );
  }

  IncidentReport makeReport({bool partial = false}) => IncidentReport(
        id: 'INC-2026-0001',
        timestamp: DateTime(2026, 9, 20, 14, 30),
        callerLabel: 'Unknown Caller (+20 10 ••• ••42)',
        callDurationSeconds: 195,
        audioDigestSha256: 'ab' * 32,
        audioSourceLabel: 'Live Microphone',
        transcriptionSourceLabel: 'AssemblyAI Streaming',
        peakRiskScore: 0.91,
        riskLevel: ThreatRiskLevel.highRisk,
        threatReasons: const [
          'Financial transfer demand detected',
          'Urgency manipulation tactics',
        ],
        acousticMetrics: const AudioForensicMetrics(
          spectralFlux: 0.04,
          spectralRolloffRatio: 0.07,
          zeroCrossingRate: 0.024,
          syntheticVoiceScore: 0.7,
        ),
        semanticSignals: const SemanticThreatSignals(
          urgencyScore: 0.8,
          financialDemandScore: 1.0,
          secrecyScore: 0.8,
          detectedKeywords: ['transfer'],
          impersonationClaims: [],
        ),
        transcriptSnippets: const [],
        recommendedActions: const [
          'End the call immediately',
          'Do not share OTPs, PINs or banking details',
        ],
        analysisIsPartial: partial,
      );

  // ── Source audit ──────────────────────────────────────────────────
  //
  // Flags English-looking multi-word literals in UI-bearing contexts
  // (Text, label/title/tooltip/content args, SnackBar/dialog copy,
  // `return`/`=>` string positions) inside presentation sources.
  // Blocs and domain folders are out of scope BY DESIGN — they emit
  // the stable domain strings that localized_text.dart maps.
  group('consumer-copy audit', () {
    final uiContext = RegExp(
        r'(Text\(|title:\s|label:\s|tooltip:\s|hintText:\s|labelText:\s'
        r'|helperText:\s|content:\s|subtitle:\s|message:\s|return\s|=>)');
    final literal = RegExp(r'''r?(['"])((?:(?!\1).)*?)\1''');
    final englishWords = RegExp(r'[A-Za-z]{2,} [A-Za-z]{2,}');

    /// Intentional non-translatable values — each entry must stay
    /// justified or the audit loses meaning.
    final whitelist = RegExp(
        r'^(vg_|SHA-256|[A-Z0-9_ .:/\-]*$|.*https?://.*|\{.*\}|'
        r'.*[0-9]{2}:[0-9]{2}.*|\W*$)');

    /// Literals that are legal even when flagged — stable domain
    /// constants compared (never rendered) or provider names.
    const allowedPhrases = {
      'No significant threat indicators', // fusion-engine predicate
    };

    Iterable<File> presentationFiles() sync* {
      final features = Directory('lib/features');
      for (final e in features.listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final p = e.path.replaceAll('\\', '/');
        if (!p.contains('/presentation/')) continue;
        // Blocs emit domain strings — they are mapper input, not UI.
        if (p.contains('/presentation/bloc/') ||
            p.contains('/presentation/cubit/')) {
          continue;
        }
        yield e;
      }
      for (final e
          in Directory('lib/core/widgets').listSync(recursive: true)) {
        if (e is File && e.path.endsWith('.dart')) yield e;
      }
      yield File('lib/main.dart');
    }

    test('no user-facing English literal bypasses localization', () {
      final violations = <String>[];
      for (final file in presentationFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final raw = lines[i];
          if (RegExp(r'^\s*(import|export|part)\b').hasMatch(raw)) {
            continue;
          }
          // Strip // line comments before scanning.
          final code = raw.split('//').first;
          if (!uiContext.hasMatch(code)) continue;
          for (final m in literal.allMatches(code)) {
            final s = m.group(2)!;
            if (s.length < 4) continue;
            if (!englishWords.hasMatch(s)) continue;
            if (whitelist.hasMatch(s)) continue;
            if (allowedPhrases.contains(s)) continue;
            violations.add('${file.path}:${i + 1}: "$s"');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'unlocalized consumer copy:\n${violations.join('\n')}');
    });
  });

  // ── Share report ──────────────────────────────────────────────────
  group('localized share report', () {
    for (final code in ['en', 'ar', 'es', 'fr']) {
      test('renders fully localized in $code', () {
        pinLocale(code);
        final l = lookupAppLocalizations(Locale(code));
        final text = makeReport().toShareText();

        // Shell + every mapped domain string rendered in-locale.
        expect(text, contains(l.incidentReportTitle));
        expect(text, contains(l.bandHigh));
        expect(text, contains(l.reasonFinancial));
        expect(text, contains(l.reasonUrgency));
        expect(text, contains(l.sourceLiveMic));
        expect(text, contains(l.sourceAssemblyAiStreaming));
        expect(text, contains(l.callerUnknown));
        expect(text, contains(l.reportDisclaimer));

        // Raw domain/persisted English must not leak in non-English
        // locales; stable identifiers always survive verbatim.
        if (code != 'en') {
          expect(text, isNot(contains('highRisk')));
          expect(text,
              isNot(contains('Financial transfer demand detected')));
          expect(text, isNot(contains('Live Microphone')));
          expect(text, isNot(contains('AssemblyAI Streaming')));
          expect(text, isNot(contains('AI-generated forensic')));
        }
        expect(text, contains('INC-2026-0001'));
        expect(text, contains('ab' * 32));
        expect(text, contains('91/100'));
      });
    }

    test('persisted incident shares in the NEW locale after switch',
        () async {
      final incident = makeReport();
      AppPreferencesLocator.instance =
          AppPreferences.inMemory(locale: AppLocaleOption.en);
      final en = incident.toShareText();
      expect(en, contains('HIGH RISK'));

      await AppPreferencesLocator.instance
          .setLocale(AppLocaleOption.fr);
      final fr = incident.toShareText();
      final frL10n = lookupAppLocalizations(const Locale('fr'));
      expect(fr, contains(frL10n.bandHigh));
      expect(fr, contains(frL10n.reportDisclaimer));
      expect(fr, isNot(contains('HIGH RISK')));
      // The stored record itself is unchanged — same object, stable
      // English fields, only the rendered share text localized.
      expect(incident.riskLevel, ThreatRiskLevel.highRisk);
      expect(incident.threatReasons.first,
          'Financial transfer demand detected');
    });
  });

  // ── Home name reactivity ──────────────────────────────────────────
  group('Home display-name reactivity', () {
    testWidgets('edits and clears apply without navigation',
        (tester) async {
      await tester.pumpWidget(localizedShell(const HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await prefs.setDisplayName('Maya');
      await tester.pump();
      expect(find.textContaining('Maya'), findsOneWidget);

      await prefs.setDisplayName('Lina');
      await tester.pump();
      expect(find.textContaining('Lina'), findsOneWidget);
      expect(find.textContaining('Maya'), findsNothing);

      await prefs.setDisplayName('');
      await tester.pump();
      expect(find.textContaining('Lina'), findsNothing);
    });
  });

  // ── Family Alert placeholders ─────────────────────────────────────
  group('Family Alert localization', () {
    final contact = FamilyContact(
      id: 'fc_aaaa1111bbbb2222',
      name: 'Maya',
      externalId: 'vg_${'a' * 32}',
      trustedPhone: '+20 100 123 4567',
      updatedAt: DateTime(2026),
    );

    for (final code in ['en', 'ar', 'es', 'fr']) {
      testWidgets('headline + call action localized in $code',
          (tester) async {
        pinLocale(code);
        final l = lookupAppLocalizations(Locale(code));
        final alert = ReceivedFamilyAlert(
          incidentId: 'INC-1',
          senderExternalId: contact.externalId,
          riskLevel: 'highRisk',
          receivedAt: DateTime(2026, 9, 20),
        );
        await tester.pumpWidget(localizedShell(
          FamilyAlertScreen(alert: alert, sender: contact),
          locale: Locale(code),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(l.familyAlertHighRisk('Maya')), findsOneWidget,
            reason: code);
        expect(find.text(l.familyCallAction('Maya')), findsOneWidget,
            reason: code);
      });
    }

    testWidgets('partial-scope alert uses the acoustic warning copy',
        (tester) async {
      pinLocale('es');
      final l = lookupAppLocalizations(const Locale('es'));
      final alert = ReceivedFamilyAlert(
        incidentId: 'INC-2',
        senderExternalId: contact.externalId,
        riskLevel: 'highRisk',
        receivedAt: DateTime(2026, 9, 20),
        analysisScope: 'partial',
      );
      await tester.pumpWidget(localizedShell(
        FamilyAlertScreen(alert: alert, sender: contact),
        locale: const Locale('es'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l.familyAlertAcoustic('Maya')), findsOneWidget);
      expect(find.text(l.familyAlertHighRisk('Maya')), findsNothing);
    });
  });

  // ── Incident Detail localization ──────────────────────────────────
  group('Incident Detail localization', () {
    testWidgets('actions and partial copy render in French',
        (tester) async {
      pinLocale('fr');
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final l = lookupAppLocalizations(const Locale('fr'));
      await tester.pumpWidget(localizedShell(
        IncidentDetailScreen(incident: makeReport(partial: true)),
        locale: const Locale('fr'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l.incidentShare), findsOneWidget);
      expect(find.text(l.conversationNotAnalyzed), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l.incidentDeleteTitle), findsOneWidget);
      expect(find.text(l.actionDelete), findsOneWidget);
      expect(find.text(l.actionCancel), findsOneWidget);
    });
  });

  // ── Post-call Family Alert ────────────────────────────────────────
  group('post-call Family Alert', () {
    testWidgets('send action localizes in Arabic', (tester) async {
      pinLocale('ar');
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final l = lookupAppLocalizations(const Locale('ar'));
      await tester.pumpWidget(localizedShell(
        Scaffold(
          body: PostCallSafetySheet(
            result: SafeCallEnded(
              peakRiskLevel: ThreatRiskLevel.highRisk,
              incident: makeReport(),
            ),
          ),
        ),
        locale: const Locale('ar'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // No relay configured in tests → Demo Mode label; the real
      // `postCallSendFamilyAlert` path renders when a relay exists.
      expect(find.text(l.sendDemoFamilyAlert), findsOneWidget);
      // The non-demo label is localized too — not a raw English leak.
      expect(l.postCallSendFamilyAlert, isNot(contains('Send')));
    });
  });

  // ── Free-tier price label ─────────────────────────────────────────
  group('paywall Free label', () {
    test('planFreeLabel differs across locales', () {
      expect(lookupAppLocalizations(const Locale('en')).planFreeLabel,
          'Free');
      expect(lookupAppLocalizations(const Locale('es')).planFreeLabel,
          'Gratis');
      expect(lookupAppLocalizations(const Locale('fr')).planFreeLabel,
          'Gratuit');
      expect(lookupAppLocalizations(const Locale('ar')).planFreeLabel,
          isNot('Free'));
    });
  });

  // ── Preference write truthfulness ─────────────────────────────────
  group('preference persistence truthfulness', () {
    test('a failed write mutates nothing and returns false', () async {
      final p = AppPreferences.withStore(_FailingStore());
      var notified = 0;
      p.addListener(() => notified++);

      expect(await p.setDisplayName('Maya'), isFalse);
      expect(p.displayName, isNull);
      expect(await p.setThemeMode(AppThemeMode.dark), isFalse);
      expect(p.themeMode, AppThemeMode.system);
      expect(await p.setLocale(AppLocaleOption.ar), isFalse);
      expect(p.localeOption, AppLocaleOption.system);
      expect(await p.completeSetup(), isFalse);
      expect(p.setupCompleted, isFalse);
      expect(notified, 0);
    });

    test('a throwing store is contained — same contract', () async {
      final p = AppPreferences.withStore(_FailingStore(throws: true));
      expect(await p.setHaptics(AppHapticsPref.off), isFalse);
      expect(p.haptics, AppHapticsPref.on);
    });

    test('in-memory instances always persist trivially', () async {
      expect(await prefs.setDisplayName('Maya'), isTrue);
      expect(prefs.displayName, 'Maya');
    });

    testWidgets('Welcome Setup stays and reports when persistence '
        'fails', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final failing = AppPreferences.withStore(_FailingStore());
      AppPreferencesLocator.instance = failing;
      var done = false;
      await tester.pumpWidget(localizedShell(
        WelcomeSetupScreen(onDone: () => done = true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(failing.setupCompleted, isFalse);
      expect(done, isFalse);
      expect(find.byType(WelcomeSetupScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

/// Deterministic write-failure backend for [AppPreferences.withStore].
final class _FailingStore implements PrefsStore {
  _FailingStore({this.throws = false});
  final bool throws;
  int writeAttempts = 0;

  Future<bool> _fail() {
    writeAttempts++;
    if (throws) throw StateError('simulated io failure');
    return Future.value(false);
  }

  @override
  Future<bool?> getBool(String k) async => null;
  @override
  Future<String?> getString(String k) async => null;
  @override
  Future<bool> setBool(String k, bool v) => _fail();
  @override
  Future<bool> setString(String k, String v) => _fail();
  @override
  Future<bool> remove(String k) => _fail();
}
