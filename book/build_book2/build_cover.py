"""Build the Book 2 cover wrap PDF for KDP submission.

Output: book/build_book2/out/cover_wrap.pdf

Layout (left to right):
  [back cover (8.5") + spine (0.0939") + front cover (8.5")]
  with 0.125" bleed on outer edges + top + bottom.

Total wrap dimensions: 17.3439 × 8.75 in.

Spine: brand-pink band, no text (40 pages is under KDP's ~80-page text
threshold). Same approach as Book 1's spine.

Front cover: the pre-composited cover_front_book2_composite.png (hero art
+ wordmark + volume tag already baked in) is dropped in directly, with
the inner (spine-side) bleed cropped so the image lands cleanly at the
spine boundary.

Back cover: rendered fully as a PIL image at print resolution (300 DPI)
using the same Bookmania/EBG font stack as the interior pages, then
dropped into the PDF as a single image. This avoids ReportLab's lack of
OpenType-CFF support for the Bookmania family. Layout per
cover_copy_book2.md §3.
"""
from __future__ import annotations
import sys
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas as canvas_mod

sys.path.insert(0, str(Path(__file__).parent))
from config import FONTS, DPI

# ---------------------------------------------------------------------------
# Geometry (8.5 × 8.5 in trim, 0.125 in bleed, 40-page spine on premium color)
# ---------------------------------------------------------------------------
INCH = 72.0
TRIM_IN = 8.5
BLEED_IN = 0.125
INTERIOR_PAGES = 40
SPINE_PER_PAGE_COLOR_IN = 0.002347   # premium-color paper
SPINE_W_IN = round(INTERIOR_PAGES * SPINE_PER_PAGE_COLOR_IN, 4)  # 0.0939

TRIM_W = TRIM_IN * INCH
TRIM_H = TRIM_IN * INCH
BLEED = BLEED_IN * INCH
SPINE_W = SPINE_W_IN * INCH

COVER_W_PT = (TRIM_IN + SPINE_W_IN + TRIM_IN + 2 * BLEED_IN) * INCH
COVER_H_PT = (TRIM_IN + 2 * BLEED_IN) * INCH

BACK_X_PT = BLEED
SPINE_X_PT = BLEED + TRIM_W
FRONT_X_PT = SPINE_X_PT + SPINE_W

# Back-cover image dimensions in pixels (matches the back-cover wrap region).
# Back cover region = trim_width + outer bleed (left only, no spine-side bleed)
# = 8.5 + 0.125 = 8.625 in wide × 8.75 in tall (trim + top/bot bleed).
BACK_REGION_W_IN = TRIM_IN + BLEED_IN     # 8.625
BACK_REGION_H_IN = TRIM_IN + 2 * BLEED_IN  # 8.75
BACK_W_PX = int(BACK_REGION_W_IN * DPI)    # 2587 px
BACK_H_PX = int(BACK_REGION_H_IN * DPI)    # 2625 px

# Within the back-cover image, x=0 is the outer edge of the bleed, so the
# trim begins at x=BLEED_PX. The right edge of the trim sits at x=BLEED_PX
# + TRIM_W_PX (= the spine boundary, no bleed on that side).
BLEED_PX = int(BLEED_IN * DPI)             # 37
TRIM_W_PX = int(TRIM_IN * DPI)             # 2550
SAFE_INSET_IN = 0.375
SAFE_INSET_PX = int(SAFE_INSET_IN * DPI)   # 112

# ---------------------------------------------------------------------------
# Palette (Knight-Owl-dusk per cover_copy_book2.md §2 + §3)
# ---------------------------------------------------------------------------
SKY_TOP = "#1B2440"          # deep teal-indigo (back cover background)
VOLUME_GOLD = "#E4C46C"      # volume tag + back headline + series footer
WORDMARK_CREAM = "#F5E9D0"   # body blurb on dark sky
SPINE_PINK = "#FF8FB8"       # spine band (matches Book 1 for shelf consistency)
METADATA_SUBDUED = "#5A4A6E" # far-bottom row


def hex_to_rgb(h: str):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


