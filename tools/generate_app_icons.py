"""
Resize a single master icon image into every slot iOS + Android need.

Usage:
    python tools/generate_app_icons.py <source.png>

The source should be a square RGB image at least 1024x1024, with NO
alpha channel (iOS App Store rejects transparent icons).

Re-run any time to swap icons — existing files at every target path
are overwritten.
"""

import argparse
import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent

# iOS AppIcon sizes match existing Contents.json entries in
# ios/Runner/Assets.xcassets/AppIcon.appiconset/.
IOS_ICONS = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

ANDROID_ICONS = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192),
]


def flatten_rgba(img: Image.Image) -> Image.Image:
    """iOS rejects transparent icons — flatten any alpha onto white."""
    if img.mode == "RGBA":
        bg = Image.new("RGB", img.size, (255, 255, 255))
        bg.paste(img, mask=img.split()[-1])
        return bg
    return img.convert("RGB")


def resize_square(img: Image.Image, size: int) -> Image.Image:
    if img.size[0] != img.size[1]:
        raise ValueError(
            f"source image must be square; got {img.size}"
        )
    return img.resize((size, size), Image.LANCZOS)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="path to master icon PNG (>=1024 square)")
    args = parser.parse_args()

    src_path = Path(args.source)
    if not src_path.exists():
        print(f"ERROR: source not found: {src_path}")
        sys.exit(1)

    src = Image.open(src_path)
    src = flatten_rgba(src)
    if src.size[0] < 1024:
        print(f"ERROR: source is {src.size}; need >=1024 square")
        sys.exit(1)

    ios_dir = REPO_ROOT / "ios" / "Runner" / "Assets.xcassets" / \
        "AppIcon.appiconset"
    print(f"iOS -> {ios_dir}")
    for name, size in IOS_ICONS:
        out = ios_dir / name
        resized = resize_square(src, size)
        resized.save(out, format="PNG", optimize=True)
        print(f"  {name}  {size}x{size}  "
              f"{out.stat().st_size // 1024} KB")

    android_res = REPO_ROOT / "android" / "app" / "src" / "main" / "res"
    print(f"\nAndroid -> {android_res}")
    for bucket, size in ANDROID_ICONS:
        out = android_res / bucket / "ic_launcher.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        resized = resize_square(src, size)
        resized.save(out, format="PNG", optimize=True)
        print(f"  {bucket}/ic_launcher.png  {size}x{size}  "
              f"{out.stat().st_size // 1024} KB")

    print("\nDone.")


if __name__ == "__main__":
    main()
