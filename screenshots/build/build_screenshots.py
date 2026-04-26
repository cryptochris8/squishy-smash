"""
Build captioned App Store screenshots from `screenshots/raw/`.

Apple's iPhone 6.7" Display spec is 1290 x 2796 portrait. Output PNGs
preserve those EXACT pixel dimensions — Apple rejects screenshots that
don't match the device-class spec.

Design (per UI-design subagent spec, redesigned 2026-04-25):

- Single dark-plum band (#1A0F22) at 240 px tall — covers iOS status
  bar plus 120 px of breathing room. Solid fill, no gradient. Behaves
  as editorial chrome across all 10 screenshots regardless of their
  background palette (so the pink no longer fights the neon shot).
- Brand bunny mark (64 x 64) at top-left of band + 12 px pink accent
  dot. The pink moves out of the band fill and into a small mark, so
  it stays in the brand system without dominating any single image.
- Caption auto-fits via binary search inside a 1010 x 160 px box,
  font range 64-110 px. Tracking -8 at >= 90 px, -4 below. Single
  line only. Cream type (#FFD36E) with a 4 px drop shadow in dark
  plum at 55% alpha for crisp separation.
- Bottom-of-band 2 px hairline rule in cream at 40% alpha replaces
  the previous heavy dark-plum bar.

Usage:
    python screenshots/build/build_screenshots.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "screenshots" / "raw"
OUT_DIR = ROOT / "screenshots" / "captioned"
FONT_PATH = ROOT / "website" / "public" / "fonts" / "Fredoka.ttf"
BRAND_ICON = ROOT / "branding" / "icon" / "squishy_smash_icon_bunny_v1.png"

# ---------------------------------------------------------------------------
# Tokens (locked by UI design spec)
# ---------------------------------------------------------------------------

BAND_HEIGHT_PX = 240               # absolute, locked to status-bar geometry
BAND_FILL = (26, 15, 34)           # #1A0F22 — one shade lighter than #120B17
CREAM = (255, 211, 110)            # #FFD36E — caption text
BRAND_PINK = (255, 143, 184)       # #FF8FB8 — bunny mark + accent dot
SHADOW_RGBA = (18, 11, 23, 140)    # #120B178C — caption drop shadow
RULE_RGBA = (255, 211, 110, 102)   # #FFD36E66 — bottom hairline rule

CAPTION_FONT_MIN = 64
CAPTION_FONT_MAX = 110
CAPTION_BOX = (1010, 160)          # text box inside band
CAPTION_ORIGIN = (140, 40)         # top-left of text box (band-relative)

BUNNY_SIZE = 64
BUNNY_MARGIN_LEFT = 32
DOT_SIZE = 12
DOT_GAP = 24                       # gap between bunny right edge and dot left edge
SHADOW_OFFSET = (0, 4)
RULE_HEIGHT = 2

# ---------------------------------------------------------------------------
# Captions (slot order, by NN prefix)
# ---------------------------------------------------------------------------

CAPTIONS: dict[str, str] = {
    "01": "Tap. Squish. Collect.",
    "02": "Smash to reveal.",
    "03": "Every burst, a new world.",
    "04": "Three packs to discover.",
    "05": "Chain combos for big rewards.",
    "06": "Soft. Sweet. Satisfying.",
    "07": "A soft, sparkly world.",
    "08": "48 squishies to collect.",
    "09": "Save coins. Unlock legends.",
    "10": "No ads. No sign-up. Just play.",
}


def find_caption(filename: str) -> str | None:
    return CAPTIONS.get(filename.split("_", 1)[0])


# ---------------------------------------------------------------------------
# Typography helpers
# ---------------------------------------------------------------------------

def _tracking_for_size(size: int) -> int:
    """Per spec: -8 px tracking at >= 90 px, -4 px below."""
    return -8 if size >= 90 else -4


def measure_with_tracking(text: str, font: ImageFont.FreeTypeFont,
                          tracking: int) -> float:
    """Sum of advance widths plus per-pair tracking (n-1 gaps)."""
    if not text:
        return 0.0
    return font.getlength(text) + tracking * (len(text) - 1)


def fit_caption_font(text: str) -> tuple[ImageFont.FreeTypeFont, int]:
    """Binary-search the largest font size at which `text` fits in the
    caption box. Converges in ~6 iterations."""
    box_w, box_h = CAPTION_BOX
    lo, hi = CAPTION_FONT_MIN, CAPTION_FONT_MAX
    best_size = lo
    best_font = ImageFont.truetype(str(FONT_PATH), lo)
    while lo <= hi:
        mid = (lo + hi) // 2
        font = ImageFont.truetype(str(FONT_PATH), mid)
        tracking = _tracking_for_size(mid)
        w = measure_with_tracking(text, font, tracking)
        ascent, descent = font.getmetrics()
        h = ascent + descent
        if w <= box_w and h <= box_h:
            best_size = mid
            best_font = font
            lo = mid + 1
        else:
            hi = mid - 1
    return best_font, best_size


def draw_text_with_tracking(draw: ImageDraw.ImageDraw,
                            xy: tuple[float, float],
                            text: str,
                            font: ImageFont.FreeTypeFont,
                            fill,
                            tracking: int) -> None:
    """Draw `text` glyph-by-glyph with manual letter-spacing. PIL has no
    native tracking parameter, so we walk the string and offset each
    glyph by its advance width plus the tracking value."""
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=font, fill=fill)
        x += font.getlength(ch) + tracking


# ---------------------------------------------------------------------------
# Brand mark + accent dot
# ---------------------------------------------------------------------------

def _bunny_mark_image() -> Image.Image:
    """Load the brand bunny icon, recolor as a pink silhouette, and
    return a 64 x 64 RGBA image. Falls back to a placeholder (pink
    filled circle with two ear rectangles) if the icon is missing."""
    if BRAND_ICON.exists():
        icon = Image.open(BRAND_ICON).convert("RGBA")
        icon = icon.resize((BUNNY_SIZE, BUNNY_SIZE), Image.Resampling.LANCZOS)
        # Recolor: keep alpha, replace RGB with brand pink so the mark
        # reads as a single brand atom regardless of the original icon's
        # internal color treatment.
        silhouette = Image.new("RGBA", icon.size, BRAND_PINK + (0,))
        silhouette.putalpha(icon.getchannel("A"))
        return silhouette

    # Placeholder: filled circle + 2 rounded-rect ears
    img = Image.new("RGBA", (BUNNY_SIZE, BUNNY_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (circle)
    d.ellipse([(8, 16), (56, 64)], fill=BRAND_PINK + (255,))
    # Left ear
    d.rounded_rectangle([(14, 0), (28, 28)], radius=7,
                        fill=BRAND_PINK + (255,))
    # Right ear
    d.rounded_rectangle([(36, 0), (50, 28)], radius=7,
                        fill=BRAND_PINK + (255,))
    return img


def _draw_brand_mark(canvas: Image.Image) -> None:
    bunny = _bunny_mark_image()
    y = (BAND_HEIGHT_PX - BUNNY_SIZE) // 2  # vertically center in band
    canvas.alpha_composite(bunny, (BUNNY_MARGIN_LEFT, y))


def _draw_accent_dot(draw: ImageDraw.ImageDraw, baseline_y: float) -> None:
    """12 px pink dot, vertically aligned with the caption x-height,
    placed in the gap between bunny + caption."""
    x = BUNNY_MARGIN_LEFT + BUNNY_SIZE + DOT_GAP
    y = baseline_y - DOT_SIZE  # slight visual lift above baseline
    draw.ellipse([(x, y), (x + DOT_SIZE, y + DOT_SIZE)],
                 fill=BRAND_PINK + (255,))


# ---------------------------------------------------------------------------
# Compositor
# ---------------------------------------------------------------------------

def caption_screenshot(raw_path: Path, out_path: Path) -> tuple[int, int]:
    """Composite a caption band over the top of the raw screenshot.
    Output PNG has the SAME dimensions as the input — Apple's spec.
    Returns the (width, height) for verification."""
    base = Image.open(raw_path).convert("RGB")
    w, h = base.size

    # Work in RGBA so the drop shadow + hairline rule alpha-composite
    # cleanly. Convert back to RGB before saving so the output format
    # matches the source.
    canvas = base.convert("RGBA")

    # 1) Solid band fill
    band = Image.new("RGBA", (w, BAND_HEIGHT_PX), BAND_FILL + (255,))
    canvas.alpha_composite(band, (0, 0))

    # 2) Brand bunny mark + accent dot
    _draw_brand_mark(canvas)

    # 3) Caption — binary-search the font size, then draw shadow + fill
    caption = find_caption(raw_path.name)
    if caption:
        font, size = fit_caption_font(caption)
        tracking = _tracking_for_size(size)

        # Vertical center of caption inside the text box
        ascent, descent = font.getmetrics()
        text_h = ascent + descent
        text_x = CAPTION_ORIGIN[0]
        text_y = CAPTION_ORIGIN[1] + (CAPTION_BOX[1] - text_h) // 2

        # Shadow on its own RGBA layer so the alpha is preserved
        shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow_layer)
        draw_text_with_tracking(
            shadow_draw,
            (text_x + SHADOW_OFFSET[0], text_y + SHADOW_OFFSET[1]),
            caption, font, SHADOW_RGBA, tracking,
        )
        canvas.alpha_composite(shadow_layer)

        # Cream caption on top
        caption_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        caption_draw = ImageDraw.Draw(caption_layer)
        draw_text_with_tracking(
            caption_draw, (text_x, text_y), caption, font,
            CREAM + (255,), tracking,
        )
        canvas.alpha_composite(caption_layer)

        # Accent dot — sit it just above the caption baseline
        dot_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        dot_draw = ImageDraw.Draw(dot_layer)
        _draw_accent_dot(dot_draw, baseline_y=text_y + ascent * 0.55)
        canvas.alpha_composite(dot_layer)

    # 4) Hairline rule along the bottom of the band
    rule_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(rule_layer).rectangle(
        [(0, BAND_HEIGHT_PX - RULE_HEIGHT), (w, BAND_HEIGHT_PX)],
        fill=RULE_RGBA,
    )
    canvas.alpha_composite(rule_layer)

    # 5) Save as RGB PNG (same format as the raw input)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)
    return canvas.size


def build_all() -> list[Path]:
    if not RAW_DIR.exists():
        raise FileNotFoundError(f"Missing raw screenshots dir: {RAW_DIR}")
    if not FONT_PATH.exists():
        raise FileNotFoundError(f"Missing Fredoka font: {FONT_PATH}")

    outputs: list[Path] = []
    for raw in sorted(RAW_DIR.glob("*.[Pp][Nn][Gg]")):
        out = OUT_DIR / raw.name
        size = caption_screenshot(raw, out)
        outputs.append(out)
        print(f"  {raw.name}  ->  {out.relative_to(ROOT)}  ({size[0]}x{size[1]})")
    return outputs


if __name__ == "__main__":
    print(f"Reading from:  {RAW_DIR.relative_to(ROOT)}")
    print(f"Writing to:    {OUT_DIR.relative_to(ROOT)}")
    print()
    outs = build_all()
    print()
    print(f"Done. {len(outs)} captioned screenshots written.")
    sys.exit(0)
