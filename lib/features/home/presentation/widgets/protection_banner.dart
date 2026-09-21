import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../paywall/domain/models/subscription_tier.dart';
import '../../../paywall/domain/services/purchase_service_locator.dart';

/// "VoxGuard Ready" status banner with a subtle pulsating ring around
/// the shield emblem.
class ProtectionBanner extends StatefulWidget {
  const ProtectionBanner({super.key});

  @override
  State<ProtectionBanner> createState() => _ProtectionBannerState();
}

class _ProtectionBannerState extends State<ProtectionBanner>
    with SingleTickerProviderStateMixin {
  // Eagerly initialized in initState — lazy field init inside
  // dispose() would create a ticker on a deactivated element.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _PulsatingShield(animation: _controller),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.shieldStatusReady,
                  style: AppTypography.titleMedium,
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.shieldSubtitle,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _PlanBadge(),
        ],
      ),
    );
  }
}

/// Live entitlement badge — flips from FREE TIER to the purchased plan
/// the moment a checkout or restore completes.
class _PlanBadge extends StatelessWidget {
  const _PlanBadge();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: PurchaseServiceLocator.instance.activeTier,
      builder: (context, tierId, _) {
        final tier = SubscriptionTiers.byId(tierId);
        final premium = tier != null && !tier.isFree;
        final label = switch (tierId) {
          'sentinel' => AppStrings.planSentinel,
          'family_vault' => AppStrings.planFamily,
          _ => AppStrings.planFree,
        };
        final color =
            premium ? AppColors.statusSafe : AppColors.textMuted;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class _PulsatingShield extends StatelessWidget {
  const _PulsatingShield({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding pulse ring.
              Transform.scale(
                scale: 0.75 + (t * 0.45),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.statusSafe.withValues(
                        alpha: (1 - t) * 0.55,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Solid emblem.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.statusSafe.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.statusSafe.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.statusSafe,
                  size: 26,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
