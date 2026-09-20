import '../models/audio_forensic_metrics.dart';
import '../models/composite_threat_report.dart';
import '../models/semantic_threat_signals.dart';

/// Threat Fusion Engine — merges Engine A (acoustic) and Engine B
/// (semantic) outputs into a single composite risk assessment.
///
///   CompositeRisk = (SemanticScore × 0.65) + (AcousticScore × 0.35)
///
/// When financial demand + secrecy + urgency are all elevated
/// (> 0.75), the classic coordinated-scam signature, a +15%
/// amplification boost is applied.
///
/// Bands: Safe < 0.40, Suspicious 0.40–0.75, High Risk ≥ 0.75.
final class ThreatFusionEngine {
  static const double _semanticWeight = 0.65;
  static const double _acousticWeight = 0.35;
  static const double _amplificationFactor = 1.15;
  static const double _amplificationThreshold = 0.75;

  static const double _suspiciousFloor = 0.40;
  static const double _highRiskFloor = 0.75;

  /// Signal considered "elevated" when listing it as a threat reason.
  static const double _reasonThreshold = 0.50;

  /// Fuses both engine outputs into a [CompositeThreatReport].
  CompositeThreatReport fuse(
    AudioForensicMetrics acoustic,
    SemanticThreatSignals semantic,
  ) {
    var composite = semantic.combinedScore * _semanticWeight +
        acoustic.syntheticVoiceScore * _acousticWeight;

    final coordinatedAttack =
        semantic.urgencyScore > _amplificationThreshold &&
            semantic.financialDemandScore > _amplificationThreshold &&
            semantic.secrecyScore > _amplificationThreshold;
    if (coordinatedAttack) {
      composite = (composite * _amplificationFactor).clamp(0.0, 1.0);
    }
    composite = composite.clamp(0.0, 1.0);

    final level = _categorize(composite);
    return CompositeThreatReport(
      compositeRiskScore: composite,
      riskLevel: level,
      primaryThreatReasons:
          _buildReasons(acoustic, semantic, coordinatedAttack),
      recommendedAction: _recommendedAction(level),
    );
  }

  ThreatRiskLevel _categorize(double composite) {
    if (composite >= _highRiskFloor) return ThreatRiskLevel.highRisk;
    if (composite >= _suspiciousFloor) return ThreatRiskLevel.suspicious;
    return ThreatRiskLevel.safe;
  }

  List<String> _buildReasons(
    AudioForensicMetrics acoustic,
    SemanticThreatSignals semantic,
    bool coordinatedAttack,
  ) {
    final reasons = <String>[];
    if (semantic.financialDemandScore >= _reasonThreshold) {
      reasons.add('Financial transfer demand detected');
    }
    if (semantic.secrecyScore >= _reasonThreshold) {
      reasons.add('Secrecy & isolation pressure');
    }
    if (semantic.urgencyScore >= _reasonThreshold) {
      reasons.add('Urgency manipulation tactics');
    }
    if (semantic.impersonationClaims.isNotEmpty) {
      reasons.add(
        'Identity impersonation claim: "${semantic.impersonationClaims.first}"',
      );
    }
    if (acoustic.isSyntheticElevated) {
      reasons.add('Synthetic voice artifacts detected');
    }
    if (coordinatedAttack) {
      reasons.add('Coordinated scam pattern — amplified');
    }
    if (reasons.isEmpty) {
      reasons.add('No significant threat indicators');
    }
    return reasons;
  }

  String _recommendedAction(ThreatRiskLevel level) {
    return switch (level) {
      ThreatRiskLevel.safe => 'Continue monitoring',
      ThreatRiskLevel.suspicious =>
        'Advise caution — verify caller identity',
      ThreatRiskLevel.highRisk =>
        'End call immediately and alert a trusted contact',
    };
  }
}
