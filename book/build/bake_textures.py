"""
Bake the three per-pack texture PNGs once and ship them in the repo.

Each texture is a tile that the page-template renderer (Phase 3
T5/T6 spreads) overlays at low alpha on top of the per-pack
background gradient. The textures themselves are deliberately
subtle — they should read as "this page has texture" not
"someone scattered glitter on it."

Squishy Foods   -> sprinkle dots in pink/cream/lime (warm dessert vibes)
Goo & Fidgets   -> nested bubble outlines in jelly-blue (glossy)
Creepy-Cute     -> moondust specks + tiny stars in lavender (haunted)

Tile size is 1024x1024 — large enough to seamlessly tile across an
8.75 in page at 300 DPI without visible repetition seams. Alpha
channel is preserved so the renderer can multiply at low opacity
(typical 6%) without clobbering the gradient underneath.

Usage:
    python book/build/bake_textures.py
    -> writes book/assets/textures/{sprinkles,bubbles,moondust}_*.png
"""

from __future__ import annotations

import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import PALETTE, TEXTURE_DIR  # noqa: E402

TILE = 1024


def _hex_to_rgba(hex_str: str, alpha: int) -> tuple[int, int, int, int]:
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def bake_sprinkles_foods() -> Image.Image:
    """Pink + cream + lime sprinkle dots scattered across the tile.
    Two size buckets (3 px and 6 px) to break visual rhythm. RGBA so
    the gradient bleeds through where there are no sprinkles."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(seed=42)
    colors = [
        _hex_to_rgba(PALETTE["pink"], 180),
        _hex_to_rgba(PALETTE["cream"], 200),
        _hex_to_rgba(PALETTE["lime"], 160),
        _hex_to_rgba(PALETTE["rose_dust"], 170),
    ]
    # ~250 small + ~80 medium dots per tile = subtle but present
    for _ in range(250):
        x = rng.randrange(0, TILE)
        y = rng.randrange(0, TILE)
        r = rng.randint(2, 4)
        draw.ellipse((x - r, y - r, x + r, y + r),
                     fill=rng.choice(colors))
    for _ in range(80):
        x = rng.randrange(0, TILE)
        y = rng.randrange(0, TILE)
        r = rng.randint(5, 7)
        draw.ellipse((x - r, y - r, x + r, y + r),
                     fill=rng.choice(colors))
    return img


def bake_bubbles_goo() -> Image.Image:
    """Concentric bubble outlines in jelly-blue. Thin strokes, varied
    radii, scattered with no repeating grid. RGBA."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(seed=137)
    blue = _hex_to_rgba(PALETTE["jelly_blue"], 130)
    blue_dim = _hex_to_rgba(PALETTE["jelly_blue"], 80)
    # 60 bubble clusters of 1-3 nested rings each
    for _ in range(60):
        cx = rng.randrange(0, TILE)
        cy = rng.randrange(0, TILE)
        rings = rng.randint(1, 3)
        base = rng.randint(8, 28)
        for i in range(rings):
            r = base + i * 6
            color = blue if i == 0 else blue_dim
            draw.ellipse((cx - r, cy - r, cx + r, cy + r),
                         outline=color, width=2)
    return img


def bake_moondust_creatures() -> Image.Image:
    """Lavender moondust + tiny 4-point stars. RGBA."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(seed=909)
    lavender = _hex_to_rgba(PALETTE["lavender"], 140)
    soft_white = _hex_to_rgba(PALETTE["soft_white"], 180)
    cream = _hex_to_rgba(PALETTE["cream"], 200)
    # 400 moondust specks
    for _ in range(400):
        x = rng.randrange(0, TILE)
        y = rng.randrange(0, TILE)
        r = rng.randint(1, 2)
        draw.ellipse((x - r, y - r, x + r, y + r),
                     fill=rng.choice([lavender, soft_white]))
    # 25 tiny 4-point stars
    for _ in range(25):
        cx = rng.randrange(0, TILE)
        cy = rng.randrange(0, TILE)
        size = rng.randint(4, 8)
        # 4-point star = two thin diamonds rotated 45 degrees
        draw.polygon([
            (cx, cy - size),
            (cx + size // 3, cy),
            (cx, cy + size),
            (cx - size // 3, cy),
        ], fill=cream)
        draw.polygon([
            (cx - size, cy),
            (cx, cy + size // 3),
            (cx + size, cy),
            (cx, cy - size // 3),
        ], fill=cream)
    return img


def bake_all() -> list[Path]:
    TEXTURE_DIR.mkdir(parents=True, exist_ok=True)
    bakers = [
        ("sprinkles_foods.png",      bake_sprinkles_foods),
        ("bubbles_goo.png",          bake_bubbles_goo),
        ("moondust_creatures.png",   bake_moondust_creatures),
    ]
    written: list[Path] = []
    for filename, fn in bakers:
        path = TEXTURE_DIR / filename
        img = fn()
        img.save(path, "PNG", optimize=True)
        size_kb = path.stat().st_size / 1024
        print(f"  wrote {path.relative_to(TEXTURE_DIR.parents[2])} "
              f"({size_kb:.1f} KB)")
        written.append(path)
    return written


# `random.Random(seed=...)` is the public 3.13+ kw — older shims may
# need the positional form. Provide a one-arg fallback in case
# someone runs this against a 3.10 venv.
def _shim_random_random_seed_kw():
    try:
        random.Random(seed=1)
    except TypeError:
        original = random.Random
        random.Random = lambda seed=None: original(seed)


_shim_random_random_seed_kw()


if __name__ == "__main__":
    print(f"Writing to: {TEXTURE_DIR}")
    bake_all()
