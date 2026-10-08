#!/usr/bin/env python3
"""Builds every app-icon source under assets/icon/ from assets/images/logo.png.

The logo is a flattened PNG — a white glyph on a gradient circle — but icons need
those two things apart: Android's adaptive icon wants them as separate layers,
and each platform wants the pair recomposed differently. So the glyph is isolated
by its near-white pixels and the brand gradient is synthesised behind it.

Outputs, all consumed by flutter_launcher_icons.yaml:

  adaptive_foreground.png  the glyph alone, sized for the 108dp adaptive layer;
                           also serves as the Android 13+ monochrome layer, which
                           is the same silhouette
  adaptive_background.png  the gradient, full bleed so every mask shape is filled
  icon_android.png         legacy mipmap for API < 26: the pair recomposed as the
                           brand circle, so old launchers match the adaptive look
  icon_ios.png             full-bleed square: iOS applies its own rounded-rect
                           mask, so anything with transparent corners ends up a
                           black tile with a small circle floating in it

It also writes the native launch-screen images directly into the android/ and
ios/ trees, because those have to match: the Android 12+ system splash draws the
adaptive icon, and the pre-31 launch screen and the iOS storyboard have to show
the same mark or the handoff into SplashScreen visibly changes. Drawing the raw
logo there put its thin white ring on screen for one of the three.

Run this, then `dart run flutter_launcher_icons`.

Usage:  python3 tool/build_icons.py
"""

import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGO = os.path.join(ROOT, 'assets/images/logo.png')
OUT = os.path.join(ROOT, 'assets/icon')

SIZE = 1024

# Brand fill, matching the logo's circle. Flat: the logo's blue-to-violet
# gradient was removed in favour of a single #0266FA (the app's primary, see
# AppTheme.primary), so the background synthesised here has to be flat too or
# the launcher icons would disagree with the artwork everywhere else.
# GRAD_START/GRAD_END are kept as the two ends of the ramp so gradient() below
# is unchanged; identical ends simply make it render a solid fill.
BRAND = (2, 102, 250)
GRAD_START = BRAND
GRAD_END = BRAND

# Android adaptive icon geometry: 108dp layers of which the inner 72dp is the
# area every mask is guaranteed to show.
VIS = 72 / 108

# Glyph width as a fraction of its canvas, per target. The adaptive value is
# chosen against the 72dp viewport rather than the full layer; the other two are
# against the whole image, since nothing crops them further.
GLYPH_ADAPTIVE = 0.50
GLYPH_ANDROID = 0.69   # matches the glyph's share of the circle in the logo
GLYPH_IOS = 0.60       # a little tighter: no circle frames it, and iOS rounds


def extract_glyph():
    """The white glyph from the logo, cropped to its bounds, as RGBA."""
    src = Image.open(LOGO).convert('RGBA')
    w, h = src.size
    cx, cy = w / 2, h / 2
    # Stay inside the logo's outer white ring, or the ring reads as artwork.
    inner = (w / 2) * 0.93
    px = src.load()

    glyph = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gp = glyph.load()
    for y in range(h):
        dy = y - cy
        for x in range(w):
            dx = x - cx
            if dx * dx + dy * dy > inner * inner:
                continue
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            mx, mn = max(r, g, b), min(r, g, b)
            # Bright and unsaturated is the glyph; the gradient is deeply
            # saturated everywhere else.
            if mx > 170 and (mx - mn) < 46:
                gp[x, y] = (255, 255, 255, 255)
    return glyph.crop(glyph.getbbox())


def place(glyph, fraction, size=SIZE):
    """The glyph centred on a transparent square, at `fraction` of its width."""
    target = round(size * fraction)
    scale = target / max(glyph.size)
    scaled = glyph.resize(
        (round(glyph.width * scale), round(glyph.height * scale)), Image.LANCZOS
    )
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2)
    )
    return canvas


def gradient(span, size=SIZE):
    """The brand gradient on a diagonal, with its full range inside `span`.

    `span` is the (lo, length) window of raw diagonal position — (x+y)/2s — that
    the blue-to-violet range is mapped onto. Anything outside it holds the end
    colours. Without this the visible part of the icon only ever shows the middle
    of the ramp and the gradient reads as flat.
    """
    lo, length = span
    img = Image.new('RGB', (size, size))
    p = img.load()
    for y in range(size):
        for x in range(size):
            raw = (x + y) / (2 * (size - 1))
            t = min(1.0, max(0.0, (raw - lo) / length))
            p[x, y] = tuple(
                round(GRAD_START[i] + (GRAD_END[i] - GRAD_START[i]) * t)
                for i in range(3)
            )
    return img


