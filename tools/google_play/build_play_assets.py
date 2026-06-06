"""Build Google Play Console submission assets in one pass.

Outputs to assets/google_play/:
  icon_512.png                  — 512x512 opaque, flattened on Squishy pink
  feature_graphic_1024x500.png  — pack_squishy_foods.png cropped + wordmark
  screenshots/*.png             — iOS captioned shots padded to 9:16 (Play max)
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "assets" / "google_play"
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "screenshots").mkdir(exist_ok=True)

# ---------- 1. ICON 512x512 OPAQUE ----------
SQUISHY_PINK = (244, 179, 208)  # soft brand pink fills the rounded-corner void

def build_icon():
    src = Image.open(REPO / "website" / "public" / "icon-512.png").convert("RGBA")
    bg = Image.new("RGB", src.size, SQUISHY_PINK)
    bg.paste(src, mask=src.split()[3])
    out = OUT / "icon_512.png"
    bg.save(out, "PNG", optimize=True)
    print(f"icon: {out} {bg.size}")

# ---------- 2. FEATURE GRAPHIC 1024x500 ----------
FREDOKA = REPO / "assets" / "google_fonts" / "Fredoka.ttf"

def build_feature_graphic():
    src = Image.open(REPO / "assets" / "website_hero" / "pack_squishy_foods.png").convert("RGB")
    # crop 1376x768 to 2.048:1 (1024:500) - center crop the height
    target_aspect = 1024 / 500
    src_aspect = src.width / src.height
    if src_aspect < target_aspect:
        # source is taller than target — crop height
        new_h = int(src.width / target_aspect)
        top = (src.height - new_h) // 2
        # bias upward slightly so the sky stays visible (characters are in lower 2/3)
        top = max(0, top - 40)
        src = src.crop((0, top, src.width, top + new_h))
    else:
        new_w = int(src.height * target_aspect)
        left = (src.width - new_w) // 2
        src = src.crop((left, 0, left + new_w, src.height))
    img = src.resize((1024, 500), Image.LANCZOS)

    # Wordmark — bottom-left, soft drop shadow for legibility on warm sky.
    # Use anchor "ls" (left-baseline) so x/y refer to the visual start of the
    # text, not the font bbox origin — earlier version cropped the first
    # letter because the bbox.left offset wasn't compensated for.
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(str(FREDOKA), 64)
    text = "SQUISHY SMASH"
    x = 40
    y = 500 - 40  # baseline 40px above the bottom

    # Soft shadow layer (blurred)
    shadow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    for off in [(3, 3), (2, 4), (4, 2)]:
        sd.text((x + off[0], y + off[1]), text, font=font, fill=(0, 0, 0, 110), anchor="ls")
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=5))
    img = img.convert("RGBA")
    img.alpha_composite(shadow_layer)

    # Wordmark itself — cream white
    draw = ImageDraw.Draw(img)
    draw.text((x, y), text, font=font, fill=(255, 248, 238, 255), anchor="ls")

    out = OUT / "feature_graphic_1024x500.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    print(f"feature graphic: {out} {img.size}")

# ---------- 3. SCREENSHOTS 9:16 MAX ----------
PHONE_BLACK = (8, 6, 18)  # matches the in-game deep purple-black

def pad_to_9_16(src_path: Path, out_path: Path):
    src = Image.open(src_path).convert("RGB")
    w, h = src.size
    target_w = int(round(h * 9 / 16))  # what width SHOULD be at 9:16
    if w >= target_w:
        # already wide enough — no padding needed
        src.save(out_path, "PNG", optimize=True)
        return src.size
    canvas = Image.new("RGB", (target_w, h), PHONE_BLACK)
    pad = (target_w - w) // 2
    canvas.paste(src, (pad, 0))
    canvas.save(out_path, "PNG", optimize=True)
    return canvas.size

def build_screenshots():
    src_dir = REPO / "screenshots" / "captioned"
    files = sorted(src_dir.glob("*.PNG"))
    for f in files:
        out = OUT / "screenshots" / f.name.lower().replace(".png", "_play.png")
        size = pad_to_9_16(f, out)
        ratio = size[1] / size[0]
        print(f"  {f.name} -> {size} (ratio {ratio:.3f}, target <= 1.778)")

if __name__ == "__main__":
    build_icon()
    build_feature_graphic()
    print("screenshots:")
    build_screenshots()
    print(f"\nAll assets in: {OUT}")
