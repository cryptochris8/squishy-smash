"""Final seam verification on the INTEGRATED print spreads.

Reads book2_final_spreads_print/spread_NN.png (the actual files the book builds
from), simulates the print crop + fold, overlays the seam line + gutter band,
and writes 3 contact sheets (1-6, 7-12, 13-18) for a full-res fold check.

Usage: python verify_seams.py
"""
from pathlib import Path
import PIL.Image
from PIL import ImageDraw, ImageFont

PROJ = Path(r"C:\Users\chris\Squishy-smash")
SP = PROJ / "book2_final_spreads_print"
OUT = PROJ / "_tmp_spine_regen"
BLEED = 37; PW = 2625; PH = 2625; INNER = PW - BLEED; GUTTER = 75


def open_book_seam(img):
    img = img.convert("RGB")
    new_w = int(img.width * PH / img.height)
    s = img.resize((new_w, PH), PIL.Image.LANCZOS)
    sx = new_w // 2
    v = s.crop((sx - INNER, 0, sx + BLEED, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    r = s.crop((sx - BLEED, 0, sx + INNER, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    c = PIL.Image.new("RGB", (v.width + r.width, v.height))
    c.paste(v, (0, 0)); c.paste(r, (v.width, 0))
    d = ImageDraw.Draw(c, "RGBA")
    d.rectangle((v.width - GUTTER, 0, v.width + GUTTER, c.height), fill=(255, 60, 60, 70))
    d.line((v.width, 0, v.width, c.height), fill=(255, 30, 30), width=4)
    return c


try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()

W = 1120
for sheet_i, lo in enumerate([1, 7, 13]):
    cells = []
    for n in range(lo, lo + 6):
        ob = open_book_seam(PIL.Image.open(SP / f"spread_{n:02d}.png"))
        im = ob.resize((W, int(W * 0.5)), PIL.Image.LANCZOS)
        bar = PIL.Image.new("RGB", (W, 28), (20, 20, 20))
        ImageDraw.Draw(bar).text((8, 2), f"Spread {n:02d}   (red line = fold; band = gutter)", font=F, fill=(255, 255, 255))
        cell = PIL.Image.new("RGB", (W, 28 + im.height), (0, 0, 0))
        cell.paste(bar, (0, 0)); cell.paste(im, (0, 28))
        cells.append(cell)
    H = sum(c.height for c in cells) + 8 * (len(cells) - 1)
    sheet = PIL.Image.new("RGB", (W, H), (0, 0, 0))
    y = 0
    for c in cells:
        sheet.paste(c, (0, y)); y += c.height + 8
    out = OUT / f"verify_seams_{sheet_i+1}.png"
    sheet.save(out)
    print("WROTE", out.name)
print("DONE")
