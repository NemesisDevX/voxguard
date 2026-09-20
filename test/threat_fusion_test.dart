import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/domain/services/semantic_threat_service.dart';
import 'package:voxguard/features/protection/domain/services/threat_fusion_engine.dart';

void main() {
  final engine = ThreatFusionEngine();

  AudioForensicMetrics acoustic(double synthetic) => AudioForensicMetrics(
        spectralFlux: 0.1,
        spectralRolloffRatio: 0.1,
        zeroCrossingRate: 0.03,
        syntheticVoiceScore: synthetic,
      );

  SemanticThreatSignals semantic({
    double urgency = 0,
    double financial = 0,
    double secrecy = 0,
    List<String> claims = const [],
  }) =>
      SemanticThreatSignals(
        urgencyScore: urgency,
        financialDemandScore: financial,
        secrecyScore: secrecy,
        detectedKeywords: const [],
        impersonationClaims: claims,
      );

  group('ThreatFusionEngine', () {
    test('flags SAFE for a clean call', () {
      final report = engine.fuse(
        acoustic(0.05),
        semantic(urgency: 0.05, financial: 0.02, secrecy: 0.03),
      );

      expect(report.riskLevel, ThreatRiskLevel.safe);
      expect(report.compositeRiskScore, lessThan(0.40));
      expect(report.recommendedAction, 'Continue monitoring');
    });

    test('flags HIGH RISK for a coordinated scam signature', () {
      final report = engine.fuse(
        acoustic(0.85),
        semantic(
          urgency: 0.9,
          financial: 0.95,
          secrecy: 0.85,
          claims: const ['أنا أخوك'],
        ),
      );

      expect(report.riskLevel, ThreatRiskLevel.highRisk);
      expect(report.compositeRiskScore, greaterThan(0.85));
      expect(report.primaryThreatReasons, isNotEmpty);
      expect(
        report.recommendedAction,
        contains('End call'),
      );
    });

    test('applies +15% amplification when all three semantic signals exceed 0.75', () {
      final unamplified = engine.fuse(
        acoustic(0.5),
        semantic(urgency: 0.8, financial: 0.8, secrecy: 0.7),
      );
      final amplified = engine.fuse(
        acoustic(0.5),
        semantic(urgency: 0.8, financial: 0.8, secrecy: 0.8),
      );

      // Same signals except secrecy crossing the 0.75 threshold → the
      // boosted score must exceed the plain weighted blend.
      expect(
        amplified.compositeRiskScore,
        greaterThan(unamplified.compositeRiskScore),
      );
    });

    test('flags SUSPICIOUS for a mid-range composite', () {
      final report = engine.fuse(
        acoustic(0.3),
        semantic(urgency: 0.8, financial: 0.5, secrecy: 0.4),
      );

      expect(report.riskLevel, ThreatRiskLevel.suspicious);
      expect(report.compositeRiskScore,
          inInclusiveRange(0.40, 0.75));
    });
  });

  group('SemanticThreatService (local engine)', () {
    final service = SemanticThreatService();

    test('detects the Arabic demo scam script', () {
      final signals = service.analyzeLocally(
        'أنا أخوك، حول لي 2,000 جنيه بسرعة على المحفظة، '
        'متقولش لحد الموضوع خطير',
      );

      expect(signals.financialDemandScore, greaterThan(0.75));
      expect(signals.urgencyScore, greaterThan(0.5));
      expect(signals.secrecyScore, greaterThan(0.5));
      expect(signals.impersonationClaims, isNotEmpty);
      expect(signals.detectedKeywords, isNotEmpty);
    });

    test('detects English scam phrases', () {
      final signals = service.analyzeLocally(
        "This is your bank security. Transfer the money now, "
        "it's an emergency. Don't tell anyone.",
      );

      expect(signals.urgencyScore, greaterThan(0));
      expect(signals.financialDemandScore, greaterThan(0));
      expect(signals.secrecyScore, greaterThan(0));
    });

    test('returns zero scores for benign conversation', () {
      final signals = service.analyzeLocally(
        'Hey, are we still on for dinner tonight?',
      );

      expect(signals.urgencyScore, 0);
      expect(signals.financialDemandScore, 0);
      expect(signals.secrecyScore, 0);
      expect(signals.impersonationClaims, isEmpty);
    });
  });

  group('SemanticThreatSignals.evidenceCategories', () {
    test('exposes all four evidence buckets for the demo scam script', () {
      final signals = SemanticThreatService().analyzeLocally(
        'أنا أخوك، حول لي 2,000 جنيه بسرعة على المحفظة، '
        'متقولش لحد الموضوع خطير',
      );

      expect(
        signals.evidenceCategories,
        containsAll([
          EvidenceCategory.impersonation,
          EvidenceCategory.moneyRequest,
          EvidenceCategory.urgency,
          EvidenceCategory.secrecy,
        ]),
      );
      expect(signals.flaggedPhrases, isNotEmpty);
    });

    test('is empty for benign signals', () {
      expect(
        const SemanticThreatSignals.empty().evidenceCategories,
        isEmpty,
      );
    });
  });
}
