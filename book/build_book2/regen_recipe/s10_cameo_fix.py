"""S10 fix: the Star-Eyed Bunny cameo sits at the far-right edge and the print
crop clips it. NBP edit of pilot_s10_1.png -> move the cameo inward, keep the
validated trio + scene EXACTLY. 3 candidates + seam-cropped previews."""
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
base = PIL.Image.open(REG / "pilot_s10_1.png").convert("RGB")

PROMPT = (
    "This is a finished soft painterly children's picture-book illustration (watercolor and gouache, "
    "warm 'Knight Owl' dusk style): a wide 21:9 two-page spread of three plush friends on the LEFT -- "
    "peach Soft Dumpling with a single spiral curl, blue Goo Ball, and a white floppy-eared Blushy "
    "Bun -- walking into a violet Moonlit Hollow glade with a crescent moon, soft stars, silver "
    "mushrooms, and gnarled trees framing the far left and far right. Keep the three friends on the "
    "LEFT, the moon, the sky, the glade and the trees EXACTLY as they are. Make ONE change: a small "
    "white STAR-EYED BUNNY cameo is tucked at the FAR-RIGHT edge of the picture -- REMOVE it from the "
    "edge entirely and REPAINT that same little star-eyed bunny further INTO the scene, out in the "
    "open moonlit glade roughly three-quarters of the way across (clearly to the LEFT of the "
    "right-side tree), sitting on a silver mushroom cap or a small mossy rock in the grass -- small "
    "and atmospheric, FULLY visible, well clear of the right edge. The far-right edge must now show "
    "ONLY tree, moss and glade -- NO bunny at or near the right edge. No text, no words, no border."
)
CFG = types.GenerateContentConfig(image_config=types.ImageConfig(aspect_ratio="21:9"))
BLEED = 37; PW = 2625; PH = 2625; INNER = PW - BLEED; GUTTER = 75


def seam_crop(img):
    img = img.convert("RGB")
    nw = int(img.width * PH / img.height)
    s = img.resize((nw, PH), PIL.Image.LANCZOS); sx = nw // 2
    v = s.crop((sx - INNER, 0, sx + BLEED, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    r = s.crop((sx - BLEED, 0, sx + INNER, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    c = PIL.Image.new("RGB", (v.width + r.width, v.height)); c.paste(v, (0, 0)); c.paste(r, (v.width, 0))
    d = ImageDraw.Draw(c, "RGBA")
    d.line((v.width, 0, v.width, c.height), fill=(255, 30, 30), width=4)
    return c


for k in (1, 2, 3):
    print(f"S10 cameo-fix candidate {k} ...", flush=True)
    resp = client.models.generate_content(model="gemini-3-pro-image-preview",
                                          contents=[PROMPT, base], config=CFG)
    data = None
    for part in resp.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            data = part.inline_data.data; break
    if not data:
        print("   none"); continue
    p = REG / f"s10fix_{k}.png"; p.write_bytes(data)
    seam_crop(PIL.Image.open(p)).resize((1400, 600), PIL.Image.LANCZOS).save(REG / f"s10fix_{k}_crop.png")
    print("   saved", p.name, flush=True)
print("DONE")
