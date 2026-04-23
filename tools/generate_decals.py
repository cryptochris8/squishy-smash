"""
Procedurally generate decal PNGs for assets/images/decals/.

Replaces the placeholder folder with real splat art. Each preset becomes
a 256x256 RGBA PNG containing a main blob + satellite droplets with
soft alpha edges. "smear" presets get an elongated drag shape oriented
randomly; "splat" / "burst" presets get a radial scatter.

Run from project root:
    python tools/generate_decals.py

Requires Pillow: `pip install pillow`. Already installed in this env.

Output is deterministic per-preset (seeded RNG keyed by preset name)
so re-running produces byte-identical files unless the script changes.
That keeps git diffs small when iterating.
"""

import os
import random
from PIL import Image, ImageDraw, ImageFilter

# (preset_name, base_rgb_color, shape_kind)
# Color values lifted from lib/game/components/decal_manager.dart so the
# PNG decals match the procedural-circle fallback color exactly. The
# "burst" presets are not currently referenced in any pack JSON — they're
# generated for future packs and so the asset folder is complete.
PRESETS = [
    ("cool_blue_smear",       (127, 231, 255), "smear"),
    ("cream_smudge",          (255, 230, 189), "smear"),
    ("green_goo_smear",       (182, 255,  92), "smear"),
    ("purple_monster_splat",  (176, 132, 242), "splat"),
    ("gold_mythic_splat",     (255, 209,  92), "splat"),
    ("soft_peach_splat",      (255, 143, 184), "splat"),
    # Defined-but-unused presets (no current pack reference). Colors are
    # interpolations from the in-use palette, not authoritative — adjust
    # if/when a pack JSON adopts them.
    ("pink_soup_burst",       (255, 168, 196), "splat"),
    ("blue_jelly_burst",      ( 88, 196, 255), "splat"),
    ("cream_puff_burst",      (255, 240, 210), "splat"),
    ("green_goo_burst",       (160, 230,  80), "splat"),
    ("purple_monster_burst",  (160, 110, 230), "splat"),
]

CANVAS = 256
CENTER = CANVAS // 2


def _draw_blob(draw, cx, cy, r, color, alpha):
    """Filled circle with given alpha, RGB tinted with the preset color."""
    rgba = (*color, alpha)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba)


def _smear(img, color, rng):
    """Elongated drag shape: a chain of overlapping blobs along a random axis."""
    draw = ImageDraw.Draw(img)
    angle = rng.uniform(0, 6.283)  # 2*pi
    span = rng.randint(60, 110)
    # Chain of 6-9 blobs from one end to the other, shrinking at the tail.
    n = rng.randint(6, 9)
    for i in range(n):
        t = i / (n - 1)
        # Offset along the angle, centered.
        dx = int((t - 0.5) * 2 * span * (1 if rng.random() > 0.5 else -1) * 0.6 * __cos(angle))
        dy = int((t - 0.5) * 2 * span * (1 if rng.random() > 0.5 else -1) * 0.6 * __sin(angle))
        # Cleaner: deterministic placement along the axis instead of jitter.
        dx = int((t - 0.5) * span * 1.6 * __cos(angle))
        dy = int((t - 0.5) * span * 1.6 * __sin(angle))
        radius = int(38 * (1.0 - 0.4 * abs(t - 0.5)))  # bigger in the middle
        alpha = int(220 - 60 * abs(t - 0.5))
        _draw_blob(draw, CENTER + dx, CENTER + dy, radius, color, alpha)
    # A few satellite droplets perpendicular to the smear axis.
    for _ in range(rng.randint(3, 6)):
        dx = int(rng.uniform(-span, span) * __cos(angle) +
                 rng.uniform(-25, 25) * __cos(angle + 1.57))
        dy = int(rng.uniform(-span, span) * __sin(angle) +
                 rng.uniform(-25, 25) * __sin(angle + 1.57))
        r = rng.randint(6, 14)
        a = rng.randint(140, 200)
        _draw_blob(draw, CENTER + dx, CENTER + dy, r, color, a)


def _splat(img, color, rng):
    """Radial scatter: large central blob + ring of satellite droplets."""
    draw = ImageDraw.Draw(img)
    # Main blob, slightly off-center for organic feel.
    main_dx = rng.randint(-8, 8)
    main_dy = rng.randint(-8, 8)
    _draw_blob(draw, CENTER + main_dx, CENTER + main_dy, rng.randint(58, 72),
               color, 230)
    # Inner ring of medium droplets.
    for _ in range(rng.randint(4, 7)):
        a = rng.uniform(0, 6.283)
        dist = rng.randint(55, 85)
        dx = int(dist * __cos(a))
        dy = int(dist * __sin(a))
        r = rng.randint(14, 24)
        _draw_blob(draw, CENTER + dx, CENTER + dy, r, color, 210)
    # Outer ring of small flecks.
    for _ in range(rng.randint(6, 11)):
        a = rng.uniform(0, 6.283)
        dist = rng.randint(85, 118)
        dx = int(dist * __cos(a))
        dy = int(dist * __sin(a))
        r = rng.randint(4, 10)
        alpha = rng.randint(150, 200)
        _draw_blob(draw, CENTER + dx, CENTER + dy, r, color, alpha)


def __cos(a):
    import math
    return math.cos(a)


def __sin(a):
    import math
    return math.sin(a)


def generate(preset_name, color, kind):
    """Create one decal PNG. Output path returned."""
    rng = random.Random(hash(preset_name) & 0xFFFFFFFF)
    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    if kind == "smear":
        _smear(img, color, rng)
    else:
        _splat(img, color, rng)
    # Soft alpha edge so decals blend into the scene — ~3px Gaussian blur
    # smoothes rasterized circle aliasing without losing the silhouette.
    img = img.filter(ImageFilter.GaussianBlur(radius=2.5))
    out_path = os.path.join("assets", "images", "decals", f"{preset_name}.png")
    img.save(out_path, "PNG", optimize=True)
    return out_path


def main():
    decals_dir = os.path.join("assets", "images", "decals")
    if not os.path.isdir(decals_dir):
        raise SystemExit(f"ERROR: {decals_dir} not found. Run from project root.")
    print(f"Generating {len(PRESETS)} decal PNGs in {decals_dir}/...")
    for name, color, kind in PRESETS:
        path = generate(name, color, kind)
        size_kb = os.path.getsize(path) // 1024
        print(f"  {name} ({kind}): {size_kb} KB")
    print("Done.")


if __name__ == "__main__":
    main()
