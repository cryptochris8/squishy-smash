# Food Pack Audio

**Dumplio (the meme-hook object) is fully wired.** 4 ElevenLabs-generated
MP3s ship in this folder:

- `dumplio_squish_01.mp3` — soft fingertip press, ASMR
- `dumplio_squish_02.mp3` — quick gentle squish with release pop
- `dumplio_squish_03.mp3` — firm press with stretch + squelch
- `dumplio_burst_01.mp3` — big juicy pop with goo splash tail

Still needed (drop in to wire automatically — JSON paths already point
at these filenames):

- `jellyzap_hit_01.mp3`, `jellyzap_hit_02.mp3`, `jellyzap_pop_01.mp3`
- `poppling_hit_01.mp3`, `poppling_hit_02.mp3`, `poppling_burst_01.mp3`

Format: MP3 @ 44.1 kHz / 128 kbps (the ElevenLabs default). Both .mp3
and .wav play through `flame_audio` — file extension just needs to match
what's referenced in `launch_squishy_foods.json`.

**Plug-in target:** ElevenLabs `text_to_sound_effects` MCP. See the four
prompts in commit `<latest>` for tone direction; mirror them per object.
