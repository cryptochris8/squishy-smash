"""
Composite kinetic text overlays + brand end card onto a screen recording
to produce voiceless TikTok/Reddit ads.

Pipeline (per the research-agent spec):
  1. Render a per-frame RGBA PNG sequence in Pillow (full Python control
     over Fredoka variable-font axis, easing curves, and color accuracy).
  2. ffmpeg overlays the sequence onto the base recording in a single
     pass: trim recording to gameplay duration, pad with cloned last
     frame for the end card, pad audio with silence for the same window,
     composite, encode H.264 yuv420p with +faststart.

Two storyboards baked in (matches the design-agent spec):
  --storyboard 30s  → 25s gameplay + 5s end card
  --storyboard 15s  → 12s gameplay + 3s end card

Usage:
    python tools/build_kinetic_overlay_video.py --storyboard 30s
    python tools/build_kinetic_overlay_video.py --storyboard 15s

Output lands in marketing/ (gitignored — these are build artifacts).
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent

# Brand palette — same hex values pinned in brand_and_social_presence.md
PALETTE = {
    "bg":         "#120B17",
    "pink":       "#FF8FB8",
    "cream":      "#FFD36E",
    "jelly_blue": "#7FE7FF",
    "lavender":   "#C98BFF",
    "lime":       "#B6FF5C",
    "soft_white": "#F5F0FA",
}

FONT_PATH = REPO_ROOT / "assets" / "google_fonts" / "Fredoka.ttf"
DEFAULT_FFMPEG = (
    r"C:\Users\chris\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe"
)
DEFAULT_INPUT = (
    REPO_ROOT / "assets" / "images"
    / "ScreenRecording_05-01-2026 19-06-46_1.MP4"
)

WIDTH, HEIGHT = 886, 1920
FPS = 30


# ─── Easing ──────────────────────────────────────────────────────────────

def ease_out_cubic(t: float) -> float:
    return 1 - (1 - t) ** 3


def ease_in_cubic(t: float) -> float:
    return t ** 3


def ease_in_out_cubic(t: float) -> float:
    if t < 0.5:
        return 4 * t ** 3
    return 1 - ((-2 * t + 2) ** 3) / 2


# ─── Data classes ────────────────────────────────────────────────────────

@dataclass
class TextBeat:
    """One text overlay's lifecycle on the timeline."""
    text: str
    t_in: float          # animation-in starts
    t_hold: float        # in-animation completes; hold begins
    t_out: float         # fade-out starts
    t_end: float         # fully gone
    y: int               # top of text block (center-anchored on x)
    font_size: int
    weight: int          # Fredoka wght axis (300-700)
    color_hex: str
    anim_in: Literal["pop_in", "drift_up"] = "pop_in"
    x: int = WIDTH // 2


@dataclass
class EndCardSpec:
    duration: float
    bg_hex: str = PALETTE["bg"]
    wordmark_size: int = 120
    wordmark_weight: int = 700
    wordmark1_text: str = "SQUISHY"
    wordmark1_color: str = PALETTE["pink"]
    wordmark1_y: int = 380
    wordmark2_text: str = "SMASH"
    wordmark2_color: str = PALETTE["cream"]
    wordmark2_y: int = 510
    tagline_text: str = "a fidget toy you can keep in your pocket."
    tagline_color: str = PALETTE["soft_white"]
    tagline_alpha: int = 200
    tagline_size: int = 32
    tagline_y: int = 660
    cta_text: str = "Free on the App Store"
    cta_size: int = 36
    cta_y_center: int = 800
    cta_pill_bg: str = PALETTE["pink"]
    cta_pill_alpha: int = 230
    # Stagger entrance: SQUISHY at 0ms, SMASH at 120ms,
    # tagline at 280ms, CTA pill at 420ms. Each pop_in is 200ms.
    stagger_ms: tuple[int, int, int, int] = (0, 120, 280, 420)
    pop_in_ms: int = 200


@dataclass
class Storyboard:
    name: str
    gameplay_duration: float
    end_card: EndCardSpec
    beats: list[TextBeat] = field(default_factory=list)

    @property
    def total_duration(self) -> float:
        return self.gameplay_duration + self.end_card.duration


# ─── Storyboards ─────────────────────────────────────────────────────────
# Numbers come straight from the ui-design subagent's spec; do NOT edit
# without coordinating with the storyboard table — the engineering and
# design specs are paired.

