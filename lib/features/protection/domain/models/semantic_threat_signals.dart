import 'dart:math';

import 'package:equatable/equatable.dart';

/// Semantic threat indicators extracted from call transcript text.
///
/// Produced by `SemanticThreatService` (Engine B) — either via the Groq
/// API or the deterministic local rule engine. Scores are 0.0 – 1.0.
final class SemanticThreatSignals extends Equatable {
  const SemanticThreatSignals({
    required this.urgencyScore,
    required this.financialDemandScore,
    required this.secrecyScore,
    required this.detectedKeywords,
    required this.impersonationClaims,
  });

  /// Empty baseline — no semantic evidence.
  const SemanticThreatSignals.empty()
      : urgencyScore = 0,
        financialDemandScore = 0,
        secrecyScore = 0,
        detectedKeywords = const [],
        impersonationClaims = const [];

  /// Pressure/urgency manipulation ("now", "emergency", "بسرعة").
  final double urgencyScore;

  /// Financial transfer demand ("transfer", "wallet", "حول", "جنيه").
  final double financialDemandScore;

  /// Secrecy / isolation request ("don't tell anyone", "متقولش لحد").
  final double secrecyScore;

  /// Matched threat lexicon entries that drove the scores.
  final List<String> detectedKeywords;

  /// Identity/impersonation claims found ("أنا أخوك", "this is your boss").
  final List<String> impersonationClaims;

  /// Single fused semantic score for the fusion engine.
  ///
  /// Blends the strongest signal with the mean so one dominant threat
  /// vector can't be diluted, while broad multi-vector pressure still
  /// compounds.
  double get combinedScore {
    final peak = max(urgencyScore, max(financialDemandScore, secrecyScore));
    final mean = (urgencyScore + financialDemandScore + secrecyScore) / 3;
    final impersonationBoost = impersonationClaims.isEmpty ? 0.0 : 0.08;
    return (peak * 0.6 + mean * 0.4 + impersonationBoost).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        urgencyScore,
        financialDemandScore,
        secrecyScore,
        detectedKeywords,
        impersonationClaims,
      ];
}
