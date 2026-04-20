# Food Pack Audio — WIRED

All food-pack SFX are generated and shipped:

- **Dumplio**: `dumplio_squish_01/02/03.mp3` + `dumplio_burst_01.mp3`
- **JellyZap**: `jellyzap_hit_01/02.mp3` + `jellyzap_pop_01.mp3`
- **Poppling**: `poppling_hit_01/02.mp3` + `poppling_burst_01.mp3`

All MP3 @ 44.1kHz / 128kbps. Generated via
`mcp__elevenlabs__text_to_sound_effects`. Filenames exactly match the
`impactSounds` and `burstSound` fields in `launch_squishy_foods.json`.

To regenerate any single sound, fire one new ElevenLabs call into this
folder, then rename the result to overwrite the existing file.
