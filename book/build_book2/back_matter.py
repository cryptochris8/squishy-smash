"""Render p40 — back matter (verso).

Two stacked blocks: "Have You Met All Forty-Eight?" Book 1 callback at top,
gold divider, "About the Author" bio (with round photo + expanded copy) at
bottom.
"""
from __future__ import annotations
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont, ImageFilter

sys.path.insert(0, str(Path(__file__).parent))
from config import (
    PAGE_W_PX, PAGE_H_PX, FONTS, PALETTE, PT,
    BLEED_PX, SAFE_INSET_PX,
)
from spread_overlay import hex_to_rgba, draw_runs_in_box, load_fonts
from front_matter import _new_cream_page, _centered_text


# ---------------------------------------------------------------------------
# Copy
# ---------------------------------------------------------------------------
CALLBACK_HEADER = "HAVE YOU MET ALL FORTY-EIGHT?"
CALLBACK_BODY = (
    "Squishy Smash: Meet the Squishies is the companion field guide — "
    "forty-eight soft-shaped friends across three magical packs, each with "
    "their own signature squish and a story all their own. The Squishkeeper "
    "has been waiting to introduce you."
)
CALLBACK_LINK = "amazon.com/dp/B0H219KX2X"
CALLBACK_AVAILABILITY = "Available wherever books are sold."

BIO_HEADER = "ABOUT THE AUTHOR"
BIO_PARAS = [
    ("Christopher Ryan Campbell is the creator of Squishy Smash, a "
     "soft-shaped universe of plush characters, magical packs, and gentle "
     "adventures. He builds the world across iOS, picture books, and short "
     "illustrated tales for readers who like their adventures soft."),
    ("He lives in Spartanburg, South Carolina, with his partner and three "
     "daughters."),
    ("He is also the author of The Red Brick Road, a fantasy reimagining of "
     "the Land of Oz for older readers."),
]
BIO_LINK = "Find Squishy Smash at squishysmash.com or @CryptoChris8 on TikTok."

AUTHOR_PHOTO_PATH = Path(__file__).parent.parent / "assets" / "author_photo.jpg"
PHOTO_DIAMETER_IN = 1.5
PHOTO_DIAMETER_PX = int(PHOTO_DIAMETER_IN * 300)
# Cream paper color the photo fades into at the edges (matches PALETTE["paper"])
PHOTO_FADE_RGB = (245, 233, 208)
# Warm tint blend amount (0.0 = original photo, 1.0 = full warm overlay)
PHOTO_WARM_BLEND = 0.12


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _draw_wrapped_centered(canvas, text, font, color_hex, y_top, max_w,
                            leading_px):
    """Draw centered wrapped text. Returns bottom y."""
    d = ImageDraw.Draw(canvas)
    color = hex_to_rgba(color_hex)
    words = text.split()
    lines = []
    line = ""
    for w in words:
        test = (line + " " + w).strip()
        if font.getbbox(test)[2] - font.getbbox(test)[0] <= max_w:
            line = test
        else:
            lines.append(line)
            line = w
    if line:
        lines.append(line)
    y = y_top
    for ln in lines:
        bbox = font.getbbox(ln)
        w = bbox[2] - bbox[0]
        x = (canvas.width - w) // 2
        d.text((x, y), ln, font=font, fill=color)
        y += leading_px
    return y


