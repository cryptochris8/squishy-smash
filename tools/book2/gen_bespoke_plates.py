"""Generate per-spread bespoke plates via Fal FLUX dev (2048×2048).

Distinct scene-specific plates for the spreads where the base 3 pack-world
plates were getting reused too much. Output goes to book/spread_poc/ alongside
the base plates, named plate_sNN_*.png so the spec files can reference them.
"""
import json, os, subprocess, sys
from PIL import Image

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "fal.key.txt"), encoding="utf-8").read().strip()
OUT_DIR = os.path.join(SQ, "book", "spread_poc")

PLATES = [
    {
        "name": "s02_flicker",
        "prompt": (
            "A cozy children's picture book illustration of a gentle evening sky "
            "over rolling pastel pudding hills, with a small luminous Sparkle "
            "visibly cracked and splitting into three soft glowing shards drifting "
            "slowly in different directions across the sky. Dreamy painterly mood, "
            "pastel palette cream peach blush pink butter yellow soft lavender. "
            "Full bleed edge to edge with rich detail. No characters, no people, "
            "no creatures, no text, no logo, no watermark. Picture book art for ages 4 to 8."
        ),
    },
    {
        "name": "s04_border",
        "prompt": (
            "A cozy children's picture book illustration of a magical border where "
            "two soft pastel landscapes meet in the center: on the left soft "
            "rolling cream and peach Pudding Hills with a thin pale golden syrup "
            "river thinning out, on the right glossy mint green and aqua bubble-tide "
            "of Goo Coast lapping onto pale sand. The two worlds meet gently in the "
            "middle of the frame under a soft pastel sky. Dreamy painterly "
            "watercolor and gouache, pastel palette. Full bleed edge to edge with "
            "rich detail. No characters, no people, no creatures, no text, no logo, "
            "no watermark. Picture book art for ages 4 to 8."
        ),
    },
    {
        "name": "s07_orchard",
        "prompt": (
            "A cozy children's picture book illustration of the edge of a magical "
            "pudding orchard, soft rounded gleaming pastel fruit trees with "
            "cream-and-peach foliage, a small glowing shard of warm light resting "
            "on the soft ground at the orchard's edge, warm pastel sky with soft "
            "pink and cream clouds above. Dreamy painterly watercolor and gouache. "
            "Pastel palette cream peach blush butter yellow soft lavender. "
            "Full bleed edge to edge. No characters, no people, no creatures, "
            "no text, no logo, no watermark. Picture book art for ages 4 to 8."
        ),
    },
    {
        "name": "s09_bouncing",
        "prompt": (
            "A cozy children's picture book illustration of a closer view of Goo "
            "Coast's glossy bubble-tide, soft mint and aqua waves with rounded "
            "jelly bubbles bouncing playfully above the water like dewdrops, soft "
            "pastel sky with fluffy seafoam clouds, a small bright glowing shard "
            "of light visible just above the bouncing water at the center. "
            "Pastel palette mint green sky blue pearl white butter cream aqua. "
            "Dreamy painterly watercolor and gouache. Full bleed edge to edge. "
            "No characters, no people, no creatures, no text, no logo, no watermark. "
            "Picture book art for ages 4 to 8."
        ),
    },
    {
        "name": "s10_mushrooms",
        "prompt": (
            "A cozy children's picture book illustration of a gentle moonlit "
            "meadow in Moonlit Hollow with clusters of soft glowing silver "
            "mushrooms scattered across rolling lavender and indigo hills, a soft "
            "round glowing moon overhead, gentle fireflies drifting in the soft "
            "night air, silhouetted rounded trees at the edges. Pastel palette "
            "lavender soft indigo pearl white dusty pink silver. Dreamy painterly "
            "watercolor and gouache, soft moonlit glow, gentle and never scary. "
            "Full bleed edge to edge. No characters, no people, no creatures, "
            "no text, no logo, no watermark. Picture book art for ages 4 to 8."
        ),
    },
    {
        "name": "s14_overview",
        "prompt": (
            "A cozy children's picture book illustration of an enchanted "
            "three-region overview at golden hour: on the left soft warm pudding "
            "hills with peach and cream, in the middle glossy mint-green Goo Coast "
            "with a gentle bubble tide, on the right gentle lavender Moonlit Hollow "
            "with a soft moon, all three regions visible together meeting near the "
            "center of the frame, a large bright restored Sparkle of warm golden "
            "light shining brilliantly in the sky above the whole scene. Dreamy "
            "painterly watercolor and gouache, harmonious pastel palette. "
            "Full bleed edge to edge with rich detail. No characters, no people, "
            "no creatures, no text, no logo, no watermark. Picture book art for ages 4 to 8."
        ),
    },
    {
        "name": "s16_arrival",
        "prompt": (
            "A cozy children's picture book illustration of a quiet warm intimate "
            "corner of Pudding Hills at golden sunset, a small soft nest-like "
            "clearing nestled among gentle cream and peach hills with a warm soft "
            "golden glow at the center, the feeling of arriving home, soft pastel "
            "sky with rose and lavender clouds. Dreamy painterly watercolor and "
            "gouache, pastel palette cream peach blush butter yellow gold soft "
            "lavender. Full bleed edge to edge. No characters, no people, no "
            "creatures, no text, no logo, no watermark. Picture book art for ages 4 to 8."
        ),
    },
    {
        "name": "s18_bedtime",
        "prompt": (
            "A cozy children's picture book illustration of a gentle bedtime sky "
            "over soft rolling pastel pudding hills at dusk, the sky a soft "
            "gradient of pink and lavender with a small distant Sparkle of warm "
            "light shining gently. Very peaceful, very still, the world settling "
            "down for sleep. Dreamy painterly watercolor and gouache, pastel "
            "palette soft pink lavender cream butter yellow soft indigo. Full "
            "bleed edge to edge. No characters, no people, no creatures, no text, "
            "no logo, no watermark. Picture book art for ages 4 to 8."
        ),
    },
]


def gen_plate(cfg):
    body = {
        "prompt": cfg["prompt"],
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
        capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=SQ,
        timeout=240,
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
        capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=SQ,
    )
    print(r2.stdout.strip())

    img = Image.open(raw_path)
    out = os.path.join(OUT_DIR, f"plate_{cfg['name']}.png")
    img.convert("RGB").save(out, format="PNG", optimize=True)
    os.remove(raw_path)
    print(f"  -> {out} ({img.size})")


for cfg in PLATES:
    gen_plate(cfg)

print("DONE")
