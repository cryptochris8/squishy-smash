"""Mock v2: regenerate Celestial Dumpling Core in the existing 3D card style
but in a new action/hero pose outside the card frame.

Uses Nano Banana Pro with the existing card as BOTH character reference AND
style reference. Goal: keep the cards in their lane, but expand the
character library for non-card website use (hero shots, ambient decoration,
pack callouts, scene art).
"""
import sys
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
OUT_DIR = SQ / "book" / "build_book2" / "out"

REF_CARD = CARDS_DIR / "016_Celestial_Dumpling_Core.webp"
OUT_PATH = OUT_DIR / "_card016_3d_pose_mock.png"

PROMPT = """
A hero-shot illustration of CELESTIAL DUMPLING CORE in a dynamic floating hover pose — same character as the reference image, same exact visual style as the reference image, but in a fresh dynamic pose for use on a website hero section (NOT inside a card frame).

CHARACTER ANCHOR (matches reference image exactly):
- Round peach-cream dumpling body with a small spiral curl tuft on top
- Two big shiny anime-style sparkle eyes, gentle happy smile
- Body glows from within with warm golden cosmic light
- Tiny gold constellation freckles and star markings scattered across the cream body
- Painted glowing planetary rings orbiting around the body at a soft tilt
- No arms, no legs visible (it is a dumpling — that's the canon silhouette)

STYLE (match the reference image EXACTLY):
- Glossy 3D digital illustration with soft clay-render quality
- Vibrant rim-light, soft cast shadows, smooth shading
- Sparkle particles and star bursts scattered around the character
- Same lush vibrant cosmic palette as the reference: warm gold core, magenta-purple, deep cosmic blue
- Same brand polish — looks like a premium mobile game collectible illustration
- NOT painterly, NOT watercolor, NOT children's book illustration — keep the digital game-art aesthetic

COMPOSITION: 3:4 portrait orientation. Character centered, slightly mid-air floating hover pose with a gentle upward tilt as if catching a breath of starlight. Plenty of background sparkle and depth around the character.

BACKGROUND: vibrant cosmic gradient — deep magenta-purple top fading to warm gold horizon glow at bottom, scattered tiny stars and one or two larger painted nebula swirls in the deep background. Same cosmic legendary vibe as the reference card.

STRICT: no card frame, no text, no letters, no name label, no rarity badge, no stats, no UI. Just the character floating in the cosmic scene. No extra limbs, no arms, no legs.
""".strip()


def main():
    key = open(HOME / "gemini.key.txt").read().strip()
    client = genai.Client(api_key=key)

    config = types.GenerateContentConfig(
        image_config=types.ImageConfig(aspect_ratio="3:4"),
    )

    ref = PIL.Image.open(REF_CARD)
    print(f"Reference: {REF_CARD.name} ({ref.size})")
    print("Generating 3D card-style mock in new floating pose...")

    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[PROMPT, ref],
        config=config,
    )

    for part in response.candidates[0].content.parts:
        if part.inline_data and part.inline_data.data:
            with open(OUT_PATH, "wb") as f:
                f.write(part.inline_data.data)
            size_kb = len(part.inline_data.data) / 1024
            print(f"Saved {OUT_PATH} ({size_kb:.1f} KB)")
            return
    print("ERROR: no image in response")
    sys.exit(1)


if __name__ == "__main__":
    main()
