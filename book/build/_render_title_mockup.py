"""
Standalone render script — produces cover mockups without running the
full 46-page PDF build.

Outputs:
    book/mockups/title_current.png   — existing T1_title() as-is
    book/mockups/title_option_1.png  — Option 1: pure type poster
    book/mockups/title_option_2.png  — Option 2: type + single brand icon
    book/mockups/title_option_3.png  — Option 3: type + pack-colour band + subtitle

Usage (from repo root):
    cd book/build && python _render_title_mockup.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PIL import Image, ImageDraw, ImageFilter

from card_frame import _hex_to_rgba, _glow_layer
from config import BRAND_ICON, PALETTE
from page_templates import T1_title, _new_canvas, SAFE, PAGE_W, PAGE_H
from typography import draw_text

OUT = Path(__file__).resolve().parents[1] / "mockups"
OUT.mkdir(exist_ok=True)


# ─── helpers ─────────────────────────────────────────────────────────────────

def _soft_rule(canvas: Image.Image, cx: int, y: int, half_w: int,
               color_hex: str, thickness: int = 6, alpha: int = 180) -> None:
    """Horizontal rule, centred on cx, softened with a tiny blur."""
    layer = Image.new("RGBA", (PAGE_W, PAGE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    r, g, b, _ = _hex_to_rgba(color_hex)
    draw.rectangle(
        [cx - half_w, y, cx + half_w, y + thickness],
        fill=(r, g, b, alpha),
    )
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius=3)))


def _bunny_stamp(canvas: Image.Image, cx: int, cy: int, size: int,
                 alpha: int = 90) -> None:
    """Stamp the brand icon centred on (cx, cy) at reduced opacity."""
    if not BRAND_ICON.exists():
        return
    icon = Image.open(BRAND_ICON).convert("RGBA")
    icon = icon.resize((size, size), Image.Resampling.LANCZOS)
    # Scale overall alpha so the icon reads as a ghosted stamp
    r2, g2, b2, a2 = icon.split()
    a2 = a2.point(lambda v, k=alpha: int(v * k / 255))
    icon = Image.merge("RGBA", (r2, g2, b2, a2))
    canvas.alpha_composite(icon, (cx - size // 2, cy - size // 2))


def _warm_wash(canvas: Image.Image, alpha_frac: float = 0.08) -> None:
    """Very faint central pink wash — takes the hard edge off pure #120B17."""
    glow = _glow_layer(PAGE_W, PAGE_H, PALETTE["pink"], radius=800,
                       alpha=alpha_frac)
    canvas.alpha_composite(glow)


# ─── current ─────────────────────────────────────────────────────────────────

print("Rendering current…")
T1_title().save(OUT / "title_current.png")
print(f"  -> {OUT / 'title_current.png'}")


# ─── Option 1: Pure typography poster ────────────────────────────────────────
# Two words, solid brand colours, nothing else. Optically centred (slightly
# above page mid) with generous space between them. A thin rose-dust rule
# separates SQUISHY from SMASH so the stack reads as a single two-beat title
# rather than two disconnected shouts. No cards, no sparkles, no subtitle.
# Sacrifices any illustration hint — the words have to sell the book alone.

def T1_option_1() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2
    _warm_wash(canvas, 0.07)

    # Optical centre of a square page sits ~45% from top.
    # Title block = two words + gap. Estimate total block height:
    #   wordmark leading ~240 px + gap 300 px + wordmark_alt leading ~240 px
    #   = ~780 px. Centre that on 0.45 * 2625 = 1181 px.
    block_top = int(PAGE_H * 0.45) - 390   # ~791
    gap = 300

    draw_text(canvas, cx, block_top, "SQUISHY", style_name="wordmark", shadow=True)

    rule_y = block_top + 248   # just below SQUISHY cap height
    _soft_rule(canvas, cx, rule_y, half_w=380, color_hex=PALETTE["rose_dust"],
               thickness=5, alpha=150)

    draw_text(canvas, cx, block_top + gap, "SMASH", style_name="wordmark_alt", shadow=True)

    return canvas


print("Rendering Option 1 (pure type)…")
T1_option_1().save(OUT / "title_option_1.png")
print(f"  -> {OUT / 'title_option_1.png'}")


# ─── Option 2: Type + brand icon ─────────────────────────────────────────────
# Same stacked wordmark, shifted up ~15% to make room for a large faint brand
# icon watermark below. Icon at 50% opacity reads as a confident stamp rather
# than competing art. Subtitle "Meet the Squishies" anchors below the icon.
# Sacrifices: no hero card art, no pack representation.

