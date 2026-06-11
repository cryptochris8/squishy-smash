"""Pack Blender squish frames into a game-ready WebP spritesheet.

Trims the frame stack to its shared content bbox (keeping registration so the
squash stays grounded), resizes to the target cell height, and writes a
horizontal strip plus a JSON sidecar with the frame geometry.

  python pack_squish_sheet.py soft_dumpling [goo_ball ...]

Output: assets/images/anim/<name>_squish.webp + <name>_squish.json
"""

import re
import sys
from pathlib import Path

from PIL import Image

RENDERS = Path(r"C:\Users\chris\Squishy-smash\_tmp_3d_renders")
REPO = Path(__file__).resolve().parents[2]
CARDS = REPO / "assets" / "cards" / "final_48"
OUT = REPO / "assets" / "images" / "anim"
CELL_H = 320
FPS = 30


def card_number_for(name: str):
    """Friend id -> card number via the final_48 filenames; None if unmapped."""
    want = name.replace("_", " ").lower()
    for f in CARDS.glob("*.webp"):
        m = re.match(r"(\d+)_(.+)\.webp", f.name)
        if m and m.group(2).replace("_", " ").lower() == want:
            return int(m.group(1))
    return None


def pack(name: str) -> bool:
    frames_dir = RENDERS / name / "squish"
    paths = sorted(p for p in frames_dir.glob(f"{name}_*.png") if not p.name.startswith("_"))
    if not paths:
        print(f"!! no squish frames for {name}")
        return False

    frames = [Image.open(p).convert("RGBA") for p in paths]

    # union content bbox across all frames so every cell shares registration
    boxes = [f.getbbox() for f in frames if f.getbbox()]
    left = min(b[0] for b in boxes)
    top = min(b[1] for b in boxes)
    right = max(b[2] for b in boxes)
    bottom = max(b[3] for b in boxes)

    cropped = [f.crop((left, top, right, bottom)) for f in frames]
    w, h = cropped[0].size
    cell_w = round(CELL_H * w / h)
    cells = [c.resize((cell_w, CELL_H), Image.LANCZOS) for c in cropped]

    sheet = Image.new("RGBA", (cell_w * len(cells), CELL_H), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        sheet.paste(c, (i * cell_w, 0))

    card_n = card_number_for(name)
    if card_n is None:
        print(f"!! {name}: no card mapping in final_48 — skipping")
        return False

    # Named by card number — SmashableComponent resolves the sheet from
    # the smashable's cardNumber field ("016/048" -> card_016_squish.webp).
    OUT.mkdir(parents=True, exist_ok=True)
    # No JSON sidecar: assets/images/anim/ ships wholesale via pubspec's
    # folder entry, and the runtime needs nothing beyond the fixed 13-cell
    # contract (SmashableComponent._squishFrameCount).
    sheet_path = OUT / f"card_{card_n:03d}_squish.webp"
    sheet.save(sheet_path, "WEBP", quality=90, method=6)
    kb = sheet_path.stat().st_size / 1024
    print(f"OK {sheet_path.name}: {len(cells)} cells {cell_w}x{CELL_H}, {kb:.0f} KB")
    return True


names = sys.argv[1:]
if not names:
    raise SystemExit("usage: pack_squish_sheet.py <friend_id> [...]")
ok = sum(pack(n) for n in names)
print(f"DONE {ok}/{len(names)}")
