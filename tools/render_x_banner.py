"""
Render an X / Twitter header banner for @squishy_smash.

Output: 1500 x 500 PNG composed of:
  - Brand gradient backdrop (deep purple-black with pink + lavender
    radial glows mirroring the marketing site's aesthetic)
  - "SQUISHY SMASH" wordmark in Fredoka, left third
  - Tagline under the wordmark
  - A scattered cluster of card WebPs on the right two-thirds — chosen
    to show off the launch pack's hero-tier art across all 3 packs

Re-run any time the cluster needs refreshing or the wordmark changes:

    python tools/render_x_banner.py

Output lands at branding/x_banner.png (also mirrored into
website/public/branding/ so the marketing site can reference it
later if desired).
"""

from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
CARDS_DIR = REPO_ROOT / "assets" / "cards" / "final_48"
FONT_PATH = REPO_ROOT / "assets" / "google_fonts" / "Fredoka.ttf"
OUT_DIRS = [
    REPO_ROOT / "branding",
    REPO_ROOT / "website" / "public" / "branding",
]
OUT_NAME = "x_banner.png"

# X banner spec.
W, H = 1500, 500

# Brand palette — same hex values as Palette.rarityColor + the SPA's
# CSS variables. Keep these in sync if the brand colors ever shift.
BG_DEEP = (18, 11, 23)       # #120B17
PINK = (255, 143, 184)       # #FF8FB8
CREAM = (255, 211, 110)      # #FFD36E
LAVENDER = (201, 139, 255)   # #C98BFF
WHITE = (245, 240, 250)


