"""
Phase-3 page templates. One function per template type. Each takes
the page geometry and any character/text data it needs, returns an
RGBA Pillow Image at full bleed resolution (300 DPI).

The build_interior.py script then stamps each rendered Image onto
a ReportLab Canvas page via drawImage. That hybrid keeps the rich
alpha/gradient/glow work in Pillow while still producing one PDF
file per book.

Layout pixel grid (300 DPI render):
    bleed page:   2625 x 2625 px (8.75 x 8.75 in)
    trim line:    inset 38 px on all sides
    safe area:    inset 150 px on all sides

Templates implemented (matches book/manuscript/02_manuscript_v2.md):

    T1_title           — page 1
    T2_imprint         — page 2
    T3_narrator        — page 3 (letter from the Squishkeeper)
    T_map              — page 4 (Map of the Squishy World)
    T4_pack_index      — pages 5-6 (left + right halves rendered separately)
    T5_pack_portal     — pages 7, 15, 23
    T6_pack_scene      — pages 8, 16, 24
    T8_featured        — pages 9-12, 17-20, 25-28 (one character per page)
    T9_premium_duo     — pages 13, 21, 29 (two stacked premium chars)
    T10_mythic_finale  — pages 14, 22, 30 (single-character finale spread)
    T_gallery          — page 31 (27 thumbnails)
    T_tracker          — page 32 (48-cell checklist)
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from card_frame import (
    _drop_shadow_layer,
    _glow_layer,
    _hex_to_rgba,
    _vertical_gradient,
    draw_card_frame,
    paint_pack_background,
)


def _draw_gradient_wordmark(canvas, x_center, y, text, *,
                            font_size, top_hex, mid_hex, bottom_hex,
                            shadow=True):
    """Paint a wordmark with a vertical 3-stop color gradient
    inside each glyph (foil-stamp illusion). Pre-fix the title was
    flat pink/cream which read as digital. With a top->mid->bottom
    ramp clipped to the glyph alpha, the wordmark reads as press-
    foil.

    Implementation: render the text once on a large RGBA tile in
    pure white (which becomes our alpha mask), build a 3-stop
    vertical gradient image at the same size, then putalpha() to
    keep only the gradient pixels where the text was opaque.
    """
    from PIL import ImageDraw as _ID
    f = font("display", font_size)
    # Measure
    bbox = _ID.Draw(canvas).textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    # Tile size = text bbox + margin for glyph descenders
    tile_w = tw + 80
    tile_h = th + 80
    # 1) Build 3-stop vertical gradient
    grad = Image.new("RGB", (tile_w, tile_h))
    top = _hex_to_rgba(top_hex)[:3]
    mid = _hex_to_rgba(mid_hex)[:3]
    bot = _hex_to_rgba(bottom_hex)[:3]
    for ty in range(tile_h):
        if ty < tile_h // 2:
            t = ty / max(tile_h // 2 - 1, 1)
            r = round(top[0] * (1 - t) + mid[0] * t)
            g = round(top[1] * (1 - t) + mid[1] * t)
            b = round(top[2] * (1 - t) + mid[2] * t)
        else:
            t = (ty - tile_h // 2) / max(tile_h // 2 - 1, 1)
            r = round(mid[0] * (1 - t) + bot[0] * t)
            g = round(mid[1] * (1 - t) + bot[1] * t)
            b = round(mid[2] * (1 - t) + bot[2] * t)
        for tx in range(tile_w):
            grad.putpixel((tx, ty), (r, g, b))
    grad = grad.convert("RGBA")
    # 2) Build alpha mask = opacity from rendered text
    mask = Image.new("L", (tile_w, tile_h), 0)
    _ID.Draw(mask).text((40 - bbox[0], 40 - bbox[1]),
                        text, font=f, fill=255)
    grad.putalpha(mask)
    # 3) Optional drop shadow (rendered as offset black silhouette)
    if shadow:
        shadow_layer = Image.new("RGBA", (tile_w, tile_h), (0, 0, 0, 0))
        _ID.Draw(shadow_layer).text(
            (40 - bbox[0] + 6, 40 - bbox[1] + 6),
            text, font=f, fill=(0, 0, 0, 130),
        )
        # Stamp shadow first
        sx = x_center - tile_w // 2
        sy = y - 40
        canvas.alpha_composite(shadow_layer, (sx, sy))
    # 4) Stamp gradient-filled wordmark
    sx = x_center - tile_w // 2
    sy = y - 40
    canvas.alpha_composite(grad, (sx, sy))


def _draw_star_row(canvas, x, y, count, *, size=24,
                   color_hex=None, gap=6):
    """Draw `count` filled stars starting at (x, y). Used in place of
    Unicode ★ characters because Fredoka's glyph set doesn't include
    them — drawing them as polygons avoids font-fallback drama."""
    from PIL import ImageDraw
    from config import PALETTE
    from card_frame import _hex_to_rgba as _rgba
    color = _rgba(color_hex or PALETTE["cream"], 230)
    draw = ImageDraw.Draw(canvas)
    cx = x + size // 2
    cy = y + size // 2
    for i in range(count):
        # 5-point star polygon
        points = []
        for k in range(10):
            angle = -math.pi / 2 + k * math.pi / 5
            r = size // 2 if k % 2 == 0 else size // 4
            points.append((cx + r * math.cos(angle),
                           cy + r * math.sin(angle)))
        draw.polygon(points, fill=color)
        cx += size + gap
    return cx - x  # total width drawn
from config import (
    BRAND_ICON,
    GLOW,
    PACK_BG_GRADIENT,
    PACK_ORNAMENT,
    PACK_TEXTURE,
    PACK_TINTS,
    PALETTE,
    RARITY_RING,
    by_num,
    featured_characters,
    gallery_characters,
)
from typography import (
    draw_text,
    font,
    measure_block,
    measure_line,
    style,
)

# 300 DPI bleed page
PAGE_W = 2625
PAGE_H = 2625
TRIM = 38  # inset to trim line
SAFE = 150  # inset to safe area (~0.5 in from bleed edge)


def _new_canvas(bg_hex: str) -> Image.Image:
    canvas = Image.new("RGBA", (PAGE_W, PAGE_H), _hex_to_rgba(bg_hex))
    return canvas


def _vignette(canvas: Image.Image, intensity: float = 0.35) -> None:
    """Soft radial darkening at the page edges so the deep-plum bleed
    feels intentional, not flat. Pasted as a separate alpha layer
    on top of whatever's underneath."""
    layer = Image.new("RGBA", (PAGE_W, PAGE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    a = int(intensity * 255)
    # A series of rings inside-out, increasing alpha at the edge.
    for i in range(60):
        t = i / 60
        ring_inset = int(SAFE + (PAGE_W // 2 - SAFE) * t)
        opacity = int((1 - t) * a * t * 4)  # peaks mid-out, falls off
        if opacity <= 0:
            continue
        draw.rectangle(
            (ring_inset, ring_inset,
             PAGE_W - ring_inset, PAGE_H - ring_inset),
            outline=(0, 0, 0, min(opacity, 255)),
            width=2,
        )
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius=8)))


# ---------------------------------------------------------------------------
# Decorative atoms: scatter sparkles, draw a dotted rule, drop a folio
# ---------------------------------------------------------------------------

def _scatter_sparkles(canvas: Image.Image, count: int, colors: list[str],
                      seed: int = 0, sizes: tuple[int, int] = (2, 8),
                      alpha: int = 200) -> None:
    """Random sparkle particles across the canvas. Used for premium
    pages (mythic finale) and the title cover."""
    import random
    rng = random.Random(seed)
    draw = ImageDraw.Draw(canvas)
    for _ in range(count):
        x = rng.randrange(SAFE // 2, PAGE_W - SAFE // 2)
        y = rng.randrange(SAFE // 2, PAGE_H - SAFE // 2)
        size = rng.randint(*sizes)
        color_hex = rng.choice(colors)
        c = _hex_to_rgba(color_hex, alpha)
        # 4-point sparkle = two thin diamonds rotated 45 degrees
        draw.polygon(
            [(x, y - size), (x + size // 3, y),
             (x, y + size), (x - size // 3, y)],
            fill=c,
        )
        draw.polygon(
            [(x - size, y), (x, y + size // 3),
             (x + size, y), (x, y - size // 3)],
            fill=c,
        )


def _dotted_rule(canvas: Image.Image, x1: int, y: int, x2: int,
                 color_hex: str, dot_size: int = 4, gap: int = 12,
                 alpha: int = 200) -> None:
    draw = ImageDraw.Draw(canvas)
    fill = _hex_to_rgba(color_hex, alpha)
    x = x1
    while x < x2:
        draw.ellipse(
            (x, y, x + dot_size, y + dot_size),
            fill=fill,
        )
        x += dot_size + gap


def _folio(canvas: Image.Image, page_num: int, *,
           pack_color: str | None = None) -> None:
    """Page number in the bottom-outer corner. Tinted to the pack
    when given (pack-character pages); cream otherwise."""
    if page_num <= 0:
        return
    color = pack_color or PALETTE["cream"]
    # Bottom-right corner, inside safe area. We don't bother
    # mirroring left/right pages since the build is symmetrical
    # (8.75x8.75 with full bleed both sides).
    cx = PAGE_W - SAFE - 60
    cy = PAGE_H - SAFE - 50
    draw = ImageDraw.Draw(canvas)
    f = font("display", 22)
    text = str(page_num)
    bbox = draw.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    # Soft circular glyph background
    r = max(tw, th) + 14
    draw.ellipse(
        (cx - r, cy - r, cx + r, cy + r),
        outline=_hex_to_rgba(color, 200),
        width=2,
    )
    draw.text(
        (cx - tw // 2 - bbox[0], cy - th // 2 - bbox[1]),
        text,
        font=f,
        fill=_hex_to_rgba(color, 230),
    )


def _stamp_pack_corners(canvas: Image.Image, pack: str,
                         size: int = 220, alpha: int = 220) -> None:
    """Stamp the per-pack corner ornament in top-left + bottom-right.
    Bottom-right copy is rotated 180° so the ornament reads as a
    visual frame — the ear of one ornament points into the page,
    the ear of the other points out. The ornament is the single
    most "Scholastic-bridge" element per the UI design audit.

    No-op if the ornament file is missing (fresh checkouts before
    bake_ornaments.py runs)."""
    path = PACK_ORNAMENT.get(pack)
    if path is None or not path.exists():
        return
    src = Image.open(path).convert("RGBA")
    src = src.resize((size, size), Image.Resampling.LANCZOS)
    # Apply alpha
    r, g, b, a = src.split()
    a = a.point(lambda v, k=alpha: int(v * (k / 255)))
    tinted = Image.merge("RGBA", (r, g, b, a))
    # Top-left
    canvas.alpha_composite(tinted, (40, 40))
    # Bottom-right, rotated 180° for a "frame" feel
    rotated = tinted.rotate(180, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(rotated, (PAGE_W - size - 40, PAGE_H - size - 40))


def _bunny_mark(canvas: Image.Image, x: int, y: int, size: int,
                tint_hex: str | None = None,
                alpha: int = 220) -> None:
    """Stamp the brand bunny silhouette at (x, y) sized to fit a
    `size` x `size` square. Tinted to `tint_hex` if given (used for
    pack-page corner marks)."""
    if not BRAND_ICON.exists():
        return
    icon = Image.open(BRAND_ICON).convert("RGBA")
    icon = icon.resize((size, size), Image.Resampling.LANCZOS)
    if tint_hex is not None:
        # Recolor: keep the bunny's alpha mask, replace RGB with tint
        rgba = _hex_to_rgba(tint_hex, alpha)
        sil = Image.new("RGBA", icon.size, rgba[:3] + (0,))
        sil.putalpha(icon.getchannel("A"))
        # Apply target alpha
        r, g, b, a = sil.split()
        a = a.point(lambda v, k=alpha: int(v * (k / 255)))
        sil = Image.merge("RGBA", (r, g, b, a))
        canvas.alpha_composite(sil, (x, y))
    else:
        canvas.alpha_composite(icon, (x, y))


# ---------------------------------------------------------------------------
# T1 — Title page (page 1)
# ---------------------------------------------------------------------------

def T1_title() -> Image.Image:
    """Cover-open title page. Brand wordmark, subtitle, hero trio
    one card per pack (1, 17, 33), sparkle scatter."""
    canvas = _new_canvas(PALETTE["bg"])

    # Subtle radial highlight behind the wordmark to lift it off
    # the deep-plum bg. Big soft pink halo.
    glow = _glow_layer(PAGE_W, PAGE_H, PALETTE["pink"],
                       radius=480, alpha=0.15)
    canvas.alpha_composite(glow)

    # Sparkle scatter for "magical world" vibe.
    _scatter_sparkles(
        canvas,
        count=80,
        colors=[PALETTE["cream"], PALETTE["pink"], PALETTE["jelly_blue"]],
        seed=1,
        sizes=(3, 14),
        alpha=180,
    )

    # SQUISHY in solid pink over SMASH in solid cream, centered.
    # Pre-fix the wordmark used a 3-stop vertical gradient inside
    # each glyph for a foil-stamp illusion, but two issues showed
    # up on the cover: (1) the gradient renderer's per-glyph tile
    # padding caused the SMASH tile to overlap the bottom of
    # SQUISHY by ~70 px, and (2) the rose-dust mid-color was too
    # close in luminance to the dark plum bg, making the middle of
    # each letter hard to read. Solid colors with a wider vertical
    # gap fix both at once. We keep the drop shadow for legibility.
    cx = PAGE_W // 2
    title_y = 280
    draw_text(canvas, cx, title_y,
              "SQUISHY", style_name="wordmark", shadow=True)
    # 380 px gap (was 230) so the words have clear breathing room
    # — the SQUISHY descender ("Y") and the SMASH cap ("S") no
    # longer touch.
    draw_text(canvas, cx, title_y + 380,
              "SMASH", style_name="wordmark_alt", shadow=True)

    # Subtitle + tagline
    sub_y = title_y + 480
    draw_text(canvas, cx, sub_y,
              "Meet the Squishies", style_name="subtitle")
    draw_text(canvas, cx, sub_y + 90,
              "A Field Guide from the Squishkeeper",
              style_name="tagline")

    # Hero trio — asymmetric stack with the center card largest and
    # forward, the two side cards rotated slightly and overlapping
    # behind. Pre-fix the trio sat as three equal cards with a flat
    # row — the gap between title and cards read as empty space and
    # the layout was static. Post-fix the cards fill the lower half
    # confidently and signal "three packs, one world" at a glance.
    chars = by_num()
    pack_heroes = [
        (17, -10, 0.78),   # Goo Ball, rotated CCW, smaller, behind-left
        (33,  +0, 1.00),   # Blushy Bun Bunny, no rotation, biggest, center+front
        (1,  +10, 0.78),   # Soft Dumpling, rotated CW, smaller, behind-right
    ]
    center_card_w = 820
    center_card_h = int(center_card_w * 1.3)
    # Pull the trio up so its top tucks ~200 px under the tagline
    # rather than sitting in the bottom third with a big empty
    # band above. Bottom of center card ends well above the trim
    # line; the side cards are rotated so they extend slightly
    # past the center card's footprint without crossing safe area.
    center_y = 1080
    center_x = cx - center_card_w // 2
    overlap_inset = 240  # how far the side cards tuck under center

    # Render the side cards FIRST so the center card composites on
    # top — overlap reads correctly with the larger card in front.
    for i, (num, angle_deg, scale) in enumerate(pack_heroes):
        if scale == 1.0:
            continue  # render center last
        char = chars[num]
        cw = int(center_card_w * scale)
        ch = int(center_card_h * scale)

        # Render the card onto a tile slightly larger than the card
        # so the rotation doesn't clip the rarity ring + drop shadow.
        pad = 80
        tile = Image.new("RGBA", (cw + pad * 2, ch + pad * 2),
                         (0, 0, 0, 0))
        draw_card_frame(
            tile, char.card_path,
            pad, pad, cw, ch,
            rarity=char.rarity, pack=char.pack,
        )
        # Rotate around the tile center; resample bicubic for smooth
        # edges. expand=False keeps tile size stable so we know
        # exactly where to paste.
        rotated = tile.rotate(angle_deg, resample=Image.Resampling.BICUBIC,
                              expand=False)
        side = "left" if i == 0 else "right"
        if side == "left":
            paste_x = center_x - cw + overlap_inset - pad
        else:
            paste_x = center_x + center_card_w - overlap_inset - pad
        paste_y = center_y + (center_card_h - ch) // 2 - pad
        canvas.alpha_composite(rotated, (paste_x, paste_y))

    # Center card — biggest, no rotation, drawn last so it sits in
    # front of the side cards.
    center_char = chars[pack_heroes[1][0]]
    draw_card_frame(
        canvas, center_char.card_path,
        center_x, center_y, center_card_w, center_card_h,
        rarity=center_char.rarity, pack=center_char.pack,
    )

    _vignette(canvas, intensity=0.45)
    return canvas


# ---------------------------------------------------------------------------
# T2 — Imprint / copyright (page 2)
# ---------------------------------------------------------------------------

def T2_imprint() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2
    cy = PAGE_H // 2

    # Quiet ornament — small bunny mark above the text block
    _bunny_mark(canvas, cx - 60, cy - 380, size=120,
                tint_hex=PALETTE["pink"], alpha=180)

    block_y = cy - 200
    block_y = draw_text(canvas, cx, block_y,
                        "Squishy Smash:\nMeet the Squishies",
                        style_name="title", max_width=PAGE_W - SAFE * 2)
    block_y += 40
    _dotted_rule(canvas, cx - 200, block_y, cx + 200,
                 PALETTE["rose_dust"])
    block_y += 60

    block_y = draw_text(canvas, cx, block_y,
                        "© 2026 Squishy Smash. All rights reserved.",
                        style_name="imprint", max_width=PAGE_W - SAFE * 2)
    block_y += 20
    block_y = draw_text(canvas, cx, block_y,
                        "squishysmash.com  ·  Printed by Amazon KDP.",
                        style_name="imprint_dim",
                        max_width=PAGE_W - SAFE * 2)
    block_y += 100
    draw_text(canvas, cx, block_y,
              "For everyone who has ever needed\na soft thing to squish.",
              style_name="imprint_dim", max_width=PAGE_W - SAFE * 2)

    _vignette(canvas, intensity=0.35)
    return canvas


# ---------------------------------------------------------------------------
# T3 — Letter from the Squishkeeper (page 3)
# ---------------------------------------------------------------------------

def T3_narrator() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2

    # Header: "A note from the Squishkeeper" in display
    header_y = SAFE + 120
    draw_text(canvas, cx, header_y, "A note from",
              style_name="section_kicker")
    draw_text(canvas, cx, header_y + 60,
              "the Squishkeeper",
              style_name="title")

    # Decorative rule
    rule_y = header_y + 280
    _dotted_rule(canvas, cx - 320, rule_y, cx + 320,
                 PALETTE["rose_dust"])

    # Body — the locked 110-word narrator letter (italic,
    # narrator style on a single block).
    letter = (
        # 5a fix: removed em dash. Voice rule: kids read periods,
        # not em dashes. The first prose the reader meets must
        # follow our own rules.
        "Long ago, the very first wobble rolled across the Squishy "
        "World. Someone had to keep track of every wonderful "
        "squish that followed.\n\n"
        "That someone is me. I am the Squishkeeper.\n\n"
        "No one is quite sure where I live. Somewhere soft, "
        "probably. No one is quite sure what I look like. Probably "
        "round. What I can tell you is this: every squishy that "
        "bounces, ripples, glows, or giggles has a page in this "
        "book.\n\n"
        "Forty-eight friends. Three packs. One soft, silly, "
        "sparkly world.\n\n"
        "Turn the page gently. I have been saving this one for you."
    )
    body_x = SAFE + 160
    body_w = PAGE_W - 2 * (SAFE + 160)
    body_y = rule_y + 80

    draw_text(canvas, body_x, body_y, letter,
              style_name="narrator_lg", max_width=body_w)

    # Sign-off in script accent
    signoff_y = PAGE_H - SAFE - 160
    draw_text(canvas, cx, signoff_y,
              "— the Squishkeeper",
              style_name="flavor")

    _folio(canvas, 3)
    _vignette(canvas, intensity=0.30)
    return canvas


# ---------------------------------------------------------------------------
# T_map — Map of the Squishy World (page 4)
# ---------------------------------------------------------------------------

REGIONS = [
    {
        "name": "PUDDING HILLS",
        "subtitle": "(home of Squishy Foods)",
        "tint": PALETTE["lime"],
        "landmarks": ["Sprinkle Cliffs", "Dumpling Dell",
                      "Mochi Meadows", "Syrup River"],
    },
    {
        "name": "GOO COAST",
        "subtitle": "(home of Goo & Fidgets)",
        "tint": PALETTE["jelly_blue"],
        "landmarks": ["Bubble Bay", "Stretch Tide",
                      "Plasma Shore", "Aurora Reef"],
    },
    {
        "name": "MOONLIT HOLLOW",
        "subtitle": "(home of Creepy-Cute Creatures)",
        "tint": PALETTE["lavender"],
        "landmarks": ["Whisper Woods", "Star Pond",
                      "Crescent Cave", "Cuddle Glade"],
    },
]


def T_map() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2

    # Title
    draw_text(canvas, cx, SAFE + 80,
              "THE SQUISHY WORLD",
              style_name="title")
    draw_text(canvas, cx, SAFE + 220,
              "Three regions. Forty-eight squishies.\n"
              "One Squishkeeper to keep track.",
              style_name="tagline", max_width=PAGE_W - SAFE * 2)

    # Three region medallions in triangle layout. Pulled down + scaled
    # up so the page reads as balanced rather than top-heavy. Inside
    # text bumped at the same time so the larger medallions don't
    # leave a small label rattling around in a big circle.
    medallion_r = 320         # was 240
    triangle_y = SAFE + 880   # was SAFE + 700
    positions = [
        (cx - 700, triangle_y),               # Pudding Hills (left)
        (cx,       triangle_y + 420),         # Goo Coast (center, lower)
        (cx + 700, triangle_y),               # Moonlit Hollow (right)
    ]

    for i, region in enumerate(REGIONS):
        mx, my = positions[i]
        tint = region["tint"]
        # Soft glow halo per region
        halo = _glow_layer(medallion_r * 4, medallion_r * 4,
                           tint, radius=180, alpha=0.30)
        canvas.alpha_composite(
            halo, (mx - medallion_r * 2, my - medallion_r * 2),
        )
        # Medallion ring
        draw = ImageDraw.Draw(canvas)
        draw.ellipse(
            (mx - medallion_r, my - medallion_r,
             mx + medallion_r, my + medallion_r),
            outline=_hex_to_rgba(tint, 230),
            width=5,
        )
        # Inner soft fill
        inner = Image.new("RGBA",
                          (medallion_r * 2, medallion_r * 2),
                          (0, 0, 0, 0))
        ImageDraw.Draw(inner).ellipse(
            (0, 0, medallion_r * 2, medallion_r * 2),
            fill=_hex_to_rgba(tint, 35),
        )
        canvas.alpha_composite(inner, (mx - medallion_r,
                                       my - medallion_r))
        # Region name (bumped from map_region 42pt -> 56pt for
        # presence inside the larger medallion)
        draw_text(canvas, mx, my - 50,
                  region["name"], style_name="map_region_lg")
        # Subtitle (bumped from 22pt -> 28pt for legibility)
        draw_text(canvas, mx, my + 30,
                  region["subtitle"], style_name="map_landmark_lg")

    # Landmarks for each region — under the corresponding medallion
    for i, region in enumerate(REGIONS):
        mx, my = positions[i]
        ly = my + medallion_r + 70
        for landmark in region["landmarks"]:
            draw_text(canvas, mx, ly, "·  " + landmark + "  ·",
                      style_name="map_landmark_lg")
            ly += 44

    # Phase 5c — anchor 1 character thumbnail per region. Kids match
    # characters to places visually; without a thumbnail anchor the
    # map teaches geography but not character-place pairing.
    chars = by_num()
    region_heroes = [
        (1,  positions[0]),    # Soft Dumpling -> Pudding Hills
        (17, positions[1]),    # Goo Ball -> Goo Coast
        (33, positions[2]),    # Blushy Bun Bunny -> Moonlit Hollow
    ]
    thumb_w = 180
    thumb_h = int(thumb_w * 1.3)
    for num, (mx, my) in region_heroes:
        char = chars[num]
        # Place thumbnail to the side of the medallion so it doesn't
        # cover the region name. Goo Coast (center, lower) gets its
        # thumbnail to the right; left + right medallions get
        # thumbnails toward the page edge.
        if mx < PAGE_W // 2:           # left medallion -> outside left
            tx = mx - medallion_r - thumb_w - 30
        elif mx > PAGE_W // 2:          # right medallion -> outside right
            tx = mx + medallion_r + 30
        else:                           # center medallion -> off to right
            tx = mx + medallion_r + 40
        ty = my - thumb_h // 2
        draw_card_frame(
            canvas, char.card_path,
            tx, ty, thumb_w, thumb_h,
            rarity=char.rarity, pack=char.pack,
            background="transparent",
        )

    _folio(canvas, 4)
    _vignette(canvas, intensity=0.30)
    return canvas


# ---------------------------------------------------------------------------
# T4 — Pack Index Plinth (pages 5-6)
# ---------------------------------------------------------------------------

def T4_pack_index_left() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    cx = PAGE_W // 2
    cy = PAGE_H // 2

    draw_text(canvas, cx, cy - 380,
              "Three packs.\nThree worlds.\nForty-eight friends.",
              style_name="title", max_width=PAGE_W - SAFE * 2)

    block_y = cy + 50
    _dotted_rule(canvas, cx - 350, block_y, cx + 350, PALETTE["rose_dust"])
    block_y += 60

    draw_text(canvas, cx, block_y,
              "Every squishy belongs to a pack.\n"
              "Every pack has its own kind of squish.",
              style_name="lede", max_width=PAGE_W - SAFE * 2)

    block_y += 280
    draw_text(canvas, cx, block_y,
              "Can you spot the bunny? The ghost? The goo?",
              style_name="flavor", max_width=PAGE_W - SAFE * 2)

    _folio(canvas, 5)
    _vignette(canvas, intensity=0.30)
    return canvas


def T4_pack_index_right() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    chars = by_num()

    # 3 pack sections, each with a centered text block above 2
    # cards. Pre-fix this template had 9 cards in tinted plinth
    # panels with the headers tucked into a left text column —
    # cream-on-cream blended into the warm card art and the cards
    # crowded each other. Post-fix: tint the pack name itself so it
    # pops against the dark plum bg, keep the blurb cream, drop to
    # 2 hero cards per pack, lose the plinth panel entirely.
    sections = [
        ("SQUISHY FOODS",         "warm and sweet",
         PALETTE["lime"],         "Squishy Foods",
         [1, 2]),                 # Soft Dumpling + Jelly Bun
        ("GOO & FIDGETS",         "glossy and bouncy",
         PALETTE["jelly_blue"],   "Goo & Fidgets",
         [17, 18]),                # Goo Ball + Bubble Blob
        ("CREEPY-CUTE CREATURES", "spooky and sweet",
         PALETTE["lavender"],      "Creepy-Cute Creatures",
         [33, 34]),                # Blushy Bun Bunny + Squish Bat
    ]

    section_h = (PAGE_H - SAFE * 2) // 3
    cx = PAGE_W // 2

    for i, (name, blurb, tint, pack, nums) in enumerate(sections):
        sy = SAFE + i * section_h

        # Pack name — tinted so it stands out against the dark bg
        # rather than blending with the cream/pink card details.
        # Custom inline draw because the style sheet's char_name_lg
        # is locked to cream; we want pack tint just for this row.
        from PIL import ImageDraw as _ID
        pack_font = font("display", 78)
        bbox = _ID.Draw(canvas).textbbox((0, 0), name, font=pack_font)
        name_w = bbox[2] - bbox[0]
        name_x = cx - name_w // 2
        name_y = sy + 30
        # Soft drop shadow + fill in pack tint
        d = _ID.Draw(canvas)
        d.text((name_x + 4, name_y + 4), name, font=pack_font,
               fill=(0, 0, 0, 130))
        d.text((name_x, name_y), name, font=pack_font,
               fill=_hex_to_rgba(tint, 255))

        # Blurb (italic cream) below the pack name
        draw_text(canvas, cx, name_y + 130, blurb,
                  style_name="tagline",
                  max_width=PAGE_W - SAFE * 2)

        # 2 cards centered in the row, generous gap between them.
        # Card size sized to fit a 3-section vertical stack: at
        # 380x494 each, two cards + name + blurb + breathing room
        # leaves ~50 px between sections so headers don't collide
        # with cards from the row above.
        card_w = 380
        card_h = int(card_w * 1.3)
        gap = 100
        total_w = card_w * 2 + gap
        cards_x_start = cx - total_w // 2
        cards_y = name_y + 220
        for j, num in enumerate(nums):
            char = chars[num]
            draw_card_frame(
                canvas, char.card_path,
                cards_x_start + j * (card_w + gap),
                cards_y, card_w, card_h,
                rarity=char.rarity, pack=pack,
                background="transparent",
            )

    _folio(canvas, 6)
    _vignette(canvas, intensity=0.25)
    return canvas


# ---------------------------------------------------------------------------
# T5 — Pack Portal (pages 7, 15, 23)
# ---------------------------------------------------------------------------

PACK_PORTAL_DATA = {
    "Squishy Foods": {
        "letter": "S",
        "title": "QUISHY FOODS.",
        "tagline": "The softest snacks. The sweetest squishies.",
        "scribe": "The Squishkeeper writes from the Pudding Hills…",
    },
    "Goo & Fidgets": {
        "letter": "G",
        "title": "OO & FIDGETS.",
        "tagline": "Glossy. Bouncy. Made for squishing.",
        "scribe": "The Squishkeeper writes from the Goo Coast…",
    },
    "Creepy-Cute Creatures": {
        "letter": "C",
        "title": "REEPY-CUTE CREATURES.",
        "tagline": "Spooky and sweet. Cuddly, never scary.",
        "scribe": "The Squishkeeper writes from Moonlit Hollow…",
    },
}


def T5_pack_portal(pack: str, page_num: int) -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    paint_pack_background(canvas, 0, 0, PAGE_W, PAGE_H,
                          pack=pack, with_texture=True,
                          texture_alpha=36)
    data = PACK_PORTAL_DATA[pack]
    tint = PACK_TINTS[pack]

    # Drop-cap-style letter at very large size with the rest of the
    # word inline. We render the cap separately so it can be larger.
    cap_size = 480
    cap_font = font("display", cap_size)
    cap_x = SAFE + 60
    cap_y = PAGE_H // 2 - 240
    draw = ImageDraw.Draw(canvas)
    # Cap shadow
    draw.text((cap_x + 8, cap_y + 8), data["letter"],
              font=cap_font,
              fill=(0, 0, 0, 120))
    draw.text((cap_x, cap_y), data["letter"],
              font=cap_font,
              fill=_hex_to_rgba(tint, 255))

    # Rest of the title runs inline
    rest_x = cap_x + int(cap_font.getlength(data["letter"])) + 30
    rest_y = cap_y + cap_size - 220
    rest_font = font("display", 220)
    draw.text((rest_x + 4, rest_y + 4), data["title"],
              font=rest_font, fill=(0, 0, 0, 100))
    draw.text((rest_x, rest_y), data["title"],
              font=rest_font, fill=_hex_to_rgba(PALETTE["soft_white"]))

    # Tagline
    tag_y = cap_y + cap_size + 60
    draw_text(canvas, SAFE + 60, tag_y,
              data["tagline"], style_name="char_name_lg")

    # Scribe line in script
    scribe_y = tag_y + 200
    draw_text(canvas, SAFE + 60, scribe_y,
              data["scribe"], style_name="flavor")

    # Decorative pack-tinted corner ornament (sparkle cluster)
    _scatter_sparkles(
        canvas, count=24,
        colors=[tint, PALETTE["cream"]],
        seed=hash(pack) & 0xFFFF,
        sizes=(4, 12),
        alpha=180,
    )
    _stamp_pack_corners(canvas, pack, size=220, alpha=200)

    _folio(canvas, page_num, pack_color=tint)
    _vignette(canvas, intensity=0.40)
    return canvas


# ---------------------------------------------------------------------------
# T6 — Pack Scene (pages 8, 16, 24)
# ---------------------------------------------------------------------------

PACK_SCENE_DATA = {
    "Squishy Foods": {
        "title": "Welcome to the Pudding Hills.",
        "body": "The clouds here are made of sprinkles.\n"
                "The rivers run with syrup.\n"
                "Everything bounces a little.",
        "prompt": "Count the sprinkle clouds. How many did you find?",
        "scatter_chars": [1, 2, 3, 5, 11, 13],
    },
    "Goo & Fidgets": {
        "title": "Welcome to the Goo Coast.",
        "body": "The shore is jelly.\n"
                "The waves are gentle.\n"
                "Every footprint goes sploink.",
        "prompt": "Goo goes squish, splat, wobble. Can you say all three?",
        "scatter_chars": [17, 18, 19, 20, 25, 30],
    },
    "Creepy-Cute Creatures": {
        "title": "Welcome to Moonlit Hollow.",
        "body": "Here the moon is a nightlight.\n"
                "The shadows wave hello.\n"
                "Every squishy in this pack is more cuddly than creepy.",
        "prompt": "Spooky or sweet? Look at every page and decide.",
        "scatter_chars": [33, 34, 35, 39, 41, 43],
    },
}


def T6_pack_scene(pack: str, page_num: int) -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])
    # Phase 5b — texture opacity bumped to 64 (was 48). T6 is the
    # most "scene"-like page; the texture should clearly carry the
    # pack identity rather than be a faint wash.
    paint_pack_background(canvas, 0, 0, PAGE_W, PAGE_H,
                          pack=pack, with_texture=True,
                          texture_alpha=64)
    data = PACK_SCENE_DATA[pack]
    tint = PACK_TINTS[pack]
    chars = by_num()

    # Scatter card thumbnails at varying sizes / depths across the
    # bottom 3/5 of the page so it reads as a "scene" populated by
    # squishies. The text block sits above.
    rng_seed = hash(pack) & 0xFFFF
    import random
    rng = random.Random(rng_seed)
    scatter_chars = data["scatter_chars"]
    char_thumb_sizes = [380, 320, 300, 280, 260, 240]
    scatter_y_start = PAGE_H // 2 + 80
    scatter_y_end = PAGE_H - SAFE - 100

    for idx, num in enumerate(scatter_chars):
        char = chars[num]
        size = char_thumb_sizes[idx % len(char_thumb_sizes)]
        x = SAFE + rng.randint(0, PAGE_W - SAFE * 2 - size)
        y = rng.randint(scatter_y_start, scatter_y_end - size)
        # Soft tinted halo behind each scattered card
        halo = _glow_layer(size + 80, size + 80,
                           tint, radius=40, alpha=0.20)
        canvas.alpha_composite(halo, (x - 40, y - 40))
        draw_card_frame(
            canvas, char.card_path,
            x, y, size, int(size * 1.25),
            rarity=char.rarity, pack=pack,
            background="transparent",
        )

    # Text block on a parchment plate so the pack-scene title +
    # body read like a real picture-book "welcome to" header card,
    # not a flat website hero. Pack-tinted stroke matches the
    # gradient world below.
    text_w = PAGE_W - SAFE * 2 - 200
    plate_h = 380
    plate_y = SAFE + 100
    plate = Image.new("RGBA", (text_w, plate_h), (0, 0, 0, 0))
    ImageDraw.Draw(plate).rounded_rectangle(
        (0, 0, text_w, plate_h),
        radius=22,
        fill=_hex_to_rgba(PALETTE["parchment"], 240),
        outline=_hex_to_rgba(tint, 220),
        width=3,
    )
    canvas.alpha_composite(plate, (SAFE + 100, plate_y))

    block_y = plate_y + 40
    block_y = draw_text(canvas, SAFE + 100, block_y,
                        data["title"],
                        style_name="char_name_lg_dark",
                        max_width=text_w)
    block_y += 30
    draw_text(canvas, SAFE + 100, block_y,
              data["body"], style_name="field_value_dark",
              max_width=text_w)

    # Engagement prompt at the bottom
    draw_text(canvas, PAGE_W // 2, PAGE_H - SAFE - 80,
              data["prompt"], style_name="flavor",
              max_width=PAGE_W - SAFE * 2)

    _stamp_pack_corners(canvas, pack, size=200, alpha=180)
    _folio(canvas, page_num, pack_color=tint)
    _vignette(canvas, intensity=0.30)
    return canvas


# ---------------------------------------------------------------------------
# T8 — Featured single character (most pages)
# ---------------------------------------------------------------------------

def T8_featured(num: int, page_num: int) -> Image.Image:
    char = by_num()[num]
    canvas = _new_canvas(PALETTE["bg"])
    # 5b: pack texture opacity 20 -> 40 so the sprinkles / bubbles /
    # moondust actually announce the pack at-a-glance instead of
    # whispering. The whole point of the per-pack signatures is that
    # a child can tell "I'm in the Goo pack now" without reading.
    paint_pack_background(canvas, 0, 0, PAGE_W, PAGE_H,
                          pack=char.pack, with_texture=True,
                          texture_alpha=40)
    tint = PACK_TINTS[char.pack]

    # Card hero on the left
    card_w = 1000
    card_h = 1300
    card_x = SAFE + 80
    card_y = (PAGE_H - card_h) // 2
    draw_card_frame(
        canvas, char.card_path,
        card_x, card_y, card_w, card_h,
        rarity=char.rarity, pack=char.pack,
    )

    # Field-guide entry on the right, set on a parchment plate so the
    # serif body type reads as "real children's hardcover" instead of
    # cream-on-plum digital. The plate is sized to the text column,
    # rounded corners, low-alpha pack-tinted stroke. UI agent flagged
    # PALETTE["parchment"] as defined-but-unused; this is its first
    # production use.
    text_x = card_x + card_w + 120
    text_w = PAGE_W - SAFE - 80 - text_x
    plate_top = card_y + 20
    plate_h = card_h - 40
    plate = Image.new("RGBA", (text_w + 100, plate_h), (0, 0, 0, 0))
    ImageDraw.Draw(plate).rounded_rectangle(
        (0, 0, text_w + 100, plate_h),
        radius=18,
        fill=_hex_to_rgba(PALETTE["parchment"], 235),
        outline=_hex_to_rgba(tint, 200),
        width=2,
    )
    canvas.alpha_composite(plate, (text_x - 50, plate_top))

    cursor_y = card_y + 40

    # Header: name + pack chip + rarity stars
    cursor_y = draw_text(canvas, text_x, cursor_y, char.name,
                         style_name="char_name_lg_dark",
                         max_width=text_w)
    cursor_y += 10

    # Pack + rarity row. Draw stars as polygons (Fredoka doesn't
    # have the Unicode ★ glyph) inline with the text.
    star_count = {"common": 1, "rare": 2, "epic": 3, "mythic": 4}[char.rarity]
    pack_label = f"{char.pack}  ·  "
    rarity_word = f"  ·  {char.rarity}"
    label_w = measure_line(pack_label, style("rarity_stars_dark"))
    star_w = star_count * 30 + (star_count - 1) * 6
    draw_text(canvas, text_x, cursor_y, pack_label,
              style_name="rarity_stars_dark")
    _draw_star_row(canvas, text_x + label_w, cursor_y + 6,
                   star_count, size=24, color_hex=PALETTE["gold"])
    draw_text(canvas, text_x + label_w + star_w, cursor_y,
              rarity_word, style_name="rarity_stars_dark")
    cursor_y += 50

    _dotted_rule(canvas, text_x, cursor_y,
                 text_x + text_w, tint, alpha=180)
    cursor_y += 50

    # Squishkeeper says (narrator italic) — dark on parchment
    if char.keeper_says:
        draw_text(canvas, text_x, cursor_y,
                  "Squishkeeper says…",
                  style_name="field_label_dark",
                  max_width=text_w)
        cursor_y += 32
        cursor_y = draw_text(canvas, text_x, cursor_y,
                             '"' + char.keeper_says + '"',
                             style_name="narrator_dark",
                             max_width=text_w)
        cursor_y += 40

    # First spotted at
    if char.location:
        draw_text(canvas, text_x, cursor_y, "FIRST SPOTTED AT",
                  style_name="field_label_dark", max_width=text_w)
        cursor_y += 32
        cursor_y = draw_text(canvas, text_x, cursor_y,
                             char.location.rstrip("."),
                             style_name="field_value_dark",
                             max_width=text_w)
        cursor_y += 36

    # Signature squish
    if char.signature_squish:
        draw_text(canvas, text_x, cursor_y, "SIGNATURE SQUISH",
                  style_name="field_label_dark", max_width=text_w)
        cursor_y += 32
        cursor_y = draw_text(canvas, text_x, cursor_y,
                             char.signature_squish,
                             style_name="field_value_dark",
                             max_width=text_w)
        cursor_y += 36

    # Pack-mate
    if char.pack_mate:
        draw_text(canvas, text_x, cursor_y, "PACK-MATE",
                  style_name="field_label_dark", max_width=text_w)
        cursor_y += 32
        cursor_y = draw_text(canvas, text_x, cursor_y,
                             char.pack_mate,
                             style_name="field_value_dark",
                             max_width=text_w)

    # Flavor pull quote inside the parchment plate, near the bottom
    if char.flavor:
        flavor_y = plate_top + plate_h - 140
        draw_text(canvas, text_x, flavor_y,
                  char.flavor,
                  style_name="flavor", max_width=text_w)

    _stamp_pack_corners(canvas, char.pack, size=180, alpha=160)
    _folio(canvas, page_num, pack_color=tint)
    _vignette(canvas, intensity=0.30)
    return canvas


# ---------------------------------------------------------------------------
# T9 — Premium duo (pages 13, 21, 29)
# ---------------------------------------------------------------------------

T9_HEADERS = {
    "Squishy Foods":          "SHINY, SPARKLY, SUPER RARE",
    "Goo & Fidgets":          "THE BRIGHTEST BOUNCES",
    "Creepy-Cute Creatures":  "WHEN THE MOON WAKES UP",
}


def T9_premium_duo(num_a: int, num_b: int, page_num: int,
                    mid_pack_note: str | None = None) -> Image.Image:
    a = by_num()[num_a]
    b = by_num()[num_b]
    pack = a.pack
    canvas = _new_canvas(PALETTE["bg"])
    # Phase 5b — texture 28 -> 44 to announce pack identity at-a-
    # glance on every spread, not just the scene page.
    paint_pack_background(canvas, 0, 0, PAGE_W, PAGE_H,
                          pack=pack, with_texture=True,
                          texture_alpha=44)
    tint = PACK_TINTS[pack]

    # Header band at top
    draw_text(canvas, PAGE_W // 2, SAFE + 40,
              T9_HEADERS[pack], style_name="title")
    _dotted_rule(canvas, PAGE_W // 2 - 400, SAFE + 200,
                 PAGE_W // 2 + 400, PALETTE["rose_dust"])
    _scatter_sparkles(canvas, count=30,
                      colors=[tint, PALETTE["cream"]],
                      seed=page_num, sizes=(3, 10), alpha=160)

    # Two stacked entries — top half + bottom half. Pre-fix the card
    # was sized to entry_h with a 1.3 aspect ratio, which made it
    # taller than the entry itself and spilled into the header above
    # AND off the bottom of the page. Now the card height is sized
    # to FIT in the entry with breathing room, and the width is
    # derived from the 0.769 aspect (card art is 1086x1408 ≈ 0.77).
    entry_h = (PAGE_H - SAFE - 280) // 2 - 30
    entry_w = PAGE_W - SAFE * 2

    for i, char in enumerate((a, b)):
        ey = SAFE + 280 + i * (entry_h + 60)

        # Card sized to fit the entry with 50 px padding above and
        # below. Width derived from the card-art aspect ratio so the
        # frame doesn't add letterbox gaps.
        card_h = entry_h - 100
        card_w = int(card_h / 1.3)
        card_x = SAFE + 40
        card_y = ey + (entry_h - card_h) // 2
        draw_card_frame(
            canvas, char.card_path,
            card_x, card_y, card_w, card_h,
            rarity=char.rarity, pack=pack,
            background="transparent",
        )

        # Text on the right
        text_x = card_x + card_w + 80
        text_w = PAGE_W - SAFE - 40 - text_x
        ty = ey + 30

        ty = draw_text(canvas, text_x, ty, char.name,
                       style_name="char_name_lg", max_width=text_w)
        ty += 8
        star_count = {"common": 1, "rare": 2, "epic": 3,
                      "mythic": 4}[char.rarity]
        pack_label = f"{pack}  ·  "
        label_w = measure_line(pack_label, style("rarity_stars"))
        draw_text(canvas, text_x, ty, pack_label,
                  style_name="rarity_stars")
        _draw_star_row(canvas, text_x + label_w, ty + 6,
                       star_count, size=24,
                       color_hex=PALETTE["cream"])
        ty += 50

        if char.keeper_says:
            ty = draw_text(canvas, text_x, ty,
                           '"' + char.keeper_says + '"',
                           style_name="narrator", max_width=text_w)
            ty += 28
        if char.location:
            ty = draw_text(canvas, text_x, ty,
                           f"First spotted at {char.location}",
                           style_name="body", max_width=text_w)
            ty += 14
        if char.signature_squish:
            ty = draw_text(canvas, text_x, ty,
                           "Signature squish — " + char.signature_squish,
                           style_name="body", max_width=text_w)

    # Mid-pack rest beat (Phase 5b). One of the three packs gets a
    # single italic line per pack from the Squishkeeper to break
    # the long T9 run. Bottom-right corner, in the Squishkeeper's
    # accent script so it reads as a quiet aside, not chrome.
    if mid_pack_note:
        draw_text(canvas, PAGE_W // 2,
                  PAGE_H - SAFE - 90,
                  mid_pack_note,
                  style_name="flavor",
                  max_width=PAGE_W - SAFE * 2)

    _stamp_pack_corners(canvas, pack, size=180, alpha=160)
    _folio(canvas, page_num, pack_color=tint)
    _vignette(canvas, intensity=0.35)
    return canvas


# ---------------------------------------------------------------------------
# T10 — Mythic Finale (pages 14, 22, 30)
# ---------------------------------------------------------------------------

# Per ELEVATION_PLAN, mythic copy is fairy-tale paragraphs not
# bullet schema. Pull the locked manuscript versions verbatim.
MYTHIC_COPY = {
    16: {  # Celestial Dumpling Core
        "headline": "CELESTIAL DUMPLING CORE",
        "tagline": "Squishy Foods  ·  mythic",
        "tale": ("Long ago, before the stars knew how to glow,\n"
                 "they watched a tiny dumpling shine in the dark."),
        "stinger": "That is how they learned.",
        "guide": "Sell-ESS-tee-al. Say it slow. Then say it loud.",
    },
    32: {  # Singularity Goo Core
        "headline": "SINGULARITY GOO CORE",
        "tagline": "Goo & Fidgets  ·  mythic",
        "tale": ("So heavy the air bends around it.\n"
                 "So strange that gravity tips its hat as it walks by."),
        "stinger": "Stand still. Can you feel the pull?",
        "guide": None,
    },
    48: {  # Mythic Plush Familiar
        "headline": "MYTHIC PLUSH FAMILIAR",
        "tagline": "Creepy-Cute  ·  mythic",
        "tale": ("When a squishy gets lost,\n"
                 "a soft pawprint shows up in the dust.\n"
                 "Then another. Then another."),
        "stinger": "Someone is always coming back for them.",
        # Each mythic now has its own closing flourish so the third
        # mythic doesn't look identical to the first two. #16 has a
        # pronunciation guide; #32 has a sense prompt embedded in
        # the stinger; #48 gets a "find the trail" prompt.
        "guide": "Look back through the book. Did you spot any pawprints?",
    },
}


def T10_mythic_finale(num: int, page_num: int) -> Image.Image:
    char = by_num()[num]
    copy = MYTHIC_COPY[num]
    canvas = _new_canvas(PALETTE["velvet"])  # premium velvet base

    # Starfield scatter — denser than the regular sparkle scatter
    _scatter_sparkles(canvas, count=180,
                      colors=[PALETTE["cream"], PALETTE["gold_hi"],
                              PALETTE["soft_white"]],
                      seed=num, sizes=(2, 6), alpha=180)
    _scatter_sparkles(canvas, count=24,
                      colors=[PALETTE["gold"]],
                      seed=num + 999, sizes=(8, 16), alpha=220)

    # Gold rule top + bottom
    _dotted_rule(canvas, SAFE + 120, SAFE + 100,
                 PAGE_W - SAFE - 120,
                 PALETTE["gold"], dot_size=6, gap=18, alpha=240)
    _dotted_rule(canvas, SAFE + 120, PAGE_H - SAFE - 100,
                 PAGE_W - SAFE - 120,
                 PALETTE["gold"], dot_size=6, gap=18, alpha=240)

    # Headline + tagline + 4 gold stars
    draw_text(canvas, PAGE_W // 2, SAFE + 200,
              copy["headline"], style_name="char_name_mythic",
              max_width=PAGE_W - SAFE * 2)
    draw_text(canvas, PAGE_W // 2, SAFE + 340,
              copy["tagline"], style_name="rarity_stars",
              max_width=PAGE_W - SAFE * 2)
    # Four gold stars centered under the tagline — graphically
    # rendered so they're legible regardless of font glyph coverage.
    star_size = 30
    star_gap = 12
    star_row_w = star_size * 4 + star_gap * 3
    _draw_star_row(canvas,
                   (PAGE_W - star_row_w) // 2,
                   SAFE + 400,
                   4, size=star_size, gap=star_gap,
                   color_hex=PALETTE["gold"])

    # The hero card — large, centered, with a heavy mythic glow
    card_w = 900
    card_h = 1200
    card_x = (PAGE_W - card_w) // 2
    card_y = SAFE + 480
    # Massive halo behind the card
    halo = _glow_layer(card_w + 400, card_h + 400,
                       PALETTE["gold_hi"], radius=180, alpha=0.50)
    canvas.alpha_composite(halo, (card_x - 200, card_y - 200))
    draw_card_frame(
        canvas, char.card_path,
        card_x, card_y, card_w, card_h,
        rarity=char.rarity, pack=char.pack,
    )

    # Fairy-tale paragraph below the card
    tale_y = card_y + card_h + 80
    draw_text(canvas, PAGE_W // 2, tale_y,
              copy["tale"], style_name="lede",
              max_width=PAGE_W - SAFE * 2)
    # Hand-script stinger
    stinger_y = PAGE_H - SAFE - 320
    draw_text(canvas, PAGE_W // 2, stinger_y,
              copy["stinger"], style_name="flavor_lg",
              max_width=PAGE_W - SAFE * 2)

    # Optional pronunciation guide (only mythic 16 has one)
    if copy["guide"]:
        draw_text(canvas, PAGE_W // 2, PAGE_H - SAFE - 180,
                  copy["guide"], style_name="tagline",
                  max_width=PAGE_W - SAFE * 2)

    _folio(canvas, page_num, pack_color=PALETTE["gold"])
    return canvas


# ---------------------------------------------------------------------------
# Page 31 — The Other Squishies gallery (27 thumbnails)
# ---------------------------------------------------------------------------

def T_gallery() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])

    # Title
    draw_text(canvas, PAGE_W // 2, SAFE + 60,
              "THE OTHER SQUISHIES", style_name="title")
    draw_text(canvas, PAGE_W // 2, SAFE + 220,
              "Twenty-seven more friends live in the Squishy World.\n"
              "The Squishkeeper has written about them too —\n"
              "but those pages are saved for another book.\n\n"
              "For now, here are their faces.",
              style_name="tagline", max_width=PAGE_W - SAFE * 2)

    # 3-column x 9-row thumbnail grid
    gallery = gallery_characters()
    cols = 3
    rows = 9
    grid_top = SAFE + 600
    grid_h = PAGE_H - SAFE - grid_top - 100
    cell_w = (PAGE_W - SAFE * 2) // cols
    cell_h = grid_h // rows
    thumb_w = int(cell_w * 0.62)
    thumb_h = int(thumb_w * 1.3)

    for i, char in enumerate(gallery):
        col = i % cols
        row = i // cols
        cx = SAFE + col * cell_w + (cell_w - thumb_w) // 2
        cy = grid_top + row * cell_h + (cell_h - thumb_h) // 2 - 10
        draw_card_frame(
            canvas, char.card_path,
            cx, cy, thumb_w, thumb_h,
            rarity=char.rarity, pack=char.pack,
            background="transparent",
        )
        # Name caption below thumbnail
        draw_text(canvas, cx + thumb_w // 2, cy + thumb_h + 6,
                  char.name, style_name="map_landmark")

    _folio(canvas, 31)
    _vignette(canvas, intensity=0.25)
    return canvas


# ---------------------------------------------------------------------------
# Page 32 — Squishy Tracker (48-cell checklist)
# ---------------------------------------------------------------------------

def T_tracker() -> Image.Image:
    canvas = _new_canvas(PALETTE["bg"])

    draw_text(canvas, PAGE_W // 2, SAFE + 60,
              "THE SQUISHY TRACKER", style_name="title")
    # Phase 5b — one verb only ("star your favorites"). Earlier
    # version had both a checkbox AND a star which was one verb too
    # many for a 5-year-old. Picking star because it's more
    # emotional than ownership ("which is your favorite?" beats
    # "have you met").
    draw_text(canvas, PAGE_W // 2, SAFE + 220,
              "Star the squishies you love most.\n"
              "Find a friend you might have missed.",
              style_name="tagline", max_width=PAGE_W - SAFE * 2)

    # 48 cells in a 6 x 8 grid
    chars = sorted(
        [by_num()[n] for n in range(1, 49)], key=lambda c: c.num,
    )
    cols = 6
    rows = 8
    grid_top = SAFE + 480
    grid_bottom = PAGE_H - SAFE - 240
    cell_w = (PAGE_W - SAFE * 2) // cols
    cell_h = (grid_bottom - grid_top) // rows

    for i, char in enumerate(chars):
        col = i % cols
        row = i // cols
        x = SAFE + col * cell_w + 10
        y = grid_top + row * cell_h + 10
        w = cell_w - 20
        h = cell_h - 20

        # Cell border tinted by pack
        tint = PACK_TINTS[char.pack]
        cell = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(cell).rounded_rectangle(
            (0, 0, w, h),
            radius=12,
            fill=_hex_to_rgba(PALETTE["bg"], 200),
            outline=_hex_to_rgba(tint, 180),
            width=2,
        )
        canvas.alpha_composite(cell, (x, y))

        # Mini card thumbnail in the cell
        thumb_w = w - 16
        thumb_h = int(thumb_w * 1.0)
        thumb_x = x + 8
        thumb_y = y + 8
        draw_card_frame(
            canvas, char.card_path,
            thumb_x, thumb_y, thumb_w, thumb_h,
            rarity=char.rarity, pack=char.pack,
            background="transparent",
        )
        # Single star outline at the bottom-center of each cell.
        # One verb (star) instead of the previous checkbox-AND-star
        # combo so a 5-year-old has a clean action.
        sx = x + w // 2
        sy = y + h - 24
        draw = ImageDraw.Draw(canvas)
        draw.polygon(
            [(sx, sy - 16), (sx + 5, sy - 5),
             (sx + 16, sy - 5), (sx + 7, sy + 2),
             (sx + 10, sy + 14), (sx, sy + 7),
             (sx - 10, sy + 14), (sx - 7, sy + 2),
             (sx - 16, sy - 5), (sx - 5, sy - 5)],
            outline=_hex_to_rgba(PALETTE["cream"], 240),
            width=3,
        )

    # Closing line
    draw_text(canvas, PAGE_W // 2, PAGE_H - SAFE - 160,
              "48 squishies. Three packs.\nOne soft, silly, sparkly world.",
              style_name="tagline", max_width=PAGE_W - SAFE * 2)
    draw_text(canvas, PAGE_W // 2, PAGE_H - SAFE - 60,
              "See you on the next bounce.\n— The Squishkeeper",
              style_name="flavor", max_width=PAGE_W - SAFE * 2)

    _folio(canvas, 32)
    return canvas


__all__ = [
    "PAGE_H",
    "PAGE_W",
    "T1_title",
    "T2_imprint",
    "T3_narrator",
    "T4_pack_index_left",
    "T4_pack_index_right",
    "T5_pack_portal",
    "T6_pack_scene",
    "T8_featured",
    "T9_premium_duo",
    "T10_mythic_finale",
    "T_gallery",
    "T_map",
    "T_tracker",
]
