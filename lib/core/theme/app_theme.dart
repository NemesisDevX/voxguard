import 'package:flutter/material.dart';

import '../services/preferences/app_preferences.dart';
import 'app_palette.dart';
import 'app_typography.dart';

/// PauseSignal Material 3 themes — dark and light, accent-parameterized.
///
/// Every theme carries an [AppPalette] extension; widgets read colors
/// via `context.palette` so Light Mode is a real palette, not a
/// scaffold swap. The interactive accent comes from the user's
/// curated choice; safety semantic colors never do.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData dark([AppAccent accent = AppAccent.periwinkle]) =>
      _build(AppPalette.dark(accent));

  static ThemeData light([AppAccent accent = AppAccent.periwinkle]) =>
      _build(AppPalette.light(accent));

  static ThemeData _build(AppPalette p) {
    final dark = p.brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.statusSafe,
      onSecondary: dark ? Colors.black : Colors.white,
      surface: p.bgSurface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceCard,
      error: p.statusDanger,
      onError: Colors.white,
      outline: p.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bgBase,
      // Hierarchy via color: body/label-small read muted; everything
      // else inherits the palette's primary text color. The base
      // styles carry no color so they theme correctly in both modes.
      textTheme: () {
        final t = AppTypography.textTheme.apply(
          bodyColor: p.textPrimary,
          displayColor: p.textPrimary,
        );
        return t.copyWith(
          bodyMedium: t.bodyMedium?.copyWith(color: p.textMuted),
          labelSmall: t.labelSmall?.copyWith(color: p.textMuted),
        );
      }(),
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bgBase,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle:
            AppTypography.titleLarge.copyWith(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.surfaceCard,
        elevation: dark ? 0 : 0.6,
        shadowColor: Colors.black.withValues(alpha: dark ? 0 : 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: p.textMuted, size: 22),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.borderSubtle,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.bgSurface,
        selectedItemColor: p.accent,
        unselectedItemColor: p.textMuted,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.bgElevated,
        contentTextStyle:
            AppTypography.bodyLarge.copyWith(color: p.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.bgElevated,
        titleTextStyle:
            AppTypography.titleLarge.copyWith(color: p.textPrimary),
        contentTextStyle:
            AppTypography.bodyMedium.copyWith(color: p.textMuted),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.accent
              : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.accentMuted
              : p.borderSubtle,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.accent
              : p.textMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent, width: 1.6),
        ),
      ),
    );
  }
}
