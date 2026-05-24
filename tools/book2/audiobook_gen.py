"""Generate music bed + SFX for the Book #2 audiobook polish via ElevenLabs sound-generation."""
import json, os, subprocess, sys

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "elevenlabs.txt"), encoding="utf-8").read().strip()

SOUNDS = [
    {
        "id": "music",
        "out": os.path.join(HOME, "_tmp_book2_music.mp3"),
        "body": {
            "text": (
                "A gentle soft pastel bedtime children's story music bed. "
                "Soft piano with light music box twinkles, warm ambient pad underneath, "
                "calm dreamy slow tempo, no drums, no vocals, perfect quiet background "
                "for a children's bedtime story narration, seamless loop."
            ),
            "duration_seconds": 22,
            "loop": True,
            "prompt_influence": 0.4,
        },
    },
    {
        "id": "pop",
        "out": os.path.join(HOME, "_tmp_book2_pop.mp3"),
        "body": {
            "text": (
                "A soft cute satisfying squishy pop sound, gentle bubble burst, brief, "
                "friendly and warm not sharp, perfect for a children's story moment."
            ),
            "duration_seconds": 1.0,
            "prompt_influence": 0.5,
        },
    },
    {
        "id": "sparkle",
        "out": os.path.join(HOME, "_tmp_book2_sparkle.mp3"),
        "body": {
            "text": (
                "A soft magical sparkle chime, warm twinkly bell-like sound rising "
                "and resolving, gentle uplift, magical and wondrous like a star appearing, "
                "soft and warm for a children's bedtime story."
            ),
            "duration_seconds": 2.5,
            "prompt_influence": 0.5,
        },
    },
]


def gen(cfg):
    if os.path.exists(cfg["out"]):
        print(f"skip (exists): {cfg['id']}")
        return
    body_path = os.path.join(SQ, f"_tmp_sfx_body_{cfg['id']}.json")
    with open(body_path, "w", encoding="ascii") as f:
        json.dump(cfg["body"], f)
    print(f">>> generate {cfg['id']}")
    r = subprocess.run(
        ["curl", "--ssl-no-revoke", "-sS", "-X", "POST",
         "https://api.elevenlabs.io/v1/sound-generation",
         "-H", f"xi-api-key: {KEY}",
         "-H", "Content-Type: application/json",
         "--data-binary", f"@{body_path}",
         "-o", cfg["out"],
         "-w", "HTTP %{http_code} size %{size_download}\n"],
        capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=SQ,
        timeout=240,
    )
    print(r.stdout)
    if "HTTP 200" not in r.stdout:
        with open(cfg["out"], "rb") as f:
            err = f.read()[:1500]
        print(f"  error: {err.decode('utf-8', 'replace')}")
        sys.exit(1)
    print(f"  -> {cfg['out']}")


for cfg in SOUNDS:
    gen(cfg)
print("DONE")