# ---------------------------------------------------------------------------
# Assets
# ---------------------------------------------------------------------------
COVER_DIR = Path(__file__).parent.parent / "cover"
FRONT_COMPOSITE = COVER_DIR / "cover_front_book2_composite.png"
BACK_VIGNETTE = COVER_DIR / "book2_back_vignette_LOCKED_print.png"

OUT_PDF = Path(__file__).parent / "out" / "cover_wrap.pdf"


# ---------------------------------------------------------------------------
# Back-cover image renderer (PIL, 300 DPI)
# ---------------------------------------------------------------------------
def _wrap_lines(text: str, font: ImageFont.FreeTypeFont,
                  max_w_px: int, draw: ImageDraw.Draw) -> list[str]:
    """Wrap text to fit within max_w_px. Returns list of lines."""
    words = text.split()
    lines: list[str] = []
    cur: list[str] = []
    for w in words:
        trial = " ".join(cur + [w])
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] > max_w_px and cur:
            lines.append(" ".join(cur))
            cur = [w]
        else:
            cur.append(w)
    if cur:
        lines.append(" ".join(cur))
    return lines


def _draw_centered_block(canvas, lines, font, color, y_top, line_gap_px=0):
    draw = ImageDraw.Draw(canvas)
    y = y_top
    last_h = 0
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        x = (canvas.width - tw) // 2
        draw.text((x, y), line, font=font, fill=color)
        y += th + line_gap_px
        last_h = th
    return y


def render_back_cover() -> Image.Image:
    """Render the back cover as a single PIL image (BACK_W_PX × BACK_H_PX)."""
    canvas = Image.new("RGB", (BACK_W_PX, BACK_H_PX), hex_to_rgb(SKY_TOP))

    # ---- Vignette (upper third, centered, ~2.5 × 2.5 in) ----
    vig_size_in = 2.5
    vig_size_px = int(vig_size_in * DPI)
    vig = Image.open(BACK_VIGNETTE).convert("RGB")
    vig = vig.resize((vig_size_px, vig_size_px), Image.LANCZOS)
    vig_x = (BACK_W_PX - vig_size_px) // 2
    vig_y = BLEED_PX + SAFE_INSET_PX
    canvas.paste(vig, (vig_x, vig_y))

    # ---- Headline (EB Garamond Italic, ~22pt, volume gold, centered) ----
    headline_font = ImageFont.truetype(
        str(FONTS["ebg_italic"]), int(22 * DPI / 72)
    )
    headline = "A sparkle goes missing. Three new friends go looking."
    draw = ImageDraw.Draw(canvas)
    # Wrap to ~5.5 in column
    headline_max_w = int(5.5 * DPI)
    headline_lines = _wrap_lines(headline, headline_font, headline_max_w, draw)
    head_y = vig_y + vig_size_px + int(0.30 * DPI)
    head_y = _draw_centered_block(
        canvas, headline_lines, headline_font,
        hex_to_rgb(VOLUME_GOLD), head_y,
        line_gap_px=int(0.05 * DPI),
    )

    # ---- Body blurb (Bookmania Regular 11/15pt, cream, centered, max ~4.2 in) ----
    body_font = ImageFont.truetype(
        str(FONTS["body"]), int(11 * DPI / 72)
    )
    italic_font = ImageFont.truetype(
        str(FONTS["body_italic"]), int(11 * DPI / 72)
    )
    body_max_w = int(4.2 * DPI)
    blurb_main = (
        "When the last Sparkle of the Squishy World flickers and "
        "splits into three, Soft Dumpling sets out into the warm dark "
        "to find the missing light. Along the way she meets a curious "
        "Goo Ball and a Blushy Bun Bunny — and discovers that some "
        "sparkles are only found when three first feelings remember "
        "each other."
    )
    body_y = head_y + int(0.18 * DPI)
    body_lines = _wrap_lines(blurb_main, body_font, body_max_w, draw)
    body_y = _draw_centered_block(
        canvas, body_lines, body_font, hex_to_rgb(WORDMARK_CREAM),
        body_y, line_gap_px=int(15 * DPI / 72) - int(11 * DPI / 72),
    )

    # Pact line (italic, same size, cream)
    pact = "Every pop is a hello. Every hello comes back."
    pact_y = body_y + int(0.16 * DPI)
    pact_lines = _wrap_lines(pact, italic_font, body_max_w, draw)
    _draw_centered_block(
        canvas, pact_lines, italic_font, hex_to_rgb(WORDMARK_CREAM),
        pact_y, line_gap_px=int(0.04 * DPI),
    )

    # ---- Series footer (Bookmania Black 8pt, gold, lower-LEFT) ----
    footer_font = ImageFont.truetype(
        str(FONTS["display"]), int(8 * DPI / 72)
    )
    footer_text = "SQUISHY SMASH · BOOK TWO"
    footer_y = BACK_H_PX - BLEED_PX - SAFE_INSET_PX - int(0.40 * DPI)
    footer_x = BLEED_PX + SAFE_INSET_PX
    draw.text((footer_x, footer_y), footer_text,
                font=footer_font, fill=hex_to_rgb(VOLUME_GOLD))

    # ---- Far-bottom metadata (centered above bottom trim) ----
    meta_font = ImageFont.truetype(
        str(FONTS["body"]), int(7 * DPI / 72)
    )
    meta_text = "Ages 4–8  ·  squishysmash.com  ·  © 2026 Christopher Ryan Campbell"
    meta_y = BACK_H_PX - BLEED_PX - SAFE_INSET_PX - int(0.12 * DPI)
    bbox = draw.textbbox((0, 0), meta_text, font=meta_font)
    mw = bbox[2] - bbox[0]
    meta_x = (BACK_W_PX - mw) // 2
    draw.text((meta_x, meta_y), meta_text,
                font=meta_font, fill=hex_to_rgb(METADATA_SUBDUED))

    return canvas


