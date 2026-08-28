"""
Build the paid-ad creative set for the Run to Christmas campaign.

Every asset is composited from art we own: the locked Book 2 cover and the
18 reprint spreads. Pure Pillow for the stills, FFmpeg for the video spot.

    python tools/marketing/build_ad_creative.py            # everything
    python tools/marketing/build_ad_creative.py --stills   # skip the video

Output lands in docs/marketing/ad_creative/. Copy lives in
docs/marketing/AD_COPY_LIBRARY.md; the plan is CAMPAIGN_RUN_TO_CHRISTMAS.md.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO = Path(__file__).resolve().parents[2]
SPREADS = REPO / "book" / "book2_final_spreads"
COVER = REPO / "book" / "cover" / "cover_front_book2_composite.png"
OUT = REPO / "docs" / "marketing" / "ad_creative"
MUSIC = Path("C:/Users/chris/Roblox-squishy/marketing/music/music_pudding.mp3")

FONT_SERIF = REPO / "assets" / "google_fonts" / "EBGaramond-Regular.ttf"
FONT_SERIF_IT = REPO / "assets" / "google_fonts" / "EBGaramond-Italic.ttf"
FONT_SANS = REPO / "assets" / "google_fonts" / "Fredoka.ttf"

# Palette pulled off the cover art.
CREAM = (253, 246, 233)
NIGHT = (28, 52, 76)
NIGHT_SOFT = (58, 84, 110)
GOLD = (243, 190, 92)
MUTED = (120, 134, 148)


# ---------------------------------------------------------------- helpers


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(path), size)
    if path == FONT_SANS:
        # Fredoka ships as a variable font; pin a weight when we can.
        try:
            f.set_variation_by_name("SemiBold")
        except Exception:
            pass
    return f


def spread(n: int) -> Image.Image:
    return Image.open(SPREADS / f"spread_{n:02d}.png").convert("RGB")


def cover_art() -> Image.Image:
    return Image.open(COVER).convert("RGB")


def fill(img: Image.Image, size: tuple[int, int], fx: float = 0.5, fy: float = 0.5) -> Image.Image:
    """Cover-crop `img` to `size`, keeping the point (fx, fy) in frame."""
    tw, th = size
    scale = max(tw / img.width, th / img.height)
    im = img.resize((max(tw, int(img.width * scale)), max(th, int(img.height * scale))), Image.LANCZOS)
    x = int((im.width - tw) * fx)
    y = int((im.height - th) * fy)
    return im.crop((x, y, x + tw, y + th))


def scrim(img: Image.Image, frac: float = 0.55, alpha: int = 232, top: bool = False) -> None:
    """Paint a soft bottom (or top) gradient so text stays legible."""
    h = int(img.height * frac)
    grad = Image.new("L", (1, h))
    for i in range(h):
        t = i / max(h - 1, 1)
        v = int(alpha * (t ** 1.7))
        grad.putpixel((0, i if not top else h - 1 - i), v)
    mask = grad.resize((img.width, h), Image.BILINEAR)
    band = Image.new("RGB", (img.width, h), NIGHT)
    img.paste(band, (0, img.height - h if not top else 0), mask)


def wrap(text: str, f: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines, line = [], ""
    for word in text.split():
        probe = f"{line} {word}".strip()
        if f.getlength(probe) <= width or not line:
            line = probe
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def text_block(
    d: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    f: ImageFont.FreeTypeFont,
    fill_color,
    width: int,
    leading: float = 1.18,
    center: bool = False,
    shadow: bool = False,
) -> int:
    """Draw wrapped text; return the y just past the last line."""
    x, y = xy
    step = int(f.size * leading)
    for line in wrap(text, f, width):
        lx = x + (width - f.getlength(line)) / 2 if center else x
        if shadow:
            d.text((lx + 2, y + 3), line, font=f, fill=(0, 0, 0, 90))
        d.text((lx, y), line, font=f, fill=fill_color)
        y += step
    return y


def fit_font(text: str, path: Path, max_size: int, width: int, max_lines: int) -> ImageFont.FreeTypeFont:
    """Largest size at or below max_size that wraps `text` into <= max_lines."""
    size = max_size
    while size > 12:
        f = font(path, size)
        if len(wrap(text, f, width)) <= max_lines:
            return f
        size -= 2
    return font(path, size)


def block_height(text: str, f: ImageFont.FreeTypeFont, width: int, leading: float) -> int:
    return int(f.size * leading) * len(wrap(text, f, width))


def footer(img: Image.Image, margin: int, chip_h: int, light: bool = False) -> int:
    """Cover chip + brand line along the bottom. Returns the footer's top y."""
    w, h = img.size
    chip = book_chip(chip_h)
    top = h - int(h * 0.045) - chip.height
    if img.mode == "RGBA":
        img.alpha_composite(chip, (margin - 26, top))
    else:
        img.paste(chip.convert("RGB"), (margin - 26, top), chip)

    d = ImageDraw.Draw(img)
    tx = margin - 26 + chip.width - 18
    ty = top + int(chip.height * 0.34)
    f_brand = font(FONT_SANS, int(w * 0.030))
    f_sub = font(FONT_SERIF_IT, int(w * 0.032))
    d.text((tx, ty), "SQUISHY SMASH · BOOK TWO", font=f_brand, fill=NIGHT if light else CREAM)
    d.text((tx, ty + int(f_brand.size * 1.55)), "Ages 4–8 · full-color picture book",
           font=f_sub, fill=MUTED if light else (214, 222, 230))
    return top


