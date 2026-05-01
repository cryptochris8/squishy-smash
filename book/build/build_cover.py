"""
Build the cover wrap PDF for the Squishy Smash KDP character book.

Output: book/build/out/cover_wrap.pdf

Layout:
    [back cover (8.5") + spine (~0.075") + front cover (8.5")] x 8.5" tall,
    with 0.125" bleed added to top, bottom, and outside edges.

KDP wants the cover as a single PDF with the back on the left, front on
the right, and the spine in between.

Spine note:
    32 interior pages produces a ~0.075" spine. KDP recommends NO spine
    text below ~80 pages. We treat the spine as a brand-color band only.

Barcode safe zone:
    KDP overlays a 2 x 1.2 in barcode at the lower-right of the back cover
    (0.25 in from trim edges). This script reserves that zone empty.
"""

from __future__ import annotations

import sys
from pathlib import Path

from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as canvas_mod
from reportlab.platypus import Paragraph

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import (  # noqa: E402
    BARCODE_H, BARCODE_INSET, BARCODE_W, BLEED, COVER_H, COVER_W, FONT_PATH,
    INCH, OUT_DIR, PALETTE, SPINE_W_IN, TRIM_IN, all_characters,
)
from image_helpers import draw_card as _draw_fitted_card  # noqa: E402

COVER_PDF = OUT_DIR / "cover_wrap.pdf"

# Font fallback (matches build_interior.py)
DISPLAY_FONT = "Helvetica-Bold"
BODY_FONT = "Helvetica"
if FONT_PATH.exists():
    pdfmetrics.registerFont(TTFont("Fredoka", str(FONT_PATH)))
    DISPLAY_FONT = "Fredoka"
    BODY_FONT = "Fredoka"

# Wrap geometry — left/right halves split by spine.
# Back cover x-range: [BLEED, BLEED + TRIM_W]
# Spine x-range:      [BLEED + TRIM_W, BLEED + TRIM_W + SPINE_W]
# Front cover x-range:[BLEED + TRIM_W + SPINE_W, BLEED + 2 * TRIM_W + SPINE_W]
TRIM_W = TRIM_IN * INCH
SPINE_W = SPINE_W_IN * INCH

BACK_X = BLEED
SPINE_X = BLEED + TRIM_W
FRONT_X = BLEED + TRIM_W + SPINE_W

# Y range for trim (excludes top/bottom bleed)
TRIM_Y_BOT = BLEED
TRIM_Y_TOP = BLEED + TRIM_IN * INCH


def _style(font: str, size: float, leading: float, color: str,
           alignment: int = TA_LEFT) -> ParagraphStyle:
    return ParagraphStyle(
        f"cs_{font}_{size}",
        fontName=font, fontSize=size, leading=leading,
        textColor=HexColor(color), alignment=alignment,
    )


def _draw_paragraph(c: canvas_mod.Canvas, text: str, x: float, y_top: float,
                    width: float, p_style: ParagraphStyle) -> float:
    para = Paragraph(text, p_style)
    _, h = para.wrap(width, COVER_H)
    para.drawOn(c, x, y_top - h)
    return y_top - h


def _draw_card(c: canvas_mod.Canvas, image_path: Path,
               x: float, y: float, side: float) -> None:
    """Draw a card preserving its 3:4 aspect inside a (side x side) box."""
    _draw_fitted_card(c, image_path, x, y, side, side)


def draw_full_background(c: canvas_mod.Canvas) -> None:
    """Fill the entire wrap (including bleed) with the brand background."""
    c.setFillColor(HexColor(PALETTE["bg"]))
    c.rect(0, 0, COVER_W, COVER_H, fill=1, stroke=0)


def draw_spine(c: canvas_mod.Canvas) -> None:
    """Brand-color spine band, no text (32 pages too thin for spine print)."""
    c.setFillColor(HexColor(PALETTE["pink"]))
    c.rect(SPINE_X, 0, SPINE_W, COVER_H, fill=1, stroke=0)


