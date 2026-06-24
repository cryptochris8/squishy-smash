"""Reusable Goo-eye fix: feed a candidate back with the original black-eyed Goo
crop as reference, change ONLY Goo's eyes (green -> black). Keeps everything else.
Usage: python eyefix.py <candidate_filename_in__tmp_spine_regen>"""
import sys
import httpx
_o = httpx.Client.__init__; _oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
from pathlib import Path
import PIL.Image
from google import genai
from google.genai import types

KEY = open(r"C:\Users\chris\gemini.key.txt").read().strip()
client = genai.Client(api_key=KEY)
REG = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen")
ref = PIL.Image.open(REG / "goo_blackeyes_ref.png").convert("RGB")
cand_file = sys.argv[1]
cand = PIL.Image.open(REG / cand_file).convert("RGB")

PROMPT = (
    "This is a finished children's picture-book spread. KEEP THE IMAGE EXACTLY THE SAME "
    "-- identical composition, identical characters, identical colors, background and "
    "painterly style. Change ONE thing only: the blue Goo Ball currently has GREEN eyes; "
    "change them to small simple BLACK dot eyes with a tiny white shine, exactly like the "
    "blue Goo Ball's eyes in the SECOND reference image. CRITICAL: KEEP the Goo Ball's "
    "MOUTH and smile exactly as they are -- do not remove, shrink, or move the mouth. "
    "Change NOTHING else (only the eye color).")
CFG = types.GenerateContentConfig(image_config=types.ImageConfig(aspect_ratio="21:9"))

r = client.models.generate_content(model="gemini-3-pro-image-preview",
                                   contents=[PROMPT, cand, ref], config=CFG)
for part in r.candidates[0].content.parts:
    if getattr(part, "inline_data", None) and part.inline_data.data:
        out = REG / (Path(cand_file).stem + "_eyefix.png")
        out.write_bytes(part.inline_data.data)
        print("WROTE", out.name)
        break
else:
    print("no image")
