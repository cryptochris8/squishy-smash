"""Mix the polished Book #2 audiobook: George VO + looped music bed + timed SFX, mastered."""
import subprocess, os, sys

HOME = r"C:\Users\chris"
VO = os.path.join(HOME, "squishy_book2_george.mp3")
MUSIC = os.path.join(HOME, "_tmp_book2_music.mp3")
POP = os.path.join(HOME, "_tmp_book2_pop.mp3")
SPARKLE = os.path.join(HOME, "_tmp_book2_sparkle.mp3")
OUT = os.path.join(HOME, "squishy_book2_audiobook_v1.mp3")

# George VO duration probed via ffprobe (5:37.6 ≈ 337.62s in the Pfft re-render).
# ElevenLabs picks slightly different cadence per render — if you re-render
# george.mp3, re-derive these constants via silencedetect (`-32dB d=1.1`).
VO_DURATION = 337.62

# SFX placement (absolute seconds) — re-derived from silencedetect on the
# Pfft re-render. Cadence shifted +5s vs the original take.
#   S12 (EVERYBODY SQUISH!) starts at 243.21s — the shout lands mid-spread,
#   so the three pops sit ~9.5-11s in.
#   S14 (Sparkle came back) starts at 281.33s — chime on the opening word.
POP_TIMES = [252.8, 253.5, 254.3]
SPARKLE_TIME = 281.8

# Mix levels — pulled-back so the VO stays unambiguously dominant.
MUSIC_VOL = 0.08
POP_VOL = 0.35
SPARKLE_VOL = 0.30

filter_parts = [
    "[0:a]volume=1.0[vo]",
    f"[1:a]volume={MUSIC_VOL},afade=t=in:st=0:d=2,afade=t=out:st={VO_DURATION-2.5}:d=2.5[mus]",
]
for i, t in enumerate(POP_TIMES):
    filter_parts.append(
        f"[2:a]adelay={int(t*1000)}:all=1,volume={POP_VOL}[pop{i}]"
    )
filter_parts.append(
    f"[3:a]adelay={int(SPARKLE_TIME*1000)}:all=1,volume={SPARKLE_VOL}[spark]"
)
mix_label_chain = "[vo][mus]" + "".join(f"[pop{i}]" for i in range(len(POP_TIMES))) + "[spark]"
n_inputs = 2 + len(POP_TIMES) + 1  # vo + mus + 3 pops + sparkle = 6
filter_parts.append(
    f"{mix_label_chain}amix=inputs={n_inputs}:duration=first:normalize=0,"
    "alimiter=limit=0.95[aout]"
)
filter_complex = ";".join(filter_parts)

# Note: [2:a] is referenced 3 times (one per pop), so ffmpeg auto-splits the
# pop input. Same for the sparkle input [3:a] (referenced once, no split needed).
# Actually ffmpeg requires explicit asplit if a pad is reused. Let's split [2:a] first.
filter_complex = (
    "[2:a]asplit=" + str(len(POP_TIMES)) + "".join(f"[psrc{i}]" for i in range(len(POP_TIMES))) + ";"
    + ";".join([
        "[0:a]volume=1.0[vo]",
        f"[1:a]volume={MUSIC_VOL},afade=t=in:st=0:d=2,afade=t=out:st={VO_DURATION-2.5}:d=2.5[mus]",
    ])
    + ";"
    + ";".join([
        f"[psrc{i}]adelay={int(t*1000)}:all=1,volume={POP_VOL}[pop{i}]"
        for i, t in enumerate(POP_TIMES)
    ])
    + ";"
    + f"[3:a]adelay={int(SPARKLE_TIME*1000)}:all=1,volume={SPARKLE_VOL}[spark]"
    + ";"
    + f"{mix_label_chain}amix=inputs={n_inputs}:duration=first:normalize=0,alimiter=limit=0.95[aout]"
)

cmd = [
    "ffmpeg", "-y",
    "-i", VO,
    "-stream_loop", "-1", "-i", MUSIC,
    "-i", POP,
    "-i", SPARKLE,
    "-filter_complex", filter_complex,
    "-map", "[aout]",
    "-c:a", "libmp3lame", "-b:a", "192k", "-ar", "44100",
    OUT,
]

print(">>> ffmpeg mix")
r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
if r.returncode != 0:
    print("STDERR:\n", r.stderr[-3500:])
    sys.exit(1)
print(f"DONE: {OUT}")
