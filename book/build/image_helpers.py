"""
Image helpers shared by build_interior.py and build_cover.py.

Cards in assets/cards/final_48/ are 1086 x 1448 px (3:4 portrait). When we
hand a card to ReportLab as-is, the embedded image is far higher resolution
than print needs (300 DPI x ~3 in on the page = ~900 px), and the PDF
balloons to ~180 MB for the interior. Resampling to ~300 DPI before
embedding keeps print quality and produces a sub-50 MB PDF.

Public API:
    fit_box(box_w, box_h, img_w, img_h) -> (draw_w, draw_h)
    prepare_card_image(image_path, target_w_pt, target_h_pt) -> ImageReader
    draw_card(canvas, image_path, x, y, w, h, palette)

`palette` is an optional dict for the placeholder color when an asset is
missing — both builders pass their own copy so this module stays
dependency-free.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader

PRINT_DPI = 300
PT_PER_IN = 72.0


def fit_box(box_w: float, box_h: float,
            img_w: float, img_h: float) -> tuple[float, float]:
    """Return the largest (w, h) that preserves the image's aspect ratio
    and fits inside (box_w, box_h)."""
    box_ratio = box_w / box_h
    img_ratio = img_w / img_h
    if img_ratio >= box_ratio:
        # Image wider than box -> width-limited
        return box_w, box_w / img_ratio
    return box_h * img_ratio, box_h


def prepare_card_image(image_path: Path,
                       target_w_pt: float,
                       target_h_pt: float) -> ImageReader:
    """Load a card image, resample down to print resolution for the target
    draw size, and return an ImageReader."""
    img = Image.open(image_path)
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA")

    target_w_px = int(target_w_pt / PT_PER_IN * PRINT_DPI)
    target_h_px = int(target_h_pt / PT_PER_IN * PRINT_DPI)
    if img.width > target_w_px or img.height > target_h_px:
        img.thumbnail((target_w_px, target_h_px), Image.Resampling.LANCZOS)
    return ImageReader(img)


def draw_card(canvas, image_path: Path,
              x: float, y: float, w: float, h: float,
              missing_fill: str = "#2A1A36",
              missing_text: str = "#FFF6EE") -> None:
    """Draw a card image inside (x, y, w, h), preserving aspect ratio and
    centering. Falls back to a placeholder if the asset is missing so the
    PDF still builds for layout review."""
    if not image_path.exists():
        canvas.setFillColor(HexColor(missing_fill))
        canvas.rect(x, y, w, h, fill=1, stroke=0)
        canvas.setFillColor(HexColor(missing_text))
        try:
            canvas.drawCentredString(x + w / 2, y + h / 2,
                                     f"[missing] {image_path.name}")
        except Exception:
            pass
        return

    with Image.open(image_path) as probe:
        img_w, img_h = probe.size

    draw_w, draw_h = fit_box(w, h, img_w, img_h)
    draw_x = x + (w - draw_w) / 2
    draw_y = y + (h - draw_h) / 2
    reader = prepare_card_image(image_path, draw_w, draw_h)
    canvas.drawImage(reader, draw_x, draw_y, draw_w, draw_h,
                     mask="auto", preserveAspectRatio=True)
