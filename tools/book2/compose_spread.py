"""Compose a single Book #2 spread from a TOML spec at print resolution.

Output is 2550×2550 (8.5×8.5 inch at 300 DPI) — KDP single-page interior format.
Use one TOML spec file per spread under book/spread_specs/. Custom layouts
(triptychs, big-pop bursts, etc.) get their own one-off scripts; this is the
uniform-layout compositor that handles the majority of spreads.

Usage:
  python3 tools/book2/compose_spread.py book/spread_specs/spread_01_three_places.toml
"""
import os, sys, tomllib
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
CANVAS_W = 2550
CANVAS_H = 2550


def abs_path(rel):
    return rel if os.path.isabs(rel) else os.path.join(SQ, rel)


def hex_to_rgb(hex_str):
    h = hex_str.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def load_plate(path, target=(CANVAS_W, CANVAS_H)):
    """Scale-fill the plate to target with center crop; becomes the base layer."""
    img = Image.open(abs_path(path)).convert("RGBA")
    iw, ih = img.size
    scale = max(target[0] / iw, target[1] / ih)
    nw, nh = int(iw * scale), int(ih * scale)
    img = img.resize((nw, nh), Image.LANCZOS)
    left = (nw - target[0]) // 2
    top = (nh - target[1]) // 2
    return img.crop((left, top, left + target[0], top + target[1]))


def crop_to_alpha(img):
    bbox = img.split()[3].getbbox()
    return img.crop(bbox) if bbox else img


def resize_h(img, h):
    w, hh = img.size
    return img.resize((int(w * h / hh), h), Image.LANCZOS)


def paste_with_shadow(canvas, sprite, x_center, y_bottom, shadow_blur=24):
    sw, sh = sprite.size
    x = int(x_center - sw / 2)
    y_top = int(y_bottom - sh)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    shw = int(sw * 0.75)
    shh = int(sh * 0.06)
    shx = int(x_center - shw / 2)
    shy = int(y_bottom - shh * 0.45)
    draw.ellipse([shx, shy, shx + shw, shy + shh], fill=(0, 0, 30, 140))
    shadow = shadow.filter(ImageFilter.GaussianBlur(shadow_blur))
    canvas.alpha_composite(shadow)
    canvas.paste(sprite, (x, y_top), sprite)


def add_text_band(canvas, position, height_frac, color_hex, opacity_frac, soft_edge_px=40):
    """Add a soft text-contrast band. Solid color + soft-feather edge toward the
    illustration so the band reads as part of the design, not a glued-on rectangle."""
    band_h = int(canvas.size[1] * height_frac)
    rgb = hex_to_rgb(color_hex)
    a = int(255 * opacity_frac)
    band = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(band)
    if position == "bottom":
        y0, y1 = canvas.size[1] - band_h, canvas.size[1]
    else:
        y0, y1 = 0, band_h
    draw.rectangle([0, y0, canvas.size[0], y1], fill=rgb + (a,))
    # Soft-feather the band edge facing the illustration
    if soft_edge_px > 0:
        feather = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        fd = ImageDraw.Draw(feather)
        if position == "bottom":
            fd.rectangle([0, y0 - soft_edge_px, canvas.size[0], y0 + soft_edge_px], fill=rgb + (a,))
        else:
            fd.rectangle([0, y1 - soft_edge_px, canvas.size[0], y1 + soft_edge_px], fill=rgb + (a,))
        feather = feather.filter(ImageFilter.GaussianBlur(soft_edge_px // 2))
        band = Image.alpha_composite(feather, band)
    return Image.alpha_composite(canvas, band)


def wrap_text(text, font, max_width_px, draw):
    """Word-wrap respecting double-newline paragraph breaks. Empty string marks a paragraph gap."""
    lines = []
    paragraphs = text.strip().split("\n\n")
    for pi, para in enumerate(paragraphs):
        para = para.replace("\n", " ").strip()
        words = para.split()
        current = []
        for word in words:
            test = " ".join(current + [word])
            bbox = draw.textbbox((0, 0), test, font=font)
            if (bbox[2] - bbox[0]) > max_width_px and current:
                lines.append(" ".join(current))
                current = [word]
            else:
                current.append(word)
        if current:
            lines.append(" ".join(current))
        if pi < len(paragraphs) - 1:
            lines.append("")
    return lines


def draw_text_block(canvas, content, font_path, size, color_hex, x_center, y_center, max_width, align):
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(abs_path(font_path), size)
    max_w_px = int(canvas.size[0] * max_width)
    lines = wrap_text(content, font, max_w_px, draw)
    sample_bbox = draw.textbbox((0, 0), "Mg", font=font)
    line_h = sample_bbox[3] - sample_bbox[1]
    line_gap = int(line_h * 0.45)
    para_gap = int(line_h * 0.5)
    total_h = 0
    for line in lines:
        total_h += (line_h if line else para_gap) + line_gap
    if lines:
        total_h -= line_gap  # no gap after last line
    cx = int(canvas.size[0] * x_center)
    cy = int(canvas.size[1] * y_center)
    start_y = cy - total_h // 2
    rgb = hex_to_rgb(color_hex)
    y = start_y
    for line in lines:
        if line:
            bbox = draw.textbbox((0, 0), line, font=font)
            tw = bbox[2] - bbox[0]
            if align == "center":
                x = cx - tw // 2
            elif align == "right":
                x = cx + (max_w_px // 2) - tw
            else:
                x = cx - (max_w_px // 2)
            draw.text((x, y), line, fill=rgb, font=font)
            y += line_h + line_gap
        else:
            y += para_gap + line_gap


def compose(spec_path):
    print(f">>> {spec_path}")
    with open(spec_path, "rb") as f:
        spec = tomllib.load(f)

    canvas = load_plate(spec["plate"])

    band = spec.get("text_band", {})
    if band.get("enabled"):
        canvas = add_text_band(
            canvas,
            band.get("position", "bottom"),
            band.get("height", 0.28),
            band.get("color", "#FFFFFF"),
            band.get("opacity", 0.78),
            band.get("soft_edge_px", 40),
        )

    for char in spec.get("characters", []):
        sprite = crop_to_alpha(Image.open(abs_path(char["sprite"])).convert("RGBA"))
        target_h = int(canvas.size[1] * char["height"])
        sprite = resize_h(sprite, target_h)
        x_center_px = int(canvas.size[0] * char["x_center"])
        y_bottom_px = int(canvas.size[1] * char["y_bottom"])
        if char.get("shadow", True):
            paste_with_shadow(canvas, sprite, x_center_px, y_bottom_px,
                              shadow_blur=char.get("shadow_blur", 24))
        else:
            sw, sh = sprite.size
            canvas.paste(sprite, (x_center_px - sw // 2, y_bottom_px - sh), sprite)

    for text in spec.get("text_blocks", []):
        draw_text_block(
            canvas,
            text["content"],
            text["font"],
            text["size"],
            text.get("color", "#120B17"),
            text.get("x_center", 0.5),
            text.get("y_center", 0.85),
            text.get("max_width", 0.84),
            text.get("align", "center"),
        )

    out_path = abs_path(spec["output"])
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.convert("RGB").save(out_path, format="PNG", optimize=True)
    print(f"-> {out_path} ({canvas.size})")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} <spec.toml>")
        sys.exit(1)
    compose(sys.argv[1])