def draw_back_cover(c: canvas_mod.Canvas) -> None:
    """Back cover: blurb, three pack callouts, footer, barcode safe zone."""
    chars = {ch.num: ch for ch in all_characters()}

    # Inner safe area (0.375 in inset from trim edges)
    safe_inset = 0.375 * INCH
    inner_x = BACK_X + safe_inset
    inner_w = TRIM_W - 2 * safe_inset

    # Headline
    headline_style = _style(DISPLAY_FONT, 18, 22, PALETTE["pink"], TA_CENTER)
    body_style = _style(BODY_FONT, 11, 15, PALETTE["soft_white"], TA_CENTER)
    pack_title_style = _style(DISPLAY_FONT, 12, 14,
                              PALETTE["cream"], TA_CENTER)
    pack_body_style = _style(BODY_FONT, 9, 12,
                             PALETTE["soft_white"], TA_CENTER)
    footer_style = _style(BODY_FONT, 9, 12,
                          PALETTE["soft_white"], TA_CENTER)

    y = TRIM_Y_TOP - safe_inset - 18
    y = _draw_paragraph(
        c, "48 squishies. 3 magical packs.<br/>One bouncy world.",
        inner_x, y, inner_w, headline_style,
    )
    y -= 14

    y = _draw_paragraph(
        c,
        "Step into the world of Squishy Smash, where the softest snacks, "
        "the glossiest goos, and the cutest little creatures are ready to "
        "bounce, wobble, and shine.",
        inner_x, y, inner_w, body_style,
    )
    y -= 8
    y = _draw_paragraph(
        c,
        "From cozy little Soft Dumpling to the legendary Mythic Plush "
        "Familiar, every page bursts with brand-new squishy friends to "
        "meet, share, and love.",
        inner_x, y, inner_w, body_style,
    )
    y -= 8
    y = _draw_paragraph(
        c, "<i>Open the book. Pick a pack. Find your favorite.</i>",
        inner_x, y, inner_w, body_style,
    )
    y -= 18

    # Three pack callouts (cards + names)
    panel_w = (inner_w - 16) / 3
    panel_h = 110
    card_side = 60
    panels = [
        ("Squishy Foods", "warm, tasty, sweet", PALETTE["lime"], 1),
        ("Goo & Fidgets", "glossy, bouncy, satisfying", PALETTE["jelly_blue"], 17),
        ("Creepy-Cute", "spooky-sweet, magical", PALETTE["lavender"], 33),
    ]
    panel_y_top = y
    for i, (name, blurb, tint, num) in enumerate(panels):
        px = inner_x + i * (panel_w + 8)
        py = panel_y_top - panel_h
        c.setFillColor(HexColor(tint))
        c.setFillAlpha(0.16)
        c.roundRect(px, py, panel_w, panel_h, 8, fill=1, stroke=0)
        c.setFillAlpha(1.0)
        # Card centered horizontally near top
        _draw_card(c, chars[num].card_path,
                   px + panel_w / 2 - card_side / 2,
                   py + panel_h - card_side - 6,
                   card_side)
        # Text
        ts = _style(DISPLAY_FONT, 10, 12, tint, TA_CENTER)
        bs = _style(BODY_FONT, 8, 10, PALETTE["soft_white"], TA_CENTER)
        ty = py + panel_h - card_side - 14
        ty = _draw_paragraph(c, name, px + 4, ty, panel_w - 8, ts)
        ty -= 2
        _draw_paragraph(c, blurb, px + 4, ty, panel_w - 8, bs)

    # Footer (above barcode safe zone, left side)
    footer_y = TRIM_Y_BOT + safe_inset + 30
    _draw_paragraph(c, "Ages 4 and up &mdash; squishysmash.com &mdash; "
                       "&copy; 2026 Squishy Smash",
                    inner_x, footer_y, inner_w, footer_style)

    # Barcode safe zone — visible outline ONLY in this draft proof so the
    # designer can see where KDP will overlay the barcode. Comment out the
    # outline before final upload (KDP draws over whatever is there, but a
    # visible box muddles the proof).
    bx = BACK_X + TRIM_W - BARCODE_INSET - BARCODE_W
    by = TRIM_Y_BOT + BARCODE_INSET
    c.setStrokeColor(HexColor("#5A4A6E"))
    c.setDash(3, 3)
    c.rect(bx, by, BARCODE_W, BARCODE_H, fill=0, stroke=1)
    c.setDash()
    c.setFillColor(HexColor("#5A4A6E"))
    c.setFont(BODY_FONT, 7)
    c.drawCentredString(bx + BARCODE_W / 2, by + BARCODE_H / 2,
                        "KDP barcode (auto)")


