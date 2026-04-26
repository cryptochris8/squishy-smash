"""
Phase-2 visual primitives for the book pipeline.

Two public functions:

    draw_card_frame(canvas, image_path, x, y, w, h, *, rarity, pack)
        Draws a card image inside a rarity- and pack-aware frame.
        Replaces the bare `draw_card()` in image_helpers.py for the
        T7/T8/T9/T10 character templates Phase 3 will introduce.

    paint_pack_background(canvas, x, y, w, h, *, pack, with_texture=True)
        Fills a rectangle with the per-pack vertical gradient and
        optionally overlays the baked pack texture at low alpha.
        Phase 3 will use this for the T5 portal + T6 scene spreads.

Both helpers are pure-Pillow (no ReportLab); they paint onto a
Pillow `Image` (the canvas argument is the image, not a draw
context). The build_*.py scripts that currently use ReportLab
canvases will compose Pillow images at the page level and stamp
them onto the PDF page. That kept the original pipeline simple but
ties us to ReportLab; Phase 2 walks away from that for any layout
that needs alpha compositing or gradients.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from config import (
    GLOW,
    PACK_BG_GRADIENT,
    PACK_TEXTURE,
    PACK_TINTS,
    PALETTE,
    RARITY_RING,
    SHADOW,
)
from image_helpers import fit_box


def _hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def _hex_to_rgba(hex_str: str, alpha: int = 255) -> tuple[int, int, int, int]:
    return (*_hex_to_rgb(hex_str), alpha)


def _vertical_gradient(width: int, height: int,
                       top_hex: str, bottom_hex: str) -> Image.Image:
    """RGB gradient column. Generates a single 1xH column then stretches
    horizontally — far cheaper than per-pixel per-column work."""
    top = _hex_to_rgb(top_hex)
    bottom = _hex_to_rgb(bottom_hex)
    grad = Image.new("RGB", (1, height))
    for y in range(height):
        t = y / max(height - 1, 1)
        grad.putpixel((0, y), (
            round(top[0] * (1 - t) + bottom[0] * t),
            round(top[1] * (1 - t) + bottom[1] * t),
            round(top[2] * (1 - t) + bottom[2] * t),
        ))
    return grad.resize((width, height))


def paint_pack_background(canvas: Image.Image,
                          x: int, y: int, w: int, h: int,
                          *,
                          pack: str,
                          with_texture: bool = True,
                          texture_alpha: int = 24) -> None:
    """Fill `canvas` rect with the per-pack gradient and optionally
    overlay the baked texture at `texture_alpha` (0-255).

    `texture_alpha=24` ≈ 9 % opacity — the audit's recommendation
    for "subtle but present" coverage. Tune up to 40 for premium
    spreads, down to 12 for character spreads where the card art
    shouldn't compete with the texture.
    """
    if pack not in PACK_BG_GRADIENT:
        raise ValueError(
            f"Unknown pack {pack!r}; "
            f"expected one of {sorted(PACK_BG_GRADIENT)}")

    top_hex, bottom_hex = PACK_BG_GRADIENT[pack]
    grad = _vertical_gradient(w, h, top_hex, bottom_hex).convert("RGBA")
    canvas.paste(grad, (x, y))

    if with_texture and pack in PACK_TEXTURE:
        tex_path = PACK_TEXTURE[pack]
        if Path(tex_path).exists():
            tex = Image.open(tex_path).convert("RGBA")
            # Tile to fit; the texture file is 1024x1024 so anything
            # bigger needs repetition.
            tiled = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            for ty in range(0, h, tex.height):
                for tx in range(0, w, tex.width):
                    tiled.paste(tex, (tx, ty), tex)
            # Re-alpha the whole tiled image to the target opacity.
            r, g, b, a = tiled.split()
            a = a.point(lambda v, k=texture_alpha: int(v * (k / 255)))
            tiled = Image.merge("RGBA", (r, g, b, a))
            canvas.alpha_composite(tiled, (x, y))


def _glow_layer(width: int, height: int,
                color_hex: str, radius: int,
                alpha: float) -> Image.Image:
    """Build a soft halo behind a card. Returns an RGBA image the same
    size as `canvas`; transparent everywhere except a glowing rounded
    rectangle.
    """
    layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    a = int(alpha * 255)
    # Inset by `radius` so the blur expands back to the original edge.
    draw.rounded_rectangle(
        (radius, radius, width - radius, height - radius),
        radius=max(8, radius // 2),
        fill=_hex_to_rgba(color_hex, a),
    )
    return layer.filter(ImageFilter.GaussianBlur(radius=radius / 2))


def _drop_shadow_layer(width: int, height: int,
                       offset_x: int, offset_y: int,
                       blur: int, alpha: float) -> Image.Image:
    """A translucent black rounded-rect, offset and blurred. Pasted
    behind the card panel for that "lifted off the page" feel."""
    layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    a = int(alpha * 255)
    draw.rounded_rectangle(
        (blur + offset_x, blur + offset_y,
         width - blur + offset_x, height - blur + offset_y),
        radius=14,
        fill=(0, 0, 0, a),
    )
    return layer.filter(ImageFilter.GaussianBlur(radius=blur / 2))


def draw_card_frame(canvas: Image.Image,
                    image_path: Path,
                    x: int, y: int, w: int, h: int,
                    *,
                    rarity: str,
                    pack: str,
                    background: str = "panel") -> None:
    """Composite a framed card onto `canvas` at (x, y, w, h).

    Layers (back to front):
      1. Drop shadow under the panel
      2. Pack-tinted panel background (rounded rect, faint pack tint)
      3. Rarity-tier halo glow (rare+, behind the card art)
      4. Card image, fitted to the panel's interior
      5. Rarity ring border (rounded-rect outline in the rarity edge color)

    Args:
        rarity: "common" | "rare" | "epic" | "mythic". Drives the
            ring color + glow. Common = no glow.
        pack: Pack name. Drives the panel tint via PACK_TINTS.
        background: "panel" (default — solid pack-tinted background) or
            "transparent" (skip the panel, useful when the page
            template already painted a gradient behind the card).
    """
    if rarity not in RARITY_RING:
        raise ValueError(f"unknown rarity {rarity!r}")
    if pack not in PACK_TINTS:
        raise ValueError(f"unknown pack {pack!r}")

    spec = RARITY_RING[rarity]
    pack_tint_hex = PACK_TINTS[pack]

    # 1. Drop shadow (only when we paint a panel; transparent mode
    #    assumes the caller already established the surface).
    if background == "panel":
        sh = SHADOW["card_drop"]
        shadow = _drop_shadow_layer(
            w + sh["blur"] * 2, h + sh["blur"] * 2,
            sh["dx"], sh["dy"], sh["blur"], sh["alpha"],
        )
        canvas.alpha_composite(shadow, (x - sh["blur"], y - sh["blur"]))

        # 2. Panel background — slightly tinted version of the bg.
        panel = Image.new("RGBA", (w, h), _hex_to_rgba(PALETTE["bg"], 255))
        # Layer pack-tint at low alpha for the "this card belongs to
        # this pack" cue without shouting it.
        tint = Image.new("RGBA", (w, h),
                         _hex_to_rgba(pack_tint_hex, 25))
        panel.alpha_composite(tint)
        # Round the corners by masking.
        mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, w, h), radius=14, fill=255,
        )
        panel.putalpha(mask)
        canvas.alpha_composite(panel, (x, y))

    # 3. Rarity halo (rare+ only).
    if spec["glow"] is not None and spec["stops"] > 0:
        glow_key = {1: "rare_halo", 2: "epic_halo", 3: "mythic_halo"}[
            spec["stops"]]
        g = GLOW[glow_key]
        glow = _glow_layer(w + g["radius"] * 2, h + g["radius"] * 2,
                           spec["glow"], g["radius"], g["alpha"])
        canvas.alpha_composite(glow,
                               (x - g["radius"], y - g["radius"]))

    # 4. Card image, fitted with a small inset from the panel edge.
    pad = 12
    card_box = (x + pad, y + pad, w - pad * 2, h - pad * 2)
    if image_path.exists():
        with Image.open(image_path) as src:
            iw, ih = src.size
            draw_w, draw_h = fit_box(card_box[2], card_box[3], iw, ih)
            sized = src.convert("RGBA").resize(
                (int(draw_w), int(draw_h)), Image.Resampling.LANCZOS,
            )
        cx = card_box[0] + (card_box[2] - draw_w) // 2
        cy = card_box[1] + (card_box[3] - draw_h) // 2
        canvas.alpha_composite(sized, (int(cx), int(cy)))
    else:
        # Placeholder: solid panel-tint rect so the layout still
        # composes when an asset is missing in CI.
        ph = Image.new("RGBA", (w - pad * 2, h - pad * 2),
                       _hex_to_rgba(pack_tint_hex, 60))
        canvas.alpha_composite(ph, (x + pad, y + pad))

    # 5. Rarity ring outline. Wider for higher tiers — common is a
    # thin etched line, mythic is a heavy gold band.
    border_w = {0: 1, 1: 2, 2: 3, 3: 4}[spec["stops"]]
    ring_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(ring_layer).rounded_rectangle(
        (border_w // 2, border_w // 2,
         w - border_w // 2, h - border_w // 2),
        radius=14,
        outline=_hex_to_rgba(spec["edge"], 230),
        width=border_w,
    )
    canvas.alpha_composite(ring_layer, (x, y))


__all__ = [
    "draw_card_frame",
    "paint_pack_background",
]
