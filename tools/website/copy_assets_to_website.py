"""Copy generated website_hero assets to the website's public directory
so Vite serves them as static assets at /website_hero/*.png.
"""
import shutil
from pathlib import Path

SQ = Path(r"C:\Users\chris\Squishy-smash\squishy_smash")
SRC = SQ / "assets" / "website_hero"
DST = SQ / "website" / "public" / "website_hero"

DST.mkdir(parents=True, exist_ok=True)

count = 0
for src in sorted(SRC.glob("*.png")):
    shutil.copy2(src, DST / src.name)
    count += 1
    print(f"  -> {src.name}")
print(f"Copied {count} files to {DST}")
