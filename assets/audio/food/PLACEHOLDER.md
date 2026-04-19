# Food Pack Audio — PLACEHOLDER

Drop in WAV files (≤300ms each) matching the `impactSounds` and
`burstSound` fields of `launch_squishy_foods.json`. Recommended layering:

- 4 light hit variants per object
- 1 burst variant per object
- pitch jitter handled at runtime in `sound_manager.dart`

**Plug-in target:** ElevenLabs sound effects (`text_to_sound_effects`) +
recorded household Foley. See `prompts/elevenlabs_audio_direction.md` in
the brief pack.

Until WAVs are added, `SoundManager.play()` silently no-ops — gameplay
remains functional.
