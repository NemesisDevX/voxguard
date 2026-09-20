import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../screens/paywall_screen.dart';

/// Bottom-sheet upsell shown after a high-risk call is intercepted.
///
/// Anchors the Family Vault value proposition to the threat the user
/// just witnessed.
Future<void> showFamilyShieldUpsell(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.statusDanger.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppColors.statusDanger.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.gpp_maybe_outlined,
                  color: AppColors.statusDanger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.upsellTitle,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.upsellBody,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    PaywallScreen.show(context);
                  },
                  icon: const Icon(Icons.workspace_premium, size: 20),
                  label: const Text(
                    AppStrings.upsellCta,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text(
                  AppStrings.upsellDismiss,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
