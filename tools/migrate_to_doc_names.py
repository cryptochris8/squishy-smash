"""
One-shot migration: align 9 pre-doc squishy IDs with the
collectible_rarity_map.md naming.

Operations:
  * 5 clean renames — keep existing sprite + sound files, just rename
    them and update JSON IDs/names/paths.
  * 4 removals — delete old assets + remove JSON entries. Those slots
    are refilled by generate_pack_content.py with new prompts.

Run once from repo root:
    python tools/migrate_to_doc_names.py
"""

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PACKS_DIR = REPO_ROOT / "assets" / "data" / "packs"
SPRITES_DIR = REPO_ROOT / "assets" / "images" / "objects"
THUMBS_DIR = REPO_ROOT / "assets" / "images" / "thumbnails"

# (pack_id, old_id, new_id, new_display_name)
CLEAN_RENAMES = [
    ("launch_squishy_foods", "dumplio",   "soft_dumpling",         "Soft Dumpling"),
    ("launch_squishy_foods", "jellyzap",  "jelly_bun",             "Jelly Bun"),
    ("goo_fidgets_drop_01",  "slimeorb",  "goo_ball",              "Goo Ball"),
    ("creepy_cute_pack_01",  "squishkin", "round_eared_creature",  "Round Eared Creature"),
    ("creepy_cute_pack_01",  "snagglet",  "candy_fang_creature",   "Candy Fang Creature"),
]

# IDs whose assets will be deleted and slots refilled by the generator
TO_REGENERATE = {
    ("launch_squishy_foods", "poppling"),
    ("goo_fidgets_drop_01",  "popzee"),
    ("goo_fidgets_drop_01",  "goodrop"),
    ("creepy_cute_pack_01",  "gloomp"),
}


def rename_file(old: Path, new: Path) -> bool:
    if not old.exists():
        return False
    new.parent.mkdir(parents=True, exist_ok=True)
    old.rename(new)
    return True


def delete_file(path: Path) -> bool:
    if path.exists():
        path.unlink()
        return True
    return False


def clean_rename(pack: dict, old_id: str, new_id: str, new_name: str) -> None:
    """Update the matching object in [pack] dict + rename its asset files."""
    target = None
    for obj in pack["objects"]:
        if obj["id"] == old_id:
            target = obj
            break
    if target is None:
        raise RuntimeError(f"{old_id} not found in pack {pack['packId']}")

    # 1. Rename sprite + thumbnail
    sprite_old = REPO_ROOT / target["sprite"]
    sprite_new = sprite_old.with_name(f"{new_id}.png")
    rename_file(sprite_old, sprite_new)
    target["sprite"] = f"assets/images/objects/{new_id}.png"

    thumb_old = REPO_ROOT / target["thumbnail"]
    thumb_new = thumb_old.with_name(f"{new_id}_thumb.png")
    rename_file(thumb_old, thumb_new)
    target["thumbnail"] = f"assets/images/thumbnails/{new_id}_thumb.png"

    # 2. Rename impact + burst sounds. We preserve the existing suffix
    # pattern (e.g. "_hit_02", "_snicker_03", "_pop_01") by replacing
    # only the ID prefix. Old files live under audio/<category>/ relative
    # to the project root, with JSON paths starting with "audio/".
    def rename_audio(old_path: str) -> str:
        old_file = REPO_ROOT / "assets" / old_path
        rel = Path(old_path)  # e.g. audio/food/dumplio_squish_01.mp3
        category_dir = rel.parent  # audio/food
        old_filename = rel.name
        # Replace the ID prefix while keeping the suffix.
        new_filename = old_filename.replace(f"{old_id}_", f"{new_id}_", 1)
        new_rel_path = f"{category_dir.as_posix()}/{new_filename}"
        new_file = REPO_ROOT / "assets" / new_rel_path
        rename_file(old_file, new_file)
        return new_rel_path

    target["impactSounds"] = [rename_audio(p) for p in target["impactSounds"]]
    target["burstSound"] = rename_audio(target["burstSound"])

    # 3. Update identity
    target["id"] = new_id
    target["name"] = new_name


def remove_for_regen(pack: dict, old_id: str) -> dict:
    """Delete the object's asset files + drop it from the pack. Returns
    the removed entry in case we want to log it."""
    idx = next(
        (i for i, o in enumerate(pack["objects"]) if o["id"] == old_id),
        None,
    )
    if idx is None:
        raise RuntimeError(f"{old_id} not found in pack {pack['packId']}")
    obj = pack["objects"].pop(idx)
    delete_file(REPO_ROOT / obj["sprite"])
    delete_file(REPO_ROOT / obj["thumbnail"])
    for p in obj["impactSounds"]:
        delete_file(REPO_ROOT / "assets" / p)
    delete_file(REPO_ROOT / "assets" / obj["burstSound"])
    return obj


def write_pack(pack_id: str, pack: dict) -> None:
    path = PACKS_DIR / f"{pack_id}.json"
    with path.open("w", encoding="utf-8") as f:
        json.dump(pack, f, indent=2, ensure_ascii=False)
        f.write("\n")


def load_pack(pack_id: str) -> dict:
    path = PACKS_DIR / f"{pack_id}.json"
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def main():
    touched_packs: dict[str, dict] = {}

    print("=== Clean renames ===")
    for pack_id, old_id, new_id, new_name in CLEAN_RENAMES:
        pack = touched_packs.setdefault(pack_id, load_pack(pack_id))
        clean_rename(pack, old_id, new_id, new_name)
        print(f"  {pack_id}: {old_id} -> {new_id} ({new_name})")

    print("\n=== Removing for regeneration ===")
    for pack_id, old_id in TO_REGENERATE:
        pack = touched_packs.setdefault(pack_id, load_pack(pack_id))
        removed = remove_for_regen(pack, old_id)
        print(f"  {pack_id}: removed {old_id} ({removed.get('name')})")

    print("\n=== Writing packs ===")
    for pack_id, pack in touched_packs.items():
        write_pack(pack_id, pack)
        print(f"  wrote {pack_id}.json ({len(pack['objects'])} objects)")

    print("\nDone. Run tools/generate_pack_content.py next to create the "
          "4 regen items.")


if __name__ == "__main__":
    main()
