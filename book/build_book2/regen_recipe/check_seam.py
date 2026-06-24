"""Render a raw 21:9 candidate as an open-book with the seam line + a faint
gutter band (+/-0.25in) so we can see exactly what the fold touches.
Usage: python check_seam.py <filename_in__tmp_spine_regen>"""
import sys
from pathlib import Path
import PIL.Image
from PIL import ImageDraw

REG = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen")
BLEED = 37; PW = 2625; PH = 2625; INNER = PW - BLEED
GUTTER = 75  # ~0.25 in each side of the fold that the perfect binding eats

f = sys.argv[1]
img = PIL.Image.open(REG / f).convert("RGB")
new_w = int(img.width * PH / img.height)
s = img.resize((new_w, PH), PIL.Image.LANCZOS)
sx = new_w // 2
v = s.crop((sx - INNER, 0, sx + BLEED, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
r = s.crop((sx - BLEED, 0, sx + INNER, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
c = PIL.Image.new("RGB", (v.width + r.width, v.height))
c.paste(v, (0, 0)); c.paste(r, (v.width, 0))
d = ImageDraw.Draw(c, "RGBA")
seam = v.width
d.rectangle((seam - GUTTER, 0, seam + GUTTER, c.height), fill=(255, 60, 60, 60))  # gutter band
d.line((seam, 0, seam, c.height), fill=(255, 30, 30), width=4)                     # fold
out = REG / (Path(f).stem + "_seam.png")
c.resize((1500, int(1500 * c.height / c.width)), PIL.Image.LANCZOS).save(out)
print("WROTE", out.name)
