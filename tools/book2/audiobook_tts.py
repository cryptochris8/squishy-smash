"""Render the full Book #2 manuscript via ElevenLabs TTS (cloned voice 'Chris')."""
import json, os, subprocess, sys

HOME = r"C:\Users\chris"
SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
KEY = open(os.path.join(HOME, "elevenlabs.txt"), encoding="utf-8").read().strip()
# Voice selection — swap VOICE_ID + OUT_NAME to render with a different voice.
# Bedtime/storybook candidates on this account:
#   George   JBFqnCBsd6RMkjVDRZzb  (British male, "Warm, Captivating Storyteller")  <- current
#   Jeanette RILOU7YmBhvwJGDGjNmP  (British female 50s, professional audiobook narrator)
#   Bill     pqHfZKP75CvOlQylNhV4  (American older male, "friendly and comforting")
#   Brian    nPczCjzI2devNBz1zQrb  (American middle-aged male, "deep, resonant and comforting")
#   Chris    lYrrnzRPPSdEjHBryk33  (the user's cloned voice — promo energy, not bedtime)
VOICE_ID = "JBFqnCBsd6RMkjVDRZzb"  # George
OUT_NAME = "squishy_book2_george.mp3"

manuscript = """Squishy Smash. The Lost Sparkle.

<break time="1.5s" />

Three places had wobbled themselves into being, one for each first feeling. Pudding Hills, where comfort spilled warm. Goo Coast, where surprise spilled glossy. Moonlit Hollow, where the brave-cuddle spilled quiet. Above them all, the Sparkle held. Small and bright. The way being seen is always bright.

<break time="1.2s" />

And then. The Sparkle did something it had never done. It flickered. It wobbled. It split, very gently, into three. One shard drifted toward Pudding Hills. One drifted toward Goo Coast. One drifted toward Moonlit Hollow. The three places, for the first time, felt a little quieter.

<break time="1.2s" />

In Pudding Hills, Soft Dumpling looked up. In Goo Coast, Goo Ball looked up. In Moonlit Hollow, Blushy Bun Bunny looked up. None of them had ever left home before. But each of them, very quietly, decided it was time.

<break time="1.2s" />

Soft Dumpling reached the edge of the Pudding Hills and stopped. The grass was different here. Greener. Glossier. Just past where the syrup river thinned to a trickle, somebody glossy was waiting. Sploink, said Goo Ball, by way of hello. Soft Dumpling tilted. Pmf, she answered, which is dumpling for hello back.

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

print(f"manuscript char count: {len(manuscript)}")

body = {
    "text": manuscript,
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
        # Bedtime/storybook settings — calmer than promo: pull stability up,
        # pull style down. Keeps the voice's natural character without
        # over-emoting on every sentence.
        "stability": 0.55,
        "similarity_boost": 0.75,
        "style": 0.25,
        "use_speaker_boost": True,
    },
}

body_path = os.path.join(SQ, "_tmp_book2_tts_body.json")
with open(body_path, "w", encoding="ascii") as f:
    json.dump(body, f)

out_path = os.path.join(HOME, OUT_NAME)
print(f"calling ElevenLabs TTS -> {out_path}")
r = subprocess.run(
    ["curl", "--ssl-no-revoke", "-sS", "-X", "POST",
     f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}",
     "-H", f"xi-api-key: {KEY}",
     "-H", "Content-Type: application/json",
     "--data-binary", f"@{body_path}",
     "-o", out_path,
     "-w", "HTTP %{http_code} size %{size_download} time %{time_total}s\n"],
    capture_output=True, text=True, cwd=SQ,
    timeout=420,
)
print(r.stdout)
if r.returncode != 0:
    print("STDERR:", r.stderr[-1500:])
    sys.exit(1)
if "HTTP 200" not in r.stdout:
    with open(out_path, "rb") as f:
        err_body = f.read()[:2000]
    print("Likely error response:", err_body.decode("utf-8", "replace"))
    sys.exit(1)
print(f"DONE: {out_path}")
