"""S11 re-roll at 21:9 — fix duplicate Soft Dumpling, trio together."""
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
OUT = PROJ / "_tmp_nano_banana_book_21x9"
KEY = (HOME / "gemini.key.txt").read_text(encoding="utf-8").strip()

REFS = [
    WINNERS / "01_dumpling_neutral.png",
    WINNERS / "04_goo_ball_neutral.png",
    WINNERS / "09_bunny_gentle_front.png",
]

PROMPT = (
    "The three attached images show three different plush characters "
    "from a children's picture book series.\n\n"
    "IMAGE 1: Soft Dumpling — peach-pink round egg-shaped plush dumpling "
    "with a small curl tuft on top, soft cheek blush, two small dot eyes, "
    "gentle smile. NO ears (not a bunny). Round nub arms, NO fingers.\n\n"
    "IMAGE 2: Goo Ball — blue glossy translucent round jelly-dome "
    "character with cheek blush, two small dot eyes, soft smile. Clean "
    "dome shape, no tentacles. Round nub arms, NO fingers.\n\n"
    "IMAGE 3: Blushy Bun Bunny — white cream plush bunny with long "
    "floppy droopy ears (NOT upright), pink ear interior, soft cheek "
    "blush, pink triangular nose, two small dot eyes, gentle smile, "
    "pink paw pads visible. White body (NOT pink).\n\n"
    "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
    "(extra-wide horizontal panoramic format, 21:9 aspect ratio).\n\n"
    "IMPORTANT — EXACTLY THREE CHARACTERS IN THE IMAGE: only ONE Soft "
    "Dumpling, only ONE Goo Ball, only ONE Blushy Bun Bunny. Do NOT "
    "duplicate any character. Do NOT show any character twice. The trio "
    "stands TOGETHER in a small tight cluster.\n\n"
    "Scene: A deep moonlit hollow grove at night, darker than dark. The "
    "three characters stand together very still in shadow at the center "
    "of the spread, scared but holding their ground, with worried "
    "scared-but-brave expressions. They are huddled close together in a "
    "small group, NOT spread apart. A small dimming shard sits on the "
    "ground in front of them, barely glowing. Above the trio looms a "
    "large soft ghostly puff shape — a friendly haunting silhouette "
    "with a gentle face. The remnant Sparkle in the sky above is almost "
    "gone, barely visible. Quiet, somber, hushed mood. Dark forest "
    "with bare trees on either side of the spread.\n\n"
    "Each character must look EXACTLY like its reference — preserve "
    "Soft Dumpling's peach color and egg shape (NO ears), Goo Ball's "
    "glossy blue and dome shape (NO tentacles), Bun's WHITE body and "
    "FLOPPY droopy ears (NOT upright). All three character faces must "
    "be clearly visible. Hand-painted watercolor and gouache storybook "
    "illustration style, soft brush strokes, painterly hand-painted "
    "texture. Picture book illustration for ages 4 to 8. No text in "
    "image, no letters, no words, no book cover artifacts."
)

client = genai.Client(api_key=KEY)
config = types.GenerateContentConfig(
    image_config=types.ImageConfig(aspect_ratio="21:9"),
)

print(">>> S11 re-roll — anti-duplication...")
refs = [PIL.Image.open(p) for p in REFS]
t0 = time.time()
response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=[PROMPT, *refs],
    config=config,
)
dt = int(time.time() - t0)
print(f"    done in {dt}s")

out = OUT / "spread_11_v2.png"
for cand in response.candidates or []:
    if not cand.content or not cand.content.parts:
        continue
    for part in cand.content.parts:
        if part.inline_data and part.inline_data.data:
            out.write_bytes(part.inline_data.data)
            img = PIL.Image.open(out)
            print(f"    saved -> {out.name} ({img.size[0]}x{img.size[1]})")
            break
print(">>> DONE")