STORYBOARD_30S = Storyboard(
    name="30s",
    gameplay_duration=25.0,
    end_card=EndCardSpec(duration=5.0),
    beats=[
        TextBeat("tap. squish. pop.",
                 t_in=1.5, t_hold=1.7, t_out=3.5, t_end=3.8,
                 y=720, font_size=88, weight=600,
                 color_hex=PALETTE["pink"], anim_in="pop_in"),
        TextBeat("satisfying? oh yes.",
                 t_in=5.0, t_hold=5.3, t_out=7.5, t_end=7.8,
                 y=780, font_size=72, weight=500,
                 color_hex=PALETTE["cream"], anim_in="drift_up"),
        TextBeat("48 collectibles",
                 t_in=9.0, t_hold=9.2, t_out=15.0, t_end=15.4,
                 y=320, font_size=64, weight=700,
                 color_hex=PALETTE["jelly_blue"], anim_in="pop_in"),
        TextBeat("3 packs. so many rarities.",
                 t_in=9.2, t_hold=9.5, t_out=15.0, t_end=15.4,
                 y=420, font_size=48, weight=400,
                 color_hex=PALETTE["soft_white"], anim_in="drift_up"),
        TextBeat("each squish sounds different",
                 t_in=16.5, t_hold=16.7, t_out=20.0, t_end=20.3,
                 y=720, font_size=64, weight=500,
                 color_hex=PALETTE["lavender"], anim_in="pop_in"),
        TextBeat("goo tier just hits different",
                 t_in=21.0, t_hold=21.3, t_out=24.0, t_end=24.3,
                 y=760, font_size=64, weight=500,
                 color_hex=PALETTE["lime"], anim_in="drift_up"),
    ],
)

STORYBOARD_15S = Storyboard(
    name="15s",
    gameplay_duration=12.0,
    end_card=EndCardSpec(duration=3.0),
    beats=[
        TextBeat("tap. squish. pop.",
                 t_in=1.5, t_hold=1.7, t_out=3.5, t_end=3.8,
                 y=720, font_size=88, weight=600,
                 color_hex=PALETTE["pink"], anim_in="pop_in"),
        TextBeat("48 collectibles",
                 t_in=4.0, t_hold=4.2, t_out=9.0, t_end=9.4,
                 y=320, font_size=64, weight=700,
                 color_hex=PALETTE["jelly_blue"], anim_in="pop_in"),
        TextBeat("3 packs. so many rarities.",
                 t_in=4.2, t_hold=4.5, t_out=9.0, t_end=9.4,
                 y=420, font_size=48, weight=400,
                 color_hex=PALETTE["soft_white"], anim_in="drift_up"),
        TextBeat("each squish sounds different",
                 t_in=10.0, t_hold=10.2, t_out=12.0, t_end=12.3,
                 y=720, font_size=64, weight=500,
                 color_hex=PALETTE["lavender"], anim_in="pop_in"),
    ],
)

STORYBOARDS = {"30s": STORYBOARD_30S, "15s": STORYBOARD_15S}


# ─── Helpers ─────────────────────────────────────────────────────────────

