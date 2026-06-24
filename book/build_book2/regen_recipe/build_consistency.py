"""Crop the trio from each pilot land and stack them so consistency is obvious."""
from pathlib import Path
import PIL.Image
from PIL import ImageDraw, ImageFont

REG = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen")
try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()

picks = [(6, 2, "PUDDING HILLS"), (8, 2, "GOO COAST"), (10, 1, "MOONLIT HOLLOW")]
W = 760
cells = []
for n, k, land in picks:
    im = PIL.Image.open(REG / f"pilot_s{n:02d}_{k}.png").convert("RGB")
    crop = im.crop((0, 0, int(im.width * 0.42), im.height))  # left portion = the trio
    crop = crop.resize((W, int(W * crop.height / crop.width)), PIL.Image.LANCZOS)
    bar = PIL.Image.new("RGB", (W, 32), (30, 30, 30))
    ImageDraw.Draw(bar).text((8, 4), f"S{n:02d}  {land}", font=F, fill=(255, 255, 255))
    cell = PIL.Image.new("RGB", (W, 32 + crop.height), (0, 0, 0))
    cell.paste(bar, (0, 0)); cell.paste(crop, (0, 32))
    cells.append(cell)
out = PIL.Image.new("RGB", (W, sum(c.height for c in cells) + 8 * (len(cells) - 1)), (0, 0, 0))
y = 0
for c in cells:
    out.paste(c, (0, y)); y += c.height + 8
out.save(REG / "pilot_consistency.png")
print("WROTE pilot_consistency.png")
