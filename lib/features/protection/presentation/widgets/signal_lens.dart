import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/audio_forensic_metrics.dart';

/// VoxGuard's product signature: the **Signal Lens** — two signal
/// paths read by one human decision.
///
/// Layer A (outer path) is conversation / semantic evidence. Layer B
/// (inner path) is acoustic / voice evidence. Each path sweeps in
/// proportion to the evidence that layer actually produced:
///
/// - calm — the paths run together, nearly aligned;
/// - rising risk — the paths diverge and become unstable;
/// - acoustic-only sessions — the conversation path renders as a
///   broken, dimmed outline: visibly absent, never fabricated.
///
/// The composite score stays a *risk signal* — it is never presented
/// as a probability, and the lens is deliberately not a speedometer.
///
/// **Missing signal ≠ safe.** When [conversationAnalyzed] is false the
/// lens enters its incomplete state: no SAFE/CAUTION/HIGH RISK band,
/// no fused composite readout — just the acoustic evidence that
/// actually exists. The fusion weighting (semantic × 0.65) would
/// otherwise cap an acoustic-only composite at 0.35 and let a strongly
/// elevated voice anomaly read as "SAFE", which is a lie.
class SignalLens extends StatefulWidget {
  const SignalLens({
    super.key,
    required this.score,
    required this.acousticScore,
    required this.conversationAnalyzed,
    this.semanticScore,
    this.amplitude = 0,
    this.isDemoAudio = false,
    this.size = 230,
    this.showLegend = true,
  });

  /// Composite risk signal, 0.0–1.0 — shown only when
  /// [conversationAnalyzed] is true.
  final double score;

  /// Whether the conversation/semantic engine actually produced
  /// evidence this session. **Explicit scope, not inferred from a
  /// score:** false means the conversation layer never ran, so the
  /// lens must not render a fused band or verdict.
  final bool conversationAnalyzed;

  /// Engine B evidence, 0.0–1.0. Expected to be non-null when
  /// [conversationAnalyzed] is true; ignored in the partial state.
  final double? semanticScore;

  /// Engine A evidence (synthetic-voice / acoustic anomaly), 0.0–1.0.
  final double acousticScore;

  /// Latest audio amplitude (RMS) feeding the breathing motion.
  final double amplitude;

  /// Whether the amplitude stream is generated demo PCM.
  final bool isDemoAudio;

  final double size;

  /// Whether the two-layer legend renders beneath the lens.
  final bool showLegend;

  /// Display state for a score — the single source of truth for the
  /// label used across the product. "Safe" is a score band, never a
  /// guarantee — the score is a composite risk signal, not a verdict.
  static String stateLabel(double score) => switch (score) {
        < 0.40 => 'SAFE',
        < 0.75 => 'CAUTION',
        _ => 'HIGH RISK',
      };

  /// Short human interpretation for the current band — the message a
  /// person should read first, before any number.
  static String interpretation(double score) => switch (score) {
        < 0.40 => 'Signals look normal — keep listening.',
        < 0.75 => 'Something feels off — watch the signals.',
        _ => 'Pause before acting.',
      };

  @override
  State<SignalLens> createState() => _SignalLensState();
}