def hex_rgba(h: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


_FONT_CACHE: dict[tuple[int, int], ImageFont.FreeTypeFont] = {}


def load_fredoka(size: int, weight: int = 500) -> ImageFont.FreeTypeFont:
    """Cached Fredoka loader. Sets variable wght axis if available;
    silently falls back to default weight if Pillow's FreeType build
    doesn't support variable axes."""
    key = (size, weight)
    if key not in _FONT_CACHE:
        f = ImageFont.truetype(str(FONT_PATH), size)
        try:
            f.set_variation_by_axes([float(weight)])
        except (AttributeError, OSError):
            pass  # variable-axis support unavailable; default weight is fine
        _FONT_CACHE[key] = f
    return _FONT_CACHE[key]


def shadow_recipe_for_size(font_size: int, alpha: float) -> dict:
    """Returns offset/blur/alpha tuned to the role's type size.
    Larger text gets a heavier shadow; supporting tier gets lighter."""
    if font_size >= 100:   # wordmark tier
        return {"offset": (5, 5), "blur": 10, "alpha": int(180 * alpha)}
    if font_size <= 48:    # supporting / tagline tier
        return {"offset": (2, 3), "blur": 8, "alpha": int(150 * alpha)}
    return {"offset": (3, 4), "blur": 10, "alpha": int(170 * alpha)}


def draw_text_with_shadow(canvas: Image.Image, text: str, cx: int, y: int,
                          font: ImageFont.FreeTypeFont,
                          color_rgba: tuple[int, int, int, int],
                          shadow_recipe: dict | None) -> None:
    """Center-anchored text with optional drop shadow.
    cx = horizontal center. y = top of text block."""
    bbox = ImageDraw.Draw(canvas).textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_x = cx - text_w // 2

    if shadow_recipe and shadow_recipe.get("alpha", 0) > 0:
        sx, sy = shadow_recipe["offset"]
        shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        ImageDraw.Draw(shadow_layer).text(
            (text_x + sx, y + sy), text,
            font=font, fill=(0, 0, 0, shadow_recipe["alpha"]),
        )
        shadow_layer = shadow_layer.filter(
            ImageFilter.GaussianBlur(radius=shadow_recipe["blur"])
        )
        canvas.alpha_composite(shadow_layer)

    ImageDraw.Draw(canvas).text(
        (text_x, y), text, font=font, fill=color_rgba,
    )


def add_radial_glow(canvas: Image.Image, center: tuple[int, int],
                    color_hex: str, radius: int, opacity: int) -> None:
    """Same glow pattern as render_x_banner.py / render_reddit_image.py."""
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    cx, cy = center
    r, g, b, _ = hex_rgba(color_hex)
    ImageDraw.Draw(glow).ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        fill=(r, g, b, opacity),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=radius // 4))
    canvas.alpha_composite(glow)


# ─── Beat lifecycle ──────────────────────────────────────────────────────

def compute_beat_state(beat: TextBeat, t: float) -> tuple[float, float, float] | None:
    """Returns (alpha 0-1, y_offset px, scale 1.0=normal) or None if inactive.
    Animation patterns POP_IN and DRIFT_UP per the design spec; FADE_OUT
    on exit (300ms standard, 400ms for stacked beats)."""
    if t < beat.t_in or t >= beat.t_end:
        return None

    if t < beat.t_hold:
        progress = (t - beat.t_in) / max(0.001, beat.t_hold - beat.t_in)
        if beat.anim_in == "pop_in":
            # 0 -> 0.5 of progress: scale 0.72 -> 1.06, alpha 0 -> 1 (ease-out)
            # 0.5 -> 1.0 of progress: scale 1.06 -> 1.00 (ease-in-out)
            if progress < 0.5:
                p = progress / 0.5
                scale = 0.72 + (1.06 - 0.72) * ease_out_cubic(p)
                alpha = ease_out_cubic(p)
            else:
                p = (progress - 0.5) / 0.5
                scale = 1.06 + (1.00 - 1.06) * ease_in_out_cubic(p)
                alpha = 1.0
            y_offset = 0.0
        else:  # drift_up: y +16 -> 0, alpha 0 -> 1
            scale = 1.0
            alpha = ease_out_cubic(progress)
            y_offset = 16 * (1 - ease_out_cubic(progress))
    elif t < beat.t_out:
        scale, alpha, y_offset = 1.0, 1.0, 0.0
    else:  # fade out
        progress = (t - beat.t_out) / max(0.001, beat.t_end - beat.t_out)
        scale = 1.0
        alpha = 1.0 - ease_in_cubic(progress)
        y_offset = 0.0

    return alpha, y_offset, scale


# ─── Frame renderers ─────────────────────────────────────────────────────

def render_overlay_frame(t: float, storyboard: Storyboard) -> Image.Image:
    """Transparent RGBA frame with all active text beats composited."""
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))

    for beat in storyboard.beats:
        state = compute_beat_state(beat, t)
        if state is None:
            continue
        alpha, y_offset, scale = state
        if alpha <= 0:
            continue

        # Scale handled by re-loading font at the scaled size — Pillow
        # rasterizes at this size, no quality loss vs. transform-scaling
        effective_size = max(8, int(round(beat.font_size * scale)))
        font = load_fredoka(effective_size, beat.weight)
        y_actual = beat.y + int(y_offset)

        text_alpha = int(255 * alpha)
        color_rgba = hex_rgba(beat.color_hex, text_alpha)
        shadow = shadow_recipe_for_size(beat.font_size, alpha)

        draw_text_with_shadow(
            canvas, beat.text, beat.x, y_actual, font, color_rgba, shadow,
        )

    return canvas


def _pop_in_progress(t_now_ms: float, t_start_ms: float,
                     duration_ms: int = 200) -> tuple[float, float]:
    """Returns (alpha 0-1, scale) for an end-card element pop_in."""
    if t_now_ms < t_start_ms:
        return 0.0, 0.72
    progress = min(1.0, (t_now_ms - t_start_ms) / duration_ms)
    if progress < 0.5:
        p = progress / 0.5
        return ease_out_cubic(p), 0.72 + (1.06 - 0.72) * ease_out_cubic(p)
    p = (progress - 0.5) / 0.5
    return 1.0, 1.06 + (1.00 - 1.06) * ease_in_out_cubic(p)


