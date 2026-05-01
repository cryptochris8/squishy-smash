"""
Phase-3 typography system. Three roles: display, body, accent.

Each role has named "styles" (`title`, `subtitle`, `body`, `narrator`,
`caption`, `pack_label`, etc.) so layout code calls
`draw_text(canvas, x, y, "...", style="title")` instead of remembering
which font + size + tracking goes where. Adding a new style is a
one-place change here, not a 12-page sweep.

Pure Pillow — no ReportLab. Each page renders as one Pillow image
that gets stamped onto the ReportLab Canvas as a single drawImage
call. Trade-off: rasterized text vs vector. For a children's
picture book where the smallest text is ~22 pt, the visual
difference at 300 DPI print is invisible, and it lets us use the
alpha-compositing tricks (gradients, glows, drop shadows) that
make the book look premium.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from config import FONTS, PALETTE

# Re-exported so `style()` callers can also reach the resolver
# without two separate imports.


# ---------------------------------------------------------------------------
# Font cache. Loading a TTF file is ~10 ms; caching by (path, size) keeps
# page renders fast.
# ---------------------------------------------------------------------------

_FONT_CACHE: dict[tuple[Path, int], ImageFont.FreeTypeFont] = {}


def font(role: str, size: int) -> ImageFont.FreeTypeFont:
    """Look up a font by role + size. Roles must exist in
    `config.FONTS`. Variable fonts (EB Garamond) load at the file's
    default weight; if a layout needs bold + regular both, request
    them via separate role names."""
    if role not in FONTS:
        raise KeyError(f"unknown font role {role!r}")
    path = Path(FONTS[role])
    key = (path, size)
    cached = _FONT_CACHE.get(key)
    if cached is not None:
        return cached
    if not path.exists():
        # Fall back to the display face if the requested role's TTF
        # is missing (e.g., in a fresh checkout before fonts are
        # downloaded). Better to render in the wrong face than to
        # crash the whole pipeline.
        path = Path(FONTS["display"])
    f = ImageFont.truetype(str(path), size)
    _FONT_CACHE[key] = f
    return f


# ---------------------------------------------------------------------------
# Style sheet. Each entry is the canonical typographic spec for one
# layout role. Fields:
#   - role:     which font to use (display / body / body_italic / accent)
#   - size:     point size (assumes ~300 DPI render canvas)
#   - leading:  line-height in points; None = font's default
#   - tracking: per-character pixel offset; negative tightens
#   - color:    hex from PALETTE (string key or raw "#XXXXXX")
#   - align:    "left" | "center" | "right"
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class TextStyle:
    role: str
    size: int
    leading: int | None
    tracking: int
    color: str
    align: str = "left"


STYLES: dict[str, TextStyle] = {
    # Wordmarks + giant titles (T1, T10 mythic finale).
    "wordmark":     TextStyle("display", 220, 240, -8, "pink",       "center"),
    "wordmark_alt": TextStyle("display", 220, 240, -8, "cream",      "center"),
    "title":         TextStyle("display", 110, 124, -4, "soft_white","center"),
    "subtitle":      TextStyle("display",  56,  68, -2, "cream",     "center"),
    "subtitle_xl":   TextStyle("display",  72,  86, -2, "cream",     "center"),
    "tagline":       TextStyle("body_italic", 38, 46, 0, "soft_white","center"),

    # Section / pack headers.
    "pack_portal":   TextStyle("display",  140, 156, -3, "cream",    "left"),
    "pack_subtitle": TextStyle("body_italic", 42, 52, 0, "soft_white","left"),
    "section_label": TextStyle("display",   38,  44, 4, "cream",     "left"),
    "section_kicker":TextStyle("display",   28,  32, 8, "rose_dust", "center"),

    # Body prose + bios.
    "body":          TextStyle("body",      30,  44, 0, "soft_white","left"),
    "body_dim":      TextStyle("body",      28,  42, 0, "soft_white","left"),
    "lede":          TextStyle("body",      36,  48, 0, "soft_white","center"),

    # Squishkeeper narrator voice — italic + cream so it reads
    # apart from prose without disrupting the page.
    "narrator":      TextStyle("body_italic", 32, 46, 0, "cream",    "left"),
    "narrator_lg":   TextStyle("body_italic", 42, 56, 0, "cream",    "left"),

    # Hand-letter accents — flavor pulls, mythic stingers.
    "flavor":        TextStyle("accent",    52,  58, 0, "rose_dust","left"),
    "flavor_lg":     TextStyle("accent",    72,  82, 0, "cream",    "center"),

    # Character + field labels.
    "char_name":     TextStyle("display",   58,  64, -2, "soft_white","left"),
    "char_name_lg":  TextStyle("display",   88,  96, -3, "cream",    "left"),
    "char_name_mythic": TextStyle("display", 96, 110, -3, "gold_hi", "center"),
    # Bumped field_label up 18->26 + tightened tracking 6->4 for
    # legibility on the dark plum bg (the previous size felt dim
    # and small even at 300 DPI render).
    "field_label":   TextStyle("display",   26,  32, 4,  "cream",    "left"),
    "field_value":   TextStyle("body",      30,  40, 0,  "soft_white","left"),
    "rarity_stars":  TextStyle("display",   30,  36, 4,  "cream",    "left"),

    # Page chrome.
    "folio":         TextStyle("display",   16,  18, 4,  "soft_white","center"),
    "imprint":       TextStyle("body",      18,  26, 0,  "soft_white","center"),
    "imprint_dim":   TextStyle("body_italic", 16, 22, 0, "soft_white","center"),

    # Map labels (page 4).
    "map_region":    TextStyle("display",   42,  48, 4,  "cream",    "center"),
    "map_region_lg": TextStyle("display",   56,  62, 6,  "cream",    "center"),
    "map_landmark":  TextStyle("body_italic", 22, 28, 0, "soft_white","center"),
    "map_landmark_lg": TextStyle("body_italic", 28, 36, 0, "soft_white","center"),

    # Phase 5b — dark variants used when the text sits on a parchment
    # plate (T3 narrator, T8 right column, T10 fairy-tale paragraph).
    # Dark plum on cream parchment reads as "real children's
    # hardcover" instead of cream-on-cream-confusion.
    "char_name_lg_dark":     TextStyle("display",   88,  96, -3, "deep_plum", "left"),
    "rarity_stars_dark":     TextStyle("display",   30,  36, 4,  "deep_plum", "left"),
    "field_label_dark":      TextStyle("display",   26,  32, 4,  "shadow_warm","left"),
    "field_value_dark":      TextStyle("body",      30,  40, 0,  "deep_plum", "left"),
    "narrator_dark":         TextStyle("body_italic", 32, 46, 0, "shadow_warm", "left"),
    "narrator_lg_dark":      TextStyle("body_italic", 42, 56, 0, "deep_plum", "left"),
    "lede_dark":             TextStyle("body",      36,  48, 0, "deep_plum","center"),
}


def style(name: str) -> TextStyle:
    """Look up a registered style by name."""
    if name not in STYLES:
        raise KeyError(f"unknown style {name!r}")
    return STYLES[name]


# ---------------------------------------------------------------------------
# Text drawing. Two functions:
#   - measure(text, style)            -> (width, height)
#   - draw_text(canvas, x, y, text, *, style, max_width=None, max_lines=None)
#                                      -> int  (final y baseline)
# ---------------------------------------------------------------------------

def _resolve_color(color: str) -> tuple[int, int, int, int]:
    hex_str = PALETTE.get(color, color)
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def _font_for(s: TextStyle) -> ImageFont.FreeTypeFont:
    return font(s.role, s.size)


def measure_line(text: str, s: TextStyle) -> int:
    """Width in pixels of a single rendered line."""
    f = _font_for(s)
    if not text:
        return 0
    if s.tracking == 0:
        return int(f.getlength(text))
    # Manual tracking: sum advance widths + (n-1) * tracking
    return int(f.getlength(text) + s.tracking * (len(text) - 1))


def _wrap_lines(text: str, s: TextStyle, max_width: int) -> list[str]:
    """Greedy word-wrap. Splits on whitespace; preserves explicit
    `\\n` line breaks. Doesn't hyphenate (kid-readable)."""
    if max_width <= 0:
        return [text]
    paragraphs = text.split("\n")
    lines: list[str] = []
    for paragraph in paragraphs:
        words = paragraph.split()
        if not words:
            lines.append("")
            continue
        current = words[0]
        for w in words[1:]:
            candidate = f"{current} {w}"
            if measure_line(candidate, s) <= max_width:
                current = candidate
            else:
                lines.append(current)
                current = w
        lines.append(current)
    return lines


