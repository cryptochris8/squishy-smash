"""TikTok teaser v2 — fast character debut.

Skips the abstract landscape/sparkle pages (S1, S2) and jumps directly to S3
where the trio first appears, so the teaser front-loads the characters.

Audio: title narration (0-4.08s) + [JUMP] + S3+S4 narration (46.63-83.38s).
"""
import subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HOME = Path(r"C:\Users\chris")
SQ = HOME / "Squishy-smash" / "squishy_smash"
PAGES_DIR = SQ / "book" / "build_book2" / "out" / "pages"
COVER_IMG = SQ / "book" / "cover" / "cover_front_book2_composite.png"
AUDIO_SRC = HOME / "squishy_book2_audiobook_v1.mp3"
TMP = HOME / "_tmp_tiktok"
TMP.mkdir(exist_ok=True)
OUT_VIDEO = HOME / "squishy_book2_tiktok_teaser_v2.mp4"

W, H = 1080, 1920
BG_RGB = (16, 16, 24)

# Source timing anchors (George audio)
TITLE_END = 4.08
S3_START = 46.63
S3_END = 61.83
S4_END = 83.38

# Teaser timing
COVER_HOLD = 3.0
CTA_HOLD = 5.0

TITLE_DUR = TITLE_END                # 4.08
S3_DUR = S3_END - S3_START           # 15.20
S4_DUR = S4_END - S3_END             # 21.55
# Split each spread duration evenly across verso/recto
S3_VERSO = S3_DUR / 2
S3_RECTO = S3_DUR - S3_VERSO
S4_VERSO = S4_DUR / 2
S4_RECTO = S4_DUR - S4_VERSO
TOTAL = COVER_HOLD + TITLE_DUR + S3_DUR + S4_DUR + CTA_HOLD


def make_vertical_canvas(img_path: Path, out_path: Path):
    if out_path.exists():
        return out_path
    img = Image.open(img_path).convert("RGB")
    iw, ih = img.size
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


def make_cta_card(out_path: Path):
    if out_path.exists():
        return out_path
    bg = (27, 36, 64)
    cream = (245, 233, 208)
    gold = (228, 196, 108)
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    font_dirs = [SQ / "book" / "assets" / "fonts", Path(r"C:\Windows\Fonts")]

    def _find_font(candidates):
        for d_ in font_dirs:
            for name in candidates:
                p = d_ / name
                if p.exists():
                    return str(p)
        return None
    bold_path = _find_font(["Bookmania-Black.otf", "Bookmania-Bold.otf", "georgiab.ttf", "arialbd.ttf"])
    body_path = _find_font(["EBGaramond-Italic.ttf", "Bookmania-Italic.otf", "georgiai.ttf", "ariali.ttf"])
    bold = ImageFont.truetype(bold_path, 110) if bold_path else ImageFont.load_default()
    body = ImageFont.truetype(body_path, 70) if body_path else ImageFont.load_default()
    cta_bold = ImageFont.truetype(bold_path, 96) if bold_path else bold
    link_font = ImageFont.truetype(body_path, 60) if body_path else body

    def center(text, font, y, fill):
        bbox = d.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        d.text(((W - tw) // 2, y), text, font=font, fill=fill)
        return y + (bbox[3] - bbox[1])

    y = 380
    y = center("SQUISHY SMASH", bold, y, cream) + 30
    y = center("The Lost Sparkle", body, y, gold) + 200
    y = center("Full read-along", cta_bold, y, cream) + 20
    y = center("on YouTube", cta_bold, y, cream) + 200
    center("Link in bio", link_font, y, gold)
    img.save(out_path)
    return out_path


def build_teaser_audio():
    """Cut [0..TITLE_END] + [S3_START..S4_END] from George audio, pad with silence
    at start (cover) and end (CTA)."""
    audio_out = TMP / "teaser_v2_audio.m4a"
    if audio_out.exists():
        audio_out.unlink()

    title_clip = TMP / "_v2_title.m4a"
    body_clip = TMP / "_v2_body.m4a"
    for p in (title_clip, body_clip):
        if p.exists():
            p.unlink()

    # Title narration (0 .. TITLE_END)
    r = subprocess.run([
        "ffmpeg", "-y", "-i", str(AUDIO_SRC),
        "-ss", "0", "-t", f"{TITLE_END:.3f}",
        "-c:a", "aac", "-b:a", "192k",
        str(title_clip),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("title clip STDERR:\n", r.stderr[-2000:]); sys.exit(1)

    # S3 + S4 narration (S3_START .. S4_END)
    body_dur = S4_END - S3_START
    r = subprocess.run([
        "ffmpeg", "-y", "-i", str(AUDIO_SRC),
        "-ss", f"{S3_START:.3f}", "-t", f"{body_dur:.3f}",
        "-c:a", "aac", "-b:a", "192k",
        str(body_clip),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("body clip STDERR:\n", r.stderr[-2000:]); sys.exit(1)

    # Concat: silence(COVER_HOLD) + title + body + silence(CTA_HOLD)
    r = subprocess.run([
        "ffmpeg", "-y",
        "-f", "lavfi", "-t", str(COVER_HOLD), "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-i", str(title_clip),
        "-i", str(body_clip),
        "-f", "lavfi", "-t", str(CTA_HOLD), "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-filter_complex", "[0:a][1:a][2:a][3:a]concat=n=4:v=0:a=1[a]",
        "-map", "[a]",
        "-c:a", "aac", "-b:a", "192k",
        str(audio_out),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("concat STDERR:\n", r.stderr[-2000:]); sys.exit(1)
    return audio_out


def main():
    segments = [
        ("cover", COVER_HOLD, COVER_IMG),
        ("title", TITLE_DUR, PAGES_DIR / "page_01.png"),
        ("s3_verso", S3_VERSO, PAGES_DIR / "page_08.png"),
        ("s3_recto", S3_RECTO, PAGES_DIR / "page_09.png"),
        ("s4_verso", S4_VERSO, PAGES_DIR / "page_10.png"),
        ("s4_recto", S4_RECTO, PAGES_DIR / "page_11.png"),
        ("cta", CTA_HOLD, None),
    ]
    canvases = []
    for name, dur, src in segments:
        out = TMP / f"canvas_v2_{name}.png"
        if name == "cta":
            make_cta_card(out)
        else:
            make_vertical_canvas(src, out)
        canvases.append((out, dur))

    concat_file = TMP / "concat_v2.txt"
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
        print("STDERR:\n", r.stderr[-3000:]); sys.exit(1)
    size_mb = OUT_VIDEO.stat().st_size / 1024 / 1024
    print(f">>> DONE: {OUT_VIDEO} ({size_mb:.1f} MB, runtime {TOTAL:.1f}s)")


if __name__ == "__main__":
    main()
