"""Compress cover_wrap.pdf for KDP upload.

Composites the back + spine + front into a single full-bleed PIL image at
300 DPI, saves as JPEG quality 88, then wraps the JPEG in a single-page
PDF. Same approach as compress_interior.py — preserves resolution well
above KDP's 300 DPI minimum while dropping size roughly 10×.
"""
from __future__ import annotations
import sys, time
from pathlib import Path

from PIL import Image
from reportlab.pdfgen import canvas as canvas_mod
from reportlab.lib.utils import ImageReader

sys.path.insert(0, str(Path(__file__).parent))
from build_cover import (
    render_back_cover, FRONT_COMPOSITE, SPINE_PINK, hex_to_rgb,
    BACK_W_PX, BACK_H_PX, BLEED_IN, TRIM_IN, COVER_W_PT, COVER_H_PT,
    INCH,
)
from config import DPI

JPEG_QUALITY = 88
OUT_PDF = Path(__file__).parent / "out" / "cover_wrap_compressed.pdf"
OUT_JPG = Path(__file__).parent / "out" / "_cover_wrap.jpg"


def composite_wrap() -> Image.Image:
    """Render the full wrap as a single PIL image at print resolution."""
    # Back cover image (already 8.625 × 8.75 in at 300 DPI = BACK_W_PX × BACK_H_PX)
    back = render_back_cover()

    # Front cover: 4096×4096 input → crop left bleed → resize to match wrap height
    front = Image.open(FRONT_COMPOSITE).convert("RGB")
    left_bleed_px_src = round(
        BLEED_IN / (TRIM_IN + 2 * BLEED_IN) * front.width
    )
    front = front.crop((left_bleed_px_src, 0, front.width, front.height))
    # Scale front to BACK_H_PX tall (same as wrap height)
    front_w_scaled = int(front.width * BACK_H_PX / front.height)
    front = front.resize((front_w_scaled, BACK_H_PX), Image.LANCZOS)

    # Spine band
    spine_w_px = int(0.0939 * DPI)
    spine = Image.new("RGB", (spine_w_px, BACK_H_PX), hex_to_rgb(SPINE_PINK))

    # Total width = back + spine + front
    total_w = BACK_W_PX + spine.width + front.width
    wrap = Image.new("RGB", (total_w, BACK_H_PX), (16, 16, 24))
    wrap.paste(back, (0, 0))
    wrap.paste(spine, (BACK_W_PX, 0))
    wrap.paste(front, (BACK_W_PX + spine.width, 0))
    return wrap


def build_pdf(wrap: Image.Image, out_path: Path):
    # Save as JPEG first (lossy compression)
    wrap.save(OUT_JPG, "JPEG", quality=JPEG_QUALITY, optimize=True,
                dpi=(DPI, DPI))
    # Wrap the JPEG in a single-page PDF at the cover wrap dimensions
    c = canvas_mod.Canvas(str(out_path), pagesize=(COVER_W_PT, COVER_H_PT))
    c.setTitle("Squishy Smash: The Lost Sparkle — Cover Wrap (compressed)")
    c.setAuthor("Christopher Ryan Campbell")
    c.setSubject("Book 2 paperback cover wrap PDF for KDP")
    c.setCreator("Squishy Smash cover build pipeline (Book 2, compressed)")
    reader = ImageReader(str(OUT_JPG))
    c.drawImage(reader, 0, 0,
                  width=COVER_W_PT, height=COVER_H_PT,
                  preserveAspectRatio=False, mask="auto")
    c.showPage()
    c.save()


if __name__ == "__main__":
    t0 = time.time()
    print(">>> Compositing wrap at print resolution ...")
    wrap = composite_wrap()
    print(f"    {wrap.size}, {int(time.time()-t0)}s")
    print(f">>> Encoding JPEG q{JPEG_QUALITY} -> {OUT_JPG.name}")
    print(f">>> Assembling PDF -> {OUT_PDF.name}")
    build_pdf(wrap, OUT_PDF)
    jpg_mb = OUT_JPG.stat().st_size / 1024 / 1024
    pdf_mb = OUT_PDF.stat().st_size / 1024 / 1024
    print(f">>> DONE: JPEG {jpg_mb:.1f} MB, PDF {pdf_mb:.1f} MB, "
          f"total {int(time.time()-t0)}s")
