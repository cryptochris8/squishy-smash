"""
Stage 3 of the all-48 sprite restyle. Takes the winning candidate per
sprite (chosen.json, produced by the judging workflow), runs BiRefNet
background removal, centers into 512x512, and writes game-spec WebP
sprites + 256 thumbnails to a STAGING dir. Also builds review art.

  python tools/restyle_sprites_finalize.py            # stage all chosen
  python tools/restyle_sprites_finalize.py --only goo_ball
  python tools/restyle_sprites_finalize.py --promote   # copy staging -> real assets

chosen.json format: { "<slug>": <candidate_index>, ... }
Staging:  _sprite_restyle_proto/final/objects/<slug>.webp
          _sprite_restyle_proto/final/thumbnails/<slug>_thumb.webp
Promote copies those over assets/images/objects + thumbnails (git-reversible).

Requires FAL_KEY in .env (for the cutout step).
"""

import argparse
import json
import shutil
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from generate_pack_content import load_env, ENV_PATH  # noqa: E402
from prototype_sprite_restyle import (  # noqa: E402
    birefnet_cutout, center_512, build_strip,
)

OUT = REPO / "_sprite_restyle_proto"
CAND = OUT / "candidates"
FINAL_OBJ = OUT / "final" / "objects"
FINAL_THUMB = OUT / "final" / "thumbnails"
COMPARE = OUT / "compare"
for d in (FINAL_OBJ, FINAL_THUMB, COMPARE):
    d.mkdir(parents=True, exist_ok=True)

ASSET_OBJ = REPO / "assets" / "images" / "objects"
ASSET_THUMB = REPO / "assets" / "images" / "thumbnails"


def save_webp(img: Image.Image, path: Path, quality: int = 90):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGBA").save(path, format="WEBP", quality=quality, method=6)


def thumb_512_to_256(sprite_512: Image.Image, size: int = 256) -> Image.Image:
    im = sprite_512.convert("RGBA").copy()
    im.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(im, ((size - im.width) // 2, (size - im.height) // 2), im)
    return canvas


def stage(only, fal_key):
    mapping = json.loads((OUT / "mapping.json").read_text(encoding="utf-8"))
    by_slug = {c["slug"]: c for c in mapping}
    chosen = json.loads((OUT / "chosen.json").read_text(encoding="utf-8"))

    slugs = [s for s in chosen if (not only or s in only)]
    print(f"Staging {len(slugs)} sprites...")
    for i, slug in enumerate(slugs, 1):
        idx = chosen[slug]
        cand = CAND / slug / f"cand_{idx}.png"
        if not cand.exists():
            print(f"  [{i}/{len(slugs)}] MISSING candidate {cand}"); continue
        raw = cand.read_bytes()
        try:
            cut = birefnet_cutout(fal_key, raw)
        except Exception as e:
            print(f"  [{i}/{len(slugs)}] {slug}: bg-remove failed ({str(e)[:90]}); raw")
            cut = Image.open(cand).convert("RGBA")
        sprite = center_512(cut)
        save_webp(sprite, FINAL_OBJ / f"{slug}.webp")
        save_webp(thumb_512_to_256(sprite), FINAL_THUMB / f"{slug}_thumb.webp")

        # comparison strip card | old | new
        c = by_slug[slug]
        old = ASSET_OBJ / f"{slug}.webp"
        if old.exists():
            build_strip(slug, Path(c["card"]), old, sprite, COMPARE / f"{slug}.png")
        sz = (FINAL_OBJ / f"{slug}.webp").stat().st_size
        print(f"  [{i}/{len(slugs)}] {slug}: staged ({sz//1024} KB)")


def build_grid():
    """One contact sheet of all staged NEW sprites, grouped by pack."""
    mapping = json.loads((OUT / "mapping.json").read_text(encoding="utf-8"))
    chosen = json.loads((OUT / "chosen.json").read_text(encoding="utf-8"))
    from PIL import ImageDraw
    cell = 150
    cols = 8
    items = [c for c in mapping if c["slug"] in chosen]
    rows = (len(items) + cols - 1) // cols
    pad = 6
    W = cols * cell + (cols + 1) * pad
    H = rows * (cell + 18) + pad
    sheet = Image.new("RGB", (W, H), (250, 250, 252))
    d = ImageDraw.Draw(sheet)
    for k, c in enumerate(items):
        r, col = divmod(k, cols)
        x = pad + col * (cell + pad)
        y = pad + r * (cell + 18)
        sp = FINAL_OBJ / f"{c['slug']}.webp"
        if sp.exists():
            im = Image.open(sp).convert("RGBA")
            im.thumbnail((cell - 8, cell - 8), Image.LANCZOS)
            panel = Image.new("RGB", (cell, cell), (235, 235, 240))
            panel.paste(im, ((cell - im.width) // 2, (cell - im.height) // 2), im)
            sheet.paste(panel, (x, y))
        d.text((x + 2, y + cell + 2), c["name"][:20], fill=(60, 60, 70))
    sheet.save(OUT / "review_grid.png")
    print(f"Review grid -> {OUT / 'review_grid.png'}")


def promote(only):
    chosen = json.loads((OUT / "chosen.json").read_text(encoding="utf-8"))
    slugs = [s for s in chosen if (not only or s in only)]
    n = 0
    for slug in slugs:
        src = FINAL_OBJ / f"{slug}.webp"
        srct = FINAL_THUMB / f"{slug}_thumb.webp"
        if not src.exists():
            print(f"  skip {slug}: not staged"); continue
        shutil.copyfile(src, ASSET_OBJ / f"{slug}.webp")
        if srct.exists():
            shutil.copyfile(srct, ASSET_THUMB / f"{slug}_thumb.webp")
        n += 1
    print(f"Promoted {n} sprites + thumbnails into assets/. Review `git diff --stat`.")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--only", default="")
    ap.add_argument("--promote", action="store_true")
    ap.add_argument("--grid-only", action="store_true")
    args = ap.parse_args()
    only = {s.strip() for s in args.only.split(",") if s.strip()}

    if args.grid_only:
        build_grid(); return
    if args.promote:
        promote(only); return

    env = load_env(ENV_PATH)
    fal_key = env.get("FAL_KEY")
    if not fal_key:
        print("ERROR: FAL_KEY missing in .env"); sys.exit(1)
    stage(only, fal_key)
    build_grid()
    print("\nStaged. Review _sprite_restyle_proto/review_grid.png and compare/*.png,")
    print("then: python tools/restyle_sprites_finalize.py --promote")


if __name__ == "__main__":
    main()
