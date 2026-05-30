"""Verify aspect_ratio=21:9 works on Gemini 3 Pro Image Preview.

If output dimensions are roughly 21:9 (~1568x672 or similar wide format),
the parameter is accepted and we can batch the remaining 16 spreads.
If output is still square 1024x1024, the param was ignored and we need
a different approach.

Single test on Spread 5 — has all 3 characters in a known-working prompt.
Cost ~$0.13.
"""
import os
import time
from pathlib import Path

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
OUT = PROJ / "_tmp_nano_banana_aspect_test"
OUT.mkdir(exist_ok=True)
KEY = (HOME / "gemini.key.txt").read_text(encoding="utf-8").strip()

REFS = [
    WINNERS / "01_dumpling_neutral.png",
    WINNERS / "04_goo_ball_neutral.png",
    WINNERS / "09_bunny_gentle_front.png",
]

PROMPT = (
    "The three attached images show three different plush characters from "
    "a children's picture book series.\n\n"
    "IMAGE 1: Soft Dumpling — peach-pink round egg-shaped plush dumpling "
    "with a small curl tuft on top, soft cheek blush, two small dot eyes, "
    "gentle smile. NO ears (not a bunny). Round nub arms, NO fingers.\n\n"
    "IMAGE 2: Goo Ball — blue glossy translucent round jelly-dome character "
    "with cheek blush, two small dot eyes, soft smile. Clean dome shape, no "
    "tentacles. Round nub arms, NO fingers.\n\n"
    "IMAGE 3: Blushy Bun Bunny — white cream plush bunny with long floppy "
    "droopy ears (NOT upright), pink ear interior, soft cheek blush, pink "
    "triangular nose, two small dot eyes, gentle smile, pink paw pads "
    "visible. White body (NOT pink).\n\n"
    "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION (extra-wide "
    "horizontal panoramic format, 21:9 aspect ratio) showing all three "
    "characters walking together to the right across a soft pastel border "
    "landscape — peach pudding hills meeting mint goo coast, with a hint of "
    "lavender moonlit hollow on the far right horizon. Soft Dumpling on the "
    "left, Goo Ball in the center, Blushy Bun Bunny on the right. All three "
    "in calm walking poses with gentle smiles. Soft daylight.\n\n"
    "Each character must look EXACTLY like its reference. Hand-painted "
    "watercolor and gouache storybook illustration style, soft brush strokes, "
    "painterly hand-painted texture. Picture book illustration for ages 4 "
    "to 8. No text in image."
)


client = genai.Client(api_key=KEY)
print(">>> Testing aspect_ratio='21:9' on Gemini 3 Pro Image Preview...")
refs = [PIL.Image.open(p) for p in REFS]
t0 = time.time()

# Try the config-based aspect_ratio approach
try:
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[PROMPT, *refs],
        config=types.GenerateContentConfig(
            image_config=types.ImageConfig(aspect_ratio="21:9"),
        ),
    )
    print("    config.image_config.aspect_ratio accepted")
except Exception as e:
    print(f"    config.image_config approach failed: {e}")
    raise

dt = int(time.time() - t0)
print(f"    done in {dt}s")

out = OUT / "spread_05_aspect_test.png"
for cand in response.candidates or []:
    if not cand.content or not cand.content.parts:
        continue
    for part in cand.content.parts:
        if part.inline_data and part.inline_data.data:
            out.write_bytes(part.inline_data.data)
            print(f"    saved -> {out.name} ({len(part.inline_data.data)} bytes)")
            break

# Check actual dimensions
if out.exists():
    img = PIL.Image.open(out)
    w, h = img.size
    ratio = w / h
    print(f"\n>>> OUTPUT DIMENSIONS: {w}x{h} (ratio {ratio:.2f}:1)")
    if 2.0 < ratio < 2.5:
        print(">>> SUCCESS — aspect ratio is in the 21:9 / 2:1 range, parameter worked!")
    elif 0.95 < ratio < 1.05:
        print("!! FAILED — still square. aspect_ratio param was ignored.")
    else:
        print(f"!! UNEXPECTED RATIO — investigate.")
