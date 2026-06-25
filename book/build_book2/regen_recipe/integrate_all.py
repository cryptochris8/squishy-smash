"""Batch-integrate the re-rendered Book 2 picks into book2_final_spreads_print/.

For each spread: back up the original ONCE (into _orig_centered_backup), upscale
the chosen candidate 4x with fal clarity-upscaler to print res (6336x2688), and
place it as spread_NN.png.

Usage:
  python integrate_all.py           # integrate ALL picks
  python integrate_all.py 9 13      # only these spreads
  python integrate_all.py --list    # print the pick map, do nothing
"""
import sys, os, shutil, subprocess, json, time
from pathlib import Path
import httpx
_o = httpx.Client.__init__; _oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **k: (k.update(verify=False), _o(s, *a, **k))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **k: (k.update(verify=False), _oa(s, *a, **k))[1]
import warnings; warnings.filterwarnings("ignore", message="Unverified HTTPS request")
import fal_client
from PIL import Image

HOME = Path(r"C:\Users\chris"); PROJ = HOME / "Squishy-smash"
REG = PROJ / "_tmp_spine_regen"
SPREADS_DIR = PROJ / "book2_final_spreads_print"
BACKUP = SPREADS_DIR / "_orig_centered_backup"; BACKUP.mkdir(exist_ok=True)
os.environ["FAL_KEY"] = (HOME / "fal.key.txt").read_text(encoding="utf-8").strip()

# spread -> chosen candidate file in REG. S10 reuses the validated pilot target.
# S9 / S13 default to their fallbacks; updated to the re-roll picks after review.
PICKS = {
    3: "full_s03_1.png", 4: "s04_arms.png", 5: "s05_arms.png", 6: "full_s06_2.png",
    7: "s07_arms.png", 8: "s08_arms.png", 9: "full_s09_1.png", 10: "s10_arms.png",
    11: "full_s11_1.png", 12: "s12_arms.png", 13: "s13_arms.png", 14: "s14_arms.png",
    15: "s15fix_2.png", 16: "s16_arms.png", 17: "s17_arms.png", 18: "full_s18_1.png",
    # arm-raise edits (s10/s16/s17 also carry the earlier cameo/inward/model fixes)
}

PROMPT = ("hand-painted watercolor and gouache picture book illustration, soft brush strokes, "
          "painterly hand-painted texture, paper grain, picture book for ages 4 to 8, masterpiece, "
          "best quality, highres")
NEGATIVE = ("(worst quality, low quality, normal quality:2), 3d render, plastic, photoreal, glossy "
            "plastic, text, letters, watermark, signature")


def upscale(src, dst):
    url = fal_client.upload_file(str(src)); t0 = time.time()
    r = fal_client.submit("fal-ai/clarity-upscaler", arguments={
        "image_url": url, "upscale_factor": 4, "creativity": 0.25, "resemblance": 0.75,
        "prompt": PROMPT, "negative_prompt": NEGATIVE, "num_inference_steps": 18,
        "enable_safety_checker": False}).get()
    if r.get("image", {}).get("url"):
        subprocess.run(["curl", "--ssl-no-revoke", "-sS", "-L", "-o", str(dst), r["image"]["url"]],
                       check=True, timeout=300)
        with Image.open(dst) as im:
            print(f"   placed {dst.name} {im.size} in {int(time.time()-t0)}s")
        return True
    print("   !! no image url", json.dumps(r)[:200]); return False


def integrate(n):
    src = REG / PICKS[n]; dst = SPREADS_DIR / f"spread_{n:02d}.png"; bak = BACKUP / f"spread_{n:02d}.png"
    if not src.exists():
        print(f"S{n:02d}: SOURCE MISSING -> {src.name}"); return False
    if dst.exists() and not bak.exists():
        shutil.copy2(dst, bak); print(f"S{n:02d}: backed up original")
    print(f"S{n:02d}: upscaling {src.name} -> spread_{n:02d}.png")
    return upscale(src, dst)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["--list"]:
        for n in sorted(PICKS):
            print(f"  S{n:02d} <- {PICKS[n]}")
        sys.exit(0)
    todo = [int(a) for a in args] if args else sorted(PICKS)
    print("INTEGRATING:", todo)
    ok, fail = [], []
    for n in todo:
        (ok if integrate(n) else fail).append(n)
    print(f"DONE ok={ok} fail={fail}")
