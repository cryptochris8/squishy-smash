"""
Build the 32-page interior PDF for the Squishy Smash KDP character book.

Phase 3 rewrite: each page is rendered as a Pillow Image at 300 DPI
by `page_templates.py`, then stamped onto a ReportLab Canvas page
via drawImage. Hybrid keeps Pillow's alpha / gradient / glow tricks
for visuals while still producing one PDF file per book.

Output: book/build/out/interior.pdf

Usage:
    python -m pip install -r book/build/requirements.txt
    python book/build/build_interior.py

The 32-page sequence is locked by ELEVATION_PLAN.md and the v2
manuscript at book/manuscript/02_manuscript_v2.md. Each entry in
PAGE_ORDER below is a (page_number, render_fn) pair that MUST
align with the Featured-21 selection in config.FEATURED_NUMS.
"""

from __future__ import annotations

import io
import sys
from pathlib import Path

from PIL import Image
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas as canvas_mod

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import OUT_DIR  # noqa: E402
from page_templates import (  # noqa: E402
    PAGE_H,
    PAGE_W,
    T1_title,
    T2_imprint,
    T3_narrator,
    T4_pack_index_left,
    T4_pack_index_right,
    T5_pack_portal,
    T6_pack_scene,
    T8_featured,
    T9_premium_duo,
    T10_mythic_finale,
    T_gallery,
    T_map,
    T_tracker,
)

INTERIOR_PDF = OUT_DIR / "interior.pdf"

# 8.75 x 8.75 in at 72 pt/in for the ReportLab page size
PDF_PAGE_W_PT = 8.75 * 72
PDF_PAGE_H_PT = 8.75 * 72

# 32-page sequence per book/manuscript/02_manuscript_v2.md.
# Each lambda renders ONE page as an RGBA Pillow Image.
PAGE_RENDERERS = [
    # 1-4: Front matter
    (1,  lambda: T1_title()),
    (2,  lambda: T2_imprint()),
    (3,  lambda: T3_narrator()),
    (4,  lambda: T_map()),
    # 5-6: Meet the Three Packs
    (5,  lambda: T4_pack_index_left()),
    (6,  lambda: T4_pack_index_right()),
    # 7-14: Squishy Foods
    (7,  lambda: T5_pack_portal("Squishy Foods", 7)),
    (8,  lambda: T6_pack_scene("Squishy Foods", 8)),
    (9,  lambda: T8_featured(1, 9)),    # Soft Dumpling
    (10, lambda: T8_featured(2, 10)),   # Jelly Bun
    (11, lambda: T8_featured(3, 11)),   # Peach Mochi
    (12, lambda: T8_featured(5, 12)),   # Cream Puff
    (13, lambda: T9_premium_duo(11, 13, 13)),   # Sparkle Mochi + Galaxy Dumpling
    (14, lambda: T10_mythic_finale(16, 14)),     # Celestial Dumpling Core
    # 15-22: Goo & Fidgets
    (15, lambda: T5_pack_portal("Goo & Fidgets", 15)),
    (16, lambda: T6_pack_scene("Goo & Fidgets", 16)),
    (17, lambda: T8_featured(17, 17)),  # Goo Ball
    (18, lambda: T8_featured(19, 18)),  # Stretch Cube
    (19, lambda: T8_featured(18, 19)),  # Bubble Blob
    (20, lambda: T8_featured(20, 20)),  # Soft Stress Orb
    (21, lambda: T9_premium_duo(25, 30, 21)),    # Glitter Goo Ball + Aurora Stretch Cube
    (22, lambda: T10_mythic_finale(32, 22)),     # Singularity Goo Core
    # 23-30: Creepy-Cute Creatures
    (23, lambda: T5_pack_portal("Creepy-Cute Creatures", 23)),
    (24, lambda: T6_pack_scene("Creepy-Cute Creatures", 24)),
    (25, lambda: T8_featured(33, 25)),  # Blushy Bun Bunny
    (26, lambda: T8_featured(35, 26)),  # Puff Ghost
    (27, lambda: T8_featured(34, 27)),  # Squish Bat
    (28, lambda: T8_featured(39, 28)),  # Sleepy Slime Pet
    (29, lambda: T9_premium_duo(41, 43, 29)),    # Star-Eyed Bunny + Glow Ghost Puff
    (30, lambda: T10_mythic_finale(48, 30)),     # Mythic Plush Familiar
    # 31-32: Back matter
    (31, lambda: T_gallery()),
    (32, lambda: T_tracker()),
]


def _stamp_page(c: canvas_mod.Canvas, image: Image.Image) -> None:
    """Convert a Pillow RGBA image to PNG bytes and drawImage it
    full-bleed onto the current ReportLab page. Uses an in-memory
    buffer so we never touch disk for the per-page rasters."""
    if image.size != (PAGE_W, PAGE_H):
        raise ValueError(
            f"page image must be {PAGE_W}x{PAGE_H}, got {image.size}",
        )
    # Flatten alpha onto a white background so the JPEG-friendly
    # RGB output is smaller than the equivalent RGBA PNG. This
    # halves typical page size with no visible quality loss for a
    # full-color picture book.
    rgb = Image.new("RGB", image.size, (18, 11, 23))  # bg #120B17
    rgb.paste(image, mask=image.split()[-1] if image.mode == "RGBA" else None)
    buf = io.BytesIO()
    rgb.save(buf, "JPEG", quality=88, optimize=True)
    buf.seek(0)
    c.drawImage(
        ImageReader(buf), 0, 0,
        PDF_PAGE_W_PT, PDF_PAGE_H_PT,
    )


def build(out_path: Path = INTERIOR_PDF) -> Path:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    c = canvas_mod.Canvas(str(out_path),
                          pagesize=(PDF_PAGE_W_PT, PDF_PAGE_H_PT))
    c.setTitle("Squishy Smash: Meet the Squishies")
    c.setAuthor("Squishy Smash")
    c.setSubject("Character book — KDP paperback, 8.5x8.5 trim")
    for page_num, render_fn in PAGE_RENDERERS:
        img = render_fn()
        _stamp_page(c, img)
        c.showPage()
        print(f"  page {page_num:>2}  done")
    c.save()
    return out_path


if __name__ == "__main__":
    print(f"Rendering {len(PAGE_RENDERERS)} pages "
          f"({PAGE_W}x{PAGE_H} px each) ...")
    pdf = build()
    size_mb = pdf.stat().st_size / 1024 / 1024
    print()
    print(f"Wrote {pdf}")
    print(f"  pages: {len(PAGE_RENDERERS)}")
    print(f"  size:  {size_mb:.1f} MB")
    print(f"  trim:  8.75 x 8.75 in (full bleed)")
