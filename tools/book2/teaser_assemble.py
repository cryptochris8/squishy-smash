"""Assemble Book #2 TikTok teaser v7 — vertical 1080x1920, 37 seconds.

v7 attempt vs v6: re-add Ken Burns. Hypothesis on v3/v4 breakage:
  -loop 1 -t {dur} -i image.png fed zoompan multiple input frames, each of
  which triggered a separate zoompan cycle, and the concat downstream got
  confused. Fix: drop -loop and -t from zoompan-treated inputs. ffmpeg's
  image2 demuxer gives ONE input frame, and zoompan's d=frames + fps=30
  generates the full scene duration of output frames. End card still uses
  -loop 1 -t since it's a static scene.

If frames verify all scenes appear, this ships. Otherwise v6 stands as final.

(All v6 audio + text + SFX + scene timing preserved.)
"""
import os, subprocess, sys

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
HOME = r"C:\Users\chris"

PLATE_PH = os.path.join(SQ, "book", "spread_poc", "plate_pudding_hills.png")
PLATE_GC = os.path.join(SQ, "book", "spread_poc", "plate_goo_coast.png")
PLATE_MH = os.path.join(SQ, "book", "spread_poc", "plate_moonlit_hollow.png")
SCARED = os.path.join(HOME, "_tmp_teaser_scared.png")
TRIUMPHANT = os.path.join(HOME, "_tmp_teaser_triumphant.png")
ENDCARD = os.path.join(HOME, "_tmp_teaser_endcard.png")

GEORGE = os.path.join(HOME, "squishy_book2_george.mp3")
MUSIC = os.path.join(HOME, "_tmp_book2_teaser_music.mp3")
PACT_V2 = os.path.join(HOME, "_tmp_book2_pact_v2.mp3")
PAGE_RUSTLE = os.path.join(HOME, "_tmp_book2_page_rustle.mp3")
BIG_POP = os.path.join(HOME, "_tmp_book2_big_pop.mp3")

OUT = os.path.join(HOME, "squishy_book2_teaser_v7.mp4")
FONT = "assets/google_fonts/Fredoka.ttf"

DUR = [9.0, 3.0, 4.0, 7.5, 9.0, 4.5]
TOTAL = sum(DUR)
FPS = 30
MAX_ZOOM = 1.10


def vscale_kenburns(idx, dur):
    """Single-input-frame zoompan. Pre-scale to crop-aspect 1080:1920 first,
    then zoompan does the slow zoom-in centered. d = total output frames."""
    frames = int(dur * FPS)
    inc = (MAX_ZOOM - 1.0) / frames
    return (
        f"[{idx}:v]scale=1920:1920,crop=1080:1920,setsar=1,"
        f"zoompan=z='min(1+{inc:.6f}*on\\,{MAX_ZOOM})':"
        f"d={frames}:s=1080x1920:fps={FPS}:"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)',"
        f"setsar=1,format=yuv420p[v{idx}]"
    )


def vscale_endcard(idx):
    return f"[{idx}:v]scale=1080:1920,setsar=1,format=yuv420p,fps={FPS}[v{idx}]"


def drawtext(text, fontsize, y_frac, t0, t1):
    return (
        f"drawtext=fontfile={FONT}:text='{text}':"
        f"fontcolor=white:fontsize={fontsize}:"
        f"borderw=6:bordercolor=black@0.75:"
        f"x=(w-text_w)/2:y=h*{y_frac}:"
        f"enable='between(t,{t0},{t1})'"
    )


filter_parts = [
    vscale_kenburns(0, DUR[0]),
    vscale_kenburns(1, DUR[1]),
    vscale_kenburns(2, DUR[2]),
    vscale_kenburns(3, DUR[3]),
    vscale_kenburns(4, DUR[4]),
    vscale_endcard(5),
    "[v0][v1][v2][v3][v4][v5]concat=n=6:v=1:a=0[concatv]",
    "[concatv]" + ",".join([
        drawtext("Three packs.", 80, 0.18, 1.5, 7.0),
        drawtext("One light.", 80, 0.18, 13.0, 16.0),
        drawtext("EVERYBODY SQUISH!", 110, 0.18, 23.5, 25.5),
        drawtext("Every pop is a hello.", 64, 0.84, 27.5, 29.5),
        drawtext("Every hello comes back.", 64, 0.84, 30.5, 32.5),
    ]) + "[vout]",
    "[6:a]asplit=3[a0][a1][a2]",
    "[a0]atrim=4.0:17.88,asetpts=PTS-STARTPTS,adelay=1500:all=1,volume=1.25[seg_a]",
    "[a1]atrim=237.92:245.3,asetpts=PTS-STARTPTS,adelay=16000:all=1,volume=1.25[seg_b]",
    "[a2]atrim=245.62:248.99,asetpts=PTS-STARTPTS,adelay=23500:all=1,volume=1.25[seg_c]",
    "[8:a]adelay=27870:all=1,volume=1.25[seg_d]",
    f"[7:a]volume=0.20,afade=t=in:st=0:d=1.5,afade=t=out:st={TOTAL-2}:d=2[mus]",
    "[9:a]asplit=3[r0][r1][r2]",
    "[r0]adelay=8800:all=1,volume=0.45[rustle0]",
    "[r1]adelay=11800:all=1,volume=0.45[rustle1]",
    "[r2]adelay=15800:all=1,volume=0.45[rustle2]",
    "[10:a]adelay=23500:all=1,volume=0.60[bigpop]",
    "[seg_a][seg_b][seg_c][seg_d][mus][rustle0][rustle1][rustle2][bigpop]"
    "amix=inputs=9:duration=longest:normalize=0,alimiter=limit=0.95[aout]",
]

filter_complex = ";".join(filter_parts)

# Key change: inputs 0-4 are bare -i (single frame each, zoompan generates duration)
# Input 5 (end card) still uses -loop 1 -t since it's static
cmd = [
    "ffmpeg", "-y",
    "-i", PLATE_PH,
    "-i", PLATE_GC,
    "-i", PLATE_MH,
    "-i", SCARED,
    "-i", TRIUMPHANT,
    "-loop", "1", "-t", str(DUR[5]), "-i", ENDCARD,
    "-i", GEORGE,
    "-stream_loop", "-1", "-i", MUSIC,
    "-i", PACT_V2,
    "-i", PAGE_RUSTLE,
    "-i", BIG_POP,
    "-filter_complex", filter_complex,
    "-map", "[vout]", "-map", "[aout]",
    "-t", str(TOTAL),
    "-c:v", "libx264", "-preset", "medium", "-crf", "19",
    "-pix_fmt", "yuv420p", "-r", str(FPS),
    "-movflags", "+faststart",
    "-c:a", "aac", "-b:a", "192k",
    OUT,
]

print(">>> ffmpeg teaser v7 assemble (Ken Burns retry — single-frame inputs)")
r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                   errors="replace", cwd=SQ)
if r.returncode != 0:
    print("STDERR:\n", r.stderr[-4000:])
    sys.exit(1)
print(f"DONE: {OUT}")
