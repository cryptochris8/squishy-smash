"""Render the 3 front-matter pages (p1 title recto, p2 copyright verso, p3 dedication recto).

All pages: 2625x2625 on cream paper (#F5E9D0).
Type: deep palette-brown ink (#4A2D24) — inverted from cover (cream-on-indigo).
"""
from __future__ import annotations
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont, ImageFilter

sys.path.insert(0, str(Path(__file__).parent))
from config import (
    PAGE_W_PX, PAGE_H_PX, FONTS, PALETTE, PT,
    BLEED_PX, SAFE_INSET_PX,
    MATTER_BODY_PT, MATTER_BODY_LEADING_PT, DEDICATION_PT, DEDICATION_LEADING_PT,
)
from spread_overlay import hex_to_rgba, draw_runs_in_box, load_fonts


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _new_cream_page() -> Image.Image:
    return Image.new("RGBA", (PAGE_W_PX, PAGE_H_PX),
                      hex_to_rgba(PALETTE["paper"]))


def _draw_painterly_sparkle(canvas, cx, cy, half_size, color_rgb, halo_opacity=0.45):
    """Same 4-point gouache sparkle used on the cover wordmark flanks."""
    r, g, b = color_rgb
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    waist = max(2, half_size // 5)
    d.polygon([(cx, cy - half_size), (cx + waist, cy),
                (cx, cy + half_size), (cx - waist, cy)],
                fill=(r, g, b, 255))
    d.polygon([(cx - half_size, cy), (cx, cy - waist),
                (cx + half_size, cy), (cx, cy + waist)],
                fill=(r, g, b, 255))
    halo = layer.filter(ImageFilter.GaussianBlur(half_size * 0.6))
    halo_a = halo.split()[3].point(lambda v: int(v * halo_opacity))
    halo.putalpha(halo_a)
    return Image.alpha_composite(Image.alpha_composite(canvas, halo), layer)


def _centered_text(canvas, text, font, color_hex, y, tracking_em=0.0):
    """Render text centered horizontally at y_top = y. Returns bottom y."""
    em_size = font.size
    tracking_px = int(em_size * tracking_em)
    widths = [font.getbbox(ch)[2] - font.getbbox(ch)[0] for ch in text]
    total_w = sum(widths) + tracking_px * (len(text) - 1)
    x = (canvas.width - total_w) // 2
    d = ImageDraw.Draw(canvas)
    color = hex_to_rgba(color_hex)
    for i, ch in enumerate(text):
        d.text((x, y), ch, font=font, fill=color)
        x += widths[i] + tracking_px
    bbox = font.getbbox(text)
    return y + (bbox[3] - bbox[1])


# ---------------------------------------------------------------------------
# p1 — Title page (recto)
# ---------------------------------------------------------------------------

def render_title_page() -> Image.Image:
    page = _new_cream_page()
    cx = PAGE_W_PX // 2

    # 1. Small painted sparkle ornament at ~22% from top
    sparkle_y = int(PAGE_H_PX * 0.22)
    sparkle_half = 60
    sparkle_color = (228, 196, 108)  # dusty gold #E4C46C
    page = _draw_painterly_sparkle(page, cx, sparkle_y, sparkle_half,
                                     sparkle_color, halo_opacity=0.50)

    # 2. SQUISHY SMASH wordmark — Bookmania Black, ink color (not cream — we're on cream paper)
    wm_font = ImageFont.truetype(str(FONTS["display"]), int(150 * PT))
    # Find the size that gives a width of ~60% of canvas
    target_w = int(PAGE_W_PX * 0.60)
    lo, hi = 50, 600
    while hi - lo > 2:
        mid = (lo + hi) // 2
        f = ImageFont.truetype(str(FONTS["display"]), mid)
        widths = [f.getbbox(ch)[2] - f.getbbox(ch)[0] for ch in "SQUISHY SMASH"]
        tracking_px = int(mid * -0.02)
        w = sum(widths) + tracking_px * (len("SQUISHY SMASH") - 1)
        if w < target_w:
            lo = mid
        else:
            hi = mid
    wm_font = ImageFont.truetype(str(FONTS["display"]), lo)
    wm_y = int(PAGE_H_PX * 0.32)
    wm_bottom = _centered_text(page, "SQUISHY SMASH", wm_font,
                                PALETTE["ink"], wm_y, tracking_em=-0.02)

    # 3. Volume tag — EB Garamond Italic, dusty gold
    vt_font = ImageFont.truetype(str(FONTS["ebg_italic"]),
                                   int(36 * PT))
    vt_y = wm_bottom + int(20 * PT)
    vt_bottom = _centered_text(page, "The Lost Sparkle", vt_font,
                                PALETTE["gold"], vt_y, tracking_em=0.02)

    # 4. Byline — EB Garamond Caps small, deep ink, letter-spaced
    by_font = ImageFont.truetype(str(FONTS["ebg_regular"]), int(14 * PT))
    by_y = int(PAGE_H_PX * 0.70)
    _centered_text(page, "CHRISTOPHER RYAN CAMPBELL", by_font,
                    PALETTE["ink"], by_y, tracking_em=0.10)

    # 5. Imprint mark — small, near bottom inside safety
    imp_font = ImageFont.truetype(str(FONTS["ebg_regular"]), int(11 * PT))
    imp_y = PAGE_H_PX - BLEED_PX - SAFE_INSET_PX - int(11 * PT) * 2
    _centered_text(page, "ATHLETE DOMAINS, LLC", imp_font,
                    PALETTE["ink"], imp_y, tracking_em=0.10)

    return page


# ---------------------------------------------------------------------------
# p2 — Copyright (verso)
# ---------------------------------------------------------------------------

COPYRIGHT_BLOCKS = [
    ("title_line", "SQUISHY SMASH: The Lost Sparkle"),
    ("series_line", "Book Two in the Squishy Smash series"),
    ("space", None),
    ("copyright", "Copyright © 2026 Christopher Ryan Campbell."),
    ("rights", "All rights reserved."),
    ("space", None),
    ("body",
     "No part of this book may be reproduced or transmitted in any form or "
     "by any means, electronic or mechanical, including photocopying, "
     "recording, or by any information storage and retrieval system, "
     "without written permission from the publisher, except for brief "
     "quotations in a review."),
    ("space", None),
    ("body",
     "This is a work of fiction. All characters, places, and events are "
     "products of the author's imagination."),
    ("space", None),
    ("body", "ISBN: [assigned by KDP at submission]"),
    ("space", None),
    ("body", "First Edition: 2026"),
    ("space", None),
    ("body", "Athlete Domains, LLC"),
    ("body", "squishysmash.com"),
    ("space", None),
    ("body", "Printed in the United States of America."),
]


def render_copyright_page() -> Image.Image:
    page = _new_cream_page()
    body_font = ImageFont.truetype(str(FONTS["body"]),
                                     int(MATTER_BODY_PT * PT))
    italic_font = ImageFont.truetype(str(FONTS["body_italic"]),
                                       int(MATTER_BODY_PT * PT))
    title_font = ImageFont.truetype(str(FONTS["display"]),
                                      int(MATTER_BODY_PT * PT))

    leading_px = int(MATTER_BODY_LEADING_PT * PT)
    para_gap = leading_px // 3

    # Top-left aligned, sitting in the upper-left third (Block 1 typical)
    x = BLEED_PX + SAFE_INSET_PX
    y = BLEED_PX + SAFE_INSET_PX + int(PAGE_H_PX * 0.05)  # slight top inset
    max_w = int(PAGE_W_PX * 0.62)  # ~5.4 inches wide

    d = ImageDraw.Draw(page)
    ink = hex_to_rgba(PALETTE["ink"])

    for kind, text in COPYRIGHT_BLOCKS:
        if kind == "space":
            y += para_gap
            continue
        # Choose font
        f = body_font
        if kind in ("title_line",):
            f = title_font  # Bookmania Black for the title line
        # Word-wrap
        words = text.split()
        line = ""
        for w in words:
            test = (line + " " + w).strip()
            if f.getbbox(test)[2] - f.getbbox(test)[0] <= max_w:
                line = test
            else:
                d.text((x, y), line, font=f, fill=ink)
                y += leading_px
                line = w
        if line:
            d.text((x, y), line, font=f, fill=ink)
            y += leading_px

    return page


# ---------------------------------------------------------------------------
# p3 — Dedication (recto)
# ---------------------------------------------------------------------------

DEDICATION_TEXT_LINES = [
    "For my fiancée and our three daughters —",
    "the comfort, the brave-cuddle,",
    "and all the sparkle.",
    "You are why I went looking.",
]


def render_dedication_page() -> Image.Image:
    page = _new_cream_page()
    f = ImageFont.truetype(str(FONTS["body_italic"]),
                            int(DEDICATION_PT * PT))
    leading_px = int(DEDICATION_LEADING_PT * PT)

    # Vertically center the dedication block. Block top y is offset upward
    # by half the total block height so the block stays roughly centered on
    # y=0.46 regardless of line count.
    total_h = leading_px * (len(DEDICATION_TEXT_LINES) - 1) + int(DEDICATION_PT * PT)
    block_y = int(PAGE_H_PX * 0.46) - total_h // 2
    y = block_y
    for line in DEDICATION_TEXT_LINES:
        _centered_text(page, line, f, PALETTE["ink"], y, tracking_em=0.0)
        y += leading_px

    # Small painted sparkle below the dedication as a soft accent
    sparkle_y = y + int(DEDICATION_LEADING_PT * PT)
    page = _draw_painterly_sparkle(page, PAGE_W_PX // 2, sparkle_y,
                                     half_size=30,
                                     color_rgb=(228, 196, 108),
                                     halo_opacity=0.45)
    return page


# ---------------------------------------------------------------------------
# Smoke test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    out_dir = Path(__file__).parent / "out" / "preview"
    out_dir.mkdir(parents=True, exist_ok=True)
    for n, render_fn in [(1, render_title_page),
                          (2, render_copyright_page),
                          (3, render_dedication_page)]:
        img = render_fn()
        out_path = out_dir / f"matter_p{n:02d}.png"
        img.save(out_path)
        print(f"saved p{n:02d} -> {out_path.name}")
