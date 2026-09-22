import 'package:flutter/material.dart';

/// PauseSignal design-system color tokens.
///
/// Signal Lens palette: deep graphite foundations, warm off-white
/// type, muted periwinkle for neutral evidence, mint for verified /
/// safe resolution, warm amber for uncertainty, and an oxide red
/// reserved for genuinely high-risk states. Flat surfaces — no
/// gradients, no neon.
abstract final class AppColors {
  AppColors._();

  // ── Backgrounds (deep graphite / ink) ────────────────────────────
  static const Color bgBase = Color(0xFF0E1014);
  static const Color bgSurface = Color(0xFF15181F);
  static const Color bgElevated = Color(0xFF1D2029);

  // ── Cards & surfaces ─────────────────────────────────────────────
  static const Color surfaceCard = Color(0xFF21252F);
  static const Color borderSubtle = Color(0xFF343A47);

  // ── Text ─────────────────────────────────────────────────────────
  /// Warm off-white — never pure #FFF.
  static const Color textPrimary = Color(0xFFF4F1EA);

  /// Muted periwinkle — secondary information, evidence, metadata.
  static const Color textMuted = Color(0xFF9AA1BC);

  // ── Semantic status ──────────────────────────────────────────────
  /// Verified / safe — calm mint.
  static const Color statusSafe = Color(0xFF3ED0A0);

  /// Uncertain / elevated — warm amber.
  static const Color statusWarning = Color(0xFFE3A63C);

  /// Active high risk — oxide red, used sparingly.
  static const Color statusDanger = Color(0xFFE15B44);

  // ── Brand accent (muted periwinkle) ──────────────────────────────
  static const Color accent = Color(0xFF8B9CC9);
  static const Color accentMuted = Color(0xFF566080);

  // ── Signal Lens layer colors ─────────────────────────────────────
  /// Layer A — conversation / semantic evidence.
  static const Color signalSemantic = Color(0xFF8B9CC9);

  /// Layer B — acoustic / voice evidence. Warm sand so the two
  /// signals are distinguishable without leaning on status hues.
  static const Color signalAcoustic = Color(0xFFC9B284);

  /// Color of a signal layer that has not run — visible absence.
  static const Color signalAbsent = Color(0xFF4A4F5E);

  /// Maps a normalized threat score (0.0 – 1.0) to its semantic color.
  static Color forThreat(double value) {
    if (value >= 0.7) return statusDanger;
    if (value >= 0.4) return statusWarning;
    return statusSafe;
  }

  /// A layer's own color tinted toward its risk band as its score
  /// earns it — low evidence keeps the layer hue, high evidence
  /// converges on the status color.
  static Color forSignalLayer(Color layer, double score) {
    return Color.lerp(layer, forThreat(score), score.clamp(0.0, 1.0))!;
  }
}
