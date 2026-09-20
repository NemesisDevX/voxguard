import 'package:equatable/equatable.dart';

/// Coarse risk classification produced by the threat fusion engine.
enum ThreatRiskLevel {
  /// Composite < 0.40 — no meaningful threat evidence.
  safe,

  /// 0.40 ≤ composite < 0.75 — elevated suspicion, monitor closely.
  suspicious,

  /// Composite ≥ 0.75 — active threat, intervene.
  highRisk,
}

/// Fused, user-facing threat assessment for the SafeCall HUD.
final class CompositeThreatReport extends Equatable {
  const CompositeThreatReport({
    required this.compositeRiskScore,
    required this.riskLevel,
    required this.primaryThreatReasons,
    required this.recommendedAction,
  });

  /// All-clear baseline report.
  const CompositeThreatReport.initial()
      : compositeRiskScore = 0,
        riskLevel = ThreatRiskLevel.safe,
        primaryThreatReasons = const [],
        recommendedAction = 'Continue monitoring';

  /// Fused risk score, 0.0 – 1.0.
  final double compositeRiskScore;

  /// Discrete risk band derived from [compositeRiskScore].
  final ThreatRiskLevel riskLevel;

  /// Human-readable drivers of the score, highest-impact first.
  final List<String> primaryThreatReasons;

  /// What the shield recommends the user do right now.
  final String recommendedAction;

  @override
  List<Object?> get props => [
        compositeRiskScore,
        riskLevel,
        primaryThreatReasons,
        recommendedAction,
      ];
}
