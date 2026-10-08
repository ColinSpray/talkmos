#!/usr/bin/env python3
"""Relocates the adaptive icon's layers from drawable-* to mipmap-*.

flutter_launcher_icons hardcodes drawable-* for the foreground, background and
monochrome layers, and emits @drawable/ references in mipmap-anydpi-v26. There is
no setting for it (see adaptiveForegroundIcons in the package's android.dart), so
this runs afterwards and moves them.

Why it matters: mipmap exists precisely so launcher icons survive density-based
APK splitting. Everything in drawable-* is stripped down to the device's own
bucket, but a launcher may ask for an icon a bucket or two above that — which is
why the legacy icon has always lived in mipmap. The adaptive layers are launcher
icon artwork too, so they belong in the same place; left in drawable they can be
stripped out from under the icon that references them.

Idempotent: safe to run whether or not the layers have already been moved.

Usage:  python3 tool/icons_to_mipmap.py
"""

import os
import re
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'android/app/src/main/res')
ADAPTIVE_XML = os.path.join(RES, 'mipmap-anydpi-v26/ic_launcher.xml')

LAYERS = ('ic_launcher_background', 'ic_launcher_foreground')

# The monochrome layer is the same silhouette as the foreground, so it is pointed
# at the foreground drawable and its own copies are dropped. flutter_launcher_icons
# writes it as a separate file per density regardless of the two being the same
# image, which put five byte-identical PNGs in the APK.
DUPLICATE = 'ic_launcher_monochrome'

DENSITIES = ('mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi')


def main():
    moved = dropped = 0
    for density in DENSITIES:
        src_dir = os.path.join(RES, f'drawable-{density}')
        dst_dir = os.path.join(RES, f'mipmap-{density}')
        for layer in LAYERS:
            src = os.path.join(src_dir, f'{layer}.png')
            if not os.path.exists(src):
                continue
            os.makedirs(dst_dir, exist_ok=True)
            shutil.move(src, os.path.join(dst_dir, f'{layer}.png'))
            moved += 1
        for d in (src_dir, dst_dir):
            dupe = os.path.join(d, f'{DUPLICATE}.png')
            if os.path.exists(dupe):
                os.remove(dupe)
                dropped += 1
        # Only if this run emptied it — splash_icon and launch_logo also live here.
        if os.path.isdir(src_dir) and not os.listdir(src_dir):
            os.rmdir(src_dir)

    if not os.path.exists(ADAPTIVE_XML):
        raise SystemExit(f'missing {ADAPTIVE_XML}; run flutter_launcher_icons first')

    xml = open(ADAPTIVE_XML).read()
    rewritten = re.sub(
        r'@(?:drawable|mipmap)/ic_launcher_monochrome',
        '@mipmap/ic_launcher_foreground',
        xml,
    )
    rewritten = re.sub(
        r'@drawable/(ic_launcher_(?:background|foreground))',
        r'@mipmap/\1',
        rewritten,
    )
    if rewritten != xml:
        open(ADAPTIVE_XML, 'w').write(rewritten)

    print(f'moved {moved} layer file(s) to mipmap-*, dropped {dropped} duplicate(s)')
    for line in rewritten.splitlines():
        if 'drawable=' in line:
            print('  ' + line.strip())


if __name__ == '__main__':
    main()
