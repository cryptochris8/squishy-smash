"""
Generate sprites, thumbnails, and impact/burst sounds for the three
launch packs (Squishy Foods, Goo & Fidgets, Creepy-Cute Creatures) to
hit the 8C/4R/3E/1L rarity-map target per pack.

Run from project root:
    python tools/generate_pack_content.py --help

Default mode is dry-run. Nothing is called until you pass --execute.

Asset placement:
    assets/images/objects/<id>.png           1024x1024 sprite
    assets/images/thumbnails/<id>_thumb.png  256x256 downsample
    assets/audio/<category>/<id>_squish_0N.mp3  (3 variants)
    assets/audio/<category>/<id>_burst_01.mp3

Pack JSONs are patched in-place to append the new objects.

Deps: requests, Pillow. Already installed in this env.
API keys: loaded from .env in repo root. Required: FAL_KEY,
ELEVENLABS_API_KEY.
"""

import argparse
import io
import json
import os
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import requests
from PIL import Image


def _retry(fn, *args, attempts: int = 4, backoff: float = 2.0, **kwargs):
    """Call fn with up to [attempts] retries on network/HTTP transients.
    Backs off 2s, 4s, 8s. Re-raises the last error if all attempts fail."""
    last_err = None
    for i in range(attempts):
        try:
            return fn(*args, **kwargs)
        except (requests.exceptions.ConnectionError,
                requests.exceptions.Timeout,
                requests.exceptions.ChunkedEncodingError) as e:
            last_err = e
            wait = backoff ** i
            print(f"      retry {i + 1}/{attempts} after {wait:.0f}s "
                  f"({type(e).__name__}: {str(e)[:60]})")
            time.sleep(wait)
        except requests.exceptions.HTTPError as e:
            status = e.response.status_code if e.response is not None else 0
            if status in (429, 500, 502, 503, 504):
                last_err = e
                wait = backoff ** i
                print(f"      retry {i + 1}/{attempts} after {wait:.0f}s "
                      f"(HTTP {status})")
                time.sleep(wait)
                continue
            raise
    raise last_err

REPO_ROOT = Path(__file__).resolve().parent.parent
ENV_PATH = REPO_ROOT / ".env"

# ---------------------------------------------------------------------
# Env loading — no python-dotenv dependency; just parse KEY=VALUE lines.
# ---------------------------------------------------------------------


def load_env(path: Path) -> dict:
    env = {}
    if not path.exists():
        return env
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


# ---------------------------------------------------------------------
# Content plan — 39 new items across three packs.
# Existing objects (dumplio, jellyzap, poppling, slimeorb, goodrop,
# popzee, squishkin, snagglet, gloomp) stay untouched. These are the
# NEW additions that bring each pack to 16.
# ---------------------------------------------------------------------


@dataclass
class NewObject:
    id: str                   # slug; file names derive from this
    name: str                 # display name
    rarity: str               # common | rare | epic | mythic
    behavior_profile: str     # see lib/data/models/behavior_profile.dart
    art_prompt: str           # image prompt (style prefix auto-added)
    sound_kind: str           # for audio prompts: "squish" | "pop" | "wobble"
    particle_preset: str      # references existing decal system
    decal_preset: str
    theme_tag: str            # free-form tag for searching
    coin_reward: int
    unlock_tier: int = 1
    search_tags: list = field(default_factory=list)


# Shared art-style baseline — prefixes every image prompt.
ART_STYLE_PREFIX = (
    "Adorable kawaii squishy 3D character, soft toy material with "
    "glossy matte finish, cute round proportions, large shiny eyes "
    "with tiny white highlights, pink blush on cheeks, warm friendly "
    "expression, centered composition, plain white background, "
    "clean alpha edges, no shadow, studio lighting. Subject: "
)

# Rarity shorthand for readability
C, R, E, M = "common", "rare", "epic", "mythic"

