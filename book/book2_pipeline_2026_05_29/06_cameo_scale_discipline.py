"""S6, S8, S10 re-rolls — cameos made small/atmospheric per author's intent.

Author's voice note: Rare guides are described-by-feeling, not named.
They should be brief atmospheric encounters in the world the trio passes
through — NOT secondary co-stars.

Card art still passed as reference so the cameo is recognizable, but
the prompt emphasizes "small," "in the background," "brief encounter."
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
CARDS = PROJ / "squishy_smash" / "assets" / "cards" / "final_48"
OUT = PROJ / "_tmp_nano_banana_book_21x9"
KEY = (HOME / "gemini.key.txt").read_text(encoding="utf-8").strip()

SD_REF = WINNERS / "01_dumpling_neutral.png"
GOO_REF = WINNERS / "04_goo_ball_neutral.png"
BUN_REF = WINNERS / "09_bunny_gentle_front.png"

SD_DESC = (
    "Soft Dumpling — peach-pink round egg-shaped plush dumpling with a "
    "small curl tuft on top, soft cheek blush, two small dot eyes, "
    "gentle smile. NO ears. Round nub arms, NO fingers."
)
GOO_DESC = (
    "Goo Ball — blue glossy translucent round jelly-dome with cheek "
    "blush, two small dot eyes, soft smile. Clean dome shape, no "
    "tentacles. Round nub arms, NO fingers."
)
BUN_DESC = (
    "Blushy Bun Bunny — white cream plush bunny with long floppy droopy "
    "ears (NOT upright), pink ear interior, soft cheek blush, pink "
    "triangular nose, two small dot eyes, gentle smile, pink paw pads "
    "visible. White body (NOT pink)."
)

STYLE_TAIL = (
    " Each protagonist must look EXACTLY like their references. Hand-"
    "painted watercolor and gouache storybook illustration style, soft "
    "brush strokes, painterly hand-painted texture. Picture book "
    "illustration for ages 4 to 8. No text in image, no letters, no "
    "words, no book cover artifacts."
)

SPREADS = [
    {
        "n": 6,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "011_Sparkle_Mochi.webp"],
        "prompt": (
            "Four images attached. The first three are the protagonists "
            "of a picture book.\n\n"
            f"IMAGE 1: {SD_DESC}\n\n"
            f"IMAGE 2: {GOO_DESC}\n\n"
            f"IMAGE 3: {BUN_DESC}\n\n"
            "IMAGE 4 (cameo character reference for atmospheric detail "
            "only): a small round pink-peach mochi with kawaii sparkle "
            "eyes and soft pink glitter aura. This is a BRIEF "
            "ATMOSPHERIC CAMEO, not a co-star.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio).\n\n"
            "MAIN FOCUS: All three plush protagonists walking together "
            "to the right across rolling peach-cream pudding hills. They "
            "are the CLEAR PRIMARY SUBJECT of the spread — large, "
            "centered, faces visible. Soft Dumpling leads in front, Goo "
            "Ball walks behind her, Blushy Bun walks last. A warm amber "
            "syrup river suggested in the middle distance.\n\n"
            "ATMOSPHERIC BACKGROUND DETAIL (small, NOT a co-star): "
            "Somewhere in the middle-distance background, a small mochi "
            "character (matching image 4 but rendered SMALL and "
            "atmospheric) is glimpsed waving one shimmery wave toward "
            "an orchard in the far distance. She is small enough that "
            "the reader sees her as a brief background presence — like "
            "spotting a fairy in a field — NOT as a co-star competing "
            "with the protagonists. She is approximately 1/6th the "
            "size of the protagonists. The protagonist trio dominates "
            "the foreground.\n\n"
            "Soft golden-hour light. Painterly watercolor pudding hills "
            "landscape." + STYLE_TAIL
        ),
    },
    {
        "n": 8,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "025_Glitter_Goo_Ball.webp"],
        "prompt": (
            "Four images attached. The first three are the protagonists.\n\n"
            f"IMAGE 1: {SD_DESC}\n\n"
            f"IMAGE 2: {GOO_DESC}\n\n"
            f"IMAGE 3: {BUN_DESC}\n\n"
            "IMAGE 4 (cameo character reference for atmospheric detail "
            "only): a small round purple-blue translucent glitter goo "
            "with kawaii sparkle eyes. This is a BRIEF ATMOSPHERIC "
            "CAMEO, not a co-star.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio).\n\n"
            "MAIN FOCUS: All three plush protagonists walking together "
            "to the right across a glossy aqua-mint goo coast with "
            "bubble tide and glossy shore. They are the CLEAR PRIMARY "
            "SUBJECT — large, centered, faces visible. Goo Ball leads in "
            "front. Soft Dumpling and Blushy Bun follow.\n\n"
            "ATMOSPHERIC BACKGROUND DETAIL (small, NOT a co-star): "
            "Somewhere in the middle-distance background, a small "
            "glittering goo creature (matching image 4 but rendered "
            "SMALL and atmospheric) sits on a glossy rise far from the "
            "trio, pointing seaward. She is approximately 1/6th the "
            "size of the protagonists, just a brief background presence "
            "the trio glimpses while passing. NOT a co-star.\n\n"
            "Soft daylight, bouncy sea in mid-distance. Painterly "
            "watercolor." + STYLE_TAIL
        ),
    },
    {
        "n": 10,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "041_Star_Eyed_Bunny.webp"],
        "prompt": (
            "Four images attached. The first three are the protagonists.\n\n"
            f"IMAGE 1: {SD_DESC}\n\n"
            f"IMAGE 2: {GOO_DESC}\n\n"
            f"IMAGE 3: {BUN_DESC}\n\n"
            "IMAGE 4 (cameo character reference for atmospheric detail "
            "only): a small cream-white bunny with star-shaped eyes. "
            "This is a BRIEF ATMOSPHERIC CAMEO, not a co-star.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio).\n\n"
            "MAIN FOCUS: All three plush protagonists walking together "
            "to the right through a soft lavender-purple moonlit hollow "
            "with silver mushrooms and a gentle moon above. They are "
            "the CLEAR PRIMARY SUBJECT — large, centered, faces "
            "visible, approximately the same size as each other. Blushy "
            "Bun Bunny leads in front. Soft Dumpling and Goo Ball "
            "follow behind.\n\n"
            "ATMOSPHERIC BACKGROUND DETAIL (small, NOT a co-star): "
            "Somewhere in the middle-distance background under the "
            "moon, a tiny star-eyed bunny creature (matching image 4 "
            "but rendered SMALL and atmospheric) is glimpsed briefly, "
            "her star-shaped eyes barely catching the moonlight as she "
            "watches the trio pass. She is approximately 1/6th the "
            "size of the protagonists. NOT a co-star — just a brief "
            "magical detail the reader spots.\n\n"
            "Soft slow not-afraid moonlit atmosphere. Painterly "
            "watercolor." + STYLE_TAIL
        ),
    },
]


client = genai.Client(api_key=KEY)
config = types.GenerateContentConfig(
    image_config=types.ImageConfig(aspect_ratio="21:9"),
)


def run_spread(s):
    n = s["n"]
    out = OUT / f"spread_{n:02d}_cameo_small.png"
    refs = [PIL.Image.open(p) for p in s["refs"]]
    t0 = time.time()
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[s["prompt"], *refs],
        config=config,
    )
    dt = int(time.time() - t0)
    print(f"  done in {dt}s")
    for cand in response.candidates or []:
        if not cand.content or not cand.content.parts:
            continue
        for part in cand.content.parts:
            if part.inline_data and part.inline_data.data:
                out.write_bytes(part.inline_data.data)
                img = PIL.Image.open(out)
                print(f"  saved -> {out.name} ({img.size[0]}x{img.size[1]})")
                return True
    return False


total = time.time()
for s in SPREADS:
    print(f"\n=== Spread {s['n']:02d} (smaller cameo) ===")
    run_spread(s)
print(f"\n=== DONE in {int(time.time()-total)}s ===")
