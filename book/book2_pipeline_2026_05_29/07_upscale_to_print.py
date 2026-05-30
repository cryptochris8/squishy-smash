"""Upscale all 18 final spreads to print resolution.

Uses fal-ai/clarity-upscaler at 4x:
  Input: 1584x672 (~21:9 facing-pair format)
  Output: 6336x2688 (4x scale, plenty for ~17" wide print at 300 DPI)

Conservative settings for painterly art preservation:
  - creativity 0.25 (lower than default 0.35) — preserves source detail
  - resemblance 0.75 (higher than default 0.6) — keeps close to source
  - prompt anchors painterly watercolor style

Cost: ~$0.05/image × 18 = ~$0.90. Wall: ~5-10 min.
"""
import json
import os
import subprocess
import time
from pathlib import Path

import httpx
_o = httpx.Client.__init__
_oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
import warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

import fal_client
from PIL import Image

HOME = Path(r"C:\Users\chris")
PROJ = Path(r"C:\Users\chris\Squishy-smash")
SRC_DIR = PROJ / "book2_final_spreads"
OUT_DIR = PROJ / "book2_final_spreads_print"
OUT_DIR.mkdir(exist_ok=True)
KEY = (HOME / "fal.key.txt").read_text(encoding="utf-8").strip()
os.environ["FAL_KEY"] = KEY

PROMPT = (
    "hand-painted watercolor and gouache picture book illustration, soft "
    "brush strokes, painterly hand-painted texture, paper grain, picture "
    "book for ages 4 to 8, masterpiece, best quality, highres"
)
NEGATIVE = (
    "(worst quality, low quality, normal quality:2), 3d render, plastic, "
    "photoreal, glossy plastic, text, letters, watermark, signature"
)


def upscale(src_path, out_path):
    print(f"  uploading {src_path.name}...")
    src_url = fal_client.upload_file(str(src_path))
    t0 = time.time()
    print(f"  upscaling 4x via clarity-upscaler...")
    response = fal_client.submit(
        "fal-ai/clarity-upscaler",
        arguments={
            "image_url": src_url,
            "upscale_factor": 4,
            "creativity": 0.25,
            "resemblance": 0.75,
            "prompt": PROMPT,
            "negative_prompt": NEGATIVE,
            "num_inference_steps": 18,
            "enable_safety_checker": False,
        },
    ).get()
    dt = int(time.time() - t0)
    print(f"  done in {dt}s")

    # clarity-upscaler returns a single image, not array
    if "image" in response and response["image"].get("url"):
        img_url = response["image"]["url"]
        subprocess.run(
            ["curl", "--ssl-no-revoke", "-sS", "-L", "-o", str(out_path), img_url],
            check=True, timeout=300,
        )
        # Verify output dimensions
        with Image.open(out_path) as img:
            w, h = img.size
        print(f"  saved -> {out_path.name} ({w}x{h}, {out_path.stat().st_size//1024} KB)")
        return True
    else:
        print(f"  !! no image in response: {json.dumps(response)[:300]}")
        return False


# Process all 18 spreads
src_files = sorted(SRC_DIR.glob("spread_*.png"))
print(f">>> Found {len(src_files)} spreads to upscale")
print(f">>> Output dir: {OUT_DIR}\n")

total = time.time()
ok = 0
for src in src_files:
    out = OUT_DIR / src.name
    if out.exists():
        print(f"=== {src.name} ===")
        print(f"  SKIP — already exists")
        ok += 1
        continue
    print(f"=== {src.name} ===")
    if upscale(src, out):
        ok += 1
    print()

print(f"=== ALL DONE in {int(time.time()-total)}s ===")
print(f">>> {ok}/{len(src_files)} upscaled successfully")
print(f">>> Print-resolution finals in {OUT_DIR}")
