"""Generate the 3 pack-world environment plates via Fal FLUX dev. Second pass for the Book #2 POC."""
import json, os, subprocess, sys
from PIL import Image

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "fal.key.txt"), encoding="utf-8").read().strip()
OUT_DIR = os.path.join(SQ, "book", "spread_poc")
os.makedirs(OUT_DIR, exist_ok=True)

PLATES = [
    {
        "name": "pudding_hills",
        "prompt": (
            "A cozy children's picture book illustration of Pudding Hills: "
            "a wide landscape of soft rounded smooth pudding hills like upturned bowls of cream, "
            "with a gentle drizzle of pale golden syrup winding through the valley. "
            "Sugar sprinkles drift gently in the warm pastel sky among soft pink and cream clouds. "
            "Pastel palette — cream, peach, blush pink, butter yellow, soft lavender — no orange, no red, no magenta. "
            "Whimsical kawaii style, watercolor and gouache painting, soft daylight, dreamy painterly depth, "
            "fills the frame edge to edge with rich detail and atmosphere. "
            "Open foreground meadow in the lower third. "
            "Picture book art for ages 4 to 8. No characters, no people, no creatures, no text, no logo, no watermark."
        ),
    },
    {
        "name": "goo_coast",
        "prompt": (
            "A cozy children's picture book illustration of Goo Coast: "
            "a wide pastel beach landscape where a soft glossy bubble-tide rolls onto a pale sandy shore. "
            "Shiny rounded mint-green and aqua jelly bubbles float just above the water like dewdrops. "
            "Pastel palette — mint green, soft sky blue, pearl white, butter cream, gentle aqua — no pink, no red, no magenta. "
            "Soft pastel sky with fluffy seafoam clouds. Gentle waves with smooth glossy crests. "
            "Open foreground sand in the lower third. "
            "Whimsical kawaii style, watercolor and gouache painting, soft daylight, dreamy painterly depth, "
            "fills the frame edge to edge with rich detail and atmosphere. "
            "Picture book art for ages 4 to 8. No characters, no people, no creatures, no text, no logo, no watermark."
        ),
    },
    {
        "name": "moonlit_hollow",
        "prompt": (
            "A cozy children's picture book illustration of Moonlit Hollow at gentle night: "
            "a round soft glowing moon turned down to nightlight brightness over rolling lavender and indigo hills, "
            "a gentle deep-blue meadow scattered with faint glowing fireflies, "
            "soft mist drifting between rounded silhouetted trees. "
            "Pastel palette — lavender, soft indigo, pearl white, dusty pink, butter cream — soft dark, never scary or harsh. "
            "Open foreground clearing in the lower third. "
            "Whimsical kawaii style, watercolor and gouache painting, gentle moonlit glow, dreamy painterly depth, "
            "fills the frame edge to edge with rich detail and atmosphere. "
            "Picture book art for ages 4 to 8. No characters, no people, no creatures, no text, no logo, no watermark."
        ),
    },
]


def gen_plate(cfg):
    body = {
        "prompt": cfg["prompt"],
        # Production scale — 2048x2048 single-page plate. KDP 8.5x8.5 at 300 DPI
        # is 2550x2550; this is the safe FLUX dev ceiling for square. Can be
        # AI-upscaled via fal-ai/clarity-upscaler to true print resolution later.
        "image_size": {"width": 2048, "height": 2048},
        "num_inference_steps": 28,
        "guidance_scale": 3.5,
        "num_images": 1,
        "enable_safety_checker": False,
    }
    body_path = os.path.join(SQ, f"_tmp_fal_body_{cfg['name']}.json")
    with open(body_path, "w", encoding="utf-8") as f:
        json.dump(body, f)

    print(f">>> Fal FLUX dev: {cfg['name']}")
    r = subprocess.run(
        ["curl", "--ssl-no-revoke", "-sS", "-X", "POST",
         "https://fal.run/fal-ai/flux/dev",
         "-H", f"Authorization: Key {KEY}",
         "-H", "Content-Type: application/json",
         "--data-binary", f"@{body_path}",
         "-w", "\n__HTTP__ %{http_code}\n"],
        capture_output=True, text=True, cwd=SQ,
    )
    if r.returncode != 0:
        print("STDERR:", r.stderr[-1200:])
        sys.exit(1)
    body_text, _, http_line = r.stdout.rpartition("\n__HTTP__ ")
    http_code = http_line.strip().split("\n")[0]
    if http_code != "200":
        print(f"  HTTP {http_code}: {body_text[-1500:]}")
        sys.exit(1)
    data = json.loads(body_text)
    img_url = data["images"][0]["url"]

    raw_path = os.path.join(OUT_DIR, f"_tmp_fal_{cfg['name']}.image")
    r2 = subprocess.run(
        ["curl", "--ssl-no-revoke", "-sS", "-L", img_url, "-o", raw_path,
         "-w", "  HTTP %{http_code} size %{size_download}\n"],
        capture_output=True, text=True, cwd=SQ,
    )
    print(r2.stdout.strip())

    img = Image.open(raw_path)
    out = os.path.join(OUT_DIR, f"plate_{cfg['name']}.png")
    img.convert("RGB").save(out, format="PNG", optimize=True)
    print(f"  -> {out} ({img.size})")


for cfg in PLATES:
    gen_plate(cfg)

print("DONE")
