#!/usr/bin/env python3
"""Builds assets/animations/splash_dots.json — the splash's Lottie animation.

The three dots type, then the logo builds itself around them: the dots bounce in
a staggered wave like a chat typing indicator, blink once, and then the speech
bubble grows outward from them while the handset swings in from the lower left.
The dots are real Lottie shapes and the raster parts exclude them on purpose, so
the dots that bounce at the start are literally the same dots in the finished
logo — nothing crossfades.

Authored in three acts — intro, loop, outro — whose boundaries ship as Lottie
markers, so SplashScreen can hold on the loop for as long as the app takes to
boot without the frame numbers being duplicated in Dart.

All geometry is measured from assets/images/logo.png rather than eyeballed: the
glyph is isolated by its near-white pixels and flood-filled into components, and
the dot positions and sizes come straight out of that. Generated rather than
hand-written because Lottie JSON is far too fiddly to edit by hand and keep
correct.

Usage:  python3 tool/build_splash_lottie.py
"""

import base64
import io
import json
import math
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGO = os.path.join(ROOT, 'assets/images/logo.png')
OUT_DOTS = os.path.join(ROOT, 'assets/animations/splash_dots.json')

SIZE = 512          # canvas, in Lottie units
FPS = 60
LAST_FRAME = 200    # generous layer out-point; the
                    # composition's own op is what bounds playback

# Lottie clips to the composition bounds, so the artwork cannot fill the canvas:
# the head's pop would push its edges outside and come back visibly faceted.
# Everything is laid out at logo proportions and then scaled by this to leave
# room for the largest frame of the pop.
FIT = 0.92
POP = 104

# Brand fill, matching the logo and the adaptive icon background — both flat
# AppTheme.primary, not the two-tone gradient this used to be.
BRAND = (2, 102, 250)


# ---------------------------------------------------------------- measurement


def _glyph_mask(work):
    """Binary mask of the glyph at `work` resolution, plus its components."""
    src = Image.open(LOGO).convert('RGBA')
    w, h = src.size
    cx, cy, inner = w / 2, h / 2, (w / 2) * 0.93
    px = src.load()
    step = w / work

    mask = [[False] * work for _ in range(work)]
    for j in range(work):
        for i in range(work):
            x, y = int(i * step), int(j * step)
            dx, dy = x - cx, y - cy
            if dx * dx + dy * dy > inner * inner:
                continue
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            mx, mn = max(r, g, b), min(r, g, b)
            if mx > 170 and (mx - mn) < 46:
                mask[j][i] = True

    seen = [[False] * work for _ in range(work)]
    comps = []
    for j in range(work):
        for i in range(work):
            if not mask[j][i] or seen[j][i]:
                continue
            q, pts = deque([(i, j)]), []
            seen[j][i] = True
            while q:
                a, b = q.popleft()
                pts.append((a, b))
                for da, db in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
                    na, nb = a + da, b + db
                    if 0 <= na < work and 0 <= nb < work and not seen[nb][na] and mask[nb][na]:
                        seen[nb][na] = True
                        q.append((na, nb))
            comps.append(pts)
    comps.sort(key=len, reverse=True)
    return comps

def _part_png(points, work):
    """One component as a white, antialiased SIZE x SIZE RGBA PNG.

    Rendered in the component's absolute position within the logo canvas, so the
    Lottie layer needs no offset — just the shared FIT scale.
    """
    m = Image.new('L', (work, work), 0)
    mp = m.load()
    for a, b in points:
        mp[a, b] = 255
    # Downscaling a hard binary mask is what gives the edges their antialiasing.
    m = m.resize((SIZE, SIZE), Image.LANCZOS)
    white = Image.new('L', (SIZE, SIZE), 255)
    return Image.merge('RGBA', (white, white, white, m))

def _embed(img):
    buf = io.BytesIO()
    img.save(buf, 'PNG', optimize=True)
    return 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode('ascii')


# --------------------------------------------------------------- lottie pieces

def prop(value, animated=None):
    """A static or keyframed Lottie property.

    `animated` is [(frame, value, ease_out_x, ease_in_x), ...]; the easing pair
    defaults to a soft ease so nothing moves linearly.
    """
    if animated is None:
        return {'a': 0, 'k': value}
    keys = []
    for idx, entry in enumerate(animated):
        frame, val = entry[0], entry[1]
        ox = entry[2] if len(entry) > 2 else 0.33
        ix = entry[3] if len(entry) > 3 else 0.67
        key = {'t': frame, 's': val if isinstance(val, list) else [val]}
        if idx < len(animated) - 1:
            key['o'] = {'x': [ox], 'y': [0]}
            key['i'] = {'x': [ix], 'y': [1]}
        keys.append(key)
    return {'a': 1, 'k': keys}

