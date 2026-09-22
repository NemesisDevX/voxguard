import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_palette.dart';

/// How the meter's current value is rendered on the trailing edge.
enum ThreatMeterStyle {
  /// Shows a percentage readout (e.g. `42%`).
  percent,

  /// Shows a status chip (`NORMAL` / `ELEVATED`) instead of a number.
  status,
}

/// A single real-time signal meter in the SafeCall technical-details
/// section — supporting evidence, visually secondary to the lens.
///
/// Animates smoothly toward [value] and shifts its accent color
/// green → amber → red as the score rises.
class ThreatMeterCard extends StatelessWidget {
  const ThreatMeterCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.graphic_eq,
    this.style = ThreatMeterStyle.percent,
    this.normalLabel = 'NORMAL',
    this.elevatedLabel = 'ELEVATED',
  });

  /// Signal name, e.g. "Urgent Pressure".
  final String title;

  /// Normalized score, 0.0 – 1.0.
  final double value;

  /// Leading icon for the signal.
  final IconData icon;

  /// Percent readout vs. NORMAL/ELEVATED status chip.
  final ThreatMeterStyle style;

  final String normalLabel;
  final String elevatedLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.borderSubtle),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) {
          final color = p.forThreat(animated);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: AppTypography.labelLarge),
                  ),
                  _TrailingValue(
                    style: style,
                    value: animated,
                    color: color,
                    normalLabel: normalLabel,
                    elevatedLabel: elevatedLabel,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animated,
                  minHeight: 6,
                  backgroundColor: p.borderSubtle.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrailingValue extends StatelessWidget {
  const _TrailingValue({
    required this.style,
    required this.value,
    required this.color,
    required this.normalLabel,
    required this.elevatedLabel,
  });

  final ThreatMeterStyle style;
  final double value;
  final Color color;
  final String normalLabel;
  final String elevatedLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (style == ThreatMeterStyle.status) {
      final elevated = value >= 0.5;
      final chipColor =
          elevated ? p.statusWarning : p.statusSafe;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: chipColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          elevated ? elevatedLabel : normalLabel,
          style: AppTypography.labelSmall.copyWith(color: chipColor),
        ),
      );
    }
    return SizedBox(
      width: 46,
      child: Text(
        '${(value * 100).round()}%',
        textAlign: TextAlign.end,
        style: AppTypography.statLarge.copyWith(fontSize: 16, color: color),
      ),
    );
  }
}
