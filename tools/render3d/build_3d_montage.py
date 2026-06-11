"""Build the 'Meet the Squishies in 3D' vertical montage (store preview / TikTok).

Five spin segments (1.6 s each) + brand end card = ~9.5 s at 1080x1920.
Consumes the composited vertical frames produced by assemble_turntable.py
(runs it implicitly if a character hasn't been composited yet) and the
Fredoka brand font for the end card.

  python build_3d_montage.py
  -> C:/Users/chris/squishy_turntables/squishy_3d_montage_vertical.mp4
"""

import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RENDERS = Path(r"C:\Users\chris\Squishy-smash\_tmp_3d_renders")
REPO = Path(__file__).resolve().parents[2]
OUT = Path(r"C:\Users\chris\squishy_turntables")
FPS = 30
SEG_FRAMES = 48  # 1.6 s of each spin
LINEUP = [
    "soft_dumpling",
    "goo_ball",
    "galaxy_dumpling",
    "mythic_plush_familiar",
    "celestial_dumpling_core",
]
W, H = 1080, 1920


def ensure_composited(name: str) -> Path:
    d = RENDERS / name / "composited" / "vertical"
    if not list(d.glob("f_*.png")):
        print(f"[montage] compositing {name} first...")
        subprocess.run(
            [sys.executable, str(Path(__file__).parent / "assemble_turntable.py"), name],
            check=True,
        )
    return d


def build_end_card() -> Path:
    """Brand end card: deep purple, wordmark, CTA."""
    card = Image.new("RGB", (W, H), (34, 16, 46))
    draw = ImageDraw.Draw(card)
    font_big = ImageFont.truetype(str(REPO / "assets" / "google_fonts" / "Fredoka.ttf"), 110)
    font_mid = ImageFont.truetype(str(REPO / "assets" / "google_fonts" / "Fredoka.ttf"), 56)
    draw.text((W / 2, H * 0.42), "SQUISHY SMASH", font=font_big, fill=(255, 143, 184), anchor="mm")
    draw.text((W / 2, H * 0.52), "Tap. Squish. Pop. Collect.", font=font_mid, fill=(245, 233, 208), anchor="mm")
    draw.text((W / 2, H * 0.62), "Free on iPhone", font=font_mid, fill=(127, 231, 255), anchor="mm")
    p = OUT / "_end_card.png"
    p.parent.mkdir(exist_ok=True)
    card.save(p)
    return p


def main():
    OUT.mkdir(exist_ok=True)
    inputs, filters = [], []
    for i, name in enumerate(LINEUP):
        d = ensure_composited(name)
        inputs += ["-framerate", str(FPS), "-i", str(d / "f_%04d.png")]
        filters.append(f"[{i}:v]trim=end_frame={SEG_FRAMES},setpts=PTS-STARTPTS[v{i}]")
    end_card = build_end_card()
    inputs += ["-loop", "1", "-t", "2.2", "-i", str(end_card)]
    n = len(LINEUP)
    filters.append(f"[{n}:v]format=yuv420p,fps={FPS}[v{n}]")
    concat = "".join(f"[v{i}]" for i in range(n + 1)) + f"concat=n={n + 1}:v=1:a=0[out]"
    filters.append(concat)

    out_mp4 = OUT / "squishy_3d_montage_vertical.mp4"
    cmd = (
        ["ffmpeg", "-y"]
        + inputs
        + ["-filter_complex", ";".join(filters), "-map", "[out]",
           "-c:v", "libx264", "-preset", "medium", "-crf", "19",
           "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(out_mp4)]
    )
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        raise SystemExit(f"ffmpeg failed: {r.stderr[-600:]}")
    print(f"OK {out_mp4}")


main()