SQUISHY_FOODS_NEW = [
    # 6 commons to reach 8 (dumplio + jellyzap already common)
    NewObject("peach_mochi", "Peach Mochi", C, "mochi",
              "a peach-pink mochi ball with a tiny leaf on top, smiling gently",
              "squish", "pink_soup_burst", "soft_peach_splat",
              "mochi", 8, search_tags=["mochi", "peach", "dessert"]),
    NewObject("syrup_cube", "Syrup Cube", C, "jelly_cube",
              "a glossy amber syrup-jelly cube, translucent with tiny bubbles inside",
              "squish", "blue_jelly_burst", "cream_smudge",
              "jelly", 9, search_tags=["syrup", "jelly", "cube"]),
    NewObject("cream_puff", "Cream Puff", C, "dumpling",
              "a fluffy cream puff pastry with whipped cream peeking out the top",
              "squish", "cream_puff_burst", "cream_smudge",
              "pastry", 9, search_tags=["cream", "puff", "pastry"]),
    NewObject("rice_ball_squish", "Rice Ball Squish", C, "dumpling",
              "a plump white rice ball (onigiri) with a tiny nori belt and shy smile",
              "squish", "cream_puff_burst", "cream_smudge",
              "onigiri", 8, search_tags=["rice", "onigiri", "food"]),
    NewObject("marshmallow_puff", "Marshmallow Puff", C, "dumpling",
              "a pillowy marshmallow with pastel pink and blue swirls",
              "squish", "pink_soup_burst", "soft_peach_splat",
              "marshmallow", 10, search_tags=["marshmallow", "soft"]),
    NewObject("pudding_pop", "Pudding Pop", C, "jelly_cube",
              "a wobbling caramel pudding with a cherry on top",
              "wobble", "cream_puff_burst", "cream_smudge",
              "pudding", 10, search_tags=["pudding", "wobble"]),
    # 3 rares to reach 4 (poppling already rare)
    NewObject("rainbow_jelly_bun", "Rainbow Jelly Bun", R, "jelly_cube",
              "a translucent steamed bun filled with rainbow jelly, iridescent shimmer",
              "squish", "blue_jelly_burst", "cool_blue_smear",
              "jelly_bun", 16, unlock_tier=2,
              search_tags=["rainbow", "jelly", "rare"]),
    NewObject("sparkle_mochi", "Sparkle Mochi", R, "mochi",
              "a pastel mochi ball dusted with tiny star-shaped sparkles",
              "squish", "cream_puff_burst", "soft_peach_splat",
              "sparkle_mochi", 16, unlock_tier=2,
              search_tags=["sparkle", "mochi", "rare"]),
    NewObject("golden_syrup_cube", "Golden Syrup Cube", R, "jelly_cube",
              "a golden honey-jelly cube with flecks of real gold leaf suspended inside",
              "squish", "blue_jelly_burst", "cream_smudge",
              "gold_syrup", 18, unlock_tier=2,
              search_tags=["gold", "syrup", "rare"]),
    # 3 epics
    NewObject("galaxy_dumpling", "Galaxy Dumpling", E, "dumpling",
              "a dumpling with deep purple galaxy swirls and tiny stars across its surface",
              "squish", "purple_monster_burst", "purple_monster_splat",
              "galaxy", 28, unlock_tier=3,
              search_tags=["galaxy", "dumpling", "epic"]),
    NewObject("crystal_mochi", "Crystal Mochi", E, "mochi",
              "a faceted crystalline mochi that catches light like a gemstone",
              "squish", "blue_jelly_burst", "cool_blue_smear",
              "crystal", 28, unlock_tier=3,
              search_tags=["crystal", "mochi", "epic"]),
    NewObject("neon_dessert_blob", "Neon Dessert Blob", E, "jelly_cube",
              "a glowing neon-pink-and-cyan jelly blob pulsing with soft light",
              "wobble", "pink_soup_burst", "cool_blue_smear",
              "neon", 30, unlock_tier=3,
              search_tags=["neon", "jelly", "epic"]),
    # 1 legendary
    NewObject("celestial_dumpling_core", "Celestial Dumpling Core", M, "dumpling",
              "a radiant celestial dumpling with golden rays, floating in a halo of light, "
              "tiny stars orbiting around it, magical mythic energy",
              "squish", "cream_puff_burst", "gold_mythic_splat",
              "celestial_legendary", 120, unlock_tier=5,
              search_tags=["celestial", "legendary", "mythic"]),
]

