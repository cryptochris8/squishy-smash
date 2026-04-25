"""
Copy sprite + thumbnail PNGs from the Flutter game's assets into the
web site's public folder, and emit a typed catalog of all 48 squishies
so the site doesn't have to re-parse pack JSONs at runtime.

Run from the repo root:
    python website/scripts/sync_content_from_game.py

Re-run any time pack JSONs change.
"""

import json
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
GAME_PACKS = REPO_ROOT / "assets" / "data" / "packs"
GAME_SPRITES = REPO_ROOT / "assets" / "images" / "objects"
GAME_THUMBS = REPO_ROOT / "assets" / "images" / "thumbnails"
GAME_CARDS = REPO_ROOT / "assets" / "cards" / "final_48"
GAME_CARDS_MANIFEST = REPO_ROOT / "assets" / "data" / "cards_manifest.json"
GAME_BRANDING = REPO_ROOT / "branding"
SITE_PUBLIC = REPO_ROOT / "website" / "public"
SITE_DATA = REPO_ROOT / "website" / "src" / "data"

# Only the three main launch packs make up the "48 collection". The
# Dumpling weekly drop is a bonus pack and gets its own section later.
LAUNCH_PACK_IDS = {
    "launch_squishy_foods",
    "goo_fidgets_drop_01",
    "creepy_cute_pack_01",
}

PACK_DISPLAY_META = {
    "launch_squishy_foods": {
        "slug": "squishy-foods",
        "accent": "#FF8FB8",
        "accentDark": "#FF6FA5",
        "blurb": "Cozy cream mochis, glossy jelly cubes, and galaxy dumplings.",
        "emoji": "\U0001F371",  # bento
    },
    "goo_fidgets_drop_01": {
        "slug": "goo-and-fidgets",
        "accent": "#B6FF5C",
        "accentDark": "#7FE7FF",
        "blurb": "Sticky goo balls, stress orbs, and cosmic jelly pads.",
        "emoji": "\U0001F9EA",  # test tube
    },
    "creepy_cute_pack_01": {
        "slug": "creepy-cute-creatures",
        "accent": "#C98BFF",
        "accentDark": "#8040D8",
        "blurb": "Bunnies, bats, and glow ghosts — creepy, cute, never scary.",
        "emoji": "\U0001F47B",  # ghost
    },
}


def copy_if_exists(src: Path, dst: Path) -> bool:
    if not src.exists():
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return True


