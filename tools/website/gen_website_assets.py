"""Generate the website refresh asset batch via Nano Banana Pro.

Output assets (saved to `assets/website_hero/`):
  - hero_celestial_dumpling.png  (Legendary, 1:1)
  - hero_singularity_goo.png     (Legendary, 1:1)
  - hero_mythic_plush.png        (Legendary, 1:1)
  - pack_squishy_foods.png       (16:9 banner)
  - pack_goo_fidgets.png         (16:9 banner)
  - pack_creepy_cute.png         (16:9 banner)
  - trio_book2_protagonists.png  (16:9 banner)

Style target: match the existing 3D card lane — glossy clay-render, vibrant
cosmic gradients, sparkle accents. Each shot is FRAMELESS (no card UI) so
the website can present them at any size/crop.

Cost: ~$0.13 per generation × 7 = ~$1.
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


# ---- Shared style prefix (every asset gets this for lane consistency) ----
STYLE_BLOCK = """
STYLE (match the reference card images EXACTLY):
- Glossy 3D digital illustration with soft clay-render quality
- Vibrant rim-light, soft cast shadows, smooth shading
- Sparkle particles and star bursts scattered around the characters
- Premium mobile-game collectible illustration polish
- NOT painterly, NOT watercolor, NOT children's book illustration — keep the digital game-art aesthetic

STRICT: no card frame, no text, no letters, no name label, no rarity badge, no stats, no UI.
""".strip()


# ============================================================================
# Asset definitions
# ============================================================================
ASSETS = [
    # ---- 3 Legendary hero shots (1:1, single character, hero pose) ----
    {
        "name": "hero_celestial_dumpling",
        "refs": ["016_Celestial_Dumpling_Core.webp"],
        "aspect": "1:1",
        "prompt": f"""
A hero-shot illustration of CELESTIAL DUMPLING CORE in a dynamic floating hover pose with arms gently outstretched as if cradling cosmic energy.

