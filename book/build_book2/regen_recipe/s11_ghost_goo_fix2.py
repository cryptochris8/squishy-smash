"""S11 ghost+goo fix v2 -- same as v1 but the recolored ghost must KEEP the
little SPIRAL CURL / flame-wisp tuft on top of its head (the gold ghost + card
043 both have it; v1 candidates smoothed it away). So: keep image 1's ghost
silhouette AND its top curl + position; only recolor warm gold -> cool
white/lavender and enlarge the eyes to the card's big sparkly look. Goo Ball
keeps the two-nub-arm cleanup. Reference (image 2) = the card-043 ghost crop,
used ONLY for colour + eyes/face (not its sparkly card background).

Base = full_s11_1.png. 3 candidates + seam-marked compare sheet.
Usage: python s11_ghost_goo_fix2.py
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
N = 3

base = PIL.Image.open(REG / "full_s11_1.png").convert("RGB")
card = PIL.Image.open(REG / "_card043_ghost.png").convert("RGB")  # cropped card-043 ghost

PROMPT = (
    "IMAGE 1 is a finished soft painterly children's picture-book spread (watercolor and "
    "gouache): a dark Moonlit-Hollow grove at night, a glowing ghost in the upper left, and "
    "three friends on the right -- peach Soft Dumpling, blue Goo Ball, white floppy-eared "
    "Blushy Bun.\n\n"
    "REPRODUCE IMAGE 1 EXACTLY -- the same grove, trees, mushrooms, moss, stars, sky, lighting, "
    "brushwork, the same Soft Dumpling and Blushy Bun, and the same two-page layout with the "
    "calm open center kept open. Make ONLY the two changes below.\n\n"
    "IMAGE 2 is the reference for the ghost's colour and FACE only (use it ONLY for that; do NOT "
    "copy its sparkly background or spiral aura).\n\n"
    "CHANGE 1 -- THE GHOST: keep the SAME ghost in IMAGE 1 -- the same silhouette, the same "
    "position and size, and ESPECIALLY keep the little SPIRAL CURL / flame-wisp tuft on TOP of "
    "its head (do NOT remove, smooth, or shrink that curl -- it is important) and its soft wispy "
    "tail and two little nub arms. Change only its COLOUR and FACE: recolour it from warm GOLD to "
    "a soft COOL WHITE-AND-LAVENDER moonlit glow, and give it BIG round sparkly friendly eyes "
    "with pink cheek blush and a gentle happy smile, matching IMAGE 2. It must glow gentle "
    "white-lavender, NOT warm gold, and it must still have its curl on top.\n\n"
    "CHANGE 2 -- THE GOO BALL: the little blue Goo Ball currently has too many small hands/arms "
    "bunched together. Give it exactly TWO small nub arms (one each side) plus its two little peg "
    "feet, and remove any extra hands or nubs. It may still gently hold the tiny shard with one "
    "nub hand. Keep it the same size, round blue shape, small BLACK dot eyes and gentle smile, in "
    "the same spot.\n\n"
    "Do not change anything else. No text, no words, no letters, no border."
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


def gen():
    r = client.models.generate_content(model="gemini-3-pro-image-preview",
                                       contents=[PROMPT, base, card], config=CFG)
    for part in r.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            return part.inline_data.data
    return None


try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()

rows = [("S11 ORIGINAL (gold ghost w/ curl; goo extra hands) -- red line = fold", open_book_seam(base))]
for k in range(1, N + 1):
    print(f"S11 ghost+goo v2 candidate {k}/{N} ...", flush=True)
    try:
        data = gen()
    except Exception as e:
        print("   ERROR", repr(e)[:160]); continue
    if not data:
        print("   none returned"); continue
    p = REG / f"s11_ghostgoo2_{k}.png"
    p.write_bytes(data)
    rows.append((f"S11 ghost+goo v2 #{k}", open_book_seam(PIL.Image.open(p))))
    print("   saved", p.name, flush=True)

W2 = 1200
cells = []
for label, ob in rows:
    im = ob.resize((W2, int(W2 * 0.5)), PIL.Image.LANCZOS)
    bar = PIL.Image.new("RGB", (W2, 32), (30, 30, 30))
    ImageDraw.Draw(bar).text((8, 4), label, font=F, fill=(255, 255, 255))
    cell = PIL.Image.new("RGB", (W2, 32 + im.height), (0, 0, 0))
    cell.paste(bar, (0, 0)); cell.paste(im, (0, 32))
    cells.append(cell)
out = PIL.Image.new("RGB", (W2, sum(c.height for c in cells) + 10 * max(1, len(cells) - 1)), (0, 0, 0))
y = 0
for c in cells:
    out.paste(c, (0, y)); y += c.height + 10
out.save(REG / "s11_ghostgoo2_compare.png")
print("   WROTE s11_ghostgoo2_compare.png", flush=True)
print("DONE")
