"""Build review_spreads.pdf — each spread rejoined into one wide page.

Layout:
  review_p01: p1 title (centered on a square page)
  review_p02: p2 copyright + p3 dedication (facing pair, wide)
  review_p03: Spread 1 = p4 + p5 (facing pair, wide)
  ...
  review_p20: Spread 18 = p38 + p39 (facing pair, wide)
  review_p21: p40 back matter (centered on a square page)

This file is REVIEW ONLY — not for KDP submission. Use interior.pdf for that.
"""
from __future__ import annotations
import sys
import time
from pathlib import Path

from PIL import Image
from reportlab.pdfgen import canvas as rl_canvas
from reportlab.lib.utils import ImageReader

sys.path.insert(0, str(Path(__file__).parent))
from config import PAGE_W_IN, PAGE_H_IN, PAGES_DIR, OUT_DIR

INCH = 72.0
SQUARE_W_PT = PAGE_W_IN * INCH    # 630 pt
SQUARE_H_PT = PAGE_H_IN * INCH    # 630 pt
WIDE_W_PT = SQUARE_W_PT * 2       # 1260 pt
WIDE_H_PT = SQUARE_H_PT           # 630 pt

REVIEW_PDF = OUT_DIR / "review_spreads.pdf"


def _join_pair(left_path: Path, right_path: Path) -> Image.Image:
    left = Image.open(left_path)
    right = Image.open(right_path)
    if left.size != right.size:
        raise ValueError(f"size mismatch {left.size} vs {right.size}")
    w, h = left.size
    joined = Image.new("RGB", (w * 2, h), (255, 255, 255))
    joined.paste(left, (0, 0))
    joined.paste(right, (w, 0))
    return joined


def build_review():
    t0 = time.time()
    c = rl_canvas.Canvas(str(REVIEW_PDF))
    c.setTitle("Squishy Smash: The Lost Sparkle — Review Spreads")
    c.setAuthor("Christopher Ryan Campbell")
    c.setSubject("Review-only spreads PDF (not for KDP)")

    # 1) p1 title alone — square page
    c.setPageSize((SQUARE_W_PT, SQUARE_H_PT))
    c.drawImage(ImageReader(str(PAGES_DIR / "page_01.png")),
                0, 0, width=SQUARE_W_PT, height=SQUARE_H_PT,
                preserveAspectRatio=False, mask="auto")
    c.showPage()
    print("  p1 title (square)")

    # 2) p2 + p3 facing pair — wide page
    c.setPageSize((WIDE_W_PT, WIDE_H_PT))
    pair = _join_pair(PAGES_DIR / "page_02.png", PAGES_DIR / "page_03.png")
    c.drawImage(ImageReader(pair), 0, 0,
                width=WIDE_W_PT, height=WIDE_H_PT,
                preserveAspectRatio=False, mask="auto")
    c.showPage()
    print("  p2-p3 copyright+dedication (wide)")

    # 3) Spreads 1-18 = pages 4..39 — each verso+recto rejoined on wide page
    for spread_num in range(1, 19):
        verso = PAGES_DIR / f"page_{4 + (spread_num-1)*2:02d}.png"
        recto = PAGES_DIR / f"page_{4 + (spread_num-1)*2 + 1:02d}.png"
        c.setPageSize((WIDE_W_PT, WIDE_H_PT))
        pair = _join_pair(verso, recto)
        c.drawImage(ImageReader(pair), 0, 0,
                    width=WIDE_W_PT, height=WIDE_H_PT,
                    preserveAspectRatio=False, mask="auto")
        c.showPage()
        print(f"  spread {spread_num} = p{4+(spread_num-1)*2}-p{4+(spread_num-1)*2+1} (wide)")

    # 4) p40 back matter alone — square page
    c.setPageSize((SQUARE_W_PT, SQUARE_H_PT))
    c.drawImage(ImageReader(str(PAGES_DIR / "page_40.png")),
                0, 0, width=SQUARE_W_PT, height=SQUARE_H_PT,
                preserveAspectRatio=False, mask="auto")
    c.showPage()
    print("  p40 back matter (square)")

    c.save()
    size_mb = REVIEW_PDF.stat().st_size / 1024 / 1024
    print(f">>> DONE: {REVIEW_PDF} ({size_mb:.1f} MB) in {int(time.time()-t0)}s")


if __name__ == "__main__":
    build_review()
