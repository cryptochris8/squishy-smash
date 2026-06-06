"""Book 2 interior PDF build — shared geometry, fonts, palette.

Distinct from Book 1's book/build/config.py (Book 1 is the 46-page card
catalog). Book 2 is a 40-page picture-book storybook with 18 painterly
facing-pair spreads + front/back matter.

KDP spec:
- Trim: 8.5 x 8.5 in
- Bleed: 0.125 in on all four sides -> page PDF is 8.75 x 8.75 in
- Safety: 0.375 in inside trim (text + key art must stay inside)
- Color paper, perfect-bound
"""
from __future__ import annotations
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]
BOOK_DIR = REPO_ROOT / "book"
COVER_DIR = BOOK_DIR / "cover"
MANUSCRIPT_DIR = BOOK_DIR / "manuscript"
ASSETS_DIR = BOOK_DIR / "assets"

# Spread sources — print resolution (4x), 6336x2688 each (~21:9 facing-pair)
SPREADS_PRINT_DIR = Path(r"C:\Users\chris\Squishy-smash\book2_final_spreads_print")

# Build outputs
OUT_DIR = Path(__file__).resolve().parent / "out"
PAGES_DIR = OUT_DIR / "pages"  # rasterized per-page PNGs (debug + intermediate)
INTERIOR_PDF = OUT_DIR / "interior.pdf"

# ---------------------------------------------------------------------------
# Page geometry (print resolution at 300 DPI)
# ---------------------------------------------------------------------------

DPI = 300

TRIM_IN = 8.5
BLEED_IN = 0.125
SAFETY_IN = 0.375

PAGE_W_IN = TRIM_IN + 2 * BLEED_IN  # 8.75 in
PAGE_H_IN = TRIM_IN + 2 * BLEED_IN  # 8.75 in
PAGE_W_PX = int(PAGE_W_IN * DPI)    # 2625
PAGE_H_PX = int(PAGE_H_IN * DPI)    # 2625
SAFE_INSET_PX = int(SAFETY_IN * DPI)  # 112 px from trim edge
BLEED_PX = int(BLEED_IN * DPI)        # 37 px bleed

# Cover spine math (40-page premium color)
INTERIOR_PAGES = 40
SPINE_PER_PAGE_COLOR = 0.002347
SPINE_W_IN = round(INTERIOR_PAGES * SPINE_PER_PAGE_COLOR, 4)  # 0.0939 in

# ---------------------------------------------------------------------------
# Spread layout — print mapping from 21:9 source to 2-page facing pair
# ---------------------------------------------------------------------------

# Source spread native print size: 6336 x 2688
SPREAD_PRINT_W = 6336
SPREAD_PRINT_H = 2688

# Working spread coord space (what the audit prescribes against)
SPREAD_WORK_W = 1584
SPREAD_WORK_H = 672
SPREAD_WORK_TO_PRINT = SPREAD_PRINT_W / SPREAD_WORK_W  # 4.0

# Print rendering strategy: fit-height-and-crop-outside, no letterbox.
# 1. Scale spread to match facing-pair height (2 x PAGE_H_PX = 5250 ... wait,
#    actually facing pair is 2 pages stacked horizontally, each PAGE_H_PX tall)
# 2. Combined width: 2 * PAGE_W_PX = 5250
# 3. Crop equally from both spread outside edges to fit 5250
#
# Scale factor: PAGE_H_PX / SPREAD_PRINT_H = 2625 / 2688 = 0.9766
SPREAD_FIT_SCALE = PAGE_H_PX / SPREAD_PRINT_H  # 0.9766
SPREAD_FIT_W = int(SPREAD_PRINT_W * SPREAD_FIT_SCALE)  # 6188

FACING_PAIR_W = 2 * PAGE_W_PX  # 5250
OUTSIDE_CROP = (SPREAD_FIT_W - FACING_PAIR_W) // 2  # 469 px cropped from each outside

