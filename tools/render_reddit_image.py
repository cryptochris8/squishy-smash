"""
Render a 1200x1200 hero image for Reddit conversation ads.

Reddit's conversation-ad format shows a square thumbnail next to a
text post. The hero asset has to read at ~200px in feed and still
look correct at full 1200x1200 when expanded. This means:
  - One strong central visual (card cluster), not a wall of detail
  - Wordmark large enough to read at 200px
  - Deep-plum brand bg with the same pink/lavender glow accents as
    the marketing site + X banner so it feels like one brand family

Output: branding/reddit_ad_hero_1200.png + a mirror in
website/public/branding/ for parity with the X banner pattern.

Reuses the same paste_card / make_background helpers spirit as
render_x_banner.py, just resized for square + Reddit's tighter
thumbnail constraint.
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
CARDS_DIR = REPO_ROOT / "assets" / "cards" / "final_48"
FONT_PATH = REPO_ROOT / "assets" / "google_fonts" / "Fredoka.ttf"
OUT_DIRS = [
    REPO_ROOT / "branding",
    REPO_ROOT / "website" / "public" / "branding",
]
OUT_NAME = "reddit_ad_hero_1200.png"

W, H = 1200, 1200

# Brand palette — same hex values as render_x_banner.py
BG_DEEP = (18, 11, 23)       # #120B17
PINK = (255, 143, 184)       # #FF8FB8
CREAM = (255, 211, 110)      # #FFD36E
LAVENDER = (201, 139, 255)   # #C98BFF
JELLY_BLUE = (127, 231, 255) # #7FE7FF
WHITE = (245, 240, 250)


def make_background() -> Image.Image:
    """Deep purple base + radial glows. The square format wants a
    different glow pattern than the wide banner — center-weighted so
    the cluster sits in a soft warm pool."""
    bg = Image.new("RGB", (W, H), BG_DEEP)

    def add_glow(center: tuple[int, int], color: tuple[int, int, int],
                 radius: int, opacity: int) -> None:
        glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(glow)
        cx, cy = center
        d.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            fill=(*color, opacity),
        )
        glow = glow.filter(ImageFilter.GaussianBlur(radius=radius // 4))
        bg.paste(Image.alpha_composite(bg.convert("RGBA"), glow).convert("RGB"))

    # Pink top-left, lavender bottom-right — same diagonal as the X banner
    # so the brand feels coherent across surfaces.
    add_glow((250, 200), PINK, 460, 100)
    add_glow((W - 250, H - 200), LAVENDER, 480, 90)
    add_glow((W // 2, H // 2 + 100), CREAM, 320, 45)
    return bg


def paste_card(canvas: Image.Image, card_path: Path, *,
               cx: int, cy: int, height: int, angle: float,
               glow_color: tuple[int, int, int]) -> None:
    """Same card-stamping helper as render_x_banner.py — lifted verbatim
    so the cards look identical across the X banner and Reddit hero."""
    src = Image.open(card_path).convert("RGBA")
    aspect = src.width / src.height
    target_h = height
    target_w = int(target_h * aspect)
    src = src.resize((target_w, target_h), Image.LANCZOS)

    glow_pad = 36
    glow_canvas = Image.new(
        "RGBA",
        (src.width + glow_pad * 2, src.height + glow_pad * 2),
        (0, 0, 0, 0),
    )
    g = ImageDraw.Draw(glow_canvas)
    g.rounded_rectangle(
        (glow_pad - 6, glow_pad - 6,
         src.width + glow_pad + 6, src.height + glow_pad + 6),
        radius=24, fill=(*glow_color, 140),
    )
    glow_canvas = glow_canvas.filter(ImageFilter.GaussianBlur(radius=22))

    rounded = Image.new("RGBA", (src.width, src.height), (0, 0, 0, 0))
    mask = Image.new("L", (src.width, src.height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, src.width, src.height), radius=22, fill=255
    )
    rounded.paste(src, (0, 0), mask)

    tile = Image.new(
        "RGBA",
        (src.width + glow_pad * 2, src.height + glow_pad * 2),
        (0, 0, 0, 0),
    )
    tile.alpha_composite(glow_canvas)
    tile.alpha_composite(rounded, (glow_pad, glow_pad))
    tile = tile.rotate(angle, resample=Image.BICUBIC, expand=True)

    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(
        tile,
        (cx - tile.width // 2, cy - tile.height // 2),
    )
    canvas.paste(canvas_rgba.convert("RGB"), (0, 0))


def draw_wordmark(canvas: Image.Image) -> None:
    """SQUISHY SMASH stacked, centered horizontally, anchored top.
    Reddit thumbnails (~200px) drop most detail — the wordmark has to
    survive that downscale, so we're using bigger type than the X banner."""
    font_lg = ImageFont.truetype(str(FONT_PATH), 130)
    font_tagline = ImageFont.truetype(str(FONT_PATH), 32)
    font_pill = ImageFont.truetype(str(FONT_PATH), 26)

    text_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(text_layer)

    cx = W // 2

    def centered_text(y: int, text: str, font: ImageFont.FreeTypeFont,
                      fill: tuple[int, int, int, int]) -> int:
        bbox = d.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        d.text((cx - text_w // 2, y), text, font=font, fill=fill)
        return y + (bbox[3] - bbox[1])

    # SQUISHY (pink) over SMASH (cream), tight stack. Top anchored at
    # ~80px so it clears the corner glow and reads from feed thumbnails.
    y = 70
    centered_text(y, "SQUISHY", font_lg, (*PINK, 255))
    centered_text(y + 130, "SMASH", font_lg, (*CREAM, 255))

    # Tagline directly under wordmark
    centered_text(y + 290, "tap · squish · pop · collect 48", font_tagline,
                  (*WHITE, 200))

    # Bottom-right "Now on iOS" pill — the only commercial signal we need.
    pill_text = "  Now on iOS  "
    pill_bbox = d.textbbox((0, 0), pill_text, font=font_pill)
    pill_w = pill_bbox[2] - pill_bbox[0]
    pill_h = pill_bbox[3] - pill_bbox[1]
    pad_x, pad_y = 22, 14
    pill_x = W - pill_w - pad_x * 2 - 60
    pill_y = H - pill_h - pad_y * 2 - 60
    d.rounded_rectangle(
        (pill_x, pill_y,
         pill_x + pill_w + pad_x * 2,
         pill_y + pill_h + pad_y * 2),
        radius=(pill_h + pad_y * 2) // 2,
        fill=(*PINK, 230),
    )
    d.text((pill_x + pad_x, pill_y + pad_y - 4), pill_text.strip(),
           font=font_pill, fill=(*BG_DEEP, 255))

    # Drop shadow for the wordmark only (not the pill, it has its own bg)
    wordmark_only = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    wm_draw = ImageDraw.Draw(wordmark_only)
    bbox_s = wm_draw.textbbox((0, 0), "SQUISHY", font=font_lg)
    sx = cx - (bbox_s[2] - bbox_s[0]) // 2
    wm_draw.text((sx, y), "SQUISHY", font=font_lg, fill=(*PINK, 255))
    bbox_s = wm_draw.textbbox((0, 0), "SMASH", font=font_lg)
    sx = cx - (bbox_s[2] - bbox_s[0]) // 2
    wm_draw.text((sx, y + 130), "SMASH", font=font_lg, fill=(*CREAM, 255))

    shadow_alpha = wordmark_only.split()[3]
    shadow_solid = Image.new("RGBA", wordmark_only.size, (0, 0, 0, 0))
    shadow_solid.putalpha(shadow_alpha)
    shadow_solid = shadow_solid.filter(ImageFilter.GaussianBlur(radius=10))
    shadow_black = Image.new("RGBA", wordmark_only.size, (0, 0, 0, 180))
    shadow_black.putalpha(shadow_solid.split()[3])

    composed = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    composed.paste(shadow_black, (5, 5), shadow_black)
    composed.alpha_composite(text_layer)

    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(composed)
    canvas.paste(canvas_rgba.convert("RGB"), (0, 0))


def main() -> None:
    assert CARDS_DIR.exists(), f"Missing {CARDS_DIR}"
    assert FONT_PATH.exists(), f"Missing {FONT_PATH}"

    canvas = make_background()

    # Card cluster — center-weighted, hero card front+center, two
    # supporting cards angled behind. Picked to span all three packs:
    #   - Foods (Celestial Dumpling Core — mythic pink hero)
    #   - Goo (Singularity Goo Core — lavender)
    #   - Creatures (Mythic Plush Familiar — lavender)
    # plus two supporting commons for variety.
    cy = 720  # cluster vertical anchor — pushes cluster into the bottom 2/3
    cluster = [
        # Back row (smaller, behind, more rotated)
        ("032_Singularity_Goo_Core.webp",   330, cy - 30, 360, -10, LAVENDER),
        ("048_Mythic_Plush_Familiar.webp",  870, cy - 30, 360,  10, LAVENDER),
        # Front-center hero (largest)
        ("016_Celestial_Dumpling_Core.webp", 600, cy + 30, 480,  -2, CREAM),
        # Foreground accents — small commons drift in from edges
        ("014_Crystal_Mochi.webp",          150, cy + 240, 200, -16, PINK),
        ("045_Dream_Eater_Squish.webp",    1050, cy + 240, 200,  16, JELLY_BLUE),
    ]
    for fname, cx, _cy, h, ang, glow in cluster:
        paste_card(canvas, CARDS_DIR / fname, cx=cx, cy=_cy,
                   height=h, angle=ang, glow_color=glow)

    draw_wordmark(canvas)

    for d in OUT_DIRS:
        d.mkdir(parents=True, exist_ok=True)
        # PNG (alpha-flattened RGB — Reddit's ad validator occasionally
        # rejects PNGs with stray alpha channels or embedded ICC profiles).
        out = d / OUT_NAME
        flat = canvas.convert("RGB")
        flat.save(out, "PNG", optimize=True)
        size_kb = out.stat().st_size / 1024
        print(f"  wrote {out.relative_to(REPO_ROOT)} ({size_kb:.0f} KB)")

        # JPEG fallback — Reddit accepts JPG and it's the safest format
        # if a PNG keeps getting rejected. Quality 92 is visually
        # indistinguishable from PNG at this resolution.
        out_jpg = d / OUT_NAME.replace(".png", ".jpg")
        flat.save(out_jpg, "JPEG", quality=92, optimize=True)
        size_kb_jpg = out_jpg.stat().st_size / 1024
        print(f"  wrote {out_jpg.relative_to(REPO_ROOT)} ({size_kb_jpg:.0f} KB)")


if __name__ == "__main__":
    main()
