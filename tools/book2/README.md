# Book #2 production scripts

Reusable scripts for the *Squishy Smash: The Lost Sparkle* asset pipeline.
Full context lives in the `book2-spread-poc-validated` memory and in
`book/BOOK2_CONCEPT_DRAFT.md`. Production techniques (silencedetect-driven
audio cuts, Ken Burns zoompan input-frame gotcha, etc.) live in the
`asset-generation-pipeline` memory.

## Visual
- `gen_plates_fal.py` — Generate the 3 pack-world plates via Fal FLUX dev (2048×2048).
- `gen_chars.py` — Generate unified protagonist sprites via Fal FLUX + BiRefNet alpha-mask. Idempotent (skip-if-exists). Edit the `CHARS` list to add new poses.
- `composite_set.py` — Composite the trio onto each plate with PIL + ellipse drop shadows.
- `teaser_compose.py` — Compose teaser-specific scenes: scared trio on Moonlit Hollow, triumphant trio with warm radial burst, end card (1080×1920 brand title + CTA).

## Audio
- `audiobook_tts.py` — Render the full 18-spread manuscript via ElevenLabs TTS using George (`JBFqnCBsd6RMkjVDRZzb`, bedtime storyteller settings).
- `audiobook_gen.py` — Generate the music bed + climax pops + sparkle chime via ElevenLabs sound-generation.
- `audiobook_mix.py` — Mix the polished audiobook (VO + music + SFX + fades + limiter).
- `teaser_music.py` — Generate the teaser-specific music bed (more energy than the bedtime audiobook bed).
- `teaser_v3_assets.py` — One-off renders: re-rendered Pact line with `<break>` tag for middle pause, page rustle SFX, big hug pop SFX.

## Video
- `teaser_assemble.py` — Final teaser v7 assembly: vertical 1080×1920, 37s, concat of 6 scenes, Ken Burns slow zoom, audio mix (4 VO segments + music bed + 3 page rustles + 1 big pop), drawtext overlays.

## Utility
- `list_voices.py` — Dump the ElevenLabs voice catalog with labels + descriptions. Use to pick voices for new content.

## Conventions

- **API keys**: read from `C:\Users\chris\elevenlabs.txt`, `C:\Users\chris\recraft.key.txt`, `C:\Users\chris\fal.key.txt` (all outside the repo).
- **Networking**: curl via `subprocess.run` with `--ssl-no-revoke` (Schannel + Norton on this Windows machine — see `norton-breaks-git-fetch` memory).
- **Source assets**: read from `book/spread_poc/` (plates + chars).
- **Outputs**: written to `C:\Users\chris\` because `.mp3` and `.mp4` are gitignored. The deliverables live with the user, not in the repo.
- **Body JSON files**: scripts write `_tmp_*body*.json` at the project root for curl `--data-binary @file`. These are gitignored.

## Reproducing the final pipeline from scratch

1. `python3 tools/book2/gen_plates_fal.py` — 3 plates → `book/spread_poc/plate_*.png`
2. `python3 tools/book2/gen_chars.py` — 9 sprites → `book/spread_poc/chars/*.png`
3. `python3 tools/book2/audiobook_tts.py` — VO → `C:\Users\chris\squishy_book2_george.mp3`
4. `python3 tools/book2/audiobook_gen.py` — music bed + audiobook SFX
5. `python3 tools/book2/audiobook_mix.py` — final audiobook → `C:\Users\chris\squishy_book2_audiobook_v1.mp3`
6. `python3 tools/book2/teaser_compose.py` — teaser composite scenes
7. `python3 tools/book2/teaser_music.py` — teaser music bed
8. `python3 tools/book2/teaser_v3_assets.py` — teaser SFX + re-rendered Pact line
9. `python3 tools/book2/teaser_assemble.py` — final teaser → `C:\Users\chris\squishy_book2_teaser_v7.mp4`