def _draw_line_with_tracking(draw: ImageDraw.ImageDraw,
                             xy: tuple[int, int],
                             text: str,
                             f: ImageFont.FreeTypeFont,
                             fill: tuple[int, int, int, int],
                             tracking: int) -> None:
    if tracking == 0:
        draw.text(xy, text, font=f, fill=fill)
        return
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=f, fill=fill)
        x += int(f.getlength(ch)) + tracking


def draw_text(canvas: Image.Image,
              x: int, y: int,
              text: str,
              *,
              style_name: str,
              max_width: int | None = None,
              max_lines: int | None = None,
              shadow: bool = False) -> int:
    """Render `text` onto `canvas` starting at (x, y). Returns the y
    position of the next available line below the text block.

    `max_width` triggers word-wrap. `max_lines` truncates with no
    ellipsis (we'd rather under-set a paragraph than mangle it
    mid-word — the bios are length-budgeted upstream). `shadow=True`
    drops a 4 px black-at-50% shadow under each line for legibility
    on busy backgrounds."""
    s = STYLES[style_name]
    f = _font_for(s)
    color = _resolve_color(s.color)
    leading = s.leading or s.size + 6

    lines = _wrap_lines(text, s, max_width or 10**9)
    if max_lines is not None:
        lines = lines[:max_lines]

    draw = ImageDraw.Draw(canvas)
    cursor_y = y
    for line in lines:
        line_w = measure_line(line, s)
        if s.align == "center":
            # `x` is always interpreted as the CENTER of the line
            # when align="center" — independent of max_width. Earlier
            # implementations treated `x` as the left edge when
            # max_width was provided, which silently overflowed the
            # right margin on every centered title with a wrap
            # constraint.
            line_x = x - line_w // 2
        elif s.align == "right":
            line_x = x - line_w if max_width is None \
                else x + max_width - line_w
        else:
            line_x = x

        if shadow:
            shadow_color = (0, 0, 0, 128)
            _draw_line_with_tracking(
                draw, (line_x + 4, cursor_y + 4), line, f,
                shadow_color, s.tracking,
            )
        _draw_line_with_tracking(
            draw, (line_x, cursor_y), line, f, color, s.tracking,
        )
        cursor_y += leading
    return cursor_y


def measure_block(text: str, style_name: str,
                  max_width: int) -> tuple[int, int]:
    """How wide and tall would `text` render at the given style and
    width? Useful for centering a paragraph in a box."""
    s = STYLES[style_name]
    leading = s.leading or s.size + 6
    lines = _wrap_lines(text, s, max_width)
    width = max((measure_line(line, s) for line in lines), default=0)
    height = leading * len(lines)
    return width, height


__all__ = [
    "STYLES",
    "TextStyle",
    "draw_text",
    "font",
    "measure_block",
    "measure_line",
    "style",
]
