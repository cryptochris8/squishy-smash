"""
Generate marketing voiceover MP3s via ElevenLabs.

Two scripts are supported:

  storybook (Squishkeeper, in-character) — Lily, British "velvety actress"
      Files: assets/audio/marketing/vo_marketing_trailer_<slug>_<voice>.mp3

  ad (third-person ad copy with CTA) — Jessica, American "playful, cute"
      Files: assets/audio/marketing/vo_marketing_ad_<slug>_<voice>.mp3

Reads ELEVENLABS_API_KEY from env. Writes per-segment MP3s so a video
editor can drop each line on its own track and time it independently
to the screen recording.

Usage:
    set ELEVENLABS_API_KEY=...   (Windows cmd)
    $env:ELEVENLABS_API_KEY="..."   (PowerShell)
    export ELEVENLABS_API_KEY=...   (bash)
    python tools/generate_marketing_vo.py --script ad
    python tools/generate_marketing_vo.py --script storybook

Optional flags:
    --voice <voice_id>     Override voice ID (default depends on --script)
    --voice-name <name>    Override filename suffix
    --dry-run              Print plan, skip API calls.
"""

from __future__ import annotations

import argparse
import os
import sys
import urllib.request
import urllib.error
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = REPO_ROOT / "assets" / "audio" / "marketing"

MODEL_ID = "eleven_multilingual_v2"

# Voice settings — same baseline for both scripts. Stability 0.55 keeps
# tone consistent across segments; style 0.35 leaves room for performance
# without going theatrical.
VOICE_SETTINGS = {
    "stability": 0.55,
    "similarity_boost": 0.75,
    "style": 0.35,
    "use_speaker_boost": True,
}

# Each script entry:
#   filename_prefix  — prefix on emitted MP3 filenames
#   voice_id         — default ElevenLabs voice (override with --voice)
#   voice_name       — default filename suffix (override with --voice-name)
#   segments         — list of (slug, timecode_label, text)
SCRIPTS = {
    # In-character storybook narration. Squishkeeper voice.
    # Ellipses + em-dashes are deliberate phrasing cues for ElevenLabs.
    "storybook": {
        "filename_prefix": "vo_marketing_trailer",
        "voice_id":   "pFZP5JQG7iQjIQuC4Bku",  # Lily
        "voice_name": "lily",
        "segments": [
            (
                "01_intro",
                "0:00-0:10",
                "Welcome, little smasher. I'm the Squishkeeper... "
                "and my squishies have escaped again.",
            ),
            (
                "02_gameplay_open",
                "0:10-0:25",
                "Tap one. Squish one. Watch them pop — "
                "some splat, some plip, some go kapow.",
            ),
            (
                "03_combos",
                "0:25-0:40",
                "Build a combo. Land a perfect smash. "
                "The bigger the pop... the rarer they fall.",
            ),
            (
                "04_rarity",
                "0:40-0:50",
                "Foil-touched mythics. Glittering golds. "
                "Only the most patient hunters will meet them.",
            ),
            (
                "05_collection",
                "0:50-1:00",
                "Catch them all. Forty-eight little friends, waiting. "
                "Squish on, smasher.",
            ),
        ],
    },

    # 15-second short ad — Reddit/TikTok feed format. One single
    # continuous read; ~10s of speech leaves comfortable headroom for
    # the gameplay SFX to breathe at the edges. No segmentation —
    # build pipeline treats this as one VO clip starting at t=0.
    "ad_15s": {
        "filename_prefix": "vo_marketing_ad_15s",
        "voice_id":   "cgSgspJ2msm6clMCkdW9",  # Jessica
        "voice_name": "jessica",
        "segments": [
            (
                "01_full",
                "0:00-0:15",
                "Tap one. Squish one. Watch them pop. "
                "Forty-eight collectible squishies — only on iPhone. "
                "Squishy Smash. Out now on the App Store.",
            ),
        ],
    },

    # 30-second short ad — Reddit/TikTok mid-form. Hook -> mechanic ->
    # chase -> CTA, all in one continuous read. ~18-20s of speech with
    # breath beats. Splices well across a 30s gameplay-only recording.
    "ad_30s": {
        "filename_prefix": "vo_marketing_ad_30s",
        "voice_id":   "cgSgspJ2msm6clMCkdW9",  # Jessica
        "voice_name": "jessica",
        "segments": [
            (
                "01_full",
                "0:00-0:30",
                "Some squishies splat. Some plip. Some go kapow. "
                "Tap, squish, pop your way through forty-eight collectible "
                "squishies across foods, goo, and creepy-cute creatures. "
                "Build combos. Chase foil-touched mythics. "
                "Squishy Smash — out now on the App Store. "
                "Smash one. You'll see why.",
            ),
        ],
    },

    # Third-person ad copy. Hook -> what -> chase -> collection -> CTA.
    # Tone: modern toy ad, clean, energetic. NOT in-character narration.
    "ad": {
        "filename_prefix": "vo_marketing_ad",
        "voice_id":   "cgSgspJ2msm6clMCkdW9",  # Jessica
        "voice_name": "jessica",
        "segments": [
            (
                "01_hook",
                "0:00-0:10",
                "Meet Squishy Smash — the most satisfying smash game on iPhone.",
            ),
            (
                "02_what",
                "0:10-0:25",
                "Tap, squish, and pop your way through dozens of squishies. "
                "Every smash sounds amazing. Every burst feels just right.",
            ),
            (
                "03_chase",
                "0:25-0:40",
                "Build combos. Chase rare drops. "
                "Foil-touched mythics that only the boldest smashers will ever unlock.",
            ),
            (
                "04_collect",
                "0:40-0:50",
                "Collect all forty-eight squishies — "
                "across foods, goo, and creepy-cute creatures.",
            ),
            (
                "05_cta",
                "0:50-1:00",
                "Squishy Smash. Out now on the App Store. "
                "Smash one. You'll see why.",
            ),
        ],
    },
}


