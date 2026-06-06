"""Build SRT subtitle file for the George master read-along video.

Approach:
  - Use the 19 manuscript segments (title + 18 spreads)
  - George silence-end anchors are the spread end times
  - Within each spread, split into sentences and allocate time proportional
    to char count
  - Offset everything by +3s (cover hold at start of master video)
  - Emit SRT
"""
import re
from pathlib import Path

HOME = Path(r"C:\Users\chris")
OUT_SRT = HOME / "squishy_book2_readalong_horizontal_george_master.srt"

COVER_OFFSET = 3.0  # seconds of silent cover at start of master video

# George detected silence_end times (end of each segment)
SEGMENT_ENDS = [
    4.08, 26.30, 46.63, 61.83, 83.38, 104.54, 126.35, 153.61, 172.95,
    195.04, 222.13, 243.21, 260.05, 281.33, 292.38, 305.13, 314.08, 329.36,
    337.62,  # end of audio
]
# Manuscript segments (title + 18 spreads). Note: "Pfft"/"Pmf" in audio matches print Pmf.
SEGMENTS_TEXT = [
    # 0: Title
    "Squishy Smash. The Lost Sparkle.",
    # 1: S1
    "Three places had wobbled themselves into being, one for each first feeling. Pudding Hills, where comfort spilled warm. Goo Coast, where surprise spilled glossy. Moonlit Hollow, where the brave-cuddle spilled quiet. Above them all, the Sparkle held. Small and bright. The way being seen is always bright.",
    # 2: S2
    "And then. The Sparkle did something it had never done. It flickered. It wobbled. It split, very gently, into three. One shard drifted toward Pudding Hills. One drifted toward Goo Coast. One drifted toward Moonlit Hollow. The three places, for the first time, felt a little quieter.",
    # 3: S3
    "In Pudding Hills, Soft Dumpling looked up. In Goo Coast, Goo Ball looked up. In Moonlit Hollow, Blushy Bun Bunny looked up. None of them had ever left home before. But each of them, very quietly, decided it was time.",
    # 4: S4
    "Soft Dumpling reached the edge of the Pudding Hills and stopped. The grass was different here. Greener. Glossier. Just past where the syrup river thinned to a trickle, somebody glossy was waiting. \"Sploink,\" said Goo Ball, by way of hello. Soft Dumpling tilted. \"Pmf,\" she answered, which is dumpling for hello back.",
    # 5: S5
    "A third sound came from behind them. Thup, thup. Blushy Bun Bunny hopped out from somewhere between the two worlds, cheeks rosier than usual. \"Oh good,\" said the bunny. \"I had a feeling you would find each other.\" And the three of them, three different feelings standing on a boundary nobody had ever crossed, very gently started walking.",
    # 6: S6
    "They walked through Pudding Hills first. Soft Dumpling led the way, because Pudding Hills was the place she knew. Past the cream-bowl hills. Past the syrup river. Past a small mochi that waved one shimmery wave and pointed quietly toward the orchard. \"The shard fell that way,\" said the shimmery mochi. \"It is bigger than it looks.\"",
    # 7: S7
    "And it was. The shard rested in a hush at the orchard's edge, half-glowing. Above it loomed a dumpling the size of a sky, gentle and enormous, full of small quiet stars. \"I will move,\" said the sky-dumpling, in a voice like a sky, \"when the three of you ask together.\" Soft Dumpling asked. Goo Ball asked. Blushy Bun Bunny asked. The sky-dumpling smiled and stepped aside.",
    # 8: S8
    "Next they crossed into Goo Coast. Now it was Goo Ball who led, because Goo Coast was the place he knew. Past the bubble-tide. Past the glossy shore. Past a goo who shimmered like an opal and pointed seaward. \"The shard fell out there,\" said the opal goo. \"You will have to bounce for it.\"",
    # 9: S9
    "They bounced for it. Soft Dumpling bounced first, which was a surprise to everyone, including Soft Dumpling. Goo Ball bounced second, naturally. Blushy Bun Bunny bounced last and the highest. The shard rose to meet them, glossy and bright, and a cube the color of dawn, who had been watching from the deep, let it go with a slow nod.",
    # 10: S10
    "Last, they crossed into Moonlit Hollow. Now Blushy Bun Bunny led, because Moonlit Hollow was the place she knew. The light was different here. Soft, slow, not afraid of itself. They went past the silver mushrooms. Past a bunny whose eyes were stars, who turned all her stars on them at once. \"The shard is in the deepest grove,\" said the bunny with stars in her eyes. \"It is dimming the fastest.\"",
    # 11: S11
    "The deepest grove was darker than dark. The third shard waited there, almost flickered out, almost too quiet to find. A puff loomed over it, a feeling shaped like a friendly haunting, and said nothing at all. The trio stood very still. The shard was small. The Sparkle, what was left of it, trembled.",
    # 12: S12
    "Then Blushy Bun Bunny did something brave. She squeezed Soft Dumpling. She squeezed Goo Ball. She squeezed herself. \"EVERYBODY SQUISH!\" she shouted, and they did. Three pops at once. Every pop is a hello. Every hello comes back.",
    # 13: S13
    "And the dark grove was suddenly not dark. The three shards rose, glossy and warm and brave at once, and touched. Above them, slow and enormous, the three Cores arrived. Celestial Dumpling Core. Singularity Goo Core. Mythic Plush Familiar. They bowed to the trio who had done what no Core could have done.",
    # 14: S14
    "The Sparkle came back. Not the same Sparkle, exactly. A little bigger, a little warmer. Brighter than it had ever been, because three first feelings had remembered each other.",
    # 15: S15
    "Soft Dumpling carried a little bit of the light home to Pudding Hills. Goo Ball carried a little bit of the light home to Goo Coast. Blushy Bun Bunny carried a little bit of the light home to Moonlit Hollow.",
    # 16: S16
    "Each home was waiting. Each home had been quieter without them. Each home, when they returned, made a sound a pack only makes once.",
    # 17: S17
    "And for the first time, three places that had never visited each other began to. Soft Dumpling visits Goo Coast on Sundays. Goo Ball has tried Moonlit Hollow's quiet. Blushy Bun Bunny is teaching the Pudding Hills how to hop.",
    # 18: S18
    "The Sparkle is the light that comes from being found. I have been there for every wobble. And tomorrow, another wobble. They always come back.",
]
assert len(SEGMENTS_TEXT) == 19
assert len(SEGMENT_ENDS) == 19  # 18 segment ends + audio end


