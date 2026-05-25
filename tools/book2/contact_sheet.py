"""Build a 6x3 contact sheet of all 18 spread slots — rendered + TBD placeholders."""
import os
from PIL import Image, ImageDraw, ImageFont

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
RENDERED = os.path.join(SQ, "book", "spreads_rendered")
OUT = os.path.join(RENDERED, "_contact_sheet.png")
FONT = os.path.join(SQ, "assets", "google_fonts", "Fredoka.ttf")

THUMB = 400
GAP = 18
COLS = 6
ROWS = 3
LABEL_H = 42
PADDING = 30

W = COLS * THUMB + (COLS - 1) * GAP + 2 * PADDING
H = ROWS * (THUMB + LABEL_H) + (ROWS - 1) * GAP + 2 * PADDING

canvas = Image.new("RGB", (W, H), (18, 11, 23))  # brand deep starry-night
draw = ImageDraw.Draw(canvas)
font = ImageFont.truetype(FONT, 22)
font_small = ImageFont.truetype(FONT, 18)

for i in range(1, 19):
    spread_path = os.path.join(RENDERED, f"spread_{i:02d}.png")
    col = (i - 1) % COLS
    row = (i - 1) // COLS
    x = PADDING + col * (THUMB + GAP)
    y = PADDING + row * (THUMB + LABEL_H + GAP)
    if os.path.exists(spread_path):
        img = Image.open(spread_path).convert("RGB")
        img.thumbnail((THUMB, THUMB), Image.LANCZOS)
        canvas.paste(img, (x, y))
        # Subtle border
        draw.rectangle([x, y, x + THUMB - 1, y + THUMB - 1], outline=(80, 60, 100), width=1)
    else:
        # Placeholder for pending special-layout spreads
        draw.rectangle([x, y, x + THUMB, y + THUMB], fill=(40, 28, 60),
                       outline=(120, 90, 150), width=2)
        msg = "TBD\nspecial layout"
        bbox = draw.multiline_textbbox((0, 0), msg, font=font_small, align="center")
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.multiline_text((x + (THUMB - tw) // 2, y + (THUMB - th) // 2),
                            msg, fill=(200, 180, 230), font=font_small, align="center")
    label = f"Spread {i}"
    bbox = draw.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((x + (THUMB - tw) // 2, y + THUMB + 8), label,
              fill=(255, 240, 220), font=font)

canvas.save(OUT, format="PNG", optimize=True)
print(f"-> {OUT} ({canvas.size})")
