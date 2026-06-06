"""Build a YouTube/TikTok read-along video for Book 2.

Inputs:
  - chris.mp3 (the user's narration)
  - 18 final spread images (page_NN.png) + page_01.png (title)

Output:
  - readalong_book2_horizontal.mp4 (1920x1080)

Timing strategy:
  1. Parse the manuscript into 19 segments (title + 18 spreads)
  2. Count chars per segment
  3. Use detected long-pause breaks (>=1.2s) as fixed anchors (15 known)
  4. For chunks containing multiple segments, split proportionally by char count
"""
import os, re, subprocess, sys, json
from pathlib import Path

HOME = Path(r"C:\Users\chris")
SQ = HOME / "Squishy-smash" / "squishy_smash"
BOOK_OUT = SQ / "book" / "build_book2" / "out"
PAGES_DIR = BOOK_OUT / "pages"
TMP_DIR = HOME / "_tmp_readalong"
TMP_DIR.mkdir(exist_ok=True)

import argparse
_p = argparse.ArgumentParser()
_p.add_argument("--voice", choices=["chris", "george"], default="chris")
_p.add_argument("--quality", choices=["small", "master"], default="small")
_ARGS = _p.parse_args()

_master_suffix = "_master" if _ARGS.quality == "master" else ""
if _ARGS.voice == "george":
    AUDIO = HOME / "squishy_book2_audiobook_v1.mp3"  # George VO + music + SFX
    OUT_VIDEO = HOME / f"squishy_book2_readalong_horizontal_george{_master_suffix}.mp4"
else:
    AUDIO = HOME / "squishy_book2_chris.mp3"
    OUT_VIDEO = HOME / f"squishy_book2_readalong_horizontal{_master_suffix}.mp4"

# Cover image shown for COVER_DURATION seconds (silent) before the VO begins
COVER_IMG = SQ / "book" / "cover" / "cover_front_book2_composite.png"
COVER_DURATION = 3.0
PADDED_AUDIO = TMP_DIR / f"_padded_{_ARGS.voice}.m4a"