GOO_FIDGETS_NEW = [
    # Existing: slimeorb (C), goodrop (R), popzee (C)
    NewObject("bubble_blob", "Bubble Blob", C, "goo_ball",
              "a translucent bubble-blob fidget with rainbow surface tension",
              "pop", "green_goo_burst", "green_goo_smear",
              "bubble", 10, search_tags=["bubble", "fidget"]),
    NewObject("stretch_cube", "Stretch Cube", C, "stress_ball",
              "a pastel-pink squishy cube being gently stretched, elastic bands",
              "squish", "pink_soup_burst", "soft_peach_splat",
              "stretch", 11, search_tags=["stretch", "cube", "fidget"]),
    NewObject("soft_stress_orb", "Soft Stress Orb", C, "stress_ball",
              "a smooth cream-colored stress ball with a cute happy face",
              "squish", "cream_puff_burst", "cream_smudge",
              "stress_ball", 10, search_tags=["stress", "ball", "fidget"]),
    NewObject("jelly_pad", "Jelly Pad", C, "jelly_cube",
              "a flat square wobbly jelly pad in mint green, jiggling",
              "wobble", "blue_jelly_burst", "cool_blue_smear",
              "jelly_pad", 10, search_tags=["jelly", "pad"]),
    NewObject("sticky_pop_ball", "Sticky Pop Ball", C, "goo_ball",
              "a translucent sticky goo ball with lavender color and glossy drips",
              "pop", "purple_monster_burst", "purple_monster_splat",
              "sticky", 11, search_tags=["sticky", "pop", "fidget"]),
    NewObject("wobble_drop", "Wobble Drop", C, "jelly_cube",
              "a teardrop-shaped jelly that wobbles, turquoise with glossy surface",
              "wobble", "blue_jelly_burst", "cool_blue_smear",
              "wobble", 10, search_tags=["wobble", "drop"]),
    # 3 rares to reach 4 (goodrop already rare)
    NewObject("glitter_goo_ball", "Glitter Goo Ball", R, "goo_ball",
              "a goo ball filled with sparkling silver glitter suspended in clear gel",
              "pop", "green_goo_burst", "green_goo_smear",
              "glitter_goo", 18, unlock_tier=2,
              search_tags=["glitter", "goo", "rare"]),
    NewObject("shockwave_blob", "Shockwave Blob", R, "goo_ball",
              "an electric-blue blob with tiny lightning arcs rippling across its surface",
              "pop", "blue_jelly_burst", "cool_blue_smear",
              "shockwave", 18, unlock_tier=2,
              search_tags=["shockwave", "electric", "rare"]),
    NewObject("frost_gel_cube", "Frost Gel Cube", R, "jelly_cube",
              "an icy pale-blue gel cube with frost crystals on its edges",
              "squish", "blue_jelly_burst", "cool_blue_smear",
              "frost", 19, unlock_tier=2,
              search_tags=["frost", "ice", "rare"]),
    # 3 epics
    NewObject("plasma_goo_ball", "Plasma Goo Ball", E, "goo_ball",
              "a goo ball glowing with swirling magenta plasma, electric energy inside",
              "pop", "pink_soup_burst", "purple_monster_splat",
              "plasma", 32, unlock_tier=3,
              search_tags=["plasma", "goo", "epic"]),
    NewObject("aurora_stretch_cube", "Aurora Stretch Cube", E, "stress_ball",
              "a stretchy cube rippling with northern-lights aurora colors, green to violet",
              "squish", "green_goo_burst", "green_goo_smear",
              "aurora", 32, unlock_tier=3,
              search_tags=["aurora", "stretch", "epic"]),
    NewObject("cosmic_jelly_pad", "Cosmic Jelly Pad", E, "jelly_cube",
              "a flat jelly pad with a galaxy of tiny stars swirling beneath the surface",
              "wobble", "purple_monster_burst", "purple_monster_splat",
              "cosmic", 34, unlock_tier=3,
              search_tags=["cosmic", "jelly", "epic"]),
    # 1 legendary
    NewObject("singularity_goo_core", "Singularity Goo Core", M, "goo_ball",
              "a pitch-black glossy goo core with a tiny bright singularity at its center, "
              "warping light around it, prism rainbow refractions, mythic rare energy",
              "pop", "green_goo_burst", "gold_mythic_splat",
              "singularity", 130, unlock_tier=5,
              search_tags=["singularity", "legendary", "mythic"]),
]

