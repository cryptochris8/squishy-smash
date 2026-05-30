"""Nano Banana Pro validation suite.

Four tests on Gemini 3 Pro Image Preview:
  1. SD new pose (walking in meadow) — same character / different pose
  2. Goo Ball isolated render — character #2 validation
  3. Blushy Bun isolated render — character #3 validation
  4. Multi-character spread — all 3 in one painterly scene (the real
     production case)

Cost: ~$0.52 total. Wall: ~3 min.
"""
import os
import time
from pathlib import Path

# Schannel SSL workaround
import httpx
_o = httpx.Client.__init__
_oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
import warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

import PIL.Image
from google import genai

HOME = Path(r"C:\Users\chris")
PROJ = Path(r"C:\Users\chris\Squishy-smash")
WINNERS = PROJ / "_tmp_mj_winners"
OUT_DIR = PROJ / "_tmp_nano_banana_test"
OUT_DIR.mkdir(exist_ok=True)

KEY = (HOME / "gemini.key.txt").read_text(encoding="utf-8").strip()

SD_REFS = [WINNERS / f for f in [
    "01_dumpling_neutral.png",
    "02_dumping_triamphunt.png",
    "03_dumpling_walking.png",
]]
GOO_REFS = [WINNERS / f for f in [
    "04_goo_ball_neutral.png",
    "05_goo_ball_walking.png",
    "06_goo_ball_looking_up.png",
]]
BUN_REFS = [WINNERS / f for f in [
    "07_bunny_hopping_side.png",
    "08_bunny_gentle_head_tilt.png",
    "09_bunny_gentle_front.png",
]]

