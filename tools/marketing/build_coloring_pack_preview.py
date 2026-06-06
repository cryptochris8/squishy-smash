"""Build a 2x2 preview image of the coloring pack for the Substack welcome email.

Shows the three Book 2 protagonists + the Mythic Plush Familiar Legendary
in a clean grid with a small Squishy Smash header. Sized for email-embed
(1200 wide so it's crisp on retina and downscales cleanly).

Output: website/public/coloring-pack-preview.png (will deploy with the PDF).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[2]
LINEART = REPO / "assets" / "coloring_pack" / "lineart"
OUT = REPO / "website" / "public" / "coloring-pack-preview.png"
FREDOKA = REPO / "assets" / "google_fonts" / "Fredoka.ttf"

# Picks — three protagonists + one Legendary (strongest contrast)
CHARACTERS = [
    "001_Soft_Dumpling",
    "017_Goo_Ball",
    "033_Blushy_Bun_Bunny",
    "048_Mythic_Plush_Familiar",
]

W, H = 1200, 1200
CELL = 540
GUTTER = 30
MARGIN = 30
HEADER_H = 110
FOOTER_H = 70

CREAM = (255, 246, 231)
DUSK = (59, 42, 77)
GOLD = (226, 168, 95)


def build():
    canvas = Image.new("RGB", (W, H), CREAM)

    # Header band
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([(0, 0), (W, HEADER_H)], fill=DUSK)
    font_title = ImageFont.truetype(str(FREDOKA), 44)
    font_sub = ImageFont.truetype(str(FREDOKA), 22)
    title = "SQUISHY SMASH COLORING PACK"
    bbox = draw.textbbox((0, 0), title, font=font_title)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) // 2 - bbox[0], 18), title, font=font_title, fill=CREAM)
    sub = "8 printable characters — free download"
    bbox = draw.textbbox((0, 0), sub, font=font_sub)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) // 2 - bbox[0], 72), sub, font=font_sub, fill=GOLD)

    # Footer band
    draw.rectangle([(0, H - FOOTER_H), (W, H)], fill=DUSK)
    font_foot = ImageFont.truetype(str(FREDOKA), 24)
    footer = "squishysmash.com   ·   Every pop is a hello."
    bbox = draw.textbbox((0, 0), footer, font=font_foot)
    fw = bbox[2] - bbox[0]
    draw.text(((W - fw) // 2 - bbox[0], H - FOOTER_H + 22), footer,
              font=font_foot, fill=CREAM)

    # 2x2 grid of line-art characters
    grid_x_start = (W - 2 * CELL - GUTTER) // 2
    grid_y_start = HEADER_H + 30

    for i, char_stem in enumerate(CHARACTERS):
        row = i // 2
        col = i % 2
        cell_x = grid_x_start + col * (CELL + GUTTER)
        cell_y = grid_y_start + row * (CELL + GUTTER)

        # White cell with thin dusk border for visual contrast against cream
        draw.rectangle(
            [(cell_x, cell_y), (cell_x + CELL, cell_y + CELL)],
            fill=(255, 255, 255), outline=DUSK, width=2,
        )

        # Place line art (it's square so fits cleanly)
        lineart_path = LINEART / f"{char_stem}_lineart.png"
        if lineart_path.exists():
            img = Image.open(lineart_path).convert("RGBA")
            # Add inset padding
            pad = 8
            img = img.resize((CELL - pad * 2, CELL - pad * 2), Image.LANCZOS)
            canvas.paste(img, (cell_x + pad, cell_y + pad), mask=img if img.mode == "RGBA" else None)

    canvas.save(OUT, "PNG", optimize=True)
    sz_kb = OUT.stat().st_size // 1024
    print(f"Built: {OUT} ({sz_kb} KB)")


if __name__ == "__main__":
    build()
