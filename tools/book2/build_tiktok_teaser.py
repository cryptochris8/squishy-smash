"""Build a 9:16 vertical TikTok teaser for Book 2.

Layout (60s total):
  0-3s    Cover (silent)
  3-7.08s Title page  (title narration plays)
  7.08s   Spread 1 verso (~half the S1 narration)
  -       Spread 1 recto (~rest of S1 narration)
  -       Spread 2 verso (~half the S2 narration)
  -       Spread 2 recto (~rest of S2 narration)
  end-5s  CTA card: "Full read-along on YouTube"

Single-page (1:1) images letterboxed on a 1080x1920 canvas.
"""
import subprocess, sys, os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HOME = Path(r"C:\Users\chris")
SQ = HOME / "Squishy-smash" / "squishy_smash"
PAGES_DIR = SQ / "book" / "build_book2" / "out" / "pages"
COVER_IMG = SQ / "book" / "cover" / "cover_front_book2_composite.png"
AUDIO_SRC = HOME / "squishy_book2_audiobook_v1.mp3"
TMP = HOME / "_tmp_tiktok"
TMP.mkdir(exist_ok=True)
OUT_VIDEO = HOME / "squishy_book2_tiktok_teaser.mp4"

# Vertical canvas
W, H = 1080, 1920
BG_RGB = (16, 16, 24)

# George timing anchors (silence_end seconds on george/audiobook_v1)
COVER_HOLD = 3.0    # silent cover
TITLE_END = 4.08    # end of title narration in source
S1_END = 26.30      # end of S1 narration
S2_END = 46.63      # end of S2 narration
CTA_HOLD = 5.0      # silent CTA at end

# Total runtime (s)
TOTAL = COVER_HOLD + S2_END + CTA_HOLD

# Per-screen durations (s) — relative to start of video
def make_durations():
    cover_dur = COVER_HOLD
    title_dur = TITLE_END                  # 4.08
    s1_total = S1_END - TITLE_END          # 22.22
    s2_total = S2_END - S1_END             # 20.33
    s1_verso_dur = s1_total / 2
    s1_recto_dur = s1_total - s1_verso_dur
    s2_verso_dur = s2_total / 2
    s2_recto_dur = s2_total - s2_verso_dur
    return [
        ("cover", cover_dur, COVER_IMG),
        ("title", title_dur, PAGES_DIR / "page_01.png"),
        ("s1_verso", s1_verso_dur, PAGES_DIR / "page_04.png"),
        ("s1_recto", s1_recto_dur, PAGES_DIR / "page_05.png"),
        ("s2_verso", s2_verso_dur, PAGES_DIR / "page_06.png"),
        ("s2_recto", s2_recto_dur, PAGES_DIR / "page_07.png"),
        ("cta",   CTA_HOLD, None),  # built below
    ]


