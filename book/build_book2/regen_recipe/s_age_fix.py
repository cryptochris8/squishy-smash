"""AGE/STYLE fix for S6 (page 14) and S8 (page 18): the three friends render
TOO YOUNG there -- glossy, smooth, big-headed and flat -- versus the matte
painterly look they have on every other page. This is a surgical img2img edit
in the s_arms_fix mould: reproduce each spread EXACTLY and change ONLY the way
the three friends are DRAWN, pulling them toward the approved look of S7
(page 16, s07_arms.png) as the style anchor. Background, colours, poses,
positions, the small cameo, lighting and the seam-safe open center all stay.

3 candidates per spread + an ORIGINAL-vs-candidates seam-marked compare sheet.

Usage: python s_age_fix.py          # both spreads
       python s_age_fix.py 6        # just one
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

# spread -> its CURRENT source art (the exact file the final book page came from)
SOURCES = {6: "full_s06_2.png", 8: "s08_arms.png"}
# the approved "right age" look used across the rest of the book
EXEMPLAR = REG / "s07_arms.png"

PROMPT = (
    "You are given TWO images.\n\n"
    "IMAGE 1 is a finished soft painterly children's picture-book spread (watercolor and "
    "gouache). REPRODUCE IMAGE 1 -- the same three friends (peach Soft Dumpling with one "
    "spiral curl tuft and small black dot eyes; blue glossy Goo Ball with small BLACK dot "
    "eyes; white floppy-eared Blushy Bun), the same poses, the same positions, the same "
    "small background cameo character, the EXACT same background, landscape, colours, sky, "
    "lighting and two-page layout, with the calm open center kept open. Do NOT move anyone, "
    "do NOT change the scene, the colours, or the composition.\n\n"
    "IMAGE 2 is a STYLE REFERENCE ONLY -- it shows how the three friends should be DRAWN. "
    "Do NOT copy image 2's background, scene, colours or lighting; use it ONLY for the way "
    "the characters are rendered.\n\n"
    "THE ONE CHANGE: in image 1 the three friends are drawn TOO YOUNG -- too glossy, too "
    "smooth, too rounded, with over-large baby heads and flat plastic-like shading. Redraw "
    "ONLY the three friends so they match image 2: a slightly smaller head-to-body ratio (a "
    "touch less babyish), gentle matte WATERCOLOUR and GOUACHE brush texture with visible "
    "paper grain instead of a smooth glossy finish, and a little more refined facial "
    "detail -- while staying unmistakably the SAME cute characters with the SAME colours, "
    "the same small black dot eyes, the same ear length, the same curl tuft, the same kind "
    "gentle expressions. Keep them the same size and in the same spots in the scene. "
    "No text, no words, no letters, no border."
)
CFG = types.GenerateContentConfig(image_config=types.ImageConfig(aspect_ratio="21:9"))
BLEED = 37; PW = 2625; PH = 2625; INNER = PW - BLEED; GUTTER = 75
N = 3


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


def gen(base, exemplar):
    r = client.models.generate_content(model="gemini-3-pro-image-preview",
                                       contents=[PROMPT, base, exemplar], config=CFG)
    for part in r.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            return part.inline_data.data
    return None


try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()


def run(n):
    src = SOURCES[n]
    base = PIL.Image.open(REG / src).convert("RGB")
    ex = PIL.Image.open(EXEMPLAR).convert("RGB")
    page = {6: 14, 8: 18}[n]
    rows = [(f"S{n:02d} ORIGINAL (page {page}; too young) -- red line = fold", open_book_seam(base))]
    for k in range(1, N + 1):
        print(f"S{n:02d} age-fix candidate {k}/{N} ...", flush=True)
        try:
            data = gen(base, ex)
        except Exception as e:
            print("   ERROR", repr(e)[:160]); continue
        if not data:
            print("   none returned"); continue
        p = REG / f"s{n:02d}_age_{k}.png"
        p.write_bytes(data)
        rows.append((f"S{n:02d} age-fix {k}", open_book_seam(PIL.Image.open(p))))
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
    out.save(REG / f"s{n:02d}_age_compare.png")
    print(f"   WROTE s{n:02d}_age_compare.png", flush=True)


if __name__ == "__main__":
    todo = [int(a) for a in sys.argv[1:]] if len(sys.argv) > 1 else [6, 8]
    print("AGE-FIX spreads:", todo, flush=True)
    for n in todo:
        run(n)
    print("ALL DONE")