def split_sentences(text: str) -> list[str]:
    """Split into sentences, preserving punctuation. Treats . ! ? as enders,
    but keeps dialogue with embedded punctuation together."""
    # First, protect periods inside abbreviations or quoted dialogue from breaking
    # Simple approach: split on (?<=[.!?])\s+(?=[A-Z"])
    pattern = re.compile(r'(?<=[.!?])\s+(?=["A-Z])')
    parts = pattern.split(text)
    return [p.strip() for p in parts if p.strip()]


def fmt_time(seconds: float) -> str:
    s = max(0.0, seconds)
    h = int(s // 3600)
    m = int((s % 3600) // 60)
    sec = s % 60
    ms = int(round((sec - int(sec)) * 1000))
    if ms == 1000:
        ms = 0
        sec = int(sec) + 1
    return f"{h:02d}:{m:02d}:{int(sec):02d},{ms:03d}"


def build_cues():
    cues = []  # (start, end, text)
    cur_start = 0.0  # within source audio (pre-offset)
    for seg_idx, seg_text in enumerate(SEGMENTS_TEXT):
        seg_end = SEGMENT_ENDS[seg_idx]
        seg_dur = seg_end - cur_start
        sentences = split_sentences(seg_text)
        total_chars = sum(len(s) for s in sentences)
        # First cue starts at segment start; allocate proportional to chars
        t = cur_start
        for i, s in enumerate(sentences):
            frac = len(s) / total_chars
            s_dur = seg_dur * frac
            # Last sentence in segment ends exactly at seg_end (avoid rounding drift)
            s_end = seg_end if i == len(sentences) - 1 else t + s_dur
            cues.append((t + COVER_OFFSET, s_end + COVER_OFFSET, s))
            t = s_end
        cur_start = seg_end
    return cues


def emit_srt(cues, out_path: Path):
    lines = []
    for i, (start, end, text) in enumerate(cues, start=1):
        lines.append(str(i))
        lines.append(f"{fmt_time(start)} --> {fmt_time(end)}")
        lines.append(text)
        lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f">>> {out_path} ({len(cues)} cues)")


if __name__ == "__main__":
    cues = build_cues()
    emit_srt(cues, OUT_SRT)
    # Print first 6 for sanity
    print("\nFirst cues:")
    for c in cues[:6]:
        print(f"  {fmt_time(c[0])} --> {fmt_time(c[1])}  {c[2][:60]}")
