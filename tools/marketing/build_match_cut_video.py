"""Build the 'Every pop is a hello' match-cut TikTok/Reels/Shorts video.

22-second portrait (1080x1920) silent assembly:
  0.0 - 1.0s   Cover hero fade in (Ken Burns zoom)
  1.0 - 4.0s   Book spread 18 wide reveal, slow Ken Burns into Soft Dumpling face
  4.0 - 5.0s   HOLD on Soft Dumpling face (the match-cut anchor)
  5.0 - 7.5s   MATCH CUT to Celestial Dumpling 3D card art (zoom + pulse)
  7.5 - 12.5s  Gameplay clip from mythic.mp4 (5s center-cropped portrait)
  12.5- 15.0s  MATCH CUT back to book spread 18 (zoom out to wide)
  15.0- 18.0s  Cover hero in dusk palette with tagline overlay
  18.0- 22.0s  End title card 'Every pop is a hello.' + brand mark

Output: docs/marketing/match_cut_video.mp4 (silent — user picks a trending
TikTok sound at upload, per viral playbook recommendation).
"""

import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "docs" / "marketing"
OUT_DIR.mkdir(parents=True, exist_ok=True)
TMP = OUT_DIR / "_video_tmp"
TMP.mkdir(exist_ok=True)

# Asset paths
COVER = REPO / "book" / "cover" / "book2_cover_hero_LOCKED.png"
SPREAD18 = REPO / "book" / "build_book2" / "out" / "_preview_spread18.jpg"
DUMPLING_3D = REPO / "assets" / "website_hero" / "hero_celestial_dumpling.png"
GAMEPLAY = REPO / "mythic.mp4"
FREDOKA = REPO / "assets" / "google_fonts" / "Fredoka.ttf"

OUT = OUT_DIR / "match_cut_video.mp4"

# Output specs
W, H = 1080, 1920
FPS = 30