CREEPY_CUTE_NEW = [
    # Existing: squishkin (C), snagglet (R), gloomp (E)
    # 7 commons to reach 8
    NewObject("blushy_bun_bunny", "Blushy Bun Bunny", C, "creature",
              "a chubby white bunny squishy with huge blushing cheeks and tiny paws",
              "squish", "pink_soup_burst", "soft_peach_splat",
              "bunny", 12, search_tags=["bunny", "creature"]),
    NewObject("squish_bat", "Squish Bat", C, "creature",
              "a tiny purple squish-bat with round body, little fangs, cute wings",
              "squish", "purple_monster_burst", "purple_monster_splat",
              "bat", 12, search_tags=["bat", "creepy_cute"]),
    NewObject("puff_ghost", "Puff Ghost", C, "creature",
              "a smiling pastel ghost with a rounded puffy body and tiny arms",
              "squish", "cream_puff_burst", "cream_smudge",
              "ghost", 12, search_tags=["ghost", "spooky"]),
    NewObject("wobble_kitty", "Wobble Kitty", C, "creature",
              "a round cat squishy with pointed ears, a tiny nose, and wide curious eyes",
              "squish", "pink_soup_burst", "soft_peach_splat",
              "cat", 13, search_tags=["cat", "kitty"]),
    NewObject("tiny_blob_monster", "Tiny Blob Monster", C, "creature",
              "a cute lime-green blob monster with one big eye and little nubby arms",
              "wobble", "green_goo_burst", "green_goo_smear",
              "blob_monster", 12, search_tags=["monster", "blob"]),
    NewObject("soft_fang_critter", "Soft Fang Critter", C, "creature",
              "a round pink critter with tiny soft fangs peeking out of its smile",
              "squish", "pink_soup_burst", "soft_peach_splat",
              "fang", 13, search_tags=["fang", "critter"]),
    NewObject("sleepy_slime_pet", "Sleepy Slime Pet", C, "creature",
              "a sleepy pastel-blue slime with droopy eyes and a dozing smile",
              "wobble", "blue_jelly_burst", "cool_blue_smear",
              "slime_pet", 12, search_tags=["slime", "sleepy"]),
    # 3 rares to reach 4 (snagglet already rare)
    NewObject("star_eyed_bunny", "Star-Eyed Bunny", R, "creature",
              "a white bunny squishy with sparkling star-shaped eyes and magical aura",
              "squish", "cream_puff_burst", "cream_smudge",
              "star_bunny", 22, unlock_tier=2,
              search_tags=["bunny", "star", "rare"]),
    NewObject("moon_bat_blob", "Moon Bat Blob", R, "creature",
              "a deep-blue bat blob with a crescent moon glowing on its forehead",
              "squish", "purple_monster_burst", "cool_blue_smear",
              "moon_bat", 22, unlock_tier=2,
              search_tags=["moon", "bat", "rare"]),
    NewObject("glow_ghost_puff", "Glow Ghost Puff", R, "creature",
              "a glowing white ghost puff with soft light radiating out, twinkle sparkles",
              "squish", "cream_puff_burst", "cream_smudge",
              "glow_ghost", 24, unlock_tier=2,
              search_tags=["ghost", "glow", "rare"]),
    # 2 epics to reach 3 (gloomp already epic)
    NewObject("dream_eater_squish", "Dream Eater Squish", E, "creature",
              "a small violet-and-pink creature with soft dreamy swirls on its belly, "
              "tiny starry wings, mystical aura",
              "squish", "purple_monster_burst", "purple_monster_splat",
              "dream_eater", 36, unlock_tier=3,
              search_tags=["dream_eater", "epic"]),
    NewObject("arcane_wobble_kitty", "Arcane Wobble Kitty", E, "creature",
              "a mystical cat squishy with glowing arcane runes on its forehead and paws, "
              "deep purple body with gold accents",
              "squish", "purple_monster_burst", "gold_mythic_splat",
              "arcane_kitty", 36, unlock_tier=3,
              search_tags=["arcane", "cat", "epic"]),
    # 1 legendary
    NewObject("mythic_plush_familiar", "Mythic Plush Familiar", M, "creature",
              "a radiant plush familiar with gold-and-white fur, glowing runes, a tiny crown, "
              "floating in a halo of magical light, rainbow aura, legendary mythic creature",
              "squish", "cream_puff_burst", "gold_mythic_splat",
              "legendary_familiar", 140, unlock_tier=5,
              search_tags=["legendary", "familiar", "mythic"]),
]