# Visible source-spread x-range in WORKING coords (the audit's reference frame).
# After crop, only x in [VISIBLE_X_LEFT, VISIBLE_X_RIGHT] is on the printed page.
# Anything in the audit's boxes outside this range gets clipped to safety inset.
VISIBLE_X_LEFT_WORK = int(OUTSIDE_CROP / (SPREAD_FIT_SCALE * SPREAD_WORK_TO_PRINT))   # ~120
VISIBLE_X_RIGHT_WORK = SPREAD_WORK_W - VISIBLE_X_LEFT_WORK                              # ~1464

# Text-safe band per page.
# Outside edge safety inset from trim = 0.375 in (SAFE_INSET_PX = 112 px).
# Bleed + safety from page edge = 37 + 112 = 149 px.
# Inner gutter safety for 40pp perfect-bound = ~0.5 in = 150 px from gutter edge.
GUTTER_SAFETY_PX = 150  # for perfect-bound 40pp picture book interior

VERSO_SAFE_X_PAGE = (BLEED_PX + SAFE_INSET_PX, PAGE_W_PX - GUTTER_SAFETY_PX)  # (149, 2475)
RECTO_SAFE_X_PAGE = (GUTTER_SAFETY_PX, PAGE_W_PX - BLEED_PX - SAFE_INSET_PX)  # (150, 2476)
PAGE_SAFE_Y = (BLEED_PX + SAFE_INSET_PX, PAGE_H_PX - BLEED_PX - SAFE_INSET_PX)  # (149, 2476)

# ---------------------------------------------------------------------------
# Adobe Fonts livetype paths — Bookmania family (verified 2026-05-30)
# ---------------------------------------------------------------------------

LIVETYPE_DIR = Path(r"C:\Users\chris\AppData\Roaming\Adobe\CoreSync\plugins\livetype\w")

FONTS = {
    "body":           LIVETYPE_DIR / "14724",  # Bookmania Regular
    "body_italic":    LIVETYPE_DIR / "14723",  # Bookmania Regular Italic
    "display":        LIVETYPE_DIR / "14717",  # Bookmania Black
    "display_italic": LIVETYPE_DIR / "14715",  # Bookmania Black Italic
    # Volume tag + back-cover headline + byline small caps stay EBG for warmth
    "ebg_italic":     ASSETS_DIR / "fonts" / "EBGaramond-Italic-Variable.ttf",
    "ebg_regular":    ASSETS_DIR / "fonts" / "EBGaramond-Variable.ttf",
}

# Sanity: all font files must exist before any page renders
for role, path in FONTS.items():
    assert path.exists(), f"Missing font: {role} -> {path}"

# ---------------------------------------------------------------------------
# Brand palette (Book 2 storybook line — Knight Owl warm)
# ---------------------------------------------------------------------------

PALETTE = {
    # Cream paper base (interior matter pages + back-cover background)
    "paper":         "#F5E9D0",
    # Deep palette-warm-brown for body type on cream
    "ink":           "#4A2D24",
    # Dusty gold for headers + flourishes
    "gold":          "#E4C46C",
    # Wordmark cream (used on dark sky)
    "cream":         "#F5E9D0",
}

# ---------------------------------------------------------------------------
# Typography sizes (in points; 1pt = DPI/72 px = 4.167 px at 300 DPI)
# ---------------------------------------------------------------------------

PT = DPI / 72.0  # 4.167

# Body type (spreads)
BODY_PT = 18
BODY_LEADING_PT = 26
BODY_PX = int(BODY_PT * PT)              # 75 px font size
BODY_LEADING_PX = int(BODY_LEADING_PT * PT)  # 108 px leading

# Italic chant + display sizes
S10_CHANT_PT = 22
S10_CHANT_LEADING_PT = 28
S12_SHOUT_PT = 28  # for typeset PMF!/SPLOINK!/THUP! sound-effects in body
SQUISHKEEPER_LEADING_PT = 28  # +2pt for S18 italic close

