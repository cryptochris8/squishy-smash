"""S11 (pages 24-25, Moonlit grove) targeted fix -- TWO changes, everything else
identical (our no-drift rule):
  1) The floating ghost drifted to a warm-gold simplified puff; redraw it to
     match the ORIGINAL Glow Ghost Puff (card 043) -- cool white/lavender glow,
     BIG sparkly friendly eyes, pink blush, gentle smile, little nub arms, wispy
     tail -- in the book's soft watercolour style. Reference = the v1 book ghost
     (cropped from the original spread, already on-style + on-card).
  2) The blue Goo Ball has too many hands/arms; give it exactly TWO small nub
     arms (+ its little peg feet), still gently holding the tiny shard.

Base = current pick full_s11_1.png. 3 candidates + seam-marked compare sheet.
Usage: python s11_ghost_goo_fix.py
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
BACKUP = Path(r"C:\Users\chris\Squishy-smash\book2_final_spreads_print\_orig_centered_backup\spread_11.png")
N = 3

# --- crop the v1 ghost as the style/identity reference -----------------------
_v1 = PIL.Image.open(BACKUP).convert("RGB"); W, H = _v1.size
ghost_ref = _v1.crop((int(0.42 * W), 0, int(0.64 * W), int(0.70 * H)))
ghost_ref.save(REG / "ghost_ref_v1.png")

base = PIL.Image.open(REG / "full_s11_1.png").convert("RGB")

PROMPT = (
    "IMAGE 1 is a finished soft painterly children's picture-book spread (watercolor and "
    "gouache): a dark Moonlit-Hollow grove at night, a glowing ghost floating in the upper "
    "left, and three friends on the right -- peach Soft Dumpling, blue Goo Ball, white "
    "floppy-eared Blushy Bun.\n\n"
    "REPRODUCE IMAGE 1 EXACTLY -- the same grove, trees, mushrooms, moss, stars, sky, "
    "lighting, brushwork, the same Soft Dumpling and Blushy Bun (faces, poses, positions) and "
    "the same two-page layout with the calm open center kept open. Make ONLY the two changes "
    "below.\n\n"
    "IMAGE 2 is the reference for the ghost's correct look (use it ONLY for the ghost).\n\n"
    "CHANGE 1 -- THE GHOST: it currently glows WARM GOLD with a tiny simple face. Redraw the "
    "floating ghost to match IMAGE 2: a soft COOL WHITE-AND-LAVENDER glowing ghost with BIG "
    "round sparkly friendly eyes, pink cheek blush, a gentle happy smile, two little nub arms "
    "and a soft wispy tail -- the same cute ghost, in the book's soft watercolour style, "
    "glowing gentle moonlit white-lavender (NOT warm gold). Keep it in the SAME position and "
    "size in the upper left.\n\n"
    "CHANGE 2 -- THE GOO BALL: the little blue Goo Ball currently has too many small "
    "hands/arms bunched together, which looks wrong. Give it exactly TWO small nub arms (one on "
    "each side) plus its two little peg feet, and remove any extra hands or nubs. It may still "
    "gently hold the tiny shard with one nub hand. Keep the Goo Ball the same size, round blue "
    "shape, small BLACK dot eyes and gentle smile, in the same spot.\n\n"
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
                                       contents=[PROMPT, base, ghost_ref], config=CFG)
    for part in r.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            return part.inline_data.data
    return None


try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 26)
except Exception:
    F = ImageFont.load_default()

rows = [("S11 ORIGINAL (warm-gold ghost; goo extra hands) -- red line = fold", open_book_seam(base))]
for k in range(1, N + 1):
    print(f"S11 ghost+goo fix candidate {k}/{N} ...", flush=True)
    try:
        data = gen()
    except Exception as e:
        print("   ERROR", repr(e)[:160]); continue
    if not data:
        print("   none returned"); continue
    p = REG / f"s11_ghostgoo_{k}.png"
    p.write_bytes(data)
    rows.append((f"S11 ghost+goo fix {k}", open_book_seam(PIL.Image.open(p))))
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
out.save(REG / "s11_ghostgoo_compare.png")
print("   WROTE s11_ghostgoo_compare.png", flush=True)
print("DONE")
