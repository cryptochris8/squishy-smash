"""Grid contact sheet of the rendered hero stills for orientation/quality review.

  python contact_sheet.py  ->  C:/Users/chris/Squishy-smash/_tmp_3d_renders/_contact_sheet.png
"""

from pathlib import Path

from PIL import Image, ImageDraw

RENDERS = Path(r"C:\Users\chris\Squishy-smash\_tmp_3d_renders")
CELL = 220
COLS = 8

heroes = sorted(RENDERS.glob("*/*_hero_1024.png"))
rows = (len(heroes) + COLS - 1) // COLS
sheet = Image.new("RGB", (COLS * CELL, rows * (CELL + 22)), (245, 240, 248))
draw = ImageDraw.Draw(sheet)

for i, p in enumerate(heroes):
    img = Image.open(p).convert("RGBA").resize((CELL, CELL), Image.LANCZOS)
    x, y = (i % COLS) * CELL, (i // COLS) * (CELL + 22)
    sheet.paste(img, (x, y), img)
    draw.text((x + 4, y + CELL + 3), p.parent.name[:30], fill=(60, 40, 70))

out = RENDERS / "_contact_sheet.png"
sheet.save(out)
print(f"{out}  ({len(heroes)} heroes)")
