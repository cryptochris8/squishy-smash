"""Raise Goo Ball's low-set nub arms via a targeted NBP edit of each spread's
current art -- keep everything else identical. 1 candidate per spread + an
ORIGINAL-vs-EDITED stacked compare so drift is easy to judge.

Usage: python s_arms_fix.py            # all listed spreads
       python s_arms_fix.py 12 13      # just these
"""
import sys
import httpx
_o = httpx.Client.__init__; _oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
from pathlib import Path
import PIL.Image
from PIL import ImageDraw, ImageFont
from google import genai
from google.genai import types

KEY = open(r"C:\Users\chris\gemini.key.txt").read().strip()
client = genai.Client(api_key=KEY)
REG = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen")

# spread -> its CURRENT source art (the picks, incl. the S10/S16/S17 fixes)
SOURCES = {
    4: "full_s04_1.png", 5: "full_s05_1.png", 7: "full_s07_1.png", 8: "full_s08_2.png",
    10: "s10fix_1.png", 12: "full_s12_1.png", 13: "full_s13_1.png", 14: "full_s14_1.png",
    16: "s16fix_3.png", 17: "full_s17_3.png",
}

PROMPT = (
    "This is a finished soft painterly children's picture-book illustration (watercolor and gouache). "
    "Reproduce this image EXACTLY -- the same characters, faces, eyes, mouths, colours, poses, "
    "positions, background, lighting and brushwork -- with ONE small anatomical correction: the little "
    "blue GOO BALL character (a round glossy blue blob) has its two small nub arms attached too LOW on "
    "its body, down near the bottom, which looks unnatural. Raise those two little nub arms HIGHER, to "
    "a natural mid-body height on its sides. Keep the Goo Ball the same size, colour, round shape, face "
    "and position -- ONLY the height of its two nub arms changes. Do not alter any other character, the "
    "background, or anything else in the picture. No text, no words, no border."
)
CFG = types.GenerateContentConfig(image_config=types.ImageConfig(aspect_ratio="21:9"))

try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()


def label(img, txt, W=900):
    im = img.resize((W, int(W * img.height / img.width)), PIL.Image.LANCZOS)
    bar = PIL.Image.new("RGB", (W, 28), (20, 20, 20))
    ImageDraw.Draw(bar).text((6, 2), txt, font=F, fill=(255, 255, 255))
    c = PIL.Image.new("RGB", (W, 28 + im.height), (0, 0, 0))
    c.paste(bar, (0, 0)); c.paste(im, (0, 28))
    return c


todo = [int(a) for a in sys.argv[1:]] if len(sys.argv) > 1 else sorted(SOURCES)
for n in todo:
    src = SOURCES[n]
    print(f"S{n:02d} arm-raise edit (from {src}) ...", flush=True)
    base = PIL.Image.open(REG / src).convert("RGB")
    try:
        resp = client.models.generate_content(model="gemini-3-pro-image-preview",
                                              contents=[PROMPT, base], config=CFG)
    except Exception as e:
        print("  ERROR", repr(e)[:160]); continue
    data = None
    for part in resp.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            data = part.inline_data.data; break
    if not data:
        print("  none returned"); continue
    out = REG / f"s{n:02d}_arms.png"; out.write_bytes(data)
    edited = PIL.Image.open(out).convert("RGB")
    a = label(base, f"S{n:02d}  ORIGINAL (arms low)")
    b = label(edited, f"S{n:02d}  ARMS-RAISED edit")
    cmp = PIL.Image.new("RGB", (a.width, a.height + b.height + 8), (0, 0, 0))
    cmp.paste(a, (0, 0)); cmp.paste(b, (0, a.height + 8))
    cmp.save(REG / f"s{n:02d}_arms_compare.png")
    print("  saved", out.name, flush=True)
print("DONE")
