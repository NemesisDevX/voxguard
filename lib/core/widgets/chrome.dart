import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'surfaces.dart';

/// PauseSignal chrome — the floating/translucent layers that frame
/// content: ambient background, frosted top bars, floating nav.
///
/// Blur policy: [GlassAppBar] and [GlassNavBar] are the only chrome
/// that blurs. Content slides under them via `extendBodyBehindAppBar`
/// / `extendBody` on the owning Scaffold — the blur is earned by
/// motion, not decoration.
///
/// Clearance contract: screens hosted under floating chrome pad their
/// scroll views by [PsMetrics.appBarClearance] / [PsMetrics.navClearance]
/// so chrome floats over content instead of covering it.
abstract final class PsMetrics {
  PsMetrics._();

  /// Floating nav bar height (excluding its outer margin).
  static const double navBarHeight = 62;

  /// Bottom inset a scrollable needs so content clears the floating
  /// nav: bar + outer margins + a small gap.
  static const double navClearance = navBarHeight + 34;

  /// Top inset a scrollable needs under a frosted app bar.
  static double appBarClearance(BuildContext context) =>
      kToolbarHeight + MediaQuery.paddingOf(context).top + 6;
}

/// The spatial foundation beneath a screen — two restrained radial
/// blooms that give translucent surfaces something to transmit.
///
/// Static by design: one paint pass, wrapped in a RepaintBoundary, no
/// animation — so it is inherently free under Reduced Motion and adds
/// zero continuous repaint cost. [tint] drifts the upper bloom toward
/// a semantic color (the HIGH RISK atmospheric shift) — still a
/// single static paint per state change.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.tint, this.tintAlpha = 0.0});

  /// Semantic color blended into the upper bloom (e.g. statusDanger
  /// at high risk). Null or alpha 0 leaves the neutral accent bloom.
  final Color? tint;
  final double tintAlpha;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AmbientPainter(
              accent: p.accent,
              acoustic: p.signalAcoustic,
              dark: p.brightness == Brightness.dark,
              tint: tint,
              tintAlpha: tintAlpha,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.accent,
    required this.acoustic,
    required this.dark,
    this.tint,
    this.tintAlpha = 0.0,
  });

  final Color accent;
  final Color acoustic;
  final bool dark;
  final Color? tint;
  final double tintAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    // Upper bloom — the cool accent light the hero sits in. Centered
    // just above the top edge so only the lower fringe is visible.
    final upper = Rect.fromCircle(
      center: Offset(size.width * 0.5, -size.height * 0.12),
      radius: size.width * 0.95,
    );
    final upperColor = tint != null && tintAlpha > 0
        ? Color.lerp(accent, tint!, tintAlpha)!
        : accent;
    canvas.drawRect(
      upper,
      Paint()
        ..shader = RadialGradient(
          colors: [
            upperColor.withValues(alpha: dark ? 0.13 : 0.16),
            upperColor.withValues(alpha: 0.0),
          ],
        ).createShader(upper),
    );

    // Lower counter-bloom — a warm floor so the graphite doesn't read
    // as a void. Kept much fainter than the upper light.
    final lower = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 1.08),
      radius: size.width * 0.85,
    );
    canvas.drawRect(
      lower,
      Paint()
        ..shader = RadialGradient(
          colors: [
            acoustic.withValues(alpha: dark ? 0.05 : 0.07),
            acoustic.withValues(alpha: 0.0),
          ],
        ).createShader(lower),
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.accent != accent ||
      old.acoustic != acoustic ||
      old.dark != dark ||
      old.tint != tint ||
      old.tintAlpha != tintAlpha;
}

/// Frosted top chrome — a translucent bar that blurs content scrolling
/// beneath it. Use with `extendBodyBehindAppBar: true`; the screen's
/// scroll view should start with [PsMetrics.appBarClearance].
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      bottom: bottom,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: PsGlass.chromeFill(p),
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(
          color: PsGlass.edge(p).withValues(alpha: 0.6),
        ),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// One destination in [GlassNavBar]. Icons and labels stay identical
/// to the former Material items — only the container changed.
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// Floating glass navigation — a blurred pill inset from the edges,
/// with a soft accent glow on the selected destination.
///
/// Use with `extendBody: true` and give scroll views
/// [PsMetrics.navClearance] bottom padding so content can pass under
/// the bar instead of stopping at it.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassPanel(
          radius: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: SizedBox(
            height: PsMetrics.navBarHeight - 10,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.accent : p.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          // Large-text guard: under 1.5x+ scaling the item shrinks
          // as a unit instead of overflowing the fixed bar height.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              // Selected marker — a soft accent bead under the label.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 14 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
