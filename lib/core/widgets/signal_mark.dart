import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Signal Mark — VoxGuard's primary visual symbol.
///
/// Two concentric signal paths, one slightly ahead of the other:
/// conversation evidence and acoustic evidence converging toward a
/// single human decision. Deliberately contains no shield, no
/// initials, and no wordmark — the symbol survives the pending public
/// rebrand unchanged.
class SignalMark extends StatelessWidget {
  const SignalMark({
    super.key,
    this.size = 26,
    this.color = AppColors.accent,
    this.secondaryColor = AppColors.signalAcoustic,
  });

  final double size;

  /// Outer path — conversation evidence.
  final Color color;

  /// Inner path — acoustic evidence.
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SignalMarkPainter(
          primary: color,
          secondary: secondaryColor,
        ),
      ),
    );
  }
}

class _SignalMarkPainter extends CustomPainter {
  _SignalMarkPainter({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;

  static const double _start = pi * 0.62;
  static const double _sweep = pi * 1.55;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outerR = size.width / 2 - 1.5;
    final innerR = outerR - size.width * 0.24;
    final stroke = size.width * 0.085;

    void arc(double r, Color color, double sweep, double start) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }

    // Outer path sweeps a little further — the conversation signal
    // leads; the voice signal follows.
    arc(outerR, primary, _sweep, _start);
    arc(innerR, secondary, _sweep * 0.82, _start + _sweep * 0.10);

    // Terminal node on the outer path — the decision point.
    final endAngle = _start + _sweep;
    canvas.drawCircle(
      Offset(c.dx + outerR * cos(endAngle), c.dy + outerR * sin(endAngle)),
      stroke * 0.62,
      Paint()..color = primary,
    );
  }

  @override
  bool shouldRepaint(_SignalMarkPainter old) =>
      old.primary != primary || old.secondary != secondary;
}
