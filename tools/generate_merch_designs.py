"""
Render the Squishy Smash merchandise print-ready designs.

Outputs print-ready PNGs into `commerce/print_ready/`, each at 300 DPI
sized for the matching Printful product type (apparel, stickers, mugs,
posters, totes). Matches the catalog in `commerce/SHOPIFY_LAUNCH_GUIDE.md`.

Re-run any time the cards or brand assets change:

    python tools/generate_merch_designs.py

Patterns mirror `tools/render_x_banner.py` — same Fredoka font, same
brand palette, same scatter-sparkles helper aesthetic.

Bible alignment (per `book/STORY_BIBLE.md`, locked 2026-05-13):
- The three Pact-line designs (`tee_pact_line`, `sticker_pact_line`,
  `mug_pact_wrap`) lead with the canonical brand line ("Every pop is
  a hello. Every hello comes back."). They are the most evergreen
  pieces in the catalog — no character art, no time-bound copy.
- The Squishkeeper is NEVER drawn — these designs use sparkle scatter
  and typography only. Do not add silhouettes or implied figures.
"""

from __future__ import annotations

import math
import random
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
CARDS_DIR = REPO_ROOT / "assets" / "cards" / "final_48"
FONT_PATH = REPO_ROOT / "assets" / "google_fonts" / "Fredoka.ttf"
OUT_DIR = REPO_ROOT / "commerce" / "print_ready"

# Brand palette (mirrors brand_and_social_presence.md, render_x_banner.py)
BG_DEEP = (18, 11, 23)       # #120B17
PINK = (255, 143, 184)       # #FF8FB8
CREAM = (255, 211, 110)      # #FFD36E
JELLY_BLUE = (127, 231, 255) # #7FE7FF
LAVENDER = (201, 139, 255)   # #C98BFF
LIME = (182, 255, 92)        # #B6FF5C
WHITE = (245, 240, 250)


# ---------------------------------------------------------------------------
# Asset loading
# ---------------------------------------------------------------------------

def card_path(num: int) -> Path:
    """Resolve `assets/cards/final_48/<num>_<Name>.webp` from index alone."""
    matches = sorted(CARDS_DIR.glob(f"{num:03d}_*.webp"))
    if not matches:
        raise FileNotFoundError(f"No card found for index {num}")
    return matches[0]


def load_card(num: int) -> Image.Image:
    return Image.open(card_path(num)).convert("RGBA")


