# Squishy Smash

iOS-first satisfying smash game (Flutter + Flame). Follow-up to the Rage Smash
loop, refocused on squishy/pop/splat ASMR feedback and meme-driven content
packs. Current viral hook: **Dumpling Squishy** (Gloop Dumpling object).

## Run

```bash
flutter pub get
flutter run                    # Android emulator / connected device
flutter test                   # unit tests for combo + score controllers
flutter analyze                # static analysis
```

You're on Windows: dev iteration runs fine on the Android emulator (or
`flutter run -d chrome` for fast art iteration). **iOS App Store builds run
on Codemagic** (`codemagic.yaml` at repo root). The `ios/` folder is already
configured locally for `flutter pub get` to succeed.

### Codemagic setup (one-time)

Two workflows are defined in `codemagic.yaml`:

- **`ios-debug`** — runs `analyze` + `test` + an unsigned `flutter build ios`
  to prove the pipeline works. Trigger manually. **Needs zero secrets.**
- **`ios-release`** — signed build + TestFlight upload. Triggered by pushing
  a git tag matching `v*` (e.g. `git tag v0.1.0 && git push --tags`).

Before `ios-release` will work, in the Codemagic dashboard:

1. **Apps** → connect your git repo (Codemagic needs the project pushed to
   GitHub/GitLab/Bitbucket — it cannot pull from your local Windows folder).
2. **Teams → Integrations → Developer Portal**: add an **App Store Connect API
   Key** (the `.p8` file + Key ID + Issuer ID from
   App Store Connect → Users and Access → Integrations).
3. Name that integration **`squishy_smash_asc_key`** — that exact string is
   referenced in `codemagic.yaml` under `integrations.app_store_connect`.
4. In the workflow's environment, set the var **`APP_STORE_APPLE_ID`** to the
   numeric Apple ID of the app (visible in App Store Connect → App Info →
   Apple ID once the app listing exists).
5. Set the **`Internal Testers`** TestFlight group up in App Store Connect →
   TestFlight → Internal Testing, or rename the `beta_groups` entry in
   `codemagic.yaml` to match an existing group.

Identifiers already hardcoded (not secrets):
- Team ID: `Q3UH3Y4QUU`
- Bundle ID: `com.athletedomains.squishySmash`

## What's wired

- **Menu / Gameplay / Results / Shop / Settings** screens with named routes
- **Flame** game loop with tap-smash, drag-slam, and hold-to-crush input
- Squash-and-stretch deformation via `ScaleEffect` chains (no real physics —
  fake juice on purpose, per `04_audio_vfx_plan.md`)
- **Particle bursts**, **decal splats** (capped FIFO at 30), **screen shake**,
  **haptics** (HapticFeedback API)
- **Score + combo** controllers with decaying streak meter
- **Coin wallet + pack unlock** persisted via `shared_preferences`
- **JSON-driven content packs** (3 launch packs, 9 objects total)
- **LiveOps schedule** loader → pulls "Dumpling Squishy Week" banner onto menu
- **Sound manager** scaffolded against `flame_audio` (silently no-ops until
  WAVs are dropped in)

## Folder Layout

```
lib/
├── main.dart                  # bootstrap
├── app.dart                   # MaterialApp + theme
├── core/                      # constants, routes, service locator, analytics stub
├── data/
│   ├── models/                # SmashableDef, ContentPack, LiveOpsSchedule, PlayerProfile
│   ├── repositories/          # PackRepository, ProgressionRepository
│   ├── content_loader.dart    # bundled JSON loader
│   └── persistence.dart       # SharedPreferences wrapper
├── ui/                        # menu / gameplay / results / shop / settings + widgets
└── game/
    ├── squishy_game.dart      # FlameGame root
    ├── world/arena_world.dart
    ├── components/            # smashable, particles, decals, hud, screen shake
    └── systems/               # score, combo, spawn, sound, haptics
assets/
├── data/                      # packs/*.json, liveops_schedule.json
├── images/{objects,thumbnails,decals,arenas,ui}/   # PLACEHOLDER folders
└── audio/{food,goo,creature,ui}/                   # PLACEHOLDER folders
```

Every empty asset folder has a `PLACEHOLDER.md` describing what art/audio
file to drop in and the exact filename the JSON expects.

## Adding a New Content Pack (the whole point)

Per `03_content_pipeline.md` you should be able to ship a new themed drop in
under an hour without touching gameplay code. Recipe:

1. Copy `assets/data/packs/launch_squishy_foods.json` and rename.
2. Edit `packId`, `displayName`, `palette`, `objects[]`. Schema is documented
   in `lib/data/models/smashable_def.dart` and `content_pack.dart`.
3. Drop sprites into `assets/images/objects/` matching each `sprite` path.
4. Drop SFX into `assets/audio/<category>/` matching each sound path.
5. Add the new path to `pubspec.yaml > flutter > assets`.
6. Add the path to `ContentLoader.bundledPackPaths`.
7. (Optional) add a featured-week entry to `liveops_schedule.json` so it
   appears on the menu banner during its launch week.

No gameplay code change required.

## Plug-In Targets (where the AI tools fit)

- **Arts.io / image gen** → `assets/images/objects/*.png` and arena
  backgrounds. Use the prompt direction in `01_product_brief.md` (creepy-cute,
  meme-adjacent, original silhouettes).
- **ElevenLabs `text_to_sound_effects`** → `assets/audio/<pack>/*.wav`. See
  the original brief's `prompts/elevenlabs_audio_direction.md` for tone
  options. 4 light-hit + 1 burst per object minimum.
- **ElevenLabs TTS** → optional pack-intro stinger lines (rare in-game,
  heavier in trailers).
- **Firebase Remote Config** (post-MVP) → swap `ContentLoader.loadAll()` to
  fetch packs remotely; the schema is identical.

## IP Guardrails

Per `08_ip_and_trend_guardrails.md`: all object names are original
("Gloop Dumpling", "Gobble Puff", "Wink Fang", etc). Trend energy lives in
the visual/audio direction, never in the names. Do not rename objects to
match a trending toy line — keep the meme reference in marketing copy only.

## MVP Status & Next Steps

- [x] Milestone 1 — single-object end-to-end (tap → squash → burst → coin)
- [x] Milestone 2 — 9-object rotation, score + combo, particles, decals
- [x] Milestone 3 — pack/shop, unlock persistence, settings, haptics
- [ ] Milestone 4 — App Store assets (5 screenshots per `06_app_store_aso.md`),
      preview video capture, analytics SDK selection, real art + audio drops
- [ ] iOS code-signing on Mac

## Test Plan Before Shipping

- Run on iPhone 11 (oldest target) — confirm 60fps with 30 active decals
- Validate `HapticFeedback.heavyImpact()` actually fires on iOS device
- Confirm `flame_audio` cache hit rate at round start (no audible stalls)
- Record one TikTok-format clip per pack for App Store preview video
