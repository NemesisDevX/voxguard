import 'package:flutter/material.dart';

/// VoxGuard design-system color tokens.
///
/// Consumer-first dark palette: deep zinc/slate backgrounds, crisp white
/// headings, muted slate body text, and a restrained set of semantic
/// status colors (emerald / amber / crimson).
abstract final class AppColors {
  AppColors._();

  // ── Backgrounds (deep zinc / slate) ──────────────────────────────
  static const Color bgBase = Color(0xFF0B0D13);
  static const Color bgSurface = Color(0xFF12151F);
  static const Color bgElevated = Color(0xFF1A1E2C);

  // ── Cards & surfaces ─────────────────────────────────────────────
  static const Color surfaceCard = Color(0xFF1E2333);
  static const Color borderSubtle = Color(0xFF2D354A);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Semantic status ──────────────────────────────────────────────
  /// Safe / protected.
  static const Color statusSafe = Color(0xFF10B981);

  /// Elevated suspicion.
  static const Color statusWarning = Color(0xFFF59E0B);

  /// High-risk threat.
  static const Color statusDanger = Color(0xFFEF4444);

  // ── Brand accent (restrained indigo) ─────────────────────────────
  static const Color accent = Color(0xFF6366F1);
  static const Color accentMuted = Color(0xFF4F55A3);

  /// Maps a normalized threat score (0.0 – 1.0) to its semantic color.
  static Color forThreat(double value) {
    if (value >= 0.7) return statusDanger;
    if (value >= 0.4) return statusWarning;
    return statusSafe;
  }
}
