"""Zoom into the Goo Ball region (original vs arm-raised edit) per spread so the
arm height + any face drift is clearly visible. Side-by-side, labeled."""
from pathlib import Path
import PIL.Image
from PIL import ImageDraw, ImageFont
REG = Path(r"C:\Users\chris\Squishy-smash\_tmp_spine_regen")

# spread: (orig, edited, goo_center_x_frac, goo_center_y_frac)
PAIRS = {
    4: ("full_s04_1.png", "s04_arms.png", 0.21, 0.68),
    5: ("full_s05_1.png", "s05_arms.png", 0.62, 0.58),
    7: ("full_s07_1.png", "s07_arms.png", 0.13, 0.62),
    8: ("full_s08_2.png", "s08_arms.png", 0.16, 0.68),
    10: ("s10fix_1.png", "s10_arms.png", 0.19, 0.62),
    12: ("full_s12_1.png", "s12_arms.png", 0.10, 0.58),
    13: ("full_s13_1.png", "s13_arms.png", 0.22, 0.84),
    14: ("full_s14_1.png", "s14_arms.png", 0.63, 0.64),
    16: ("s16fix_3.png", "s16_arms.png", 0.39, 0.64),
    17: ("full_s17_3.png", "s17_arms.png", 0.42, 0.62),
}
CW = 0.26  # crop width fraction
try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 22)
except Exception:
    F = ImageFont.load_default()


def crop(img, cx, cy):
    W, H = img.size
    cw = int(W * CW); ch = int(cw * 0.95)
    x = max(0, min(W - cw, int(W * cx - cw / 2)))
    y = max(0, min(H - ch, int(H * cy - ch / 2)))
    return img.crop((x, y, x + cw, y + ch))


for n, (o, e, cx, cy) in PAIRS.items():
    oi = PIL.Image.open(REG / o).convert("RGB"); ei = PIL.Image.open(REG / e).convert("RGB")
    oc = crop(oi, cx, cy); ec = crop(ei, cx, cy)
    Z = 520
    oz = oc.resize((Z, int(Z * oc.height / oc.width)), PIL.Image.LANCZOS)
    ez = ec.resize((Z, int(Z * ec.height / ec.width)), PIL.Image.LANCZOS)
    h = max(oz.height, ez.height)
    canvas = PIL.Image.new("RGB", (Z * 2 + 6, h + 30), (0, 0, 0))
    d = ImageDraw.Draw(canvas)
    d.text((6, 4), f"S{n:02d}  ORIGINAL (arms low)", font=F, fill=(255, 220, 120))
    d.text((Z + 12, 4), f"S{n:02d}  ARMS-RAISED", font=F, fill=(150, 255, 150))
    canvas.paste(oz, (0, 30)); canvas.paste(ez, (Z + 6, 30))
    canvas.save(REG / f"goozoom_s{n:02d}.png")
    print("wrote", f"goozoom_s{n:02d}.png")
print("DONE")
