import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// VoxGuard's product signature: a circular "protection core" showing
/// the composite Threat Score (0–100) with a calm, state-driven ring.
///
/// The inner pulse reacts to [amplitude] (0–1) from the live audio
/// pipeline. When the stream is generated rather than microphone-
/// derived, [isDemoAudio] renders an unobtrusive `DEMO AUDIO` caption —
/// never passing synthetic data off as real.
class ThreatCore extends StatefulWidget {
  const ThreatCore({
    super.key,
    required this.score,
    this.amplitude = 0,
    this.isDemoAudio = false,
    this.size = 210,
  });

  /// Composite risk score, 0.0–1.0.
  final double score;

  /// Latest audio amplitude (RMS) feeding the inner pulse.
  final double amplitude;

  /// Whether the amplitude stream is generated demo PCM.
  final bool isDemoAudio;

  final double size;

  /// Display state for a score — the single source of truth for the
  /// label used across the HUD.
  static String stateLabel(double score) => switch (score) {
        < 0.40 => 'SAFE — PROTECTED',
        < 0.75 => 'CAUTION',
        _ => 'HIGH RISK',
      };

  @override
  State<ThreatCore> createState() => _ThreatCoreState();
}

class _ThreatCoreState extends State<ThreatCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forThreat(widget.score);
    final score100 = (widget.score * 100).round().clamp(0, 100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            final breath = 0.5 + 0.5 * _breath.value; // 0..1 slow sine-ish
            final amp = widget.amplitude.clamp(0.0, 1.0);
            final pulse = 1.0 + breath * 0.015 + amp * 0.10;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.score),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animatedScore, _) {
                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _CorePainter(
                      score: animatedScore,
                      color: color,
                      pulse: pulse,
                      amplitude: amp,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$score100',
                                  style: AppTypography.displaySmall.copyWith(
                                    color: color,
                                    fontSize: 52,
                                  ),
                                ),
                                TextSpan(
                                  text: ' /100',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'THREAT SCORE',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              ThreatCore.stateLabel(widget.score),
                              key: ValueKey(ThreatCore.stateLabel(widget.score)),
                              style: AppTypography.labelSmall.copyWith(
                                color: color,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (widget.isDemoAudio) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              'DEMO AUDIO',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CorePainter extends CustomPainter {
  _CorePainter({
    required this.score,
    required this.color,
    required this.pulse,
    required this.amplitude,
  });

  final double score;
  final Color color;
  final double pulse;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 14;

    // Soft inner fill that breathes with the audio amplitude.
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.06 + amplitude * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius * 0.72 * pulse, innerPaint);

    // Track ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = AppColors.borderSubtle,
    );

    // Score arc.
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      score * 2 * pi,
      false,
      arcPaint,
    );

    // Restrained glow on the arc — no neon.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      score * 2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(_CorePainter old) =>
      old.score != score ||
      old.color != color ||
      old.pulse != pulse ||
      old.amplitude != amplitude;
}
