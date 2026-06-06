"""
PROTOTYPE: regenerate 4 of the worst-mismatched gameplay sprites by
reference-locking them to their trading-card art (the Book 2 method),
then build before/after comparison strips.

Writes ONLY to _sprite_restyle_proto/ — never touches assets/images/objects/.

Pipeline per character:
  1. Load the trading card (assets/cards/final_48/NNN_Name.webp), downscale,
     send as a reference image to a Fal.ai reference-conditioned model
     (nano-banana/edit = Gemini image; flux-pro/kontext fallback) with a
     prompt that says "recreate ONLY this character as a clean white-bg sprite".
  2. BiRefNet background removal -> transparent cutout.
  3. Center into a 512x512 RGBA canvas (matches the in-game sprite spec).
  4. Compose [CARD | OLD SPRITE | NEW SPRITE] strip for eyeballing.

Requires FAL_KEY in .env.
"""

import base64
import io
import sys
import time
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from generate_pack_content import load_env, ENV_PATH, _retry  # noqa: E402

OUT = REPO / "_sprite_restyle_proto"
(OUT / "raw").mkdir(parents=True, exist_ok=True)
(OUT / "cutout").mkdir(parents=True, exist_ok=True)
(OUT / "compare").mkdir(parents=True, exist_ok=True)

# (slug, card filename) — the 4 worst mismatches from the audit
TARGETS = [
    ("goo_ball", "017_Goo_Ball.webp"),
    ("jelly_bun", "002_Jelly_Bun.webp"),
    ("singularity_goo_core", "032_Singularity_Goo_Core.webp"),
    ("phantom_jelly_beast", "047_Phantom_Jelly_Beast.webp"),
]

PROMPT = (
    "The reference image is a trading card. Recreate ONLY the single main hero "
    "squishy character shown in the center of that card. Keep its EXACT colors, "
    "body shape, facial expression, eyes, and every signature feature (patterns, "
    "toppings, limbs, ears, glow, textures). Render that same character as one "
    "clean video-game sprite: a single centered character, full body, facing "
    "forward in a cheerful neutral pose, on a plain solid pure-white background. "
    "Glossy kawaii squishy 3D toy style with soft studio lighting, matching the "
    "reference's rendering. Do NOT include the card border, any text, the rarity "
    "badge, the card frame, background scenery, floating sparkles, extra "
    "characters, or props. Just the one character, large and centered, on white."
)

# Reference-conditioned model candidates, tried in order.
MODELS = [
    ("fal-ai/nano-banana/edit", "image_urls_list"),
    ("fal-ai/flux-pro/kontext", "image_url_single"),
]


def card_data_uri(card_path: Path, max_side: int = 1024) -> str:
    img = Image.open(card_path).convert("RGB")
    w, h = img.size
    scale = min(1.0, max_side / max(w, h))
    if scale < 1.0:
        img = img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    b64 = base64.b64encode(buf.getvalue()).decode("ascii")
    return f"data:image/png;base64,{b64}"


def fal_queue(fal_key: str, model: str, payload: dict, timeout_polls: int = 240):
    headers = {"Authorization": f"Key {fal_key}", "Content-Type": "application/json"}
    submit_url = f"https://queue.fal.run/{model}"

    def _submit():
        r = requests.post(submit_url, headers=headers, json=payload, timeout=120)
        r.raise_for_status()
        return r.json()

    data = _retry(_submit)
    status_url = data.get("status_url")
    result_url = data.get("response_url")
    if not status_url or not result_url:
        raise RuntimeError(f"Unexpected submit response: {data}")

    def _poll():
        r = requests.get(status_url, headers=headers, timeout=30)
        r.raise_for_status()
        return r.json()

    for _ in range(timeout_polls):
        time.sleep(0.5)
        s = _retry(_poll, attempts=3)
        st = s.get("status")
        if st == "COMPLETED":
            break
        if st in ("ERROR", "CANCELLED", "FAILED"):
            raise RuntimeError(f"Fal job {st}: {s}")
    else:
        raise TimeoutError("Fal job timed out")

    def _fetch():
        r = requests.get(result_url, headers=headers, timeout=30)
        r.raise_for_status()
        return r.json()

    return _retry(_fetch)


def generate_referenced(fal_key: str, prompt: str, data_uri: str) -> bytes:
    last = None
    for model, shape in MODELS:
        if shape == "image_urls_list":
            payload = {"prompt": prompt, "image_urls": [data_uri], "num_images": 1}
        else:
            payload = {"prompt": prompt, "image_url": data_uri,
                       "num_images": 1, "guidance_scale": 3.5}
        try:
            print(f"    -> trying {model}")
            result = fal_queue(fal_key, model, payload)
            imgs = result.get("images") or ([result["image"]] if result.get("image") else [])
            url = imgs[0]["url"]
            print(f"       ok via {model}")
            return _retry(lambda: requests.get(url, timeout=120).content)
        except Exception as e:
            msg = str(e)[:200]
            print(f"       {model} failed: {msg}")
            last = e
    raise RuntimeError(f"All reference models failed. Last: {last}")