# Pack metadata drives audio folder routing + JSON patch target.
PACK_PLAN = {
    "squishy_foods": {
        "json": "assets/data/packs/launch_squishy_foods.json",
        "audio_dir": "food",
        "category": "squishy_food",
        "theme_tag_default": "viral_food_energy",
        "items": SQUISHY_FOODS_NEW,
    },
    "goo_fidgets": {
        "json": "assets/data/packs/goo_fidgets_drop_01.json",
        "audio_dir": "goo",
        "category": "goo_fidget",
        "theme_tag_default": "antistress_goo",
        "items": GOO_FIDGETS_NEW,
    },
    "creepy_cute": {
        "json": "assets/data/packs/creepy_cute_pack_01.json",
        "audio_dir": "creature",
        "category": "creepy_cute",
        "theme_tag_default": "weird_cute",
        "items": CREEPY_CUTE_NEW,
    },
}


# ---------------------------------------------------------------------
# Fal.ai FLUX image generation
# ---------------------------------------------------------------------


def fal_generate_image(fal_key: str, prompt: str, out_path: Path,
                       width: int = 1024, height: int = 1024) -> None:
    """Call fal-ai/flux/schnell via the queue API and save the result."""
    headers = {
        "Authorization": f"Key {fal_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "prompt": prompt,
        "image_size": {"width": width, "height": height},
        "num_inference_steps": 4,
        "num_images": 1,
        "enable_safety_checker": True,
    }
    # Submit — Fal's queue API returns status_url + response_url in the
    # submit response; prefer those over hand-built paths since the route
    # shape has changed across their API versions.
    submit_url = "https://queue.fal.run/fal-ai/flux/schnell"

    def _submit():
        r = requests.post(submit_url, headers=headers, json=payload, timeout=60)
        r.raise_for_status()
        return r.json()
    data = _retry(_submit)
    status_url = data.get("status_url")
    result_url = data.get("response_url")
    if not status_url or not result_url:
        raise RuntimeError(f"Unexpected Fal submit response: {data}")

    # Poll until completed
    def _poll():
        r = requests.get(status_url, headers=headers, timeout=30)
        r.raise_for_status()
        return r.json()
    for _ in range(120):  # up to ~60s
        time.sleep(0.5)
        s = _retry(_poll, attempts=3)
        status = s.get("status")
        if status == "COMPLETED":
            break
        if status in ("ERROR", "CANCELLED", "FAILED"):
            raise RuntimeError(f"Fal.ai job {status}: {s}")
    else:
        raise TimeoutError("Fal.ai image generation timed out")

    # Fetch result
    def _fetch_result():
        r = requests.get(result_url, headers=headers, timeout=30)
        r.raise_for_status()
        return r.json()
    result = _retry(_fetch_result)
    image_url = result["images"][0]["url"]

    def _fetch_image():
        return requests.get(image_url, timeout=60).content
    img_bytes = _retry(_fetch_image)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    # Convert to clean RGBA PNG via Pillow.
    img = Image.open(io.BytesIO(img_bytes)).convert("RGBA")
    img.save(out_path, format="PNG", optimize=True)


