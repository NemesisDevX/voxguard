import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
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
    final l10n = context.l10n;
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Row(
        children: [
          const _ReadyMark(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shieldStatusReady,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.shieldSubtitle,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(child: _PlanBadge()),
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
    final l10n = context.l10n;
    final p = context.palette;
    return ValueListenableBuilder<EntitlementState>(
      valueListenable: PurchaseServiceLocator.instance.entitlement,
      builder: (context, entitlement, _) {
        final premium = entitlement.tier != TierId.free;
        final label = switch (entitlement.tier) {
          TierId.sentinel => l10n.planSentinelBadge,
          TierId.familyVault => l10n.planFamilyBadge,
          _ => l10n.planFreeBadge,
        };
        final color = premium ? p.statusSafe : p.textMuted;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
/// not a scanner. Breathing stops when either the OS or the app
/// requests reduced motion (the root MediaQuery override ORs both).
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
    final p = context.palette;
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
            color: p.accent.withValues(alpha: 0.10),
            border: Border.all(
              color: p.accent.withValues(alpha: 0.45),
            ),
          ),
          child: Center(
            child: SignalMark(
                size: 26, color: p.accent,
                secondaryColor: p.signalAcoustic),
          ),
        ),
      ),
    );
  }
}