def synthesize(api_key: str, voice_id: str, text: str) -> bytes:
    """POST to ElevenLabs TTS, return MP3 bytes."""
    url = (
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
        f"?output_format=mp3_44100_128"
    )
    body = json.dumps({
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": VOICE_SETTINGS,
    }).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.read()
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        raise SystemExit(
            f"ElevenLabs returned HTTP {e.code}: {err_body}"
        ) from e


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--script", default="ad",
                   choices=sorted(SCRIPTS.keys()),
                   help="Which script to render (default: ad)")
    p.add_argument("--voice",
                   help="Override ElevenLabs voice ID")
    p.add_argument("--voice-name",
                   help="Override filename suffix")
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    cfg = SCRIPTS[args.script]
    voice_id = args.voice or cfg["voice_id"]
    voice_name = args.voice_name or cfg["voice_name"]
    prefix = cfg["filename_prefix"]
    segments = cfg["segments"]

    api_key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not args.dry_run and not api_key:
        print("ERROR: ELEVENLABS_API_KEY env var not set.", file=sys.stderr)
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Script:     {args.script}")
    print(f"Output dir: {OUT_DIR}")
    print(f"Voice:      {voice_name} ({voice_id})")
    print(f"Model:      {MODEL_ID}")
    print(f"Settings:   {VOICE_SETTINGS}")
    print()

    total_chars = sum(len(text) for _, _, text in segments)
    print(f"Total segments: {len(segments)}  ({total_chars} chars)")
    print()

    for slug, tc, text in segments:
        fname = f"{prefix}_{slug}_{voice_name}.mp3"
        out_path = OUT_DIR / fname
        print(f"  [{tc}] {slug}  ({len(text)} chars)")
        print(f"    \"{text}\"")
        if args.dry_run:
            print(f"    -> would write {out_path.relative_to(REPO_ROOT)}")
            continue
        audio = synthesize(api_key, voice_id, text)
        out_path.write_bytes(audio)
        kb = len(audio) / 1024
        print(f"    -> wrote {out_path.relative_to(REPO_ROOT)} ({kb:.1f} KB)")
        print()

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
