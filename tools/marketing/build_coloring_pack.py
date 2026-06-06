"""Build the free Squishy Smash coloring pack PDF.

Two-stage pipeline:
  1. For each of 8 selected characters, send the card art to Nano Banana Pro
     and ask for a clean black line-art coloring page.
  2. Assemble the 8 line-art images into a US Letter PDF with a cover,
     character pages, and a back page.

Outputs:
  assets/coloring_pack/lineart/<NNN>_<name>_lineart.png  (one per character)
  docs/marketing/squishy_smash_coloring_pack.pdf         (the printable)

Cost: 8 × $0.13 = ~$1.04 NBP generation.
Wall: ~3-5 min for NBP + ~10 sec for PDF.
"""

import os
from pathlib import Path
from io import BytesIO

import httpx
_o = httpx.Client.__init__
_oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
import warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

import PIL.Image
from google import genai
from google.genai import types

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor, black, white
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader

REPO = Path(__file__).resolve().parents[2]
CARDS = REPO / "assets" / "cards" / "final_48"
LINEART_DIR = REPO / "assets" / "coloring_pack" / "lineart"
LINEART_DIR.mkdir(parents=True, exist_ok=True)
PDF_OUT = REPO / "docs" / "marketing" / "squishy_smash_coloring_pack.pdf"
PDF_OUT.parent.mkdir(parents=True, exist_ok=True)

KEY = (Path(r"C:\Users\chris") / "gemini.key.txt").read_text(encoding="utf-8").strip()
client = genai.Client(api_key=KEY)

# 8 characters — 3 protagonists + 3 Legendaries (one per pack) + 2 fan favorites
CHARACTERS = [
    ("001_Soft_Dumpling",           "Soft Dumpling",           "Squishy Foods"),
    ("017_Goo_Ball",                "Goo Ball",                "Goo & Fidgets"),
    ("033_Blushy_Bun_Bunny",        "Blushy Bun Bunny",        "Creepy-Cute Creatures"),
    ("011_Sparkle_Mochi",           "Sparkle Mochi",           "Squishy Foods"),
    ("036_Wobble_Kitty",            "Wobble Kitty",            "Creepy-Cute Creatures"),
    ("016_Celestial_Dumpling_Core", "Celestial Dumpling Core", "Squishy Foods (Legendary)"),
    ("032_Singularity_Goo_Core",    "Singularity Goo Core",    "Goo & Fidgets (Legendary)"),
    ("048_Mythic_Plush_Familiar",   "Mythic Plush Familiar",   "Creepy-Cute (Legendary)"),
]

LINEART_PROMPT = """Convert this character into a children's coloring book page.

CRITICAL REQUIREMENTS:
- Pure BLACK line art on PURE WHITE background only
- NO shading, NO grayscale, NO color, NO fill — only black outlines
- Clean simple bold outlines, kid-friendly line thickness
- Preserve the EXACT character features, expression, and proportions from the reference image
- The character should be centered, large, taking up about 80% of the frame
- Add a few simple whimsical decorative elements around the character (sparkles, stars, simple shapes) that are easy and fun for a child to color
- Square aspect ratio
- Style: classic children's coloring book illustration suitable for ages 4-8
- Background: completely white with very minimal optional simple decoration

This is for a printable coloring page. The output must be printer-ready black lines on white."""


def generate_lineart(card_file: Path, out_path: Path):
    """Convert a single card art to line art via NBP."""
    if out_path.exists():
        print(f"  skip (exists): {out_path.name}")
        return
    ref_img = PIL.Image.open(card_file)
    print(f"  generating: {out_path.name}...")
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[LINEART_PROMPT, ref_img],
        config=types.GenerateContentConfig(
            image_config=types.ImageConfig(aspect_ratio="1:1"),
        ),
    )
    # Extract the image bytes
    for part in response.candidates[0].content.parts:
        if part.inline_data:
            out_path.write_bytes(part.inline_data.data)
            return
    raise RuntimeError(f"No image in response for {card_file.name}")


