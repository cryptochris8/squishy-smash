"""
Stage 1 of the all-48 sprite restyle: generate best-of-N candidates per
squishy, each reference-locked to its trading-card art (Book 2 method).

Threaded + idempotent + resumable: existing candidate files are skipped,
so re-runs only fill gaps. Writes ONLY to _sprite_restyle_proto/candidates/.

  python tools/restyle_sprites_gen.py            # all 48, N=3
  python tools/restyle_sprites_gen.py --only goo_ball,jelly_bun
  python tools/restyle_sprites_gen.py --n 3 --workers 6 --force

Requires FAL_KEY in .env.
"""

import argparse
import io
import json
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from generate_pack_content import load_env, ENV_PATH  # noqa: E402
from prototype_sprite_restyle import (  # noqa: E402
    generate_referenced, card_data_uri,
)

OUT = REPO / "_sprite_restyle_proto"
CAND = OUT / "candidates"
CAND.mkdir(parents=True, exist_ok=True)

NAMES = [
    "Soft Dumpling", "Jelly Bun", "Peach Mochi", "Syrup Cube", "Cream Puff",
    "Rice Ball Squish", "Marshmallow Puff", "Pudding Pop", "Strawberry Dumpling",
    "Rainbow Jelly Bun", "Sparkle Mochi", "Golden Syrup Cube", "Galaxy Dumpling",
    "Crystal Mochi", "Neon Dessert Blob", "Celestial Dumpling Core",
    "Goo Ball", "Bubble Blob", "Stretch Cube", "Soft Stress Orb", "Jelly Pad",
    "Sticky Pop Ball", "Wobble Drop", "Squish Capsule", "Glitter Goo Ball",
    "Shockwave Blob", "Frost Gel Cube", "Prism Stress Orb", "Plasma Goo Ball",
    "Aurora Stretch Cube", "Cosmic Jelly Pad", "Singularity Goo Core",
    "Blushy Bun Bunny", "Squish Bat", "Puff Ghost", "Wobble Kitty",
    "Tiny Blob Monster", "Soft Fang Critter", "Sleepy Slime Pet",
    "Round Eared Creature", "Star Eyed Bunny", "Moon Bat Blob", "Glow Ghost Puff",
    "Candy Fang Creature", "Dream Eater Squish", "Arcane Wobble Kitty",
    "Phantom Jelly Beast", "Mythic Plush Familiar",
]


def build_cards():
    cards = []
    for i, name in enumerate(NAMES):
        n = i + 1
        num = f"{n:03d}"
        under = name.replace(" ", "_")
        slug = name.lower().replace(" ", "_")
        pack = ("Squishy Foods" if n <= 16 else
                "Goo & Fidgets" if n <= 32 else "Creepy-Cute Creatures")
        cards.append({
            "n": n, "num": num, "name": name, "slug": slug, "pack": pack,
            "card": str(REPO / "assets" / "cards" / "final_48" / f"{num}_{under}.webp"),
        })
    # Goo & Fidgets first (worst pack), then Creatures, then Foods.
    order = {"Goo & Fidgets": 0, "Creepy-Cute Creatures": 1, "Squishy Foods": 2}
    cards.sort(key=lambda c: (order[c["pack"]], c["n"]))
    return cards


def prompt_for(card):
    return (
        f"The reference image is a trading card for a squishy character named "
        f"\"{card['name']}\". Recreate ONLY the single main hero character in the "
        f"center of that card. Keep its EXACT colors, body shape, facial "
        f"expression, eyes, and every signature feature (patterns, toppings, "
        f"limbs, ears, glow, translucency, textures) faithful to the card. Render "
        f"that same character as one clean video-game sprite: a single centered "
        f"character, full body, facing forward in a cheerful neutral pose, on a "
        f"plain solid pure-white background. Glossy kawaii squishy 3D toy style "
        f"with soft studio lighting, matching the card's rendering. Do NOT include "
        f"the card border, any text, the rarity badge, the card frame, background "
        f"scenery, floating sparkles, extra characters, or props. Just the one "
        f"character, large and centered, on white."
    )


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--n", type=int, default=3, help="candidates per sprite")
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--only", default="", help="comma slugs to limit to")
    ap.add_argument("--force", action="store_true", help="regen even if present")
    args = ap.parse_args()

    env = load_env(ENV_PATH)
    fal_key = env.get("FAL_KEY")
    if not fal_key:
        print("ERROR: FAL_KEY missing in .env"); sys.exit(1)

    cards = build_cards()
    if args.only:
        keep = {s.strip() for s in args.only.split(",")}
        cards = [c for c in cards if c["slug"] in keep]

    (OUT / "mapping.json").write_text(json.dumps(cards, indent=2), encoding="utf-8")

    # Build the task list (slug, idx) skipping existing unless --force
    tasks = []
    for c in cards:
        d = CAND / c["slug"]
        d.mkdir(parents=True, exist_ok=True)
        for i in range(args.n):
            f = d / f"cand_{i}.png"
            if args.force or not f.exists():
                tasks.append((c, i, f))

    print(f"Cards: {len(cards)} | candidates/sprite: {args.n} | "
          f"to generate: {len(tasks)} (skipping existing)")
    if not tasks:
        print("Nothing to do."); return

    done = {"ok": 0, "fail": 0}

    def work(item):
        c, i, f = item
        try:
            b = generate_referenced(fal_key, prompt_for(c), card_data_uri(Path(c["card"])))
            Image.open(io.BytesIO(b)).convert("RGBA").save(f)
            return (c["slug"], i, True, "")
        except Exception as e:
            return (c["slug"], i, False, str(e)[:160])

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(work, t) for t in tasks]
        for fut in as_completed(futs):
            slug, i, ok, err = fut.result()
            if ok:
                done["ok"] += 1
                print(f"  [{done['ok']+done['fail']}/{len(tasks)}] ok   {slug} #{i}")
            else:
                done["fail"] += 1
                print(f"  [{done['ok']+done['fail']}/{len(tasks)}] FAIL {slug} #{i}: {err}")

    print(f"\nDone. ok={done['ok']} fail={done['fail']}")
    print("Candidates in _sprite_restyle_proto/candidates/<slug>/cand_*.png")


if __name__ == "__main__":
    main()
