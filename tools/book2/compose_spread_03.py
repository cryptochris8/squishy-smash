"""Spread 3 — Three Look Up. Triptych: 3 vertical panels, one per pack-world.
Each panel shows the relevant Common protagonist (scared pose, moment before
bravery) looking up at their home sky. Text band across the bottom."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
CANVAS_W = 2550
CANVAS_H = 2550
PANEL_H = 1785
PANEL_W = CANVAS_W // 3
BAND_H = CANVAS_H - PANEL_H
FONT = os.path.join(SQ, "assets", "google_fonts", "EBGaramond-Regular.ttf")
OUT = os.path.join(SQ, "book", "spreads_rendered", "spread_03.png")

PANELS = [
    {"plate": "book/spread_poc/plate_pudding_hills_v2.png",
     "char":  "book/spread_poc/chars/soft_dumpling_scared.png"},
    {"plate": "book/spread_poc/plate_goo_coast.png",
     "char":  "book/spread_poc/chars/goo_ball_neutral.png"},
    {"plate": "book/spread_poc/plate_moonlit_hollow.png",
     "char":  "book/spread_poc/chars/blushy_bun_bunny_scared.png"},
]
PROSE = (
    "In Pudding Hills, Soft Dumpling looked up. In Goo Coast, Goo Ball looked up. "
    "In Moonlit Hollow, Blushy Bun Bunny looked up. None of them had ever left "
    "home before. But each of them, very quietly, decided it was time."
)


def load_panel(path, w, h):
    img = Image.open(os.path.join(SQ, path)).convert("RGBA")
    iw, ih = img.size
    scale = max(w / iw, h / ih)
    nw, nh = int(iw * scale), int(ih * scale)
    img = img.resize((nw, nh), Image.LANCZOS)
    left = (nw - w) // 2
    top = (nh - h) // 2
    return img.crop((left, top, left + w, top + h))


def crop_to_alpha(img):
    bbox = img.split()[3].getbbox()
    return img.crop(bbox) if bbox else img


def resize_h(img, h):
    w, hh = img.size
    return img.resize((int(w * h / hh), h), Image.LANCZOS)


def paste_with_shadow(canvas, sprite, x_center, y_bottom, blur=18):
    sw, sh = sprite.size
    x = int(x_center - sw / 2)
    y_top = int(y_bottom - sh)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    shw = int(sw * 0.75); shh = int(sh * 0.07)
    shx = int(x_center - shw / 2); shy = int(y_bottom - shh * 0.45)
    d.ellipse([shx, shy, shx + shw, shy + shh], fill=(0, 0, 30, 140))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.paste(sprite, (x, y_top), sprite)


canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (255, 255, 255, 255))

for i, panel in enumerate(PANELS):
    plate = load_panel(panel["plate"], PANEL_W, PANEL_H)
    canvas.paste(plate, (i * PANEL_W, 0))
    sprite = crop_to_alpha(Image.open(os.path.join(SQ, panel["char"])).convert("RGBA"))
    sprite = resize_h(sprite, int(PANEL_H * 0.28))
    paste_with_shadow(canvas, sprite, i * PANEL_W + PANEL_W // 2, PANEL_H - 80)

# Thin cream dividers between panels
draw = ImageDraw.Draw(canvas)
for i in [1, 2]:
    draw.rectangle([i * PANEL_W - 3, 0, i * PANEL_W + 3, PANEL_H],
                   fill=(245, 235, 220, 255))

# Solid white text band
band = Image.new("RGBA", (CANVAS_W, BAND_H), (255, 255, 255, 255))
canvas.alpha_composite(band, (0, PANEL_H))

# Prose
font = ImageFont.truetype(FONT, 56)
words = PROSE.split()
max_w = int(CANVAS_W * 0.86)
lines = []
cur = []
for w in words:
    if (draw.textbbox((0, 0), " ".join(cur + [w]), font=font)[2]) > max_w and cur:
        lines.append(" ".join(cur)); cur = [w]
    else:
        cur.append(w)
if cur: lines.append(" ".join(cur))

sample = draw.textbbox((0, 0), "Mg", font=font)
line_h = sample[3] - sample[1]
gap = int(line_h * 0.45)
total_h = len(lines) * line_h + (len(lines) - 1) * gap
y = PANEL_H + (BAND_H - total_h) // 2
for line in lines:
    bbox = draw.textbbox((0, 0), line, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((CANVAS_W - tw) // 2, y), line, fill=(18, 11, 23), font=font)
    y += line_h + gap

canvas.convert("RGB").save(OUT, format="PNG", optimize=True)
print(f"-> {OUT}")