# -----------------------------------------------------------------------------
# Letterbox a 1:1 image onto the 1080x1920 vertical canvas
# -----------------------------------------------------------------------------
def make_vertical_canvas(img_path: Path, out_path: Path):
    if out_path.exists():
        return out_path
    img = Image.open(img_path).convert("RGB")
    iw, ih = img.size
    # Scale to fit within W (use full width since square images shrink to W on the 1080 axis)
    scale = W / iw
    new_w = W
    new_h = int(ih * scale)
    if new_h > H:
        scale = H / ih
        new_w = int(iw * scale)
        new_h = H
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGB", (W, H), BG_RGB)
    canvas.paste(resized, ((W - new_w) // 2, (H - new_h) // 2))
    canvas.save(out_path)
    return out_path


# -----------------------------------------------------------------------------
# Build CTA card
# -----------------------------------------------------------------------------
def make_cta_card(out_path: Path):
    if out_path.exists():
        return out_path
    # Background: Knight-Owl dusk indigo (Book 2 cover palette)
    bg = (27, 36, 64)  # #1B2440
    cream = (245, 233, 208)  # #F5E9D0
    gold = (228, 196, 108)   # #E4C46C
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)

    # Try Bookmania / EB Garamond fonts; fall back to default
    font_dirs = [
        SQ / "book" / "assets" / "fonts",
        Path(r"C:\Windows\Fonts"),
    ]
    def _find_font(candidates):
        for d_ in font_dirs:
            for name in candidates:
                p = d_ / name
                if p.exists():
                    return str(p)
        return None
    bold_path = _find_font(["Bookmania-Black.otf", "Bookmania-Bold.otf", "georgiab.ttf", "arialbd.ttf"])
    body_path = _find_font(["EBGaramond-Italic.ttf", "Bookmania-Italic.otf", "georgiai.ttf", "ariali.ttf"])
    if bold_path is None:
        bold = ImageFont.load_default()
    else:
        bold = ImageFont.truetype(bold_path, 110)
    if body_path is None:
        body = ImageFont.load_default()
    else:
        body = ImageFont.truetype(body_path, 70)

    # Layout: centered stack
    line_top = "SQUISHY SMASH"
    line_sub = "The Lost Sparkle"
    line_cta1 = "Full read-along"
    line_cta2 = "on YouTube"
    line_link = "Link in bio"

    def center(text, font, y, fill):
        bbox = d.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        d.text(((W - tw) // 2, y), text, font=font, fill=fill)
        return y + (bbox[3] - bbox[1])

    y = 380
    y = center(line_top, bold, y, cream) + 30
    y = center(line_sub, body, y, gold) + 200
    cta_bold = ImageFont.truetype(bold_path, 96) if bold_path else bold
    y = center(line_cta1, cta_bold, y, cream) + 20
    y = center(line_cta2, cta_bold, y, cream) + 200
    link_font = ImageFont.truetype(body_path, 60) if body_path else body
    center(line_link, link_font, y, gold)

    img.save(out_path)
    return out_path


# -----------------------------------------------------------------------------
# Build padded audio: 3s silence + George (trimmed to S2_END) + 5s silence
# -----------------------------------------------------------------------------
def build_teaser_audio():
    audio_out = TMP / "teaser_audio.m4a"
    if audio_out.exists():
        audio_out.unlink()
    # Trim source audio to first S2_END seconds
    trimmed = TMP / "_trimmed.m4a"
    if trimmed.exists():
        trimmed.unlink()
    r = subprocess.run([
        "ffmpeg", "-y", "-i", str(AUDIO_SRC),
        "-t", f"{S2_END:.3f}",
        "-c:a", "aac", "-b:a", "192k",
        str(trimmed),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("trim STDERR:\n", r.stderr[-2000:])
        sys.exit(1)
    # Concat silence + trimmed + silence
    r = subprocess.run([
        "ffmpeg", "-y",
        "-f", "lavfi", "-t", str(COVER_HOLD), "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-i", str(trimmed),
        "-f", "lavfi", "-t", str(CTA_HOLD), "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-filter_complex", "[0:a][1:a][2:a]concat=n=3:v=0:a=1[a]",
        "-map", "[a]",
        "-c:a", "aac", "-b:a", "192k",
        str(audio_out),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("concat STDERR:\n", r.stderr[-2000:])
        sys.exit(1)
    return audio_out


# -----------------------------------------------------------------------------
# Main: build canvases, write concat, encode
# -----------------------------------------------------------------------------
def main():
    durations = make_durations()
    canvases = []
    for name, dur, src in durations:
        out = TMP / f"canvas_{name}.png"
        if name == "cta":
            make_cta_card(out)
        else:
            make_vertical_canvas(src, out)
        canvases.append((out, dur))

    concat_file = TMP / "concat.txt"
    with open(concat_file, "w", encoding="utf-8") as f:
        for canvas, dur in canvases:
            f.write(f"file '{canvas.as_posix()}'\n")
            f.write(f"duration {dur:.3f}\n")
        f.write(f"file '{canvases[-1][0].as_posix()}'\n")

    audio = build_teaser_audio()

    print(f">>> Encoding {OUT_VIDEO} ...")
    r = subprocess.run([
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0", "-i", str(concat_file),
        "-i", str(audio),
        "-c:v", "libx264", "-pix_fmt", "yuv420p",
        "-r", "30", "-tune", "stillimage", "-preset", "slow", "-crf", "22",
        "-c:a", "aac", "-b:a", "128k",
        "-shortest", "-movflags", "+faststart",
        str(OUT_VIDEO),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("STDERR:\n", r.stderr[-3000:])
        sys.exit(1)
    size_mb = OUT_VIDEO.stat().st_size / 1024 / 1024
    print(f">>> DONE: {OUT_VIDEO} ({size_mb:.1f} MB, runtime {TOTAL:.1f}s)")


if __name__ == "__main__":
    main()
