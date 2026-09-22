import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// In-app bootstrap surface shown while first-run state loads.
///
/// The two SignalMark paths drift inward and settle — subtle opacity,
/// scale and path movement only. No shield, no scanner, no fake
/// progress. Reduced-motion users get a static mark + gentle fade.
/// The gate replaces it as soon as real state resolves — no
/// artificial dwell.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key});

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    // Ambient motion is driven entirely by the animation; when the
    // platform asks for reduced motion we never start the controller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.of(context).disableAnimations) {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduced = MediaQuery.of(context).disableAnimations;
    if (reduced) _c.value = 1.0;

    final outer = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    );
    final inner = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.12, 1.0, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: p.bgBase,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Opacity(
              opacity: reduced ? 1.0 : (0.35 + 0.65 * inner.value),
              child: Transform.scale(
                scale: reduced ? 1.0 : (0.92 + 0.08 * outer.value),
                child: CustomPaint(
                  size: const Size.square(96),
                  painter: _LaunchMarkPainter(
                    primary: p.signalSemantic,
                    secondary: p.signalAcoustic,
                    progressOuter: reduced ? 1.0 : outer.value,
                    progressInner: reduced ? 1.0 : inner.value,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Draws the two SignalMark paths partially — each arc sweeps only up
/// to its progress, so the paths visibly *arrive* and converge.
class _LaunchMarkPainter extends CustomPainter {
  _LaunchMarkPainter({
    required this.primary,
    required this.secondary,
    required this.progressOuter,
    required this.progressInner,
  });

  final Color primary;
  final Color secondary;
  final double progressOuter;
  final double progressInner;

  static const double _start = 3.1415926535897932 * 0.62;
  static const double _sweep = 3.1415926535897932 * 1.55;

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

    arc(outerR, primary, _sweep * progressOuter, _start);
    arc(innerR, secondary, _sweep * 0.82 * progressInner,
        _start + _sweep * 0.10);

    if (progressOuter > 0.97) {
      final endAngle = _start + _sweep;
      canvas.drawCircle(
        Offset(c.dx + outerR * cos(endAngle),
            c.dy + outerR * sin(endAngle)),
        stroke * 0.62,
        Paint()..color = primary,
      );
    }
  }

  @override
  bool shouldRepaint(_LaunchMarkPainter old) =>
      old.progressOuter != progressOuter ||
      old.progressInner != progressInner;
}
