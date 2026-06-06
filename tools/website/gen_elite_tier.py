"""Generate the Elite tier hero shots (21 Rares + Epics) and re-roll the 2
problem assets from the original batch (Mythic Plush wings, Goo & Fidgets faces).

Each hero shot is a single-character 1:1 portrait in the existing 3D card
style — NO card frame, NO text. Ready to use as website hero/decoration art.
"""
import sys, time
from pathlib import Path

import httpx
_orig = httpx.Client.__init__
_orig_a = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _orig(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _orig_a(s, *a, **kw))[1]

import PIL.Image
from google import genai
from google.genai import types

HOME = Path(r"C:\Users\chris")
SQ = HOME / "Squishy-smash" / "squishy_smash"
CARDS_DIR = SQ / "assets" / "cards" / "final_48"
OUT_DIR = SQ / "assets" / "website_hero"
OUT_DIR.mkdir(parents=True, exist_ok=True)

STYLE = """
STYLE (match reference image #1 EXACTLY):
- Glossy 3D digital illustration with soft clay-render quality
- Vibrant rim-light, soft cast shadows, smooth shading
- Sparkle particles and star bursts scattered around the character
- Premium mobile-game collectible illustration polish
- NOT painterly, NOT watercolor, NOT children's book illustration

STRICT: no card frame, no text, no letters, no name label, no rarity badge,
no stats, no UI. Character preserves the EXACT silhouette, color, and
features of the reference image — same body shape, same eye color, same
face details, same signature accessories. Render the character in a fresh
dynamic floating hover pose (NOT the static reference pose).
""".strip()

PACK_BACKGROUNDS = {
    "foods": "warm cosmic gradient — deep magenta-purple top fading to warm gold horizon glow at bottom. Scattered gold stars and one or two soft painted nebula swirls. Pudding-cosmic vibe.",
    "goo": "vibrant aqua-cyan cosmic gradient — deep teal-violet top fading to bright aqua-cyan glow at bottom. Scattered bubble-light orbs and soft cyan nebula swirls.",
    "creepy": "deep moonlit-violet cosmic gradient with painted aurora streaks. Scattered stars and soft purple-blue mystical mist swirls.",
}


# Cards to generate this run (21 Rares+Epics + 2 re-rolls)
def _card_path(num: int) -> Path:
    matches = list(CARDS_DIR.glob(f"{num:03d}_*.webp"))
    return matches[0] if matches else None


def _card_name(num: int) -> str:
    p = _card_path(num)
    if p is None:
        return f"card_{num:03d}"
    # Parse name from filename: "013_Galaxy_Dumpling.webp" -> "Galaxy Dumpling"
    parts = p.stem.split("_", 1)
    return parts[1].replace("_", " ")


def _pack_of(num: int) -> str:
    if 1 <= num <= 16:
        return "foods"
    if 17 <= num <= 32:
        return "goo"
    return "creepy"


def _slug(name: str) -> str:
    return name.lower().replace(" ", "_")


def gen_hero_shot(client, card_num: int):
    card_path = _card_path(card_num)
    name = _card_name(card_num)
    pack = _pack_of(card_num)
    out_path = OUT_DIR / f"hero_{card_num:03d}_{_slug(name)}.png"
    if out_path.exists():
        print(f"  [{card_num:03d}] {name} — exists, skipping")
        return out_path

    prompt = f"""
A hero-shot illustration of {name.upper()} in a fresh dynamic floating hover pose, as if catching cosmic energy.

CHARACTER (match reference image #1 EXACTLY): preserve the character's exact body shape, color, eye style, face details, and signature features from the reference. Render the SAME character in a new dynamic pose for use on a website hero section (NOT inside a card frame).

BACKGROUND: {PACK_BACKGROUNDS[pack]}

COMPOSITION: 1:1 square, character centered with hero-pose energy. Plenty of background sparkle and depth around the character.

{STYLE}
""".strip()

    config = types.GenerateContentConfig(
        image_config=types.ImageConfig(aspect_ratio="1:1"),
    )
    ref = PIL.Image.open(card_path)
    print(f"  [{card_num:03d}] {name} ({pack})... ", end="", flush=True)
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[prompt, ref],
        config=config,
    )
    for part in response.candidates[0].content.parts:
        if part.inline_data and part.inline_data.data:
            with open(out_path, "wb") as f:
                f.write(part.inline_data.data)
            kb = len(part.inline_data.data) / 1024
            print(f"-> {out_path.name} ({kb:.0f} KB)")
            return out_path
    print(f"ERROR: no image")
    return None


