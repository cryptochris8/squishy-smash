"""Spread 13 — The Three Cores arrive.
Moonlit Hollow plate brightened with warm overlay + 3 Cores arriving large
overhead + trio in NEUTRAL pose at center bottom looking up + 3 tiny rising
shards visible above the trio + text band."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
CANVAS = 2550
FONT = os.path.join(SQ, "assets", "google_fonts", "EBGaramond-Regular.ttf")
OUT = os.path.join(SQ, "book", "spreads_rendered", "spread_13.png")

PLATE = "book/spread_poc/plate_moonlit_hollow.png"

# Cores arrive overhead — scaled enormous (height fraction = 0.35)
CORES = [
    ("book/spread_poc/chars/celestial_dumpling_core.png", 0.20, 0.40, 0.34),
    ("book/spread_poc/chars/singularity_goo_core.png",    0.50, 0.36, 0.36),
    ("book/spread_poc/chars/mythic_plush_familiar.png",   0.80, 0.40, 0.34),
]
# Trio at center bottom — small, looking up
TRIO = [
    ("book/spread_poc/chars/soft_dumpling_neutral.png", 0.40, 0.68, 0.14),
    ("book/spread_poc/chars/goo_ball_neutral.png",      0.50, 0.68, 0.14),
    ("book/spread_poc/chars/blushy_bun_bunny_neutral.png", 0.60, 0.68, 0.14),
]
PROSE = (
    "And the dark grove was suddenly not dark. The three shards rose, glossy "
    "and warm and brave at once, and touched. Above them, slow and enormous, "
    "the three Cores arrived. Celestial Dumpling Core. Singularity Goo Core. "
    "Mythic Plush Familiar. They bowed to the trio who had done what no Core "
    "could have done."
)


def load_plate(path, target):
    img = Image.open(os.path.join(SQ, path)).convert("RGBA")
    iw, ih = img.size
    scale = max(target / iw, target / ih)
    nw, nh = int(iw * scale), int(ih * scale)
    img = img.resize((nw, nh), Image.LANCZOS)
    left = (nw - target) // 2; top = (nh - target) // 2
    return img.crop((left, top, left + target, top + target))


def crop_alpha(img):
    bbox = img.split()[3].getbbox()
    return img.crop(bbox) if bbox else img


def resize_h(img, h):
    w, hh = img.size
    return img.resize((int(w * h / hh), h), Image.LANCZOS)


def paste_with_shadow(canvas, sprite, x_center, y_bottom, blur=20):
    sw, sh = sprite.size
    x = int(x_center - sw / 2); y_top = int(y_bottom - sh)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    shw = int(sw * 0.75); shh = int(sh * 0.07)
    shx = int(x_center - shw / 2); shy = int(y_bottom - shh * 0.45)
    d.ellipse([shx, shy, shx + shw, shy + shh], fill=(0, 0, 30, 130))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.paste(sprite, (x, y_top), sprite)


def add_glow(canvas, cx, cy, radius, color=(255, 230, 170, 200)):
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
                                   fill=color)
    glow = glow.filter(ImageFilter.GaussianBlur(radius // 2))
    canvas.alpha_composite(glow)


# Base plate (the grove that's about to become not-dark)
canvas = load_plate(PLATE, CANVAS)

# Gentle warming overlay — the moment the dark grove becomes "not dark"
warm = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
ImageDraw.Draw(warm).rectangle([0, 0, CANVAS, CANVAS], fill=(255, 235, 200, 60))
canvas.alpha_composite(warm)

# Cores arriving overhead — composite with their own halos
for path, xc, yb, h in CORES:
    sprite = crop_alpha(Image.open(os.path.join(SQ, path)).convert("RGBA"))
    sprite = resize_h(sprite, int(CANVAS * h))
    px = int(CANVAS * xc); py = int(CANVAS * yb)
    # Halo behind each Core
    add_glow(canvas, px, py - int(sprite.size[1] * 0.5), int(sprite.size[1] * 0.65))
    paste_with_shadow(canvas, sprite, px, py)

# Three tiny rising shards visible between trio and Cores
shard_y = int(CANVAS * 0.62)
for sx in [0.40, 0.50, 0.60]:
    add_glow(canvas, int(CANVAS * sx), shard_y, 35, color=(255, 240, 180, 230))

# Trio at center bottom — small, looking up at the Cores
for path, xc, yb, h in TRIO:
    sprite = crop_alpha(Image.open(os.path.join(SQ, path)).convert("RGBA"))
    sprite = resize_h(sprite, int(CANVAS * h))
    paste_with_shadow(canvas, sprite, int(CANVAS * xc), int(CANVAS * yb), blur=12)

# Text band at bottom
band_h = int(CANVAS * 0.30)
band_y = CANVAS - band_h
feather = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
ImageDraw.Draw(feather).rectangle([0, band_y - 60, CANVAS, band_y + 60], fill=(255, 255, 255, 230))
feather = feather.filter(ImageFilter.GaussianBlur(40))
canvas = Image.alpha_composite(canvas, feather)
band = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
ImageDraw.Draw(band).rectangle([0, band_y, CANVAS, CANVAS], fill=(255, 255, 255, 240))
canvas = Image.alpha_composite(canvas, band)

# Prose
draw = ImageDraw.Draw(canvas)
font = ImageFont.truetype(FONT, 52)
max_w = int(CANVAS * 0.86)
words = PROSE.split()
lines = []; cur = []
for w in words:
    if (draw.textbbox((0, 0), " ".join(cur + [w]), font=font)[2]) > max_w and cur:
        lines.append(" ".join(cur)); cur = [w]
    else:
        cur.append(w)
if cur: lines.append(" ".join(cur))
sample = draw.textbbox((0, 0), "Mg", font=font)
line_h = sample[3] - sample[1]
gap = int(line_h * 0.4)
total_h = len(lines) * line_h + (len(lines) - 1) * gap
cy = int(CANVAS * 0.85)
y = cy - total_h // 2
for line in lines:
    bbox = draw.textbbox((0, 0), line, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((CANVAS - tw) // 2, y), line, fill=(18, 11, 23), font=font)
    y += line_h + gap

canvas.convert("RGB").save(OUT, format="PNG", optimize=True)
print(f"-> {OUT}")
