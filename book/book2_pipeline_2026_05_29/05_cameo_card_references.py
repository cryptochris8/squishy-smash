"""Cameo card-matched re-rolls for spreads 6, 8, 9, 10, 11, 13.

For each, pass the canonical card art as an additional reference image
so Nano Banana sees the franchise look and matches it. Result: cameo
characters are now recognizable to game fans + new readers.

Cost: 6 × $0.13 = $0.78. Wall: ~3 min.
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

# Canon character anchor descriptions
SD_DESC = (
    "Soft Dumpling — peach-pink round egg-shaped plush dumpling with a "
    "small curl tuft on top, soft cheek blush, two small dot eyes, "
    "gentle smile. NO ears (not a bunny). Round nub arms, NO fingers."
)
GOO_DESC = (
    "Goo Ball — blue glossy translucent round jelly-dome character with "
    "cheek blush, two small dot eyes, soft smile. Clean dome shape, no "
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

INTRO = (
    "Four images attached. The first three show the three plush "
    "protagonist characters of a picture book series. The FOURTH IMAGE "
    "shows a canonical cameo character from the same series who appears "
    "in this spread.\n\n"
    f"IMAGE 1: {SD_DESC}\n\n"
    f"IMAGE 2: {GOO_DESC}\n\n"
    f"IMAGE 3: {BUN_DESC}\n\n"
)


SPREADS = [
    {
        "n": 6,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "011_Sparkle_Mochi.webp"],
        "prompt": (
            INTRO +
            "IMAGE 4 (Sparkle Mochi cameo reference): a small round "
            "pink-peach mochi character with large kawaii cute eyes "
            "(white sclera, dark pupils with bright sparkle highlights), "
            "soft pink cheek blush, an open joyful smile, surrounded by "
            "tiny glittering sparkles. She has a soft pastel "
            "pink-and-lavender shimmery palette and an overall "
            "twinkling glitter aura.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio). Scene: All three plush protagonists "
            "walking together to the right across rolling peach-cream "
            "pudding hills with a warm amber syrup river suggested in "
            "the middle distance. Soft Dumpling leads in front, Goo Ball "
            "walks behind her, Blushy Bun walks last. To the side on a "
            "small rise, the small Sparkle Mochi (from image 4) stands "
            "watching them, her open joyful kawaii smile visible, soft "
            "glitter sparkles around her. The Sparkle Mochi should match "
            "image 4 exactly — same kawaii eyes, same pink-peach color, "
            "same sparkle aura. Soft golden-hour light." + STYLE_TAIL
        ),
    },
    {
        "n": 8,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "025_Glitter_Goo_Ball.webp"],
        "prompt": (
            INTRO +
            "IMAGE 4 (Glitter Goo Ball cameo reference): a round purple-"
            "blue translucent goo character covered in tiny glitter "
            "flakes with large kawaii cute eyes (sparkle highlights), "
            "soft pink cheek blush, open joyful smile, surrounded by "
            "radiating glitter stars and shimmering particles. Vibrant "
            "magenta-purple-blue palette.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio). Scene: All three plush protagonists "
            "walking together to the right across a glossy aqua-mint "
            "goo coast with bubble tide and glossy shore. Goo Ball "
            "leads in front. Soft Dumpling and Blushy Bun follow behind. "
            "To the side on a glossy rise, the small Glitter Goo Ball "
            "(from image 4) stands watching them, glittering and "
            "sparkling. The Glitter Goo Ball should match image 4 "
            "exactly — same purple-blue translucent body, same kawaii "
            "eyes, same glitter aura. Soft daylight." + STYLE_TAIL
        ),
    },
    {
        "n": 9,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "030_Aurora_Stretch_Cube.webp"],
        "prompt": (
            INTRO +
            "IMAGE 4 (Aurora Stretch Cube Epic reference): a stretchy "
            "translucent cube-shaped character with rippling aurora-"
            "colored body (pink, purple, teal, cyan northern-lights "
            "color waves), large kawaii cute eyes (sparkle highlights), "
            "soft pink cheek blush, open joyful smile, pointed soft "
            "corners. The body shimmers with aurora color waves like "
            "northern lights.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio). Scene: All three plush protagonists "
            "airborne mid-bounce over a glossy aqua-mint goo coast "
            "bubble-tide at different heights. Soft Dumpling bounces "
            "low with a surprised joyful expression. Goo Ball bounces "
            "in the middle with a content smile. Blushy Bun Bunny "
            "bounces the highest with arms raised in triumphant joy. "
            "Between them, a glossy bright shard crystal rises through "
            "the air. Deep beneath the water surface, the Aurora Stretch "
            "Cube (from image 4) is visible underwater as a huge "
            "luminous aurora-colored presence radiating warm dawn-"
            "colored aurora glow upward through the waves. The Aurora "
            "Stretch Cube should match image 4 — same aurora-color body, "
            "same kawaii eyes. Warm late-afternoon light above." + STYLE_TAIL
        ),
    },
    {
        "n": 10,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "041_Star_Eyed_Bunny.webp"],
        "prompt": (
            INTRO +
            "IMAGE 4 (Star-Eyed Bunny cameo reference): a small soft "
            "cream-white plush bunny with STAR-SHAPED EYES (each eye is "
            "a clear pink-magenta star shape inside a white sclera), "
            "pink upright ears with pink interior, soft pink cheek "
            "blush, open joyful smile, surrounded by sparkling starlight "
            "and tiny stars trailing behind her. Lavender-pink palette.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio). Scene: All three plush protagonists "
            "walking together to the right through a soft lavender-"
            "purple moonlit hollow with silver mushrooms and a gentle "
            "moon above. Blushy Bun Bunny leads in front. Soft Dumpling "
            "and Goo Ball follow behind. All three approximately the "
            "same size. To the side under the moon, the small Star-Eyed "
            "Bunny (from image 4) stands watching them, her "
            "star-shaped eyes clearly visible and twinkling. The Star-"
            "Eyed Bunny should match image 4 exactly — same star-shaped "
            "eyes, same cream color, same starlight aura. Soft slow "
            "not-afraid moonlit atmosphere." + STYLE_TAIL
        ),
    },
    {
        "n": 11,
        "refs": [SD_REF, GOO_REF, BUN_REF, CARDS / "043_Glow_Ghost_Puff.webp"],
        "prompt": (
            INTRO +
            "IMAGE 4 (Glow Ghost Puff Epic reference): a soft white-"
            "translucent ghostly puff character with a small ghost-tail "
            "wisp, large kawaii cute eyes (purple sparkle highlights), "
            "soft pink cheek blush, open joyful smile, ethereal glow "
            "around her body, surrounded by tiny stars and sparkles. "
            "Lavender-purple translucent palette.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio).\n\n"
            "IMPORTANT — EXACTLY THREE protagonist characters in the "
            "image (only ONE Soft Dumpling, ONE Goo Ball, ONE Bun). "
            "The trio stands TOGETHER in a tight cluster.\n\n"
            "Scene: A deep moonlit hollow grove at night, darker than "
            "dark. The three protagonists stand together very still in "
            "shadow at the center of the spread, scared but holding "
            "their ground, with worried scared-but-brave expressions. "
            "Huddled close together. A small dimming shard sits on the "
            "ground in front of them, barely glowing. Above the trio "
            "looms the GIANT GLOW GHOST PUFF from image 4 — sky-sized "
            "version of the canon Glow Ghost Puff, soft translucent "
            "lavender-white glow, kawaii sparkle eyes, gentle face, "
            "looking down at the trio with quiet benevolence. She must "
            "match image 4 exactly — same ghost shape, same kawaii "
            "eyes, same lavender glow. The remnant Sparkle in the sky "
            "above is almost gone. Dark forest with bare trees framing "
            "the spread. Quiet, somber, hushed mood." + STYLE_TAIL
        ),
    },
    {
        "n": 13,
        "refs": [
            SD_REF, GOO_REF, BUN_REF,
            CARDS / "016_Celestial_Dumpling_Core.webp",
            CARDS / "032_Singularity_Goo_Core.webp",
            CARDS / "048_Mythic_Plush_Familiar.webp",
        ],
        "prompt": (
            "Six images attached. The first three show the three plush "
            "protagonist characters. The fourth, fifth, and sixth show "
            "the three canonical Cores that appear in this spread's "
            "climactic moment.\n\n"
            f"IMAGE 1: {SD_DESC}\n\n"
            f"IMAGE 2: {GOO_DESC}\n\n"
            f"IMAGE 3: {BUN_DESC}\n\n"
            "IMAGE 4 (Celestial Dumpling Core Legendary): a cream-and-"
            "gold round dumpling Core with a small curl tuft, large "
            "kawaii sparkle eyes, open joyful smile, soft pink cheek "
            "blush, surrounded by golden rings of light and orbiting "
            "tiny planets/stars. Cream-gold-yellow palette, halo of "
            "golden radiance.\n\n"
            "IMAGE 5 (Singularity Goo Core Legendary): a dark "
            "purple-magenta swirling goo Core with a violet spiral "
            "pulling inward at her center, large kawaii sparkle eyes, "
            "open joyful smile, soft cheek blush, surrounded by deep "
            "cosmic purple swirls and small fragments. Dark "
            "magenta-purple-violet palette.\n\n"
            "IMAGE 6 (Mythic Plush Familiar Legendary): a cream-white "
            "plush familiar with cat-like silhouette and a halo above "
            "her head, large kawaii sparkle eyes, open joyful smile, "
            "soft cheek blush, wearing a soft purple cape, surrounded "
            "by gentle magical runes/sigils. Cream-and-lavender "
            "palette, golden halo glow.\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(21:9 aspect ratio).\n\n"
            "Scene: A moonlit grove restored by warm golden Sparkle-"
            "light. In the upper sky, the THREE LEGENDARY CORES (images "
            "4, 5, 6) appear as ENORMOUS SKY-SIZED beings — gentle "
            "benevolent presences filling the upper portion of the "
            "spread. Celestial Dumpling Core on the LEFT side of the "
            "sky (golden-cream with rings), Singularity Goo Core in the "
            "CENTER sky (dark purple swirling), Mythic Plush Familiar "
            "on the RIGHT side of the sky (cream-and-lavender with "
            "halo). All three Cores must match their canonical images "
            "exactly — same colors, same kawaii eyes, same auras.\n\n"
            "In the lower portion, the three plush protagonists stand "
            "together at the center looking up in awe with neutral "
            "expressions of wonder. All three protagonist characters "
            "approximately the same size. Between them, three small "
            "glowing shards fuse together in mid-air. Warm restored "
            "light, awestruck quiet mood." + STYLE_TAIL
        ),
    },
]


client = genai.Client(api_key=KEY)
config = types.GenerateContentConfig(
    image_config=types.ImageConfig(aspect_ratio="21:9"),
)


def run_spread(s):
    n = s["n"]
    out = OUT / f"spread_{n:02d}_cameo.png"
    refs = [PIL.Image.open(p) for p in s["refs"]]
    print(f"  refs: {len(refs)}")
    t0 = time.time()
    try:
        response = client.models.generate_content(
            model="gemini-3-pro-image-preview",
            contents=[s["prompt"], *refs],
            config=config,
        )
    except Exception as e:
        print(f"  !! API error: {e}")
        return False
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
    print(f"  !! no image in response")
    return False


total = time.time()
ok = 0
for s in SPREADS:
    print(f"\n=== Spread {s['n']:02d} ===")
    if run_spread(s):
        ok += 1
print(f"\n=== DONE in {int(time.time()-total)}s, {ok}/{len(SPREADS)} succeeded ===")