def render_end_card_frame(elapsed: float, end_card: EndCardSpec) -> Image.Image:
    """Fully opaque end card frame composited atop deep-plum bg + glows."""
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), hex_rgba(end_card.bg_hex, 255))

    # Brand glows — same diagonal as render_reddit_image.py for cohesion
    add_radial_glow(canvas, (220, 380), PALETTE["pink"], radius=460, opacity=90)
    add_radial_glow(canvas, (666, 960), PALETTE["lavender"], radius=500, opacity=80)

    cx = WIDTH // 2
    t_ms = elapsed * 1000
    s_squishy, s_smash, s_tagline, s_cta = end_card.stagger_ms

    # SQUISHY
    a1, sc1 = _pop_in_progress(t_ms, s_squishy, end_card.pop_in_ms)
    if a1 > 0:
        size1 = max(8, int(end_card.wordmark_size * sc1))
        f1 = load_fredoka(size1, end_card.wordmark_weight)
        draw_text_with_shadow(
            canvas, end_card.wordmark1_text, cx, end_card.wordmark1_y, f1,
            hex_rgba(end_card.wordmark1_color, int(255 * a1)),
            shadow_recipe_for_size(end_card.wordmark_size, a1),
        )

    # SMASH
    a2, sc2 = _pop_in_progress(t_ms, s_smash, end_card.pop_in_ms)
    if a2 > 0:
        size2 = max(8, int(end_card.wordmark_size * sc2))
        f2 = load_fredoka(size2, end_card.wordmark_weight)
        draw_text_with_shadow(
            canvas, end_card.wordmark2_text, cx, end_card.wordmark2_y, f2,
            hex_rgba(end_card.wordmark2_color, int(255 * a2)),
            shadow_recipe_for_size(end_card.wordmark_size, a2),
        )

    # Tagline
    a3, _ = _pop_in_progress(t_ms, s_tagline, end_card.pop_in_ms)
    if a3 > 0:
        f3 = load_fredoka(end_card.tagline_size, 400)
        tag_a = int(end_card.tagline_alpha * a3)
        draw_text_with_shadow(
            canvas, end_card.tagline_text, cx, end_card.tagline_y, f3,
            hex_rgba(end_card.tagline_color, tag_a),
            {"offset": (2, 3), "blur": 8, "alpha": int(140 * a3)},
        )

    # CTA pill
    a4, _ = _pop_in_progress(t_ms, s_cta, end_card.pop_in_ms)
    if a4 > 0:
        f4 = load_fredoka(end_card.cta_size, 600)
        bbox = ImageDraw.Draw(canvas).textbbox((0, 0), end_card.cta_text, font=f4)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        pad_x, pad_y = 22, 14
        pill_w = text_w + pad_x * 2
        pill_h = text_h + pad_y * 2 + 8  # +8 padding fudge for descenders
        pill_x = cx - pill_w // 2
        pill_y = end_card.cta_y_center - pill_h // 2

        pill_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        pill_alpha = int(end_card.cta_pill_alpha * a4)
        ImageDraw.Draw(pill_layer).rounded_rectangle(
            [pill_x, pill_y, pill_x + pill_w, pill_y + pill_h],
            radius=pill_h // 2,
            fill=hex_rgba(end_card.cta_pill_bg, pill_alpha),
        )
        # CTA text in deep-plum on the pink pill
        ImageDraw.Draw(pill_layer).text(
            (pill_x + pad_x, pill_y + pad_y - 2),
            end_card.cta_text, font=f4,
            fill=hex_rgba(end_card.bg_hex, int(255 * a4)),
        )
        canvas.alpha_composite(pill_layer)

    return canvas


# ─── Sequence rendering ──────────────────────────────────────────────────

def render_full_sequence(storyboard: Storyboard, out_dir: Path) -> int:
    """Write every frame to out_dir/frame_NNNNN.png. Returns frame count."""
    total_frames = int(round(storyboard.total_duration * FPS))
    end_card_start = int(round(storyboard.gameplay_duration * FPS))

    for i in range(total_frames):
        t = i / FPS
        if i < end_card_start:
            frame = render_overlay_frame(t, storyboard)
        else:
            elapsed = (i - end_card_start) / FPS
            frame = render_end_card_frame(elapsed, storyboard.end_card)
        frame.save(out_dir / f"frame_{i:05d}.png", "PNG")
        if (i + 1) % 60 == 0:
            print(f"  rendered {i + 1}/{total_frames} frames")

    return total_frames