def make_thumbnail(sprite_path: Path, thumb_path: Path,
                   size: int = 256) -> None:
    img = Image.open(sprite_path).convert("RGBA")
    img.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - img.width) // 2
    oy = (size - img.height) // 2
    canvas.paste(img, (ox, oy), img)
    thumb_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(thumb_path, format="PNG", optimize=True)


# ---------------------------------------------------------------------
# ElevenLabs Sound Effects generation
# ---------------------------------------------------------------------


def elevenlabs_sound(api_key: str, prompt: str, duration_s: float,
                     out_path: Path) -> None:
    """Call ElevenLabs sound-generation endpoint."""
    url = "https://api.elevenlabs.io/v1/sound-generation"
    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json",
        "accept": "audio/mpeg",
    }
    payload = {
        "text": prompt,
        "duration_seconds": duration_s,
        "prompt_influence": 0.55,
    }

    def _call():
        r = requests.post(url, headers=headers, json=payload, timeout=120)
        r.raise_for_status()
        return r.content
    content = _retry(_call)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(content)


def sound_prompt_for(obj: NewObject, variant: str, kind: str) -> str:
    """Build a short ElevenLabs sound-effect prompt."""
    base = {
        "squish": "a soft wet squish, close-mic ASMR, satisfying, no music",
        "pop": "a soft juicy pop, close-mic ASMR, tactile, no music",
        "wobble": "a gentle jelly wobble with a soft release, close-mic ASMR, no music",
    }[kind]
    subject = obj.name.lower()
    if variant == "burst":
        return (f"A satisfying wet burst pop of a {subject}, tactile, "
                f"ASMR close-mic, short tail, no music")
    # squish variants
    return f"{base}. Subject context: tiny {subject}. 0.5-0.8 second duration."


# ---------------------------------------------------------------------
# Pack-JSON patching
# ---------------------------------------------------------------------


def obj_to_json(obj: NewObject, pack_cfg: dict) -> dict:
    """Materialize a NewObject into the pack JSON shape."""
    audio_dir = pack_cfg["audio_dir"]
    category = pack_cfg["category"]
    theme_default = pack_cfg["theme_tag_default"]
    impact_paths = [
        f"audio/{audio_dir}/{obj.id}_squish_0{i+1}.mp3" for i in range(3)
    ]
    return {
        "id": obj.id,
        "name": obj.name,
        "category": category,
        "themeTag": obj.theme_tag or theme_default,
        "sprite": f"assets/images/objects/{obj.id}.png",
        "thumbnail": f"assets/images/thumbnails/{obj.id}_thumb.png",
        "behaviorProfile": obj.behavior_profile,
        "impactSounds": impact_paths,
        "burstSound": f"audio/{audio_dir}/{obj.id}_burst_01.mp3",
        "particlePreset": obj.particle_preset,
        "decalPreset": obj.decal_preset,
        "coinReward": obj.coin_reward,
        "unlockTier": obj.unlock_tier,
        "rarity": obj.rarity,
        "searchTags": obj.search_tags,
    }


