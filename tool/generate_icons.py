"""PauseSignal brand icon generator.

Renders the SignalMark — two concentric signal paths (conversation
evidence leading, acoustic evidence following) converging on a
terminal decision node — on the product's dark graphite foundation.
The mark is the canonical design painted by `SignalMark` /
`_SignalMarkPainter` in `lib/core/widgets/signal_mark.dart`; keep the
two implementations in sync. Deliberately no shield, no initials, no
wordmark — readable at favicon size.

Usage:  python tool/generate_icons.py

Outputs:
  android/app/src/main/res/mipmap-*/ic_launcher.png      legacy square
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  adaptive fg
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml    adaptive
  android/app/src/main/res/values/ic_launcher_background.xml    adaptive bg
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png   iOS set
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png
  web/icons/Icon-*.png, web/favicon.png                         web set
  submission/pausesignal-icon-1024.png                          Shipaton
"""

import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── Palette (lib/core/theme/app_colors.dart) ─────────────────────────
BG = (11, 13, 19, 255)          # 0B0D13 — graphite base
ACCENT = (139, 156, 201, 255)   # 8B9CC9 — accent, conversation path
ACOUSTIC = (201, 178, 132, 255)  # C9B284 — signalAcoustic, voice path

# ── SignalMark geometry (mirrors _SignalMarkPainter) ─────────────────
_START = math.pi * 0.62
_SWEEP = math.pi * 1.55


def _draw_signal_mark(d, cx, cy, span):
    """Paint the SignalMark centred at (cx, cy) inside `span` px.

    Replicates _SignalMarkPainter: outer accent arc (start 0.62π,
    sweep 1.55π), inner acoustic arc (radius −24% span, sweep 0.82×,
    phase 0.10×sweep), round caps, terminal node on the outer path.
    """
    outer_r = span / 2 - 1.5
    inner_r = outer_r - span * 0.24
    stroke = max(2, round(span * 0.085))

    def arc(r, color, sweep, start):
        # PIL arcs use degrees, 0 at 3 o'clock, clockwise — same
        # orientation convention as Flutter's drawArc.
        bbox = [cx - r, cy - r, cx + r, cy + r]
        d.arc(bbox, math.degrees(start), math.degrees(start + sweep),
              fill=color, width=stroke)
        # Round caps: disks at both arc endpoints.
        cap_r = stroke / 2
        for a in (start, start + sweep):
            px, py = cx + r * math.cos(a), cy + r * math.sin(a)
            d.ellipse([px - cap_r, py - cap_r, px + cap_r, py + cap_r],
                      fill=color)

    arc(outer_r, ACCENT, _SWEEP, _START)
    arc(inner_r, ACOUSTIC, _SWEEP * 0.82, _START + _SWEEP * 0.10)

    # Terminal node on the outer path — the decision point.
    end = _START + _SWEEP
    nx, ny = cx + outer_r * math.cos(end), cy + outer_r * math.sin(end)
    node_r = stroke * 0.62
    d.ellipse([nx - node_r, ny - node_r, nx + node_r, ny + node_r],
              fill=ACCENT)


def render(size, *, maskable=False, square_full_bleed=False):
    """Render the PauseSignal mark at `size` px.

    maskable:       full-bleed background, motif inside safe zone.
    square_full_bleed: opaque square (iOS — Apple applies the mask).
    default:        rounded-square with transparent corners.
    """
    S = size * 4  # 4x supersample for clean downscale
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    if maskable or square_full_bleed:
        d.rectangle([0, 0, S, S], fill=BG)
    else:
        d.rounded_rectangle([0, 0, S, S], radius=S * 0.225, fill=BG)

    # Motif scale: maskable keeps the mark inside the inner ~62% safe
    # zone; full-bleed squares ~74%; legacy rounded ~76%.
    span = S * (0.56 if maskable else 0.74 if square_full_bleed
                else 0.76)
    _draw_signal_mark(d, S / 2, S / 2, span)

    return img.resize((size, size), Image.LANCZOS)


def render_adaptive_foreground(size):
    """Transparent adaptive-icon foreground — mark inside the 66dp
    safe zone of the 108dp canvas (~61%)."""
    S = size * 4
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    _draw_signal_mark(d, S / 2, S / 2, S * 0.56)
    return img.resize((size, size), Image.LANCZOS)


def save(img, rel):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"  {rel}  {img.size[0]}x{img.size[1]}")


def main():
    print("Android legacy mipmaps:")
    for dpi, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                    ("xxhdpi", 144), ("xxxhdpi", 192)]:
        save(render(px), f"android/app/src/main/res/mipmap-{dpi}/ic_launcher.png")
        save(render_adaptive_foreground(int(px * 2.25)),
             f"android/app/src/main/res/mipmap-{dpi}/ic_launcher_foreground.png")

    # Adaptive icon declaration + background color.
    os.makedirs(os.path.join(ROOT, "android/app/src/main/res/mipmap-anydpi-v26"),
                exist_ok=True)
    with open(os.path.join(ROOT,
            "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"),
            "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '</adaptive-icon>\n')
    with open(os.path.join(ROOT,
            "android/app/src/main/res/values/ic_launcher_background.xml"),
            "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<resources>\n'
                '    <color name="ic_launcher_background">#0B0D13</color>\n'
                '</resources>\n')
    print("  mipmap-anydpi-v26/ic_launcher.xml + ic_launcher_background.xml")

    print("iOS AppIcon set:")
    ios = [
        ("Icon-App-20x20@1x.png", 20), ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60), ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58), ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40), ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120), ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180), ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152), ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for name, px in ios:
        save(render(px, square_full_bleed=True),
             f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{name}")

    print("iOS launch image:")
    for name, px in [("LaunchImage.png", 168), ("LaunchImage@2x.png", 336),
                     ("LaunchImage@3x.png", 504)]:
        save(render(px), f"ios/Runner/Assets.xcassets/LaunchImage.imageset/{name}")

    print("Web icons:")
    save(render(192), "web/icons/Icon-192.png")
    save(render(512), "web/icons/Icon-512.png")
    save(render(192, maskable=True), "web/icons/Icon-maskable-192.png")
    save(render(512, maskable=True), "web/icons/Icon-maskable-512.png")
    save(render(32), "web/favicon.png")

    print("Shipaton source:")
    save(render(1024, square_full_bleed=True),
         "submission/pausesignal-icon-1024.png")


if __name__ == "__main__":
    main()