# ============================================================================
# Step 1: Parse manuscript into 19 segments
# ============================================================================
MANUSCRIPT = """Squishy Smash. The Lost Sparkle.

<break time="1.5s" />

Three places had wobbled themselves into being, one for each first feeling. Pudding Hills, where comfort spilled warm. Goo Coast, where surprise spilled glossy. Moonlit Hollow, where the brave-cuddle spilled quiet. Above them all, the Sparkle held. Small and bright. The way being seen is always bright.

<break time="1.2s" />

And then. The Sparkle did something it had never done. It flickered. It wobbled. It split, very gently, into three. One shard drifted toward Pudding Hills. One drifted toward Goo Coast. One drifted toward Moonlit Hollow. The three places, for the first time, felt a little quieter.

<break time="1.2s" />

In Pudding Hills, Soft Dumpling looked up. In Goo Coast, Goo Ball looked up. In Moonlit Hollow, Blushy Bun Bunny looked up. None of them had ever left home before. But each of them, very quietly, decided it was time.

<break time="1.2s" />

Soft Dumpling reached the edge of the Pudding Hills and stopped. The grass was different here. Greener. Glossier. Just past where the syrup river thinned to a trickle, somebody glossy was waiting. Sploink, said Goo Ball, by way of hello. Soft Dumpling tilted. Pfft, she answered, which is dumpling for hello back.

<break time="1.2s" />

A third sound came from behind them. Thup, thup. Blushy Bun Bunny hopped out from somewhere between the two worlds, cheeks rosier than usual. "Oh good," said the bunny. "I had a feeling you would find each other." And the three of them, three different feelings standing on a boundary nobody had ever crossed, very gently started walking.

<break time="1.2s" />

They walked through Pudding Hills first. Soft Dumpling led the way, because Pudding Hills was the place she knew. Past the cream-bowl hills. Past the syrup river. Past a small mochi that waved one shimmery wave and pointed quietly toward the orchard. "The shard fell that way," said the shimmery mochi. "It is bigger than it looks."

<break time="1.2s" />

And it was. The shard rested in a hush at the orchard's edge, half-glowing. Above it loomed a dumpling the size of a sky, gentle and enormous, full of small quiet stars. "I will move," said the sky-dumpling, in a voice like a sky, "when the three of you ask together." Soft Dumpling asked. Goo Ball asked. Blushy Bun Bunny asked. The sky-dumpling smiled and stepped aside.

<break time="1.2s" />

Next they crossed into Goo Coast. Now it was Goo Ball who led, because Goo Coast was the place he knew. Past the bubble-tide. Past the glossy shore. Past a goo who shimmered like an opal and pointed seaward. "The shard fell out there," said the opal goo. "You will have to bounce for it."

<break time="1.2s" />

They bounced for it. Soft Dumpling bounced first, which was a surprise to everyone, including Soft Dumpling. Goo Ball bounced second, naturally. Blushy Bun Bunny bounced last and the highest. The shard rose to meet them, glossy and bright, and a cube the color of dawn, who had been watching from the deep, let it go with a slow nod.

<break time="1.2s" />

Last, they crossed into Moonlit Hollow. Now Blushy Bun Bunny led, because Moonlit Hollow was the place she knew. The light was different here. Soft, slow, not afraid of itself. They went past the silver mushrooms. Past a bunny whose eyes were stars, who turned all her stars on them at once. "The shard is in the deepest grove," said the bunny with stars in her eyes. "It is dimming the fastest."

<break time="1.2s" />

The deepest grove was darker than dark. The third shard waited there, almost flickered out, almost too quiet to find. A puff loomed over it, a feeling shaped like a friendly haunting, and said nothing at all. The trio stood very still. The shard was small. The Sparkle, what was left of it, trembled.

<break time="1.2s" />

Then Blushy Bun Bunny did something brave. She squeezed Soft Dumpling. She squeezed Goo Ball. She squeezed herself. "EVERYBODY SQUISH!" she shouted, and they did. Three pops at once. Every pop is a hello. Every hello comes back.

<break time="1.5s" />

And the dark grove was suddenly not dark. The three shards rose, glossy and warm and brave at once, and touched. Above them, slow and enormous, the three Cores arrived. Celestial Dumpling Core. Singularity Goo Core. Mythic Plush Familiar. They bowed to the trio who had done what no Core could have done.

<break time="1.2s" />

The Sparkle came back. Not the same Sparkle, exactly. A little bigger, a little warmer. Brighter than it had ever been, because three first feelings had remembered each other.

<break time="1.2s" />

Soft Dumpling carried a little bit of the light home to Pudding Hills. Goo Ball carried a little bit of the light home to Goo Coast. Blushy Bun Bunny carried a little bit of the light home to Moonlit Hollow.

<break time="1.2s" />

Each home was waiting. Each home had been quieter without them. Each home, when they returned, made a sound a pack only makes once.

<break time="1.2s" />

And for the first time, three places that had never visited each other began to. Soft Dumpling visits Goo Coast on Sundays. Goo Ball has tried Moonlit Hollow's quiet. Blushy Bun Bunny is teaching the Pudding Hills how to hop.

<break time="1.5s" />

The Sparkle is the light that comes from being found. I have been there for every wobble. And tomorrow, another wobble. They always come back."""

# Split on <break> markers, strip whitespace
SEGMENTS = [s.strip() for s in re.split(r'<break\s+time="[^"]+"\s*/>', MANUSCRIPT) if s.strip()]
assert len(SEGMENTS) == 19, f"expected 19 segments, got {len(SEGMENTS)}"
CHAR_COUNTS = [len(s) for s in SEGMENTS]

if _ARGS.voice == "george":
    # George audio: all 18 breaks detected cleanly (silencedetect -32dB d=1.0)
    DETECTED_BREAK_ENDS = [
        4.08, 26.30, 46.63, 61.83, 83.38, 104.54, 126.35, 153.61, 172.95,
        195.04, 222.13, 243.21, 260.05, 281.33, 292.38, 305.13, 314.08, 329.36,
    ]
    ANCHOR_SEG_AT_BREAK = list(range(18))  # all 18 breaks present, in order
    TOTAL_DURATION = 337.618141
