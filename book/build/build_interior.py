"""
Build the 32-page interior PDF for the Squishy Smash KDP character book.

Output: book/build/out/interior.pdf

Usage:
    python -m pip install -r book/build/requirements.txt
    python book/build/build_interior.py

The PDF is a draft proof: layout is intentionally simple so it can be opened
in a viewer, page-flipped end to end, and validated against the manuscript
(book/manuscript/01_manuscript.md). Final design polish (custom illustrations
for intro spreads, decorative borders, etc.) is meant to be done in a layout
tool. Every interior page is the same size (8.75 x 8.75 in, full bleed), so
the PDF uploads cleanly to KDP as-is.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Callable

from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as canvas_mod
from reportlab.platypus import Paragraph

# Make `config` importable when running as a script.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import (  # noqa: E402
    BLEED, BRAND_ICON, FONT_PATH, OUT_DIR, PACK_TINTS, PAGE_H, PAGE_W,
    PALETTE, SAFE_INSET, all_characters,
)
from image_helpers import draw_card  # noqa: E402

INTERIOR_PDF = OUT_DIR / "interior.pdf"

# ---------------------------------------------------------------------------
# Font registration. Fall back to Helvetica if the bundled Fredoka file is
# missing (so the build still runs in a fresh checkout that hasn't synced LFS).
# ---------------------------------------------------------------------------

DISPLAY_FONT = "Helvetica-Bold"
BODY_FONT = "Helvetica"

if FONT_PATH.exists():
    pdfmetrics.registerFont(TTFont("Fredoka", str(FONT_PATH)))
    DISPLAY_FONT = "Fredoka"
    BODY_FONT = "Fredoka"


# ---------------------------------------------------------------------------
# Style helpers
# ---------------------------------------------------------------------------

def style(font: str, size: float, leading: float, color: str,
          alignment: int = TA_LEFT) -> ParagraphStyle:
    return ParagraphStyle(
        f"s_{font}_{size}",
        fontName=font, fontSize=size, leading=leading,
        textColor=HexColor(color), alignment=alignment,
    )


def draw_background(c: canvas_mod.Canvas, color: str) -> None:
    c.setFillColor(HexColor(color))
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)


def draw_paragraph(c: canvas_mod.Canvas, text: str, x: float, y_top: float,
                   width: float, p_style: ParagraphStyle) -> float:
    """Draw a paragraph anchored at its TOP-left and return remaining y_top
    after the paragraph is laid out (for vertical stacking)."""
    para = Paragraph(text, p_style)
    _, h = para.wrap(width, PAGE_H)
    para.drawOn(c, x, y_top - h)
    return y_top - h


def draw_card_image(c: canvas_mod.Canvas, image_path: Path,
                    x: float, y: float, w: float, h: float) -> None:
    """Draw a card preserving its 3:4 aspect inside (x, y, w, h)."""
    draw_card(c, image_path, x, y, w, h)


# ---------------------------------------------------------------------------
# Page templates
# ---------------------------------------------------------------------------

def page_half_title(c: canvas_mod.Canvas) -> None:
    """Page 1: half-title — just the wordmark, decorative."""
    draw_background(c, PALETTE["bg"])
    c.setFillColor(HexColor(PALETTE["soft_white"]))
    c.setFont(DISPLAY_FONT, 24)
    c.drawCentredString(PAGE_W / 2, PAGE_H / 2, "SQUISHY SMASH")


def page_blank(c: canvas_mod.Canvas) -> None:
    """Page 2: blank with brand background. KDP forbids fully-blank pages
    in some layouts; a solid color counts as content."""
    draw_background(c, PALETTE["bg"])


def page_title(c: canvas_mod.Canvas) -> None:
    """Page 3: title page."""
    draw_background(c, PALETTE["bg"])
    cx = PAGE_W / 2

    # Wordmark
    c.setFillColor(HexColor(PALETTE["pink"]))
    c.setFont(DISPLAY_FONT, 48)
    c.drawCentredString(cx, PAGE_H - SAFE_INSET - 50, "SQUISHY")
    c.setFillColor(HexColor(PALETTE["cream"]))
    c.drawCentredString(cx, PAGE_H - SAFE_INSET - 100, "SMASH")

    # Subtitle
    c.setFillColor(HexColor(PALETTE["soft_white"]))
    c.setFont(DISPLAY_FONT, 22)
    c.drawCentredString(cx, PAGE_H - SAFE_INSET - 140, "Meet the Squishies")

    # Tagline
    c.setFont(BODY_FONT, 12)
    c.drawCentredString(cx, PAGE_H - SAFE_INSET - 162, "A Character Adventure Book")

    # Hero card cluster — one mascot per pack
    chars = {c.num: c for c in all_characters()}
    hero_size = 130
    spacing = 30
    total_w = hero_size * 3 + spacing * 2
    start_x = cx - total_w / 2
    y = SAFE_INSET + 80
    for i, num in enumerate([1, 17, 33]):
        draw_card_image(c, chars[num].card_path,
                        start_x + i * (hero_size + spacing), y,
                        hero_size, hero_size)


def page_copyright(c: canvas_mod.Canvas) -> None:
    """Page 4: copyright."""
    draw_background(c, PALETTE["bg"])

    body = style(BODY_FONT, 11, 16, PALETTE["soft_white"], TA_CENTER)
    small = style(BODY_FONT, 9, 13, PALETTE["soft_white"], TA_CENTER)

    cx = PAGE_W / 2
    y = PAGE_H / 2 + 80

    y = draw_paragraph(c, "<b>Squishy Smash: Meet the Squishies</b>",
                       SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, body)
    y -= 12
    y = draw_paragraph(c, "&copy; 2026 Squishy Smash. All rights reserved.",
                       SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, small)
    y -= 8
    y = draw_paragraph(
        c,
        "No part of this book may be reproduced without permission, "
        "except for short quotations in reviews.",
        SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, small,
    )
    y -= 12
    y = draw_paragraph(c, "squishysmash.com",
                       SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, small)
    y -= 8
    y = draw_paragraph(c, "Printed by Amazon KDP.",
                       SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, small)

    # Tiny brand mark at bottom corner
    if BRAND_ICON.exists():
        c.drawImage(ImageReader(str(BRAND_ICON)),
                    PAGE_W - SAFE_INSET - 32, SAFE_INSET, 28, 28,
                    mask="auto", preserveAspectRatio=True)


def page_welcome_l(c: canvas_mod.Canvas) -> None:
    """Page 5: Welcome left page — big headline."""
    draw_background(c, PALETTE["bg"])
    headline = style(DISPLAY_FONT, 36, 42, PALETTE["pink"], TA_LEFT)
    body = style(BODY_FONT, 14, 20, PALETTE["soft_white"], TA_LEFT)

    y = PAGE_H - SAFE_INSET - 60
    y = draw_paragraph(c, "Welcome to<br/>Squishy Smash!",
                       SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, headline)
    y -= 20
    draw_paragraph(
        c,
        "A bouncy, bright, and squishy world &mdash; full of soft little "
        "friends waiting to be discovered.",
        SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, body,
    )


def page_welcome_r(c: canvas_mod.Canvas) -> None:
    """Page 6: Welcome right page — three short lines."""
    draw_background(c, PALETTE["bg"])
    body = style(BODY_FONT, 16, 28, PALETTE["soft_white"], TA_LEFT)
    big = style(DISPLAY_FONT, 22, 30, PALETTE["cream"], TA_LEFT)

    y = PAGE_H - SAFE_INSET - 60
    y = draw_paragraph(c, "Every squishy belongs to a special pack.",
                       SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, body)
    y -= 24
    for tint, line in [
        (PALETTE["lime"], "Some are sweet."),
        (PALETTE["jelly_blue"], "Some are gooey."),
        (PALETTE["lavender"], "Some are spooky-cute."),
    ]:
        s = style(DISPLAY_FONT, 22, 30, tint, TA_LEFT)
        y = draw_paragraph(c, line, SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, s)
        y -= 6
    y -= 20
    draw_paragraph(
        c,
        "And every single one is ready to bounce, wobble, and shine.",
        SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, body,
    )


def page_meet_packs_l(c: canvas_mod.Canvas) -> None:
    """Page 7: Meet the packs — big title."""
    draw_background(c, PALETTE["bg"])
    headline = style(DISPLAY_FONT, 30, 36, PALETTE["pink"], TA_CENTER)
    sub = style(DISPLAY_FONT, 22, 28, PALETTE["cream"], TA_CENTER)

    y = PAGE_H / 2 + 50
    y = draw_paragraph(c, "Three Packs.", SAFE_INSET, y,
                       PAGE_W - 2 * SAFE_INSET, headline)
    y -= 12
    y = draw_paragraph(c, "One Squishy Smash World.",
                       SAFE_INSET, y, PAGE_W - 2 * SAFE_INSET, sub)


def page_meet_packs_r(c: canvas_mod.Canvas) -> None:
    """Page 8: three pack panels stacked."""
    draw_background(c, PALETTE["bg"])
    panel_h = (PAGE_H - 2 * SAFE_INSET - 30) / 3
    chars = {c.num: c for c in all_characters()}

    panels = [
        ("Squishy Foods", "Warm, tasty, and full of dessert dreams.",
         PALETTE["lime"], [1, 2, 3]),
        ("Goo & Fidgets", "Glossy, bouncy, satisfying squish.",
         PALETTE["jelly_blue"], [17, 18, 19]),
        ("Creepy-Cute Creatures", "Spooky and sweet — the perfect squishy mix.",
         PALETTE["lavender"], [33, 34, 35]),
    ]

    for i, (name, blurb, tint, nums) in enumerate(panels):
        y_top = PAGE_H - SAFE_INSET - i * (panel_h + 15)
        y_bot = y_top - panel_h
        # Tinted panel
        c.setFillColor(HexColor(tint))
        c.setFillAlpha(0.16)
        c.roundRect(SAFE_INSET, y_bot, PAGE_W - 2 * SAFE_INSET, panel_h, 10,
                    fill=1, stroke=0)
        c.setFillAlpha(1.0)
        # Three card thumbnails on the right
        thumb = panel_h - 16
        thumb_x_start = PAGE_W - SAFE_INSET - thumb * 3 - 24
        for j, num in enumerate(nums):
            draw_card_image(c, chars[num].card_path,
                            thumb_x_start + j * (thumb + 4), y_bot + 8,
                            thumb, thumb)
        # Pack name + blurb on the left
        title_style = style(DISPLAY_FONT, 18, 22, tint, TA_LEFT)
        body_style = style(BODY_FONT, 11, 14, PALETTE["soft_white"], TA_LEFT)
        text_w = thumb_x_start - SAFE_INSET - 20
        ty = y_top - 18
        ty = draw_paragraph(c, name, SAFE_INSET + 14, ty, text_w, title_style)
        ty -= 6
        draw_paragraph(c, blurb, SAFE_INSET + 14, ty, text_w, body_style)


def page_pack_intro_text(c: canvas_mod.Canvas, pack_name: str,
                          headline: str, body: str) -> None:
    """Pack intro left page — big headline + lede."""
    draw_background(c, PALETTE["bg"])
    tint = PACK_TINTS[pack_name]
    h_style = style(DISPLAY_FONT, 32, 38, tint, TA_LEFT)
    b_style = style(BODY_FONT, 14, 20, PALETTE["soft_white"], TA_LEFT)

    y = PAGE_H - SAFE_INSET - 60
    y = draw_paragraph(c, headline, SAFE_INSET, y,
                       PAGE_W - 2 * SAFE_INSET, h_style)
    y -= 24
    draw_paragraph(c, body, SAFE_INSET, y,
                   PAGE_W - 2 * SAFE_INSET, b_style)


def page_pack_intro_scene(c: canvas_mod.Canvas, pack_name: str,
                           card_nums: list[int]) -> None:
    """Pack intro right page — collage of character thumbnails."""
    draw_background(c, PALETTE["bg"])
    tint = PACK_TINTS[pack_name]
    chars = {c.num: c for c in all_characters()}

    # Soft tinted glow background
    c.setFillColor(HexColor(tint))
    c.setFillAlpha(0.10)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillAlpha(1.0)

    # 3x3-ish scattered thumbnails (6-8 cards depending on pack)
    n = len(card_nums)
    cols = 3
    rows = (n + cols - 1) // cols
    grid_w = PAGE_W - 2 * SAFE_INSET
    grid_h = PAGE_H - 2 * SAFE_INSET
    cell_w = grid_w / cols
    cell_h = grid_h / rows
    side = min(cell_w, cell_h) * 0.78

    for i, num in enumerate(card_nums):
        col = i % cols
        row = i // cols
        cx = SAFE_INSET + col * cell_w + cell_w / 2
        cy = PAGE_H - SAFE_INSET - row * cell_h - cell_h / 2
        # Slight stagger so it doesn't feel grid-locked
        offset = ((i * 37) % 13 - 6)
        draw_card_image(c, chars[num].card_path,
                        cx - side / 2 + offset, cy - side / 2,
                        side, side)


def page_character_grid(c: canvas_mod.Canvas, nums: list[int],
                         show_traits: bool = True,
                         show_flavor: bool = False) -> None:
    """Generic character grid — N cards stacked vertically. Layout adapts to
    count: 1=hero, 2=large, 3=medium, 4+=compact."""
    draw_background(c, PALETTE["bg"])
    chars = {c.num: c for c in all_characters()}
    n = len(nums)
    avail_h = PAGE_H - 2 * SAFE_INSET
    row_h = avail_h / n
    pad = 8

    for i, num in enumerate(nums):
        char = chars[num]
        y_top = PAGE_H - SAFE_INSET - i * row_h
        y_bot = y_top - row_h
        # Image on the left
        img_side = row_h - pad * 2
        img_side = min(img_side, PAGE_W * 0.32)
        draw_card_image(c, char.card_path, SAFE_INSET, y_bot + pad,
                        img_side, img_side)

        # Text on the right
        text_x = SAFE_INSET + img_side + 16
        text_w = PAGE_W - SAFE_INSET - text_x

        # Compact mode for 4+ cards: name + intro only
        compact = n >= 4

        tint = PACK_TINTS[char.pack]
        rarity_color = {
            "common": PALETTE["soft_white"],
            "rare": PALETTE["jelly_blue"],
            "epic": PALETTE["lavender"],
            "mythic": PALETTE["cream"],
        }[char.rarity]

        name_size = 22 if not compact else 16
        name_style = style(DISPLAY_FONT, name_size, name_size + 4,
                           rarity_color, TA_LEFT)
        pack_style = style(BODY_FONT, 9, 12, tint, TA_LEFT)
        intro_size = 11 if not compact else 10
        intro_style = style(BODY_FONT, intro_size, intro_size + 4,
                            PALETTE["soft_white"], TA_LEFT)
        trait_style = style(BODY_FONT, 10, 13, tint, TA_LEFT)
        flavor_style = style(BODY_FONT, 9, 12, PALETTE["cream"], TA_LEFT)

        ty = y_top - pad - name_size
        # Mythic flair
        name_text = char.name
        if char.rarity == "mythic":
            name_text = f"{char.name} ✴"  # heavy four-pointed star
        ty = draw_paragraph(c, name_text, text_x, ty + name_size,
                            text_w, name_style)
        ty -= 2
        if not compact:
            ty = draw_paragraph(c, char.pack, text_x, ty, text_w, pack_style)
            ty -= 4
        ty = draw_paragraph(c, char.intro, text_x, ty, text_w, intro_style)
        if show_traits and not compact:
            ty -= 4
            ty = draw_paragraph(c,
                                f"&bull; {char.traits[0]}<br/>&bull; {char.traits[1]}",
                                text_x, ty, text_w, trait_style)
        if show_flavor and not compact:
            ty -= 4
            draw_paragraph(c, f"<i>{char.flavor}</i>", text_x, ty, text_w,
                           flavor_style)


def page_closing(c: canvas_mod.Canvas) -> None:
    """Final right-page closing note (unused if 32 pages exact, kept for
    optional 33rd inside-back-cover printing)."""
    draw_background(c, PALETTE["bg"])
    body = style(BODY_FONT, 14, 20, PALETTE["soft_white"], TA_CENTER)
    sig = style(DISPLAY_FONT, 14, 18, PALETTE["pink"], TA_CENTER)

    y = PAGE_H / 2 + 40
    y = draw_paragraph(
        c,
        "From sweet snacks to spooky friends, the world of Squishy Smash "
        "is full of squishies to meet, collect, and love.",
        SAFE_INSET + 20, y, PAGE_W - 2 * SAFE_INSET - 40, body,
    )
    y -= 20
    draw_paragraph(c, "<i>See you on the next bounce.</i>",
                   SAFE_INSET + 20, y, PAGE_W - 2 * SAFE_INSET - 40, sig)


# ---------------------------------------------------------------------------
# Page order
# ---------------------------------------------------------------------------

PageRenderer = Callable[[canvas_mod.Canvas], None]

PAGE_ORDER: list[PageRenderer] = [
    # 1-2: half-title + blank
    page_half_title,
    page_blank,
    # 3-4: title + copyright
    page_title,
    page_copyright,
    # 5-6: welcome
    page_welcome_l,
    page_welcome_r,
    # 7-8: meet the packs
    page_meet_packs_l,
    page_meet_packs_r,
    # 9-10: foods intro
    lambda c: page_pack_intro_text(
        c, "Squishy Foods", "Welcome to<br/>Squishy Foods",
        "Where the softest snacks and sweetest squishies bounce through "
        "a world full of treats."),
    lambda c: page_pack_intro_scene(c, "Squishy Foods",
                                    [1, 2, 3, 4, 5, 6, 7, 8, 9]),
    # 11-12: foods featured (Soft Dumpling hero | Jelly Bun + Peach Mochi)
    lambda c: page_character_grid(c, [1], show_flavor=True),
    lambda c: page_character_grid(c, [2, 3]),
    # 13-14: Syrup + Cream | Rice Ball hero
    lambda c: page_character_grid(c, [4, 5]),
    lambda c: page_character_grid(c, [6], show_flavor=True),
    # 15-16: Marshmallow + Pudding | Strawberry + Rainbow
    lambda c: page_character_grid(c, [7, 8]),
    lambda c: page_character_grid(c, [9, 10]),
    # 17-18: Foods premium (3 each)
    lambda c: page_character_grid(c, [11, 12, 13]),
    lambda c: page_character_grid(c, [14, 15, 16]),
    # 19-20: goo intro
    lambda c: page_pack_intro_text(
        c, "Goo & Fidgets", "Welcome to<br/>Goo & Fidgets",
        "In Goo &amp; Fidgets, every wobble, splash, and stretch turns "
        "into a satisfying surprise."),
    lambda c: page_pack_intro_scene(c, "Goo & Fidgets",
                                    [17, 18, 19, 20, 21, 22, 23, 24, 25]),
    # 21-22: Goo Ball + Bubble | Stretch + Soft Stress
    lambda c: page_character_grid(c, [17, 18]),
    lambda c: page_character_grid(c, [19, 20]),
    # 23-24: Jelly Pad + Sticky | Wobble + Squish Capsule
    lambda c: page_character_grid(c, [21, 22]),
    lambda c: page_character_grid(c, [23, 24]),
    # 25-26: Goo premium (4 each, compact)
    lambda c: page_character_grid(c, [25, 26, 27, 28]),
    lambda c: page_character_grid(c, [29, 30, 31, 32]),
    # 27-28: creatures intro
    lambda c: page_pack_intro_text(
        c, "Creepy-Cute Creatures", "Welcome to<br/>Creepy-Cute Creatures",
        "In this world, spooky and sweet become the perfect squishy mix."),
    lambda c: page_pack_intro_scene(c, "Creepy-Cute Creatures",
                                    [33, 34, 35, 36, 37, 38, 39, 40, 41]),
    # 29-30: creatures core (4 each, compact)
    lambda c: page_character_grid(c, [33, 34, 35, 36]),
    lambda c: page_character_grid(c, [37, 38, 39, 40]),
    # 31-32: creatures premium finale (4 each, compact)
    lambda c: page_character_grid(c, [41, 42, 43, 44]),
    lambda c: page_character_grid(c, [45, 46, 47, 48]),
]


def build(out_path: Path = INTERIOR_PDF) -> Path:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    c = canvas_mod.Canvas(str(out_path), pagesize=(PAGE_W, PAGE_H))
    c.setTitle("Squishy Smash: Meet the Squishies")
    c.setAuthor("Squishy Smash")
    c.setSubject("Character book")
    for render in PAGE_ORDER:
        render(c)
        c.showPage()
    c.save()
    return out_path


if __name__ == "__main__":
    pdf = build()
    print(f"Wrote {pdf} ({len(PAGE_ORDER)} pages, "
          f"{PAGE_W / 72:.3f} x {PAGE_H / 72:.3f} in)")
