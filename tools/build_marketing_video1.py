"""
Build Video 1 of the Iceman-night contrast-format drop:
"Everyone tonight at 12: -> Meanwhile in our world: -> gameplay -> end card"

Pure FFmpeg + Pillow. No CapCut. One command, one MP4 out.

Usage:
    python tools/build_marketing_video1.py \
        --recording "C:/Users/chris/Downloads/ScreenRecording_05-15-2026 00-36-30_1.MP4" \
        --start 60 \
        --duration 15

Defaults assume tonight's recording in Downloads. Output lands in
marketing/iceman_video1.mp4 (1080x1920, H.264, ~27s total).
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
LOGO_PATH = REPO_ROOT / "branding" / "logo" / "squishy_smash_logo_primary.png"
ICON_PATH = REPO_ROOT / "branding" / "icon" / "squishy_smash_icon_pink_v1.png"
OUT_DIR = REPO_ROOT / "marketing"
OUT_FILE = OUT_DIR / "iceman_video1.mp4"

W, H = 1080, 1920
FPS = 30
BG = (0, 0, 0)
WHITE = (255, 255, 255)
BRAND_DARK = (18, 11, 23)
ROSE = (227, 169, 174)
CREAM = (245, 232, 210)

FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
FONT_REG = "C:/Windows/Fonts/arial.ttf"


def _font(size: int, regular: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_REG if regular else FONT_BOLD, size)


def _draw_centered(draw: ImageDraw.ImageDraw, text: str, y: int,
                   font: ImageFont.FreeTypeFont, fill=WHITE) -> None:
    bbox = draw.textbbox((0, 0), text, font=font, align="center")
    text_w = bbox[2] - bbox[0]
    draw.text(((W - text_w) // 2, y), text, font=font, fill=fill,
              align="center")


def card_opening() -> Image.Image:
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "Everyone tonight", H // 2 - 180, _font(96))
    _draw_centered(draw, "at 12:", H // 2 - 60, _font(96))
    return img


def card_clock() -> Image.Image:
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "11:59 PM", H // 2 - 110, _font(220))
    return img


def card_meanwhile() -> Image.Image:
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    _draw_centered(draw, "Meanwhile,", H // 2 - 180, _font(96))
    _draw_centered(draw, "in our world:", H // 2 - 60, _font(96))
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
                   H // 2 + 220, _font(64), fill=WHITE)
    _draw_centered(draw, "on the App Store",
                   H // 2 + 300, _font(56, regular=True), fill=ROSE)
    if ICON_PATH.exists():
        icon = Image.open(ICON_PATH).convert("RGBA")
        icon = icon.resize((180, 180), Image.LANCZOS)
        img.paste(icon, ((W - icon.width) // 2, H // 2 + 410), icon)
    _draw_centered(draw, "squishysmash.com",
                   H // 2 + 640, _font(38, regular=True), fill=CREAM)
    return img


def _run(cmd: list[str]) -> None:
    print("  $", " ".join(f'"{c}"' if " " in c else c for c in cmd))
    subprocess.run(cmd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


def image_to_clip(img: Image.Image, seconds: float, out: Path) -> None:
    """Render a still image as a silent H.264 video for `seconds`."""
    png_path = out.with_suffix(".png")
    img.save(png_path)
    _run([
        "ffmpeg", "-y",
        "-loop", "1", "-framerate", str(FPS),
        "-t", f"{seconds}",
        "-i", str(png_path),
        "-f", "lavfi", "-t", f"{seconds}",
        "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-vf", f"scale={W}:{H}:flags=lanczos,format=yuv420p",
        "-c:v", "libx264", "-preset", "medium", "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "128k",
        "-r", str(FPS),
        str(out),
    ])
    png_path.unlink(missing_ok=True)


def trim_gameplay(recording: Path, start: float, duration: float,
                  out: Path) -> None:
    """Pull `duration` sec starting at `start`, center-crop 9:16,
    re-encode to H.264 + AAC."""
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
          out: Path) -> None:
    if not recording.exists():
        sys.exit(f"Recording not found: {recording}")
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg not on PATH")
    out.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="iceman_v1_") as tdir:
        tdir = Path(tdir)
        c1 = tdir / "01_opening.mp4"
        c2 = tdir / "02_clock.mp4"
        c3 = tdir / "03_meanwhile.mp4"
        c4 = tdir / "04_gameplay.mp4"
        c5 = tdir / "05_end.mp4"

        print("[1/5] opening card (3s)")
        image_to_clip(card_opening(), 3.0, c1)
        print("[2/5] clock card (3s)")
        image_to_clip(card_clock(), 3.0, c2)
        print("[3/5] meanwhile card (2s)")
        image_to_clip(card_meanwhile(), 2.0, c3)
        print(f"[4/5] gameplay trim ({gameplay_dur}s from {start}s)")
        trim_gameplay(recording, start, gameplay_dur, c4)
        print("[5/5] end card (4s)")
        image_to_clip(card_end(), 4.0, c5)

        print(f"\nconcat -> {out}")
        concat_clips([c1, c2, c3, c4, c5], out)

    size_mb = out.stat().st_size / 1024 / 1024
    total = 3 + 3 + 2 + gameplay_dur + 4
    print(f"\nWrote {out}")
    print(f"  duration: {total:.1f}s")
    print(f"  size:     {size_mb:.1f} MB")
    print(f"  format:   {W}x{H} @ {FPS}fps H.264")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--recording", type=Path, default=DEFAULT_RECORDING,
                   help="Path to iPhone screen recording")
    p.add_argument("--start", type=float, default=60.0,
                   help="Start offset in seconds for the gameplay slice")
    p.add_argument("--duration", type=float, default=15.0,
                   help="Gameplay slice length in seconds")
    p.add_argument("--out", type=Path, default=OUT_FILE)
    args = p.parse_args()
    build(args.recording, args.start, args.duration, args.out)


if __name__ == "__main__":
    main()
