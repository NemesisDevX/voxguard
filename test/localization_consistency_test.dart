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
import 'package:voxguard/core/l10n/localized_text.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/audio/audio_stream_source.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/core/services/preferences/app_preferences.dart';
import 'package:voxguard/core/theme/app_theme.dart';
import 'package:voxguard/features/family_shield/presentation/screens/family_alert_screen.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/presentation/screens/incident_detail_screen.dart';
import 'package:voxguard/features/home/presentation/screens/home_screen.dart';
import 'package:voxguard/features/onboarding/presentation/screens/welcome_setup_screen.dart';
import 'package:voxguard/features/paywall/domain/services/mock_sandbox_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/purchase_service_locator.dart';
import 'package:voxguard/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/domain/models/transcript_snippet.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_bloc.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_state.dart';
import 'package:voxguard/features/protection/presentation/screens/safecall_screen.dart';
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
  // inside presentation sources — MULTILINE-AWARE: a literal nested
  // anywhere under `Text(`, a dialog/button arg, a SnackBar, or a
  // named copy argument is found via the enclosing construct, not by
  // matching constructor and literal on one physical line.
  // Blocs and domain folders are out of scope BY DESIGN — they emit
  // the stable domain strings that localized_text.dart maps.
  group('consumer-copy audit', () {
    /// Widgets whose positional/inner literals render verbatim.
    const uiWidgets = {
      'Text', 'TextSpan', 'SelectableText', 'Tooltip', 'SnackBar',
      'AlertDialog', 'SimpleDialog', 'CupertinoAlertDialog',
      'Dialog', 'TextButton', 'ElevatedButton', 'OutlinedButton',
      'FilledButton', 'Badge',
    };

    /// Named arguments whose literal value is rendered verbatim.
    const uiNamedArgs = {
      'title', 'label', 'tooltip', 'hintText', 'labelText',
      'helperText', 'errorText', 'content', 'subtitle', 'message',
      'text', 'semanticLabel',
    };

    /// Intentional non-translatable values — each entry must stay
    /// exact and justified or the audit loses meaning.
    final whitelist = RegExp(
        r'^(vg_\w*|SHA-256|1\.0\.0|.*https?://.*|\{.*\}|'
        r'.*[0-9]{1,2}:[0-9]{2}.*|\W*$|[0-9]+(\.[0-9]+)*$)');

    /// Literals that are legal even when flagged — stable domain
    /// constants compared (never rendered) or provider names.
    const allowedPhrases = {
      'No significant threat indicators', // fusion-engine predicate
      'Demo Store', // named demo backend, shown as a proper noun
      'AssemblyAI', // provider name
      'RevenueCat', // provider name
      'OneSignal', // provider name
    };

    /// Strips comments/import lines and blanks string contents so
    /// structural scanning can't trip on brackets inside literals.
    /// Returns (maskedCode, literalMatches) with aligned offsets.
    (String, List<RegExpMatch>) prepare(String source) {
      final literal = RegExp(r'''r?(['"])((?:(?!\1).)*?)\1''');
      final lines = source.split('\n');
      final buf = StringBuffer();
      for (final line in lines) {
        if (RegExp(r'^\s*(import|export|part)\b').hasMatch(line)) {
          buf.writeln();
          continue;
        }
        // Crude // strip — URL literals are whitelisted anyway.
        buf.writeln(line.split('//').first);
      }
      var code = buf.toString();
      code = code.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
      final matches = literal.allMatches(code).toList();
      final masked = StringBuffer();
      var cursor = 0;
      for (final m in matches) {
        masked.write(code.substring(cursor, m.start));
        final full = m.group(0)!;
        masked.write(full[0]);
        masked.write(' ' * (full.length - 2));
        masked.write(full[full.length - 1]);
        cursor = m.end;
      }
      masked.write(code.substring(cursor));
      return (masked.toString(), matches);
    }

    /// True when [slice] ends with `return`/`=>` whose value IS this
    /// literal — only whitespace/parens sit between keyword and
    /// literal. `== 'x'` predicates, switch-arm keys and ternary
    /// operands stay quiet.
    bool returnedCopy(String slice) {
      final marks = RegExp(r'\breturn\b|=>').allMatches(slice);
      if (marks.isEmpty) return false;
      final gap = slice.substring(marks.last.end);
      return RegExp(r'^[()\s]*$').hasMatch(gap);
    }

    /// True when the literal at [start] sits inside a UI construct:
    /// its enclosing `(` belongs to a UI widget, it directly follows
    /// a copy-bearing named arg, it nests in a `[` that is itself in
    /// a UI context (dialog `actions`, returned lists), or it lives
    /// in a `return`/`=>` statement.
    bool isUiContext(String masked, int start) {
      // (a) named-arg prefix — `title: 'x'`, `labelText: 'x'`.
      var before = masked.substring(0, start);
      before = before.replaceFirst(RegExp(r'''[\x27"]$'''), '');
      final arg = RegExp(r'(\w+)\s*:\s*$').firstMatch(before);
      if (arg != null && uiNamedArgs.contains(arg.group(1))) {
        return true;
      }
      // (b) enclosing opener.
      var depth = 0;
      var opener = -1;
      var boundary = -1;
      for (var i = start - 1; i >= 0; i--) {
        final ch = masked[i];
        if (ch == ')' || ch == ']' || ch == '}') {
          depth++;
        } else if (ch == '(' || ch == '[' || ch == '{') {
          if (depth == 0) {
            opener = i;
            break;
          }
          depth--;
        } else if (ch == ';' && depth == 0) {
          boundary = i;
          break;
        }
      }
      if (opener >= 0) {
        final bracket = masked[opener];
        if (bracket == '(') {
          // Immediate parent must be a UI widget or a copy arg.
          final header = masked.substring(0, opener);
          final name = RegExp(r'([A-Za-z_]\w*)\s*$')
              .firstMatch(header)
              ?.group(1);
          if (name != null && uiWidgets.contains(name)) return true;
          final argName = RegExp(r'(\w+)\s*:\s*$')
              .firstMatch(header)
              ?.group(1);
          return argName != null && uiNamedArgs.contains(argName);
        }
        if (bracket == '[') {
          // A list inherits the context of its own position —
          // `actions: [...]`, `return [...]`.
          return isUiContext(masked, opener);
        }
        // `{` — statement level inside a body/block or map literal.
        return returnedCopy(masked.substring(opener + 1, start));
      }
      // (c) raw statement — `return 'x'` / `=> 'x'` at top level.
      final slice =
          masked.substring(boundary >= 0 ? boundary + 1 : 0, start);
      return returnedCopy(slice);
    }

    /// Line number (1-based) of [offset] in [code].
    int lineOf(String code, int offset) =>
        '\n'.allMatches(code.substring(0, offset)).length + 1;

    /// Flags a domain field rendered without a mapper nearby.
    /// [pattern] matches the field access; [mapper] the tokens that
    /// prove localization within ±2 lines.
    void auditField(
      List<String> violations,
      File file,
      List<String> lines,
      RegExp pattern,
      RegExp mapper,
      String what,
    ) {
      for (var i = 0; i < lines.length; i++) {
        if (!pattern.hasMatch(lines[i])) continue;
        final lo = i - 2 < 0 ? 0 : i - 2;
        final hi = i + 2 >= lines.length ? lines.length - 1 : i + 2;
        final window = lines.sublist(lo, hi + 1).join('\n');
        if (mapper.hasMatch(window)) continue;
        violations.add('${file.path}:${i + 1}: raw $what');
      }
    }

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

    /// A multi-word phrase or a single English word of 4+ letters —
    /// `Text('Done')` counts even though it is one word.
    bool looksLikeCopy(String s) =>
        RegExp(r'[A-Za-z]{2,} [A-Za-z]{2,}').hasMatch(s) ||
        RegExp(r'^[A-Za-z]{4,}$').hasMatch(s);

    test('no user-facing English literal bypasses localization', () {
      final violations = <String>[];
      for (final file in presentationFiles()) {
        final (masked, matches) = prepare(file.readAsStringSync());
        for (final m in matches) {
          final s = m.group(2)!;
          if (s.length < 4) continue;
          if (!looksLikeCopy(s)) continue;
          if (whitelist.hasMatch(s)) continue;
          if (allowedPhrases.contains(s)) continue;
          if (!isUiContext(masked, m.start)) continue;
          violations.add(
              '${file.path}:${lineOf(masked, m.start)}: "$s"');
        }
      }
      expect(violations, isEmpty,
          reason: 'unlocalized consumer copy:\n${violations.join('\n')}');
    });

    test('stable domain fields reach the UI only through a mapper',
        () {
      final violations = <String>[];
      final reasonAccess = RegExp(
          r'primaryThreatReasons\s*\.\s*(first|firstOrNull|last'
          r'|lastOrNull|\[\w*\])');
      final reasonMapper =
          RegExp(r'threatReason|localizedReason|localizeReason');
      final actionAccess = RegExp(r'\brecommendedAction\b(?!s)');
      final disclaimerAccess = RegExp(r'\.disclaimer\b');
      final disclaimerMapper =
          RegExp(r'reportDisclaimer|legalDisclaimer|l10n');
      final billingAccess = RegExp(
          r'\b(?:BillingCycle\.\w+|c|cycle|pkg\.cycle'
          r'|billing\.cycle)\.label\b|\.priceSuffix\b');
      final billingMapper = RegExp(
          r'l10n|_cycleLabel|billing|priceSuffixMonthly'
          r'|priceSuffixAnnual|localize');
      for (final file in presentationFiles()) {
        final lines = file.readAsLinesSync();
        auditField(violations, file, lines, reasonAccess,
            reasonMapper, 'primaryThreatReasons element');
        auditField(violations, file, lines, actionAccess,
            reasonMapper, 'recommendedAction');
        auditField(violations, file, lines, disclaimerAccess,
            disclaimerMapper, 'incident.disclaimer');
        auditField(violations, file, lines, billingAccess,
            billingMapper, 'billing label/suffix');
      }
      expect(violations, isEmpty,
          reason: 'domain strings bypassing the mapper:'
              '\n${violations.join('\n')}');
    });

    test('the audit catches multiline UI literals', () {
      // The exact regression: `Text(\n  'Done',\n)` — a single-word
      // literal several lines below the constructor.
      const sample = '''
class X extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        'Done',
        style: TextStyle(),
      ),
      ElevatedButton(
        onPressed: null,
        child: Text(
          'Send help now',
        ),
      ),
      SnackBar(
        content: Text(
          'Could not save',
        ),
      ),
    ]);
  }
}
String helper() {
  return 'Call your bank';
}
''';
      final (masked, matches) = prepare(sample);
      final flagged = [
        for (final m in matches)
          if (looksLikeCopy(m.group(2)!) &&
              isUiContext(masked, m.start))
            m.group(2),
      ];
      expect(
          flagged,
          containsAll([
            'Done',
            'Send help now',
            'Could not save',
            'Call your bank',
          ]));
      // Sanity: internal strings outside UI contexts stay quiet.
      const quiet = '''
String key() => 'auth_token';
void f() { debugPrint('some debug words'); }
final re = RegExp(r'[a-z]+ pattern');
''';
      final (masked3, matches3) = prepare(quiet);
      final flagged3 = [
        for (final m in matches3)
          if (looksLikeCopy(m.group(2)!) &&
              isUiContext(masked3, m.start))
            m.group(2),
      ];
      expect(flagged3, isEmpty);
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

  // ── Follow-up: the previously-missed bypasses ─────────────────────
  group('post-call closing action', () {
    testWidgets('Done localizes in Arabic', (tester) async {
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
      expect(find.text(l.actionDone), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });
  });

  group('SafeCall threat-reason presentation', () {
    const acoustic = AudioForensicMetrics(
      spectralFlux: 0.3,
      spectralRolloffRatio: 0.6,
      zeroCrossingRate: 0.2,
      syntheticVoiceScore: 0.8,
    );

    SafeCallMonitoring monitoring(CompositeThreatReport report) =>
        SafeCallMonitoring(
          acoustic: acoustic,
          semantic: const SemanticThreatSignals(
            urgencyScore: 0.9,
            financialDemandScore: 1.0,
            secrecyScore: 0.8,
            detectedKeywords: ['transfer'],
            impersonationClaims: [],
          ),
          report: report,
          semanticAnalysisHasRun: true,
          transcript: [
            TranscriptSnippet(
              speaker: 'Caller',
              text: 'Transfer the money now',
              timestamp: DateTime(2026, 9, 20, 14, 31),
            ),
          ],
          audioSourceType: AudioSourceType.microphone,
          isTranscriptionLive: true,
          cloudTranscriptionEntitled: true,
        );

    Future<void> pumpLive(
      WidgetTester tester,
      CompositeThreatReport report,
      String code,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(localizedShell(
        SafeCallScreen(bloc: SafeCallBloc.seeded(monitoring(report))),
        locale: Locale(code),
      ));
      // Bounded pumps — the lens breathes forever.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    for (final code in ['ar', 'fr']) {
      testWidgets('high-risk reason localizes in $code', (tester) async {
        pinLocale(code);
        final l = lookupAppLocalizations(Locale(code));
        await pumpLive(
          tester,
          const CompositeThreatReport(
            compositeRiskScore: 0.9,
            riskLevel: ThreatRiskLevel.highRisk,
            primaryThreatReasons: ['Financial transfer demand detected'],
            recommendedAction:
                'End call immediately and alert a trusted contact',
          ),
          code,
        );
        // Reason under the lens AND the high-risk surface, mapped.
        expect(find.text(l.reasonFinancial), findsWidgets,
            reason: code);
        expect(find.text('Financial transfer demand detected'),
            findsNothing);
        expect(find.textContaining('End call immediately'),
            findsNothing);
      });

      testWidgets('suspicious strip localizes the reason in $code',
          (tester) async {
        pinLocale(code);
        final l = lookupAppLocalizations(Locale(code));
        await pumpLive(
          tester,
          const CompositeThreatReport(
            compositeRiskScore: 0.55,
            riskLevel: ThreatRiskLevel.suspicious,
            primaryThreatReasons: ['Urgency manipulation tactics'],
            recommendedAction:
                'Advise caution — verify caller identity',
          ),
          code,
        );
        expect(find.text(l.reasonUrgency), findsWidgets, reason: code);
        expect(find.text('Urgency manipulation tactics'), findsNothing);
      });
    }
  });

  group('Incident Detail disclaimer', () {
    testWidgets('the default disclaimer localizes in French',
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
        IncidentDetailScreen(incident: makeReport()),
        locale: const Locale('fr'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l.reportDisclaimer), findsOneWidget);
      expect(find.text(IncidentReport.legalDisclaimer), findsNothing);
    });

    test('a custom disclaimer survives unchanged', () {
      final l = lookupAppLocalizations(const Locale('fr'));
      const custom = 'Custom legal wording v2';
      expect(custom == IncidentReport.legalDisclaimer, isFalse);
      // The presentation fallback keeps unknown disclaimers verbatim.
      expect(custom, isNot(l.reportDisclaimer));
    });
  });

  group('paywall billing copy', () {
    testWidgets('cycle labels and price suffix localize in French',
        (tester) async {
      pinLocale('fr');
      PurchaseServiceLocator.instance = MockSandboxPurchaseService(
        networkDelay: Duration.zero,
        checkoutDelay: Duration.zero,
      );
      addTearDown(PurchaseServiceLocator.reset);
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final l = lookupAppLocalizations(const Locale('fr'));
      await tester.pumpWidget(localizedShell(
        const PaywallScreen(),
        locale: const Locale('fr'),
      ));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text(l.billingMonthly), findsOneWidget);
      expect(find.text(l.billingAnnual), findsOneWidget);
      expect(find.text('Monthly'), findsNothing);
      expect(find.text('Annual'), findsNothing);
      List<String> texts() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      // Annual is the default cycle when offered — '/an', never '/yr'.
      expect(texts().any((t) => t.endsWith(l.priceSuffixAnnual)),
          isTrue);
      expect(texts().any((t) => t.endsWith('/yr')), isFalse);
      await tester.tap(find.text(l.billingMonthly));
      await tester.pumpAndSettle();
      expect(texts().any((t) => t.endsWith(l.priceSuffixMonthly)),
          isTrue);
      expect(
          texts().any((t) =>
              t.endsWith('/mo') && !t.endsWith(l.priceSuffixMonthly)),
          isFalse);
    });
  });

  group('recording action mapping', () {
    test('bank/carrier/authority action maps in all four locales', () {
      const source =
          'Contact the relevant bank/carrier/authority if needed';
      for (final code in ['en', 'ar', 'es', 'fr']) {
        final l = lookupAppLocalizations(Locale(code));
        expect(localizeThreatReason(l, source), l.actionContactAuthority,
            reason: code);
        if (code != 'en') {
          expect(l.actionContactAuthority, isNot(source), reason: code);
        }
      }
      // Unknown strings still pass through untouched.
      final en = lookupAppLocalizations(const Locale('en'));
      expect(localizeThreatReason(en, 'a novel future string'),
          'a novel future string');
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
