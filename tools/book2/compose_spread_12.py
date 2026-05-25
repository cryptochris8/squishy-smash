"""Spread 12 — EVERYBODY SQUISH! (the big-pop climax).
Custom: Moonlit Hollow base + warm radial burst overlay transforming the cool
night to gold + triumphant trio in arc + body text + italic Pact line."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
CANVAS = 2550
FONT_REG = os.path.join(SQ, "assets", "google_fonts", "EBGaramond-Regular.ttf")
FONT_ITAL = os.path.join(SQ, "assets", "google_fonts", "EBGaramond-Italic.ttf")
FONT_DISPLAY = os.path.join(SQ, "assets", "google_fonts", "Fredoka.ttf")
OUT = os.path.join(SQ, "book", "spreads_rendered", "spread_12.png")

PLATE = "book/spread_poc/plate_moonlit_hollow.png"
TRIO = [
    ("book/spread_poc/chars/soft_dumpling_triumphant.png", 0.20, 0.66, 0.24),
    ("book/spread_poc/chars/goo_ball_neutral.png",         0.50, 0.58, 0.30),
    ("book/spread_poc/chars/blushy_bun_bunny_triumphant.png", 0.80, 0.48, 0.32),
]
BODY_TEXT = (
    "Then Blushy Bun Bunny did something brave. She squeezed Soft Dumpling. "
    "She squeezed Goo Ball. She squeezed herself. \"EVERYBODY SQUISH!\" she "
    "shouted, and they did. Three pops at once."
)
PACT_TEXT = "Every pop is a hello. Every hello comes back."


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


def paste_with_shadow(canvas, sprite, x_center, y_bottom, blur=24):
    sw, sh = sprite.size
    x = int(x_center - sw / 2); y_top = int(y_bottom - sh)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    shw = int(sw * 0.75); shh = int(sh * 0.07)
    shx = int(x_center - shw / 2); shy = int(y_bottom - shh * 0.45)
    d.ellipse([shx, shy, shx + shw, shy + shh], fill=(60, 40, 80, 140))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.paste(sprite, (x, y_top), sprite)


# Base plate
canvas = load_plate(PLATE, CANVAS)

# Warm radial burst — transforms cool night to gold
burst = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
bd = ImageDraw.Draw(burst)
cx, cy = CANVAS // 2, int(CANVAS * 0.55)
r = int(CANVAS * 0.55)
bd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 230, 160, 255))
burst = burst.filter(ImageFilter.GaussianBlur(180))
r_, g_, b_, a_ = burst.split()
a_ = a_.point(lambda p: int(p * 0.80))
burst = Image.merge("RGBA", (r_, g_, b_, a_))
canvas.alpha_composite(burst)

# Triumphant trio in arc
for path, xc, yb, h in TRIO:
    sprite = crop_alpha(Image.open(os.path.join(SQ, path)).convert("RGBA"))
    sprite = resize_h(sprite, int(CANVAS * h))
    paste_with_shadow(canvas, sprite, int(CANVAS * xc), int(CANVAS * yb))

# Text band at bottom (0.34 high so both text blocks fit)
band_h = int(CANVAS * 0.34)
band_y = CANVAS - band_h
band = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
ImageDraw.Draw(band).rectangle([0, band_y, CANVAS, CANVAS], fill=(255, 255, 255, 240))
# Soft feather edge
feather = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
ImageDraw.Draw(feather).rectangle([0, band_y - 60, CANVAS, band_y + 60], fill=(255, 255, 255, 240))
feather = feather.filter(ImageFilter.GaussianBlur(40))
canvas = Image.alpha_composite(canvas, feather)
canvas = Image.alpha_composite(canvas, band)


def draw_centered(canvas, text, font_path, size, color, y_center, max_width_frac):
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(font_path, size)
    max_w = int(canvas.size[0] * max_width_frac)
    words = text.split()
    lines = []; cur = []
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
    cy = int(canvas.size[1] * y_center)
    y = cy - total_h // 2
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        tw = bbox[2] - bbox[0]
        draw.text(((canvas.size[0] - tw) // 2, y), line, fill=color, font=font)
        y += line_h + gap


draw_centered(canvas, BODY_TEXT, FONT_REG, 46, (18, 11, 23), 0.79, 0.86)
draw_centered(canvas, PACT_TEXT, FONT_ITAL, 58, (18, 11, 23), 0.92, 0.86)

canvas.convert("RGB").save(OUT, format="PNG", optimize=True)
print(f"-> {OUT}")
