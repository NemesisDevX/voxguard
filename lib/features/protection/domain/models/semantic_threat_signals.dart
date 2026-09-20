import 'dart:math';

import 'package:equatable/equatable.dart';

/// Coarse evidence buckets derived from the semantic engine's actual
/// output — these drive the transcript evidence chips.
enum EvidenceCategory {
  impersonation,
  moneyRequest,
  urgency,
  secrecy;

  String get label => switch (this) {
        EvidenceCategory.impersonation => 'Impersonation',
        EvidenceCategory.moneyRequest => 'Money Request',
        EvidenceCategory.urgency => 'Urgency',
        EvidenceCategory.secrecy => 'Secrecy',
      };
}

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

  /// Every phrase the engine flagged — the union the UI highlights
  /// inline in the transcript.
  List<String> get flaggedPhrases =>
      {...detectedKeywords, ...impersonationClaims}.toList();

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

  /// Evidence chips shown in the UI — derived purely from these
  /// signals, never hard-coded per-screen.
  List<EvidenceCategory> get evidenceCategories {
    final out = <EvidenceCategory>[];
    if (impersonationClaims.isNotEmpty) out.add(EvidenceCategory.impersonation);
    if (financialDemandScore >= 0.5) out.add(EvidenceCategory.moneyRequest);
    if (urgencyScore >= 0.5) out.add(EvidenceCategory.urgency);
    if (secrecyScore >= 0.5) out.add(EvidenceCategory.secrecy);
    return out;
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
