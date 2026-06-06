"""Build the George master read-along with a comprehension quiz appended.

Quiz appears after the closing spread. Silent visual cards. Total quiz tail = 33s.
Output: squishy_book2_readalong_horizontal_george_master_quiz.mp4
"""
import subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HOME = Path(r"C:\Users\chris")
SQ = HOME / "Squishy-smash" / "squishy_smash"
PAGES_DIR = SQ / "book" / "build_book2" / "out" / "pages"
COVER_IMG = SQ / "book" / "cover" / "cover_front_book2_composite.png"
AUDIO_SRC = HOME / "squishy_book2_audiobook_v1.mp3"
TMP = HOME / "_tmp_quiz"
TMP.mkdir(exist_ok=True)
OUT_VIDEO = HOME / "squishy_book2_readalong_horizontal_george_master_quiz.mp4"

W, H = 1920, 1080
BG_RGB = (16, 16, 24)
INDIGO = (27, 36, 64)      # Knight-Owl dusk
CREAM = (245, 233, 208)
GOLD = (228, 196, 108)

COVER_HOLD = 3.0
SOURCE_END = 337.62        # end of George audio in source

# Quiz timing (seconds per card)
QUIZ_INTRO = 2.5
Q_HOLD = 4.0
A_HOLD = 3.0
QUIZ_OUTRO = 3.5

QUIZ = [
    ("What are the names of the three friends?",
     "Soft Dumpling, Goo Ball, and Blushy Bun Bunny"),
    ("What three places did they come from?",
     "Pudding Hills, Goo Coast, and Moonlit Hollow"),
    ("What did they shout together when they were brave?",
     "EVERYBODY SQUISH!"),
    ("Where does the Sparkle come from?",
     "From being found — together"),
]

# George anchors (silence_end seconds in source)
SEGMENT_ENDS = [
    4.08, 26.30, 46.63, 61.83, 83.38, 104.54, 126.35, 153.61, 172.95,
    195.04, 222.13, 243.21, 260.05, 281.33, 292.38, 305.13, 314.08, 329.36,
    337.62,
]


# ---------------------------------------------------------------------------
# Font loading
# ---------------------------------------------------------------------------
FONT_DIRS = [SQ / "book" / "assets" / "fonts", Path(r"C:\Windows\Fonts")]

def _find_font(candidates):
    for d in FONT_DIRS:
        for name in candidates:
            p = d / name
            if p.exists():
                return str(p)
    return None

BOLD_PATH = _find_font(["Bookmania-Black.otf", "Bookmania-Bold.otf", "georgiab.ttf", "arialbd.ttf"])
ITALIC_PATH = _find_font(["EBGaramond-Italic.ttf", "Bookmania-Italic.otf", "georgiai.ttf", "ariali.ttf"])
REG_PATH = _find_font(["Bookmania-Regular.otf", "georgia.ttf", "arial.ttf"])


