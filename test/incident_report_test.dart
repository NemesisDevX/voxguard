import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/l10n/generated/app_localizations.dart';
import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/family/family_shield_response.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/presentation/screens/incident_detail_screen.dart';
import 'package:voxguard/features/forensics/presentation/screens/incidents_history_screen.dart';
import 'package:voxguard/features/forensics/domain/services/incident_repository.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';

void main() {
  /// Acoustic-only uploaded-recording record — the kind Analyze
  /// Recording persists when no transcript exists.
  IncidentReport makePartial() => IncidentReport(
        id: 'INC-2026-0777',
        timestamp: DateTime(2026, 9, 21, 9, 15),
        callerLabel: 'Uploaded Recording',
        callDurationSeconds: 42,
        audioDigestSha256: 'cd' * 32,
        audioSourceLabel: 'Uploaded Recording',
        transcriptionSourceLabel: 'None — acoustic analysis only',
        peakRiskScore: 0.84,
        riskLevel: ThreatRiskLevel.suspicious,
        threatReasons: const [
          'Elevated acoustic anomalies — conversation-risk signals '
              'were not analyzed',
        ],
        acousticMetrics: const AudioForensicMetrics(
          spectralFlux: 0.04,
          spectralRolloffRatio: 0.07,
          zeroCrossingRate: 0.024,
          syntheticVoiceScore: 0.84,
        ),
        semanticSignals: const SemanticThreatSignals.empty(),
        transcriptSnippets: const [],
        recommendedActions: const ['Verify the speaker'],
        analysisIsPartial: true,
      );

  /// A FULL recording analysis (had a real transcript) — recording
  /// provenance but a complete fused verdict.
  IncidentReport makeRecordingFull() => IncidentReport(
        id: 'INC-2026-0888',
        timestamp: DateTime(2026, 9, 21, 10),
        callerLabel: 'Uploaded Recording',
        callDurationSeconds: 95,
        audioDigestSha256: 'ef' * 32,
        audioSourceLabel: 'Uploaded Recording',
        transcriptionSourceLabel: 'AssemblyAI Pre-recorded',
        peakRiskScore: 0.91,
        riskLevel: ThreatRiskLevel.highRisk,
        threatReasons: const ['Financial transfer demand detected'],
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
        recommendedActions: const ['Verify the speaker'],
      );

  IncidentReport makeReport({String id = 'INC-2026-0001'}) => IncidentReport(
        id: id,
        timestamp: DateTime(2026, 9, 20, 14, 30),
        callerLabel: 'Unknown Caller (+20 10 ••• ••42)',
        callDurationSeconds: 195,
        audioDigestSha256: 'ab' * 32,
        audioSourceLabel: 'Generated Demo Audio',
        transcriptionSourceLabel: 'Local Demo Transcript',
        peakRiskScore: 0.92,
        riskLevel: ThreatRiskLevel.highRisk,
        threatReasons: const ['Financial transfer demand detected'],
        acousticMetrics: const AudioForensicMetrics(
          spectralFlux: 0.04,
          spectralRolloffRatio: 0.07,
          zeroCrossingRate: 0.024,
          syntheticVoiceScore: 0.84,
        ),
        semanticSignals: const SemanticThreatSignals(
          urgencyScore: 1.0,
          financialDemandScore: 1.0,
          secrecyScore: 0.8,
          detectedKeywords: ['حول', 'جنيه'],
          impersonationClaims: ['أنا أخوك'],
        ),
        transcriptSnippets: const [],
        recommendedActions: const ['End the call immediately'],
      );

  group('IncidentReport', () {
    test('formats duration and timestamp labels', () {
      final report = makeReport();
      expect(report.durationLabel, '03:15');
      expect(report.timestampLabel, '20/09/2026 · 14:30');
    });

    test('carries the legal disclaimer by default', () {
      expect(
        makeReport().disclaimer,
        'AI-generated forensic telemetry. Not a legal or judicial '
        'determination.',
      );
    });

    test('aggregates flagged phrases from semantic signals', () {
      final phrases = makeReport().flaggedPhrases;
      expect(phrases, containsAll(['حول', 'جنيه', 'أنا أخوك']));
    });

    test('produces a shareable text summary', () {
      final text = makeReport().toShareText();
      expect(text, contains('INC-2026-0001'));
      expect(text, contains('92/100'));
      expect(text, contains('forensic telemetry'));
    });

    test('partial share text — acoustic only, never a Threat Score',
        () {
      final text = makePartial().toShareText();
      expect(text, contains('Analysis: Partial — acoustic signals only'));
      expect(text, contains('Acoustic anomaly score: 84/100'));
      expect(
          text, contains('Conversation-risk signals were not analyzed.'));
      expect(text, isNot(contains('Threat Score')));
      expect(text, isNot(contains('highRisk')));
    });

    test('partial round-trips through json', () {
      final decoded = IncidentReport.fromJson(makePartial().toJson());
      expect(decoded, isNotNull);
      expect(decoded!.analysisIsPartial, isTrue);
    });
  });

  // ── Partial incidents in UI (A3/A4) ────────────────────────────
  // A partial acoustic-only record must never render as a complete
  // fused verdict — no SAFE/SUSPICIOUS/HIGH RISK band, no Threat
  // Score — and an uploaded recording is never called a "call".
  group('partial incident surfaces', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      IncidentRepositoryLocator.instance =
          InMemoryIncidentRepository(seed: false);
      FamilyContactLocator.instance =
          PersistedFamilyContactRepository();
      ReceivedFamilyAlertLocator.instance =
          PersistedReceivedFamilyAlertRepository();
      FamilyShieldResponseLocator.instance =
          PersistedFamilyShieldResponseStore();
    });

    testWidgets('history card shows PARTIAL ANALYSIS, not a verdict',
        (tester) async {
      await IncidentRepositoryLocator.instance
          .saveIncident(makePartial());
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IncidentsHistoryScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PARTIAL ANALYSIS'), findsOneWidget);
      expect(find.textContaining('Acoustic anomaly 84/100'),
          findsOneWidget);
      expect(find.text('SUSPICIOUS'), findsNothing);
      expect(find.text('HIGH RISK'), findsNothing);
      expect(find.text('SAFE'), findsNothing);
      expect(find.textContaining('Threat Score'), findsNothing);
    });

    testWidgets('detail screen — partial header, acoustic score, '
        'honest gap statement', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: IncidentDetailScreen(incident: makePartial()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PARTIAL ANALYSIS'), findsOneWidget);
      expect(find.textContaining('84/100'), findsOneWidget);
      expect(find.text('Conversation-risk signals were not analyzed.'),
          findsOneWidget);
      expect(find.textContaining('Threat Score'), findsNothing);
      expect(find.text('CRITICAL / HIGH RISK'), findsNothing);
      // A recording is not a call — and a partial is an acoustic
      // warning, not a flag verdict.
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.whyElevatedAcousticTitle),
          findsOneWidget);
    });

    testWidgets('detail screen — full uploaded recording says '
        '"recording", not "call"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: IncidentDetailScreen(incident: makeRecordingFull()),
      ));
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.whyFlaggedRecordingTitle),
          findsOneWidget);
      expect(
          find.text(l10n.whyFlaggedCallTitle), findsNothing);
    });

    testWidgets('detail screen — live call keeps "call" title',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: IncidentDetailScreen(incident: makeReport()),
      ));
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.whyFlaggedCallTitle),
          findsOneWidget);
    });
  });

  group('InMemoryIncidentRepository', () {
    test('ships seeded history', () async {
      final repo = InMemoryIncidentRepository();
      final all = await repo.getAllIncidents();
      expect(all, isNotEmpty);
      expect(all.first.id, startsWith('INC-'));
    });

    test('saves and retrieves incidents', () async {
      final repo = InMemoryIncidentRepository(seed: false);
      await repo.saveIncident(makeReport());

      final all = await repo.getAllIncidents();
      expect(all, hasLength(1));
      expect(all.first.id, 'INC-2026-0001');

      final found = await repo.getIncidentById('INC-2026-0001');
      expect(found, isNotNull);
      expect(await repo.getIncidentById('INC-0000-0000'), isNull);
    });

    test('notifies listeners when a new incident is saved', () async {
      final repo = InMemoryIncidentRepository(seed: false);
      var notified = 0;
      repo.incidents.addListener(() => notified++);

      await repo.saveIncident(makeReport(id: 'INC-2026-0002'));
      await repo.saveIncident(makeReport(id: 'INC-2026-0003'));

      expect(notified, 2);
      expect(repo.incidents.value.first.id, 'INC-2026-0003');
    });

    test('deletes only the targeted incident and notifies listeners',
        () async {
      final repo = InMemoryIncidentRepository(seed: false);
      await repo.saveIncident(makeReport(id: 'INC-2026-0002'));
      await repo.saveIncident(makeReport(id: 'INC-2026-0003'));
      var notified = 0;
      repo.incidents.addListener(() => notified++);

      await repo.deleteIncident('INC-2026-0003');

      expect(notified, 1);
      final all = await repo.getAllIncidents();
      expect(all, hasLength(1));
      expect(all.single.id, 'INC-2026-0002');
      expect(await repo.getIncidentById('INC-2026-0003'), isNull);
    });

    test('deleting a nonexistent id is safe and idempotent', () async {
      final repo = InMemoryIncidentRepository(seed: false);
      await repo.saveIncident(makeReport(id: 'INC-2026-0004'));

      await repo.deleteIncident('INC-0000-0000');
      await repo.deleteIncident('INC-0000-0000');

      expect(await repo.getAllIncidents(), hasLength(1));
    });
  });

  group('PersistedIncidentRepository deletion', () {
    test('deletion persists across a fresh repository instance',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final repo = PersistedIncidentRepository(prefs: prefs);
      await repo.saveIncident(makeReport(id: 'INC-2026-0005'));
      await repo.saveIncident(makeReport(id: 'INC-2026-0006'));

      // Simulate a restart — a new repo over the same storage.
      final reloaded = PersistedIncidentRepository(prefs: prefs);
      await reloaded.deleteIncident('INC-2026-0005');

      final afterRestart = PersistedIncidentRepository(prefs: prefs);
      final all = await afterRestart.getAllIncidents();
      expect(all, hasLength(1));
      expect(all.single.id, 'INC-2026-0006');
    });

    test('delete on corrupted storage stays safe and empty', () async {
      SharedPreferences.setMockInitialValues(
          {'voxguard.incidents_v1': '{not-json'});
      final prefs = await SharedPreferences.getInstance();
      final repo = PersistedIncidentRepository(prefs: prefs);

      await repo.deleteIncident('INC-2026-0007');
      await repo.deleteIncident('INC-0000-0000'); // idempotent

      expect(await repo.getAllIncidents(), isEmpty);
      expect(await repo.getIncidentById('INC-2026-0007'), isNull);
    });

    test('write failure does not mutate memory and throws a controlled '
        'error', () async {
      final prefs = _WriteFailPrefs();
      final repo = PersistedIncidentRepository(prefs: prefs);
      await repo.saveIncident(makeReport(id: 'INC-2026-0011'));
      await repo.saveIncident(makeReport(id: 'INC-2026-0012'));

      expect(repo.deleteIncident('INC-2026-0011'),
          throwsA(isA<IncidentPersistenceException>()));
      // Give the rejected future a tick to settle.
      await Future<void>.delayed(Duration.zero);

      // In-memory list unchanged — the incident stays visible.
      final all = await repo.getAllIncidents();
      expect(all, hasLength(2));
      expect(await repo.getIncidentById('INC-2026-0011'), isNotNull);
    });

    test('failed delete leaves the stored incident intact', () async {
      // Prefs seeded with a valid stored list; writes return false.
      final seeding = _WriteFailPrefs();
      final writer = PersistedIncidentRepository(prefs: seeding);
      // saveIncident is best-effort — with a working writer it stores.
      seeding.allowWrites = true;
      await writer.saveIncident(makeReport(id: 'INC-2026-0013'));
      final storedBefore = seeding.stored;
      expect(storedBefore, contains('INC-2026-0013'));

      seeding.allowWrites = false;
      final repo = PersistedIncidentRepository(prefs: seeding);
      await expectLater(repo.deleteIncident('INC-2026-0013'),
          throwsA(isA<IncidentPersistenceException>()));

      // Disk copy still contains the incident — nothing was lost.
      expect(seeding.stored, storedBefore);
      expect(await repo.getIncidentById('INC-2026-0013'), isNotNull);
    });

    test('thrown persistence errors surface as the controlled exception',
        () async {
      // Seed a real stored row via a working prefs instance.
      SharedPreferences.setMockInitialValues({});
      final good = await SharedPreferences.getInstance();
      final goodRepo = PersistedIncidentRepository(prefs: good);
      await goodRepo.saveIncident(makeReport(id: 'INC-2026-0014'));

      // Same stored content, but every write throws.
      final prefs = _WriteFailPrefs(
        storedJson: good.getString('voxguard.incidents_v1'),
      )..throwOnWrite = true;
      final failing = PersistedIncidentRepository(prefs: prefs);
      await expectLater(failing.deleteIncident('INC-2026-0014'),
          throwsA(isA<IncidentPersistenceException>()));
      expect(await failing.getIncidentById('INC-2026-0014'),
          isNotNull);
      expect(prefs.stored, contains('INC-2026-0014'));
    });
  });

  group('incident deletion — UI', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      IncidentRepositoryLocator.instance =
          InMemoryIncidentRepository(seed: false);
      FamilyContactLocator.instance =
          PersistedFamilyContactRepository();
      ReceivedFamilyAlertLocator.instance =
          PersistedReceivedFamilyAlertRepository();
      FamilyShieldResponseLocator.instance =
          PersistedFamilyShieldResponseStore();
    });

    testWidgets('confirm deletes the incident and returns to history',
        (tester) async {
      final incident = makeReport(id: 'INC-2026-0009');
      await IncidentRepositoryLocator.instance.saveIncident(incident);

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        IncidentDetailScreen(incident: incident),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('INC-2026-0009'), findsWidgets);

      await tester.tap(find.byTooltip('Delete incident'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this incident?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Back on the launcher screen, incident is gone from the store.
      expect(find.text('open'), findsOneWidget);
      expect(await IncidentRepositoryLocator.instance
          .getIncidentById('INC-2026-0009'), isNull);
    });

    testWidgets('cancel keeps the incident and stays on detail',
        (tester) async {
      final incident = makeReport(id: 'INC-2026-0010');
      await IncidentRepositoryLocator.instance.saveIncident(incident);

      await tester.pumpWidget(MaterialApp(
        home: IncidentDetailScreen(incident: incident),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete incident'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('INC-2026-0010'), findsWidgets);
      expect(await IncidentRepositoryLocator.instance
          .getIncidentById('INC-2026-0010'), isNotNull);
    });

    testWidgets('failed deletion stays on detail and shows safe copy',
        (tester) async {
      final incident = makeReport(id: 'INC-2026-0015');
      final inner = InMemoryIncidentRepository(seed: false);
      await inner.saveIncident(incident);
      IncidentRepositoryLocator.instance =
          _FailingDeleteRepository(inner);

      await tester.pumpWidget(MaterialApp(
        home: IncidentDetailScreen(incident: incident),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete incident'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Still on Incident Detail — no navigation on failure.
      expect(find.text('INC-2026-0015'), findsWidgets);
      // Consumer-safe failure copy — no raw storage exception text.
      expect(
        find.text("Couldn't delete this incident. Please try again."),
        findsOneWidget,
      );
      // Incident is still in the store.
      expect(await inner.getIncidentById('INC-2026-0015'), isNotNull);
    });
  });
}

/// SharedPreferences fake whose writes can fail — returning false or
/// throwing — while reads keep working.
final class _WriteFailPrefs implements SharedPreferences {
  _WriteFailPrefs({String? storedJson}) : stored = storedJson;

  bool allowWrites = false;
  bool throwOnWrite = false;
  String? stored;

  @override
  String? getString(String key) => stored;

  @override
  Future<bool> setString(String key, String value) {
    if (throwOnWrite) {
      return Future<bool>.error(StateError('write failed'));
    }
    if (!allowWrites) return Future<bool>.value(false);
    stored = value;
    return Future<bool>.value(true);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repository wrapper whose deletion always fails with the controlled
/// exception — used to prove the UI surfaces it safely.
final class _FailingDeleteRepository implements IIncidentRepository {
  const _FailingDeleteRepository(this._inner);

  final IIncidentRepository _inner;

  @override
  Future<void> deleteIncident(String id) =>
      throw const IncidentPersistenceException();

  @override
  Future<void> saveIncident(IncidentReport incident) =>
      _inner.saveIncident(incident);

  @override
  Future<List<IncidentReport>> getAllIncidents() =>
      _inner.getAllIncidents();

  @override
  Future<IncidentReport?> getIncidentById(String id) =>
      _inner.getIncidentById(id);

  @override
  ValueListenable<List<IncidentReport>> get incidents => _inner.incidents;
}
