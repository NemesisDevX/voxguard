import 'package:flutter/material.dart';

import '../services/preferences/app_preferences.dart';
import 'app_colors.dart';

/// Theme-aware semantic palette — the single source of truth for
/// color in the presentation layer.
///
/// Dark and Light are real palettes, not a scaffold swap: surfaces,
/// text and borders all shift, while the *safety semantics* (safe /
/// warning / danger / signal layers / missing-signal) keep one hue
/// family in both modes, tuned only for contrast. Accent
/// personalization tints interactive surfaces; it can never recolor
/// evidence meaning — `forThreat` and the signal layer colors ignore
/// the accent by design.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.surfaceCard,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textMuted,
    required this.statusSafe,
    required this.statusWarning,
    required this.statusDanger,
    required this.accent,
    required this.accentMuted,
    required this.onAccent,
    required this.signalSemantic,
    required this.signalAcoustic,
    required this.signalAbsent,
  });

  final Brightness brightness;

  // Surfaces
  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;
  final Color surfaceCard;
  final Color borderSubtle;

  // Text
  final Color textPrimary;
  final Color textMuted;

  // Safety semantics — centrally controlled, never accent-tinted.
  final Color statusSafe;
  final Color statusWarning;
  final Color statusDanger;

  // Interactive accent — curated personalization only.
  final Color accent;
  final Color accentMuted;
  final Color onAccent;

  // Signal Lens layers
  final Color signalSemantic;
  final Color signalAcoustic;
  final Color signalAbsent;

  /// Maps a normalized threat score (0.0–1.0) to its semantic color.
  Color forThreat(double value) {
    if (value >= 0.7) return statusDanger;
    if (value >= 0.4) return statusWarning;
    return statusSafe;
  }

  /// A layer's own hue tinted toward its risk band as evidence earns
  /// it — low evidence keeps the layer hue, high converges on status.
  Color forSignalLayer(Color layer, double score) =>
      Color.lerp(layer, forThreat(score), score.clamp(0.0, 1.0))!;

  // ── Accent families ──────────────────────────────────────────────
  // Curated pairs chosen for contrast in both brightness modes.

  static Color accentFor(AppAccent accent, Brightness brightness) =>
      switch ((accent, brightness)) {
        (AppAccent.periwinkle, Brightness.dark) =>
          const Color(0xFF8B9CC9),
        (AppAccent.periwinkle, Brightness.light) =>
          const Color(0xFF5468A8),
        (AppAccent.softBlue, Brightness.dark) =>
          const Color(0xFF7FA8D9),
        (AppAccent.softBlue, Brightness.light) =>
          const Color(0xFF3D6FA8),
        (AppAccent.softViolet, Brightness.dark) =>
          const Color(0xFFA896D4),
        (AppAccent.softViolet, Brightness.light) =>
          const Color(0xFF7157B8),
      };

  static Color accentMutedFor(AppAccent accent, Brightness b) =>
      switch ((accent, b)) {
        (AppAccent.periwinkle, Brightness.dark) =>
          const Color(0xFF566080),
        (AppAccent.periwinkle, Brightness.light) =>
          const Color(0xFF8B96BC),
        (AppAccent.softBlue, Brightness.dark) =>
          const Color(0xFF50688C),
        (AppAccent.softBlue, Brightness.light) =>
          const Color(0xFF8AA5C6),
        (AppAccent.softViolet, Brightness.dark) =>
          const Color(0xFF64588C),
        (AppAccent.softViolet, Brightness.light) =>
          const Color(0xFF9C90C4),
      };

  // ── Palettes ─────────────────────────────────────────────────────

  /// Dark — deep ink/graphite base, warm off-white type, slightly
  /// blue elevated surfaces.
  factory AppPalette.dark([AppAccent accent = AppAccent.periwinkle]) =>
      AppPalette(
        brightness: Brightness.dark,
        bgBase: AppColors.bgBase,
        bgSurface: AppColors.bgSurface,
        bgElevated: AppColors.bgElevated,
        surfaceCard: AppColors.surfaceCard,
        borderSubtle: AppColors.borderSubtle,
        textPrimary: AppColors.textPrimary,
        textMuted: AppColors.textMuted,
        statusSafe: AppColors.statusSafe,
        statusWarning: AppColors.statusWarning,
        statusDanger: AppColors.statusDanger,
        accent: accentFor(accent, Brightness.dark),
        accentMuted: accentMutedFor(accent, Brightness.dark),
        onAccent: const Color(0xFF11131A),
        signalSemantic: AppColors.signalSemantic,
        signalAcoustic: AppColors.signalAcoustic,
        signalAbsent: AppColors.signalAbsent,
      );

  /// Light — warm off-white base, clean elevated white, dark ink
  /// type, cool soft borders. Same safety hue family, deepened for
  /// contrast on light surfaces.
  factory AppPalette.light([AppAccent accent = AppAccent.periwinkle]) =>
      const AppPalette(
        brightness: Brightness.light,
        bgBase: Color(0xFFF6F3EC),
        bgSurface: Color(0xFFEDEAE0),
        bgElevated: Color(0xFFFFFFFF),
        surfaceCard: Color(0xFFFFFFFF),
        borderSubtle: Color(0xFFD9D5CB),
        textPrimary: Color(0xFF1F2430),
        textMuted: Color(0xFF5C6478),
        statusSafe: Color(0xFF1D8F6C),
        statusWarning: Color(0xFF9A6A14),
        statusDanger: Color(0xFFB3402E),
        accent: Color(0xFF5468A8),
        accentMuted: Color(0xFF8B96BC),
        onAccent: Color(0xFFFFFFFF),
        signalSemantic: Color(0xFF5468A8),
        signalAcoustic: Color(0xFF9A7B3C),
        signalAbsent: Color(0xFFB4BACB),
      )._withAccent(accent);

  AppPalette _withAccent(AppAccent accent) => copyWith(
        accent: accentFor(accent, brightness),
        accentMuted: accentMutedFor(accent, brightness),
      );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? bgBase,
    Color? bgSurface,
    Color? bgElevated,
    Color? surfaceCard,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textMuted,
    Color? statusSafe,
    Color? statusWarning,
    Color? statusDanger,
    Color? accent,
    Color? accentMuted,
    Color? onAccent,
    Color? signalSemantic,
    Color? signalAcoustic,
    Color? signalAbsent,
  }) =>
      AppPalette(
        brightness: brightness ?? this.brightness,
        bgBase: bgBase ?? this.bgBase,
        bgSurface: bgSurface ?? this.bgSurface,
        bgElevated: bgElevated ?? this.bgElevated,
        surfaceCard: surfaceCard ?? this.surfaceCard,
        borderSubtle: borderSubtle ?? this.borderSubtle,
        textPrimary: textPrimary ?? this.textPrimary,
        textMuted: textMuted ?? this.textMuted,
        statusSafe: statusSafe ?? this.statusSafe,
        statusWarning: statusWarning ?? this.statusWarning,
        statusDanger: statusDanger ?? this.statusDanger,
        accent: accent ?? this.accent,
        accentMuted: accentMuted ?? this.accentMuted,
        onAccent: onAccent ?? this.onAccent,
        signalSemantic: signalSemantic ?? this.signalSemantic,
        signalAcoustic: signalAcoustic ?? this.signalAcoustic,
        signalAbsent: signalAbsent ?? this.signalAbsent,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bgBase: l(bgBase, other.bgBase),
      bgSurface: l(bgSurface, other.bgSurface),
      bgElevated: l(bgElevated, other.bgElevated),
      surfaceCard: l(surfaceCard, other.surfaceCard),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      textPrimary: l(textPrimary, other.textPrimary),
      textMuted: l(textMuted, other.textMuted),
      statusSafe: l(statusSafe, other.statusSafe),
      statusWarning: l(statusWarning, other.statusWarning),
      statusDanger: l(statusDanger, other.statusDanger),
      accent: l(accent, other.accent),
      accentMuted: l(accentMuted, other.accentMuted),
      onAccent: l(onAccent, other.onAccent),
      signalSemantic: l(signalSemantic, other.signalSemantic),
      signalAcoustic: l(signalAcoustic, other.signalAcoustic),
      signalAbsent: l(signalAbsent, other.signalAbsent),
    );
  }
}

/// Lookup convenience — `context.palette` everywhere in the UI.
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark();
}
