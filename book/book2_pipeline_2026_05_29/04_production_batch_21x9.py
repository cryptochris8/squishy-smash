"""Re-batch the 16 square spreads at 21:9 facing-pair format.

Skips S1 (already 2.36:1) and S2 (1.83:1 — close enough, also wide-ish).
Uses the same prompts that worked in the square batch, just adds
aspect_ratio=21:9 via image_config.

Cost: 16 x ~$0.13 = ~$2.08. Wall: ~10-15 min.

Outputs land in _tmp_nano_banana_book_21x9/spread_NN.png for review
before promoting to book2_final_spreads/.
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
OUT_DIR = PROJ / "_tmp_nano_banana_book_21x9"
OUT_DIR.mkdir(exist_ok=True)
KEY = (HOME / "gemini.key.txt").read_text(encoding="utf-8").strip()

SD_REF = WINNERS / "01_dumpling_neutral.png"
GOO_REF = WINNERS / "04_goo_ball_neutral.png"
BUN_REF = WINNERS / "09_bunny_gentle_front.png"
ALL_3_REFS = [SD_REF, GOO_REF, BUN_REF]
SD_3_REFS = [WINNERS / f for f in [
    "01_dumpling_neutral.png",
    "02_dumping_triamphunt.png",
    "03_dumpling_walking.png",
]]

SD_DESC = (
    "Soft Dumpling — peach-pink round egg-shaped plush dumpling with a "
    "small curl tuft on top, soft cheek blush, two small dot eyes, "
    "gentle smile. NO ears (not a bunny). Round nub arms, NO fingers."
)
GOO_DESC = (
    "Goo Ball — blue glossy translucent round jelly-dome character with "
    "cheek blush, two small dot eyes, soft smile. Clean dome shape, no "
    "tentacles, no jellyfish features. Round nub arms, NO fingers."
)
BUN_DESC = (
    "Blushy Bun Bunny — white cream plush bunny with long floppy droopy "
    "ears (NOT upright), pink ear interior, soft cheek blush, pink "
    "triangular nose, two small dot eyes, gentle smile, pink paw pads "
    "visible. White body (NOT pink)."
)

STYLE_TAIL = (
    " Hand-painted watercolor and gouache storybook illustration style, "
    "soft brush strokes, painterly hand-painted texture. Picture book "
    "illustration for ages 4 to 8. No text in image, no letters, no "
    "words, no book cover artifacts."
)


def three_char_intro(scene_text):
    return (
        "The three attached images show three different plush characters "
        "from a children's picture book series.\n\n"
        f"IMAGE 1: {SD_DESC}\n\n"
        f"IMAGE 2: {GOO_DESC}\n\n"
        f"IMAGE 3: {BUN_DESC}\n\n"
        "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
        "(extra-wide horizontal panoramic format, 21:9 aspect ratio) "
        "showing the following scene. " + scene_text +
        " Each character must look EXACTLY like its reference — preserve "
        "Soft Dumpling's peach color and egg shape (NO ears), Goo Ball's "
        "glossy blue and dome shape (NO tentacles), Bun's WHITE body and "
        "FLOPPY droopy ears (NOT upright). All character faces must be "
        "clearly visible to the reader." + STYLE_TAIL
    )


def sd_only_intro(scene_text):
    return (
        "The three attached images show the same plush character — "
        f"{SD_DESC}\n\n"
        "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
        "(extra-wide horizontal panoramic format, 21:9 aspect ratio) "
        "showing this exact character in this scene: " + scene_text +
        " Preserve her exact appearance from the references." + STYLE_TAIL
    )


SPREADS = [
    {
        "n": 3, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "A wide triptych with three vertical panels showing three "
            "VERY DIFFERENT pack-world landscapes side by side across the "
            "wide spread. LEFT PANEL: Soft Dumpling alone on warm "
            "peach-cream pudding hills at golden hour, looking up at a "
            "dimming sky with a small worried expression. CENTER PANEL: "
            "Goo Ball alone on an aqua-mint glossy goo coast at midday, "
            "looking up worried. RIGHT PANEL: Blushy Bun Bunny alone in a "
            "lavender misty moonlit hollow at twilight, looking up "
            "worried. Three distinct palettes per panel — warm peach, "
            "cool aqua, cool lavender."
        ),
    },
    {
        "n": 4, "refs": [SD_REF, GOO_REF],
        "prompt": (
            "The attached images show TWO different plush characters.\n\n"
            f"IMAGE 1: {SD_DESC}\n\n"
            f"IMAGE 2: {GOO_DESC}\n\n"
            "Generate a single new WIDE FACING-PAIR SPREAD ILLUSTRATION "
            "(extra-wide horizontal panoramic format, 21:9 aspect ratio) "
            "showing a border landscape across the wide composition. LEFT "
            "HALF: soft peach-cream pudding hills with trees. RIGHT HALF: "
            "aqua-mint glossy goo coast with gentle water. A syrup river "
            "thins into a goo tide along the center seam. Soft Dumpling "
            "stands on the left near the border. Goo Ball stands on the "
            "right just past the border. The two face each other across "
            "the border with curious gentle expressions. NO bunny in this "
            "scene. Both character faces clearly visible. Soft daylight." +
            STYLE_TAIL
        ),
    },
    {
        "n": 5, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "All three characters walking together to the right across a "
            "soft pastel border landscape spanning the wide spread — "
            "peach pudding hills meeting mint goo coast, with a hint of "
            "lavender moonlit hollow on the far right horizon. Soft "
            "Dumpling on the left, Goo Ball in the center, Blushy Bun "
            "Bunny on the right hopping behind the others. All three in "
            "calm walking poses with gentle smiles. Soft daylight."
        ),
    },
    {
        "n": 6, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "All three characters walking together to the right across "
            "rolling peach-cream pudding hills with a warm amber syrup "
            "river suggested in the middle distance. Soft Dumpling leads "
            "in front. Goo Ball walks behind her. Blushy Bun Bunny walks "
            "last. All three faces clearly visible facing forward. All "
            "three in peaceful traveling poses with content gentle "
            "smiles. Soft golden-hour light."
        ),
    },
    {
        "n": 7, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "A pudding hills orchard at golden hour. Looming large in the "
            "upper portion of the spread, a gigantic sky-dumpling shape "
            "— an enormous round silhouette filled with deep starry "
            "purple-blue night and tiny quiet stars, gentle and "
            "benevolent. At the bottom of the spread, small and "
            "grounded, the three characters stand together looking up in "
            "awe. A small glowing shard rests on the orchard ground "
            "between them and the sky-dumpling."
        ),
    },
    {
        "n": 8, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "All three characters walking together to the right across a "
            "glossy aqua-mint goo coast with bubble tide and glossy "
            "shore. Goo Ball leads in front. Soft Dumpling and Blushy "
            "Bun Bunny follow behind. All three in calm walking poses "
            "with gentle smiles and faces clearly visible. A bouncy sea "
            "visible in the mid-distance. Soft daylight."
        ),
    },
    {
        "n": 9, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "All three characters airborne mid-bounce over a glossy "
            "aqua-mint goo coast bubble-tide at different heights. Soft "
            "Dumpling bounces low with a surprised joyful expression. "
            "Goo Ball bounces in the middle with a content smile. "
            "Blushy Bun Bunny bounces the highest with arms raised in "
            "triumphant joy. Between them, a glossy bright shard "
            "crystal rises through the air. Deep beneath the water a "
            "soft dawn-colored warm glow radiates upward. Warm "
            "late-afternoon light."
        ),
    },
    {
        "n": 10, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "All three characters walking together to the right through "
            "a soft lavender-purple moonlit hollow with silver mushrooms "
            "and a gentle moon above. Blushy Bun Bunny leads in front. "
            "Soft Dumpling and Goo Ball follow behind. All three "
            "approximately the same size. All three in calm walking "
            "poses with gentle small smiles. Soft slow not-afraid "
            "atmosphere."
        ),
    },
    {
        "n": 11, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "A deep moonlit hollow grove at night, darker than dark. The "
            "three characters stand very still in shadow, scared but "
            "holding their ground. A small dimming shard sits on the "
            "ground in front of them, barely glowing. Above the trio "
            "looms a large soft ghostly puff shape — a friendly haunting "
            "silhouette with a gentle face. The remnant Sparkle in the "
            "sky above is almost gone. Quiet, somber, hushed mood."
        ),
    },
    {
        "n": 12, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "All three characters in a triumphant group hug at the "
            "climax of the story. Soft Dumpling on the left, Goo Ball in "
            "the middle, Blushy Bun Bunny on the right. All three "
            "pressed close together with arms reaching in joyful shouts "
            "and content smiles. Behind the trio, a DRAMATIC RADIANT "
            "WARM GOLDEN-ORANGE LIGHT BURST radiates outward with bright "
            "rays extending across a twilight blue-purple sky. Cinematic "
            "chiaroscuro lighting — warm orange against cool blue."
        ),
    },
    {
        "n": 13, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "A moonlit grove restored by warm golden Sparkle-light. In "
            "the upper sky, THREE LARGE ABSTRACT CELESTIAL LIGHT "
            "FORMATIONS — like enormous soft glowing constellations or "
            "aurora shapes, gentle benevolent presences filling the "
            "upper portion of the spread. In the lower portion, the "
            "three characters stand together looking up in awe. Between "
            "them, three small glowing shards fuse together in mid-air. "
            "Warm restored light, awestruck quiet mood."
        ),
    },
    {
        "n": 14, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "Three pack-world horizons silhouetted across the bottom of "
            "the wide spread — peach pudding hills on the left, aqua goo "
            "coast in the center, lavender moonlit hollow on the right. "
            "Above them all, a restored BRIGHT GOLDEN SPARKLE glows "
            "large and warm in the upper sky with soft radiating rays. "
            "THREE TINY plush silhouettes at the bottom looking up at "
            "the Sparkle — a small peach Soft Dumpling silhouette, a "
            "small blue Goo Ball silhouette, a small white Bun "
            "silhouette. Warm-pastel triumphant peaceful mood."
        ),
    },
    {
        "n": 15, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "A wide triptych with three vertical panels across the wide "
            "spread, showing each character arriving home alone with a "
            "small glowing light held close. LEFT PANEL: Soft Dumpling "
            "in warm peach-cream pudding hills at sunset, content smile, "
            "holding a small glow. CENTER PANEL: Goo Ball on an "
            "aqua-mint goo coast at midday, content smile, holding a "
            "small glow. RIGHT PANEL: Blushy Bun Bunny in a lavender "
            "moonlit hollow, content smile, holding a small glow. Each "
            "character alone in their own home pack-world. Warm soft "
            "late-day light."
        ),
    },
    {
        "n": 16, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "Three intimate homecoming scenes arranged side by side "
            "across the wide spread. LEFT: Soft Dumpling welcomed home "
            "in rolling peach pudding hills by other small peach "
            "dumpling creatures, warm sunset light. CENTER: Goo Ball "
            "welcomed home on the goo coast by other small blue glossy "
            "goo creatures, daylight. RIGHT: Blushy Bun Bunny welcomed "
            "home in a moonlit hollow by other small white bunny "
            "creatures, soft moonlight. Soft warm lighting throughout."
        ),
    },
    {
        "n": 17, "refs": ALL_3_REFS,
        "prompt": three_char_intro(
            "Three pack-world landscapes touching at their borders "
            "across the wide spread. LEFT: peach-cream rolling pudding "
            "hills. CENTER: blue glossy goo coastline with gentle water. "
            "RIGHT: lavender misty moonlit hollow with silver mushrooms. "
            "At each border one of the three characters is visiting a "
            "neighboring pack — Soft Dumpling resting by the goo coast, "
            "Goo Ball sitting in the moonlit hollow, Blushy Bun Bunny "
            "hopping across the pudding hills. Three small focal "
            "moments across the wide spread. Soft pastel palette, warm "
            "late-afternoon light."
        ),
    },
    {
        "n": 18, "refs": SD_3_REFS,
        "prompt": sd_only_intro(
            "Soft Dumpling sleeping peacefully curled on soft warm "
            "pudding hills in the foreground of the wide spread. Above "
            "her in the warm sunset sky, a small bright GOLDEN SPARKLE "
            "drifts gently overhead with a soft halo of light. Cozy "
            "bedtime mood, warm sunset palette, the warmest light in "
            "the book."
        ),
    },
]


client = genai.Client(api_key=KEY)
config = types.GenerateContentConfig(
    image_config=types.ImageConfig(aspect_ratio="21:9"),
)


def run_spread(s):
    n = s["n"]
    out = OUT_DIR / f"spread_{n:02d}.png"
    if out.exists():
        print(f"  SKIP — already exists")
        return True
    refs = [PIL.Image.open(p) for p in s["refs"]]
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
fail = []
for s in SPREADS:
    print(f"\n[{s['n']:02d}/18] === Spread {s['n']:02d} ===")
    if run_spread(s):
        ok += 1
    else:
        fail.append(s["n"])

print(f"\n=== BATCH DONE in {int(time.time()-total)}s ===")
print(f">>> {ok}/{len(SPREADS)} generated successfully")
if fail:
    print(f">>> Failed/empty: {fail}")
print(f">>> Outputs in {OUT_DIR}")
print(f">>> S1 + S2 NOT regenerated (already wide-ish in original batch)")
