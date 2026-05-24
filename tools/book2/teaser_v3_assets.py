"""Generate v3 audio assets — re-rendered Pact line with middle break, page rustle SFX, big hug pop SFX."""
import json, os, subprocess, sys

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "elevenlabs.txt"), encoding="utf-8").read().strip()
VOICE_ID = "JBFqnCBsd6RMkjVDRZzb"  # George


def post(url, body_path, out_path):
    r = subprocess.run(
        ["curl", "--ssl-no-revoke", "-sS", "-X", "POST", url,
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
            print("error:", f.read()[:1500].decode("utf-8", "replace"))
        sys.exit(1)


# 1. Re-render Pact line with explicit middle break tag.
pact_body = {
    "text": 'Every pop is a hello. <break time="1.2s" /> Every hello comes back.',
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
        "stability": 0.55,
        "similarity_boost": 0.75,
        "style": 0.25,
        "use_speaker_boost": True,
    },
}
body_path = os.path.join(SQ, "_tmp_body_pact_v2.json")
with open(body_path, "w", encoding="ascii") as f:
    json.dump(pact_body, f)
print(">>> TTS: pact line (with middle break)")
post(f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}", body_path,
     os.path.join(HOME, "_tmp_book2_pact_v2.mp3"))

# 2. Page rustle SFX — soft transition between scenes.
rustle_body = {
    "text": (
        "A soft gentle page turn rustle, brief paper flip sound, "
        "warm and inviting not sharp, perfect for a children's storybook "
        "scene transition, brief 0.8 seconds."
    ),
    "duration_seconds": 0.8,
    "prompt_influence": 0.55,
}
body_path = os.path.join(SQ, "_tmp_body_rustle.json")
with open(body_path, "w", encoding="ascii") as f:
    json.dump(rustle_body, f)
print(">>> Sound: page rustle")
post("https://api.elevenlabs.io/v1/sound-generation", body_path,
     os.path.join(HOME, "_tmp_book2_page_rustle.mp3"))

# 3. Big hug pop SFX — the EVERYBODY SQUISH moment.
big_pop_body = {
    "text": (
        "A big satisfying joyful squishy hug pop sound, magical warm burst "
        "of light and sparkle, three squishies hugging together releasing "
        "a wave of soft sparkle, gentle bell-like resonance after the pop, "
        "perfect for a children's storybook climax moment, brief 1.5 seconds."
    ),
    "duration_seconds": 1.5,
    "prompt_influence": 0.55,
}
body_path = os.path.join(SQ, "_tmp_body_big_pop.json")
with open(body_path, "w", encoding="ascii") as f:
    json.dump(big_pop_body, f)
print(">>> Sound: big hug pop")
post("https://api.elevenlabs.io/v1/sound-generation", body_path,
     os.path.join(HOME, "_tmp_book2_big_pop.mp3"))

print("DONE")