CHARACTER (matches reference image #1 exactly): peach-cream dumpling body with small spiral curl tuft, big shiny anime sparkle eyes, gentle happy smile, warm golden cosmic inner glow, tiny gold constellation freckles on body, glowing painted planetary rings orbiting at a soft tilt around the body.

BACKGROUND: vibrant cosmic gradient — deep magenta-purple top fading to warm gold horizon glow at bottom. Scattered stars + 1-2 painted nebula swirls.

COMPOSITION: 1:1 square, character centered with hero-pose energy.

{STYLE_BLOCK}
""".strip(),
    },
    {
        "name": "hero_singularity_goo",
        "refs": ["032_Singularity_Goo_Core.webp"],
        "aspect": "1:1",
        "prompt": f"""
A hero-shot illustration of SINGULARITY GOO CORE floating in cosmic space with glossy goo orbs spinning around it.

CHARACTER (matches reference image #1 exactly): the canonical Goo Ball silhouette (round translucent blue-cyan goo body with PURE BLACK DOT EYES not green, gentle smile, no human features), but in its Legendary singularity form — body glows with deep aurora-cyan inner light, swirling iridescent goo energy patterns visible inside the body, smaller goo droplets orbiting around it like a planetary system.

BACKGROUND: deep cosmic ocean-blue gradient fading to bright aurora-cyan glow at center behind the character. Scattered stars and bubble-like light orbs.

COMPOSITION: 1:1 square, character centered with hero-pose energy.

{STYLE_BLOCK}
""".strip(),
    },
    {
        "name": "hero_mythic_plush",
        "refs": ["048_Mythic_Plush_Familiar.webp"],
        "aspect": "1:1",
        "prompt": f"""
A hero-shot illustration of MYTHIC PLUSH FAMILIAR in a dynamic floating pose with magical aura swirling around it.

CHARACTER (matches reference image #1 exactly): the Mythic Plush Familiar silhouette from the reference card, with its signature plush-creature form, gentle face, and ethereal magical glow.

BACKGROUND: deep moonlit-violet gradient with painted aurora streaks. Scattered stars + soft purple-blue mystical mist swirls.

COMPOSITION: 1:1 square, character centered with hero-pose energy.

{STYLE_BLOCK}
""".strip(),
    },
    # ---- 3 pack group shots (16:9 banner, multi-character scenes) ----
    {
        "name": "pack_squishy_foods",
        "refs": ["001_Soft_Dumpling.webp", "011_Sparkle_Mochi.webp",
                  "013_Galaxy_Dumpling.webp", "016_Celestial_Dumpling_Core.webp"],
        "aspect": "16:9",
        "prompt": f"""
A vibrant group hero scene of the SQUISHY FOODS pack characters gathered together in a warm cream-and-peach pudding-hills landscape under a warm-pastel sunset sky.

CHARACTERS (match reference images exactly): four members of the Squishy Foods pack arranged in a soft triangular group composition —
- Reference 1: Soft Dumpling (peach dumpling, spiral curl tuft) standing front and slightly forward
- Reference 2: Sparkle Mochi (small pink shimmery mochi) at one side, smaller
- Reference 3: Galaxy Dumpling (cosmic purple-blue dumpling with stars on body) at the other side
- Reference 4: Celestial Dumpling Core (glowing golden dumpling with constellation freckles) hovering slightly above and behind the others

BACKGROUND: warm cream pudding-hills landscape, soft peach sunset sky, a few painted clouds and stars. Squishy Foods palette — warm cream, peach, gold.

COMPOSITION: 16:9 wide banner, all four characters clearly visible at appropriate scale (protagonist Soft Dumpling slightly forward), plenty of warm-toned background for a website-banner crop.

{STYLE_BLOCK}
""".strip(),
    },
    {
        "name": "pack_goo_fidgets",
        "refs": ["017_Goo_Ball.webp", "025_Glitter_Goo_Ball.webp",
                  "030_Aurora_Stretch_Cube.webp", "032_Singularity_Goo_Core.webp"],
        "aspect": "16:9",
        "prompt": f"""
A vibrant group hero scene of the GOO & FIDGETS pack characters gathered together on a glossy aqua goo-coast shoreline with bright water and bubble accents.

CHARACTERS (match reference images exactly): four members of the Goo & Fidgets pack arranged in a soft group composition —
- Reference 1: Goo Ball (round translucent blue goo with PURE BLACK DOT EYES not green) standing front and slightly forward
- Reference 2: Glitter Goo Ball (sparkly blue-purple goo) at one side
- Reference 3: Aurora Stretch Cube (iridescent rainbow goo cube) at the other side
- Reference 4: Singularity Goo Core (deep aurora-cyan glowing goo with swirling inner patterns) hovering slightly behind

BACKGROUND: glossy goo-coast shoreline with bright teal water, soft bubble-light orbs, soft aqua-cyan sky. Goo Coast palette — bright teal, aqua, cyan, mint.

COMPOSITION: 16:9 wide banner, all four characters clearly visible at appropriate scale (Goo Ball slightly forward), plenty of cool-toned background for a website-banner crop.

{STYLE_BLOCK}
""".strip(),
    },
    {
        "name": "pack_creepy_cute",
        "refs": ["033_Blushy_Bun_Bunny.webp", "041_Star_Eyed_Bunny.webp",
                  "043_Glow_Ghost_Puff.webp", "048_Mythic_Plush_Familiar.webp"],
        "aspect": "16:9",
        "prompt": f"""
A vibrant group hero scene of the CREEPY-CUTE CREATURES pack characters gathered together in a soft moonlit-hollow forest glade with painted purple-violet sky.

CHARACTERS (match reference images exactly): four members of the Creepy-Cute pack arranged in a soft group composition —
- Reference 1: Blushy Bun Bunny (PURE WHITE body, LONG FLOPPY DROOPY ears hanging down, pink ear interior + nose + paw pads) standing front and slightly forward
- Reference 2: Star-Eyed Bunny (white bunny with yellow star-eyes) at one side
- Reference 3: Glow Ghost Puff (small floating glowing ghost-puff) at the other side
- Reference 4: Mythic Plush Familiar (plush creature with ethereal glow) hovering slightly behind

BACKGROUND: moonlit forest glade, soft purple-violet sky with painted moon and stars, gentle mushroom and foliage silhouettes. Moonlit Hollow palette — soft violet, lavender, deep purple, cool-cream highlights.

COMPOSITION: 16:9 wide banner, all four characters clearly visible at appropriate scale (Bun slightly forward), plenty of cool moonlit background for a website-banner crop.

{STYLE_BLOCK}
""".strip(),
    },
    # ---- Trio shot for Book 2 cross-promo (16:9) ----
    {
        "name": "trio_book2_protagonists",
        "refs": ["001_Soft_Dumpling.webp", "017_Goo_Ball.webp",
                  "033_Blushy_Bun_Bunny.webp"],
        "aspect": "16:9",
        "prompt": f"""
A hero-banner illustration of the three Book 2 protagonists meeting at a border under a dusk-warm sky.

CHARACTERS (match reference images exactly):
- Soft Dumpling (peach dumpling, spiral curl tuft) — center-front
- Goo Ball (round translucent blue goo with PURE BLACK DOT EYES not green) — left of center
- Blushy Bun Bunny (PURE WHITE body, LONG FLOPPY DROOPY ears) — right of center

POSE: standing together in a triangular group, gentle smiles, looking up toward a small warm-gold sparkle floating above them.

BACKGROUND: Knight-Owl dusk palette — deep teal-indigo sky top fading to warm coral/peach horizon glow at bottom. Gentle painted hillside ground. Soft scattered stars in the deeper sky.

COMPOSITION: 16:9 wide banner, all three characters clearly visible, the sparkle hovering above and centered.

{STYLE_BLOCK}
""".strip(),
    },
]


def gen_asset(client, asset, attempt=1):
    refs = [PIL.Image.open(CARDS_DIR / r) for r in asset["refs"]]
    config = types.GenerateContentConfig(
        image_config=types.ImageConfig(aspect_ratio=asset["aspect"]),
    )
    out_path = OUT_DIR / f"{asset['name']}.png"
    print(f"  [{asset['name']}] {len(refs)} refs, aspect {asset['aspect']}, attempt {attempt}")
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[asset["prompt"], *refs],
        config=config,
    )
    for part in response.candidates[0].content.parts:
        if part.inline_data and part.inline_data.data:
            with open(out_path, "wb") as f:
                f.write(part.inline_data.data)
            kb = len(part.inline_data.data) / 1024
            print(f"    -> {out_path.name} ({kb:.1f} KB)")
            return out_path
    print(f"    ERROR: no image returned")
    return None


def main():
    key = open(HOME / "gemini.key.txt").read().strip()
    client = genai.Client(api_key=key)
    t0 = time.time()
    print(f">>> Generating {len(ASSETS)} website hero assets")
    for asset in ASSETS:
        gen_asset(client, asset)
    print(f">>> DONE in {int(time.time()-t0)}s")
    print(f">>> Output: {OUT_DIR}")


if __name__ == "__main__":
    main()