def _round_photo(path: Path, diameter_px: int) -> Image.Image:
    """Round-crop a JPG with a warm tint + cream radial vignette that fades
    the dark background out toward the circle edges.

    Returns an RGBA image sized (diameter_px, diameter_px).
    """
    img = Image.open(path).convert("RGB")
    w, h = img.size
    # Center-square crop, biased slightly upward so the face sits a bit
    # higher in the frame (faces are usually upper portion of a portrait).
    side = min(w, h)
    left = (w - side) // 2
    top = max(0, (h - side) // 2 - int(side * 0.05))
    img = img.crop((left, top, left + side, top + side))
    img = img.resize((diameter_px, diameter_px), Image.LANCZOS)

    # 1) Warm tint — blend slightly toward the cream paper color so the
    # photo bridges palette-wise to the cream page.
    warm = Image.new("RGB", img.size, PHOTO_FADE_RGB)
    img = Image.blend(img, warm, PHOTO_WARM_BLEND)

    # 2) Radial cream vignette — keep face/center sharp, fade dark
    # background and suit-edges out into cream as we move toward the edge.
    cream_layer = Image.new("RGB", img.size, PHOTO_FADE_RGB)
    # Inner-ellipse alpha (255 = keep photo, 0 = full cream). The smaller
    # the inner ellipse + the larger the blur, the more aggressive the fade.
    inner = Image.new("L", img.size, 0)
    pad = int(diameter_px * 0.18)
    ImageDraw.Draw(inner).ellipse(
        (pad, pad, diameter_px - pad, diameter_px - pad), fill=255
    )
    inner = inner.filter(ImageFilter.GaussianBlur(radius=diameter_px * 0.16))
    img = Image.composite(img, cream_layer, inner)

    # 3) Final circular alpha clip (so the photo is round on the page).
    final_mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(final_mask).ellipse(
        (0, 0, diameter_px, diameter_px), fill=255
    )
    img = img.convert("RGBA")
    img.putalpha(final_mask)
    return img


# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------
def render_back_matter_page() -> Image.Image:
    page = _new_cream_page()
    max_w = int(PAGE_W_PX * 0.56)  # ~4.9 in

    header_font = ImageFont.truetype(str(FONTS["ebg_regular"]), int(20 * PT))
    body_font = ImageFont.truetype(str(FONTS["body"]), int(13 * PT))
    bio_body_font = ImageFont.truetype(str(FONTS["body"]), int(11 * PT))
    bio_italic_font = ImageFont.truetype(str(FONTS["body_italic"]), int(11 * PT))
    link_font = ImageFont.truetype(str(FONTS["body_italic"]), int(11 * PT))
    body_leading = int(17 * PT)
    bio_leading = int(15 * PT)

    # ---- Block 1: Book 1 callback (upper half) ----
    y = int(PAGE_H_PX * 0.11)
    _centered_text(page, CALLBACK_HEADER, header_font,
                     PALETTE["gold"], y, tracking_em=0.10)
    y += int(header_font.size * 1.4) + int(8 * PT)

    y = _draw_wrapped_centered(page, CALLBACK_BODY, body_font,
                                PALETTE["ink"], y, max_w, body_leading)
    y += int(8 * PT)
    y = _draw_wrapped_centered(page, CALLBACK_AVAILABILITY, body_font,
                                PALETTE["ink"], y, max_w, body_leading)
    y += int(2 * PT)
    _draw_wrapped_centered(page, CALLBACK_LINK, link_font,
                            PALETTE["ink"], y, max_w, body_leading)

    # ---- Gold divider (moved up to 0.44 to fit larger photo + expanded bio) ----
    divider_y = int(PAGE_H_PX * 0.44)
    divider_w = int(PAGE_W_PX * 0.30)
    divider_thickness = 3
    d = ImageDraw.Draw(page)
    gold_rgba = hex_to_rgba(PALETTE["gold"], int(0.60 * 255))
    d.rectangle(((PAGE_W_PX - divider_w) // 2, divider_y,
                  (PAGE_W_PX + divider_w) // 2, divider_y + divider_thickness),
                  fill=gold_rgba)

    # ---- Block 2: About the Author (lower half) ----
    y = divider_y + int(20 * PT)
    _centered_text(page, BIO_HEADER, header_font,
                     PALETTE["gold"], y, tracking_em=0.10)
    y += int(header_font.size * 1.3) + int(8 * PT)

    # Author photo (round, centered)
    if AUTHOR_PHOTO_PATH.exists():
        photo = _round_photo(AUTHOR_PHOTO_PATH, PHOTO_DIAMETER_PX)
        photo_x = (PAGE_W_PX - PHOTO_DIAMETER_PX) // 2
        page.alpha_composite(photo, dest=(photo_x, y))
        y += PHOTO_DIAMETER_PX + int(10 * PT)

    # Bio paragraphs (tightened inter-paragraph gap to fit closing line)
    for i, para in enumerate(BIO_PARAS):
        font = bio_italic_font if i == 2 else bio_body_font  # 'also by' uses italic
        y = _draw_wrapped_centered(page, para, font,
                                    PALETTE["ink"], y, max_w, bio_leading)
        y += int(4 * PT)

    # Closing italic link line
    y += int(2 * PT)
    _draw_wrapped_centered(page, BIO_LINK, link_font,
                            PALETTE["ink"], y, max_w, bio_leading)

    return page


if __name__ == "__main__":
    out_dir = Path(__file__).parent / "out" / "preview"
    out_dir.mkdir(parents=True, exist_ok=True)
    img = render_back_matter_page()
    out_path = out_dir / "matter_p40.png"
    img.save(out_path)
    print(f"saved -> {out_path.name}")