# ─── ffmpeg encode ───────────────────────────────────────────────────────

def build_video(base_video: Path, storyboard: Storyboard, out_path: Path,
                ffmpeg: str, crf: int, preset: str) -> int:
    """Render the PNG sequence to a temp dir, then composite onto the
    base recording in a single ffmpeg pass."""
    with tempfile.TemporaryDirectory(prefix="ssmash_kinetic_") as tmp:
        png_dir = Path(tmp)
        print(f"Rendering {int(storyboard.total_duration * FPS)} frames "
              f"to {png_dir}...")
        render_full_sequence(storyboard, png_dir)

        gp_dur = storyboard.gameplay_duration
        ec_dur = storyboard.end_card.duration

        # Trim recording to gameplay window, downsample to FPS, pad with
        # cloned last frame for end-card duration. Audio: trim + silence pad.
        # The PNG overlay (input 1) covers the entire output duration —
        # transparent during gameplay, fully opaque during end card, so
        # the cloned-last-frame underlay is invisible during the card.
        filter_graph = (
            f"[0:v]fps={FPS},trim=end={gp_dur},setpts=PTS-STARTPTS,"
            f"tpad=stop_mode=clone:stop_duration={ec_dur}[base];"
            f"[0:a]atrim=end={gp_dur},asetpts=PTS-STARTPTS,"
            f"apad=pad_dur={ec_dur}[audio];"
            f"[base][1:v]overlay=format=auto[v]"
        )

        cmd = [
            ffmpeg, "-y",
            "-i", str(base_video),
            "-framerate", str(FPS),
            "-i", str(png_dir / "frame_%05d.png"),
            "-filter_complex", filter_graph,
            "-map", "[v]",
            "-map", "[audio]",
            "-t", str(storyboard.total_duration),
            "-c:v", "libx264",
            "-preset", preset,
            "-crf", str(crf),
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-b:a", "128k",
            "-ar", "44100",
            "-ac", "2",
            "-movflags", "+faststart",
            str(out_path),
        ]

        print(f"Encoding {out_path.name}...")
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            print("ffmpeg FAILED")
            print(proc.stderr[-3000:])
            return proc.returncode
    return 0


# ─── CLI ─────────────────────────────────────────────────────────────────

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--storyboard", choices=sorted(STORYBOARDS.keys()),
                   default="30s",
                   help="Which storyboard variant to render")
    p.add_argument("--input", type=Path, default=DEFAULT_INPUT,
                   help="Base screen recording")
    p.add_argument("--out", type=Path, default=None,
                   help="Output path; default marketing/squishy_smash_kinetic_<name>.mp4")
    p.add_argument("--ffmpeg", default=DEFAULT_FFMPEG)
    p.add_argument("--crf", type=int, default=20)
    p.add_argument("--preset", default="medium")
    args = p.parse_args()

    storyboard = STORYBOARDS[args.storyboard]

    ffmpeg = args.ffmpeg if Path(args.ffmpeg).exists() else shutil.which("ffmpeg")
    if not ffmpeg:
        print("ERROR: ffmpeg not found", file=sys.stderr)
        return 1
    if not args.input.exists():
        print(f"ERROR: input not found: {args.input}", file=sys.stderr)
        return 1
    if not FONT_PATH.exists():
        print(f"ERROR: Fredoka font not found at {FONT_PATH}", file=sys.stderr)
        return 1

    out = args.out or (
        REPO_ROOT / "marketing" / f"squishy_smash_kinetic_{storyboard.name}.mp4"
    )
    out.parent.mkdir(parents=True, exist_ok=True)

    print(f"Storyboard: {storyboard.name}  "
          f"({storyboard.gameplay_duration}s gameplay + "
          f"{storyboard.end_card.duration}s end card = "
          f"{storyboard.total_duration}s total)")
    print(f"Input:      {args.input.name}")
    print(f"Output:     {out.relative_to(REPO_ROOT)}")
    print(f"Beats:      {len(storyboard.beats)}")
    print()

    rc = build_video(args.input, storyboard, out, ffmpeg,
                     args.crf, args.preset)
    if rc == 0 and out.exists():
        mb = out.stat().st_size / (1024 * 1024)
        print(f"Wrote {out.relative_to(REPO_ROOT)} ({mb:.1f} MB)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
