"""Generate teaser-specific music bed via ElevenLabs sound-generation."""
import json, os, subprocess, sys

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "elevenlabs.txt"), encoding="utf-8").read().strip()

body = {
    "text": (
        "A magical mysterious children's story teaser music. "
        "Soft music box melody with subtle gentle pulse, hint of orchestral build "
        "with light strings and twinkles, dreamy and inviting, gentle wonder, "
        "perfect for a 30 second children's story trailer, "
        "no vocals, no drums, seamless loop, slowly building anticipation."
    ),
    "duration_seconds": 22,
    "loop": True,
    "prompt_influence": 0.5,
}

body_path = os.path.join(SQ, "_tmp_sfx_body_teaser_music.json")
with open(body_path, "w", encoding="ascii") as f:
    json.dump(body, f)

out_path = os.path.join(HOME, "_tmp_book2_teaser_music.mp3")
print(">>> generate teaser music bed")
r = subprocess.run(
    ["curl", "--ssl-no-revoke", "-sS", "-X", "POST",
     "https://api.elevenlabs.io/v1/sound-generation",
     "-H", f"xi-api-key: {KEY}",
     "-H", "Content-Type: application/json",
     "--data-binary", f"@{body_path}",
     "-o", out_path,
     "-w", "HTTP %{http_code} size %{size_download}\n"],
    capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=SQ,
    timeout=240,
)
print(r.stdout)
if "HTTP 200" not in r.stdout:
    with open(out_path, "rb") as f:
        err = f.read()[:1500]
    print("error:", err.decode("utf-8", "replace"))
    sys.exit(1)
print(f"-> {out_path}")
