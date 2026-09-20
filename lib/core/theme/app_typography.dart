import 'package:flutter/material.dart';

import 'app_colors.dart';

/// VoxGuard type scale.
///
/// Crisp high-contrast white for headings, muted slate for body copy.
/// Uses the platform default font family to stay clean and trusted.
abstract final class AppTypography {
  AppTypography._();

  static const TextStyle displaySmall = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.1,
  );

  /// Large numeric readout used for threat percentages and timers.
  static const TextStyle statLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Material [TextTheme] wired into [ThemeData].
  static const TextTheme textTheme = TextTheme(
    headlineSmall: displaySmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    labelLarge: labelLarge,
    labelSmall: labelSmall,
  );
}
