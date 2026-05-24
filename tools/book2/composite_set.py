"""Composite the trio onto each of the 3 pack-world plates. Book #2 POC set.
Uses the unified protagonist regen sprites from book/spread_poc/chars/."""
import os
from PIL import Image, ImageDraw, ImageFilter

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
CHARS_DIR = os.path.join(SQ, "book", "spread_poc", "chars")
OUT_DIR = os.path.join(SQ, "book", "spread_poc")

sprite_files = {
    "soft":   "soft_dumpling_neutral.png",
    "goo":    "goo_ball_neutral.png",
    "blushy": "blushy_bun_bunny_neutral.png",
}

def crop_to_alpha(img):
    alpha = img.split()[3]
    bbox = alpha.getbbox()
    return img.crop(bbox) if bbox else img

sprites = {k: crop_to_alpha(Image.open(os.path.join(CHARS_DIR, v)).convert("RGBA"))
           for k, v in sprite_files.items()}

def resize_h(img, target_h):
    w, h = img.size
    return img.resize((int(w * target_h / h), target_h), Image.LANCZOS)

target_h = 320
ch_soft = resize_h(sprites["soft"], target_h)
ch_goo = resize_h(sprites["goo"], target_h)
ch_blu = resize_h(sprites["blushy"], target_h)

def paste_with_shadow(canvas, sprite, cx, baseline_y):
    sw, sh = sprite.size
    x = int(cx - sw / 2)
    y_top = int(baseline_y - sh)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    shw = int(sw * 0.75)
    shh = int(sh * 0.07)
    shx = int(cx - shw / 2)
    shy = int(baseline_y - shh * 0.45)
    draw.ellipse([shx, shy, shx + shw, shy + shh], fill=(70, 50, 80, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(7))
    canvas.alpha_composite(shadow)
    canvas.paste(sprite, (x, y_top), sprite)


for loc in ["pudding_hills", "goo_coast", "moonlit_hollow"]:
    plate = Image.open(os.path.join(OUT_DIR, f"plate_{loc}.png")).convert("RGBA")
    W, H = plate.size
    bottom = H - 55
    centers = [W * 0.18, W * 0.50, W * 0.82]
    for sprite, cx in [(ch_soft, centers[0]), (ch_goo, centers[1]), (ch_blu, centers[2])]:
        paste_with_shadow(plate, sprite, cx, bottom)
    out = os.path.join(OUT_DIR, f"spread_{loc}.png")
    plate.convert("RGB").save(out, format="PNG", optimize=True)
    print(f"  -> {out}")

print("DONE")
