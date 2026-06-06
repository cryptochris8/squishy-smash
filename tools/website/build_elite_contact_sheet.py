"""Build a contact sheet for the elite-tier hero shots to review them in
one place after generation. Helpful for identifying re-roll candidates.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SQ = Path(r"C:\Users\chris\Squishy-smash\squishy_smash")
SRC = SQ / "assets" / "website_hero"
OUT = SQ / "book" / "build_book2" / "out" / "_elite_tier_contact_sheet.jpg"

# Try to use Bookmania, fall back
FONT_DIRS = [
    SQ / "book" / "assets" / "fonts",
    Path(r"C:\Windows\Fonts"),
]
def _find_font(candidates):
    for d in FONT_DIRS:
        for n in candidates:
            p = d / n
            if p.exists():
                return str(p)
    return None
BOLD = _find_font(["Bookmania-Black.otf", "Bookmania-Bold.otf", "georgiab.ttf", "arialbd.ttf"])

title_font = ImageFont.truetype(BOLD, 18) if BOLD else ImageFont.load_default()

# Gather hero_NNN_*.png in numerical order
hero_files = sorted(SRC.glob("hero_*_*.png"), key=lambda p: p.name)
# Filter out the 3 Legendary singletons (no number prefix)
hero_files = [p for p in hero_files if p.stem.split("_")[1].isdigit()]

print(f"Found {len(hero_files)} elite hero files")

if not hero_files:
    print("No elite-tier files found yet")
    exit(1)

# 7 across × 3 rows for 21 items (7 per pack)
COLS = 7
ROWS = (len(hero_files) + COLS - 1) // COLS
THUMB = 280
PAD = 14
LABEL_H = 36

W = COLS * THUMB + (COLS + 1) * PAD
H = ROWS * (THUMB + LABEL_H + PAD) + PAD

canvas = Image.new("RGB", (W, H), (245, 233, 208))
d = ImageDraw.Draw(canvas)
ink = (74, 45, 36)

for i, p in enumerate(hero_files):
    row = i // COLS
    col = i % COLS
    x = PAD + col * (THUMB + PAD)
    y = PAD + row * (THUMB + LABEL_H + PAD)
    img = Image.open(p).convert("RGB").resize((THUMB, THUMB), Image.LANCZOS)
    canvas.paste(img, (x, y))
    # Card number label
    num = p.stem.split("_")[1]
    name = " ".join(p.stem.split("_")[2:]).title()
    label = f"#{num}  {name}"
    bbox = d.textbbox((0, 0), label, font=title_font)
    tw = bbox[2] - bbox[0]
    d.text((x + (THUMB - tw) // 2, y + THUMB + 6), label, font=title_font, fill=ink)

canvas.thumbnail((2400, 2400))
canvas.save(OUT, quality=90)
print(f"Saved: {OUT}  size={canvas.size}")
