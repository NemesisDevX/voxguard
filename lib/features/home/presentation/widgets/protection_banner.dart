import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/signal_mark.dart';
import '../../../paywall/domain/models/entitlement_state.dart';
import '../../../paywall/domain/models/subscription_tier.dart';
import '../../../paywall/domain/services/purchase_service_locator.dart';

/// Readiness banner — a calm "ready when you are" surface topped by
/// the Signal Mark. No pulsing shield, no alarm posture; the product
/// waits quietly until the user asks for protection.
class ProtectionBanner extends StatelessWidget {
  const ProtectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Row(
        children: [
          _ReadyMark(),
          SizedBox(width: 16),
          Expanded(
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
          SizedBox(width: 12),
          _PlanBadge(),
        ],
      ),
    );
  }
}

/// Live entitlement badge — flips from FREE TIER to the purchased plan
/// the moment a checkout, restore, or CustomerInfo sync lands.
class _PlanBadge extends StatelessWidget {
  const _PlanBadge();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EntitlementState>(
      valueListenable: PurchaseServiceLocator.instance.entitlement,
      builder: (context, entitlement, _) {
        final premium = entitlement.tier != TierId.free;
        final label = switch (entitlement.tier) {
          TierId.sentinel => AppStrings.planSentinel,
          TierId.familyVault => AppStrings.planFamily,
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

/// Static mark with a single soft breathing scale — quiet readiness,
/// not a scanner.
class _ReadyMark extends StatefulWidget {
  const _ReadyMark();

  @override
  State<_ReadyMark> createState() => _ReadyMarkState();
}

class _ReadyMarkState extends State<_ReadyMark>
    with SingleTickerProviderStateMixin {
  // Eagerly initialized in initState — lazy field init inside
  // dispose() would create a ticker on a deactivated element.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduce && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final breathe = 1 + (_controller.value - 0.5) * 0.05;
          return Transform.scale(scale: breathe, child: child);
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.10),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
          ),
          child: const Center(child: SignalMark(size: 26)),
        ),
      ),
    );
  }
}
