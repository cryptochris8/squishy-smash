"""First Nano Banana Pro API test — Soft Dumpling sleeping pose.

Uses Gemini 3 Pro Image Preview (the highest-quality variant per agent
research). Multi-image reference input: 3 SD canon refs + text prompt.

Cost: ~$0.13 for one image. If it lands clean, we have our pipeline
validated end-to-end with API access.
"""
import os
import time
from pathlib import Path

# Schannel SSL workaround — patch httpx before SDK import
import httpx
_o = httpx.Client.__init__
_oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
import warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

import PIL.Image
from google import genai
from google.genai import types

HOME = Path(r"C:\Users\chris")
PROJ = Path(r"C:\Users\chris\Squishy-smash")
WINNERS = PROJ / "_tmp_mj_winners"
OUT_DIR = PROJ / "_tmp_nano_banana_test"
OUT_DIR.mkdir(exist_ok=True)

KEY = (HOME / "gemini.key.txt").read_text(encoding="utf-8").strip()

# Three Soft Dumpling canonical references
SD_REFS = [
    WINNERS / "01_dumpling_neutral.png",
    WINNERS / "02_dumping_triamphunt.png",
    WINNERS / "03_dumpling_walking.png",
]

PROMPT = (
    "The three attached images show the same plush character — \"Soft "
    "Dumpling\" — a peach-pink round egg-shaped plush dumpling with a "
    "small curl tuft on top of her head. She has soft cheek blush, two "
    "small dot eyes, and a gentle smile. She has NO ears (she is NOT a "
    "bunny). Her arms are soft round nubs with NO fingers or hands. Her "
    "color is consistently peach-pink across all references.\n\n"
    "Generate a single new image showing THIS EXACT CHARACTER in a new "
    "pose: sleeping peacefully curled up on a soft pillow. Hand-painted "
    "watercolor storybook illustration style. Soft brush strokes, "
    "painterly texture. Picture book aesthetic for ages 4 to 8.\n\n"
    "Preserve her exact appearance: same peach-pink color, same round "
    "egg shape, same small curl tuft, same dot eyes, same cheek blush, "
    "NO ears, NO fingers. The character must be recognizably the same "
    "plush dumpling shown in the reference images.\n\n"
    "White background, no text in the image."
)

print(">>> Loading reference images...")
ref_imgs = [PIL.Image.open(p) for p in SD_REFS]
for i, (p, img) in enumerate(zip(SD_REFS, ref_imgs), 1):
    print(f"  ref{i}: {p.name} ({img.size})")

print(">>> Initializing Gemini client...")
client = genai.Client(api_key=KEY)

print(">>> Calling Gemini 3 Pro Image Preview...")
t0 = time.time()
response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=[PROMPT, *ref_imgs],
)
dt = int(time.time() - t0)
print(f"    done in {dt}s")

# Save any generated images
print(">>> Inspecting response...")
saved = 0
for i, cand in enumerate(response.candidates or []):
    if not cand.content or not cand.content.parts:
        continue
    for j, part in enumerate(cand.content.parts):
        if part.inline_data and part.inline_data.data:
            mime = part.inline_data.mime_type or "image/png"
            ext = "png" if "png" in mime else "jpg"
            out = OUT_DIR / f"sd_sleeping_test_c{i}_p{j}.{ext}"
            out.write_bytes(part.inline_data.data)
            print(f"    saved -> {out.name} ({len(part.inline_data.data)} bytes)")
            saved += 1
        elif part.text:
            print(f"    text: {part.text[:200]}")

if saved == 0:
    print("!! No images returned. Full response candidates:")
    for cand in response.candidates or []:
        print(f"  finish_reason: {cand.finish_reason}")
        if cand.content and cand.content.parts:
            for part in cand.content.parts:
                if part.text:
                    print(f"  text: {part.text[:300]}")
else:
    print(f">>> DONE — {saved} image(s) saved to {OUT_DIR}")
