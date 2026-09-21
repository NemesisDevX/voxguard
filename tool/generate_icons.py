"""VoxGuard brand icon generator.

Renders an original mark — a shield outline containing a rising
voice-waveform motif — on the product's dark graphite foundation.
Emerald (#10B981) is the safety accent; no text inside the icon.

Usage:  python tool/generate_icons.py

Outputs:
  android/app/src/main/res/mipmap-*/ic_launcher.png      legacy square
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  adaptive fg
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml    adaptive
  android/app/src/main/res/values/ic_launcher_background.xml    adaptive bg
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png   iOS set
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png
  web/icons/Icon-*.png, web/favicon.png                         web set
  submission/voxguard-icon-1024.png                             Shipaton
"""

import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── Palette (lib/core/theme/app_colors.dart) ─────────────────────────
BG = (11, 13, 19, 255)          # 0B0D13 — graphite base
SURFACE = (30, 35, 51, 255)     # 1E2333 — shield interior
EMERALD = (16, 185, 129, 255)   # 10B981 — restrained safety accent
EMERALD_HI = (52, 211, 153, 255)  # 34D399 — waveform highlight


def _shield_points(cx, cy, w, h):
    """Shield outline: flat top with rounded corners, straight upper
    sides, then a smooth quadratic taper to the bottom point.
    Returns clockwise polygon points."""
    x0, y0 = cx - w / 2, cy - h / 2
    x1, y1 = cx + w / 2, cy + h / 2
    r = w * 0.14          # top corner radius
    side_y = y0 + h * 0.42  # where the taper to the point begins

    def qbez(p0, p1, p2, steps):
        out = []
        for i in range(1, steps + 1):
            t = i / steps
            mt = 1 - t
            out.append((mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0],
                        mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1]))
        return out

    pts = []
    # left top corner: arc 180° → 270° around (x0+r, y0+r)
    steps = 16
    for i in range(steps + 1):
        a = math.pi + (math.pi / 2) * (i / steps)
        pts.append((x0 + r + r * math.cos(a), y0 + r + r * math.sin(a)))
    # top edge
    pts.append((x1 - r, y0))
    # right top corner: arc 270° → 360° around (x1-r, y0+r)
    for i in range(steps + 1):
        a = 3 * math.pi / 2 + (math.pi / 2) * (i / steps)
        pts.append((x1 - r + r * math.cos(a), y0 + r + r * math.sin(a)))
    # right side straight down to the taper start
    pts.append((x1, side_y))
    # right taper: quadratic to bottom point — control pulls the side
    # inward and downward for the classic shield sweep.
    pts += qbez((x1, side_y), (x1 - w * 0.06, y0 + h * 0.78),
                (cx, y1), 32)
    # left taper: mirror — control at (x0 + w*0.06, y0 + h*0.78),
    # ending at left side start.
    pts += qbez((cx, y1), (x0 + w * 0.06, y0 + h * 0.78),
                (x0, side_y), 32)
    # close up the left side (corner arc start handled implicitly)
    return pts


def render(size, *, maskable=False, square_full_bleed=False):
    """Render the VoxGuard mark at `size` px.

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
    # zone; full-bleed squares ~78%; legacy rounded ~80%.
    span = S * (0.62 if maskable else 0.78 if square_full_bleed else 0.80)
    sw, sh = span * 0.82, span  # shield width/height
    cx, cy = S / 2, S / 2

    # Shield ring: outer emerald fill + inset surface fill.
    d.polygon(_shield_points(cx, cy, sw, sh), fill=EMERALD)
    inset = sw * 0.115
    d.polygon(
        _shield_points(cx, cy + sh * 0.012, sw - 2 * inset,
                       sh - 2 * inset),
        fill=SURFACE,
    )

    # Voice waveform: three rising rounded bars inside the shield.
    bar_w = sw * 0.085
    gap = sw * 0.115
    heights = [sh * 0.26, sh * 0.42, sh * 0.30]
    total_w = 3 * bar_w + 2 * gap
    x = cx - total_w / 2
    for i, hgt in enumerate(heights):
        bx0 = x + i * (bar_w + gap)
        by = cy + sh * 0.04  # optical center
        color = EMERALD_HI if i == 1 else EMERALD
        d.rounded_rectangle(
            [bx0, by - hgt / 2, bx0 + bar_w, by + hgt / 2],
            radius=bar_w / 2,
            fill=color,
        )

    return img.resize((size, size), Image.LANCZOS)


def render_adaptive_foreground(size):
    """Transparent adaptive-icon foreground — motif inside the 66dp
    safe zone of the 108dp canvas (~61%)."""
    S = size * 4
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    span = S * 0.58
    sw, sh = span * 0.82, span
    cx, cy = S / 2, S / 2
    d.polygon(_shield_points(cx, cy, sw, sh), fill=EMERALD)
    inset = sw * 0.115
    d.polygon(
        _shield_points(cx, cy + sh * 0.012, sw - 2 * inset,
                       sh - 2 * inset),
        fill=SURFACE,
    )
    bar_w = sw * 0.085
    gap = sw * 0.115
    heights = [sh * 0.26, sh * 0.42, sh * 0.30]
    total_w = 3 * bar_w + 2 * gap
    x = cx - total_w / 2
    for i, hgt in enumerate(heights):
        bx0 = x + i * (bar_w + gap)
        by = cy + sh * 0.04
        color = EMERALD_HI if i == 1 else EMERALD
        d.rounded_rectangle(
            [bx0, by - hgt / 2, bx0 + bar_w, by + hgt / 2],
            radius=bar_w / 2,
            fill=color,
        )
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
    save(render(1024, square_full_bleed=True), "submission/voxguard-icon-1024.png")


if __name__ == "__main__":
    main()
