"""Mock: regenerate one Legendary card character in the Book-2 painterly style.

Uses the same Nano Banana Pro pipeline as the book2 spreads (multi-image
reference + painterly prompt) to render Celestial Dumpling Core (#016) as
a hand-painted hero character at 3:4 aspect, no card frame, no text.

The result is saved alongside the current card for a side-by-side review.
"""
import os, sys
from pathlib import Path

# SSL workaround for Windows + google-genai (per book2 pipeline memory)
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

CARD_NUM = "016"
CARD_NAME = "Celestial Dumpling Core"
REF_CARD = CARDS_DIR / "016_Celestial_Dumpling_Core.webp"
OUT_PATH = OUT_DIR / "_card016_painterly_mock.png"

PROMPT = """
A hand-painted children's picture book character illustration of CELESTIAL DUMPLING CORE — a small, sweet, gentle dumpling-shaped being that glows with soft golden inner light. The character has the canon Soft Dumpling silhouette (peach egg-shape with a tiny spiral curl tuft on top, two small dot eyes, gentle smile, no arms or legs visible — just the round dumpling body), but rendered in a cosmic-legendary form: the body glows with warm golden light from within, with tiny painted stars and constellation freckles softly scattered across the cream-warm dumpling surface. A delicate halo of soft watercolor stardust surrounds the character.

STYLE: painterly watercolor and gouache, Christopher Denise inspired, Knight Owl visual lane. Soft visible brushwork, cream paper showing through pigment. Hand-painted children's book illustration — NOT digital airbrushing, NOT 3D rendering, NOT a video game card. Loose painterly edges, gentle washes.

BACKGROUND: soft painterly cosmic backdrop — deep dusk-purple and navy washes with tiny scattered painted stars and a warm horizon glow at the bottom. Looks like a watercolor night sky, not a digital nebula. Plenty of negative space.

COMPOSITION: 3:4 portrait, character centered slightly above center, taking ~50% of the frame. Plenty of painted negative space around the character so a card frame could be added later if needed.

PALETTE: deep teal-indigo sky #1B2440, warm horizon glow #E4A56C, dumpling glow color cream-gold #F5C97A, character body warm peach-cream #F8DDB8. Matches the Book 2 cover dusk-warm palette.

STRICT: no text, no letters, no card frame, no UI elements, no rarity badges, no stats. Just the painted character and the painted sky. No third arm. No extra limbs. No human features beyond the canon dumpling face (two small dot eyes + gentle smile).
""".strip()


def main():
    key = open(HOME / "gemini.key.txt").read().strip()
    client = genai.Client(api_key=key)

    config = types.GenerateContentConfig(
        image_config=types.ImageConfig(aspect_ratio="3:4"),
    )

    ref = PIL.Image.open(REF_CARD)
    print(f"Reference: {REF_CARD.name} ({ref.size})")
    print(f"Generating painterly mock for {CARD_NAME}...")

    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[PROMPT, ref],
        config=config,
    )

    # Extract image bytes from response
    for part in response.candidates[0].content.parts:
        if part.inline_data and part.inline_data.data:
            with open(OUT_PATH, "wb") as f:
                f.write(part.inline_data.data)
            size_kb = len(part.inline_data.data) / 1024
            print(f"Saved {OUT_PATH} ({size_kb:.1f} KB)")
            return
    print("ERROR: no image in response")
    print(response)
    sys.exit(1)


if __name__ == "__main__":
    main()
