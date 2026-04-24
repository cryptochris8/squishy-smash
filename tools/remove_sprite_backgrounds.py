"""
Remove solid backgrounds from generated sprite PNGs so they render
cleanly over the arena skybox in-game.

FLUX schnell produces the cute squishy on a white background — which
bakes into the PNG as opaque pixels. In-game that shows as a visible
square around the sprite. This script runs each affected PNG through
Fal.ai's BiRefNet background-removal model, downloads the result with
proper alpha, overwrites the file, and regenerates the 256x256
thumbnail from the fixed sprite.

Default: process the 39 items in tools/generate_pack_content.py's
content plan (the ones with white backgrounds). Pass --all to process
every PNG in assets/images/objects/ instead.

Cost: ~$0.005 per image via fal-ai/birefnet. 39 sprites = ~$0.20.
Requires FAL_KEY in .env.
"""

import argparse
import io
import sys
import time
from pathlib import Path

import requests
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent

# Import the content plan so we know exactly which 39 IDs we generated.
sys.path.insert(0, str(REPO_ROOT / "tools"))
from generate_pack_content import (  # noqa: E402
    PACK_PLAN, load_env, ENV_PATH, make_thumbnail, _retry,
)


def fal_remove_background(fal_key: str, sprite_path: Path) -> Image.Image:
    """Upload a sprite to Fal.ai BiRefNet and return the RGBA result.

    Fal's file-upload flow:
      1. POST the image binary to a storage endpoint
      2. Reference the returned URL in the birefnet job payload
      3. Poll the queue the same way as the text-to-image path
    """
    headers = {"Authorization": f"Key {fal_key}"}

    # Step 1: Upload the sprite as a data URL inline — simpler than
    # wrangling Fal's storage endpoint and fine for ~300 KB files.
    with open(sprite_path, "rb") as f:
        import base64
        b64 = base64.b64encode(f.read()).decode("ascii")
    data_url = f"data:image/png;base64,{b64}"

    submit_url = "https://queue.fal.run/fal-ai/birefnet"
    payload = {"image_url": data_url}

    def _submit():
        r = requests.post(
            submit_url,
            headers={**headers, "Content-Type": "application/json"},
            json=payload,
            timeout=120,
        )
        r.raise_for_status()
        return r.json()

    data = _retry(_submit)
    status_url = data.get("status_url")
    result_url = data.get("response_url")
    if not status_url or not result_url:
        raise RuntimeError(f"Unexpected Fal submit response: {data}")

    # Poll
    def _poll():
        r = requests.get(status_url, headers=headers, timeout=30)
        r.raise_for_status()
        return r.json()

    for _ in range(120):
        time.sleep(0.5)
        s = _retry(_poll, attempts=3)
        status = s.get("status")
        if status == "COMPLETED":
            break
        if status in ("ERROR", "CANCELLED", "FAILED"):
            raise RuntimeError(f"Fal job {status}: {s}")
    else:
        raise TimeoutError("Fal background removal timed out")

    # Fetch result
    def _fetch_result():
        r = requests.get(result_url, headers=headers, timeout=30)
        r.raise_for_status()
        return r.json()

    result = _retry(_fetch_result)
    # BiRefNet returns {"image": {"url": ..., "width": ..., "height": ...}}
    image_info = result.get("image") or (
        result.get("images", [{}])[0] if result.get("images") else None
    )
    if not image_info or "url" not in image_info:
        raise RuntimeError(f"No image in BiRefNet result: {result}")

    img_bytes = _retry(lambda: requests.get(image_info["url"], timeout=60).content)
    return Image.open(io.BytesIO(img_bytes)).convert("RGBA")


def has_white_background(path: Path, corner: int = 8) -> bool:
    """Heuristic: if every corner pixel is fully opaque (alpha 255),
    the PNG has a baked background that needs removal. Properly
    alpha-masked sprites always have at least some transparent pixels
    at the edges, so they fail this check."""
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    boxes = [
        img.crop((0, 0, corner, corner)),
        img.crop((w - corner, 0, w, corner)),
        img.crop((0, h - corner, corner, h)),
        img.crop((w - corner, h - corner, w, h)),
    ]
    for box in boxes:
        pixels = list(box.getdata())
        # Any transparent corner pixel = already has alpha mask
        if any(px[3] < 250 for px in pixels):
            return False
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true",
                        help="Process every PNG under assets/images/objects/, "
                             "not just the 39 from the content plan")
    parser.add_argument("--force", action="store_true",
                        help="Process even if the corner heuristic says "
                             "the sprite already has transparency")
    parser.add_argument("--limit", type=int, default=0,
                        help="Stop after N images (0 = no limit)")
    parser.add_argument("--execute", action="store_true",
                        help="Actually call the API (default is dry-run)")
    args = parser.parse_args()

    env = load_env(ENV_PATH)
    fal_key = env.get("FAL_KEY")
    if args.execute and not fal_key:
        print("ERROR: FAL_KEY missing in .env")
        sys.exit(1)

    sprites_dir = REPO_ROOT / "assets" / "images" / "objects"
    thumbs_dir = REPO_ROOT / "assets" / "images" / "thumbnails"

    if args.all:
        targets = sorted(sprites_dir.glob("*.png"))
    else:
        ids = []
        for pack_cfg in PACK_PLAN.values():
            for obj in pack_cfg["items"]:
                ids.append(obj.id)
        targets = [sprites_dir / f"{i}.png" for i in ids]
        targets = [t for t in targets if t.exists()]

    # Filter to only those that actually need removal
    work = []
    for path in targets:
        if args.force or has_white_background(path):
            work.append(path)
    if args.limit > 0:
        work = work[:args.limit]

    usd_est = len(work) * 0.005
    print(f"Candidates: {len(targets)}")
    print(f"Needs processing: {len(work)}")
    print(f"Estimated cost: ${usd_est:.2f}")
    print(f"Mode: {'EXECUTE' if args.execute else 'DRY-RUN'}")
    print()

    for i, sprite_path in enumerate(work, 1):
        tag = f"[{i}/{len(work)}]"
        if not args.execute:
            print(f"  {tag} DRY bg-remove: {sprite_path.name}")
            continue
        print(f"  {tag} bg-remove: {sprite_path.name}")
        try:
            cleaned = fal_remove_background(fal_key, sprite_path)
        except Exception as e:
            print(f"       FAILED: {e}")
            continue
        cleaned.save(sprite_path, format="PNG", optimize=True)
        # Regenerate the thumbnail from the cleaned sprite so the
        # collection screen shows the transparent version too.
        thumb_path = thumbs_dir / f"{sprite_path.stem}_thumb.png"
        make_thumbnail(sprite_path, thumb_path)
        print(f"       saved -> {sprite_path.name} + thumbnail")


if __name__ == "__main__":
    main()
