# Object Sprites — PLACEHOLDER

The MVP currently renders **procedural CustomPainter sprites** from
`lib/game/render/object_painters.dart` — the game is fully playable and
visually distinct without any PNG files.

When you have final art ready, drop 256x256 PNGs here and update
`SmashableComponent` to use a `SpriteComponent` instead of the painter.
Filenames must match the `sprite` field in `assets/data/packs/*.json`:

- dumplio.png
- jellyzap.png
- poppling.png
- slimeorb.png
- goodrop.png
- popzee.png
- squishkin.png
- snagglet.png
- gloomp.png

**Plug-in target:** Arts.io / Midjourney / DALL-E. Reference prompts in
`squishy_smash_assets_pack/arts_io_prompts.txt` (project root, one level up).