def font(size: int, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    """Fredoka at the given pt size. Variable font; weight ignored at the
    PIL level but documented for clarity."""
    return ImageFont.truetype(str(FONT_PATH), size)


# ---------------------------------------------------------------------------
# Composition primitives
# ---------------------------------------------------------------------------

def transparent_canvas(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def dark_canvas(w: int, h: int) -> Image.Image:
    """Brand-plum bg with two soft radial glows for visual depth."""
    bg = Image.new("RGBA", (w, h), (*BG_DEEP, 255))

    def add_glow(cx: int, cy: int, color: tuple[int, int, int],
                 radius: int, alpha: int) -> None:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(glow)
        d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius),
                  fill=(*color, alpha))
        glow = glow.filter(ImageFilter.GaussianBlur(radius=radius // 4))
        bg.alpha_composite(glow)

    add_glow(int(w * 0.15), int(h * 0.15), PINK, int(w * 0.3), 90)
    add_glow(int(w * 0.85), int(h * 0.85), LAVENDER, int(w * 0.35), 80)
    return bg


def scatter_sparkles(canvas: Image.Image, count: int,
                     colors: Iterable[tuple[int, int, int]],
                     seed: int = 0,
                     size_range: tuple[int, int] = (4, 14),
                     alpha: int = 200) -> None:
    """Sprinkle small twinkles across the canvas. Same idea as the X-banner
    scatter, but tunable per product (apparel uses fewer than posters)."""
    rng = random.Random(seed)
    palette = list(colors)
    d = ImageDraw.Draw(canvas)
    w, h = canvas.size
    margin = max(20, w // 30)
    for _ in range(count):
        x = rng.randrange(margin, w - margin)
        y = rng.randrange(margin, h - margin)
        s = rng.randrange(size_range[0], size_range[1])
        c = rng.choice(palette)
        # Diamond-shaped twinkle (rotated square) — feels softer than a circle
        d.polygon([(x, y - s), (x + s, y), (x, y + s), (x - s, y)],
                  fill=(*c, alpha))


def draw_centered_text(canvas: Image.Image, cy: int, text: str,
                        size: int, color: tuple[int, int, int],
                        shadow: bool = True,
                        track_px: int = 0) -> None:
    """Render `text` horizontally-centered at vertical center `cy`."""
    f = font(size)
    w, _ = canvas.size
    d = ImageDraw.Draw(canvas)
    # Compute width with optional letter tracking
    if track_px:
        text_w = sum(d.textbbox((0, 0), ch, font=f)[2] for ch in text) + \
                 track_px * (len(text) - 1)
        x = (w - text_w) // 2
        cur = x
        for ch in text:
            if shadow:
                d.text((cur + 4, cy + 4), ch, font=f, fill=(0, 0, 0, 160))
            d.text((cur, cy), ch, font=f, fill=(*color, 255))
            cur += d.textbbox((0, 0), ch, font=f)[2] + track_px
    else:
        bbox = d.textbbox((0, 0), text, font=f)
        x = (w - (bbox[2] - bbox[0])) // 2
        if shadow:
            d.text((x + 4, cy + 4), text, font=f, fill=(0, 0, 0, 160))
        d.text((x, cy), text, font=f, fill=(*color, 255))


def fit_card(card: Image.Image, max_w: int, max_h: int) -> Image.Image:
    """Resize while keeping the card's native 3:4 aspect ratio."""
    aspect = card.width / card.height
    box_aspect = max_w / max_h
    if aspect > box_aspect:
        new_w, new_h = max_w, int(max_w / aspect)
    else:
        new_w, new_h = int(max_h * aspect), max_h
    return card.resize((new_w, new_h), Image.LANCZOS)


# ---------------------------------------------------------------------------
# Apparel — t-shirts and hoodie share the wordmark file
# ---------------------------------------------------------------------------

TEE_W, TEE_H = 4500, 5400


def build_tee_wordmark() -> None:
    """Brand wordmark on transparent background — DTG print-ready.
    Sparkle scatter clusters around the wordmark, not edge-to-edge,
    so the printed design has clean negative space on the shirt."""
    canvas = transparent_canvas(TEE_W, TEE_H)
    cx = TEE_W // 2

    # SQUISHY (pink) over SMASH (cream), centered vertically
    sq_y = int(TEE_H * 0.30)
    sm_y = int(TEE_H * 0.50)
    draw_centered_text(canvas, sq_y, "SQUISHY", size=720, color=PINK)
    draw_centered_text(canvas, sm_y, "SMASH",   size=720, color=CREAM)

    # Tagline under SMASH
    tag_y = int(TEE_H * 0.68)
    draw_centered_text(canvas, tag_y, "MEET THE SQUISHIES",
                       size=180, color=WHITE, track_px=20)

    # Sparkle scatter: clustered in a vertical band around the wordmark
    band = transparent_canvas(TEE_W, TEE_H)
    scatter_sparkles(band, count=80,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=11, size_range=(8, 22), alpha=200)
    canvas.alpha_composite(band)

    out = OUT_DIR / "tee_wordmark.png"
    canvas.save(out, optimize=True)
    print(f"[tee] {out.name} ({canvas.size})")


def build_tee_card_hero(card_num: int, out_name: str,
                         tagline: str | None = None) -> None:
    """Center one card on a transparent canvas, with the wordmark
    above and an optional tagline beneath. Used for both adult and
    kid hero tees."""
    canvas = transparent_canvas(TEE_W, TEE_H)

    # Wordmark up top (smaller than the dedicated wordmark tee)
    draw_centered_text(canvas, int(TEE_H * 0.06),
                       "SQUISHY SMASH",
                       size=320, color=PINK)

    # Card centered, sized to ~52% of canvas height
    card = load_card(card_num)
    card_h = int(TEE_H * 0.55)
    card = fit_card(card, max_w=TEE_W - 800, max_h=card_h)
    card_x = (TEE_W - card.width) // 2
    card_y = int(TEE_H * 0.18)
    canvas.alpha_composite(card, (card_x, card_y))

    # Tagline below the card
    if tagline:
        draw_centered_text(canvas, card_y + card.height + 100,
                           tagline, size=180, color=CREAM)

    # Sparkle scatter, restrained
    band = transparent_canvas(TEE_W, TEE_H)
    scatter_sparkles(band, count=50,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=card_num, size_range=(6, 16), alpha=180)
    canvas.alpha_composite(band)

    out = OUT_DIR / out_name
    canvas.save(out, optimize=True)
    print(f"[tee] {out.name} ({canvas.size})")


def build_tee_pact_line() -> None:
    """The brand's most evergreen tee — canonical Pact line in two
    color-stacked lines, no card art, sparkle scatter only.

    Per `book/STORY_BIBLE.md` §2 the Pact line ("Every pop is a hello.
    Every hello comes back.") is approved cross-surface canon. This
    design carries the whole brand in one shirt without depending on
    a featured character — useful for adult buyers who don't have a
    favorite squishy yet."""
    canvas = transparent_canvas(TEE_W, TEE_H)

    # Small SQUISHY SMASH wordmark up top so the tee still reads as
    # branded at thumbnail size.
    draw_centered_text(canvas, int(TEE_H * 0.10),
                       "SQUISHY SMASH",
                       size=240, color=PINK)

    # The Pact, two stacked lines, alternating cream/pink so the
    # rhythm of "hello / comes back" reads visually as well as verbally.
    line1_y = int(TEE_H * 0.34)
    line2_y = int(TEE_H * 0.50)
    draw_centered_text(canvas, line1_y,
                       "Every pop is a hello.",
                       size=300, color=CREAM)
    draw_centered_text(canvas, line2_y,
                       "Every hello comes back.",
                       size=300, color=PINK)

    # Quiet attribution line — keeps the Squishkeeper present without
    # drawing them.
    draw_centered_text(canvas, int(TEE_H * 0.70),
                       "— the Squishkeeper",
                       size=110, color=WHITE)

    # Sparkle scatter clustered around the typography, not edge-to-edge,
    # so the tee has clean negative space.
    band = transparent_canvas(TEE_W, TEE_H)
    scatter_sparkles(band, count=70,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=42, size_range=(8, 22), alpha=180)
    canvas.alpha_composite(band)

    out = OUT_DIR / "tee_pact_line.png"
    canvas.save(out, optimize=True)
    print(f"[tee] {out.name} ({canvas.size})")


def build_tote_trio() -> None:
    """Three cards arranged like the cover trio (Goo Ball rotated CCW,
    Blushy Bun Bunny center, Soft Dumpling rotated CW), with brand
    wordmark above. Square 4200x4200 print area."""
    SIDE = 4200
    canvas = transparent_canvas(SIDE, SIDE)

    # Wordmark top
    draw_centered_text(canvas, int(SIDE * 0.06),
                       "SQUISHY SMASH",
                       size=380, color=PINK)
    draw_centered_text(canvas, int(SIDE * 0.16),
                       "MEET THE SQUISHIES",
                       size=130, color=CREAM, track_px=14)

    # Trio: Goo Ball (17) left -10°, Blushy Bun Bunny (33) center, Soft Dumpling (1) right +10°
    center_card = load_card(33)
    center_card = fit_card(center_card, max_w=int(SIDE * 0.42),
                            max_h=int(SIDE * 0.55))
    center_x = (SIDE - center_card.width) // 2
    center_y = int(SIDE * 0.30)

    # Side cards rotated, smaller (78%)
    for card_num, angle, side in [(17, -10, "left"), (1, +10, "right")]:
        side_card = load_card(card_num)
        side_card = fit_card(side_card,
                             max_w=int(center_card.width * 0.78),
                             max_h=int(center_card.height * 0.78))
        # Rotate on a padded tile so corners don't clip
        pad = 200
        tile = Image.new("RGBA",
                         (side_card.width + pad * 2,
                          side_card.height + pad * 2),
                         (0, 0, 0, 0))
        tile.paste(side_card, (pad, pad), side_card)
        rotated = tile.rotate(angle, resample=Image.BICUBIC, expand=False)
        if side == "left":
            sx = center_x - side_card.width + 240 - pad
        else:
            sx = center_x + center_card.width - 240 - pad
        sy = center_y + (center_card.height - side_card.height) // 2 - pad
        canvas.alpha_composite(rotated, (sx, sy))

    # Center card on top
    canvas.alpha_composite(center_card, (center_x, center_y))

    # Sparkles
    scatter_sparkles(canvas, count=40,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=42, size_range=(8, 18), alpha=180)

    out = OUT_DIR / "tote_3_pack_trio.png"
    canvas.save(out, optimize=True)
    print(f"[tote] {out.name} ({canvas.size})")


# ---------------------------------------------------------------------------
# Stickers
# ---------------------------------------------------------------------------

def build_sticker_sheet(pack_name: str, card_nums: list[int],
                         out_name: str,
                         tint: tuple[int, int, int]) -> None:
    """4 x 4 sticker sheet at 8.5 x 11 in (2550 x 3300 px @ 300 DPI).
    Each card sits on a transparent bg with a subtle tinted halo so
    it reads as a kiss-cut sticker. Header row identifies the pack."""
    W, H = 2550, 3300
    canvas = Image.new("RGBA", (W, H), (255, 255, 255, 0))

    # Header band — pack name in tint, small subtitle
    header_h = 240
    d = ImageDraw.Draw(canvas)
    # No background fill — keep the sheet itself transparent so Printful
    # sees a pure design + cuts around each sticker shape.
    title_font = font(120)
    sub_font = font(48)
    title_w = d.textbbox((0, 0), pack_name, font=title_font)[2]
    d.text(((W - title_w) // 2 + 4, 80 + 4), pack_name,
           font=title_font, fill=(0, 0, 0, 80))
    d.text(((W - title_w) // 2, 80), pack_name,
           font=title_font, fill=(*tint, 255))
    sub = "16 die-cut stickers · Squishy Smash"
    sub_w = d.textbbox((0, 0), sub, font=sub_font)[2]
    d.text(((W - sub_w) // 2, 200), sub, font=sub_font, fill=(*BG_DEEP, 220))

    # Grid: 4 cols x 4 rows
    cols, rows = 4, 4
    pad_x = 60
    pad_y = 60
    grid_top = header_h + 60
    grid_w = W - pad_x * 2
    grid_h = H - grid_top - 100
    cell_w = (grid_w - pad_x * (cols - 1)) // cols
    cell_h = (grid_h - pad_y * (rows - 1)) // rows
    # Cards have 3:4 aspect, so fit each into the cell
    for i, num in enumerate(card_nums[:16]):
        col = i % cols
        row = i // cols
        cx_box = pad_x + col * (cell_w + pad_x)
        cy_box = grid_top + row * (cell_h + pad_y)
        card = load_card(num)
        card = fit_card(card, max_w=cell_w, max_h=cell_h)
        # Subtle white-ish halo around card to define cut path visually
        halo_pad = 14
        halo = Image.new("RGBA",
                         (card.width + halo_pad * 2,
                          card.height + halo_pad * 2),
                         (255, 255, 255, 240))
        halo = halo.filter(ImageFilter.GaussianBlur(radius=8))
        # Center within the cell
        cx_card = cx_box + (cell_w - card.width) // 2
        cy_card = cy_box + (cell_h - card.height) // 2
        canvas.alpha_composite(halo, (cx_card - halo_pad, cy_card - halo_pad))
        canvas.alpha_composite(card, (cx_card, cy_card))

    out = OUT_DIR / out_name
    canvas.save(out, optimize=True)
    print(f"[sticker-sheet] {out.name} ({canvas.size})")


def build_sticker_pact_line() -> None:
    """Square 1500x1500 (5 x 5 in @ 300 DPI) Pact-line sticker. Dark
    plum bg, two-line Pact in stacked cream/pink, sparkle scatter.
    Per the bible §2 this is brand canon — printable anywhere."""
    SIDE = 1500
    canvas = dark_canvas(SIDE, SIDE)

    # Top: small wordmark
    draw_centered_text(canvas, int(SIDE * 0.12),
                       "SQUISHY SMASH",
                       size=80, color=PINK, track_px=4)

    # The Pact
    draw_centered_text(canvas, int(SIDE * 0.32),
                       "Every pop",
                       size=170, color=CREAM)
    draw_centered_text(canvas, int(SIDE * 0.43),
                       "is a hello.",
                       size=170, color=CREAM)
    draw_centered_text(canvas, int(SIDE * 0.59),
                       "Every hello",
                       size=170, color=PINK)
    draw_centered_text(canvas, int(SIDE * 0.70),
                       "comes back.",
                       size=170, color=PINK)

    # Quiet attribution
    draw_centered_text(canvas, int(SIDE * 0.86),
                       "— the Squishkeeper",
                       size=58, color=WHITE)

    # Sparkles
    scatter_sparkles(canvas, count=45,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=7, size_range=(6, 16), alpha=200)

    out = OUT_DIR / "sticker_pact_line.png"
    canvas.save(out, optimize=True)
    print(f"[sticker] {out.name} ({canvas.size})")


def build_sticker_solo(card_num: int, out_name: str,
                        rim_color: tuple[int, int, int] = CREAM) -> None:
    """Single oversized sticker — the card on a transparent bg with
    a subtle holographic-ish gradient halo. 1500 x 1500 px @ 300 DPI =
    5 x 5 in printed size."""
    SIDE = 1500
    canvas = transparent_canvas(SIDE, SIDE)
    card = load_card(card_num)
    card = fit_card(card, max_w=int(SIDE * 0.78), max_h=int(SIDE * 0.94))

    # Halo: glow around card (printed in regular ink; the holographic
    # effect comes from the sticker stock itself, not the print)
    halo_pad = 40
    halo = Image.new("RGBA",
                     (card.width + halo_pad * 2,
                      card.height + halo_pad * 2),
                     (*rim_color, 200))
    halo = halo.filter(ImageFilter.GaussianBlur(radius=24))
    halo_x = (SIDE - halo.width) // 2
    halo_y = (SIDE - halo.height) // 2
    canvas.alpha_composite(halo, (halo_x, halo_y))

    # Card centered
    cx = (SIDE - card.width) // 2
    cy = (SIDE - card.height) // 2
    canvas.alpha_composite(card, (cx, cy))

    out = OUT_DIR / out_name
    canvas.save(out, optimize=True)
    print(f"[sticker-solo] {out.name} ({canvas.size})")


# ---------------------------------------------------------------------------
# Mug wraps — 9 x 3.75 in @ 300 DPI = 2700 x 1125 px
# ---------------------------------------------------------------------------

MUG_W, MUG_H = 2700, 1125


def build_mug_wordmark() -> None:
    canvas = dark_canvas(MUG_W, MUG_H)
    # Wordmark on left side
    draw_centered_text(canvas, int(MUG_H * 0.18), "SQUISHY", size=240, color=PINK)
    draw_centered_text(canvas, int(MUG_H * 0.55), "SMASH",   size=240, color=CREAM)
    # Tagline at bottom
    draw_centered_text(canvas, int(MUG_H * 0.85),
                       "soft. silly. sparkly.",
                       size=70, color=WHITE)
    scatter_sparkles(canvas, count=60,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=99, size_range=(4, 12), alpha=200)
    out = OUT_DIR / "mug_wordmark_wrap.png"
    canvas.save(out, optimize=True)
    print(f"[mug] {out.name} ({canvas.size})")


def build_mug_pact_wrap() -> None:
    """11 oz mug wrap (9 x 3.75 in) with the Pact stacked on one face,
    sparkle scatter wrapping to the other face. Single-face layout is
    cleaner than splitting the two lines across mug sides — both lines
    visible at one rotation, no clipping. Dark plum bg. No character
    art — bible-canon brand piece per `STORY_BIBLE.md` §2.

    Type sizes calibrated so the longer line ("Every hello comes back.")
    stays inside the front-face safe area (~1100 px wide of the 2700 px
    wrap)."""
    canvas = dark_canvas(MUG_W, MUG_H)
    d = ImageDraw.Draw(canvas)

    # Mug wrap is wide and short. Center both lines on the front face
    # (left third of the wrap is the "front" when the handle's on the
    # right). Use size 110 — fits "Every hello comes back." in ~1050 px.
    face_cx = int(MUG_W * 0.30)

    line1 = "Every pop is a hello."
    line2 = "Every hello comes back."
    line_font = font(110)

    bbox1 = d.textbbox((0, 0), line1, font=line_font)
    line1_w = bbox1[2] - bbox1[0]
    line1_x = face_cx - line1_w // 2
    line1_y = int(MUG_H * 0.20)
    d.text((line1_x + 3, line1_y + 3), line1, font=line_font, fill=(0, 0, 0, 160))
    d.text((line1_x, line1_y), line1, font=line_font, fill=(*CREAM, 255))

    bbox2 = d.textbbox((0, 0), line2, font=line_font)
    line2_w = bbox2[2] - bbox2[0]
    line2_x = face_cx - line2_w // 2
    line2_y = int(MUG_H * 0.46)
    d.text((line2_x + 3, line2_y + 3), line2, font=line_font, fill=(0, 0, 0, 160))
    d.text((line2_x, line2_y), line2, font=line_font, fill=(*PINK, 255))

    # Attribution in script-light below
    attr_font = font(46)
    attr = "— the Squishkeeper"
    bbox3 = d.textbbox((0, 0), attr, font=attr_font)
    attr_w = bbox3[2] - bbox3[0]
    attr_x = face_cx - attr_w // 2
    attr_y = int(MUG_H * 0.74)
    d.text((attr_x, attr_y), attr, font=attr_font, fill=(*WHITE, 220))

    # Sparkle scatter — wraps to the back of the mug for visual interest
    # when the drinker rotates.
    scatter_sparkles(canvas, count=70,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=33, size_range=(4, 14), alpha=200)

    out = OUT_DIR / "mug_pact_wrap.png"
    canvas.save(out, optimize=True)
    print(f"[mug] {out.name} ({canvas.size})")


def build_mug_character(card_num: int, name: str, tagline: str,
                         out_name: str) -> None:
    """Mug wrap with character on left, brand text on right.
    Wraps around so the character and text appear on opposite sides
    when printed."""
    canvas = dark_canvas(MUG_W, MUG_H)

    # Character on the left third
    card = load_card(card_num)
    card = fit_card(card, max_w=int(MUG_W * 0.30), max_h=int(MUG_H * 0.86))
    card_x = int(MUG_W * 0.04)
    card_y = (MUG_H - card.height) // 2
    canvas.alpha_composite(card, (card_x, card_y))

    # Right two-thirds: name + tagline
    d = ImageDraw.Draw(canvas)
    name_font = font(180)
    tag_font = font(74)
    text_x = int(MUG_W * 0.42)
    name_y = int(MUG_H * 0.30)
    tag_y = int(MUG_H * 0.55)
    # name shadow + fill
    d.text((text_x + 4, name_y + 4), name, font=name_font, fill=(0, 0, 0, 160))
    d.text((text_x, name_y), name, font=name_font, fill=(*CREAM, 255))
    d.text((text_x + 3, tag_y + 3), tagline, font=tag_font, fill=(0, 0, 0, 140))
    d.text((text_x, tag_y), tagline, font=tag_font, fill=(*WHITE, 240))

    scatter_sparkles(canvas, count=40,
                      colors=[CREAM, PINK, JELLY_BLUE],
                      seed=card_num + 100,
                      size_range=(4, 12), alpha=180)

    out = OUT_DIR / out_name
    canvas.save(out, optimize=True)
    print(f"[mug] {out.name} ({canvas.size})")


# ---------------------------------------------------------------------------
# Poster — All 48 in a 6x8 grid
# ---------------------------------------------------------------------------

def build_poster_grid() -> None:
    """5400 x 7200 px (18 x 24 in @ 300 DPI). 6 columns x 8 rows = 48
    cards in numerical order (1..48). Title strip at top, brand tag at
    bottom. Dark plum bg with sparkle scatter."""
    W, H = 5400, 7200
    canvas = dark_canvas(W, H)

    # Title block at top
    title_h = 540
    draw_centered_text(canvas, 100, "SQUISHY SMASH",
                       size=320, color=PINK)
    draw_centered_text(canvas, 290, "MEET THE 48 SQUISHIES",
                       size=140, color=CREAM, track_px=14)

    # Footer
    footer_h = 220
    draw_centered_text(canvas, H - 180, "squishysmash.com",
                       size=84, color=WHITE)

    # Card grid
    cols, rows = 6, 8
    grid_top = title_h
    grid_bot = H - footer_h
    pad_x = 60
    pad_y = 30
    grid_w = W - pad_x * 2
    grid_h = grid_bot - grid_top
    cell_w = (grid_w - pad_x * (cols - 1)) // cols
    cell_h = (grid_h - pad_y * (rows - 1)) // rows

    for i, num in enumerate(range(1, 49)):
        col = i % cols
        row = i // cols
        cx_box = pad_x + col * (cell_w + pad_x)
        cy_box = grid_top + row * (cell_h + pad_y)
        card = load_card(num)
        card = fit_card(card, max_w=cell_w, max_h=cell_h)
        cx_card = cx_box + (cell_w - card.width) // 2
        cy_card = cy_box + (cell_h - card.height) // 2
        canvas.alpha_composite(card, (cx_card, cy_card))

    # Sparkle scatter in the negative spaces between cards
    scatter_sparkles(canvas, count=140,
                      colors=[CREAM, PINK, JELLY_BLUE, LAVENDER],
                      seed=4848,
                      size_range=(6, 16), alpha=160)

    out = OUT_DIR / "poster_all_48_grid.png"
    canvas.save(out, optimize=True)
    print(f"[poster] {out.name} ({canvas.size})")


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Bible-canon Pact-line trio (most evergreen pieces in the catalog).
    # Per `book/STORY_BIBLE.md` §2 — typography + sparkle only, no
    # character art, no Squishkeeper depiction.
    build_tee_pact_line()
    build_sticker_pact_line()
    build_mug_pact_wrap()

    # Apparel
    build_tee_wordmark()
    build_tee_card_hero(48, "tee_mythic_familiar.png",
                         tagline="The rarest squish of all.")
    build_tee_card_hero(33, "tee_kids_blushy_bun.png",
                         tagline="Tiny paws. Rosy cheeks.")
    build_tee_card_hero(1,  "tee_kids_soft_dumpling.png",
                         tagline="Soft. Sweet. Squishy.")
    build_tote_trio()

    # Stickers
    build_sticker_sheet("Squishy Foods",
                         list(range(1, 17)),
                         "sticker_sheet_squishy_foods.png",
                         tint=LIME)
    build_sticker_sheet("Goo & Fidgets",
                         list(range(17, 33)),
                         "sticker_sheet_goo_fidgets.png",
                         tint=JELLY_BLUE)
    build_sticker_sheet("Creepy-Cute Creatures",
                         list(range(33, 49)),
                         "sticker_sheet_creepy_cute.png",
                         tint=LAVENDER)
    build_sticker_solo(48, "sticker_solo_mythic_familiar.png", rim_color=CREAM)

    # Drinkware
    build_mug_wordmark()
    build_mug_character(1, "Soft Dumpling", "soft. sweet. squishy.",
                         "mug_soft_dumpling_wrap.png")

    # Wall art
    build_poster_grid()

    print(f"\nAll designs written to {OUT_DIR.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
