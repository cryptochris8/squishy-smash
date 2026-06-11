"""Assemble Blender turntable frames into branded spin videos.

Takes the transparent-bg PNG sequence from blender_render_squishy.py and
composites it over a pack-colored pastel radial gradient with a soft floor
shadow, then encodes square (1080x1080) and vertical (1080x1920) MP4 loops
with ffmpeg.

  python assemble_turntable.py soft_dumpling [goo_ball ...]
  python assemble_turntable.py --all

Outputs land OUTSIDE the repo at C:/Users/chris/squishy_turntables/.
"""

import math
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

RENDERS = Path(r"C:\Users\chris\Squishy-smash\_tmp_3d_renders")
CARDS = Path(r"C:\Users\chris\Squishy-smash\squishy_smash\assets\cards\final_48")
OUT = Path(r"C:\Users\chris\squishy_turntables")
FPS = 30
LOOPS = 3  # 60 frames @ 30fps = 2s per revolution; 3 loops = 6s clip

# pack palettes (center, edge) — Squishy Foods / Goo & Fidgets / Creepy-Cute
PACK_BG = {
    "foods": ((255, 233, 214), (255, 183, 197)),
    "goo": ((217, 250, 244), (148, 216, 233)),
    "creepy": ((237, 226, 255), (183, 167, 226)),
}


def pack_for(name: str) -> str:
    """Friend id -> pack, via the card number in assets/cards/final_48."""
    want = name.replace("_", " ").lower()
    for f in CARDS.glob("*.webp"):
        m = re.match(r"(\d+)_(.+)\.webp", f.name)
        if m and m.group(2).replace("_", " ").lower() == want:
            n = int(m.group(1))
            return "foods" if n <= 16 else ("goo" if n <= 32 else "creepy")
    return "foods"


_BG_CACHE: dict = {}


def background(w: int, h: int, pack: str, model_px: int, model_cy: float) -> Image.Image:
    """Radial pastel gradient + soft floor-shadow ellipse under the model."""
    cache_key = (w, h, pack, model_px, round(model_cy))
    if cache_key in _BG_CACHE:
        return _BG_CACHE[cache_key]
    center, edge = PACK_BG[pack]
    bg = Image.new("RGB", (w, h))
    px = bg.load()
    cx, cy = w / 2, h * 0.42
    max_d = math.hypot(max(cx, w - cx), max(cy, h - cy))
    for y in range(h):
        for x in range(w):
            t = min(1.0, math.hypot(x - cx, y - cy) / max_d)
            t = t * t * (3 - 2 * t)  # smoothstep
            px[x, y] = tuple(int(c + (e - c) * t) for c, e in zip(center, edge))

    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    sy = int(model_cy + model_px * 0.34)
    sw, sh = int(model_px * 0.42), int(model_px * 0.07)
    d.ellipse([w // 2 - sw, sy - sh, w // 2 + sw, sy + sh], fill=(70, 40, 60, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(model_px * 0.025))
    bg.paste(shadow, (0, 0), shadow)
    _BG_CACHE[cache_key] = bg
    return bg


def assemble(name: str) -> bool:
    frames_dir = RENDERS / name / "turntable"
    frames = sorted(frames_dir.glob(f"{name}_*.png"))
    if not frames:
        print(f"!! no turntable frames for {name}")
        return False

    OUT.mkdir(exist_ok=True)
    work = RENDERS / name / "composited"
    pack = pack_for(name)

    for label, (w, h, scale) in {
        "square": (1080, 1080, 0.92),
        "vertical": (1080, 1920, 0.86),
    }.items():
        wdir = work / label
        wdir.mkdir(parents=True, exist_ok=True)
        model_px = int(min(w, h) * scale)
        cy = h * (0.40 if label == "vertical" else 0.46)
        bg = background(w, h, pack, model_px, cy)
        for i, f in enumerate(frames, 1):
            frame = Image.open(f).convert("RGBA")
            frame = frame.resize((model_px, model_px), Image.LANCZOS)
            page = bg.copy()
            page.paste(frame, (int(w / 2 - model_px / 2), int(cy - model_px / 2)), frame)
            page.save(wdir / f"f_{i:04d}.png")

        out_mp4 = OUT / f"{name}_spin_{label}.mp4"
        cmd = [
            "ffmpeg", "-y",
            "-stream_loop", str(LOOPS - 1),
            "-framerate", str(FPS),
            "-i", str(wdir / "f_%04d.png"),
            "-c:v", "libx264", "-preset", "medium", "-crf", "19",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            str(out_mp4),
        ]
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
        if r.returncode != 0:
            print(f"!! ffmpeg failed for {name} {label}: {r.stderr[-400:]}")
            return False
        print(f"OK {out_mp4}")
    return True


def main():
    names = sys.argv[1:]
    if names == ["--all"]:
        names = sorted(p.name for p in RENDERS.iterdir() if (p / "turntable").is_dir())
    if not names:
        raise SystemExit("usage: assemble_turntable.py <friend_id> [...] | --all")
    ok = sum(assemble(n) for n in names)
    print(f"DONE {ok}/{len(names)}")


main()