else:
    # Chris audio: 15 of 18 breaks detected as long pauses. The 3 missing breaks
    # (between seg 5/6, 10/11, 16/17) get derived by proportional char-count split.
    DETECTED_BREAK_ENDS = [
        3.83, 29.25, 51.05, 66.19, 90.57,
        143.52, 172.49, 195.82, 221.97,
        258.67, 279.20, 296.60, 321.57, 336.64, 382.67,
    ]
    ANCHOR_SEG_AT_BREAK = [0, 1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 15, 17]
    TOTAL_DURATION = 394.135510


def compute_segment_start_times():
    """Compute start time of each of the 19 segments using anchors + char-count distribution."""
    n_segs = len(SEGMENTS)
    start_times = [None] * n_segs
    end_times = [None] * n_segs
    start_times[0] = 0.0
    # Anchors: segment_end[anchor_seg] = break_end_time
    for break_idx, after_seg in enumerate(ANCHOR_SEG_AT_BREAK):
        end_times[after_seg] = DETECTED_BREAK_ENDS[break_idx]
    end_times[n_segs - 1] = TOTAL_DURATION

    # Walk through segments, computing starts from ends; interpolate within gaps
    # First, propagate known boundaries: end_times[i] also implies start_times[i+1] = end_times[i]
    for i in range(n_segs - 1):
        if end_times[i] is not None:
            start_times[i + 1] = end_times[i]

    # For segments with unknown end (missing break), distribute proportionally
    # by char count across the multi-segment chunk
    i = 0
    while i < n_segs:
        if end_times[i] is not None:
            i += 1
            continue
        # Find the run of unknowns ending at the next known boundary
        j = i
        while j < n_segs and end_times[j] is None:
            j += 1
        # Now end_times[j] is known. Chunk runs from start_times[i] to end_times[j].
        chunk_start = start_times[i]
        chunk_end = end_times[j]
        chunk_duration = chunk_end - chunk_start
        chunk_segs = list(range(i, j + 1))
        chunk_chars = sum(CHAR_COUNTS[k] for k in chunk_segs)
        cursor = chunk_start
        for k in chunk_segs:
            seg_dur = chunk_duration * CHAR_COUNTS[k] / chunk_chars
            end_times[k] = cursor + seg_dur
            cursor = end_times[k]
            if k + 1 < n_segs:
                start_times[k + 1] = end_times[k]
        i = j + 1

    return start_times, end_times


# ============================================================================
# Step 2: Map segments to image files
# ============================================================================
def get_image_for_segment(seg_idx):
    """seg 0 = title (page 1). seg 1..18 = spread 1..18 (joined verso+recto)."""
    if seg_idx == 0:
        return PAGES_DIR / "page_01.png"
    # Spread N → page_(2+2N) verso + page_(3+2N) recto (since p4=S1v, p5=S1r, p6=S2v, ...)
    spread_num = seg_idx  # seg 1 = spread 1
    verso = PAGES_DIR / f"page_{4 + (spread_num-1)*2:02d}.png"
    recto = PAGES_DIR / f"page_{4 + (spread_num-1)*2 + 1:02d}.png"
    return _build_joined_image(verso, recto, spread_num)


def _build_joined_image(verso, recto, spread_num):
    out = TMP_DIR / f"spread_{spread_num:02d}_joined.png"
    if out.exists():
        return out
    from PIL import Image
    left = Image.open(verso)
    right = Image.open(recto)
    w, h = left.size
    joined = Image.new("RGB", (w * 2, h), (16, 16, 24))
    joined.paste(left, (0, 0))
    joined.paste(right, (w, 0))
    joined.save(out)
    return out


# ============================================================================
# Step 3: Create a single full-page version per segment, scaled to 1920x1080
# with letterboxing
# ============================================================================
TARGET_W, TARGET_H = 1920, 1080


