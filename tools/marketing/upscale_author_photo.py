"""Upscale the author headshot to press-feature print resolution.

Adapts the existing book2 upscaler pattern (07_upscale_to_print.py) for a
PHOTO instead of painterly art. Different prompt anchors + lower creativity
so the model preserves real photo detail instead of reinterpreting features.

  Input:  944 x 787 navy-suit headshot
  Output: ~2832 x 2361 (3x), press-feature-print ready
  Cost:   ~$0.05
"""
import os
from pathlib import Path

import httpx
_o = httpx.Client.__init__
_oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
import warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

import fal_client

HOME = Path(r"C:\Users\chris")
PROJ = Path(r"C:\Users\chris\Squishy-smash\squishy_smash")
SRC = PROJ / "docs" / "marketing" / "press_kit" / "author_photo_944.jpg"
OUT = PROJ / "docs" / "marketing" / "press_kit" / "author_photo_print.jpg"

os.environ["FAL_KEY"] = (HOME / "fal.key.txt").read_text(encoding="utf-8").strip()

# Photo-specific prompt — does NOT push toward painterly. Anchors on real
# photo detail so the model adds sharpness, not reinterpretation.
PROMPT = (
    "professional business headshot photograph, sharp focus, natural skin "
    "texture, realistic photo, business portrait, soft studio lighting, "
    "high detail, high resolution, masterpiece, professional photography, "
    "natural color"
)
NEGATIVE = (
    "(worst quality, low quality, blurry:2), painted, illustration, "
    "cartoon, anime, 3d render, plastic skin, smooth airbrushed skin, "
    "oversharpened, oversaturated, distorted face, extra features, "
    "text, letters, watermark"
)


def upscale(src_path: Path, out_path: Path):
    print(f"Uploading {src_path.name} ({src_path.stat().st_size // 1024} KB)...")
    src_url = fal_client.upload_file(str(src_path))

    print("Calling clarity-upscaler (3x, conservative settings)...")
    result = fal_client.subscribe(
        "fal-ai/clarity-upscaler",
        arguments={
            "image_url": src_url,
            "prompt": PROMPT,
            "negative_prompt": NEGATIVE,
            "upscale_factor": 3,
            "creativity": 0.20,         # low — preserve source detail
            "resemblance": 0.85,        # high — stay close to original
            "num_inference_steps": 30,
            "guidance_scale": 4,
            "tiling_width": 112,
            "tiling_height": 144,
            "enable_safety_checker": False,
        },
        with_logs=True,
        on_queue_update=lambda u: print(f"  status: {getattr(u, 'status', '?')}"),
    )

    out_url = result["image"]["url"]
    print(f"Downloading result from {out_url[:60]}...")
    resp = httpx.get(out_url, timeout=60.0, verify=False)
    resp.raise_for_status()
    out_path.write_bytes(resp.content)

    # Confirm size
    from PIL import Image
    img = Image.open(out_path)
    w, h = img.size
    sz_kb = out_path.stat().st_size // 1024
    print()
    print(f"DONE: {out_path}")
    print(f"  {w} x {h}  ({sz_kb} KB)")
    print(f"  At 300 DPI prints at: {w/300:.2f} x {h/300:.2f} inches")


if __name__ == "__main__":
    upscale(SRC, OUT)