# ---------------------------------------------------------------------------
# Letterbox a single-page image onto the 1920x1080 canvas
# ---------------------------------------------------------------------------
def make_canvas(img_path: Path, out_path: Path):
    if out_path.exists():
        return out_path
    img = Image.open(img_path).convert("RGB")
    iw, ih = img.size
    scale = min(W / iw, H / ih)
    new_w, new_h = int(iw * scale), int(ih * scale)
    img_resized = img.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGB", (W, H), BG_RGB)
    canvas.paste(img_resized, ((W - new_w) // 2, (H - new_h) // 2))
    canvas.save(out_path)
    return out_path


# ---------------------------------------------------------------------------
# Generic centered text drawer with word-wrap
# ---------------------------------------------------------------------------
def _wrap(text, font, max_w, draw):
    words = text.split()
    lines = []
    cur = []
    for w in words:
        trial = " ".join(cur + [w])
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] > max_w and cur:
            lines.append(" ".join(cur))
            cur = [w]
        else:
            cur.append(w)
    if cur:
        lines.append(" ".join(cur))
    return lines


def _draw_centered_block(canvas, lines, font, color, y_start, line_gap=20):
    d = ImageDraw.Draw(canvas)
    y = y_start
    for line in lines:
        bbox = d.textbbox((0, 0), line, font=font)
        tw = bbox[2] - bbox[0]
        d.text(((W - tw) // 2, y), line, font=font, fill=color)
        y += (bbox[3] - bbox[1]) + line_gap
    return y


# ---------------------------------------------------------------------------
# Quiz card builders
# ---------------------------------------------------------------------------
def make_intro_card(out_path: Path):
    if out_path.exists():
        return out_path
    canvas = Image.new("RGB", (W, H), INDIGO)
    d = ImageDraw.Draw(canvas)
    title_font = ImageFont.truetype(BOLD_PATH, 180) if BOLD_PATH else ImageFont.load_default()
    sub_font = ImageFont.truetype(ITALIC_PATH, 80) if ITALIC_PATH else ImageFont.load_default()
    # Centered vertically-ish
    bbox = d.textbbox((0, 0), "Quiz Time!", font=title_font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((W - tw) // 2, (H - th) // 2 - 60), "Quiz Time!", font=title_font, fill=CREAM)
    sub = "How well do you remember the story?"
    bbox = d.textbbox((0, 0), sub, font=sub_font)
    sw = bbox[2] - bbox[0]
    d.text(((W - sw) // 2, (H - th) // 2 + 180), sub, font=sub_font, fill=GOLD)
    canvas.save(out_path)
    return out_path


def make_question_card(idx: int, question: str, out_path: Path):
    if out_path.exists():
        return out_path
    canvas = Image.new("RGB", (W, H), INDIGO)
    d = ImageDraw.Draw(canvas)
    label_font = ImageFont.truetype(BOLD_PATH, 80) if BOLD_PATH else ImageFont.load_default()
    q_font = ImageFont.truetype(REG_PATH, 90) if REG_PATH else ImageFont.load_default()
    label = f"Question {idx}"
    bbox = d.textbbox((0, 0), label, font=label_font)
    lw = bbox[2] - bbox[0]
    d.text(((W - lw) // 2, 220), label, font=label_font, fill=GOLD)
    # Wrap question
    lines = _wrap(question, q_font, int(W * 0.78), d)
    _draw_centered_block(canvas, lines, q_font, CREAM, 460, line_gap=24)
    canvas.save(out_path)
    return out_path


def make_answer_card(idx: int, answer: str, out_path: Path):
    if out_path.exists():
        return out_path
    canvas = Image.new("RGB", (W, H), INDIGO)
    d = ImageDraw.Draw(canvas)
    label_font = ImageFont.truetype(BOLD_PATH, 70) if BOLD_PATH else ImageFont.load_default()
    a_font = ImageFont.truetype(BOLD_PATH, 110) if BOLD_PATH else ImageFont.load_default()
    label = "Answer"
    bbox = d.textbbox((0, 0), label, font=label_font)
    lw = bbox[2] - bbox[0]
    d.text(((W - lw) // 2, 240), label, font=label_font, fill=CREAM)
    lines = _wrap(answer, a_font, int(W * 0.85), d)
    _draw_centered_block(canvas, lines, a_font, GOLD, 420, line_gap=22)
    canvas.save(out_path)
    return out_path


def make_outro_card(out_path: Path):
    if out_path.exists():
        return out_path
    canvas = Image.new("RGB", (W, H), INDIGO)
    d = ImageDraw.Draw(canvas)
    big = ImageFont.truetype(BOLD_PATH, 140) if BOLD_PATH else ImageFont.load_default()
    small = ImageFont.truetype(ITALIC_PATH, 70) if ITALIC_PATH else ImageFont.load_default()
    line1 = "Thanks for reading along."
    bbox = d.textbbox((0, 0), line1, font=big)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((W - tw) // 2, (H - th) // 2 - 60), line1, font=big, fill=CREAM)
    sub = "Squishy Smash · The Lost Sparkle"
    bbox = d.textbbox((0, 0), sub, font=small)
    sw = bbox[2] - bbox[0]
    d.text(((W - sw) // 2, (H - th) // 2 + 160), sub, font=small, fill=GOLD)
    canvas.save(out_path)
    return out_path


# ---------------------------------------------------------------------------
# Build the master segment list (cover + title + 18 spreads + quiz tail)
# ---------------------------------------------------------------------------
def build_segments():
    """Return list of (label, duration_seconds, source_image_path)."""
    segs = []
    # Cover (silent 3s)
    segs.append(("cover", COVER_HOLD, COVER_IMG))
    # Title
    segs.append(("title", SEGMENT_ENDS[0], PAGES_DIR / "page_01.png"))
    cur = SEGMENT_ENDS[0]
    # 18 spreads — each rejoined verso+recto into one 17.5:8.75 image
    # but the master script uses joined images for horizontal output.
    for s in range(1, 19):
        seg_end = SEGMENT_ENDS[s]
        dur = seg_end - cur
        verso = PAGES_DIR / f"page_{4 + (s-1)*2:02d}.png"
        recto = PAGES_DIR / f"page_{4 + (s-1)*2 + 1:02d}.png"
        joined_path = TMP / f"spread_{s:02d}_joined.png"
        if not joined_path.exists():
            left = Image.open(verso)
            right = Image.open(recto)
            w, h = left.size
            joined = Image.new("RGB", (w * 2, h), (16, 16, 24))
            joined.paste(left, (0, 0))
            joined.paste(right, (w, 0))
            joined.save(joined_path)
        segs.append((f"spread_{s:02d}", dur, joined_path))
        cur = seg_end

    # Quiz intro
    segs.append(("quiz_intro", QUIZ_INTRO, make_intro_card(TMP / "quiz_intro.png")))
    # Questions
    for i, (q, a) in enumerate(QUIZ, start=1):
        segs.append((f"quiz_q{i}", Q_HOLD, make_question_card(i, q, TMP / f"quiz_q{i}.png")))
        segs.append((f"quiz_a{i}", A_HOLD, make_answer_card(i, a, TMP / f"quiz_a{i}.png")))
    # Outro
    segs.append(("quiz_outro", QUIZ_OUTRO, make_outro_card(TMP / "quiz_outro.png")))
    return segs


# ---------------------------------------------------------------------------
# Build audio: 3s silence + George VO + N seconds silence (for quiz tail)
# ---------------------------------------------------------------------------
def build_audio(quiz_tail_seconds: float) -> Path:
    out = TMP / "audio_with_tail.m4a"
    if out.exists():
        out.unlink()
    r = subprocess.run([
        "ffmpeg", "-y",
        "-f", "lavfi", "-t", str(COVER_HOLD), "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-i", str(AUDIO_SRC),
        "-f", "lavfi", "-t", f"{quiz_tail_seconds:.3f}", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-filter_complex", "[0:a][1:a][2:a]concat=n=3:v=0:a=1[a]",
        "-map", "[a]",
        "-c:a", "aac", "-b:a", "192k",
        str(out),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("audio STDERR:\n", r.stderr[-2000:]); sys.exit(1)
    return out


# ---------------------------------------------------------------------------
# Resize joined-spread canvases to 1920x1080 (letterboxed)
# ---------------------------------------------------------------------------
def canvasize(src: Path, label: str) -> Path:
    out = TMP / f"canvas_{label}.png"
    if out.exists():
        return out
    return make_canvas(src, out)


def main():
    segs = build_segments()
    # Materialize canvases
    items = []  # (canvas_path, duration)
    quiz_tail = 0.0
    for label, dur, src in segs:
        if label.startswith("quiz_"):
            # Quiz cards are already at 1920x1080
            items.append((src, dur))
            quiz_tail += dur
        else:
            items.append((canvasize(src, label), dur))

    # Write concat list
    concat_file = TMP / "concat.txt"
    with open(concat_file, "w", encoding="utf-8") as f:
        for canvas, dur in items:
            f.write(f"file '{canvas.as_posix()}'\n")
            f.write(f"duration {dur:.3f}\n")
        f.write(f"file '{items[-1][0].as_posix()}'\n")

    audio = build_audio(quiz_tail)

    print(f">>> Encoding {OUT_VIDEO} ...")
    r = subprocess.run([
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0", "-i", str(concat_file),
        "-i", str(audio),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-r", "30",
        "-tune", "stillimage", "-preset", "slow", "-crf", "18",
        "-c:a", "aac", "-b:a", "192k",
        "-shortest", "-movflags", "+faststart",
        str(OUT_VIDEO),
    ], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("STDERR:\n", r.stderr[-3000:]); sys.exit(1)
    size_mb = OUT_VIDEO.stat().st_size / 1024 / 1024
    total = COVER_HOLD + SOURCE_END + quiz_tail
    print(f">>> DONE: {OUT_VIDEO} ({size_mb:.1f} MB, runtime {total:.1f}s, quiz tail {quiz_tail:.1f}s)")


if __name__ == "__main__":
    main()
