import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/domain/services/incident_repository.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';

void main() {
  IncidentReport makeReport({String id = 'INC-2026-0001'}) => IncidentReport(
        id: id,
        timestamp: DateTime(2026, 9, 20, 14, 30),
        callerLabel: 'Unknown Caller (+20 10 ••• ••42)',
        callDurationSeconds: 195,
        audioFingerprint: 'ab' * 32,
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
      expect(text, contains('92%'));
      expect(text, contains('forensic telemetry'));
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
