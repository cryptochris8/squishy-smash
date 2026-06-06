"""Compress interior.pdf for KDP upload.

Re-encodes the 40 source page PNGs as JPEG quality 88, then rebuilds the
PDF. Preserves 300 DPI resolution (well above KDP minimum) and visual
quality while dropping size ~10x.
"""
from __future__ import annotations
import sys, time
from pathlib import Path

from PIL import Image
from reportlab.pdfgen import canvas as rl_canvas
from reportlab.lib.utils import ImageReader

sys.path.insert(0, str(Path(__file__).parent))
from config import PAGE_W_IN, PAGE_H_IN, PAGES_DIR, OUT_DIR

INCH = 72.0
PAGE_W_PT = PAGE_W_IN * INCH
PAGE_H_PT = PAGE_H_IN * INCH
JPEG_QUALITY = 88

JPEG_DIR = OUT_DIR / "pages_jpeg"
COMPRESSED_PDF = OUT_DIR / "interior_compressed.pdf"


def make_jpegs():
    JPEG_DIR.mkdir(parents=True, exist_ok=True)
    out_paths = []
    for i in range(1, 41):
        src = PAGES_DIR / f"page_{i:02d}.png"
        dst = JPEG_DIR / f"page_{i:02d}.jpg"
        if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime:
            img = Image.open(src).convert("RGB")
            img.save(dst, "JPEG", quality=JPEG_QUALITY, optimize=True,
                     dpi=(300, 300))
        out_paths.append(dst)
    return out_paths


def assemble_pdf(jpeg_paths):
    c = rl_canvas.Canvas(str(COMPRESSED_PDF), pagesize=(PAGE_W_PT, PAGE_H_PT))
    c.setTitle("Squishy Smash: The Lost Sparkle")
    c.setAuthor("Christopher Ryan Campbell")
    c.setSubject("A picture-book adventure for ages 4 to 8")
    c.setCreator("Squishy Smash interior build pipeline (compressed)")
    c.setKeywords("squishy smash, picture book, kids, ages 4-8")
    from reportlab.pdfbase.pdfdoc import PDFName
    c._doc.Catalog.PageLayout = PDFName("TwoPageRight")
    for p in jpeg_paths:
        reader = ImageReader(str(p))
        c.drawImage(reader, 0, 0,
                     width=PAGE_W_PT, height=PAGE_H_PT,
                     preserveAspectRatio=False, mask="auto")
        c.showPage()
    c.save()


if __name__ == "__main__":
    t0 = time.time()
    print(">>> Encoding 40 pages to JPEG q88 ...")
    jpegs = make_jpegs()
    total_jpg = sum(p.stat().st_size for p in jpegs) / 1024 / 1024
    print(f"    JPEG total: {total_jpg:.1f} MB in {int(time.time()-t0)}s")
    print(f">>> Assembling -> {COMPRESSED_PDF}")
    assemble_pdf(jpegs)
    size_mb = COMPRESSED_PDF.stat().st_size / 1024 / 1024
    print(f">>> DONE: {COMPRESSED_PDF} ({size_mb:.1f} MB, "
          f"total {int(time.time()-t0)}s)")
