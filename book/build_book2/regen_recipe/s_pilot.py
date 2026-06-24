"""PILOT: regenerate S6/S8/S10 (same trio across 3 lands) with the full new
recipe -- canonical character refs + cameo card + pulled-back wide framing +
quiet text zone + quiet gutter + fully-in-frame. Validates consistency before
committing to all 18. 2 candidates each, seam-marked."""
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
CANON = REG / "canon"
CARDS = Path(r"C:\Users\chris\Squishy-smash\squishy_smash\assets\cards\final_48")
dumpling = PIL.Image.open(CANON / "canon_dumpling.png").convert("RGB")
goo = PIL.Image.open(CANON / "canon_goo.png").convert("RGB")
bunny = PIL.Image.open(CANON / "canon_bunny.png").convert("RGB")

STYLE = ("Soft painterly children's picture-book illustration in the warm 'Knight Owl' dusk "
         "style (Christopher Denise): watercolor and gouache, visible brush texture, gentle "
         "storybook lighting. NO text, NO words, NO UI, NO frame, NO border. Wide 21:9 "
         "two-page spread.\n\n")
REFS = ("MATCH THESE CHARACTER REFERENCES EXACTLY -- image 1 = Soft Dumpling (peach dumpling, "
        "single spiral curl tuft on top, small BLACK dot eyes, pink blush, little nub arms, "
        "peg feet, NO ears). image 2 = Goo Ball (glossy BLUE blob, small BLACK dot eyes NOT "
        "green, little nub arms and feet, NO tentacles). image 3 = Blushy Bun (white bunny, "
        "medium-length floppy droopy ears hanging DOWN, pink inner ears, pink nose, pink paw "
        "pads). The 4th image is a cameo character to include small in the background. Every "
        "character MUST look EXACTLY like its reference.\n\n")


def framing(land):
    return (f"FRAMING -- this is a WIDE ESTABLISHING SHOT. Pull the camera far BACK: the three "
            f"friends are SMALL (each only about one-quarter of the image height), set within a "
            f"generous, expansive {land} landscape with lots of open space around them. Show the "
            f"whole world, not a close-up.\n\n")


def comp(land):
    return (f"COMPOSITION for a two-page book spread that folds down the EXACT vertical center: "
            f"cluster the small friends together in the LEFT third; the CENTER and RIGHT are open "
            f"{land} landscape and sky. NOTHING -- no character, face, or limb -- may touch the "
            f"vertical center, and keep ALL characters fully inside the frame, well clear of every "
            f"edge. Leave a calm area of open sky in the UPPER portion as negative space for a "
            f"text caption.\n\n")


JOBS = {
    6: ("Pudding Hills", "011_Sparkle_Mochi.webp",
        "SCENE: the three friends walking together through warm Pudding Hills -- rolling "
        "peach-and-cream sand dunes, a winding syrup river, soft dusk clouds. A small pink "
        "Sparkle Mochi (the 4th reference image) waves in the middle distance off to the right."),
    8: ("Goo Coast", "025_Glitter_Goo_Ball.webp",
        "SCENE: the three friends standing on the glossy Goo Coast shore looking out over a wide "
        "aqua sea with a glossy bubble-tide. A small opal-shimmer Glitter Goo Ball (the 4th "
        "reference image) is out in the water to the right, pointing seaward."),
    10: ("Moonlit Hollow", "041_Star_Eyed_Bunny.webp",
         "SCENE: the three friends walking into a wide violet Moonlit Hollow glade -- silver "
         "mushrooms, a crescent moon, soft stars, gentle moonlight. A small Star-Eyed Bunny (the "
         "4th reference image, a different little bunny with stars in its eyes) sits on a mossy "
         "rock off to the right."),
}
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


def gen(prompt, refs):
    r = client.models.generate_content(model="gemini-3-pro-image-preview",
                                       contents=[prompt, *refs], config=CFG)
    for part in r.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            return part.inline_data.data
    return None


try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 24)
except Exception:
    F = ImageFont.load_default()

for n, (land, card, scene) in JOBS.items():
    cameo = PIL.Image.open(CARDS / card).convert("RGB")
    refs = [dumpling, goo, bunny, cameo]
    prompt = STYLE + REFS + framing(land) + comp(land) + scene
    rows = []
    for k in (1, 2):
        print(f"S{n:02d} pilot candidate {k} ...")
        data = gen(prompt, refs)
        if not data:
            print("   none"); continue
        p = REG / f"pilot_s{n:02d}_{k}.png"
        p.write_bytes(data)
        rows.append((f"S{n:02d} pilot-{k}  ({land}; red line = fold)", open_book_seam(PIL.Image.open(p))))
        print("   saved", p.name)
    W = 1200
    cells = []
    for label, ob in rows:
        im = ob.resize((W, int(W * 0.5)), PIL.Image.LANCZOS)
        bar = PIL.Image.new("RGB", (W, 30), (30, 30, 30))
        ImageDraw.Draw(bar).text((8, 3), label, font=F, fill=(255, 255, 255))
        cell = PIL.Image.new("RGB", (W, 30 + im.height), (0, 0, 0))
        cell.paste(bar, (0, 0)); cell.paste(im, (0, 30))
        cells.append(cell)
    out = PIL.Image.new("RGB", (W, sum(c.height for c in cells) + 10 * max(1, len(cells) - 1)), (0, 0, 0))
    y = 0
    for c in cells:
        out.paste(c, (0, y)); y += c.height + 10
    out.save(REG / f"pilot_s{n:02d}_compare.png")
    print(f"   WROTE pilot_s{n:02d}_compare.png")
print("PILOT DONE")