def book_chip(height: int, border: int = 6) -> Image.Image:
    """The cover as a small product chip with a cream edge and a drop shadow."""
    art = cover_art().resize((height, height), Image.LANCZOS)
    card = Image.new("RGB", (height + border * 2, height + border * 2), CREAM)
    card.paste(art, (border, border))

    pad = 26
    canvas = Image.new("RGBA", (card.width + pad * 2, card.height + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rectangle(
        (pad, pad + 8, pad + card.width, pad + card.height + 8), fill=(12, 24, 38, 130)
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))
    canvas.paste(card, (pad, pad))
    return canvas


def pill(d: ImageDraw.ImageDraw, xy: tuple[int, int], label: str, f: ImageFont.FreeTypeFont,
         bg=GOLD, fg=NIGHT) -> None:
    x, y = xy
    padx, pady = int(f.size * 0.8), int(f.size * 0.45)
    w = int(f.getlength(label)) + padx * 2
    h = int(f.size * 1.35) + pady
    d.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=bg)
    d.text((x + padx, y + pady // 2), label, font=f, fill=fg)


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img.convert("RGB").save(path, quality=92, subsampling=0)
    print(f"  {name:28s} {img.size[0]}x{img.size[1]}")


# ------------------------------------------------------------- ad layouts


def cinematic(size, spread_n, headline, kicker, fx=0.5, fy=0.5, max_lines=3):
    """Full-bleed art, deep bottom scrim, serif headline, brand footer. Meta + Stories."""
    w, h = size
    img = fill(spread(spread_n), size, fx, fy).convert("RGBA")
    scrim(img, frac=0.70, alpha=252)

    margin = int(w * 0.075)
    box = w - margin * 2
    top = footer(img, margin, int(w * 0.17))

    d = ImageDraw.Draw(img)
    f_head = fit_font(headline, FONT_SERIF, int(w * 0.095), box, max_lines)
    f_kick = font(FONT_SANS, int(w * 0.031))

    head_h = block_height(headline, f_head, box, 1.14)
    y = top - int(h * 0.045) - head_h
    pill(d, (margin, y - int(f_kick.size * 2.9)), kicker.upper(), f_kick)
    text_block(d, (margin, y), headline, f_head, CREAM, box, leading=1.14, shadow=True)
    return img


def pin(size, spread_n, title, sub, fx=0.5, fy=0.5):
    """Pinterest: art on top, cream card below with a searchable title."""
    w, h = size
    art_h = int(h * 0.50)
    img = Image.new("RGB", size, CREAM)
    img.paste(fill(spread(spread_n), (w, art_h), fx, fy), (0, 0))

    margin = int(w * 0.085)
    box = w - margin * 2
    top = footer(img, margin, int(w * 0.17), light=True)

    d = ImageDraw.Draw(img)
    f_title = fit_font(title, FONT_SERIF, int(w * 0.086), box, 2)

    y = art_h + int(h * 0.042)
    y = text_block(d, (margin, y), title, f_title, NIGHT, box, leading=1.14)
    y += int(h * 0.022)

    # Shrink the blurb until it genuinely clears the footer -- no overlap, ever.
    room = top - int(h * 0.022) - y
    f_sub = fit_font(sub, FONT_SANS, int(w * 0.034), box, 4)
    while f_sub.size > 14 and block_height(sub, f_sub, box, 1.45) > room:
        f_sub = font(FONT_SANS, f_sub.size - 2)
    text_block(d, (margin, y), sub, f_sub, NIGHT_SOFT, box, leading=1.45)
    return img


def series_ad(size=(1080, 1350)):
    """Cover-forward, both books named. The series is the ads moat."""
    w, h = size
    img = fill(spread(6), size, 0.55, 0.45).convert("RGBA")
    scrim(img, frac=0.66, alpha=250)

    margin = int(w * 0.085)
    box = w - margin * 2
    d = ImageDraw.Draw(img)

    chip = book_chip(int(w * 0.50))
    img.alpha_composite(chip, ((w - chip.width) // 2, int(h * 0.045)))

    f_kick = font(FONT_SANS, int(w * 0.031))
    f_head = font(FONT_SERIF, int(w * 0.084))
    f_body = font(FONT_SANS, int(w * 0.034))

    y = int(h * 0.600)
    pill(d, (margin, y), "TWO BOOKS, ONE WORLD", f_kick)
    y = text_block(d, (margin, y + int(f_kick.size * 2.9)), "Start with one. You'll want both.",
                   f_head, CREAM, box, leading=1.12, shadow=True)
    y += int(h * 0.020)
    y = text_block(
        d, (margin, y),
        "Book 1 is the field guide — 48 squishy friends, one per page. "
        "Book 2 is their first real story.",
        f_body, (228, 234, 240), box, leading=1.5,
    )
    pill(d, (margin, h - int(h * 0.088)), "AGES 4–8  ·  FULL COLOR", font(FONT_SANS, int(w * 0.029)))
    return img


def aplus_banner(size=(970, 600)):
    """Amazon A+ module 1: art left, cream panel right."""
    w, h = size
    img = Image.new("RGB", size, CREAM)
    art_w = int(w * 0.58)
    img.paste(fill(spread(12), (art_w, h), 0.5, 0.45), (0, 0))

    d = ImageDraw.Draw(img)
    x = art_w + int(w * 0.045)
    box = w - x - int(w * 0.05)
    y = int(h * 0.17)

    y = text_block(d, (x, y), "Every pop is a hello.", font(FONT_SERIF, int(w * 0.058)), NIGHT, box, leading=1.1)
    y += int(h * 0.045)
    text_block(
        d, (x, y),
        "A soft storybook world for ages 4 to 8. Three lands, dozens of small friends, "
        "and no villains anywhere in it — built to be read out loud, and to end the day gently.",
        font(FONT_SANS, int(w * 0.0225)), NIGHT_SOFT, box, leading=1.55,
    )
    return img


def aplus_tile(spread_n, caption, fx=0.5, fy=0.5, size=(300, 300)):
    w, h = size
    img = Image.new("RGB", size, CREAM)
    img.paste(fill(spread(spread_n), (w, int(h * 0.74)), fx, fy), (0, 0))
    d = ImageDraw.Draw(img)
    text_block(d, (int(w * 0.06), int(h * 0.79)), caption, font(FONT_SERIF_IT, int(w * 0.062)), NIGHT, int(w * 0.88), leading=1.2)
    return img


# ------------------------------------------------------------------ video


def video_card(size, spread_n, line, fx=0.5, fy=0.5, kicker=None):
    w, h = size
    img = fill(spread(spread_n), size, fx, fy).convert("RGBA")
    scrim(img, frac=0.68, alpha=252)
    d = ImageDraw.Draw(img)
    margin = int(w * 0.09)
    f = font(FONT_SERIF, int(w * 0.082))
    lines = wrap(line, f, w - margin * 2)
    y = h - int(h * 0.13) - int(f.size * 1.15) * len(lines)
    if kicker:
        fk = font(FONT_SANS, int(w * 0.030))
        pill(d, (margin, y - int(fk.size * 3.0)), kicker.upper(), fk)
    text_block(d, (margin, y), line, f, CREAM, w - margin * 2, leading=1.15, shadow=True)
    return img


def end_card(size=(1080, 1920)):
    w, h = size
    img = Image.new("RGB", size, NIGHT)
    art = fill(spread(2), (w, h), 0.5, 0.5)
    img.paste(Image.blend(Image.new("RGB", size, NIGHT), art, 0.35), (0, 0))

    chip = book_chip(int(w * 0.62))
    img.paste(chip.convert("RGB"), ((w - chip.width) // 2, int(h * 0.20)), chip)

    d = ImageDraw.Draw(img)
    y = int(h * 0.70)
    y = text_block(d, (0, y), "Squishy Smash: The Lost Sparkle", font(FONT_SERIF, int(w * 0.062)), CREAM, w, center=True, leading=1.15)
    y += int(h * 0.012)
    y = text_block(d, (0, y), "Ages 4–8 · full-color picture book", font(FONT_SANS, int(w * 0.032)), (206, 216, 226), w, center=True)
    y += int(h * 0.030)
    text_block(d, (0, y), "squishysmash.com", font(FONT_SANS, int(w * 0.044)), GOLD, w, center=True)
    return img


def build_video(out_path: Path) -> bool:
    if not shutil.which("ffmpeg"):
        print("  ffmpeg not on PATH — skipping the video spot")
        return False

    beats = [
        (video_card((1080, 1920), 3, "Three little friends.", 0.18, 0.5, kicker="A bedtime story"), 3.2),
        (video_card((1080, 1920), 5, "Three different worlds.", 0.5, 0.5), 3.2),
        (video_card((1080, 1920), 11, "None of them had ever left home.", 0.5, 0.45), 3.6),
        (video_card((1080, 1920), 12, "None of them had ever met.", 0.5, 0.45), 3.6),
        (video_card((1080, 1920), 18, "A soft place to land.", 0.22, 0.5), 3.4),
        (end_card(), 3.2),
    ]

    tmp = Path(tempfile.mkdtemp(prefix="ss_ad_"))
    try:
        parts = []
        for i, (frame, dur) in enumerate(beats):
            png = tmp / f"beat{i}.png"
            frame.convert("RGB").save(png)
            mp4 = tmp / f"beat{i}.mp4"
            # Slow push-in: scale up 8% over the beat, then crop back to frame.
            zoom = f"zoompan=z='min(zoom+0.0012,1.09)':d={int(dur*30)}:s=1080x1920:fps=30"
            subprocess.run(
                ["ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", str(png),
                 "-t", f"{dur}", "-vf", f"{zoom},format=yuv420p", "-r", "30",
                 "-c:v", "libx264", "-preset", "medium", "-crf", "19", str(mp4)],
                check=True,
            )
            parts.append(mp4)

        listing = tmp / "list.txt"
        listing.write_text("".join(f"file '{p.as_posix()}'\n" for p in parts), encoding="utf-8")

        total = sum(d for _, d in beats)
        cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(listing)]
        if MUSIC.exists():
            cmd += ["-i", str(MUSIC),
                    "-filter_complex", f"[1:a]atrim=0:{total},afade=t=out:st={total-1.5}:d=1.5,volume=0.55[a]",
                    "-map", "0:v", "-map", "[a]", "-c:a", "aac", "-b:a", "160k", "-shortest"]
        cmd += ["-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p", str(out_path)]
        subprocess.run(cmd, check=True)
        print(f"  {out_path.name:28s} 1080x1920  {total:.0f}s"
              f"{'  + owned music' if MUSIC.exists() else '  (silent — music not found)'}")
        return True
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


# ------------------------------------------------------------------- main


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stills", action="store_true", help="skip the video spot")
    args = ap.parse_args()

    for p in (SPREADS, COVER, FONT_SERIF, FONT_SANS):
        if not p.exists():
            print(f"missing required asset: {p}", file=sys.stderr)
            return 1

    OUT.mkdir(parents=True, exist_ok=True)
    print(f"Building ad creative -> {OUT}")

    # Meta
    save(cinematic((1080, 1080), 12, "The one they'll ask you to read again.",
                   "A picture book for ages 4–8", fx=0.5, fy=0.42), "meta_1x1_gift.jpg")
    save(cinematic((1080, 1350), 10, "No villains. No scary parts. A soft place to land.",
                   "Bedtime, ages 4–8", fx=0.5, fy=0.45), "meta_4x5_bedtime.jpg")
    save(series_ad(), "meta_4x5_series.jpg")

    # Stories / Reels / TikTok static
    save(cinematic((1080, 1920), 9, "If your kid loves squishies, this is that feeling in a book.",
                   "Ages 4–8", fx=0.5, fy=0.5), "story_9x16_tease.jpg")

    # Pinterest
    save(pin((1000, 1500), 18,
             "A Gentle Bedtime Picture Book for Ages 4–8",
             "No villains. No scary parts. A soft, quiet ending made for bedtime. "
             "40 pages, full color.", fx=0.28, fy=0.5), "pin_2x3_bedtime.jpg")
    save(pin((1000, 1500), 6,
             "Gift Ideas for a 5-Year-Old Who Loves Squishy Things",
             "A full-color picture book about three little friends being brave together. "
             "Ages 4–8.", fx=0.42, fy=0.5), "pin_2x3_gift.jpg")
    save(pin((1000, 1500), 12,
             "Picture Books About Friendship and Being Brave",
             "Three squishies from three different lands have to find each other first. "
             "Read-aloud, ages 4–8.", fx=0.5, fy=0.45), "pin_2x3_friendship.jpg")

    # Amazon A+
    save(aplus_banner(), "aplus_banner_970.jpg")
    save(aplus_tile(16, "The moment kids join in on.", 0.5, 0.5), "aplus_showcase_1.jpg")
    save(aplus_tile(12, "Three friends, brave together.", 0.5, 0.45), "aplus_showcase_2.jpg")
    save(aplus_tile(18, "The soft landing at the end.", 0.24, 0.5), "aplus_showcase_3.jpg")

    if not args.stills:
        build_video(OUT / "spot_9x16_20s.mp4")

    print("done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
