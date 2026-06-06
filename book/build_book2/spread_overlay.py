"""Render a single spread page (verso or recto) as a 2625x2625 PIL image.

Pipeline for one page:
  1. Open print-res spread (6336x2688), scale to fit page height (factor 0.9766),
     crop equally from outside edges to fit 2x page width (5250 px).
  2. Slice the verso half (left 2625) or recto half (right 2625) — that's the
     painterly background.
  3. Per the per-spread layout brief: choose technique + paint wash panel (if b),
     typeset prose in Bookmania Regular/Italic at sampled palette-brown,
     handle the chant trailing run, the Pact line, the Squishkeeper close.
  4. Return the 2625x2625 RGBA composite.
"""
from __future__ import annotations
import sys
from pathlib import Path
from typing import Optional

from PIL import Image, ImageDraw, ImageFont, ImageFilter

sys.path.insert(0, str(Path(__file__).parent))
from config import (
    PAGE_W_PX, PAGE_H_PX, FONTS, PALETTE, BODY_PT, BODY_LEADING_PT, PT,
    SPREADS_PRINT_DIR, SPREAD_FIT_SCALE, OUTSIDE_CROP,
    visible_work_box_to_page,
)
import layout_brief as LB
import manuscript as MS


def hex_to_rgba(hexstr: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = hexstr.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def make_full_bleed_page(spread_img: Image.Image, page_side: str) -> Image.Image:
    """Scale + crop spread to fit one page, full-bleed."""
    # 1. Fit-height scale
    sw, sh = spread_img.size
    new_w = int(sw * SPREAD_FIT_SCALE)
    new_h = PAGE_H_PX
    scaled = spread_img.resize((new_w, new_h), Image.LANCZOS)

    # 2. Crop to facing-pair width (2 * PAGE_W_PX), centered
    crop_left = OUTSIDE_CROP
    crop_right = crop_left + 2 * PAGE_W_PX
    facing = scaled.crop((crop_left, 0, crop_right, PAGE_H_PX))

    # 3. Slice verso or recto half
    if page_side == "verso":
        page = facing.crop((0, 0, PAGE_W_PX, PAGE_H_PX))
    elif page_side == "recto":
        page = facing.crop((PAGE_W_PX, 0, 2 * PAGE_W_PX, PAGE_H_PX))
    else:
        raise ValueError(f"page_side must be 'verso' or 'recto', got {page_side!r}")
    return page.convert("RGBA")


def draw_wash_panel(canvas: Image.Image, box, color_hex, opacity, feather_px=27):
    """Feathered scumbled wash panel under the text area.

    box: (x, y, w, h) in page pixels. The wash itself extends ~feather_px
    beyond all sides so the soft edge falls inside the intended area.
    """
    x, y, w, h = box
    pad = feather_px * 2

    # Build wash at solid alpha, then blur, then composite
    wash = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    inner = Image.new("RGBA", (w, h), hex_to_rgba(color_hex, int(opacity * 255)))
    wash.paste(inner, (pad, pad))

    # Gaussian-blur for the feathered edge
    wash = wash.filter(ImageFilter.GaussianBlur(feather_px))

    # Composite onto canvas at (x-pad, y-pad)
    paste_pos = (x - pad, y - pad)
    canvas.alpha_composite(wash, paste_pos)


def _tokenize_runs(runs):
    """Flatten runs into a word list. Each token is (word, italic_bool).
    Whitespace inside runs becomes inter-word spaces.
    """
    tokens = []
    for text, italic in runs:
        for word in text.split(" "):
            if word:  # skip empty (handles consecutive spaces gracefully)
                tokens.append((word, italic))
    return tokens


# Punctuation that should attach to the preceding word with no leading space.
# Handles the italic-run boundary case where a manuscript run begins with ","
# or "." (the typical case after an italic word, e.g. ("Sploink", True) + (", said", False)).
_NO_LEAD_SPACE = set(".,;:!?)]}\"'»")


def _is_punct_attach(word: str) -> bool:
    return bool(word) and word[0] in _NO_LEAD_SPACE


def draw_runs_in_box(canvas: Image.Image, runs, fonts, box, color_hex,
                     leading_px=None, word_space_factor=1.12):
    """Draw a sequence of (text, italic) runs into a box with ragged-right wrapping.

    fonts: dict with 'regular' and 'italic' ImageFont objects.
    color_hex: text color (the wash + paper backdrop is handled separately).
    leading_px: line height; default = font.size + 12% extra.
    word_space_factor: multiplies the default space width (1.12 = slightly looser).
    Returns the bottom y of the painted text (for trailing-block stacking).
    """
    x_box, y_box, w_box, h_box = box
    draw = ImageDraw.Draw(canvas)
    color_rgba = hex_to_rgba(color_hex)
    f_reg = fonts["regular"]
    f_ital = fonts["italic"]

    if leading_px is None:
        leading_px = int(f_reg.size * 1.45)  # approx 1.45 line-height

    # Tokenize
    tokens = _tokenize_runs(runs)
    if not tokens:
        return y_box

    space_w_reg = int((f_reg.getbbox(" ")[2] - f_reg.getbbox(" ")[0]) * word_space_factor)
    space_w_ital = int((f_ital.getbbox(" ")[2] - f_ital.getbbox(" ")[0]) * word_space_factor)

    def word_w(word, italic):
        f = f_ital if italic else f_reg
        b = f.getbbox(word)
        return b[2] - b[0]

    # Greedy line wrap.
    # Each line element is (word, italic, ww, leading_space) where leading_space
    # is the px to skip BEFORE drawing this word (0 for line-leading or
    # punctuation-attached words).
    cursor_y = y_box
    line: list[tuple[str, bool, int, int]] = []
    line_w = 0

    def flush_line(y):
        cx = x_box
        for word, italic, ww, leading_space in line:
            cx += leading_space
            f = f_ital if italic else f_reg
            draw.text((cx, y), word, font=f, fill=color_rgba)
            cx += ww

    for word, italic in tokens:
        ww = word_w(word, italic)
        if line:
            # Compute leading space for this word relative to its predecessor
            if _is_punct_attach(word):
                leading_space = 0
            else:
                leading_space = space_w_ital if italic else space_w_reg
        else:
            leading_space = 0
        added = leading_space + ww
        if line_w + added <= w_box:
            line.append((word, italic, ww, leading_space))
            line_w += added
        else:
            flush_line(cursor_y)
            cursor_y += leading_px
            line = [(word, italic, ww, 0)]  # first word on new line gets no leading
            line_w = ww

    if line:
        flush_line(cursor_y)
        cursor_y += leading_px

    return cursor_y


def load_fonts(body_pt=BODY_PT, italic_pt=None, display_italic_pt=None):
    """Return a dict of PIL.ImageFont instances at the requested sizes."""
    if italic_pt is None:
        italic_pt = body_pt
    if display_italic_pt is None:
        display_italic_pt = body_pt
    body_px = int(body_pt * PT)
    italic_px = int(italic_pt * PT)
    display_italic_px = int(display_italic_pt * PT)
    return {
        "regular": ImageFont.truetype(str(FONTS["body"]), body_px),
        "italic": ImageFont.truetype(str(FONTS["body_italic"]), italic_px),
        "display_italic": ImageFont.truetype(str(FONTS["display_italic"]), display_italic_px),
    }


def render_spread_page(spread_num: int, page_side: str) -> Image.Image:
    """Main entry: render a single spread page as a 2625x2625 PIL RGBA image."""
    src = SPREADS_PRINT_DIR / f"spread_{spread_num:02d}.png"
    spread = Image.open(src)
    page = make_full_bleed_page(spread, page_side)

    layout = LB.get(spread_num)
    technique = layout["technique"]

    # TRIPTYCH gets its own handler (S15)
    if technique == LB.TRIPTYCH:
        return _render_triptych_page(page, spread_num, page_side, layout)

    # DUAL_WASH gets its own handler (S3) — one wash box + content per page
    if technique == LB.DUAL_WASH:
        return _render_dual_wash_page(page, spread_num, page_side, layout)

    # All non-triptych spreads have a single text box.
    # The box has a zone (L, R, L_BOTTOM). Only render text on the matching page.
    zone = layout["zone"]
    text_should_appear = (
        (zone in ("L", "L_BOTTOM") and page_side == "verso")
        or (zone == "R" and page_side == "recto")
    )
    if not text_should_appear:
        return page

    # Map audit box to page coords
    page_box = visible_work_box_to_page(layout["box"], page_side)
    if page_box is None:
        # The box landed entirely in the cropped region — return page bare
        return page

    fonts = load_fonts()

    # Inner text padding inside the wash panel (premium picture-book convention).
    # ~25 px (≈ 0.08 in) of padding so type doesn't sit flush against the wash edge.
    if technique == LB.WASH:
        TEXT_PAD = 30
        text_box = (page_box[0] + TEXT_PAD, page_box[1] + TEXT_PAD,
                     page_box[2] - 2 * TEXT_PAD, page_box[3] - 2 * TEXT_PAD)
    else:
        text_box = page_box

    # For WASH: render text to a transparent overlay first so we can measure
    # last_y across all blocks, then size the wash panel to fit text + bottom
    # padding. The overlay is composited over the wash at the end.
    if technique == LB.WASH:
        text_layer = Image.new("RGBA", page.size, (0, 0, 0, 0))
    else:
        text_layer = page

    # Typeset paragraphs
    ms = MS.get(spread_num)
    paras = ms.get("paras", [])
    cursor_y = text_box[1]
    last_y = cursor_y
    for para in paras:
        # Each para is a flat list of runs (we kept paras flat above)
        para_box = (text_box[0], cursor_y, text_box[2],
                     text_box[3] - (cursor_y - text_box[1]))
        last_y = draw_runs_in_box(text_layer, para, fonts, para_box,
                                    layout["text_color"])
        cursor_y = last_y + int(BODY_PT * PT * 0.2)  # small inter-para gap

    # Chant trailing block (S6, S8, S10, S12)
    if "chant_runs" in ms and "chant" in layout:
        chant_size = layout.get("chant_size_pt", BODY_PT)
        chant_leading = layout.get("chant_leading_pt", chant_size + 4)
        uses_black = layout.get("chant_uses_black_italic", False)
        chant_fonts = load_fonts(body_pt=BODY_PT, italic_pt=chant_size,
                                   display_italic_pt=chant_size)
        if uses_black:
            # Swap italic to display_italic (Bookmania Black Italic)
            chant_fonts["italic"] = chant_fonts["display_italic"]
        extra_above = int(layout.get("chant_extra_above_pt", 8) * PT)
        chant_y = last_y + extra_above
        chant_box = (text_box[0], chant_y, text_box[2],
                      text_box[1] + text_box[3] - chant_y)
        last_y = draw_runs_in_box(text_layer, ms["chant_runs"], chant_fonts,
                                    chant_box, layout["text_color"],
                                    leading_px=int(chant_leading * PT))

    # Pact line (S12 only)
    if "pact_runs" in ms and layout.get("pact_line"):
        extra_above = int(layout.get("pact_extra_above_pt", 8) * PT)
        pact_y = last_y + extra_above
        pact_box = (text_box[0], pact_y, text_box[2],
                      text_box[1] + text_box[3] - pact_y)
        last_y = draw_runs_in_box(text_layer, ms["pact_runs"], fonts,
                                    pact_box, layout["text_color"])

    # Squishkeeper close (S18 only)
    if "squishkeeper_close" in ms:
        leading_pt = layout.get("squishkeeper_leading_pt", BODY_LEADING_PT)
        extra_above = int(8 * PT)
        sk_y = last_y + extra_above
        sk_box = (text_box[0], sk_y, text_box[2],
                   text_box[1] + text_box[3] - sk_y)
        last_y = draw_runs_in_box(text_layer, ms["squishkeeper_close"], fonts,
                           sk_box, layout["text_color"],
                           leading_px=int(leading_pt * PT))

    # WASH: now that we know last_y across all blocks, size the wash to fit.
    if technique == LB.WASH:
        fitted_height = max(60, (last_y - page_box[1]) + TEXT_PAD)
        fitted_box = (page_box[0], page_box[1], page_box[2], fitted_height)
        feather_work = LB.WASH_FEATHER_WORK
        feather_px = int(feather_work * 3.906)  # work-to-print scale
        draw_wash_panel(page, fitted_box,
                         layout["wash_color"], layout["wash_opacity"], feather_px)
        page.alpha_composite(text_layer)

    return page


def _render_dual_wash_page(page, spread_num, page_side, layout):
    """DUAL_WASH (S3) — one wash panel + own content per page.

    Verso uses `verso_box` + `verso_paras` + `verso_text_color`.
    Recto uses `recto_box` + `recto_paras` + `recto_text_color`.
    Auto-fits panel height to text + bottom padding, matching the main WASH path.
    """
    ms = MS.get(spread_num)
    if page_side == "verso":
        box_work = layout["verso_box"]
        paras = ms.get("verso_paras", [])
        text_color = layout["verso_text_color"]
    else:
        box_work = layout["recto_box"]
        paras = ms.get("recto_paras", [])
        text_color = layout["recto_text_color"]

    if not paras:
        return page

    page_box = visible_work_box_to_page(box_work, page_side)
    if page_box is None:
        return page

    fonts = load_fonts()
    TEXT_PAD = 30
    text_box = (page_box[0] + TEXT_PAD, page_box[1] + TEXT_PAD,
                 page_box[2] - 2 * TEXT_PAD, page_box[3] - 2 * TEXT_PAD)

    # Render text to a transparent overlay first so the wash auto-fits.
    text_layer = Image.new("RGBA", page.size, (0, 0, 0, 0))
    cursor_y = text_box[1]
    last_y = cursor_y
    for para in paras:
        para_box = (text_box[0], cursor_y, text_box[2],
                     text_box[3] - (cursor_y - text_box[1]))
        last_y = draw_runs_in_box(text_layer, para, fonts, para_box, text_color)
        cursor_y = last_y + int(BODY_PT * PT * 0.2)

    fitted_height = max(60, (last_y - page_box[1]) + TEXT_PAD)
    fitted_box = (page_box[0], page_box[1], page_box[2], fitted_height)
    feather_px = int(LB.WASH_FEATHER_WORK * 3.906)
    draw_wash_panel(page, fitted_box,
                     layout["wash_color"], layout["wash_opacity"], feather_px)
    page.alpha_composite(text_layer)
    return page


def _render_triptych_page(page, spread_num, page_side, layout):
    """Triptych (S3, S15) — three parallel panels at the spread bottom.

    Panel A (working x=40-500) lives entirely on verso.
    Panel B (working x=562-1022) spans the gutter — we place its text in the
        verso-side half of Panel B (x_work=562 to gutter=792) for legibility.
    Panel C (working x=1084-1544) lives entirely on recto.
    S3 also has a closing line at y=620 spanning the bottom — we split it
    naturally between verso and recto with a soft break.
    """
    fonts = load_fonts()
    ms = MS.get(spread_num)
    panels = layout["panels"]
    panel_paras = ms["panel_paras"]

    if page_side == "verso":
        # Panel A
        a_box = visible_work_box_to_page(panels[0]["box"], "verso")
        if a_box:
            feather_px = int(LB.WASH_FEATHER_WORK * 3.906)
            draw_wash_panel(page, a_box, layout["wash_color"],
                             layout["wash_opacity"], feather_px)
            draw_runs_in_box(page, panel_paras[0][0], fonts, a_box,
                               panels[0]["text_color"])
        # Panel B (verso half only)
        b_orig = panels[1]["box"]
        b_verso_box = (b_orig[0], b_orig[1],
                        min(b_orig[2], 792 - b_orig[0]), b_orig[3])
        b_box = visible_work_box_to_page(b_verso_box, "verso")
        if b_box:
            feather_px = int(LB.WASH_FEATHER_WORK * 3.906)
            draw_wash_panel(page, b_box, layout["wash_color"],
                             layout["wash_opacity"], feather_px)
            # For S3 Panel B: split the text — verso gets "In Goo Coast,"
            # to keep it from the gutter, recto would get the rest. But the
            # original sentence is short ("In Goo Coast, Goo Ball looked up.")
            # — fit it on verso entirely if the box allows.
            draw_runs_in_box(page, panel_paras[1][0], fonts, b_box,
                               panels[1]["text_color"])
    elif page_side == "recto":
        # Panel C
        c_box = visible_work_box_to_page(panels[2]["box"], "recto")
        if c_box:
            feather_px = int(LB.WASH_FEATHER_WORK * 3.906)
            draw_wash_panel(page, c_box, layout["wash_color"],
                             layout["wash_opacity"], feather_px)
            draw_runs_in_box(page, panel_paras[2][0], fonts, c_box,
                               panels[2]["text_color"])

    # S3 closing line — for now, place on verso under the panels
    if spread_num == 3 and page_side == "verso" and "closing_paras" in ms:
        closing_box_work = (40, layout["closing_y"], 750, 50)
        closing_box = visible_work_box_to_page(closing_box_work, "verso")
        if closing_box:
            close_fonts = load_fonts(body_pt=14, italic_pt=14)
            draw_runs_in_box(page, ms["closing_paras"][0], close_fonts,
                               closing_box, layout["closing_color"])

    return page


if __name__ == "__main__":
    import sys as _sys
    out_dir = Path(__file__).parent / "out" / "preview"
    out_dir.mkdir(parents=True, exist_ok=True)
    if len(_sys.argv) > 1:
        spreads = [int(x) for x in _sys.argv[1:]]
    else:
        spreads = [1]
    for n in spreads:
        for side in ("verso", "recto"):
            img = render_spread_page(n, side)
            out_path = out_dir / f"spread_{n:02d}_{side}.png"
            img.save(out_path)
            print(f"saved {side} -> {out_path.name}")
