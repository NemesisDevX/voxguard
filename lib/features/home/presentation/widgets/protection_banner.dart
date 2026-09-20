import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// "Shield Status: Ready & Monitoring" banner with a subtle pulsating
/// ring around the shield emblem.
class ProtectionBanner extends StatefulWidget {
  const ProtectionBanner({super.key});

  @override
  State<ProtectionBanner> createState() => _ProtectionBannerState();
}

class _ProtectionBannerState extends State<ProtectionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

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
        ],
      ),
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