def draw_front_cover(c: canvas_mod.Canvas) -> None:
    """Front cover: title block + 3-mascot hero cluster."""
    chars = {ch.num: ch for ch in all_characters()}

    safe_inset = 0.375 * INCH
    inner_x = FRONT_X + safe_inset
    inner_w = TRIM_W - 2 * safe_inset
    inner_cx = FRONT_X + TRIM_W / 2

    # Title block (upper third)
    pink_style = _style(DISPLAY_FONT, 56, 60, PALETTE["pink"], TA_CENTER)
    cream_style = _style(DISPLAY_FONT, 56, 60, PALETTE["cream"], TA_CENTER)

    # _draw_paragraph returns the y-position at the BOTTOM of the
    # just-drawn block (PDF coords: smaller y = lower on page). The
    # subtitle/tagline lines below use the correct `y -= gap` pattern;
    # the wordmark block previously tried to "advance" with `+ 56`,
    # which moved upward in PDF space and dropped SMASH back on top
    # of SQUISHY (~4pt offset = total overlap). Use the standard
    # draw / y -= gap / draw pattern.
    y = TRIM_Y_TOP - safe_inset
    y = _draw_paragraph(c, "SQUISHY", inner_x, y, inner_w, pink_style)
    y -= 20
    y = _draw_paragraph(c, "SMASH", inner_x, y, inner_w, cream_style)
    y -= 12

    sub_style = _style(DISPLAY_FONT, 22, 26, PALETTE["soft_white"], TA_CENTER)
    y = _draw_paragraph(c, "<i>Meet the Squishies</i>",
                        inner_x, y, inner_w, sub_style)
    y -= 6

    tag_style = _style(BODY_FONT, 12, 14, PALETTE["soft_white"], TA_CENTER)
    y = _draw_paragraph(c, "A Character Adventure Book",
                        inner_x, y, inner_w, tag_style)

    # Hero card cluster (lower two-thirds)
    hero_side = 150
    spacing = 18
    total_w = hero_side * 3 + spacing * 2
    start_x = inner_cx - total_w / 2
    hero_y = TRIM_Y_BOT + safe_inset + 70
    for i, num in enumerate([1, 17, 33]):
        _draw_card(c, chars[num].card_path,
                   start_x + i * (hero_side + spacing), hero_y, hero_side)

    # Volume tag (bottom-right corner inside safe area)
    tag = _style(BODY_FONT, 9, 11, PALETTE["soft_white"], TA_CENTER)
    _draw_paragraph(c, "Book One",
                    FRONT_X + TRIM_W - safe_inset - 80,
                    TRIM_Y_BOT + safe_inset + 14, 80, tag)


def build(out_path: Path = COVER_PDF) -> Path:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    c = canvas_mod.Canvas(str(out_path), pagesize=(COVER_W, COVER_H))
    c.setTitle("Squishy Smash: Meet the Squishies — Cover")
    c.setAuthor("Squishy Smash")
    draw_full_background(c)
    draw_back_cover(c)
    draw_spine(c)
    draw_front_cover(c)
    c.showPage()
    c.save()
    return out_path


if __name__ == "__main__":
    pdf = build()
    print(f"Wrote {pdf} "
          f"({COVER_W / 72:.4f} x {COVER_H / 72:.4f} in, "
          f"spine {SPINE_W_IN:.4f} in)")
