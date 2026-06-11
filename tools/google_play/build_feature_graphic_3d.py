"""Feature graphic variant built from the 3D hero renders.

1024x500 Play feature graphic: brand gradient, the three pack mascots
(3D renders) lined up, wordmark + tagline. Companion to
build_play_assets.py's screenshot-based version.

  python build_feature_graphic_3d.py
  -> assets/google_play/feature_graphic_3d_1024x500.png
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO = Path(__file__).resolve().parents[2]
RENDERS = Path(r"C:\Users\chris\Squishy-smash\_tmp_3d_renders")
OUT = REPO / "assets" / "google_play" / "feature_graphic_3d_1024x500.png"
FREDOKA = REPO / "assets" / "google_fonts" / "Fredoka.ttf"

W, H = 1024, 500
LINEUP = ["soft_dumpling", "goo_ball", "mythic_plush_familiar"]

# vertical brand gradient: deep purple -> warm dusk pink
TOP, BOTTOM = (34, 16, 46), (122, 62, 96)

img = Image.new("RGB", (W, H))
px = img.load()
for y in range(H):
    t = y / (H - 1)
    px_row = tuple(int(a + (b - a) * t) for a, b in zip(TOP, BOTTOM))
    for x in range(W):
        px[x, y] = px_row

# soft glow behind the lineup
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse([212, 130, 812, 470], fill=(255, 143, 184, 70))
img.paste(glow.filter(ImageFilter.GaussianBlur(60)), (0, 0), glow)

# the three mascots, center one slightly larger and forward
SIZES = [240, 280, 240]
XS = [180, 512, 844]
for name, size, cx in zip(LINEUP, SIZES, XS):
    hero = Image.open(RENDERS / name / f"{name}_hero_1024.png").convert("RGBA")
    hero = hero.resize((size, size), Image.LANCZOS)
    img.paste(hero, (cx - size // 2, H - size - 40), hero)

draw = ImageDraw.Draw(img)
font_big = ImageFont.truetype(str(FREDOKA), 72)
font_small = ImageFont.truetype(str(FREDOKA), 30)

# wordmark with soft shadow, top-center
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).text((W / 2 + 3, 63), "SQUISHY SMASH", font=font_big, fill=(0, 0, 0, 140), anchor="mm")
img.paste(shadow.filter(ImageFilter.GaussianBlur(5)), (0, 0), shadow)
draw.text((W / 2, 60), "SQUISHY SMASH", font=font_big, fill=(255, 224, 235), anchor="mm")
draw.text((W / 2, 122), "Tap. Squish. Pop. Collect.", font=font_small, fill=(245, 233, 208), anchor="mm")

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT, "PNG", optimize=True)
print(f"OK {OUT}")