def transform(pos, anchor=(0, 0), scale=None, opacity=None, rotation=0):
    return {
        'o': opacity if isinstance(opacity, dict) else prop(100 if opacity is None else opacity),
        'r': rotation if isinstance(rotation, dict) else prop(rotation),
        'p': pos if isinstance(pos, dict) else prop(list(pos) + [0]),
        'a': prop(list(anchor) + [0]),
        's': scale if isinstance(scale, dict) else prop([100, 100, 100] if scale is None else scale),
    }

def layer(index, name, ks, shapes=None, ref=None, ty=4):
    base = {
        'ddd': 0, 'ind': index, 'ty': ty, 'nm': name, 'sr': 1,
        'ks': ks, 'ao': 0, 'ip': 0, 'op': LAST_FRAME, 'st': 0, 'bm': 0,
    }
    if ref is not None:
        base['refId'] = ref
    else:
        base['shapes'] = shapes or []
    return base

def ellipse(diameter, colour=(1, 1, 1)):
    return {
        'ty': 'gr', 'nm': 'ellipse', 'bm': 0, 'hd': False, 'it': [
            {'ty': 'el', 'd': 1, 'nm': 'e',
             'p': prop([0, 0]), 's': prop([diameter, diameter])},
            {'ty': 'fl', 'nm': 'fill', 'bm': 0, 'hd': False, 'r': 1,
             'c': prop(list(colour) + [1]), 'o': prop(100)},
            {'ty': 'tr', 'p': prop([0, 0]), 'a': prop([0, 0]),
             's': prop([100, 100]), 'r': prop(0), 'o': prop(100),
             'sk': prop(0), 'sa': prop(0)},
        ],
    }

# ----------------------------------------------------------------------- build

