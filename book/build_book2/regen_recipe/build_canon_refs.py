"""Build the canonical character reference set by cropping the protagonists from
clean PRINTED originals (S4 = Soft Dumpling + Goo Ball black eyes; S10 = Blushy
Bun medium ears). These lock the characters on every regen going forward."""
from pathlib import Path
import PIL.Image
from PIL import ImageDraw, ImageFont

SRC = Path(r"C:\Users\chris\Squishy-smash\book2_final_spreads_print")
OUT = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen\canon")
OUT.mkdir(parents=True, exist_ok=True)
s4 = PIL.Image.open(SRC / "spread_04.png").convert("RGB")
s10 = PIL.Image.open(SRC / "spread_10.png").convert("RGB")

crops = {
    "canon_dumpling": s4.crop((2000, 650, 3150, 2150)),   # Soft Dumpling, peach, curl tuft, black eyes
    "canon_goo": s4.crop((3450, 650, 4550, 2150)),         # Goo Ball, blue, small BLACK eyes
    "canon_bunny": s10.crop((4150, 400, 5550, 2400)),      # Blushy Bun, white, medium floppy ears
}
for name, im in crops.items():
    im.save(OUT / f"{name}.png")
    print(f"saved {name}.png {im.size}")

# contact sheet to verify the crops
try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 20)
except Exception:
    F = ImageFont.load_default()
W = 400
thumbs = []
for name, im in crops.items():
    t = im.copy(); t.thumbnail((W, W))
    cell = PIL.Image.new("RGB", (W, t.height + 28), (20, 20, 20))
    cell.paste(t, ((W - t.width) // 2, 2))
    ImageDraw.Draw(cell).text((6, t.height + 5), name, font=F, fill=(240, 240, 240))
    thumbs.append(cell)
H = max(t.height for t in thumbs)
sheet = PIL.Image.new("RGB", (W * 3 + 16, H), (8, 8, 8))
x = 4
for t in thumbs:
    sheet.paste(t, (x, 0)); x += W + 4
sheet.save(OUT / "canon_refs_sheet.png")
print("WROTE canon_refs_sheet.png")