def build_canvas_for_segment(seg_idx, img_path):
    """Create a 1920x1080 canvas with the image centered + letterboxed."""
    from PIL import Image
    out = TMP_DIR / f"canvas_{seg_idx:02d}.png"
    if out.exists():
        return out
    img = Image.open(img_path)
    # Scale to fit
    iw, ih = img.size
    scale = min(TARGET_W / iw, TARGET_H / ih)
    new_w = int(iw * scale)
    new_h = int(ih * scale)
    img_resized = img.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGB", (TARGET_W, TARGET_H), (16, 16, 24))
    canvas.paste(img_resized, ((TARGET_W - new_w) // 2, (TARGET_H - new_h) // 2))
    canvas.save(out)
    return out


# ============================================================================
# Step 4: Build video with ffmpeg concat
# ============================================================================
def _build_padded_audio():
    """Prepend COVER_DURATION seconds of silence to the source audio."""
    if PADDED_AUDIO.exists():
        PADDED_AUDIO.unlink()
    cmd = [
        "ffmpeg", "-y",
        "-f", "lavfi", "-t", str(COVER_DURATION), "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-i", str(AUDIO),
        "-filter_complex", "[0:a][1:a]concat=n=2:v=0:a=1[a]",
        "-map", "[a]",
        "-c:a", "aac", "-b:a", "192k",
        str(PADDED_AUDIO),
    ]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("STDERR (padding):\n", r.stderr[-2000:])
        sys.exit(1)


def build_video(start_times):
    _build_padded_audio()

    n = len(SEGMENTS)
    canvases = []
    durations = []

    # Cover image as new segment 0 (held for COVER_DURATION while audio is silent)
    cover_canvas = TMP_DIR / "canvas_cover.png"
    if not cover_canvas.exists():
        from PIL import Image
        img = Image.open(COVER_IMG)
        iw, ih = img.size
        scale = min(TARGET_W / iw, TARGET_H / ih)
        new_w, new_h = int(iw * scale), int(ih * scale)
        img_resized = img.resize((new_w, new_h), Image.LANCZOS)
        canvas = Image.new("RGB", (TARGET_W, TARGET_H), (16, 16, 24))
        canvas.paste(img_resized, ((TARGET_W - new_w) // 2, (TARGET_H - new_h) // 2))
        canvas.save(cover_canvas)
    canvases.append(cover_canvas)
    durations.append(COVER_DURATION)

    for i in range(n):
        img = get_image_for_segment(i)
        canvas = build_canvas_for_segment(i, img)
        canvases.append(canvas)
        end = TOTAL_DURATION if i == n - 1 else start_times[i + 1]
        durations.append(end - start_times[i])

    # Write concat file
    concat_file = TMP_DIR / "concat.txt"
    with open(concat_file, "w", encoding="utf-8") as f:
        for canvas, dur in zip(canvases, durations):
            f.write(f"file '{canvas.as_posix()}'\n")
            f.write(f"duration {dur:.3f}\n")
        # ffmpeg concat needs the last image listed once more without duration
        f.write(f"file '{canvases[-1].as_posix()}'\n")

    print("=== Segment timing ===")
    print(f"  COVER: start=  0.00s dur={COVER_DURATION:5.2f}s")
    for i, (st, dur) in enumerate(zip(start_times, durations[1:])):
        label = "TITLE" if i == 0 else f"S{i:02d}"
        print(f"  {label}: start={COVER_DURATION + st:6.2f}s dur={dur:5.2f}s chars={CHAR_COUNTS[i]}")

    print(f"\n>>> Encoding {OUT_VIDEO} ...")
    cmd = [
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0", "-i", str(concat_file),
        "-i", str(PADDED_AUDIO),
        "-c:v", "libx264", "-pix_fmt", "yuv420p",
        "-r", "30" if _ARGS.quality == "master" else "10",
        "-tune", "stillimage", "-preset", "slow",
        "-crf", "18" if _ARGS.quality == "master" else "26",
        "-c:a", "aac",
        "-b:a", "192k" if _ARGS.quality == "master" else "96k",
        "-shortest",
        "-movflags", "+faststart",
        str(OUT_VIDEO),
    ]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("STDERR:\n", r.stderr[-3000:])
        sys.exit(1)
    print(f">>> DONE: {OUT_VIDEO}")


if __name__ == "__main__":
    starts, ends = compute_segment_start_times()
    build_video(starts)
