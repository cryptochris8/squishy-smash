"""Integrate one approved stuck-spread pick: back up the original (once), then
upscale the chosen nudge 4x to print res and drop it into the print spreads dir.
Usage: python integrate_spread.py <spread_num> <source_filename_in__tmp_spine_regen>"""
import sys, os, shutil, subprocess, json, time
from pathlib import Path
import httpx
_o = httpx.Client.__init__; _oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
import warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")
import fal_client
from PIL import Image

HOME = Path(r"C:\Users\chris")
PROJ = HOME / "Squishy-smash"
REG = PROJ / "_tmp_spine_regen"
SPREADS_DIR = PROJ / "book2_final_spreads_print"
BACKUP = SPREADS_DIR / "_orig_centered_backup"
BACKUP.mkdir(exist_ok=True)
os.environ["FAL_KEY"] = (HOME / "fal.key.txt").read_text(encoding="utf-8").strip()

PROMPT = ("hand-painted watercolor and gouache picture book illustration, soft brush "
          "strokes, painterly hand-painted texture, paper grain, picture book for ages "
          "4 to 8, masterpiece, best quality, highres")
NEGATIVE = ("(worst quality, low quality, normal quality:2), 3d render, plastic, photoreal, "
            "glossy plastic, text, letters, watermark, signature")


def upscale(src_path, out_path):
    url = fal_client.upload_file(str(src_path))
    t0 = time.time()
    r = fal_client.submit("fal-ai/clarity-upscaler", arguments={
        "image_url": url, "upscale_factor": 4, "creativity": 0.25, "resemblance": 0.75,
        "prompt": PROMPT, "negative_prompt": NEGATIVE, "num_inference_steps": 18,
        "enable_safety_checker": False}).get()
    if "image" in r and r["image"].get("url"):
        subprocess.run(["curl", "--ssl-no-revoke", "-sS", "-L", "-o", str(out_path), r["image"]["url"]],
                       check=True, timeout=300)
        with Image.open(out_path) as im:
            print(f"   placed {out_path.name} {im.size} in {int(time.time()-t0)}s")
        return True
    print("   !! no image", json.dumps(r)[:200]); return False


n = int(sys.argv[1]); srcfile = sys.argv[2]
dst = SPREADS_DIR / f"spread_{n:02d}.png"
bak = BACKUP / f"spread_{n:02d}.png"
if dst.exists() and not bak.exists():
    shutil.copy2(dst, bak); print(f"backed up original spread_{n:02d}.png")
print(f"S{n:02d}: upscaling {srcfile} 4x and placing ...")
upscale(REG / srcfile, dst)
print("DONE")