def diagonal_span(diameter_fraction):
    """The raw-diagonal window covered by a centred circle of that diameter.

    A diagonal ramp spans only d*sqrt(2)/2 across a circle of diameter d, centred
    on 0.5 — not the whole 0..1 — so the range has to be mapped onto exactly that.
    """
    half = diameter_fraction * math.sqrt(2) / 4
    return (0.5 - half, 2 * half)


def circle_mask(size=SIZE):
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    return mask


def save(img, name):
    path = os.path.join(OUT, name)
    img.save(path, 'PNG', optimize=True)
    print(f'  {name:<28} {img.size[0]}px  {os.path.getsize(path) // 1024}KB')


def main():
    os.makedirs(OUT, exist_ok=True)
    glyph = extract_glyph()
    print(f'glyph {glyph.size[0]}x{glyph.size[1]} extracted from logo.png')

    # --- Android adaptive layers -------------------------------------------
    # The monochrome layer is the same silhouette, so it is not written twice —
    # flutter_launcher_icons is pointed at this file for both.
    save(place(glyph, GLYPH_ADAPTIVE), 'adaptive_foreground.png')
    save(gradient(diagonal_span(VIS)), 'adaptive_background.png')

    # --- Legacy Android mipmap ---------------------------------------------
    # The circle fills the image, so the gradient is mapped across its diagonal.
    android = gradient(diagonal_span(1.0)).convert('RGBA')
    android.alpha_composite(place(glyph, GLYPH_ANDROID))
    android.putalpha(circle_mask())
    save(android, 'icon_android.png')

    # --- iOS ----------------------------------------------------------------
    # Full bleed, corner to corner: iOS masks it to a rounded rect itself, and
    # any transparency here is flattened to background_color_ios first.
    ios = gradient((0.0, 1.0)).convert('RGBA')
    ios.alpha_composite(place(glyph, GLYPH_IOS))
    save(ios, 'icon_ios.png')

    build_splash_icon(glyph)
    build_launch_screens(android)


# Diameter the native launch screens draw the mark at. Must stay in step with
# _logoLaunchSize in lib/features/auth/screens/splash_screen.dart — it is the
# size Android's splash spec gives an icon with no icon background, and the size
# SplashScreen's first frame expects to inherit.
LAUNCH_DP = 192

DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


# Canvas the Android 12+ system splash draws its icon into.
SPLASH_DP = 288


def build_splash_icon(glyph):
    """The Android 12+ system splash icon, cut at the size the splash draws it.

    Same composition as the adaptive launcher icon — full-bleed gradient so the
    system's circular mask cuts through artwork rather than through an edge, glyph
    at the same proportion — but rasterised for a 288dp canvas rather than the
    launcher's 108dp. Pointing the splash straight at @mipmap/ic_launcher looks
    correct and is correct geometrically, but makes the system upscale a 108dp
    asset by 2.67x, and it lands visibly soft.
    """
    top = round(SPLASH_DP * max(DENSITIES.values()))
    base = gradient(diagonal_span(VIS), size=top).convert('RGBA')
    base.alpha_composite(place(glyph, GLYPH_ADAPTIVE, size=top))

    print('android 12+ splash icon:')
    for name, mult in DENSITIES.items():
        px = round(SPLASH_DP * mult)
        path = os.path.join(
            ROOT, f'android/app/src/main/res/drawable-{name}/splash_icon.png'
        )
        os.makedirs(os.path.dirname(path), exist_ok=True)
        base.resize((px, px), Image.LANCZOS).save(path, 'PNG', optimize=True)
        print(f'  drawable-{name}/splash_icon.png    {px}px')


def build_launch_screens(mark):
    """The pre-31 Android launch image and the iOS storyboard image.

    Fed the same recomposed circle as the legacy mipmap rather than the raw logo,
    so all three native launch paths — Android 12+ system splash, pre-31 launch
    screen, iOS storyboard — show a mark with no white ring, matching what
    SplashScreen paints on its first frame.
    """
    print('native launch screens:')
    for name, mult in DENSITIES.items():
        px = round(LAUNCH_DP * mult)
        path = os.path.join(
            ROOT, f'android/app/src/main/res/drawable-{name}/launch_logo.png'
        )
        os.makedirs(os.path.dirname(path), exist_ok=True)
        mark.resize((px, px), Image.LANCZOS).save(path, 'PNG', optimize=True)
        print(f'  drawable-{name}/launch_logo.png    {px}px')

    for scale in (1, 2, 3):
        suffix = '' if scale == 1 else f'@{scale}x'
        px = LAUNCH_DP * scale
        path = os.path.join(
            ROOT,
            f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png',
        )
        mark.resize((px, px), Image.LANCZOS).save(path, 'PNG', optimize=True)
        print(f'  LaunchImage{suffix}.png{" " * (18 - len(suffix))}{px}px')


if __name__ == '__main__':
    main()
