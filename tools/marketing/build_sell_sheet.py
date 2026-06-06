"""Build a bookstore consignment sell sheet for Book 2 ("The Lost Sparkle").

One-page US Letter PDF intended for:
  - dropping on bookstore manager's desk during a 3-min pitch
  - tucking inside each of the 15 incoming author copies before they ship out
  - mailing with press kits

Output: docs/marketing/sell_sheet_book2.pdf
"""

from pathlib import Path
import qrcode
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor, black, white
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from PIL import Image as PILImage

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "docs" / "marketing"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT = OUT_DIR / "sell_sheet_book2.pdf"

# Brand colors echoing the cover wash
CREAM = HexColor("#FFF6E7")
DUSK_PURPLE = HexColor("#3B2A4D")
WARM_GOLD = HexColor("#E2A85F")
SOFT_RED = HexColor("#D26A6A")

# Asset paths
COVER_FRONT = REPO / "book" / "cover" / "book2_cover_hero_LOCKED.png"
BYLINE = REPO / "book" / "cover" / "byline_book2.png"

# Try Fredoka first (in repo), fall back to Helvetica
def reg_font(name, path):
    try:
        pdfmetrics.registerFont(TTFont(name, str(path)))
        return name
    except Exception:
        return None

FREDOKA = reg_font("Fredoka", REPO / "assets" / "google_fonts" / "Fredoka.ttf")
GARAMOND = reg_font("Garamond", REPO / "assets" / "google_fonts" / "EBGaramond-Regular.ttf")

DISPLAY = FREDOKA or "Helvetica-Bold"
BODY = GARAMOND or "Helvetica"