def patch_pack_json(pack_cfg: dict, new_items: list) -> None:
    """Append new objects to the pack JSON, skipping any whose id already exists."""
    json_path = REPO_ROOT / pack_cfg["json"]
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    existing_ids = {o["id"] for o in data["objects"]}
    added = 0
    for obj in new_items:
        if obj.id in existing_ids:
            print(f"    skip {obj.id} — already in {json_path.name}")
            continue
        data["objects"].append(obj_to_json(obj, pack_cfg))
        added += 1
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"  patched {json_path.name}: +{added} objects")


# ---------------------------------------------------------------------
# Main orchestration
# ---------------------------------------------------------------------


def plan_to_actions(pack_name: str, pack_cfg: dict,
                    limit: int = 0) -> list[dict]:
    """Flatten the content plan into a list of concrete action records."""
    actions = []
    items = pack_cfg["items"] if limit <= 0 else pack_cfg["items"][:limit]
    for obj in items:
        sprite = REPO_ROOT / "assets" / "images" / "objects" / f"{obj.id}.png"
        thumb = REPO_ROOT / "assets" / "images" / "thumbnails" / \
            f"{obj.id}_thumb.png"
        actions.append({"kind": "image", "obj": obj, "path": sprite,
                        "pack": pack_name})
        actions.append({"kind": "thumb", "obj": obj, "sprite": sprite,
                        "path": thumb, "pack": pack_name})
        audio_dir = REPO_ROOT / "assets" / "audio" / pack_cfg["audio_dir"]
        for i in range(1, 4):
            actions.append({
                "kind": "sound_squish",
                "obj": obj,
                "variant": i,
                "path": audio_dir / f"{obj.id}_squish_0{i}.mp3",
                "pack": pack_name,
            })
        actions.append({
            "kind": "sound_burst",
            "obj": obj,
            "path": audio_dir / f"{obj.id}_burst_01.mp3",
            "pack": pack_name,
        })
    return actions


def estimate_cost(actions: list[dict]) -> tuple[float, int, int]:
    """Return (usd_estimate, image_count, sound_count)."""
    images = sum(1 for a in actions if a["kind"] == "image")
    sounds = sum(1 for a in actions if a["kind"].startswith("sound"))
    # Rough rates. Adjust if you see actual invoicing drift.
    usd = images * 0.003 + sounds * 0.10
    return usd, images, sounds


