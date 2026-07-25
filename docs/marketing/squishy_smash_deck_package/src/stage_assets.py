"""Stage real Squishy Smash brand assets into the deck package.

Reads from the live repo (D:/squishy-smash), converts WebP -> PNG (PowerPoint
does not reliably support WebP), downscales oversized masters, and writes
everything to assets/staged/ with deck-friendly names.

Run:  py src/stage_assets.py
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from PIL import Image, ImageDraw

Image.MAX_IMAGE_PIXELS = None

REPO = Path("D:/squishy-smash")
PKG = Path(__file__).resolve().parent.parent
STAGED = PKG / "assets" / "staged"
STAGED.mkdir(parents=True, exist_ok=True)

# The six characters that already have GLB 3D models. This is not an arbitrary
# pick -- it is the honest pilot lineup, because these are the only characters
# with existing 3D geometry a factory could review today.
PILOT = [
    ("soft_dumpling", "Soft Dumpling", "001/048", "Common", "Squishy Foods"),
    ("goo_ball", "Goo Ball", "017/048", "Common", "Goo & Fidgets"),
    ("blushy_bun_bunny", "Blushy Bun Bunny", "033/048", "Common", "Creepy Cute"),
    ("celestial_dumpling_core", "Celestial Dumpling Core", "016/048", "Legendary", "Squishy Foods"),
    ("singularity_goo_core", "Singularity Goo Core", "032/048", "Legendary", "Goo & Fidgets"),
    ("mythic_plush_familiar", "Mythic Plush Familiar", "048/048", "Legendary", "Creepy Cute"),
]


def save(im: Image.Image, name: str, *, max_px: int | None = None, jpeg: bool = False) -> Path:
    """Write an image to the staging dir, optionally downscaled."""
    if max_px:
        im = im.copy()
        im.thumbnail((max_px, max_px), Image.LANCZOS)
    out = STAGED / name
    if jpeg:
        im.convert("RGB").save(out, "JPEG", quality=88, optimize=True)
    else:
        im.save(out, "PNG", optimize=True)
    return out


def load(rel: str) -> Image.Image:
    return Image.open(REPO / rel)


def main() -> None:
    written: list[str] = []

    # --- brand marks -------------------------------------------------------
    # The master logo is a flat rectangle with a baked gradient background. On
    # the dark cover that hard edge reads as a pasted box, so round the corners
    # into a deliberate brand plate.
    logo = load("branding/logo/squishy_smash_logo_primary.png").convert("RGBA")
    logo.thumbnail((1400, 1400), Image.LANCZOS)
    radius = int(min(logo.size) * 0.075)
    mask = Image.new("L", logo.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), (logo.width - 1, logo.height - 1)],
                                           radius=radius, fill=255)
    logo.putalpha(mask)
    save(logo, "logo.png")
    written.append("logo.png (rounded)")
    save(load("branding/icon/squishy_smash_icon_bunny_512.png").convert("RGBA"), "icon_bunny.png")
    written.append("icon_bunny.png")

    # --- 3D model renders (transparent, straight from the GLB posters) -----
    for slug, *_ in PILOT:
        im = load(f"website/public/models/posters/{slug}.webp").convert("RGBA")
        save(im, f"model_{slug}.png")
        written.append(f"model_{slug}.png")

    # --- gameplay sprites: transparent cutouts, ideal on colored slides ----
    manifest = json.loads((REPO / "assets/data/cards_manifest.json").read_text(encoding="utf-8"))
    for slug, *_ in PILOT:
        src = REPO / f"assets/images/objects/{slug}.webp"
        if src.exists():
            save(Image.open(src).convert("RGBA"), f"sprite_{slug}.png")
            written.append(f"sprite_{slug}.png")

    # --- trading cards -----------------------------------------------------
    card_by_num = {c["card_number"]: c for c in manifest}
    for slug, name, num, *_ in PILOT:
        entry = card_by_num.get(num)
        if not entry:
            continue
        cp = REPO / entry["packaged_filename"]
        if cp.exists():
            save(Image.open(cp).convert("RGB"), f"card_{slug}.jpg", max_px=900, jpeg=True)
            written.append(f"card_{slug}.jpg")

    # --- full 48-character grid (appendix) --------------------------------
    cols, cell, pad = 12, 150, 6
    rows = (len(manifest) + cols - 1) // cols
    grid = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
    placed = 0
    for i, entry in enumerate(manifest):
        cp = REPO / entry["packaged_filename"]
        if not cp.exists():
            continue
        card = Image.open(cp).convert("RGBA")
        card.thumbnail((cell - pad * 2, cell - pad * 2), Image.LANCZOS)
        x = (i % cols) * cell + (cell - card.width) // 2
        y = (i // cols) * cell + (cell - card.height) // 2
        grid.paste(card, (x, y), card)
        placed += 1
    save(grid, "grid_48_cards.png")
    written.append(f"grid_48_cards.png ({placed} cards)")

    # --- books -------------------------------------------------------------
    save(load("book/mockups/cover_after_fix_front_only.png").convert("RGB"),
         "book1_cover.jpg", max_px=1000, jpeg=True)
    written.append("book1_cover.jpg")
    save(load("book/cover/cover_front_book2_composite.png").convert("RGB"),
         "book2_cover.jpg", max_px=1000, jpeg=True)
    written.append("book2_cover.jpg")

    # --- digital surfaces --------------------------------------------------
    for i, shot in enumerate(
        ["01_menu_floating_mascot", "08_collection_grid", "07_arcane_kitty_reveal"], start=1
    ):
        p = REPO / f"screenshots/captioned/{shot}.PNG"
        if p.exists():
            save(Image.open(p).convert("RGB"), f"app_{i:02d}.jpg", max_px=1100, jpeg=True)
            written.append(f"app_{i:02d}.jpg")
    save(load("website/public/roblox-lost-sparkle.jpg").convert("RGB"),
         "roblox.jpg", max_px=1400, jpeg=True)
    written.append("roblox.jpg")

    # --- pack scene art (section backgrounds) ------------------------------
    for pack in ["squishy_foods", "goo_fidgets", "creepy_cute"]:
        p = REPO / f"assets/website_hero/pack_{pack}.png"
        if p.exists():
            save(Image.open(p).convert("RGB"), f"pack_{pack}.jpg", max_px=1200, jpeg=True)
            written.append(f"pack_{pack}.jpg")

    total = sum(f.stat().st_size for f in STAGED.iterdir() if f.is_file())
    print(f"Staged {len(written)} assets -> {STAGED}")
    for w in written:
        print("  ", w)
    print(f"\nTotal staged size: {total/1024/1024:.1f} MB")


if __name__ == "__main__":
    main()