# ---------- helpers ----------
def make_qr(url: str, box_size: int = 10) -> PILImage.Image:
    qr = qrcode.QRCode(version=None, error_correction=qrcode.constants.ERROR_CORRECT_M,
                       box_size=box_size, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    return qr.make_image(fill_color="black", back_color="white").convert("RGB")

def draw_pil_image(c, pil_img, x, y, w, h):
    """Draw a PIL image into the reportlab canvas via in-memory PNG."""
    buf = BytesIO()
    pil_img.save(buf, "PNG")
    buf.seek(0)
    from reportlab.lib.utils import ImageReader
    c.drawImage(ImageReader(buf), x, y, width=w, height=h, preserveAspectRatio=True, mask='auto')

# ---------- layout ----------
def build():
    W, H = LETTER
    c = canvas.Canvas(str(OUT), pagesize=LETTER)

    # Background cream
    c.setFillColor(CREAM)
    c.rect(0, 0, W, H, fill=1, stroke=0)

    # ---- top band: dusk purple with brand wordmark ----
    BAND_H = 1.2 * inch
    c.setFillColor(DUSK_PURPLE)
    c.rect(0, H - BAND_H, W, BAND_H, fill=1, stroke=0)

    # Wordmark
    c.setFillColor(CREAM)
    c.setFont(DISPLAY, 30)
    c.drawString(0.5 * inch, H - 0.55 * inch, "SQUISHY SMASH")
    c.setFont(BODY, 12)
    c.setFillColor(WARM_GOLD)
    c.drawString(0.5 * inch, H - 0.85 * inch, "An indie children's picture book series + mobile game")
    c.setFillColor(CREAM)
    c.setFont(BODY, 10)
    c.drawString(0.5 * inch, H - 1.05 * inch, "Athlete Domains, LLC  -  Spartanburg, SC  -  squishysmash.com")

    # ---- cover thumbnail (left column) ----
    cover_w = 2.4 * inch
    cover_h = 3.0 * inch
    cover_x = 0.5 * inch
    cover_y = H - BAND_H - 0.3 * inch - cover_h
    if COVER_FRONT.exists():
        cover_img = PILImage.open(COVER_FRONT).convert("RGB")
        draw_pil_image(c, cover_img, cover_x, cover_y, cover_w, cover_h)
        # subtle border
        c.setStrokeColor(DUSK_PURPLE)
        c.setLineWidth(0.5)
        c.rect(cover_x, cover_y, cover_w, cover_h, fill=0, stroke=1)

    # ---- title block (right of cover) ----
    title_x = cover_x + cover_w + 0.35 * inch
    title_y = H - BAND_H - 0.5 * inch
    c.setFillColor(DUSK_PURPLE)
    c.setFont(DISPLAY, 22)
    c.drawString(title_x, title_y, "The Lost Sparkle")
    c.setFont(BODY, 11)
    c.setFillColor(black)
    c.drawString(title_x, title_y - 0.25 * inch, "Book 2 in the Squishy Smash series")
    c.drawString(title_x, title_y - 0.45 * inch, "by Christopher Ryan Campbell")

    # Metadata table
    md_y = title_y - 0.85 * inch
    c.setFont(BODY, 10)
    rows = [
        ("Format", "Paperback - 40 pages - 8.5 x 8.5 in"),
        ("Reading age", "4 - 8 years"),
        ("ASIN", "B0H3QP7ZPH"),
        ("Amazon URL", "amazon.com/dp/B0H3QP7ZPH"),
        ("Published", "June 2, 2026"),
        ("Imprint", "Athlete Domains, LLC"),
        ("Companion book", "Meet the Squishies (B0H219KX2X)"),
        ("Companion game", "Squishy Smash (iOS App Store)"),
    ]
    for label, value in rows:
        c.setFillColor(DUSK_PURPLE)
        c.drawString(title_x, md_y, label + ":")
        c.setFillColor(black)
        c.drawString(title_x + 1.2 * inch, md_y, value)
        md_y -= 0.2 * inch

    # ---- pitch block (below cover, full width) ----
    pitch_y = cover_y - 0.4 * inch
    c.setFillColor(DUSK_PURPLE)
    c.setFont(DISPLAY, 14)
    c.drawString(0.5 * inch, pitch_y, "What it is")
    c.setFillColor(black)
    c.setFont(BODY, 10.5)
    pitch_lines = [
        "Three small worlds. One Sparkle. When it splits into three shards, Soft Dumpling,",
        "Goo Ball, and Blushy Bun Bunny leave home for the first time to find the pieces.",
        "What they find on the way is each other. A gentle, read-aloud bedtime picture book",
        "for ages 4-8 about brave kindness, friendship across difference, and being found.",
    ]
    py = pitch_y - 0.22 * inch
    for line in pitch_lines:
        c.drawString(0.5 * inch, py, line)
        py -= 0.18 * inch

    # ---- "Why it's selling" block ----
    py -= 0.15 * inch
    c.setFillColor(DUSK_PURPLE)
    c.setFont(DISPLAY, 14)
    c.drawString(0.5 * inch, py, "Why now")
    py -= 0.22 * inch
    c.setFillColor(black)
    c.setFont(BODY, 10.5)
    why_lines = [
        "- Original-IP squishy storybook - the lane the licensed brands (Squishmallows,",
        "  Pop Mart) haven't filled. First-mover during the active squishy craze.",
        "- Production story: $11 per book AI-pipeline vs $3K-20K traditional baseline.",
        "  Local press angle that travels - Spartanburg dad, three girls, solo build.",
        "- Cross-product ecosystem: Book 1 (Meet the Squishies) + Book 2 + mobile game.",
        "  Multiple price points, repeat-purchase ladder, lifelong-customer mechanics.",
    ]
    for line in why_lines:
        c.drawString(0.5 * inch, py, line)
        py -= 0.18 * inch

    # ---- read-along QR block (bottom-left) ----
    # Pushed up to 1.95in (was 1.4in) so QR + terms list both clear the
    # 0.5in contact footer band with margin. QR shrunk 1.0->0.85in for clearance.
    qr_block_y = 1.95 * inch
    qr_size = 0.85 * inch
    readalong_url = "https://youtu.be/_0_s3P6uN-o"
    qr_img = make_qr(readalong_url, box_size=8)
    draw_pil_image(c, qr_img, 0.5 * inch, qr_block_y - qr_size, qr_size, qr_size)
    c.setFillColor(DUSK_PURPLE)
    c.setFont(DISPLAY, 11)
    c.drawString(1.45 * inch, qr_block_y - 0.22 * inch, "Free 5:37 read-along on YouTube")
    c.setFont(BODY, 9.5)
    c.setFillColor(black)
    c.drawString(1.45 * inch, qr_block_y - 0.40 * inch, "Professional voiceover + music + SFX.")
    c.drawString(1.45 * inch, qr_block_y - 0.55 * inch, "Library + classroom ready. No author needed.")
    c.drawString(1.45 * inch, qr_block_y - 0.70 * inch, "youtu.be/_0_s3P6uN-o")

    # ---- consignment terms block (bottom-right) ----
    terms_x = W - 3.3 * inch
    c.setFillColor(DUSK_PURPLE)
    c.setFont(DISPLAY, 11)
    c.drawString(terms_x, qr_block_y - 0.22 * inch, "Consignment terms")
    c.setFont(BODY, 9.5)
    c.setFillColor(black)
    terms_lines = [
        "- 60/40 split (author favor)",
        "- 5-10 copies typical drop",
        "- 6-month review window",
        "- Payment monthly or quarterly",
        "- Author handles restock",
    ]
    ty = qr_block_y - 0.40 * inch
    for line in terms_lines:
        c.drawString(terms_x, ty, line)
        ty -= 0.16 * inch

    # ---- contact footer ----
    c.setFillColor(DUSK_PURPLE)
    c.rect(0, 0, W, 0.5 * inch, fill=1, stroke=0)
    c.setFillColor(CREAM)
    c.setFont(DISPLAY, 11)
    c.drawString(0.5 * inch, 0.18 * inch, "Christopher Ryan Campbell  -  chriscam8@gmail.com  -  squishysmash.com  -  Athlete Domains, LLC")

    c.showPage()
    c.save()
    print(f"Built: {OUT} ({OUT.stat().st_size // 1024} KB)")

if __name__ == "__main__":
    build()
