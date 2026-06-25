"""S15 fix: Soft Dumpling sits at the far-left edge and the print crop clips
him. NBP edit of full_s15_1.png -> move him inward, keep Goo + bunny + the
three-land panorama EXACTLY. 3 candidates + seam-cropped previews."""
import httpx
_o = httpx.Client.__init__; _oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
from pathlib import Path
import PIL.Image
from PIL import ImageDraw
from google import genai
from google.genai import types

KEY = open(r"C:\Users\chris\gemini.key.txt").read().strip()
client = genai.Client(api_key=KEY)
REG = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen")
base = PIL.Image.open(REG / "full_s15_1.png").convert("RGB")

PROMPT = (
    "This is a finished soft painterly children's picture-book illustration (watercolor and gouache, "
    "warm 'Knight Owl' dusk style): a wide 21:9 two-page 'going home' panorama. On the LEFT, peach "
    "Soft Dumpling (a teardrop dumpling with a single spiral curl on top, small black dot eyes, pink "
    "blush) walks into the warm Pudding Hills carrying a tiny glowing light. In the CENTER-LEFT, blue "
    "Goo Ball carries a light along the teal coast. On the RIGHT, a white floppy-eared bunny walks "
    "away into the violet Moonlit Hollow. Keep Goo Ball, the bunny, the three lands, the water, the "
    "sky and the whole composition EXACTLY as they are. Make ONE change: peach Soft Dumpling on the "
    "far LEFT is too close to the left edge and is cut off -- move him INWARD to the right so he "
    "stands FULLY within the frame, comfortably clear of the left edge (still in the Pudding Hills on "
    "the left third, still carrying his light, same size and pose). The left edge must show ONLY "
    "Pudding-Hills landscape -- no part of Soft Dumpling touching the edge. No text, no words, no border."
)
CFG = types.GenerateContentConfig(image_config=types.ImageConfig(aspect_ratio="21:9"))
BLEED = 37; PW = 2625; PH = 2625; INNER = PW - BLEED


def seam_crop(img):
    img = img.convert("RGB")
    nw = int(img.width * PH / img.height)
    s = img.resize((nw, PH), PIL.Image.LANCZOS); sx = nw // 2
    v = s.crop((sx - INNER, 0, sx + BLEED, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    r = s.crop((sx - BLEED, 0, sx + INNER, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    c = PIL.Image.new("RGB", (v.width + r.width, v.height)); c.paste(v, (0, 0)); c.paste(r, (v.width, 0))
    ImageDraw.Draw(c, "RGBA").line((v.width, 0, v.width, c.height), fill=(255, 30, 30), width=4)
    return c


for k in (1, 2, 3):
    print(f"S15 dumpling-fix candidate {k} ...", flush=True)
    resp = client.models.generate_content(model="gemini-3-pro-image-preview",
                                          contents=[PROMPT, base], config=CFG)
    data = None
    for part in resp.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            data = part.inline_data.data; break
    if not data:
        print("   none"); continue
    p = REG / f"s15fix_{k}.png"; p.write_bytes(data)
    seam_crop(PIL.Image.open(p)).resize((1400, 600), PIL.Image.LANCZOS).save(REG / f"s15fix_{k}_crop.png")
    print("   saved", p.name, flush=True)
print("DONE")
