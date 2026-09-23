import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../services/haptics/app_haptics.dart';
import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// PauseSignal material system — the layered surfaces every screen is
/// built from.
///
/// Two material families, deliberately separated:
///
/// - [SurfaceCard] — the everyday content surface. A translucent
///   fill over the screen's ambient bloom, a hairline edge, a faint
///   top sheen, and one soft shadow. No blur: cheap enough for list
///   rows and repeated cards.
/// - [GlassPanel] — the chromed surface. A real `BackdropFilter`
///   blur reserved for floating chrome (navigation, sheets, overlays)
///   where content visibly passes beneath. Never use it for ordinary
///   cards — blur is the most expensive layer in the system.
///
/// Both derive every color from [AppPalette], so accent
/// personalization, dark/light palettes and RTL flow through
/// automatically. Safety semantics are never tinted by the accent.
abstract final class PsGlass {
  PsGlass._();

  static bool _dark(AppPalette p) => p.brightness == Brightness.dark;

  /// Translucent card fill — lets the ambient bloom read through.
  static Color fill(AppPalette p, {bool elevated = false}) {
    if (_dark(p)) {
      return elevated
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.085)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.048);
    }
    return elevated
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.92)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.72);
  }

  /// Frosted chrome fill over a blur — darker in dark mode so
  /// blurred content doesn't wash the bar out.
  static Color chromeFill(AppPalette p) => _dark(p)
      ? p.bgBase.withValues(alpha: 0.55)
      : p.bgElevated.withValues(alpha: 0.72);

  /// Hairline edge — reads as a rim of light on dark glass, a cool
  /// edge on pearl surfaces.
  static Color edge(AppPalette p) => _dark(p)
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
      : p.borderSubtle.withValues(alpha: 0.85);

  /// Top sheen — the "light through glass" highlight that separates
  /// a lifted surface from the background.
  static Gradient sheen(AppPalette p, {bool elevated = false}) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _dark(p)
            ? [
                const Color(0xFFFFFFFF)
                    .withValues(alpha: elevated ? 0.075 : 0.05),
                const Color(0xFFFFFFFF).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFFFFFFFF)
                    .withValues(alpha: elevated ? 0.9 : 0.55),
                const Color(0xFFFFFFFF).withValues(alpha: 0.0),
              ],
        stops: const [0.0, 0.42],
      );

  /// A single soft shadow — depth without the stacked-grey look.
  static List<BoxShadow> shadow(AppPalette p) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: _dark(p) ? 0.32 : 0.10),
          blurRadius: _dark(p) ? 22 : 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// The everyday content surface — translucent, sheened, hairline-edged,
/// softly shadowed. Replaces the flat `surfaceCard + border` card
/// idiom across the app.
///
/// Wraps [child] in [Material] + [InkWell] when [onTap] is set, so
/// callers keep ripple feedback for free.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 18,
    this.elevated = false,
    this.tint,
    this.tintAlpha = 0.08,
    this.onTap,
    this.margin,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  /// A slightly lifted variant — hero surfaces and primary cards.
  final bool elevated;

  /// Optional semantic tint (e.g. a status color) laid under the
  /// sheen. Kept subtle so the glass language survives the tint.
  final Color? tint;
  final double tintAlpha;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  /// Overrides the default hairline — used by selected or semantic
  /// states that need a stronger edge.
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = BorderRadius.circular(radius);
    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: content,
      );
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: PsGlass.sheen(p, elevated: elevated),
        color: tint?.withValues(alpha: tintAlpha) ?? PsGlass.fill(p),
        border: Border.all(
          color: borderColor ?? PsGlass.edge(p),
          width: borderWidth,
        ),
        boxShadow: PsGlass.shadow(p),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }
}

/// Frosted glass — a real [BackdropFilter] blur. Reserved for
/// floating chrome: navigation, modal sheets, overlay panels where
/// content visibly passes underneath. Expensive; never use for
/// ordinary content cards.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 20,
    this.borderRadius,
    this.padding,
    this.blur = 16,
    this.tint,
    this.tintAlpha = 1.0,
    this.border,
  });

  final Widget child;
  final double radius;

  /// Full-radius override (e.g. top-only corners on bottom sheets).
  /// Wins over [radius] when set.
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Blur strength — sigma for both axes. Keep within 10–22; higher
  /// values smear text edges behind the panel.
  final double blur;

  /// Optional color mixed with the chrome fill (e.g. a status tint).
  final Color? tint;
  final double tintAlpha;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = tint == null
        ? PsGlass.chromeFill(p)
        : Color.alphaBlend(
            tint!.withValues(alpha: 0.10 * tintAlpha),
            PsGlass.chromeFill(p),
          );
    final r = borderRadius ?? BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: r,
            border: border ?? Border.all(color: PsGlass.edge(p)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// One consistent pill for truth badges, plan chips and evidence
/// markers — the radii/alpha rules live here so labels can't drift.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.color,
    required this.label,
    this.icon,
    this.compact = false,
  });

  final Color color;
  final String label;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3.5 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          // Loose-fit so the label ellipsizes under a bounded parent
          // (e.g. an AppBar slot at 320px) instead of overflowing.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontSize: compact ? 9 : 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Eyebrow-style section header — the quiet divider between card
/// groups. Consistent letter-spaced small caps.
class PsSectionHeader extends StatelessWidget {
  const PsSectionHeader(this.title, {super.key, this.top = 22});

  final String title;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, top, 0, 10),
      child: Text(title, style: AppTypography.labelSmall),
    );
  }
}

/// Press feedback — a 140 ms, 3% compression that makes cards and
/// tiles feel physical without ripples being the only response.
///
/// Honors the reduced-motion contract (`MediaQuery.disableAnimations`
/// already ORs the OS flag and the app's Reduced Motion preference):
/// under it the wrapper is inert and the tap still fires instantly.
///
/// The child keeps its own [InkWell]/button for the actual tap and
/// ripple — this widget only observes the pointer for scale.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.haptic = false,
    this.scale = 0.97,
  });

  final Widget child;

  /// Fire [AppHaptics.tap] on press-down — use on primary cards and
  /// committed actions only, never list rows.
  final bool haptic;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (v == _down || !mounted) return;
    setState(() => _down = v);
    if (v && widget.haptic) AppHaptics.tap();
  }

  @override
  Widget build(BuildContext context) {
    final reduce =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final child = GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: widget.child,
    );
    if (reduce) return child;
    return AnimatedScale(
      scale: _down ? widget.scale : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}
