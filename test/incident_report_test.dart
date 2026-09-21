import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      expect(find.text('WHY VOXGUARD FOUND ELEVATED ACOUSTIC SIGNALS'),
          findsOneWidget);
    });

    testWidgets('detail screen — full uploaded recording says '
        '"recording", not "call"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: IncidentDetailScreen(incident: makeRecordingFull()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('WHY VOXGUARD FLAGGED THIS RECORDING'),
          findsOneWidget);
      expect(find.text('WHY VOXGUARD FLAGGED THIS CALL'), findsNothing);
    });

    testWidgets('detail screen — live call keeps "call" title',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: IncidentDetailScreen(incident: makeReport()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('WHY VOXGUARD FLAGGED THIS CALL'),
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
  });
}
