"""SHARD COLOUR fix for S9 (page 21, Goo Coast bounce). The floating shard there
rendered as a cool SILVER/BLUE-WHITE crystal; everywhere else in the book the
shards are a warm GOLDEN-AMBER glow (cf. page 16). Surgical img2img edit in the
s_arms_fix / s_age_fix mould: reproduce the spread EXACTLY and change ONLY the
shard's colour/glow to warm gold -- same shape, same position, same sparkle,
same friends, same dawn cube, same water/sky/composition, seam-safe center.

3 candidates + an ORIGINAL-vs-candidates seam-marked compare sheet.

Usage: python s09_shard_fix.py
"""
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
SRC = "full_s09_1.png"      # the current S9 pick (pre-upscale)
N = 3

PROMPT = (
    "This is a finished soft painterly children's picture-book spread (watercolor and "
    "gouache): three little friends -- peach Soft Dumpling, blue Goo Ball, white floppy-eared "
    "Blushy Bun -- bounce up over a glossy aqua sea reaching toward a floating shard of light, "
    "while a large dawn-coloured cube watches from the water on the left.\n\n"
    "REPRODUCE THIS IMAGE EXACTLY -- the same three friends (same faces, eyes, mouths, colours, "
    "fur/skin, ears, poses and positions), the same dawn cube, the same sea, bubbles, sky, "
    "clouds, lighting, brushwork and two-page layout, with the calm open center kept open.\n\n"
    "THE ONE CHANGE: the floating shard of light is currently a cool SILVER / BLUE-WHITE crystal. "
    "Recolour ONLY that shard to a warm GOLDEN-AMBER glowing light -- a sunlit honey-gold / topaz "
    "shard with a soft warm glow and gentle sparkle, matching the warm golden shards elsewhere in "
    "the book. Keep the shard in the SAME position and the SAME size and roughly the same faceted "
    "shape; change only its COLOUR and glow from cool blue-white to warm gold. It must NOT be "
    "blue, silver, or white any more. Do not change anything else in the picture. "
    "No text, no words, no letters, no border."
)
CFG = types.GenerateContentConfig(image_config=types.ImageConfig(aspect_ratio="21:9"))
BLEED = 37; PW = 2625; PH = 2625; INNER = PW - BLEED; GUTTER = 75


def open_book_seam(img):
    img = img.convert("RGB")
    new_w = int(img.width * PH / img.height)
    s = img.resize((new_w, PH), PIL.Image.LANCZOS)
    sx = new_w // 2
    v = s.crop((sx - INNER, 0, sx + BLEED, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    r = s.crop((sx - BLEED, 0, sx + INNER, PH)).crop((BLEED, BLEED, PW - BLEED, PH - BLEED))
    c = PIL.Image.new("RGB", (v.width + r.width, v.height))
    c.paste(v, (0, 0)); c.paste(r, (v.width, 0))
    d = ImageDraw.Draw(c, "RGBA")
    d.rectangle((v.width - GUTTER, 0, v.width + GUTTER, c.height), fill=(255, 60, 60, 70))
    d.line((v.width, 0, v.width, c.height), fill=(255, 30, 30), width=4)
    return c


def gen(base):
    r = client.models.generate_content(model="gemini-3-pro-image-preview",
                                       contents=[PROMPT, base], config=CFG)
    for part in r.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            return part.inline_data.data
    return None


try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()

base = PIL.Image.open(REG / SRC).convert("RGB")
rows = [("S09 ORIGINAL (page 21; silver/blue shard) -- red line = fold", open_book_seam(base))]
for k in range(1, N + 1):
    print(f"S09 shard-fix candidate {k}/{N} ...", flush=True)
    try:
        data = gen(base)
    except Exception as e:
        print("   ERROR", repr(e)[:160]); continue
    if not data:
        print("   none returned"); continue
    p = REG / f"s09_shard_{k}.png"
    p.write_bytes(data)
    rows.append((f"S09 shard-fix {k} (gold)", open_book_seam(PIL.Image.open(p))))
    print("   saved", p.name, flush=True)

W = 1200
cells = []
for label, ob in rows:
    im = ob.resize((W, int(W * 0.5)), PIL.Image.LANCZOS)
    bar = PIL.Image.new("RGB", (W, 32), (30, 30, 30))
    ImageDraw.Draw(bar).text((8, 4), label, font=F, fill=(255, 255, 255))
    cell = PIL.Image.new("RGB", (W, 32 + im.height), (0, 0, 0))
    cell.paste(bar, (0, 0)); cell.paste(im, (0, 32))
    cells.append(cell)
out = PIL.Image.new("RGB", (W, sum(c.height for c in cells) + 10 * max(1, len(cells) - 1)), (0, 0, 0))
y = 0
for c in cells:
    out.paste(c, (0, y)); y += c.height + 10
out.save(REG / "s09_shard_compare.png")
print("   WROTE s09_shard_compare.png", flush=True)
print("DONE")
