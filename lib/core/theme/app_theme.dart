import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// VoxGuard Material 3 dark theme.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.statusSafe,
      onSecondary: Colors.white,
      surface: AppColors.bgSurface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceCard,
      error: AppColors.statusDanger,
      onError: Colors.white,
      outline: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      textTheme: AppTypography.textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textMuted, size: 22),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.statusSafe,
        linearTrackColor: AppColors.borderSubtle,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgElevated,
        contentTextStyle: AppTypography.bodyLarge,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
