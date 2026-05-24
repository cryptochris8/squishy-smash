"""Generate Book #2 protagonist sprites via Fal FLUX dev + BiRefNet alpha-mask.
Configurable per run — currently set to Phase 2 (pose variants).
Re-edit the CHARS list and re-run as needed."""
import json, os, subprocess, sys, time
from PIL import Image

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "fal.key.txt"), encoding="utf-8").read().strip()
OUT_DIR = os.path.join(SQ, "book", "spread_poc", "chars")
os.makedirs(OUT_DIR, exist_ok=True)

STYLE_SUFFIX = (
    " 3D render, soft-gloss toy aesthetic, pastel palette, centered 3/4 front angle, "
    "warm rim light from upper-left, soft key light, subtle subsurface scattering, "
    "pure white studio background, cute satisfying squishable character, 1:1 aspect, "
    "professional children's picture book character render, "
    "no text, no logo, no watermark, no shadow on ground, "
    "not photorealistic skin, not trademarked."
)

CHARS = [
    # --- SOFT DUMPLING variants ---
    {
        "id": "soft_dumpling_scared",
        "prompt": (
            "A cute kawaii Soft Dumpling squishy character: a small peach-cream "
            "colored steamed bun (xiao long bao style) with a soft swirled topknot on top, "
            "wide worried teary eyes, mouth a small 'o' shape of surprise, "
            "gentle pink blush on both cheeks, no arms, small visible feet, "
            "leaning slightly backward with body squished down in a scared startled pose. "
            "Anxious but adorable."
        ),
    },
    {
        "id": "soft_dumpling_triumphant",
        "prompt": (
            "A cute kawaii Soft Dumpling squishy character: a small peach-cream "
            "colored steamed bun with a soft swirled topknot on top, "
            "eyes closed in a big delighted smile with sparkles around, "
            "mouth open in joyful exclamation, gentle pink blush on both cheeks, "
            "no arms, small visible feet, body stretched upward in a triumphant "
            "joyful victory pose. Beaming and ecstatic."
        ),
    },

    # --- GOO BALL variants ---
    {
        "id": "goo_ball_scared",
        "prompt": (
            "A cute kawaii Goo Ball squishy character: a bright glossy mint-green "
            "spherical jelly blob, wide worried dark dot eyes with teary glints, "
            "small 'o' shaped mouth, slight blush dots, "
            "smooth shiny surface with light reflections, slightly squished-down "
            "wobbly jelly shape, in a scared startled pose. Nervous but adorable."
        ),
    },
    {
        "id": "goo_ball_triumphant",
        "prompt": (
            "A cute kawaii Goo Ball squishy character: a bright glossy mint-green "
            "spherical jelly blob, sparkly excited dark dot eyes with star glints, "
            "big upturned grin, slight blush dots, smooth shiny surface, "
            "slightly elongated upward jelly shape, in a triumphant bouncy joyful pose. "
            "Bouncy and victorious."
        ),
    },

    # --- BLUSHY BUN BUNNY variants ---
    {
        "id": "blushy_bun_bunny_scared",
        "prompt": (
            "A cute kawaii Blushy Bun Bunny squishy character: a small soft round "
            "white bunny with floppy ears hanging down, wide worried dark dot eyes "
            "with teary glints, small 'o' shaped mouth, large rosy pink blush cheeks, "
            "a tiny pink nose, tiny paws pulled up close to chest in fear, "
            "leaning slightly backward in a scared startled pose. Anxious but adorable."
        ),
    },
    {
        "id": "blushy_bun_bunny_triumphant",
        "prompt": (
            "A cute kawaii Blushy Bun Bunny squishy character: a small soft round "
            "white bunny with floppy ears slightly perked up, sparkly excited "
            "dark dot eyes with star glints, big beaming open-mouth grin, "
            "large rosy pink blush cheeks, a tiny pink nose, tiny paws raised up "
            "high in celebration, body stretched upward in a triumphant joyful "
            "victory pose. Ecstatic and beaming."
        ),
    },
]


def curl_post_json(url, body_path):
    r = subprocess.run(
        ["curl", "--ssl-no-revoke", "-sS", "-X", "POST", url,
         "-H", f"Authorization: Key {KEY}",
         "-H", "Content-Type: application/json",
         "--data-binary", f"@{body_path}",
         "-w", "\n__HTTP__ %{http_code}\n"],
        capture_output=True, text=True, cwd=SQ,
    )
    if r.returncode != 0:
        raise SystemExit(f"curl failed: {r.stderr[-1200:]}")
    body_text, _, http_line = r.stdout.rpartition("\n__HTTP__ ")
    http_code = http_line.strip().split("\n")[0]
    if http_code != "200":
        raise SystemExit(f"HTTP {http_code}: {body_text[-1500:]}")
    return json.loads(body_text)


def curl_get_json(url):
    r = subprocess.run(
        ["curl", "--ssl-no-revoke", "-sS", url,
         "-H", f"Authorization: Key {KEY}",
         "-w", "\n__HTTP__ %{http_code}\n"],
        capture_output=True, text=True, cwd=SQ,
    )
    if r.returncode != 0:
        raise SystemExit(f"curl failed: {r.stderr[-1200:]}")
    body_text, _, http_line = r.stdout.rpartition("\n__HTTP__ ")
    return json.loads(body_text)


def download_binary(url, out_path):
    r = subprocess.run(
        ["curl", "--ssl-no-revoke", "-sS", "-L", url, "-o", out_path,
         "-w", "  size %{size_download}\n"],
        capture_output=True, text=True, cwd=SQ,
    )
    print(r.stdout.strip())


def gen_with_alpha(cfg):
    out_path = os.path.join(OUT_DIR, f"{cfg['id']}.png")
    if os.path.exists(out_path):
        print(f"  skip (exists): {cfg['id']}")
        return

    full_prompt = cfg["prompt"] + STYLE_SUFFIX
    body = {
        "prompt": full_prompt,
        "image_size": "square_hd",
        "num_inference_steps": 28,
        "guidance_scale": 3.5,
        "num_images": 1,
        "enable_safety_checker": False,
    }
    body_path = os.path.join(SQ, f"_tmp_fal_body_{cfg['id']}.json")
    with open(body_path, "w", encoding="ascii") as f:
        json.dump(body, f)

    print(f">>> {cfg['id']}: FLUX gen")
    flux_resp = curl_post_json("https://fal.run/fal-ai/flux/dev", body_path)
    flux_url = flux_resp["images"][0]["url"]

    rembg_body_path = os.path.join(SQ, f"_tmp_fal_rembg_body_{cfg['id']}.json")
    with open(rembg_body_path, "w", encoding="ascii") as f:
        json.dump({"image_url": flux_url}, f)

    print(f">>> {cfg['id']}: BiRefNet rembg submit")
    submit = curl_post_json("https://queue.fal.run/fal-ai/birefnet", rembg_body_path)
    status_url = submit["status_url"]
    response_url = submit["response_url"]

    for i in range(60):
        time.sleep(2)
        s = curl_get_json(status_url)
        status = s.get("status")
        if status == "COMPLETED":
            break
        if status in ("ERROR", "CANCELLED", "FAILED"):
            raise SystemExit(f"  BiRefNet {status}: {s}")
    else:
        raise SystemExit("  BiRefNet timeout")

    result = curl_get_json(response_url)
    alpha_url = result["image"]["url"]
    download_binary(alpha_url, out_path)
    img = Image.open(out_path)
    print(f"  -> {out_path} {img.size} {img.mode}")


for cfg in CHARS:
    gen_with_alpha(cfg)

print("DONE")
