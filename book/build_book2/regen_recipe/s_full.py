"""FULL RE-RENDER of Book 2 interior spreads with the validated recipe:
canonical character refs + S10 trio anchor + pulled-back framing + seam-safe
composition + manuscript-accurate scenes + per-spread cameo/Epic map.

Usage:  python s_full.py 3 12 13 18      # run just these spreads
        python s_full.py all             # run every spread in SPREADS

Per spread: N candidates (default 2), each saved as full_sNN_k.png, plus a
seam-marked compare sheet full_sNN_compare.png. S10 is REUSED from the pilot
(it is the named character target) -- not in this script's run set by default.
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
CANON = REG / "canon"
CARDS = Path(r"C:\Users\chris\Squishy-smash\squishy_smash\assets\cards\final_48")

dumpling = PIL.Image.open(CANON / "canon_dumpling.png").convert("RGB")
goo = PIL.Image.open(CANON / "canon_goo.png").convert("RGB")
bunny = PIL.Image.open(CANON / "canon_bunny.png").convert("RGB")
trio = PIL.Image.open(CANON / "canon_trio_s10.png").convert("RGB")

STYLE = ("Soft painterly children's picture-book illustration in the warm 'Knight Owl' dusk "
         "style (Christopher Denise): watercolor and gouache, visible brush texture, gentle "
         "storybook lighting. Absolutely NO text, NO words, NO letters, NO captions, NO writing "
         "anywhere in the image, NO UI, NO frame, NO border. Wide 21:9 two-page spread.\n\n")

D = ("image 1 = Soft Dumpling (peach teardrop dumpling, one single spiral curl tuft on top, "
     "small BLACK dot eyes, pink blush, little nub arms, peg feet, NO ears).")
G = ("image 2 = Goo Ball (glossy BLUE round blob, small BLACK dot eyes NOT green, little nub "
     "arms and feet, NO tentacles).")
B = ("image 3 = Blushy Bun (white bunny, medium-length floppy droopy ears hanging DOWN, pink "
     "inner ears, pink nose, pink paw pads).")
T = ("image 4 shows all three friends TOGETHER -- match this exact trio for their shared look, "
     "soft plush proportions, painterly rendering, and small BLACK dot eyes; do NOT copy their pose.")


def char_refs(chars):
    if chars == "trio":
        return [dumpling, goo, bunny, trio], "MATCH THESE CHARACTER REFERENCES EXACTLY -- " + " ".join([D, G, B, T])
    if chars == "sd_goo":
        return [dumpling, goo], ("MATCH THESE CHARACTER REFERENCES EXACTLY -- " + " ".join([D, G]) +
                                 " This scene has ONLY these two characters -- NO bunny, no other creatures.")
    if chars == "sd":
        return [dumpling], ("MATCH THIS CHARACTER REFERENCE EXACTLY -- " + D +
                            " This scene has ONLY Soft Dumpling -- no other characters.")
    raise ValueError(chars)


def framing(kind, land):
    if kind == "wide":
        return (f"FRAMING -- this is a WIDE ESTABLISHING SHOT. Pull the camera far BACK: the "
                f"friends are SMALL (each only about one-quarter of the image height), set within a "
                f"generous, expansive {land} landscape with lots of open space around them. Show the "
                f"whole world, not a close-up.\n\n")
    if kind == "closer":
        return (f"FRAMING -- a medium shot in {land}, pulled back enough to show the setting around "
                f"them, but the friends are a bit larger (about one-third of the image height) for an "
                f"intimate, emotional moment. Still keep generous open space around them.\n\n")
    if kind == "panorama":
        return (f"FRAMING -- a WIDE PANORAMA that sweeps across {land} from left to right. The "
                f"friends are SMALL (about one-quarter of the image height) and set apart from one "
                f"another across the scene. Show lots of open landscape and sky.\n\n")
    raise ValueError(kind)


def comp(kind, land, side):
    base = "COMPOSITION for a two-page book spread that folds down the EXACT vertical center: "
    tail = ("Keep ALL characters fully inside the frame, well clear of every edge, and leave a calm "
            "area of open sky as negative space for a text caption.\n\n")
    if kind == "side":
        s = "the LEFT third" if side == "L" else "the RIGHT third"
        o = "RIGHT" if side == "L" else "LEFT"
        return (base + f"cluster the small friends together in {s}; the CENTER and the {o} side are "
                f"open {land} landscape and sky. NOTHING -- no character, face, or limb -- may touch "
                f"the vertical center. " + tail)
    if kind == "panorama":
        return (base + "place the friends spread ACROSS the scene but arranged so the EXACT vertical "
                "center is OPEN space (sky or land) BETWEEN two of them -- NOTHING may touch the "
                "centerline. Render all three friends at roughly the SAME small size, and keep each "
                "one set IN from the left and right edges (not near the outer trim). " + tail)
    if kind == "cores":
        return (base + "the three small friends stand together LOW and toward the LEFT; high above, "
                "three ENORMOUS glowing cosmic Cores are arranged across the upper sky -- but NONE of "
                "the three Cores, and no friend, may sit on or touch the EXACT vertical center; keep "
                "the centerline OPEN, glowing sky between two Cores. " + tail)
    raise ValueError(kind)


# Each spread: land, chars, cameo (list of card filenames), framing, comp, side, scene, n(optional)
SPREADS = {
    3: dict(land="three different lands", chars="trio", cameo=[], framing="panorama", comp="panorama", side=None,
            scene=("SCENE: a sweeping panorama of THREE lands blended left to right -- warm peach-and-cream "
                   "PUDDING HILLS on the left, glossy teal GOO COAST in the center-left, violet star-lit "
                   "MOONLIT HOLLOW on the right. In Pudding Hills (left) a small Soft Dumpling looks UP. In "
                   "Goo Coast (center-left, clearly LEFT of the fold) a small Goo Ball looks UP. In Moonlit "
                   "Hollow (right) a small white Blushy Bun looks UP. Each gazes toward a tiny drifting shard "
                   "of light high in the sky. The exact center of the spread is open twilight sky.")),
    4: dict(land="the border of Pudding Hills and Goo Coast", chars="sd_goo", cameo=[], framing="wide", comp="side", side="L",
            scene=("SCENE: Soft Dumpling reaches the edge of the peach Pudding Hills, where the grass turns "
                   "greener and glossier toward Goo Coast and a thin syrup river trickles between. Just across "
                   "the gentle boundary, glossy blue Goo Ball is waiting to say hello. The two stand near each "
                   "other on the left, the open boundary landscape and sky stretching to the right.")),
    5: dict(land="the soft boundary between Pudding Hills and Goo Coast", chars="trio", cameo=[], framing="wide", comp="side", side="R",
            scene=("SCENE: the white floppy-eared Blushy Bun has just hopped out from between the two worlds to "
                   "join Soft Dumpling and Goo Ball. The three friends -- three different feelings -- gently begin "
                   "walking together for the first time across the soft boundary, in warm dusk light.")),
    6: dict(land="Pudding Hills", chars="trio", cameo=["011_Sparkle_Mochi.webp"], framing="wide", comp="side", side="L",
            scene=("SCENE: the three friends walk together through warm Pudding Hills -- rolling peach-and-cream "
                   "cream-bowl dunes, a winding syrup river, soft dusk clouds. ATMOSPHERIC BACKGROUND CAMEO "
                   "(small, NOT a co-star): in the right-of-center middle distance (set well IN from the right "
                   "edge), a small pink Sparkle Mochi (the 5th reference image, rendered SMALL, about one-sixth "
                   "the friends' size) waves one shimmery wave and points toward a distant orchard.")),
    7: dict(land="the orchard edge of Pudding Hills", chars="trio", cameo=["013_Galaxy_Dumpling.webp"], framing="wide", comp="side", side="L", n=3,
            scene=("SCENE: a half-glowing shard of light rests in a hush at the orchard's edge. EPIC SKY PRESENCE: "
                   "high above, OFF the vertical center, looms an ENORMOUS gentle dumpling the size of the sky "
                   "(the 5th reference image: a deep galaxy-purple dumpling full of small quiet stars), serene and "
                   "glowing. The three small friends stand together below on the left, gazing up.")),
    8: dict(land="Goo Coast", chars="trio", cameo=["025_Glitter_Goo_Ball.webp"], framing="wide", comp="side", side="L",
            scene=("SCENE: the three friends stand on the glossy Goo Coast shore on the left, looking out over a wide "
                   "aqua sea with a glossy bubble-tide. ATMOSPHERIC BACKGROUND CAMEO (small, NOT a co-star): out in "
                   "the water in the right-of-center middle distance (set well IN from the right edge), a small "
                   "opal-shimmer Glitter Goo Ball (the 5th reference image, rendered SMALL, about one-sixth the "
                   "friends' size) points seaward.")),
    9: dict(land="the glossy Goo Coast sea", chars="trio", cameo=["030_Aurora_Stretch_Cube.webp"], framing="wide", comp="side", side="R", n=3,
            scene=("SCENE: the three friends BOUNCE high together, mid-jump, clustered toward the RIGHT (kept well "
                   "clear of the right edge), reaching up for a glossy shard of light that rises above the goo-water. "
                   "EPIC PRESENCE: FAR to the LEFT, deep in the glossy water, a large gentle cube the color of dawn "
                   "(the 5th reference image: an aurora-hued stretchy cube with a calm face) watches and lets the "
                   "shard go. Keep the EXACT vertical center as open water and sky -- nothing on the centerline.")),
    11: dict(land="the deepest, darkest grove of Moonlit Hollow", chars="trio", cameo=["043_Glow_Ghost_Puff.webp"], framing="closer", comp="side", side="R", n=3,
             scene=("SCENE: the deepest grove, darker than dark. A tiny third shard waits, almost flickered out. "
                    "EPIC PRESENCE: in the UPPER LEFT, OFF the vertical center, a large soft glowing ghost-puff "
                    "(the 5th reference image: a friendly gentle haunting, a glowing puff) looms quietly and says "
                    "nothing. The three friends stand very still and small, lower and to the RIGHT, holding the "
                    "faint shard between them.")),
    12: dict(land="the deepest grove, now bursting with light", chars="trio", cameo=[], framing="closer", comp="side", side="L",
             scene=("SCENE: the climax -- the three friends squeeze together in a tight three-way group HUG on the "
                    "LEFT, eyes happy, mid-squish. From their hug a radiant warm sunburst of light blooms outward "
                    "across the CENTER and RIGHT of the spread, turning the dark grove bright. Joyful and tender.")),
    13: dict(land="the grove, suddenly not dark", chars="trio", cameo=["016_Celestial_Dumpling_Core.webp", "032_Singularity_Goo_Core.webp", "048_Mythic_Plush_Familiar.webp"],
             framing="wide", comp="cores", side="L", n=3,
             scene=("SCENE: three shards of light rise, glossy and warm, and touch above the friends. Three ENORMOUS, "
                    "slow, glowing cosmic Cores arrive high in the sky and bow to the trio: the Celestial Dumpling "
                    "Core (5th reference image: a radiant golden-cream dumpling ringed with golden Saturn-like halos "
                    "of starlight), the Singularity Goo Core (6th reference image: a deep purple galaxy-spiral "
                    "singularity), and the Mythic Plush Familiar (7th reference image: a CREAM-WHITE winged fox-eared "
                    "plush with a golden halo and a flowing purple cape). Each Core is sky-sized. The three small "
                    "friends -- peach Soft Dumpling with her spiral curl, blue Goo Ball, and the white floppy-eared "
                    "Blushy Bun -- stand together low on the left, gazing up in wonder.")),
    14: dict(land="the open twilight sky over the grove", chars="trio", cameo=[], framing="wide", comp="side", side="R",
             scene=("SCENE: the Sparkle has returned -- bigger, warmer, brighter than ever, a radiant star glowing "
                    "in the open sky, positioned OFF the vertical center. The three small friends are gathered "
                    "together on the RIGHT, gazing up at it, lit by its warm glow.")),
    15: dict(land="three lands at dusk", chars="trio", cameo=[], framing="panorama", comp="panorama", side=None,
             scene=("SCENE: a panorama of going home, left to right. On the LEFT, Soft Dumpling carries a little "
                    "glowing bit of light home into the peach Pudding Hills. In the CENTER-LEFT (LEFT of the fold), "
                    "Goo Ball carries light home into the teal Goo Coast. On the RIGHT, Blushy Bun carries light home "
                    "into the violet Moonlit Hollow. Each small, walking away into their own land. Center is open sky.")),
    16: dict(land="three home-lands welcoming them back", chars="trio", cameo=[], framing="panorama", comp="panorama", side=None,
             scene=("SCENE: a panorama of three homecomings, left to right -- the peach Pudding Hills welcoming Soft "
                    "Dumpling home on the LEFT, the teal Goo Coast welcoming Goo Ball home in the center-left (LEFT of "
                    "the fold), the violet Moonlit Hollow welcoming Blushy Bun home on the RIGHT. Each land glows a "
                    "little brighter as its friend returns. Each friend small in their own land; center is open sky.")),
    17: dict(land="three lands that now visit each other", chars="trio", cameo=[], framing="panorama", comp="panorama", side=None,
             scene=("SCENE: the three lands now touch and visit, blended left to right. Soft Dumpling (peach) is over "
                    "in the teal Goo Coast; Goo Ball (blue) rests in the violet Moonlit Hollow quiet; Blushy Bun "
                    "(white) is up in the peach Pudding Hills teaching it to hop. The friends are small, scattered "
                    "across each other's lands in a warm, peaceful panorama. The exact center is open landscape.")),
    18: dict(land="Pudding Hills at night", chars="sd", cameo=[], framing="closer", comp="side", side="L",
             scene=("SCENE: a quiet, intimate nighttime close. Soft Dumpling sleeps peacefully, curled up on the LEFT, "
                    "in the soft Pudding Hills under a gentle night sky. High in the open sky to the RIGHT, OFF the "
                    "vertical center, the warm Sparkle glows small and watchful. Calm, tender, full of soft night space.")),
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


def run_spread(n):
    sp = SPREADS[n]
    cr, ctext = char_refs(sp["chars"])
    cameo_imgs = [PIL.Image.open(CARDS / c).convert("RGB") for c in sp["cameo"]]
    refs = cr + cameo_imgs
    cameo_clause = ""
    if cameo_imgs:
        idxs = list(range(len(cr) + 1, len(cr) + 1 + len(cameo_imgs)))
        if len(idxs) == 1:
            cameo_clause = f" Image {idxs[0]} is a cameo character to render exactly as described in the scene."
        else:
            cameo_clause = (f" Images {', '.join(map(str, idxs))} are cameo characters (the giant Cores) "
                            f"to render exactly as described in the scene.")
    REFS = ctext + cameo_clause + " Every character MUST look EXACTLY like its reference.\n\n"
    prompt = (STYLE + REFS + framing(sp["framing"], sp["land"]) +
              comp(sp["comp"], sp["land"], sp["side"]) + sp["scene"])
    N = sp.get("n", 2)
    rows = []
    for k in range(1, N + 1):
        print(f"S{n:02d} candidate {k}/{N} ...", flush=True)
        try:
            data = gen(prompt, refs)
        except Exception as e:
            print("   ERROR", repr(e)[:160]); continue
        if not data:
            print("   none returned"); continue
        p = REG / f"full_s{n:02d}_{k}.png"
        p.write_bytes(data)
        rows.append((f"S{n:02d}-{k}  ({sp['land']}; red line = fold)", open_book_seam(PIL.Image.open(p))))
        print("   saved", p.name, flush=True)
    if not rows:
        print(f"S{n:02d}: NO candidates"); return
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
    out.save(REG / f"full_s{n:02d}_compare.png")
    print(f"   WROTE full_s{n:02d}_compare.png", flush=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["all"]:
        todo = sorted(SPREADS)
    else:
        todo = [int(a) for a in args]
    print("RUNNING spreads:", todo, flush=True)
    for n in todo:
        run_spread(n)
    print("ALL DONE")