TESTS = [
    {
        "name": "test_1_sd_walking_meadow",
        "refs": SD_REFS,
        "prompt": (
            "The three attached images show the same plush character — "
            "\"Soft Dumpling\" — a peach-pink round egg-shaped plush dumpling "
            "with a small curl tuft on top, soft cheek blush, two small dot "
            "eyes, gentle smile. NO ears (not a bunny). Round nub arms, NO "
            "fingers. Consistent peach-pink color across references.\n\n"
            "Generate a single new image showing THIS EXACT CHARACTER walking "
            "happily through a soft pastel-peach meadow at golden hour. "
            "Hand-painted watercolor storybook illustration style, soft brush "
            "strokes, painterly texture. Picture book aesthetic for ages 4 "
            "to 8.\n\n"
            "Preserve her exact appearance: same peach-pink color, same round "
            "egg shape, same small curl tuft, same dot eyes, same cheek "
            "blush, NO ears, NO fingers. White or transparent background, "
            "no text in image."
        ),
    },
    {
        "name": "test_2_goo_ball_canonical",
        "refs": GOO_REFS,
        "prompt": (
            "The three attached images show the same plush character — "
            "\"Goo Ball\" — a blue glossy translucent round jelly-dome "
            "character with soft pink cheek blush, two small black dot eyes, "
            "a gentle small smile. He has a clean round dome body (no "
            "tentacles, no jellyfish features). Round nub arms with NO "
            "fingers. Consistent glossy blue color across all references.\n\n"
            "Generate a single new image showing THIS EXACT CHARACTER "
            "looking up in wonder at a soft golden sparkle in the sky, "
            "standing on a glossy aqua-mint goo coast. Hand-painted "
            "watercolor storybook illustration style, soft brush strokes, "
            "painterly texture. Picture book aesthetic for ages 4 to 8.\n\n"
            "Preserve his exact appearance: same glossy blue translucent "
            "color, same round dome shape, same cheek blush, same black dot "
            "eyes, NO tentacles, NO jellyfish features, NO fingers. White "
            "or transparent background, no text in image."
        ),
    },
    {
        "name": "test_3_bun_canonical",
        "refs": BUN_REFS,
        "prompt": (
            "The three attached images show the same plush character — "
            "\"Blushy Bun Bunny\" — a white cream plush bunny with long "
            "floppy droopy ears (NOT upright), pink ear interiors, soft pink "
            "cheek blush, pink triangular nose, two small black dot eyes, "
            "gentle smile, pink paw pads visible on her feet. Her body is "
            "WHITE/CREAM (not pink). Consistent across all references.\n\n"
            "Generate a single new image showing THIS EXACT CHARACTER "
            "hopping joyfully through a lavender moonlit hollow with silver "
            "mushrooms. Hand-painted watercolor storybook illustration "
            "style, soft brush strokes, painterly texture. Picture book "
            "aesthetic for ages 4 to 8.\n\n"
            "Preserve her exact appearance: same WHITE cream body color "
            "(NOT pink), same long floppy droopy ears (NOT upright), same "
            "pink paw pads, same pink nose, same cheek blush, same dot "
            "eyes. White or transparent background, no text in image."
        ),
    },
    {
        "name": "test_4_multi_character_spread",
        # Use 1 ref per character so we stay within reasonable input limits
        "refs": [
            SD_REFS[0],   # SD neutral
            GOO_REFS[0],  # Goo neutral
            BUN_REFS[2],  # Bun gentle front
        ],
        "prompt": (
            "The three attached images show THREE DIFFERENT plush characters "
            "of a picture book series.\n\n"
            "IMAGE 1: \"Soft Dumpling\" — peach-pink round egg-shaped plush "
            "dumpling with a small curl tuft on top, cheek blush, dot eyes, "
            "gentle smile. NO ears (not a bunny). Round nub arms, NO "
            "fingers.\n\n"
            "IMAGE 2: \"Goo Ball\" — blue glossy translucent round jelly-dome "
            "with cheek blush, dot eyes, soft smile. Clean dome shape, no "
            "tentacles, no jellyfish features. Round nub arms, NO "
            "fingers.\n\n"
            "IMAGE 3: \"Blushy Bun Bunny\" — white cream plush bunny with "
            "long floppy droopy ears (NOT upright), pink ear interior, "
            "cheek blush, pink nose, pink paw pads, dot eyes, gentle smile. "
            "White body (NOT pink).\n\n"
            "Generate a single new image showing ALL THREE characters "
            "together walking gently to the right across a soft pastel "
            "border landscape — peach pudding hills on the left meeting "
            "mint goo coast in the middle, with a hint of lavender moonlit "
            "hollow on the far right horizon. All three in calm walking "
            "poses with gentle smiles. Hand-painted watercolor storybook "
            "illustration style, soft brush strokes, painterly texture. "
            "Picture book aesthetic for ages 4 to 8.\n\n"
            "Each character must look EXACTLY like its reference — preserve "
            "Soft Dumpling's peach color and egg shape, Goo Ball's glossy "
            "blue and dome shape, Bun's WHITE body and FLOPPY droopy ears. "
            "Each character is distinct and recognizable. No text in image."
        ),
    },
]


client = genai.Client(api_key=KEY)


def run_test(test):
    print(f"\n=== {test['name']} ===")
    print(f"  refs: {len(test['refs'])}")
    refs = [PIL.Image.open(p) for p in test["refs"]]
    t0 = time.time()
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[test["prompt"], *refs],
    )
    dt = int(time.time() - t0)
    print(f"  done in {dt}s")

    saved = 0
    for i, cand in enumerate(response.candidates or []):
        if not cand.content or not cand.content.parts:
            continue
        for j, part in enumerate(cand.content.parts):
            if part.inline_data and part.inline_data.data:
                mime = part.inline_data.mime_type or "image/png"
                ext = "png" if "png" in mime else "jpg"
                out = OUT_DIR / f"{test['name']}.{ext}"
                out.write_bytes(part.inline_data.data)
                print(f"  saved -> {out.name} ({len(part.inline_data.data)} bytes)")
                saved += 1
            elif part.text:
                print(f"  text: {part.text[:120]}")
    if saved == 0:
        for cand in response.candidates or []:
            print(f"  finish_reason: {cand.finish_reason}")


total = time.time()
for t in TESTS:
    run_test(t)
print(f"\n=== ALL DONE in {int(time.time()-total)}s ===")
