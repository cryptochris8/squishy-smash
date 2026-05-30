"""S7 v3 re-roll — include Galaxy Dumpling card 013 as 4th reference to
match the canonical franchise look (open joyful eyes, vibrant pink-purple
cosmic palette).
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
OUT = PROJ / "_tmp_nano_banana_book_21x9"
KEY = (HOME / "gemini.key.txt").read_text(encoding="utf-8").strip()

# Add Galaxy Dumpling card as the 4th reference
GALAXY_DUMPLING_CARD = (
    PROJ / "squishy_smash" / "assets" / "cards" / "final_48" /
    "013_Galaxy_Dumpling.webp"
)

REFS = [
    WINNERS / "01_dumpling_neutral.png",
    WINNERS / "04_goo_ball_neutral.png",
    WINNERS / "09_bunny_gentle_front.png",
    GALAXY_DUMPLING_CARD,
]

PROMPT = (
    "Four images are attached. The first three show the three plush "
    "protagonist characters of a picture book series. The FOURTH IMAGE "
    "shows the canonical Galaxy Dumpling — a giant Epic dumpling character "
    "from the same series.\n\n"
    "IMAGE 1: Soft Dumpling — peach-pink round egg-shaped plush dumpling "
    "with a small curl tuft on top, soft cheek blush, two small dot eyes, "
    "gentle smile. NO ears (not a bunny). Round nub arms, NO fingers.\n\n"
    "IMAGE 2: Goo Ball — blue glossy translucent round jelly-dome "
    "character with cheek blush, two small dot eyes, soft smile. Clean "
    "dome shape, no tentacles. Round nub arms, NO fingers.\n\n"
    "IMAGE 3: Blushy Bun Bunny — white cream plush bunny with long "
    "floppy droopy ears (NOT upright), pink ear interior, soft cheek "
    "blush, pink triangular nose, two small dot eyes, gentle smile, pink "
    "paw pads visible. White body (NOT pink).\n\n"
    "IMAGE 4 (Galaxy Dumpling reference): a giant cosmic dumpling Epic "
    "with a ROUND DUMPLING SHAPE, small curl tuft on top, body filled "
    "with VIBRANT COSMIC SPACE — purple, pink, magenta, and blue swirling "
    "nebulas with bright stars, sparkles, and tiny planets visible inside "
    "her translucent body. She has BIG ROUND CUTE KAWAII EYES (white "
    "sclera, dark pupils with bright sparkle highlights), soft pink "
    "cheek blush, and a small gentle smile. She glows softly with magical "
    "cosmic energy.\n\n"
    "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
    "(extra-wide horizontal panoramic format, 21:9 aspect ratio).\n\n"
    "Scene: A pudding hills orchard at golden hour with apple-laden "
    "fruit trees and rolling cream-and-peach hills on both sides.\n\n"
    "GIANT GALAXY DUMPLING IN THE SKY: Looming large in the upper portion "
    "of the spread, the canonical Galaxy Dumpling (image 4) appears as a "
    "GIGANTIC SKY-SIZED VERSION of herself filling the upper sky. She is "
    "an ENORMOUS round dumpling shape with the small curl tuft on top, "
    "her body a VIBRANT COSMIC SPACE filled with swirling purple/pink/"
    "magenta nebulas, bright stars, sparkles, and tiny planets visible "
    "throughout. Her eyes are BIG ROUND CUTE KAWAII EYES open and gentle, "
    "with bright sparkle highlights — looking down peacefully at the "
    "trio below. She has a soft gentle smile, pink cheek blush. She "
    "glows softly. The Galaxy Dumpling in this image must clearly match "
    "the canonical look in IMAGE 4 — same vibrant cosmic palette, same "
    "kawaii eyes, same color scheme — just MUCH BIGGER (sky-sized) and "
    "positioned in the upper sky.\n\n"
    "At the bottom of the spread, small and grounded, the three plush "
    "protagonists stand together looking up in awe at Galaxy Dumpling. "
    "All three approximately the same size as each other (Soft Dumpling "
    "on the left, Goo Ball in the middle, Blushy Bun on the right). "
    "Between the trio and Galaxy Dumpling, a small glowing magical shard "
    "crystal rests on the orchard ground, half-glowing softly.\n\n"
    "Each protagonist must look EXACTLY like their references — preserve "
    "Soft Dumpling's peach color (NO ears), Goo Ball's glossy blue dome "
    "(NO tentacles), Bun's WHITE body and FLOPPY droopy ears (NOT "
    "upright). Each character face clearly visible.\n\n"
    "Warm golden orchard hills around the trio. Cinematic scale contrast "
    "between sky-sized Galaxy Dumpling above and tiny trio below. "
    "Hand-painted watercolor and gouache storybook illustration style, "
    "soft brush strokes, painterly hand-painted texture. Picture book "
    "illustration for ages 4 to 8. No text in image, no letters, no "
    "words, no book cover artifacts."
)

client = genai.Client(api_key=KEY)
config = types.GenerateContentConfig(
    image_config=types.ImageConfig(aspect_ratio="21:9"),
)

print(">>> S7 v3 — Galaxy Dumpling card-matched...")
refs = [PIL.Image.open(p) for p in REFS]
t0 = time.time()
response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=[PROMPT, *refs],
    config=config,
)
dt = int(time.time() - t0)
print(f"    done in {dt}s")

out = OUT / "spread_07_v3.png"
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
