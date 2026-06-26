"""AGE/STYLE fix v2 (STRONGER) for S6 (page 14) and S8 (page 18).

v1 (s_age_fix.py) was too subtle -- the "reproduce IMAGE 1 exactly" framing
only nudged the finish. v2 keeps the SCENE locked (background, landscape,
colours, sky, lighting, layout, positions, the small cameo, the open center)
but gives the model real freedom to REDRAW the three friends in the older,
matte, painterly style of the rest of the book: smaller head-to-body ratio,
slimmer/taller little bodies, more refined faces, watercolour/gouache paper
grain instead of the glossy baby-plastic finish. Two in-book exemplars
(S7 = page 16, S13 = page 28) anchor the target look.

3 candidates per spread + an ORIGINAL-vs-candidates seam-marked compare sheet.

Usage: python s_age_fix2.py        # both
       python s_age_fix2.py 6      # just one
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

SOURCES = {6: "full_s06_2.png", 8: "s08_arms.png"}
EXEMPLARS = [REG / "s07_arms.png", REG / "s13_arms.png"]  # page 16 + page 28 = the right age

PROMPT = (
    "You are given THREE images.\n\n"
    "IMAGE 1 is a finished children's picture-book spread. KEEP its scene unchanged -- the "
    "EXACT same background, landscape, water/hills, sky, colours, lighting, the small "
    "background cameo character, and the two-page layout with a calm open center. The three "
    "main friends must stay in the SAME spots, the SAME poses, and roughly the SAME size in "
    "the frame.\n\n"
    "IMAGES 2 and 3 show the SAME three friends drawn in the CORRECT house style. Use them "
    "ONLY as the style target for the characters -- do NOT copy their backgrounds, scenes, "
    "colours, lighting, or the extra glowing creatures in them.\n\n"
    "THE PROBLEM: in image 1 the three friends are drawn TOO YOUNG and babyish -- heads far "
    "too big, bodies too short and round, shading too smooth and glossy-plastic, faces too "
    "simple. REDRAW the three friends so they clearly match images 2 and 3 instead:\n"
    "  - a noticeably SMALLER head-to-body ratio (less top-heavy, less baby-like);\n"
    "  - slightly slimmer, a little TALLER little bodies with more natural posture;\n"
    "  - soft MATTE watercolour-and-gouache rendering with visible brushwork and paper "
    "grain -- NOT a smooth glossy plastic finish;\n"
    "  - a little more refined facial detail and gentle shaping.\n"
    "Make this a clear, obvious change -- they should look like the same friends a bit more "
    "grown-up, the way they look on the other pages.\n\n"
    "They MUST stay unmistakably the SAME characters: peach Soft Dumpling (teardrop body, "
    "one spiral curl tuft, small BLACK dot eyes, pink blush, nub arms, peg feet, NO ears); "
    "blue glossy-but-matte Goo Ball (round blob, small BLACK dot eyes NOT green, nub arms); "
    "white Blushy Bun (medium-length floppy droopy ears hanging DOWN, pink inner ears, pink "
    "nose). Same colours, same gentle happy expressions. No text, no words, no border."
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


def gen(base, exemplars):
    r = client.models.generate_content(model="gemini-3-pro-image-preview",
                                       contents=[PROMPT, base, *exemplars], config=CFG)
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
    ex = [PIL.Image.open(p).convert("RGB") for p in EXEMPLARS]
    page = {6: 14, 8: 18}[n]
    rows = [(f"S{n:02d} ORIGINAL (page {page}; too young) -- red line = fold", open_book_seam(base))]
    for k in range(1, N + 1):
        print(f"S{n:02d} age-fix2 candidate {k}/{N} ...", flush=True)
        try:
            data = gen(base, ex)
        except Exception as e:
            print("   ERROR", repr(e)[:160]); continue
        if not data:
            print("   none returned"); continue
        p = REG / f"s{n:02d}_age2_{k}.png"
        p.write_bytes(data)
        rows.append((f"S{n:02d} age-fix2 {k}", open_book_seam(PIL.Image.open(p))))
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
    out.save(REG / f"s{n:02d}_age2_compare.png")
    print(f"   WROTE s{n:02d}_age2_compare.png", flush=True)


if __name__ == "__main__":
    todo = [int(a) for a in sys.argv[1:]] if len(sys.argv) > 1 else [6, 8]
    print("AGE-FIX2 spreads:", todo, flush=True)
    for n in todo:
        run(n)
    print("ALL DONE")
