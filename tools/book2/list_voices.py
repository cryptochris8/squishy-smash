"""List ElevenLabs voices available on the account with labels + descriptions for selection."""
import json, os, subprocess

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "elevenlabs.txt"), encoding="utf-8").read().strip()

r = subprocess.run(
    ["curl", "--ssl-no-revoke", "-sS",
     "https://api.elevenlabs.io/v1/voices",
     "-H", f"xi-api-key: {KEY}",
     "-w", "\n__HTTP__ %{http_code}\n"],
    capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=SQ,
)
body, _, http = r.stdout.rpartition("\n__HTTP__ ")
print("HTTP:", http.strip())
data = json.loads(body)

voices = data.get("voices", [])
print(f"\nTotal voices: {len(voices)}\n")
for v in voices:
    print(f"[{v.get('category', '?')}] {v.get('name')} ({v.get('voice_id')})")
    labels = v.get('labels') or {}
    if labels:
        # tidy label dict
        kv = ", ".join(f"{k}={v}" for k, v in labels.items() if v)
        print(f"  labels: {kv}")
    desc = v.get('description') or ''
    if desc:
        print(f"  desc: {desc[:240]}")
    print()