def birefnet_cutout(fal_key: str, png_bytes: bytes) -> Image.Image:
    headers = {"Authorization": f"Key {fal_key}", "Content-Type": "application/json"}
    b64 = base64.b64encode(png_bytes).decode("ascii")
    payload = {"image_url": f"data:image/png;base64,{b64}"}
    result = fal_queue(fal_key, "fal-ai/birefnet", payload)
    info = result.get("image") or (result.get("images", [{}])[0] if result.get("images") else None)
    if not info or "url" not in info:
        raise RuntimeError(f"No image in BiRefNet result: {result}")
    raw = _retry(lambda: requests.get(info["url"], timeout=60).content)
    return Image.open(io.BytesIO(raw)).convert("RGBA")


def center_512(cut: Image.Image, size: int = 512, pad_frac: float = 0.92) -> Image.Image:
    bbox = cut.getbbox()
    if bbox:
        cut = cut.crop(bbox)
    target = int(size * pad_frac)
    w, h = cut.size
    scale = min(target / w, target / h)
    cut = cut.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(cut, ((size - cut.width) // 2, (size - cut.height) // 2), cut)
    return canvas


def _font(sz):
    for p in ("arial.ttf", "C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf"):
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            continue
    return ImageFont.load_default()


def on_bg(img_rgba: Image.Image, box: int, bg=(238, 238, 242)) -> Image.Image:
    panel = Image.new("RGB", (box, box), bg)
    im = img_rgba.convert("RGBA")
    im.thumbnail((box - 16, box - 16), Image.LANCZOS)
    panel.paste(im, ((box - im.width) // 2, (box - im.height) // 2), im)
    return panel


def build_strip(name, card_path, old_path, new_512, out_path):
    box = 440
    head = 54
    gap = 12
    cols = 3
    W = cols * box + (cols + 1) * gap
    H = head + box + 2 * gap
    strip = Image.new("RGB", (W, H), (255, 255, 255))
    d = ImageDraw.Draw(strip)
    d.text((gap, 14), name, fill=(20, 20, 30), font=_font(30))

    labels = ["CARD ART (canon)", "OLD SPRITE (in game)", "NEW SPRITE (prototype)"]
    panels = [
        on_bg(Image.open(card_path).convert("RGBA"), box),
        on_bg(Image.open(old_path).convert("RGBA"), box),
        on_bg(new_512, box),
    ]
    lf = _font(22)
    for i, (panel, lab) in enumerate(zip(panels, labels)):
        x = gap + i * (box + gap)
        y = head + gap
        strip.paste(panel, (x, y))
        d.rectangle([x, y, x + box - 1, y + box - 1], outline=(210, 210, 218), width=1)
        d.text((x + 8, head - 26), lab, fill=(90, 90, 100), font=lf)
    strip.save(out_path, format="PNG")
    return out_path


def main():
    env = load_env(ENV_PATH)
    fal_key = env.get("FAL_KEY")
    if not fal_key:
        print("ERROR: FAL_KEY missing in .env")
        sys.exit(1)

    cards_dir = REPO / "assets" / "cards" / "final_48"
    objs_dir = REPO / "assets" / "images" / "objects"

    for slug, card_file in TARGETS:
        print(f"\n=== {slug} ===")
        card_path = cards_dir / card_file
        old_path = objs_dir / f"{slug}.webp"

        print("  [1/4] generate (reference-locked to card)")
        img_bytes = generate_referenced(fal_key, PROMPT, card_data_uri(card_path))
        raw_path = OUT / "raw" / f"{slug}.png"
        Image.open(io.BytesIO(img_bytes)).convert("RGBA").save(raw_path)

        print("  [2/4] background removal (BiRefNet)")
        try:
            cut = birefnet_cutout(fal_key, img_bytes)
        except Exception as e:
            print(f"       bg-remove failed ({str(e)[:120]}); using raw")
            cut = Image.open(io.BytesIO(img_bytes)).convert("RGBA")

        print("  [3/4] center into 512x512")
        new_512 = center_512(cut)
        new_512.save(OUT / "cutout" / f"{slug}.png")

        print("  [4/4] build comparison strip")
        out = build_strip(slug, card_path, old_path, new_512,
                          OUT / "compare" / f"{slug}.png")
        print(f"       -> {out}")

    print("\nDONE. Comparison strips in _sprite_restyle_proto/compare/")


if __name__ == "__main__":
    main()
