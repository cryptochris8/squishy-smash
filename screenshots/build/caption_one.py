"""
Caption a SINGLE incoming screenshot with the locked brand treatment,
normalizing it to Apple's 6.7" spec (1290x2796) first.

Reuses every token + the compositor from build_screenshots.py, so the
output is pixel-identical in style to the existing captioned set — just
applied to a new raw capture with a caption passed on the command line.

Usage:
    python screenshots/build/caption_one.py <input> "<caption>" <output.png>
    python screenshots/build/caption_one.py shot.png "Smash to reveal." out.png
    # empty caption -> band + bunny mark only, no text:
    python screenshots/build/caption_one.py shot.png "" out.png
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import build_screenshots as bs  # noqa: E402

TARGET = (1290, 2796)  # 6.7" — Apple uses this class to render all sizes


def fit_target(img: Image.Image) -> Image.Image:
    tw, th = TARGET
    w, h = img.size
    if (w, h) == TARGET:
        return img
    src_ar, tgt_ar = w / h, tw / th
    if abs(src_ar - tgt_ar) < 0.01:
        # Same aspect (any modern 19.5:9 iPhone) — clean resize, no distortion.
        print(f"  resize {w}x{h} -> {tw}x{th} (same aspect)")
        return img.resize(TARGET, Image.LANCZOS)
    # Aspect mismatch (iPad / older device) — scale-to-fill + center-crop so
    # there are no letterbox bars and no stretching. Warn so it's a choice.
    print(f"  WARNING aspect {src_ar:.4f} != {tgt_ar:.4f}; cover-cropping")
    scale = max(tw / w, th / h)
    nw, nh = round(w * scale), round(h * scale)
    img = img.resize((nw, nh), Image.LANCZOS)
    left, top = (nw - tw) // 2, (nh - th) // 2
    return img.crop((left, top, left + tw, top + th))


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__)
        return 2
    inp, caption, outp = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3])

    img = fit_target(Image.open(inp).convert("RGB"))
    tmp = HERE / "_tmp_caption_one.png"
    img.save(tmp, "PNG")

    # Override the filename-based caption lookup with the caption we were given.
    bs.find_caption = lambda name: (caption if caption.strip() else None)
    size = bs.caption_screenshot(tmp, outp)
    tmp.unlink(missing_ok=True)
    print(f"  -> {outp} ({size[0]}x{size[1]})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