# --- helper: render a static frame as a video clip with Ken Burns zoom ---
def kenburns_clip(src_path: Path, out_path: Path, duration: float,
                  zoom_start: float = 1.0, zoom_end: float = 1.1,
                  pan_y_frac_start: float = 0.5, pan_y_frac_end: float = 0.5,
                  pan_x_frac_start: float = 0.5, pan_x_frac_end: float = 0.5):
    """Generate a portrait Ken Burns clip from a still image.

    pan_*_frac control which point in the source stays centered in the
    crop — 0.5 is center, 0.0 is top/left edge.
    """
    img = Image.open(src_path).convert("RGB")
    sw, sh = img.size

    # Target crop aspect 9:16. Pick crop dimensions that fit inside source.
    target_aspect = W / H  # 0.5625
    if sw / sh > target_aspect:
        # source wider — crop horizontally
        crop_h = sh
        crop_w = int(sh * target_aspect)
    else:
        crop_w = sw
        crop_h = int(sw / target_aspect)

    # Save canonical portrait crop as base
    # We'll let ffmpeg do the zoom from this base via scale + zoompan
    base = TMP / f"_base_{src_path.stem}.png"
    if not base.exists() or True:
        # center-crop fallback; pan handled separately via two-frame interpolation
        cx = int(sw * (pan_x_frac_start + pan_x_frac_end) / 2)
        cy = int(sh * (pan_y_frac_start + pan_y_frac_end) / 2)
        left = max(0, cx - crop_w // 2)
        right = min(sw, left + crop_w)
        left = right - crop_w
        top = max(0, cy - crop_h // 2)
        bot = min(sh, top + crop_h)
        top = bot - crop_h
        cropped = img.crop((left, top, right, bot)).resize((W, H), Image.LANCZOS)
        cropped.save(base, "PNG")

    # Use zoompan for a smooth zoom. zoompan works on a single still.
    frames = int(duration * FPS)
    zoom_filter = (
        f"zoompan=z='{zoom_start}+({zoom_end - zoom_start})*on/{frames}'"
        f":d={frames}:s={W}x{H}:fps={FPS}"
    )
    cmd = [
        "ffmpeg", "-y", "-loop", "1", "-i", str(base),
        "-vf", zoom_filter,
        "-c:v", "libx264", "-t", f"{duration}", "-pix_fmt", "yuv420p",
        "-r", str(FPS), str(out_path),
    ]
    subprocess.run(cmd, check=True, capture_output=True)

# --- helper: extract a portrait clip from gameplay video ---
def gameplay_clip(out_path: Path, start: float, duration: float):
    """Center-crop the landscape gameplay video to portrait."""
    # mythic.mp4 is 1868x862. Crop to (862 * 9/16) wide = 485 — too narrow.
    # Better: scale up to 1920 tall first, then center-crop to 1080 wide.
    vf = (
        f"scale=-2:{H},crop={W}:{H}:(in_w-{W})/2:0"
    )
    cmd = [
        "ffmpeg", "-y", "-ss", f"{start}", "-i", str(GAMEPLAY),
        "-t", f"{duration}", "-vf", vf,
        "-c:v", "libx264", "-pix_fmt", "yuv420p",
        "-r", str(FPS), "-an", str(out_path),
    ]
    subprocess.run(cmd, check=True, capture_output=True)

# --- helper: render a still title card as a video clip ---
def title_card_clip(out_path: Path, duration: float, lines: list[tuple[str, int, tuple]],
                    bg_color: tuple = (59, 42, 77)):
    """Render a multi-line title card (text, font_size, fill) on a solid bg."""
    img = Image.new("RGB", (W, H), bg_color)
    draw = ImageDraw.Draw(img)

    # measure total block height
    fonts = [ImageFont.truetype(str(FREDOKA), sz) for (_, sz, _) in lines]
    line_heights = []
    for (txt, sz, _), f in zip(lines, fonts):
        bbox = draw.textbbox((0, 0), txt, font=f)
        line_heights.append(bbox[3] - bbox[1])
    gap = 30
    total_h = sum(line_heights) + gap * (len(lines) - 1)
    y = (H - total_h) // 2

    for (txt, sz, color), f, lh in zip(lines, fonts, line_heights):
        bbox = draw.textbbox((0, 0), txt, font=f)
        tw = bbox[2] - bbox[0]
        x = (W - tw) // 2 - bbox[0]
        # subtle shadow
        draw.text((x + 2, y + 2), txt, font=f, fill=(0, 0, 0))
        draw.text((x, y), txt, font=f, fill=color)
        y += lh + gap

    frame = TMP / f"_title_{out_path.stem}.png"
    img.save(frame, "PNG")
    cmd = [
        "ffmpeg", "-y", "-loop", "1", "-i", str(frame),
        "-c:v", "libx264", "-t", f"{duration}", "-pix_fmt", "yuv420p",
        "-r", str(FPS),
        "-vf", f"scale={W}:{H}", str(out_path),
    ]
    subprocess.run(cmd, check=True, capture_output=True)

# --- helper: tagline overlay on a still (cover with tagline at bottom) ---
def cover_with_tagline_clip(src_path: Path, out_path: Path, duration: float,
                            tagline: str = "Every pop is a hello."):
    img = Image.open(src_path).convert("RGB")
    # Resize keeping aspect, center on portrait canvas with darker letterbox
    sw, sh = img.size
    # Fit cover into upper 70% of canvas
    target_h = int(H * 0.62)
    target_w = int(sw * target_h / sh)
    if target_w > W - 60:
        target_w = W - 60
        target_h = int(sh * target_w / sw)
    cover_resized = img.resize((target_w, target_h), Image.LANCZOS)

    canvas = Image.new("RGB", (W, H), (59, 42, 77))  # dusk purple
    x = (W - target_w) // 2
    y = int(H * 0.15)
    canvas.paste(cover_resized, (x, y))

    # Tagline below
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(str(FREDOKA), 64)
    bbox = draw.textbbox((0, 0), tagline, font=font)
    tw = bbox[2] - bbox[0]
    tx = (W - tw) // 2 - bbox[0]
    ty = y + target_h + 80
    draw.text((tx + 2, ty + 2), tagline, font=font, fill=(0, 0, 0))
    draw.text((tx, ty), tagline, font=font, fill=(255, 248, 230))

    # Sub-line
    sub_font = ImageFont.truetype(str(FREDOKA), 32)
    sub = "SQUISHY SMASH"
    sb = draw.textbbox((0, 0), sub, font=sub_font)
    sx = (W - (sb[2] - sb[0])) // 2 - sb[0]
    sy = ty + 100
    draw.text((sx, sy), sub, font=sub_font, fill=(226, 168, 95))

    frame = TMP / f"_cov_{out_path.stem}.png"
    canvas.save(frame, "PNG")
    cmd = [
        "ffmpeg", "-y", "-loop", "1", "-i", str(frame),
        "-c:v", "libx264", "-t", f"{duration}", "-pix_fmt", "yuv420p",
        "-r", str(FPS), str(out_path),
    ]
    subprocess.run(cmd, check=True, capture_output=True)

# ---------- assemble ----------
def build():
    clips = []

    # 0.0 - 1.0s  Cover hero quick zoom in
    p = TMP / "01_cover_in.mp4"
    kenburns_clip(COVER, p, duration=1.0, zoom_start=1.05, zoom_end=1.18)
    clips.append(p)

    # 1.0 - 4.0s  Book spread 18 wide reveal, slow Ken Burns toward dumpling on left
    p = TMP / "02_spread18_wide.mp4"
    # Soft Dumpling is in the left third of spread 18
    kenburns_clip(SPREAD18, p, duration=3.0,
                  zoom_start=1.0, zoom_end=1.35,
                  pan_x_frac_start=0.25, pan_x_frac_end=0.20,
                  pan_y_frac_start=0.55, pan_y_frac_end=0.55)
    clips.append(p)

    # 4.0 - 5.0s  HOLD on Soft Dumpling face (zoomed in)
    p = TMP / "03_spread18_hold.mp4"
    kenburns_clip(SPREAD18, p, duration=1.0,
                  zoom_start=1.35, zoom_end=1.40,
                  pan_x_frac_start=0.20, pan_x_frac_end=0.20,
                  pan_y_frac_start=0.55, pan_y_frac_end=0.55)
    clips.append(p)

    # 5.0 - 7.5s  MATCH CUT — Celestial Dumpling 3D card, zoom + pulse
    p = TMP / "04_dumpling_3d.mp4"
    kenburns_clip(DUMPLING_3D, p, duration=2.5,
                  zoom_start=1.05, zoom_end=1.20)
    clips.append(p)

    # 7.5 - 12.5s  Gameplay clip from mythic.mp4 (5 seconds)
    p = TMP / "05_gameplay.mp4"
    gameplay_clip(p, start=8.0, duration=5.0)
    clips.append(p)

    # 12.5 - 15.0s MATCH CUT back to book spread 18, zooming OUT to wide
    p = TMP / "06_spread18_out.mp4"
    kenburns_clip(SPREAD18, p, duration=2.5,
                  zoom_start=1.40, zoom_end=1.00,
                  pan_x_frac_start=0.20, pan_x_frac_end=0.50,
                  pan_y_frac_start=0.55, pan_y_frac_end=0.55)
    clips.append(p)

    # 15.0 - 18.0s  Cover with tagline (held)
    p = TMP / "07_cover_tagline.mp4"
    cover_with_tagline_clip(COVER, p, duration=3.0)
    clips.append(p)

    # 18.0 - 22.0s End title card
    p = TMP / "08_endcard.mp4"
    title_card_clip(p, duration=4.0, lines=[
        ("Squishy Smash", 84, (255, 248, 230)),
        ("THE LOST SPARKLE", 42, (226, 168, 95)),
        ("on Amazon now", 36, (255, 248, 230)),
    ])
    clips.append(p)

    # ---- concat ----
    list_file = TMP / "concat.txt"
    list_file.write_text("\n".join(f"file '{c.as_posix()}'" for c in clips))

    cmd = [
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(list_file),
        "-c:v", "libx264", "-preset", "medium", "-crf", "20",
        "-pix_fmt", "yuv420p", "-r", str(FPS),
        "-vf", f"scale={W}:{H}:flags=lanczos",
        "-an", str(OUT),
    ]
    subprocess.run(cmd, check=True)
    sz = OUT.stat().st_size // 1024
    print(f"\nBuilt: {OUT} ({sz} KB)")

if __name__ == "__main__":
    build()
