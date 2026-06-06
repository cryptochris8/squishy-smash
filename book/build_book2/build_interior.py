"""Assemble Book 2's 40-page interior PDF.

Page order:
  p1  — Title (recto)
  p2  — Copyright (verso)
  p3  — Dedication (recto)
  p4  — Spread 1 verso
  p5  — Spread 1 recto
  p6  — Spread 2 verso
  ...
  p39 — Spread 18 recto
  p40 — Back matter (verso)

Strategy: rasterize each page at 2625x2625 (300 DPI), drop into a single
ReportLab PDF at 8.75x8.75 in (full-bleed page size).
"""
from __future__ import annotations
import sys
import time
from pathlib import Path

from PIL import Image
from reportlab.pdfgen import canvas as rl_canvas
from reportlab.lib.utils import ImageReader

sys.path.insert(0, str(Path(__file__).parent))
from config import (
    PAGE_W_IN, PAGE_H_IN, PAGE_W_PX, PAGE_H_PX,
    OUT_DIR, PAGES_DIR, INTERIOR_PDF,
)

INCH = 72.0  # PDF unit conversion (1 in = 72 pt)
from spread_overlay import render_spread_page
from front_matter import render_title_page, render_copyright_page, render_dedication_page
from back_matter import render_back_matter_page


def render_all_pages():
    """Render the 40 pages as PNGs into PAGES_DIR. Idempotent — skips existing."""
    PAGES_DIR.mkdir(parents=True, exist_ok=True)
    out = []

    # p1-p3 front matter
    front_matter_renderers = [
        (1, render_title_page),
        (2, render_copyright_page),
        (3, render_dedication_page),
    ]
    for page_num, fn in front_matter_renderers:
        out_path = PAGES_DIR / f"page_{page_num:02d}.png"
        if not out_path.exists():
            print(f"  rendering p{page_num} ({fn.__name__})")
            img = fn()
            img.save(out_path)
        out.append(out_path)

    # p4-p39: 18 spreads × 2 pages
    for spread_num in range(1, 19):
        for side, page_offset in (("verso", 0), ("recto", 1)):
            page_num = 4 + (spread_num - 1) * 2 + page_offset
            out_path = PAGES_DIR / f"page_{page_num:02d}.png"
            if not out_path.exists():
                print(f"  rendering p{page_num} (spread {spread_num} {side})")
                img = render_spread_page(spread_num, side)
                img.save(out_path)
            out.append(out_path)

    # p40 back matter
    out_path = PAGES_DIR / "page_40.png"
    if not out_path.exists():
        print(f"  rendering p40 (back matter)")
        img = render_back_matter_page()
        img.save(out_path)
    out.append(out_path)

    return out


def assemble_pdf(page_paths, pdf_path):
    """Write the 40 PNGs into a single PDF, one page per image at 8.75x8.75 in."""
    page_w_pt = PAGE_W_IN * INCH  # 630 pt
    page_h_pt = PAGE_H_IN * INCH  # 630 pt
    pdf_path.parent.mkdir(parents=True, exist_ok=True)

    c = rl_canvas.Canvas(str(pdf_path), pagesize=(page_w_pt, page_h_pt))
    c.setTitle("Squishy Smash: The Lost Sparkle")
    c.setAuthor("Christopher Ryan Campbell")
    c.setSubject("A picture-book adventure for ages 4 to 8")
    c.setCreator("Squishy Smash interior build pipeline")
    c.setKeywords("squishy smash, picture book, kids, ages 4-8")
    # Open as facing-pair spreads: p1 alone, then p2-p3, p4-p5, etc.
    from reportlab.pdfbase.pdfdoc import PDFName
    c._doc.Catalog.PageLayout = PDFName("TwoPageRight")

    for i, page_path in enumerate(page_paths, start=1):
        with Image.open(page_path) as img:
            # PIL → ReportLab via ImageReader; preserves embedded resolution.
            reader = ImageReader(img)
            c.drawImage(reader, 0, 0,
                          width=page_w_pt, height=page_h_pt,
                          preserveAspectRatio=False, mask="auto")
        c.showPage()

    c.save()
    return pdf_path


if __name__ == "__main__":
    t0 = time.time()
    print(">>> Rendering 40 pages...")
    pages = render_all_pages()
    print(f">>> {len(pages)} pages rendered in {int(time.time()-t0)}s")
    print(f">>> Assembling PDF -> {INTERIOR_PDF}")
    pdf = assemble_pdf(pages, INTERIOR_PDF)
    size_mb = pdf.stat().st_size / 1024 / 1024
    print(f">>> DONE: {pdf} ({size_mb:.1f} MB)")