def build_pdf():
    """Assemble the 8 line-art images into a printable PDF."""
    # Register Fredoka if available
    fredoka_path = REPO / "assets" / "google_fonts" / "Fredoka.ttf"
    if fredoka_path.exists():
        pdfmetrics.registerFont(TTFont("Fredoka", str(fredoka_path)))
        display_font = "Fredoka"
    else:
        display_font = "Helvetica-Bold"

    PINK = HexColor("#FF8FB8")
    DUSK = HexColor("#3B2A4D")
    CREAM = HexColor("#FFF6E7")
    GOLD = HexColor("#E2A85F")

    W, H = LETTER
    c = canvas.Canvas(str(PDF_OUT), pagesize=LETTER)

    # ---- COVER PAGE ----
    c.setFillColor(CREAM)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    # Top brand band
    c.setFillColor(DUSK)
    c.rect(0, H - 1.4 * inch, W, 1.4 * inch, fill=1, stroke=0)
    c.setFillColor(CREAM)
    c.setFont(display_font, 36)
    c.drawCentredString(W / 2, H - 0.7 * inch, "SQUISHY SMASH")
    c.setFillColor(GOLD)
    c.setFont(display_font, 16)
    c.drawCentredString(W / 2, H - 1.05 * inch, "Coloring Pack — 8 of Our Favorite Squishies")

    # Cover blurb
    c.setFillColor(DUSK)
    c.setFont(display_font, 22)
    c.drawCentredString(W / 2, H - 2.2 * inch, "Color them in. Make them yours.")
    c.setFont("Helvetica", 12)
    c.setFillColor(black)
    blurb_lines = [
        "Inside: 8 of our favorite Squishy Smash characters as printable",
        "coloring pages. Print them, color them, hang them on the fridge.",
        "",
        "Includes the three Book 2 stars (Soft Dumpling, Goo Ball, Blushy Bun)",
        "and the three Legendary characters from the game and books.",
    ]
    y = H - 2.7 * inch
    for line in blurb_lines:
        c.drawCentredString(W / 2, y, line)
        y -= 0.22 * inch

    # CTA box
    c.setFillColor(PINK)
    c.roundRect(1.5 * inch, 2.5 * inch, W - 3 * inch, 1.4 * inch, 10, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont(display_font, 16)
    c.drawCentredString(W / 2, 3.55 * inch, "Want more Squishies?")
    c.setFont("Helvetica", 11)
    c.drawCentredString(W / 2, 3.25 * inch, "Squishy Smash mobile game — free on iOS App Store")
    c.drawCentredString(W / 2, 3.05 * inch, "Picture books on Amazon: Books 1 & 2 live now")
    c.drawCentredString(W / 2, 2.85 * inch, "squishysmash.com  •  squishysmash.substack.com")

    # Footer
    c.setFillColor(DUSK)
    c.setFont("Helvetica-Oblique", 9)
    c.drawCentredString(W / 2, 1.6 * inch, "Original characters by Christopher Ryan Campbell")
    c.drawCentredString(W / 2, 1.4 * inch, "Athlete Domains, LLC  •  Spartanburg, SC")

    # Bottom note
    c.setFillColor(GOLD)
    c.setFont("Helvetica-Oblique", 10)
    c.drawCentredString(W / 2, 0.7 * inch, "For personal and classroom use only.")
    c.drawCentredString(W / 2, 0.5 * inch, "Please don't resell or distribute commercially. Sharing with friends is encouraged!")

    c.showPage()

    # ---- ONE PAGE PER CHARACTER ----
    for card_stem, display_name, pack_label in CHARACTERS:
        lineart_path = LINEART_DIR / f"{card_stem}_lineart.png"
        if not lineart_path.exists():
            print(f"  warn: missing lineart for {card_stem}, skipping page")
            continue

        # White background
        c.setFillColor(white)
        c.rect(0, 0, W, H, fill=1, stroke=0)

        # Top header band (slim)
        c.setFillColor(DUSK)
        c.rect(0, H - 0.7 * inch, W, 0.7 * inch, fill=1, stroke=0)
        c.setFillColor(CREAM)
        c.setFont(display_font, 22)
        c.drawCentredString(W / 2, H - 0.45 * inch, display_name)
        c.setFillColor(GOLD)
        c.setFont("Helvetica-Oblique", 10)
        c.drawCentredString(W / 2, H - 0.62 * inch, pack_label)

        # Big centered image area
        img_size = 7.0 * inch
        img_x = (W - img_size) / 2
        img_y = (H - img_size) / 2 - 0.3 * inch
        img = PIL.Image.open(lineart_path).convert("RGB")
        c.drawImage(ImageReader(img), img_x, img_y, width=img_size, height=img_size,
                    preserveAspectRatio=True, mask='auto')

        # Bottom hint
        c.setFillColor(DUSK)
        c.setFont(display_font, 10)
        c.drawCentredString(W / 2, 0.7 * inch, "SQUISHY SMASH  •  squishysmash.com")
        c.setFillColor(GOLD)
        c.setFont("Helvetica-Oblique", 9)
        c.drawCentredString(W / 2, 0.5 * inch, "Every pop is a hello.")

        c.showPage()

    # ---- BACK PAGE ----
    c.setFillColor(CREAM)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(DUSK)
    c.setFont(display_font, 28)
    c.drawCentredString(W / 2, H - 1.5 * inch, "Thank you for coloring!")
    c.setFont("Helvetica", 12)
    c.setFillColor(black)
    back_lines = [
        "If you enjoyed these characters, there are 40 more waiting for you",
        "in the Squishy Smash mobile game and picture books.",
        "",
        "Book 1: Squishy Smash — Meet the Squishies (Amazon paperback)",
        "Book 2: Squishy Smash — The Lost Sparkle (Amazon paperback)",
        "Game: Squishy Smash on the iOS App Store (free)",
        "Free read-along video on YouTube",
        "",
        "Six books planned in the series — Books 3 and 4 in active production.",
        "",
        "Follow the build at squishysmash.substack.com",
        "TikTok: @CryptoChris8",
        "",
        "Tag #SquishySmash if you share your colored pages — we'd love to see them.",
    ]
    y = H - 2.4 * inch
    for line in back_lines:
        c.drawCentredString(W / 2, y, line)
        y -= 0.22 * inch

    c.setFillColor(GOLD)
    c.setFont(display_font, 14)
    c.drawCentredString(W / 2, 1.2 * inch, "Every pop is a hello. Every hello comes back.")
    c.setFillColor(DUSK)
    c.setFont("Helvetica-Oblique", 9)
    c.drawCentredString(W / 2, 0.6 * inch, "© 2026 Athlete Domains, LLC  •  Squishy Smash and all characters are original works")
    c.showPage()

    c.save()
    sz_kb = PDF_OUT.stat().st_size // 1024
    print(f"\nPDF built: {PDF_OUT} ({sz_kb} KB)")


def main():
    print("Stage 1: generating line art via Nano Banana Pro...")
    for card_stem, _, _ in CHARACTERS:
        card_file = CARDS / f"{card_stem}.webp"
        if not card_file.exists():
            print(f"  ERROR: card not found: {card_file}")
            continue
        out_path = LINEART_DIR / f"{card_stem}_lineart.png"
        generate_lineart(card_file, out_path)

    print("\nStage 2: assembling PDF...")
    build_pdf()


if __name__ == "__main__":
    main()
