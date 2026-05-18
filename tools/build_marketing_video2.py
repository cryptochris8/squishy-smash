"""
Build Video 2 of the Iceman-night contrast-format drop:
album-announcement parody -> "Forty-eight tracks. No features. Just squish."

Pure FFmpeg + Pillow. No CapCut. One command, one MP4 out.

Usage:
    python tools/build_marketing_video2.py \
        --recording "C:/Users/chris/Downloads/ScreenRecording_05-15-2026 00-36-30_1.MP4" \
        --vo "assets/audio/marketing/vo_marketing_iceman_01_tracks_adam.mp3" \
        --start 100

If --vo is omitted, the punchline beat plays silently (still readable
via the caption overlay). Drop the real Adam clip in once it's rendered
and re-run.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RECORDING = Path(
    "C:/Users/chris/Downloads/ScreenRecording_05-15-2026 00-36-30_1.MP4"
)
ALBUM_COVER = REPO_ROOT / "assets" / "images" / "soft_album_cover.png"
LOGO_PATH = REPO_ROOT / "branding" / "logo" / "squishy_smash_logo_primary.png"
ICON_PATH = REPO_ROOT / "branding" / "icon" / "squishy_smash_icon_pink_v1.png"
OUT_DIR = REPO_ROOT / "marketing"
OUT_FILE = OUT_DIR / "iceman_video2.mp4"
DEFAULT_VO = (REPO_ROOT / "assets" / "audio" / "marketing"
              / "vo_marketing_iceman_01_tracks_adam.mp3")

W, H = 1080, 1920
FPS = 30
BG_BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
BRAND_DARK = (18, 11, 23)
CREAM = (245, 232, 210)
ROSE = (227, 169, 174)

FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
FONT_REG = "C:/Windows/Fonts/arial.ttf"


def _font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def _draw_centered(draw: ImageDraw.ImageDraw, text: str, y: int,
                   font: ImageFont.FreeTypeFont, fill=WHITE) -> None:
    bbox = draw.textbbox((0, 0), text, font=font, align="center")
    text_w = bbox[2] - bbox[0]
    draw.text(((W - text_w) // 2, y), text, font=font, fill=fill,
              align="center")


def card_tonight() -> Image.Image:
    """Drake-album-poster vibe: white text on black, all caps, deadpan."""
    img = Image.new("RGB", (W, H), BG_BLACK)
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "TONIGHT", H // 2 - 200, _font(FONT_BOLD, 180))
    _draw_centered(draw, "AT MIDNIGHT", H // 2 + 10, _font(FONT_BOLD, 140))
    return img


def card_album() -> Image.Image:
    """Album cover full-frame with title + artist text overlay below."""
    img = Image.new("RGB", (W, H), BG_BLACK)
    if ALBUM_COVER.exists():
        cover = Image.open(ALBUM_COVER).convert("RGBA")
        target = int(W * 0.85)
        cover = cover.resize((target, target), Image.LANCZOS)
        cover_y = (H - cover.height) // 2 - 220
        img.paste(cover, ((W - cover.width) // 2, cover_y), cover)
        text_y = cover_y + cover.height + 70
    else:
        text_y = H // 2 + 200
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "SOFT", text_y, _font(FONT_BOLD, 130), fill=WHITE)
    _draw_centered(draw, "Squishy Smash", text_y + 160,
                   _font(FONT_REG, 56), fill=CREAM)
    _draw_centered(draw, "PLAYING NOWHERE", text_y + 240,
                   _font(FONT_BOLD, 44), fill=ROSE)
    return img


def card_tracklist() -> Image.Image:
    """Three columns of 16 tracks, all named 'Squish'. Joke = uniformity."""
    img = Image.new("RGB", (W, H), BRAND_DARK)
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "TRACKLIST", 130, _font(FONT_BOLD, 90), fill=WHITE)
    _draw_centered(draw, "SOFT", 230, _font(FONT_REG, 42), fill=ROSE)

    body_font = _font(FONT_REG, 38)
    num_font = _font(FONT_BOLD, 38)
    list_top = 380
    line_h = 78
    col_w = (W - 120) // 3
    for col in range(3):
        x_num = 60 + col * col_w + 10
        x_text = x_num + 70
        for row in range(16):
            n = col * 16 + row + 1
            y = list_top + row * line_h
            draw.text((x_num, y), f"{n:02d}", font=num_font, fill=CREAM)
            draw.text((x_text, y), "Squish", font=body_font, fill=WHITE)
    return img


def card_punchline() -> Image.Image:
    """Hold on album cover behind a darkened overlay, big caption.
    This is the beat the VO ('Forty-eight tracks. No features. Just squish.')
    lands on — caption keeps the joke legible if audio is muted."""
    img = Image.new("RGB", (W, H), BG_BLACK)
    if ALBUM_COVER.exists():
        cover = Image.open(ALBUM_COVER).convert("RGBA")
        cover = cover.resize((W, W), Image.LANCZOS)
        cover_y = (H - cover.height) // 2
        # Darken cover so caption text reads cleanly on top.
        dim = Image.new("RGBA", cover.size, (0, 0, 0, 110))
        cover.alpha_composite(dim)
        img.paste(cover, (0, cover_y), cover)
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "48 tracks.",      H // 2 - 200, _font(FONT_BOLD, 110))
    _draw_centered(draw, "No features.",    H // 2 - 60,  _font(FONT_BOLD, 110))
    _draw_centered(draw, "Just squish.",    H // 2 + 80,  _font(FONT_BOLD, 110),
                   fill=ROSE)
    return img


def card_end() -> Image.Image:
    img = Image.new("RGB", (W, H), BRAND_DARK)
    if LOGO_PATH.exists():
        logo = Image.open(LOGO_PATH).convert("RGBA")
        target_w = int(W * 0.72)
        ratio = target_w / logo.width
        logo = logo.resize((target_w, int(logo.height * ratio)),
                           Image.LANCZOS)
        logo_y = (H - logo.height) // 2 - 260
        img.paste(logo, ((W - logo.width) // 2, logo_y), logo)
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "Search “Squishy Smash”",
                   H // 2 + 220, _font(FONT_BOLD, 64), fill=WHITE)
    _draw_centered(draw, "on the App Store",
                   H // 2 + 300, _font(FONT_REG, 56), fill=ROSE)
    if ICON_PATH.exists():
        icon = Image.open(ICON_PATH).convert("RGBA")
        icon = icon.resize((180, 180), Image.LANCZOS)
        img.paste(icon, ((W - icon.width) // 2, H // 2 + 410), icon)
    _draw_centered(draw, "squishysmash.com",
                   H // 2 + 640, _font(FONT_REG, 38), fill=CREAM)
    return img


def _run(cmd: list[str]) -> None:
    print("  $", " ".join(f'"{c}"' if " " in c else c for c in cmd))
    subprocess.run(cmd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


def image_to_clip(img: Image.Image, seconds: float, out: Path,
                  audio: Path | None = None) -> None:
    """Render a still image as an H.264 video for `seconds`. If `audio`
    is given, mux it (padded/trimmed to fit); otherwise emit silence."""
    png_path = out.with_suffix(".png")
    img.save(png_path)
    cmd = ["ffmpeg", "-y",
           "-loop", "1", "-framerate", str(FPS),
           "-t", f"{seconds}",
           "-i", str(png_path)]
    if audio:
        cmd += ["-i", str(audio),
                "-af", f"apad=whole_dur={seconds}",
                "-shortest"]
    else:
        cmd += ["-f", "lavfi", "-t", f"{seconds}",
                "-i", "anullsrc=channel_layout=stereo:sample_rate=44100"]
    cmd += [
        "-vf", f"scale={W}:{H}:flags=lanczos,format=yuv420p",
        "-c:v", "libx264", "-preset", "medium", "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "192k",
        "-ar", "44100", "-ac", "2",
        "-t", f"{seconds}",
        "-r", str(FPS),
        str(out),
    ]
    _run(cmd)
    png_path.unlink(missing_ok=True)


def trim_gameplay(recording: Path, start: float, duration: float,
                  out: Path) -> None:
    _run([
        "ffmpeg", "-y",
        "-ss", f"{start}",
        "-i", str(recording),
        "-t", f"{duration}",
        "-vf",
        f"scale={W}:-2:flags=lanczos,crop={W}:{H},format=yuv420p",
        "-r", str(FPS),
        "-c:v", "libx264", "-preset", "medium", "-crf", "20",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "192k",
        "-ar", "44100", "-ac", "2",
        str(out),
    ])


def concat_clips(clips: list[Path], out: Path) -> None:
    list_file = out.with_suffix(".txt")
    list_file.write_text(
        "\n".join(f"file '{c.as_posix()}'" for c in clips),
        encoding="utf-8",
    )
    _run([
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0",
        "-i", str(list_file),
        "-c", "copy",
        str(out),
    ])
    list_file.unlink(missing_ok=True)


def build(recording: Path, start: float, gameplay_dur: float,
          vo: Path | None, out: Path) -> None:
    if not recording.exists():
        sys.exit(f"Recording not found: {recording}")
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg not on PATH")
    if vo and not vo.exists():
        print(f"  ! VO file {vo} not found — falling back to silent punchline")
        vo = None
    out.parent.mkdir(parents=True, exist_ok=True)

    # Timeline: 27s total
    # 0:00-0:03 TONIGHT AT MIDNIGHT   (3s)
    # 0:03-0:08 album cover hold       (5s)
    # 0:08-0:14 tracklist              (6s)
    # 0:14-0:19 punchline + VO         (5s)  <- VO drops here
    # 0:19-0:23 gameplay flash         (4s)
    # 0:23-0:27 end card               (4s)

    with tempfile.TemporaryDirectory(prefix="iceman_v2_") as tdir:
        tdir = Path(tdir)
        c1 = tdir / "01_tonight.mp4"
        c2 = tdir / "02_album.mp4"
        c3 = tdir / "03_tracklist.mp4"
        c4 = tdir / "04_punchline.mp4"
        c5 = tdir / "05_gameplay.mp4"
        c6 = tdir / "06_end.mp4"

        print("[1/6] TONIGHT AT MIDNIGHT (3s)")
        image_to_clip(card_tonight(), 3.0, c1)
        print("[2/6] album cover (5s)")
        image_to_clip(card_album(), 5.0, c2)
        print("[3/6] tracklist (6s)")
        image_to_clip(card_tracklist(), 6.0, c3)
        print(f"[4/6] punchline (5s) — VO: {vo if vo else 'silent'}")
        image_to_clip(card_punchline(), 5.0, c4, audio=vo)
        print(f"[5/6] gameplay flash ({gameplay_dur}s from {start}s)")
        trim_gameplay(recording, start, gameplay_dur, c5)
        print("[6/6] end card (4s)")
        image_to_clip(card_end(), 4.0, c6)

        print(f"\nconcat -> {out}")
        concat_clips([c1, c2, c3, c4, c5, c6], out)

    size_mb = out.stat().st_size / 1024 / 1024
    total = 3 + 5 + 6 + 5 + gameplay_dur + 4
    print(f"\nWrote {out}")
    print(f"  duration: {total:.1f}s")
    print(f"  size:     {size_mb:.1f} MB")
    print(f"  format:   {W}x{H} @ {FPS}fps H.264")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--recording", type=Path, default=DEFAULT_RECORDING)
    p.add_argument("--vo", type=Path, default=DEFAULT_VO,
                   help="Adam-voice MP3 for the punchline (silent if missing)")
    p.add_argument("--start", type=float, default=100.0,
                   help="Start offset (sec) for gameplay flash slice")
    p.add_argument("--duration", type=float, default=4.0,
                   help="Gameplay flash slice length (sec) — short on purpose")
    p.add_argument("--out", type=Path, default=OUT_FILE)
    args = p.parse_args()
    build(args.recording, args.start, args.duration, args.vo, args.out)


if __name__ == "__main__":
    main()