# Front matter (title page)
TITLE_WORDMARK_PT = 90   # smaller than cover wordmark (which is ~140pt-equiv)
TITLE_VOLUME_PT = 40
TITLE_BYLINE_PT = 14

# Copyright + dedication + back matter body
MATTER_BODY_PT = 11
MATTER_BODY_LEADING_PT = 15
MATTER_HEADER_PT = 14
MATTER_HEADER_LEADING_PT = 18
DEDICATION_PT = 16
DEDICATION_LEADING_PT = 22

# ---------------------------------------------------------------------------
# Visible spread bounds re-check (for the build to verify at startup)
# ---------------------------------------------------------------------------

_GUTTER_WORK = SPREAD_WORK_W // 2  # 792


def _work_to_facing_x(work_x: float) -> float:
    """Map a working-coord x to facing-pair coord x (0 to 2*PAGE_W_PX)."""
    return work_x * SPREAD_WORK_TO_PRINT * SPREAD_FIT_SCALE - OUTSIDE_CROP


def visible_work_box_to_page(work_box, page_side):
    """Map an audit box (x, y, w, h) in 1584x672 working coords to a page rect.

    Clamps to:
      - the visible spread region after outside-edge crop
      - the page-side band (verso = left half of facing pair, recto = right half)
      - the page-safe text band (outer SAFE_INSET, inner GUTTER_SAFETY)

    Returns (x, y, w, h) in print page pixels (0..PAGE_W_PX-1), or None if the
    box would entirely disappear after clamping.
    """
    x, y, w, h = work_box
    x_end = x + w

    # 1. Clamp to visible spread (after outside-edge crop)
    x_vis = max(x, VISIBLE_X_LEFT_WORK)
    x_vis_end = min(x_end, VISIBLE_X_RIGHT_WORK)
    if x_vis_end <= x_vis:
        return None

    # 2. Clamp to the requested page side (verso = left of gutter, recto = right)
    if page_side == "verso":
        x_side = max(x_vis, VISIBLE_X_LEFT_WORK)
        x_side_end = min(x_vis_end, _GUTTER_WORK)
        safe_lo, safe_hi = VERSO_SAFE_X_PAGE
    elif page_side == "recto":
        x_side = max(x_vis, _GUTTER_WORK)
        x_side_end = min(x_vis_end, VISIBLE_X_RIGHT_WORK)
        safe_lo, safe_hi = RECTO_SAFE_X_PAGE
    else:
        raise ValueError(f"page_side must be 'verso' or 'recto', got {page_side!r}")

    if x_side_end <= x_side:
        return None

    # 3. Convert to page-pixel x range
    f_start = _work_to_facing_x(x_side)
    f_end = _work_to_facing_x(x_side_end)
    if page_side == "verso":
        page_x_start = max(0, int(f_start))
        page_x_end = min(PAGE_W_PX, int(f_end))
    else:
        page_x_start = max(0, int(f_start - PAGE_W_PX))
        page_x_end = min(PAGE_W_PX, int(f_end - PAGE_W_PX))

    # 4. Apply safety insets (text must stay inside)
    page_x_start = max(page_x_start, safe_lo)
    page_x_end = min(page_x_end, safe_hi)
    if page_x_end <= page_x_start:
        return None

    # 5. Y conversion + safety
    page_y_start = max(int(y * SPREAD_WORK_TO_PRINT * SPREAD_FIT_SCALE), PAGE_SAFE_Y[0])
    page_y_end = min(int((y + h) * SPREAD_WORK_TO_PRINT * SPREAD_FIT_SCALE), PAGE_SAFE_Y[1])
    if page_y_end <= page_y_start:
        return None

    return (page_x_start, page_y_start, page_x_end - page_x_start, page_y_end - page_y_start)
