"""
Bake per-pack corner ornaments. One PNG per pack, ~280x280 RGBA,
placed in `book/assets/ornaments/`. The page templates stamp these
in the top-left + bottom-right corners of pack-character pages so
every Foods page (T5/T6/T8/T9) has a sprinkle ornament cluster,
every Goo page has concentric bubbles, every Creatures page has a
crescent moon + star.

Per the UI design audit's premium-tier lever:
  "Custom corner ornaments per pack — the single change that does
   more for 'real publication' feel than anything else."

Usage: python book/build/bake_ornaments.py
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import PALETTE, REPO_ROOT  # noqa: E402

ORNAMENT_DIR = REPO_ROOT / "book" / "assets" / "ornaments"
TILE = 280


def _hex_to_rgba(h: str, a: int = 255) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def bake_foods_corner() -> Image.Image:
    """Sprinkle cluster in lime/cream/pink — three sprinkle dots in
    a curling formation with a single open whisk-loop arc behind
    them. Reads as 'kitchen / dessert' at-a-glance."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Whisk-loop arc — a single elegant curve in lime
    d.arc((40, 40, 240, 240),
          start=200, end=350,
          fill=_hex_to_rgba(PALETTE["lime"], 220),
          width=8)
    # Three sprinkle dots in cream/pink/lime
    sprinkles = [
        (90,  140, _hex_to_rgba(PALETTE["pink"], 255), 14),
        (140, 100, _hex_to_rgba(PALETTE["cream"], 255), 16),
        (190, 150, _hex_to_rgba(PALETTE["lime"], 255), 12),
    ]
    for sx, sy, color, r in sprinkles:
        d.ellipse((sx - r, sy - r, sx + r, sy + r), fill=color)
    # Tiny third-tier sparkles for texture
    for (sx, sy, r) in [(60, 200, 5), (220, 90, 6), (160, 200, 4)]:
        d.ellipse((sx - r, sy - r, sx + r, sy + r),
                  fill=_hex_to_rgba(PALETTE["rose_dust"], 200))
    return img


def bake_goo_corner() -> Image.Image:
    """Three concentric bubble outlines + a single pop sparkle in
    jelly-blue. Reads as 'wet / glossy / fluid' at-a-glance."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    blue = _hex_to_rgba(PALETTE["jelly_blue"], 230)
    # Three nested bubbles, varying size
    cx, cy = 130, 140
    for r in (90, 60, 32):
        d.ellipse((cx - r, cy - r, cx + r, cy + r),
                  outline=blue, width=6)
    # Tiny inner highlight (the "wet" cue)
    d.ellipse((cx + 8, cy - 8, cx + 18, cy + 2),
              fill=_hex_to_rgba(PALETTE["soft_white"], 220))
    # A single offset bubble bottom-right for asymmetry
    d.ellipse((200, 200, 240, 240),
              outline=_hex_to_rgba(PALETTE["jelly_blue"], 180),
              width=4)
    return img


def bake_creatures_corner() -> Image.Image:
    """Waning crescent moon + 4 tiny stars in lavender + cream.
    Reads as 'night / dreamy / spooky-cute' at-a-glance."""
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    lav = _hex_to_rgba(PALETTE["lavender"], 240)
    # Crescent: full circle + offset cutout circle
    full = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    ImageDraw.Draw(full).ellipse((40, 40, 200, 200), fill=lav)
    cutout = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    ImageDraw.Draw(cutout).ellipse((70, 30, 230, 190),
                                    fill=(0, 0, 0, 255))
    # Mask the cutout out of the full circle
    crescent_mask = Image.new("L", (TILE, TILE), 0)
    cm = ImageDraw.Draw(crescent_mask)
    cm.ellipse((40, 40, 200, 200), fill=255)
    cm.ellipse((70, 30, 230, 190), fill=0)
    crescent = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    crescent.paste(full, (0, 0), crescent_mask)
    img.alpha_composite(crescent)
    # Stars scattered around the crescent
    cream = _hex_to_rgba(PALETTE["cream"], 230)
    star_positions = [
        (220, 80, 8), (240, 130, 6),
        (50, 220, 10), (180, 230, 7),
    ]
    for sx, sy, size in star_positions:
        # 4-point star polygon
        d.polygon([
            (sx, sy - size),
            (sx + size // 3, sy),
            (sx, sy + size),
            (sx - size // 3, sy),
        ], fill=cream)
        d.polygon([
            (sx - size, sy),
            (sx, sy + size // 3),
            (sx + size, sy),
            (sx, sy - size // 3),
        ], fill=cream)
    return img


def bake_all() -> list[Path]:
    ORNAMENT_DIR.mkdir(parents=True, exist_ok=True)
    bakers = [
        ("foods_corner.png",      bake_foods_corner),
        ("goo_corner.png",        bake_goo_corner),
        ("creatures_corner.png",  bake_creatures_corner),
    ]
    written: list[Path] = []
    for filename, fn in bakers:
        path = ORNAMENT_DIR / filename
        img = fn()
        img.save(path, "PNG", optimize=True)
        kb = path.stat().st_size / 1024
        print(f"  wrote {path.relative_to(REPO_ROOT)} ({kb:.1f} KB)")
        written.append(path)
    return written


if __name__ == "__main__":
    print(f"Writing to: {ORNAMENT_DIR}")
    bake_all()