# ---------------------------------------------------------------------------
# PDF assembly
# ---------------------------------------------------------------------------
def _pil_to_imagereader(img: Image.Image) -> ImageReader:
    buf = BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return ImageReader(buf)


def build(out_path: Path = OUT_PDF) -> Path:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    c = canvas_mod.Canvas(str(out_path), pagesize=(COVER_W_PT, COVER_H_PT))
    c.setTitle("Squishy Smash: The Lost Sparkle — Cover Wrap")
    c.setAuthor("Christopher Ryan Campbell")
    c.setSubject("Book 2 paperback cover wrap PDF for KDP")
    c.setCreator("Squishy Smash cover build pipeline (Book 2)")

    # Full-bleed deep-indigo background
    c.setFillColor(HexColor(SKY_TOP))
    c.rect(0, 0, COVER_W_PT, COVER_H_PT, fill=1, stroke=0)

    # Back cover: render PIL image and drop it in
    back_img = render_back_cover()
    back_pt_w = (BACK_REGION_W_IN) * INCH
    c.drawImage(_pil_to_imagereader(back_img), 0, 0,
                  width=back_pt_w, height=COVER_H_PT,
                  preserveAspectRatio=False, mask="auto")

    # Spine band
    c.setFillColor(HexColor(SPINE_PINK))
    c.rect(SPINE_X_PT, 0, SPINE_W, COVER_H_PT, fill=1, stroke=0)

    # Front cover: pre-composited image (4096×4096 = 8.75×8.75 in incl. bleed)
    # Crop the LEFT bleed so the image lands at the spine boundary without
    # distortion (no spine-side bleed on the front cover wrap region).
    front_img = Image.open(FRONT_COMPOSITE).convert("RGB")
    left_bleed_px = round(
        BLEED_IN / (TRIM_IN + 2 * BLEED_IN) * front_img.width
    )
    front_img = front_img.crop(
        (left_bleed_px, 0, front_img.width, front_img.height)
    )
    front_w_pt = COVER_W_PT - FRONT_X_PT
    c.drawImage(_pil_to_imagereader(front_img), FRONT_X_PT, 0,
                  width=front_w_pt, height=COVER_H_PT,
                  preserveAspectRatio=False, mask="auto")

    c.showPage()
    c.save()
    return out_path


if __name__ == "__main__":
    pdf = build()
    size_mb = pdf.stat().st_size / 1024 / 1024
    print(f"Wrote {pdf}")
    print(f"  Wrap: {COVER_W_PT / 72:.4f} × {COVER_H_PT / 72:.4f} in")
    print(f"  Spine: {SPINE_W_IN:.4f} in ({INTERIOR_PAGES} pages)")
    print(f"  Size: {size_mb:.1f} MB")