def main():
    assert GAME_PACKS.exists(), f"Missing {GAME_PACKS}"

    # Index card_number -> card art filename so smashables with a
    # `cardNumber` field in pack JSON can map to their full WebP art.
    card_art_by_number: dict[str, str] = {}
    if GAME_CARDS_MANIFEST.exists():
        with GAME_CARDS_MANIFEST.open("r", encoding="utf-8") as f:
            for entry in json.load(f):
                # packaged_filename is "assets/cards/final_48/NNN_Name.webp".
                # Strip the asset prefix; we'll re-root under /cards on the site.
                filename = Path(entry["packaged_filename"]).name
                card_art_by_number[entry["card_number"]] = filename

    catalog = []
    copied_sprites = 0
    copied_thumbs = 0
    copied_cards = 0

    for pack_path in sorted(GAME_PACKS.glob("*.json")):
        with pack_path.open("r", encoding="utf-8") as f:
            pack = json.load(f)
        pack_id = pack["packId"]
        if pack_id not in LAUNCH_PACK_IDS:
            continue  # skip the dumpling weekly drop for the 48-grid
        meta = PACK_DISPLAY_META[pack_id]
        for obj in pack["objects"]:
            oid = obj["id"]
            sprite_src = GAME_SPRITES / f"{oid}.png"
            thumb_src = GAME_THUMBS / f"{oid}_thumb.png"
            if copy_if_exists(sprite_src, SITE_PUBLIC / "sprites" / f"{oid}.png"):
                copied_sprites += 1
            if copy_if_exists(
                thumb_src, SITE_PUBLIC / "thumbnails" / f"{oid}_thumb.png"
            ):
                copied_thumbs += 1

            # Card art (v0.1.1+): smashables with a `cardNumber` field
            # have a corresponding 48-card-collection WebP. Copy it
            # over and emit the public path so the website can render
            # the richer art.
            card_number = obj.get("cardNumber")
            card_image_path: str | None = None
            if card_number and card_number in card_art_by_number:
                fname = card_art_by_number[card_number]
                card_src = GAME_CARDS / fname
                if copy_if_exists(card_src, SITE_PUBLIC / "cards" / fname):
                    copied_cards += 1
                card_image_path = f"/cards/{fname}"

            catalog.append({
                "id": oid,
                "name": obj["name"],
                "rarity": obj.get("rarity", "common"),
                "packId": pack_id,
                "packSlug": meta["slug"],
                "packName": pack["displayName"],
                "sprite": f"/sprites/{oid}.png",
                "thumbnail": f"/thumbnails/{oid}_thumb.png",
                "cardNumber": card_number,
                "cardImage": card_image_path,
                "themeTag": obj.get("themeTag", ""),
                "behaviorProfile": obj.get("behaviorProfile"),
                "searchTags": obj.get("searchTags", []),
            })

    # Pack summary data for section components
    pack_summary = []
    for pack_id in LAUNCH_PACK_IDS:
        meta = PACK_DISPLAY_META[pack_id]
        pack_path = GAME_PACKS / f"{pack_id}.json"
        with pack_path.open("r", encoding="utf-8") as f:
            pack = json.load(f)
        counts = {"common": 0, "rare": 0, "epic": 0, "legendary": 0}
        legendary_name = None
        for obj in pack["objects"]:
            r = obj.get("rarity", "common")
            # Legacy "mythic" token still maps to Legendary display.
            if r == "mythic":
                r = "legendary"
                legendary_name = obj["name"]
            counts[r] = counts.get(r, 0) + 1
        pack_summary.append({
            "id": pack_id,
            "slug": meta["slug"],
            "displayName": pack["displayName"],
            "blurb": meta["blurb"],
            "accent": meta["accent"],
            "accentDark": meta["accentDark"],
            "emoji": meta["emoji"],
            "counts": counts,
            "legendaryName": legendary_name,
            "totalCount": sum(counts.values()),
        })

    # Sort: foods first, then goo, then creatures
    pack_order = [
        "launch_squishy_foods",
        "goo_fidgets_drop_01",
        "creepy_cute_pack_01",
    ]
    pack_summary.sort(key=lambda p: pack_order.index(p["id"]))

    # Emit the TS catalog
    SITE_DATA.mkdir(parents=True, exist_ok=True)
    ts_path = SITE_DATA / "squishies.ts"
    lines = [
        "// AUTO-GENERATED by website/scripts/sync_content_from_game.py.",
        "// Do not edit by hand — re-run the script after changing pack JSONs.",
        "",
        "export type Rarity = 'common' | 'rare' | 'epic' | 'legendary';",
        "",
        "export interface Squishy {",
        "  id: string;",
        "  name: string;",
        "  rarity: Rarity;",
        "  packId: string;",
        "  packSlug: string;",
        "  packName: string;",
        "  sprite: string;",
        "  thumbnail: string;",
        "  /** Card-number string (e.g., '001/048') or null for un-mapped",
        "   *  smashables. Cards on the public 48-card grid always carry one. */",
        "  cardNumber: string | null;",
        "  /** Public path to the WebP card art (e.g., '/cards/001_Soft_Dumpling.webp'),",
        "   *  or null for un-mapped smashables. The Collection grid prefers this",
        "   *  over `thumbnail` when present. */",
        "  cardImage: string | null;",
        "  themeTag: string;",
        "  behaviorProfile?: string | null;",
        "  searchTags: string[];",
        "}",
        "",
        "export interface PackSummary {",
        "  id: string;",
        "  slug: string;",
        "  displayName: string;",
        "  blurb: string;",
        "  accent: string;",
        "  accentDark: string;",
        "  emoji: string;",
        "  counts: { common: number; rare: number; epic: number; legendary: number };",
        "  legendaryName: string | null;",
        "  totalCount: number;",
        "}",
        "",
        f"export const squishies: Squishy[] = {_js(catalog)};",
        "",
        f"export const packs: PackSummary[] = {_js(pack_summary)};",
        "",
    ]
    # Normalize any legacy "mythic" tokens in the emitted catalog to
    # "legendary" so the runtime deals in one name.
    ts_path.write_text("\n".join(lines).replace('"mythic"', '"legendary"'),
                       encoding="utf-8")

    # Copy branding logos/icons for the site
    for src_rel in [
        "logo/squishy_smash_logo_primary.png",
        "icon/squishy_smash_icon_bunny_v1.png",
        "icon/squishy_smash_icon_pink_v1.png",
    ]:
        src = GAME_BRANDING / src_rel
        dst = SITE_PUBLIC / "branding" / Path(src_rel).name
        copy_if_exists(src, dst)

    print(f"Catalog: {len(catalog)} squishies -> {ts_path.relative_to(REPO_ROOT)}")
    print(f"Sprites copied: {copied_sprites}")
    print(f"Thumbnails copied: {copied_thumbs}")
    print(f"Card WebPs copied: {copied_cards}")
    print(f"Packs: {len(pack_summary)}")


def _js(data) -> str:
    """Render Python data as a TypeScript literal via JSON. Works for
    plain dicts/lists of strings, numbers, bools, and None (-> null)."""
    return json.dumps(data, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
