"""
Stitch a marketing voiceover onto the screen recording.

Two scripts are supported (must match tools/generate_marketing_vo.py):

  storybook  -> marketing/squishy_smash_trailer_<voice>.mp4
                In-character Squishkeeper narration (Lily by default).

  ad         -> marketing/squishy_smash_ad_<voice>.mp4
                Third-person ad copy with CTA (Jessica by default).

Lays each VO segment on its own delayed track, ducks the original
game-SFX bed to ~35% so the VO reads clearly, and re-encodes
HEVC -> H.264 so the output plays everywhere (App Store preview,
TikTok, Reels, X, browser-embedded).

Usage:
    python tools/build_trailer_video.py --script ad
    python tools/build_trailer_video.py --script storybook
    python tools/build_trailer_video.py --script ad --bed-volume 0.5
    python tools/build_trailer_video.py --script ad --dry-run

Requires ffmpeg. On this machine it's at the winget shim path; pass
--ffmpeg <path> to override.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
VIDEO_IN = (REPO_ROOT / "assets" / "images"
            / "ScreenRecording_04-27-2026 19-10-53_1.MP4")
VO_DIR = REPO_ROOT / "assets" / "audio" / "marketing"
OUT_DIR = REPO_ROOT / "marketing"

DEFAULT_FFMPEG = (
    r"C:\Users\chris\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe"
)

# Per-script config. Each entry:
#   vo_prefix      — prefix on the VO mp3 filenames
#                    (matches generate_marketing_vo.py SCRIPTS[*].filename_prefix)
#   default_voice  — filename suffix to assume when --voice-name not passed
#   out_prefix     — prefix on the output mp4 filename
#   segments       — (slug, start_offset_ms) per VO clip
SCRIPTS = {
    "storybook": {
        "vo_prefix":     "vo_marketing_trailer",
        "default_voice": "lily",
        "out_prefix":    "squishy_smash_trailer",
        "segments": [
            ("01_intro",          0),
            ("02_gameplay_open",  10_000),
            ("03_combos",         25_000),
            ("04_rarity",         40_000),
            ("05_collection",     50_000),
        ],
    },
    "ad": {
        "vo_prefix":     "vo_marketing_ad",
        "default_voice": "jessica",
        "out_prefix":    "squishy_smash_ad",
        "segments": [
            ("01_hook",     0),
            ("02_what",     10_000),
            ("03_chase",    25_000),
            ("04_collect",  40_000),
            ("05_cta",      50_000),
        ],
    },
}


def build_filter_graph(num_vo: int, bed_volume: float, vo_gain: float,
                       segments: list) -> str:
    """Compose the -filter_complex string.

    Inputs assumed to be: 0=video+bed-audio, 1..N=VO segments.
    """
    parts = []
    vo_labels = []
    for idx, (_slug, offset_ms) in enumerate(segments, start=1):
        # adelay needs one value per channel; VO files are stereo so two.
        parts.append(
            f"[{idx}:a]adelay={offset_ms}|{offset_ms}[v{idx}]"
        )
        vo_labels.append(f"[v{idx}]")
    # Mix the delayed VO tracks. normalize=0 keeps each at full level
    # (default amix divides by N which would crater the VO).
    parts.append(
        f"{''.join(vo_labels)}"
        f"amix=inputs={num_vo}:duration=longest:normalize=0,"
        f"volume={vo_gain}[vo]"
    )
    # Duck the bed so the VO sits clearly on top.
    parts.append(f"[0:a]volume={bed_volume}[bed]")
    # Final mix; duration=first trims any VO tail past the video length.
    parts.append("[bed][vo]amix=inputs=2:duration=first:normalize=0[mix]")
    return ";".join(parts)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--script", default="ad",
                   choices=sorted(SCRIPTS.keys()),
                   help="Which VO script to build (default: ad)")
    p.add_argument("--voice-name",
                   help="Override VO filename voice suffix")
    p.add_argument("--bed-volume", type=float, default=0.35,
                   help="Original game-SFX volume (0.0 = mute, 1.0 = full)")
    p.add_argument("--vo-gain", type=float, default=1.0,
                   help="VO gain multiplier (1.0 = ElevenLabs default)")
    p.add_argument("--crf", type=int, default=20,
                   help="x264 quality (lower = better, 18-23 typical)")
    p.add_argument("--preset", default="medium",
                   help="x264 preset (slower = smaller file at same quality)")
    p.add_argument("--audio-bitrate", default="192k",
                   help="AAC bitrate (e.g. 96k, 128k, 192k)")
    p.add_argument("--ffmpeg", default=DEFAULT_FFMPEG,
                   help="Path to ffmpeg.exe")
    p.add_argument("--out", type=Path, default=None,
                   help="Output path; default marketing/<out_prefix>_<voice>.mp4")
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    cfg = SCRIPTS[args.script]
    voice_name = args.voice_name or cfg["default_voice"]
    vo_prefix = cfg["vo_prefix"]
    out_prefix = cfg["out_prefix"]
    segments = cfg["segments"]

    ffmpeg = args.ffmpeg if Path(args.ffmpeg).exists() else shutil.which("ffmpeg")
    if not ffmpeg:
        print("ERROR: ffmpeg not found. Pass --ffmpeg <path>.", file=sys.stderr)
        return 1

    if not VIDEO_IN.exists():
        print(f"ERROR: input video not found: {VIDEO_IN}", file=sys.stderr)
        return 1

    vo_files = []
    for slug, _offset in segments:
        fname = f"{vo_prefix}_{slug}_{voice_name}.mp3"
        path = VO_DIR / fname
        if not path.exists():
            print(f"ERROR: VO segment missing: {path}", file=sys.stderr)
            return 1
        vo_files.append(path)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = args.out or (OUT_DIR / f"{out_prefix}_{voice_name}.mp4")

    filter_graph = build_filter_graph(
        len(segments), args.bed_volume, args.vo_gain, segments,
    )

    cmd = [
        ffmpeg,
        "-y",
        "-i", str(VIDEO_IN),
    ]
    for vo in vo_files:
        cmd += ["-i", str(vo)]
    cmd += [
        "-filter_complex", filter_graph,
        "-map", "0:v",
        "-map", "[mix]",
        # Re-encode HEVC -> H.264 for universal compatibility (App Store
        # preview, TikTok, Reels, X embeds all want H.264 baseline-ish).
        "-c:v", "libx264",
        "-preset", args.preset,
        "-crf", str(args.crf),
        "-pix_fmt", "yuv420p",
        # AAC stereo audio.
        "-c:a", "aac",
        "-b:a", args.audio_bitrate,
        "-ar", "44100",
        "-ac", "2",
        # Faststart so social platforms can begin streaming before
        # the file is fully buffered.
        "-movflags", "+faststart",
        str(out_path),
    ]

    print("Script:     ", args.script)
    print("Input video:", VIDEO_IN.relative_to(REPO_ROOT))
    print("VO voice:   ", voice_name)
    print("Bed volume: ", args.bed_volume)
    print("VO gain:    ", args.vo_gain)
    print("Output:     ", out_path.relative_to(REPO_ROOT))
    print()
    print("Filter graph:")
    for line in filter_graph.split(";"):
        print(f"  {line}")
    print()

    if args.dry_run:
        print("Dry-run. Skipping ffmpeg.")
        return 0

    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print("ffmpeg FAILED")
        print(proc.stderr[-3000:])
        return proc.returncode

    if out_path.exists():
        mb = out_path.stat().st_size / (1024 * 1024)
        print(f"Wrote {out_path.relative_to(REPO_ROOT)} ({mb:.1f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
