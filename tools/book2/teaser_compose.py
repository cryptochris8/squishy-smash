"""Compose teaser scenes — scared trio on Moonlit Hollow, triumphant trio with burst, end card."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
HOME = r"C:\Users\chris"
CHARS_DIR = os.path.join(SQ, "book", "spread_poc", "chars")
PLATE_MH = os.path.join(SQ, "book", "spread_poc", "plate_moonlit_hollow.png")
FONT = os.path.join(SQ, "assets", "google_fonts", "Fredoka.ttf")

OUT_SCARED = os.path.join(HOME, "_tmp_teaser_scared.png")
OUT_TRIUMPHANT = os.path.join(HOME, "_tmp_teaser_triumphant.png")
OUT_ENDCARD = os.path.join(HOME, "_tmp_teaser_endcard.png")


def crop_to_alpha(img):
    alpha = img.split()[3]
    bbox = alpha.getbbox()
    return img.crop(bbox) if bbox else img


def resize_h(img, h):
    w, hh = img.size
    return img.resize((int(w * h / hh), h), Image.LANCZOS)


def paste_with_shadow(canvas, sprite, cx, baseline_y, shadow_scale=1.0):
    sw, sh = sprite.size
    x = int(cx - sw / 2)
    y_top = int(baseline_y - sh)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    shw = int(sw * 0.75)
    shh = int(sh * 0.07)
    shx = int(cx - shw / 2)
    shy = int(baseline_y - shh * 0.45)
    # Darker shadow for night scene
    draw.ellipse([shx, shy, shx + shw, shy + shh], fill=(0, 0, 20, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(14 * shadow_scale)))
    canvas.alpha_composite(shadow)
    canvas.paste(sprite, (x, y_top), sprite)


def compose_trio(plate_path, pose, out_path, with_burst=False):
    plate = Image.open(plate_path).convert("RGBA")
    W, H = plate.size  # 2048, 2048
    sprites = {
        "soft": crop_to_alpha(Image.open(os.path.join(CHARS_DIR, f"soft_dumpling_{pose}.png")).convert("RGBA")),
        "goo": crop_to_alpha(Image.open(os.path.join(CHARS_DIR, f"goo_ball_{pose}.png")).convert("RGBA")),
        "blushy": crop_to_alpha(Image.open(os.path.join(CHARS_DIR, f"blushy_bun_bunny_{pose}.png")).convert("RGBA")),
    }
    target_h = 640  # 2x the POC's 320 — same proportion against the now-2x plate
    # Positions tighter (0.30/0.50/0.70 rather than 0.20/0.80) so all three
    # characters survive the ffmpeg center-crop to 1080x1920 vertical.
    chars = [
        (resize_h(sprites["soft"], target_h), W * 0.30),
        (resize_h(sprites["goo"], target_h), W * 0.50),
        (resize_h(sprites["blushy"], target_h), W * 0.70),
    ]
    bottom = H - 110

    if with_burst:
        # Warm radial burst behind the trio — represents the Big Pop / Sparkle returning
        burst = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        bd = ImageDraw.Draw(burst)
        cx, cy = W // 2, int(H * 0.65)
        r = int(W * 0.55)
        bd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 235, 170, 255))
        burst = burst.filter(ImageFilter.GaussianBlur(150))
        # Reduce alpha for blended overlay
        r_, g_, b_, a_ = burst.split()
        a_ = a_.point(lambda p: int(p * 0.75))
        burst = Image.merge("RGBA", (r_, g_, b_, a_))
        plate.alpha_composite(burst)

    for sprite, cx in chars:
        paste_with_shadow(plate, sprite, cx, bottom, shadow_scale=2.0)

    plate.convert("RGB").save(out_path, format="PNG", optimize=True)
    print(f"-> {out_path}")


def make_endcard(out_path):
    W, H = 1080, 1920
    card = Image.new("RGB", (W, H), (18, 11, 23))  # brand deep starry-night

    # Soft glow at center to draw the eye
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = W // 2, int(H * 0.50)
    r = int(W * 0.65)
    gd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 200, 235, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(140))
    card_rgba = card.convert("RGBA")
    card_rgba.alpha_composite(glow)
    card = card_rgba.convert("RGB")

    draw = ImageDraw.Draw(card)
    try:
        title_font = ImageFont.truetype(FONT, 110)
        sub_font = ImageFont.truetype(FONT, 56)
        cta_font = ImageFont.truetype(FONT, 64)
        tiny_font = ImageFont.truetype(FONT, 38)
    except OSError:
        title_font = sub_font = cta_font = tiny_font = ImageFont.load_default()

    def center_text(text, font, y, color):
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        draw.text(((W - tw) / 2, y), text, fill=color, font=font)

    center_text("The Lost", title_font, H * 0.32, (255, 240, 220))
    center_text("Sparkle", title_font, H * 0.39, (255, 240, 220))
    center_text("a Squishy Smash story", sub_font, H * 0.50, (255, 180, 210))
    center_text("Coming soon", cta_font, H * 0.62, (255, 220, 170))
    center_text("Squishy Smash — free on iPhone", tiny_font, H * 0.70, (200, 200, 230))

    card.save(out_path, format="PNG", optimize=True)
    print(f"-> {out_path}")


compose_trio(PLATE_MH, "scared", OUT_SCARED, with_burst=False)
compose_trio(PLATE_MH, "triumphant", OUT_TRIUMPHANT, with_burst=True)
make_endcard(OUT_ENDCARD)
print("DONE")