def make_background() -> Image.Image:
    """Deep purple base + two radial glows (pink top-left, lavender
    bottom-right) to mirror the marketing-site backdrop."""
    bg = Image.new("RGB", (W, H), BG_DEEP)

    def add_glow(center: tuple[int, int], color: tuple[int, int, int],
                 radius: int, opacity: int) -> None:
        # Build the glow on a small canvas, blur it, paste with alpha.
        glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(glow)
        cx, cy = center
        d.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            fill=(*color, opacity),
        )
        glow = glow.filter(ImageFilter.GaussianBlur(radius=radius // 4))
        bg.paste(Image.alpha_composite(bg.convert("RGBA"), glow).convert("RGB"))

    add_glow((150, 80), PINK, 380, 110)
    add_glow((W - 200, H - 80), LAVENDER, 420, 100)
    add_glow((W // 2, H // 2 + 80), CREAM, 260, 50)
    return bg


def paste_card(canvas: Image.Image, card_path: Path, *,
               cx: int, cy: int, height: int, angle: float,
               glow_color: tuple[int, int, int]) -> None:
    """Place a card centered at (cx, cy), height in px, rotated by
    `angle` degrees, with a soft underglow in `glow_color`. Keeps the
    card's 3:4 aspect ratio."""
    src = Image.open(card_path).convert("RGBA")
    aspect = src.width / src.height
    target_h = height
    target_w = int(target_h * aspect)
    src = src.resize((target_w, target_h), Image.LANCZOS)

    # Soft glow behind the card.
    glow_pad = 30
    glow_canvas = Image.new(
        "RGBA",
        (src.width + glow_pad * 2, src.height + glow_pad * 2),
        (0, 0, 0, 0),
    )
    g = ImageDraw.Draw(glow_canvas)
    g.rounded_rectangle(
        (
            glow_pad - 4,
            glow_pad - 4,
            src.width + glow_pad + 4,
            src.height + glow_pad + 4,
        ),
        radius=20,
        fill=(*glow_color, 130),
    )
    glow_canvas = glow_canvas.filter(ImageFilter.GaussianBlur(radius=18))

    # Round the card corners — match the in-app album look.
    rounded = Image.new("RGBA", (src.width, src.height), (0, 0, 0, 0))
    mask = Image.new("L", (src.width, src.height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, src.width, src.height), radius=18, fill=255
    )
    rounded.paste(src, (0, 0), mask)

    # Composite glow + card onto a tile, then rotate together.
    tile = Image.new(
        "RGBA",
        (src.width + glow_pad * 2, src.height + glow_pad * 2),
        (0, 0, 0, 0),
    )
    tile.alpha_composite(glow_canvas)
    tile.alpha_composite(rounded, (glow_pad, glow_pad))
    tile = tile.rotate(angle, resample=Image.BICUBIC, expand=True)

    # Paste centered at (cx, cy).
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(
        tile,
        (cx - tile.width // 2, cy - tile.height // 2),
    )
    # Mutate `canvas` in place by copying the result back.
    canvas.paste(canvas_rgba.convert("RGB"), (0, 0))


def draw_wordmark(canvas: Image.Image) -> None:
    """SQUISHY SMASH in Fredoka, stacked two lines, with a tagline
    underneath. Drop-shadow for legibility against busy backgrounds."""
    # PIL's variable-font weight axis support is patchy; use the
    # default weight from the file (which renders as ~500 medium).
    font_lg = ImageFont.truetype(str(FONT_PATH), 80)
    font_tagline = ImageFont.truetype(str(FONT_PATH), 22)

    # Wordmark canvas (with shadow) — render on a transparent layer
    # so we can blur a copy for the shadow without smearing the text.
    text_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(text_layer)

    # "SQUISHY" line 1, "SMASH" line 2 — stacked, left-aligned with
    # the cards starting around x=550 so nothing collides.
    x_text = 60
    y_text = 130
    d.text((x_text, y_text), "SQUISHY", font=font_lg, fill=(*WHITE, 255))
    d.text((x_text, y_text + 90), "SMASH", font=font_lg, fill=(*PINK, 255))

    # Tagline.
    d.text(
        (x_text + 4, y_text + 200),
        "tap · squish · pop · collect 48 cards",
        font=font_tagline,
        fill=(*WHITE, 200),
    )

    # Drop shadow — duplicate text layer, offset, blur.
    shadow = text_layer.copy()
    shadow_data = shadow.split()[3]  # alpha
    shadow_solid = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    shadow_solid.putalpha(shadow_data)
    shadow_solid = shadow_solid.filter(ImageFilter.GaussianBlur(radius=8))
    # Tint the shadow black at low opacity.
    shadow_black = Image.new("RGBA", shadow.size, (0, 0, 0, 160))
    shadow_black.putalpha(shadow_solid.split()[3])

    composed = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    composed.paste(shadow_black, (4, 4), shadow_black)
    composed.alpha_composite(text_layer)

    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(composed)
    canvas.paste(canvas_rgba.convert("RGB"), (0, 0))


def main() -> None:
    assert CARDS_DIR.exists(), f"Missing {CARDS_DIR}"
    assert FONT_PATH.exists(), f"Missing {FONT_PATH}"

    canvas = make_background()

    # Card cluster — variety across packs + rarities. Smaller cards
    # back, larger cards front; slight rotations so the cluster feels
    # tossed rather than stacked. Coordinates picked by eye for a
    # 1500x500 frame with the wordmark on the left third.
    cluster = [
        # (cardfile, cx, cy, height, angle, glow_color)
        ("014_Crystal_Mochi.webp",         700, 250, 280, -8,  PINK),
        ("032_Singularity_Goo_Core.webp",  920, 290, 320,  6,  LAVENDER),
        ("016_Celestial_Dumpling_Core.webp", 1140, 240, 360, -4, CREAM),
        ("048_Mythic_Plush_Familiar.webp", 1340, 290, 280,  10, LAVENDER),
        ("045_Dream_Eater_Squish.webp",    830, 380, 200, -14, PINK),
        ("012_Golden_Syrup_Cube.webp",    1240, 410, 180,  18, CREAM),
    ]
    for fname, cx, cy, h, ang, glow in cluster:
        paste_card(canvas, CARDS_DIR / fname, cx=cx, cy=cy,
                   height=h, angle=ang, glow_color=glow)

    draw_wordmark(canvas)

    # Save to all output dirs.
    for d in OUT_DIRS:
        d.mkdir(parents=True, exist_ok=True)
        out = d / OUT_NAME
        canvas.save(out, "PNG", optimize=True)
        size_kb = out.stat().st_size / 1024
        print(f"  wrote {out.relative_to(REPO_ROOT)} ({size_kb:.0f} KB)")


if __name__ == "__main__":
    main()