def T1_option_2() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2
    _warm_wash(canvas, 0.09)

    block_top = int(PAGE_H * 0.16)   # higher up to make room below
    gap = 300

    draw_text(canvas, cx, block_top, "SQUISHY", style_name="wordmark", shadow=True)

    rule_y = block_top + 248
    _soft_rule(canvas, cx, rule_y, half_w=360, color_hex=PALETTE["rose_dust"],
               thickness=5, alpha=140)

    draw_text(canvas, cx, block_top + gap, "SMASH", style_name="wordmark_alt", shadow=True)

    # Brand icon — large, low alpha, centred in lower half of page
    icon_cy = int(PAGE_H * 0.70)
    _bunny_stamp(canvas, cx, icon_cy, size=680, alpha=75)

    # Subtitle overlaid on the icon (icon is transparent enough not to fight it)
    sub_y = icon_cy + 370
    draw_text(canvas, cx, sub_y, "Meet the Squishies", style_name="subtitle")

    return canvas


print("Rendering Option 2 (type + brand icon)…")
T1_option_2().save(OUT / "title_option_2.png")
print(f"  -> {OUT / 'title_option_2.png'}")


# ─── Option 2 v2: User-requested tweaks on Option 2 ──────────────────────────
# User picked Option 2 but asked for: (1) SMASH closer to SQUISHY, (2) subtitle
# moved further down from the wordmark/icon stack, (3) subtitle a little larger.
# Tweaks vs Option 2:
#   gap 300 -> 250  (SQUISHY-SMASH closer)
#   subtitle -> subtitle_xl (56pt -> 72pt; "a little larger")
#   sub_y = icon_cy + 420  (was +370; pushes subtitle 50px lower for breathing room)

def T1_option_2_v2() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2
    _warm_wash(canvas, 0.09)

    block_top = int(PAGE_H * 0.16)
    gap = 250

    draw_text(canvas, cx, block_top, "SQUISHY", style_name="wordmark", shadow=True)

    rule_y = block_top + 248
    _soft_rule(canvas, cx, rule_y, half_w=360, color_hex=PALETTE["rose_dust"],
               thickness=5, alpha=140)

    draw_text(canvas, cx, block_top + gap, "SMASH", style_name="wordmark_alt", shadow=True)

    icon_cy = int(PAGE_H * 0.70)
    _bunny_stamp(canvas, cx, icon_cy, size=680, alpha=75)

    sub_y = icon_cy + 420
    draw_text(canvas, cx, sub_y, "Meet the Squishies", style_name="subtitle_xl")

    return canvas


print("Rendering Option 2 v2 (tweaked: tighter wordmark, larger subtitle)…")
T1_option_2_v2().save(OUT / "title_option_2_v2.png")
print(f"  -> {OUT / 'title_option_2_v2.png'}")


# ─── Option 3: Type + pack-colour band + subtitle ────────────────────────────
# Wordmark centred. A narrow 3-segment horizontal band — one chip per pack
# (lime / jelly-blue / lavender) — sits between the two words as a colourful
# divider. Subtitle + tagline below give parents the book's name. The band
# signals "three packs, one world" with zero figurative art.
# Sacrifices: no character imagery. Band feels abstract to someone unfamiliar
# with the packs until they open the book.

def _pack_band(canvas: Image.Image, cx: int, y: int, half_w: int,
               band_h: int = 18) -> None:
    """Three-colour horizontal bar: Foods lime | Goo blue | Creatures lavender."""
    layer = Image.new("RGBA", (PAGE_W, PAGE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    colours = [PALETTE["lime"], PALETTE["jelly_blue"], PALETTE["lavender"]]
    chip_w = (half_w * 2) // 3
    x0 = cx - half_w
    for i, hex_col in enumerate(colours):
        r, g, b, _ = _hex_to_rgba(hex_col)
        draw.rectangle(
            [x0 + i * chip_w, y,
             x0 + (i + 1) * chip_w, y + band_h],
            fill=(r, g, b, 220),
        )
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius=2)))


def T1_option_3() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2
    _warm_wash(canvas, 0.08)

    # Words at optical centre; subtitle sits below
    block_top = int(PAGE_H * 0.30)
    gap = 300

    draw_text(canvas, cx, block_top, "SQUISHY", style_name="wordmark", shadow=True)

    # Pack-band replaces the rose-dust rule as the divider
    band_y = block_top + 250
    _pack_band(canvas, cx, band_y, half_w=380, band_h=16)

    draw_text(canvas, cx, block_top + gap, "SMASH", style_name="wordmark_alt", shadow=True)

    # Subtitle + tagline below the wordmark block
    sub_y = block_top + gap + 280
    draw_text(canvas, cx, sub_y, "Meet the Squishies", style_name="subtitle")
    draw_text(canvas, cx, sub_y + 90,
              "A Field Guide from the Squishkeeper", style_name="tagline")

    return canvas


print("Rendering Option 3 (type + pack band + subtitle)…")
T1_option_3().save(OUT / "title_option_3.png")
print(f"  -> {OUT / 'title_option_3.png'}")

print("\nDone. Files in book/mockups/")