def build_dots():
    """The three dots type, blink, and the logo assembles around them.

    The dots are Lottie shapes rather than pixels, and the raster parts
    deliberately exclude them, so the dots that bounce at the start are the same
    dots that end up in the finished logo — no crossfade, no second copy.
    """
    # Component analysis at the logo's own resolution: the masks are binary, so
    # their only antialiasing comes from the downscale to SIZE. Working at 640
    # left barely a 1.25x reduction and the edges came out visibly stepped.
    WORK = Image.open(LOGO).size[0]
    comps = _glyph_mask(WORK)
    handset, bubble = comps[0], comps[1]
    dot_comps = sorted(comps[2:5], key=lambda p: sum(a for a, _ in p) / len(p))

    c = SIZE / 2

    def at(x, y):
        return (c + (x - c) * FIT, c + (y - c) * FIT)

    centres, dot_d = [], 0.0
    for pts in dot_comps:
        xs = [a for a, _ in pts]
        ys = [b for _, b in pts]
        centres.append(at(sum(xs) / len(pts) / WORK * SIZE,
                          sum(ys) / len(pts) / WORK * SIZE))
        dot_d = max(dot_d, (max(xs) - min(xs) + 1) / WORK * SIZE * FIT)

    # Timeline (60fps), in three acts so the splash can hold on the middle one
    # for as long as the app takes to boot:
    #
    #   intro  the complete logo, held briefly, then the handset and bubble
    #          dissolve away — frame 0 has to match the native launch screen
    #          exactly, or the handoff that the rest of the splash is built
    #          around falls apart;
    #   loop   one typing cycle, seamless because every layer is in an identical
    #          state at both ends;
    #   outro  a blink, then the logo rebuilds itself around the dots.
    #
    # The boundaries ship as Lottie markers rather than being duplicated in Dart.
    HOLD = 10
    LOOP_IN = 40
    CYCLE, LIFT = 48, 9
    LOOP_OUT = LOOP_IN + CYCLE
    BLINK = LOOP_OUT
    ASSEMBLE = BLINK + 9
    END = ASSEMBLE + 27

    hub = (sum(p[0] for p in centres) / 3, sum(p[1] for p in centres) / 3)
    away = (c - 54, c + 38)

    layers = []

    for idx, (cx_, cy_) in enumerate(centres):
        rest = [cx_, cy_, 0]
        lift = idx * LIFT
        t0 = LOOP_IN + lift

        pos = [(0, rest), (LOOP_IN, rest)]
        scale = [(0, [100, 100, 100]), (LOOP_IN, [100, 100, 100])]
        if lift:
            pos.append((t0, rest))
            scale.append((t0, [100, 100, 100]))
        pos += [(t0 + 9, [cx_, cy_ - 24, 0]), (t0 + 20, rest)]
        scale += [(t0 + 9, [116, 116, 100]), (t0 + 20, [100, 100, 100])]
        # Back to rest well before the cycle closes, so looping is seamless.
        pos.append((LOOP_OUT, rest))
        scale.append((LOOP_OUT, [100, 100, 100]))
        # The blink that opens the outro.
        scale += [(BLINK + 5, [100, 9, 100]), (ASSEMBLE, [100, 100, 100])]

        layers.append(layer(idx + 1, f'dot {idx + 1}', transform(
            pos=prop(None, pos), scale=prop(None, scale),
        ), [ellipse(dot_d)]))

    # The bubble shrinks into, and later grows back out of, the dots it contains
    # — so it is anchored on the dot row rather than on the canvas.
    big, small = FIT * 100, FIT * 55
    layers.append(layer(4, 'bubble', transform(
        pos=hub, anchor=hub,
        scale=prop(None, [
            (HOLD, [big, big, 100]), (LOOP_IN, [small, small, 100]),
            (LOOP_OUT, [small, small, 100]),
            (ASSEMBLE, [small, small, 100]),
            (ASSEMBLE + 15, [FIT * 105, FIT * 105, 100]),
            (ASSEMBLE + 23, [big, big, 100]),
        ]),
        opacity=prop(None, [
            (HOLD, [100]), (LOOP_IN - 4, [0]), (LOOP_OUT, [0]),
            (ASSEMBLE, [0]), (ASSEMBLE + 10, [100]),
        ]),
    ), ref='bubble', ty=2))

    # The handset swings out to the lower left and back, a beat behind.
    hs = ASSEMBLE + 5
    layers.append(layer(5, 'handset', transform(
        pos=prop(None, [
            (HOLD, [c, c, 0]), (LOOP_IN, list(away) + [0]),
            (LOOP_OUT, list(away) + [0]), (hs, list(away) + [0]),
            (hs + 18, [c, c, 0]),
        ]),
        anchor=(c, c),
        scale=prop(None, [
            (HOLD, [big, big, 100]), (LOOP_IN, [FIT * 82, FIT * 82, 100]),
            (LOOP_OUT, [FIT * 82, FIT * 82, 100]),
            (hs, [FIT * 82, FIT * 82, 100]), (hs + 18, [big, big, 100]),
        ]),
        opacity=prop(None, [
            (HOLD - 4, [100]), (LOOP_IN - 8, [0]), (LOOP_OUT, [0]),
            (hs, [0]), (hs + 12, [100]),
        ]),
    ), ref='handset', ty=2))

    layers.append(layer(6, 'head', transform(
        pos=(c, c),
        scale=prop(None, [
            (0, [big, big, 100]), (ASSEMBLE + 10, [big, big, 100]),
            (ASSEMBLE + 18, [FIT * POP, FIT * POP, 100]),
            (END, [big, big, 100]),
        ]),
    ), [ellipse(SIZE * 0.995, colour=[c / 255 for c in BRAND])]))

    doc = {
        'v': '5.7.4', 'fr': FPS, 'ip': 0, 'op': END,
        'w': SIZE, 'h': SIZE, 'nm': 'talkmos dots', 'ddd': 0,
        'markers': [
            {'tm': 0, 'cm': 'intro', 'dr': LOOP_IN},
            {'tm': LOOP_IN, 'cm': 'loop', 'dr': CYCLE},
            {'tm': LOOP_OUT, 'cm': 'outro', 'dr': END - LOOP_OUT},
        ],
        'assets': [
            {'id': 'handset', 'w': SIZE, 'h': SIZE, 'u': '', 'e': 1,
             'p': _embed(_part_png(handset, WORK))},
            {'id': 'bubble', 'w': SIZE, 'h': SIZE, 'u': '', 'e': 1,
             'p': _embed(_part_png(bubble, WORK))},
        ],
        'layers': layers,
    }

    os.makedirs(os.path.dirname(OUT_DOTS), exist_ok=True)
    with open(OUT_DOTS, 'w') as f:
        json.dump(doc, f, separators=(',', ':'))
    print(f'dots: d={dot_d:.1f} at {[(round(x), round(y)) for x, y in centres]}')
    print(f'      intro 0-{LOOP_IN}, loop {LOOP_IN}-{LOOP_OUT}, outro {LOOP_OUT}-{END}'
          f'  ({os.path.getsize(OUT_DOTS)//1024}KB)')


if __name__ == '__main__':
    build_dots()
