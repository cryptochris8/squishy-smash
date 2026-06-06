"""Build Substack publication branding assets.

Substack publication specs:
  - Logo / avatar: square, 256x256 minimum (we'll do 512 for crispness)
  - Cover image / hero banner: 1500x500 (newsletter header)
  - Post-card image (for shareable posts): 1456x816 (~16:9)
  - About-page hero: same as cover

Outputs to assets/substack/.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "assets" / "substack"
OUT.mkdir(parents=True, exist_ok=True)

ICON_SRC = REPO / "website" / "public" / "icon-512.png"
TRIO_SRC = REPO / "assets" / "website_hero" / "trio_book2_protagonists.png"
COVER_SRC = REPO / "book" / "cover" / "book2_cover_hero_LOCKED.png"
FREDOKA = REPO / "assets" / "google_fonts" / "Fredoka.ttf"

PINK = (244, 179, 208)
DUSK = (59, 42, 77)
CREAM = (255, 248, 230)
GOLD = (226, 168, 95)

# ---------- 1. Logo (square 512x512 opaque) ----------
def build_logo():
    src = Image.open(ICON_SRC).convert("RGBA")
    bg = Image.new("RGB", src.size, PINK)
    bg.paste(src, mask=src.split()[3])
    out = OUT / "logo_512.png"
    bg.save(out, "PNG", optimize=True)
    print(f"logo: {out} {bg.size}")

# ---------- 2. Cover / newsletter header (1500x500) ----------
def build_cover_banner():
    src = Image.open(TRIO_SRC).convert("RGB")
    # 1376x768 -> need 1500x500. Crop to 3:1 aspect first
    target_aspect = 1500 / 500
    sw, sh = src.size
    if sw / sh > target_aspect:
        # wider than target — crop horizontally
        new_w = int(sh * target_aspect)
        left = (sw - new_w) // 2
        cropped = src.crop((left, 0, left + new_w, sh))
    else:
        # taller — crop vertically, bias upward to keep characters in frame
        new_h = int(sw / target_aspect)
        top = (sh - new_h) // 2
        # bias upward so characters stay in lower 2/3
        top = max(0, top - 80)
        cropped = src.crop((0, top, sw, top + new_h))
    img = cropped.resize((1500, 500), Image.LANCZOS)
    out = OUT / "cover_banner_1500x500.png"
    img.save(out, "PNG", optimize=True)
    print(f"cover banner: {out} {img.size}")

# ---------- 3. Post-card image for the first post (1456x816) ----------
# Substack uses this as the share-card og:image. The $11-vs-$20K headline
# is the point — make this scannable in 1.2s.
def build_post01_card():
    # Base: book cover scaled into a dusk-purple field with the price contrast
    img = Image.new("RGB", (1456, 816), DUSK)
    cover = Image.open(COVER_SRC).convert("RGB")
    # Fit cover into right ~40% of canvas
    target_h = 700
    target_w = int(cover.width * target_h / cover.height)
    cover_resized = cover.resize((target_w, target_h), Image.LANCZOS)
    x = 1456 - target_w - 60
    y = (816 - target_h) // 2
    img.paste(cover_resized, (x, y))

    draw = ImageDraw.Draw(img)
    # Headline: $11 vs $20K
    font_big = ImageFont.truetype(str(FREDOKA), 96)
    font_med = ImageFont.truetype(str(FREDOKA), 56)
    font_small = ImageFont.truetype(str(FREDOKA), 32)

    # "I made this picture book for"
    line1 = "I made this picture book for"
    bbox = draw.textbbox((0, 0), line1, font=font_med)
    draw.text((90, 140), line1, font=font_med, fill=CREAM, anchor="ls")

    # "$10.97" - big gold
    line2 = "$10.97"
    bbox = draw.textbbox((0, 0), line2, font=font_big)
    draw.text((92, 260), line2, font=font_big, fill=GOLD, anchor="ls")

    # Subline
    line3 = "Industry baseline: $3,000-$20,000."
    draw.text((92, 360), line3, font=font_med, fill=CREAM, anchor="ls")

    # By line
    line4 = "Here are the 5 pivots that got me there."
    draw.text((92, 460), line4, font=font_med, fill=CREAM, anchor="ls")

    # Byline
    line5 = "by Chris Campbell  |  squishysmash.substack.com"
    draw.text((92, 700), line5, font=font_small, fill=GOLD, anchor="ls")

    out = OUT / "post01_card_1456x816.png"
    img.save(out, "PNG", optimize=True)
    print(f"post 1 share card: {out} {img.size}")

if __name__ == "__main__":
    build_logo()
    build_cover_banner()
    build_post01_card()
    print(f"\nAll Substack assets in: {OUT}")
