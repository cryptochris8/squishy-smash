"""Seam-overlay the 10 arm-raised edits to confirm the repaint didn't shift any
subject onto the gutter. Two contact sheets (red line = fold, band = gutter)."""
from pathlib import Path
import PIL.Image
from PIL import ImageDraw, ImageFont
REG = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen")
BLEED = 37; PW = 2625; PH = 2625; INNER = PW - BLEED; GUTTER = 75
SPREADS = [4, 5, 7, 8, 10, 12, 13, 14, 16, 17]


def open_book_seam(img):
    img = img.convert("RGB")
    nw = int(img.width * PH / img.height)
    s = img.resize((nw, PH), PIL.Image.LANCZOS); sx = nw // 2
    v = s.crop((sx - INNER, 0, sx + BLEED, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    r = s.crop((sx - BLEED, 0, sx + INNER, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    c = PIL.Image.new("RGB", (v.width + r.width, v.height)); c.paste(v, (0, 0)); c.paste(r, (v.width, 0))
    d = ImageDraw.Draw(c, "RGBA")
    d.rectangle((v.width - GUTTER, 0, v.width + GUTTER, c.height), fill=(255, 60, 60, 70))
    d.line((v.width, 0, v.width, c.height), fill=(255, 30, 30), width=4)
    return c


try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()

W = 1120
for si, group in enumerate([SPREADS[:5], SPREADS[5:]]):
    cells = []
    for n in group:
        ob = open_book_seam(PIL.Image.open(REG / f"s{n:02d}_arms.png"))
        im = ob.resize((W, int(W * 0.5)), PIL.Image.LANCZOS)
        bar = PIL.Image.new("RGB", (W, 28), (20, 20, 20))
        ImageDraw.Draw(bar).text((8, 2), f"S{n:02d} arms-raised  (red line = fold)", font=F, fill=(255, 255, 255))
        cell = PIL.Image.new("RGB", (W, 28 + im.height), (0, 0, 0))
        cell.paste(bar, (0, 0)); cell.paste(im, (0, 28))
        cells.append(cell)
    H = sum(c.height for c in cells) + 8 * (len(cells) - 1)
    sheet = PIL.Image.new("RGB", (W, H), (0, 0, 0)); y = 0
    for c in cells:
        sheet.paste(c, (0, y)); y += c.height + 8
    sheet.save(REG / f"arms_seamcheck_{si+1}.png")
    print("wrote", f"arms_seamcheck_{si+1}.png")
print("DONE")