def run_actions(actions: list[dict], env: dict, dry_run: bool,
                skip_images: bool, skip_audio: bool) -> None:
    fal_key = env.get("FAL_KEY")
    el_key = env.get("ELEVENLABS_API_KEY")
    for idx, a in enumerate(actions, 1):
        tag = f"[{idx}/{len(actions)}]"
        kind = a["kind"]
        obj = a["obj"]
        if kind == "image":
            if skip_images:
                print(f"  {tag} skip image (sprites-off): {obj.id}")
                continue
            if a["path"].exists():
                print(f"  {tag} skip image (exists): {a['path'].name}")
                continue
            prompt = ART_STYLE_PREFIX + obj.art_prompt
            if dry_run:
                print(f"  {tag} DRY image -> {a['path'].name}")
                print(f"       prompt: {prompt[:90]}...")
                continue
            if not fal_key:
                raise RuntimeError("FAL_KEY missing in .env")
            print(f"  {tag} image -> {a['path'].name}")
            fal_generate_image(fal_key, prompt, a["path"])
        elif kind == "thumb":
            if skip_images:
                continue
            if a["path"].exists():
                print(f"  {tag} skip thumb (exists): {a['path'].name}")
                continue
            if not a["sprite"].exists():
                print(f"  {tag} skip thumb (no sprite): {a['path'].name}")
                continue
            if dry_run:
                print(f"  {tag} DRY thumb -> {a['path'].name}")
                continue
            print(f"  {tag} thumb -> {a['path'].name}")
            make_thumbnail(a["sprite"], a["path"])
        elif kind in ("sound_squish", "sound_burst"):
            if skip_audio:
                print(f"  {tag} skip audio (audio-off): {a['path'].name}")
                continue
            if a["path"].exists() and a["path"].stat().st_size > 1024:
                print(f"  {tag} skip audio (exists): {a['path'].name}")
                continue
            variant = "burst" if kind == "sound_burst" else f"squish_{a.get('variant', 1)}"
            prompt = sound_prompt_for(obj, variant, obj.sound_kind)
            duration = 0.9 if kind == "sound_burst" else 0.7
            if dry_run:
                print(f"  {tag} DRY sound -> {a['path'].name}")
                print(f"       prompt: {prompt[:90]}...")
                continue
            if not el_key:
                raise RuntimeError("ELEVENLABS_API_KEY missing in .env")
            print(f"  {tag} sound -> {a['path'].name}")
            elevenlabs_sound(el_key, prompt, duration, a["path"])
        else:
            raise ValueError(f"unknown action kind: {kind}")


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--pack", choices=list(PACK_PLAN.keys()) + ["all"],
                        default="all", help="Which pack to generate")
    parser.add_argument("--items", type=int, default=0,
                        help="Limit to first N items per pack (0 = all)")
    parser.add_argument("--test-one", action="store_true",
                        help="Only generate the first item of the first pack")
    parser.add_argument("--execute", action="store_true",
                        help="Actually hit APIs (default is dry-run)")
    parser.add_argument("--sprites-only", action="store_true",
                        help="Generate images only, skip audio")
    parser.add_argument("--audio-only", action="store_true",
                        help="Generate audio only, skip images")
    parser.add_argument("--patch-json", action="store_true",
                        help="After generation, append new objects to pack JSONs")
    args = parser.parse_args()

    if args.sprites_only and args.audio_only:
        print("--sprites-only and --audio-only are mutually exclusive")
        sys.exit(2)

    env = load_env(ENV_PATH)

    packs = ([args.pack] if args.pack != "all"
             else list(PACK_PLAN.keys()))
    if args.test_one:
        packs = packs[:1]

    dry_run = not args.execute
    all_actions = []
    for pack_name in packs:
        pack_cfg = PACK_PLAN[pack_name]
        limit = args.items if not args.test_one else 1
        actions = plan_to_actions(pack_name, pack_cfg, limit=limit)
        all_actions.extend(actions)

    usd, imgs, snds = estimate_cost(all_actions)
    print(f"Pack(s): {', '.join(packs)}")
    print(f"Actions: {len(all_actions)} "
          f"({imgs} images + thumbs downsampled, {snds} sounds)")
    print(f"Estimated cost: ${usd:.2f}  "
          f"(${imgs * 0.003:.2f} images + ${snds * 0.10:.2f} sounds)")
    print(f"Mode: {'EXECUTE' if args.execute else 'DRY-RUN'}")
    print()
    # skip_images is true when --audio-only was passed; skip_audio is
    # true when --sprites-only was passed. Both can't be true (checked above).
    run_actions(all_actions, env, dry_run,
                skip_images=args.audio_only,
                skip_audio=args.sprites_only)

    if args.patch_json and args.execute:
        print("\nPatching pack JSONs...")
        for pack_name in packs:
            pack_cfg = PACK_PLAN[pack_name]
            items = pack_cfg["items"]
            if args.items > 0 or args.test_one:
                limit = 1 if args.test_one else args.items
                items = items[:limit]
            patch_pack_json(pack_cfg, items)
    elif args.patch_json:
        print("\n(Would patch JSONs; run with --execute to actually patch.)")


if __name__ == "__main__":
    main()