def reroll_mythic_plush(client):
    """Re-roll #048 Mythic Plush Familiar without wings."""
    card_path = _card_path(48)
    out_path = OUT_DIR / "hero_mythic_plush.png"  # overwrite original
    prompt = f"""
A hero-shot illustration of MYTHIC PLUSH FAMILIAR in a dynamic floating pose with magical aura swirling around it.

CHARACTER (match reference image #1 EXACTLY): preserve the cat-plush silhouette from the reference card. Small plush cat-creature body with pointed ears, gentle face. NO WINGS. NO MAGICAL STAFF. NO EXTRA ACCESSORIES BEYOND THOSE IN THE REFERENCE. Just the canon plush familiar in its mythic glow form.

BACKGROUND: {PACK_BACKGROUNDS['creepy']}

COMPOSITION: 1:1 square, character centered with hero-pose energy.

{STYLE}
""".strip()
    config = types.GenerateContentConfig(
        image_config=types.ImageConfig(aspect_ratio="1:1"),
    )
    ref = PIL.Image.open(card_path)
    print(f"  [RE-ROLL 048] Mythic Plush Familiar (no wings)... ", end="", flush=True)
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[prompt, ref],
        config=config,
    )
    for part in response.candidates[0].content.parts:
        if part.inline_data and part.inline_data.data:
            with open(out_path, "wb") as f:
                f.write(part.inline_data.data)
            kb = len(part.inline_data.data) / 1024
            print(f"-> {out_path.name} ({kb:.0f} KB)")
            return out_path
    print("ERROR")
    return None


def reroll_goo_pack(client):
    """Re-roll Goo & Fidgets pack banner with faces on all characters."""
    ref_cards = [_card_path(n) for n in [17, 25, 30, 32]]
    out_path = OUT_DIR / "pack_goo_fidgets.png"  # overwrite original
    prompt = f"""
A vibrant group hero scene of the GOO & FIDGETS pack characters gathered together on a glossy aqua goo-coast shoreline with bright water and bubble accents.

CHARACTERS (each MUST have a clear face with cute anime-style eyes and a gentle smile, matching reference images exactly):
- Reference 1: Goo Ball (round translucent blue goo, PURE BLACK DOT EYES not green, gentle smile, no human features) — center-front, slightly forward
- Reference 2: Glitter Goo Ball (sparkly blue-purple goo with face) — to the left, with cute face and eyes
- Reference 3: Aurora Stretch Cube (iridescent rainbow goo cube with face) — to the right, with cute face and eyes
- Reference 4: Singularity Goo Core (deep aurora-cyan glowing goo with swirling inner patterns and a face) — hovering slightly behind the trio, with face and eyes

IMPORTANT: ALL FOUR characters must have visible faces with cute eyes and gentle smiles — DO NOT render any of them as faceless abstract goo objects.

BACKGROUND: glossy goo-coast shoreline with bright teal water, soft bubble-light orbs, soft aqua-cyan sky.

COMPOSITION: 16:9 wide banner, all four characters clearly visible at appropriate scale (Goo Ball slightly forward), plenty of cool-toned background for a website-banner crop.

{STYLE}
""".strip()
    config = types.GenerateContentConfig(
        image_config=types.ImageConfig(aspect_ratio="16:9"),
    )
    refs = [PIL.Image.open(p) for p in ref_cards]
    print("  [RE-ROLL Goo Pack] 4 refs, asking for faces... ", end="", flush=True)
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[prompt, *refs],
        config=config,
    )
    for part in response.candidates[0].content.parts:
        if part.inline_data and part.inline_data.data:
            with open(out_path, "wb") as f:
                f.write(part.inline_data.data)
            kb = len(part.inline_data.data) / 1024
            print(f"-> {out_path.name} ({kb:.0f} KB)")
            return out_path
    print("ERROR")
    return None


def main():
    key = open(HOME / "gemini.key.txt").read().strip()
    client = genai.Client(api_key=key)

    # Elite tier: Rares (9-12, 25-28, 41-44) + Epics (13-15, 29-31, 45-47) per pack
    elite_cards = (
        list(range(9, 16)) +    # foods rares + epics: 9,10,11,12,13,14,15
        list(range(25, 32)) +   # goo rares + epics: 25,26,27,28,29,30,31
        list(range(41, 48))     # creepy rares + epics: 41,42,43,44,45,46,47
    )
    assert len(elite_cards) == 21, f"expected 21, got {len(elite_cards)}"

    t0 = time.time()
    print(f">>> Elite tier batch: {len(elite_cards)} new hero shots + 2 re-rolls")
    for num in elite_cards:
        gen_hero_shot(client, num)

    print(">>> Re-rolls:")
    reroll_mythic_plush(client)
    reroll_goo_pack(client)

    print(f">>> DONE in {int(time.time()-t0)}s, output: {OUT_DIR}")


if __name__ == "__main__":
    main()