class _SignalLensState extends State<SignalLens>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the platform reduced-motion setting: the ambient
    // breathing loop stops entirely; state still renders instantly
    // (no tween) so evidence stays truthful.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce && _breath.isAnimating) {
      _breath.stop();
    } else if (!reduce && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Partial scope: the conversation layer never ran. The lens must
    // not mint a SAFE/CAUTION/HIGH RISK band or a fused /100 verdict
    // from a composite that structurally ignores the missing layer.
    final partial = !widget.conversationAnalyzed;
    final semantic =
        partial ? null : (widget.semanticScore ?? 0.0);
    final acoustic100 =
        (widget.acousticScore * 100).round().clamp(0, 100);
    // Acoustic elevation reuses the domain threshold — the lens does
    // not duplicate fusion/verdict logic.
    final acousticElevated =
        widget.acousticScore >= AudioForensicMetrics.elevatedThreshold;
    final color = partial
        ? (acousticElevated
            ? AppColors.statusWarning
            : AppColors.textMuted)
        : AppColors.forThreat(widget.score);
    final score100 = (widget.score * 100).round().clamp(0, 100);
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final stateText = partial
        ? AppStrings.signalPartialState
        : SignalLens.stateLabel(widget.score);
    final centerNumber = partial ? acoustic100 : score100;
    final centerCaption =
        partial ? AppStrings.acousticAnomalyLabel : 'RISK SIGNAL';
    // The instability driver is the evidence on display — in partial
    // mode that is the acoustic score, not the capped composite.
    final motionScore = partial ? widget.acousticScore : widget.score;
    final semanticsLabel = partial
        ? 'Partial signal — acoustic anomaly $acoustic100 of 100. '
            'Conversation analysis not run.'
        : 'Risk signal $stateText, $score100 of 100. '
            'Acoustic analysis $acoustic100 of 100.';

    Widget lens(double animatedScore, double phase, double amp) =>
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Semantics(
            label: semanticsLabel,
            child: CustomPaint(
              painter: _SignalLensPainter(
                score: animatedScore,
                semanticScore: semantic,
                acousticScore: widget.acousticScore,
                color: color,
                phase: phase,
                amplitude: amp,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large-text safety: the label may scale down to
                    // fit the lens rather than overflow the ring.
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: widget.size - 20),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 300),
                          child: Text(
                            stateText,
                            key: ValueKey(stateText),
                            maxLines: 1,
                            style: AppTypography.titleLarge.copyWith(
                              color: color,
                              fontSize: widget.size * 0.095,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text.rich inherits DefaultTextStyle — RichText
                    // alone leaves spans unfonted (Ahem boxes in
                    // capture harness, engine fallback on device).
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$centerNumber',
                            style: AppTypography.statLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: widget.size * 0.13,
                            ),
                          ),
                          TextSpan(
                            text: ' /100',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: widget.size * 0.055,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      centerCaption,
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: widget.size * 0.038,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    // Reduced-motion: render the final state directly — no ambient
    // breathing loop, no score tween.
    final Widget animatedLens = reduceMotion
        ? lens(motionScore, 0.0, 0.0)
        : AnimatedBuilder(
            animation: _breath,
            builder: (context, _) {
              final amp = widget.amplitude.clamp(0.0, 1.0);
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: motionScore),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, animatedScore, _) =>
                    lens(animatedScore, _breath.value, amp),
              );
            },
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        animatedLens,
        if (widget.showLegend) ...[
          const SizedBox(height: 14),
          _Legend(
            semanticScore: semantic,
            acousticScore: widget.acousticScore,
          ),
        ],
        if (widget.isDemoAudio) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

/// Legend naming the two signal paths — state is never color-only.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.semanticScore,
    required this.acousticScore,
  });

  final double? semanticScore;
  final double acousticScore;

  @override
  Widget build(BuildContext context) {
    // Wrap — at narrow widths / large text the two layer readouts
    // stack rather than overflow.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 6,
      children: [
        _LegendRow(
          color: AppColors.signalSemantic,
          label: 'Conversation',
          value: semanticScore == null
              ? 'not analyzed'
              : '${(semanticScore! * 100).round()}',
        ),
        _LegendRow(
          color: AppColors.signalAcoustic,
          label: 'Voice acoustics',
          value: '${(acousticScore * 100).round()}',
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final absent = value == 'not analyzed';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A missing layer reads as a broken segment, not a value.
        if (absent)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 3.4,
                  height: 3,
                  margin: const EdgeInsets.only(right: 1.6),
                  decoration: BoxDecoration(
                    color: AppColors.signalAbsent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          )
        else
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 9.5,
              letterSpacing: 0.7,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.borderSubtle,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 9.5,
              letterSpacing: 0.7,
              color:
                  absent ? AppColors.signalAbsent : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalLensPainter extends CustomPainter {
  _SignalLensPainter({
    required this.score,
    required this.semanticScore,
    required this.acousticScore,
    required this.color,
    required this.phase,
    required this.amplitude,
  });

  final double score;
  final double? semanticScore;
  final double acousticScore;
  final Color color;

  /// Breathing phase 0–1 from the ambient controller.
  final double phase;
  final double amplitude;

  /// Both paths start together at the lower-left and travel clockwise;
  /// the endpoint gap between them IS the divergence readout.
  static const double _startAngle = pi * 0.78; // ~140°
  static const double _maxSweep = pi * 1.66; // ~300°

  void _track(Canvas canvas, Offset c, double r, {bool dashed = false}) {
    if (!dashed) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        _startAngle,
        _maxSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = AppColors.borderSubtle.withValues(alpha: 0.55),
      );
      return;
    }
    // Broken outline for a layer that never ran — incomplete by
    // design, not "zero".
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.signalAbsent.withValues(alpha: 0.7);
    const dash = _maxSweep / 18;
    for (var i = 0; i < 18; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        _startAngle + i * dash,
        dash * 0.72,
        false,
        paint,
      );
    }
  }

  void _arc(
    Canvas canvas,
    Offset c,
    double r,
    double value,
    Color paintColor,
    double wobble,
  ) {
    if (value <= 0.004) return;
    final sweep = max(0.045, value) * _maxSweep;
    // Rising risk makes the path unstable — a subtle angular jitter
    // that grows with the composite score.
    final jitter = wobble * sin(phase * 2 * pi * 3);
    final start = _startAngle + jitter;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = paintColor,
    );
    // Terminal node — the "position" of the signal.
    final endAngle = start + sweep;
    final node = Offset(
      c.dx + r * cos(endAngle),
      c.dy + r * sin(endAngle),
    );
    canvas.drawCircle(node, 4.6, Paint()..color = paintColor);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2 - 16;
    final innerR = outerR - 22;

    // Risk-driven instability: 0 when calm, visible jitter when high.
    final wobble = score >= 0.75
        ? 0.045
        : score >= 0.4
            ? 0.018
            : 0.0;
    // Gentle breathing — the lens is alive while it listens.
    final breathe = 1 + (phase - 0.5) * 0.02 + amplitude * 0.05;

    // Soft inner field that responds to the live audio level.
    canvas.drawCircle(
      center,
      (innerR - 14) * breathe,
      Paint()
        ..color = color.withValues(alpha: 0.05 + amplitude * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Layer A — conversation / semantic evidence (outer path).
    final semantic = semanticScore;
    _track(canvas, center, outerR, dashed: semantic == null);
    if (semantic != null) {
      _arc(
        canvas,
        center,
        outerR,
        semantic,
        AppColors.forSignalLayer(AppColors.signalSemantic, semantic),
        wobble,
      );
    }

    // Layer B — acoustic / voice evidence (inner path). Always real:
    // acoustic analysis runs in every session mode.
    _track(canvas, center, innerR);
    _arc(
      canvas,
      center,
      innerR,
      acousticScore,
      AppColors.forSignalLayer(AppColors.signalAcoustic, acousticScore),
      -wobble, // the two paths shear apart under pressure
    );
  }

  @override
  bool shouldRepaint(_SignalLensPainter old) =>
      old.score != score ||
      old.semanticScore != semanticScore ||
      old.acousticScore != acousticScore ||
      old.color != color ||
      old.phase != phase ||
      old.amplitude != amplitude;
}
