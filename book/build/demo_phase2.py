"""
Phase-2 visual demo. Renders a 4-up rarity tier showcase + a 3-up
pack background showcase so you can eyeball the new visual system
before Phase 3 wires it into actual page templates.

Output: book/build/out/phase2_demo.png — single PNG image, easy to
open and review.

Usage: python book/build/demo_phase2.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))

from card_frame import draw_card_frame, paint_pack_background  # noqa: E402
from config import (  # noqa: E402
    FONT_PATH,
    OUT_DIR,
    PALETTE,
    by_num,
)


# Pick one card per rarity tier from Squishy Foods so the demo
# stays visually coherent.
SHOWCASE_NUMS = {
    "common": 1,    # Soft Dumpling
    "rare":   11,   # Sparkle Mochi
    "epic":   13,   # Galaxy Dumpling
    "mythic": 16,   # Celestial Dumpling Core
}

# One card per pack for the gradient backgrounds row.
PACK_HEROES = [
    ("Squishy Foods",          1),    # Soft Dumpling
    ("Goo & Fidgets",          17),   # Goo Ball
    ("Creepy-Cute Creatures",  33),   # Blushy Bun Bunny
]


def _hex(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def _label(canvas: Image.Image, text: str, x: int, y: int,
           size: int = 22) -> None:
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype(str(FONT_PATH), size)
    except OSError:
        font = ImageFont.load_default()
    draw.text((x, y), text, fill=_hex(PALETTE["soft_white"]) + (255,),
              font=font)


def render_demo() -> Path:
    chars = by_num()
    # Page is 1800 px wide x 2200 px tall. Top half = rarity row,
    # bottom half = pack-bg row.
    canvas = Image.new("RGBA", (1800, 2200), _hex(PALETTE["bg"]) + (255,))

    # ---- Top: Rarity tier showcase --------------------------------
    _label(canvas, "RARITY TIERS — common -> mythic", 60, 36, size=28)
    card_w, card_h = 380, 520
    gap = 40
    start_x = 60
    row_y = 100
    for i, (rarity, num) in enumerate(SHOWCASE_NUMS.items()):
        x = start_x + i * (card_w + gap)
        char = chars[num]
        draw_card_frame(
            canvas, char.card_path,
            x, row_y, card_w, card_h,
            rarity=rarity, pack=char.pack,
        )
        # Caption under each card
        _label(canvas, f"{char.name}", x + 8, row_y + card_h + 18,
               size=20)
        _label(canvas, f"{rarity}", x + 8, row_y + card_h + 50,
               size=16)

    # ---- Bottom: Per-pack background showcase ---------------------
    _label(canvas, "PER-PACK BACKGROUNDS — gradient + texture",
           60, 1180, size=28)
    bg_w, bg_h = 560, 720
    gap = 40
    start_x = 60
    row_y = 1240
    for i, (pack, num) in enumerate(PACK_HEROES):
        x = start_x + i * (bg_w + gap)
        # Paint the per-pack gradient + texture across the full panel
        paint_pack_background(canvas, x, row_y, bg_w, bg_h,
                              pack=pack, with_texture=True)
        # Stamp the pack hero card centered on the bg panel for
        # visual reference.
        char = chars[num]
        card_w_inner, card_h_inner = 360, 500
        cx = x + (bg_w - card_w_inner) // 2
        cy = row_y + (bg_h - card_h_inner) // 2 - 30
        draw_card_frame(
            canvas, char.card_path,
            cx, cy, card_w_inner, card_h_inner,
            rarity=char.rarity, pack=pack,
        )
        # Pack label under the panel
        _label(canvas, pack, x + 12, row_y + bg_h + 20, size=20)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUT_DIR / "phase2_demo.png"
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)
    return out_path


if __name__ == "__main__":
    out = render_demo()
    size_kb = out.stat().st_size / 1024
    print(f"Wrote {out} ({size_kb:.1f} KB)")
