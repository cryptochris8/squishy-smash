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
3. Reuse the existing **`Pregame`** App Store Connect API key integration —
   that exact name is referenced in `codemagic.yaml` under
   `integrations.app_store_connect`. (One Team-level key serves all apps in
   the Apple Developer account.)
4. In the workflow's **Environment variables** section in the Codemagic
   dashboard (NOT in `codemagic.yaml` — Codemagic rejects empty-string
   placeholders), add **`APP_STORE_APPLE_ID`** with the numeric Apple ID of
   the app (visible in App Store Connect → App Info → Apple ID once the app
   listing exists). Leave it unencrypted — it's not a secret.
5. **Sentry crash reporting**: in the same `smash` variable group, add
   **`SENTRY_DSN`** (mark it secure) with the full DSN URL from your
   Sentry project's Settings → Client Keys page. The `flutter build ipa`
   step in `codemagic.yaml` already passes it through via
   `--dart-define=SENTRY_DSN=$SENTRY_DSN` — without this var set, the
   shipped IPA has crash reporting silently off. Empty/missing is
   tolerated by the Dart-side init (no crash on launch), so this is
   safe to add later, but real TestFlight builds should always have it.
6. Set the **`Internal Testers`** TestFlight group up in App Store Connect →
   TestFlight → Internal Testing, or rename the `beta_groups` entry in
   `codemagic.yaml` to match an existing group.

Identifiers already hardcoded (not secrets):
- Team ID: `Q3UH3Y4QUU`
- Bundle ID: `com.athletedomains.squishySmash`

## What's wired

- **Menu / Gameplay / Results / Shop / Settings / Collection** screens with named routes
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
- **48-card collection album** with 3-path unlock system (burst threshold,
  achievements, coin purchase) — see "Card Collection" below

## Card Collection (3-path unlock system)

The album in the Collection screen tracks **48 cards** (16 per pack × 3 packs,
with the canonical 8 Common / 4 Rare / 3 Epic / 1 Legendary composition per
pack) plus **3 separate "keepsake" custom family cards**. Source of truth:

- `assets/cards/final_48/` — WebP card art (~14 MB total)
- `assets/cards/custom_family/` — keepsake cards
- `assets/data/cards_manifest.json` — `{ card_number, name, pack, rarity, packaged_filename }`
- `assets/data/custom_cards_manifest.json` — separate manifest for the family set

**Three concurrent unlock paths.** Any one path is enough to mark a card
unlocked; players can mix paths freely:

| Path | How | Where it's wired |
|---|---|---|
| **Burst threshold** | Burst the matching smashable N times (Common 1 / Rare 3 / Epic 7 / Legendary 15) | `lib/data/card_unlock.dart` `CardUnlockThresholds` |
| **Achievement reward** | Claim an achievement carrying a `CardUnlockReward` | `lib/data/achievement_registry.dart` |
| **Coin purchase** | Spend 50 / 200 / 750 / 2500 coins by rarity | `lib/data/card_unlock.dart` `CardCoinPrice` |

**Wiring a smashable to a card.** Add `"cardNumber": "001/048"` to a smashable
entry in any pack JSON. The game's burst handler calls
`ProgressionRepository.incrementBurstForCard(cardNumber)` on every burst of
that object. Smashables without a `cardNumber` play normally but don't progress
any card — fill mappings in incrementally as content is finalized.

**Achievements.** 8 starter achievements ship in `lib/data/achievement_registry.dart`:
streak milestones (5/7/14 days), combo & score thresholds, lifetime burst count,
first-ever Mythic discovery. Most reward coins or guaranteed-reveal tokens; one
(`first_mythic_ever`) directly unlocks card 048 as the example pattern for
"achievements that unlock cards." Detection runs at round end via
`AchievementDetector` — pure, deterministic, idempotent.

**Custom family cards** are loaded from a separate manifest and rendered in a
clearly separated "Keepsakes" section at the bottom of the album. They are
**not** counted toward the 48-card progress bar — the 48-card collection and
the keepsake set are deliberately decoupled.

### Notes for the website team

The same manifest JSONs in `assets/data/` and the same WebPs in `assets/cards/`
are intended for the marketing site's collection gallery. To keep the two
surfaces in sync:

- **Read-only contract** — the website should **load** these files (e.g., copy
  them into the Netlify build, or fetch them at build time). Do not rewrite
  them; the app's progression logic depends on the field shape.
- **Filtering** — group by `pack` (3 packs) and filter by `rarity` (4 tiers).
  Match the app's terminology: the JSON uses "Legendary" while the internal
  Dart enum uses `mythic`. Surface "Legendary" to users.
- **Custom family cards** — keep them in a separate "private" or "extras"
  section if shown at all; the integration docs in
  `docs/Cards/_extracted/docs_only/docs/website_integration_instructions.md`
  describe the recommended structure.
- **Performance** — the WebPs are already optimized (~140 KB each). Use
  responsive `<picture>` + lazy loading for the grid.

## Folder Layout

```
lib/
├── main.dart                  # bootstrap
├── app.dart                   # MaterialApp + theme
├── core/                      # constants, routes, service locator, analytics stub
├── data/
│   ├── models/                # SmashableDef, ContentPack, LiveOpsSchedule,
│   │                          # PlayerProfile, CardEntry, Achievement
│   ├── repositories/          # PackRepository, ProgressionRepository
│   ├── content_loader.dart    # bundled pack JSON loader
│   ├── card_manifest_loader.dart  # 48-card + family manifests
│   ├── card_unlock.dart       # 3-path unlock derivation + thresholds + prices
│   ├── achievement_registry.dart  # 8 starter achievements
│   ├── achievement_detector.dart  # eligibility scanner
│   └── persistence.dart       # SharedPreferences wrapper
├── ui/                        # menu / gameplay / results / shop / settings /
│   │                          # collection (album) + widgets
│   └── widgets/               # card_album_widgets.dart (FilterPill, RarityPill, ...)
└── game/
    ├── squishy_game.dart      # FlameGame root
    ├── world/arena_world.dart
    ├── components/            # smashable, particles, decals, hud, screen shake
    └── systems/               # score, combo, spawn, sound, haptics
assets/
├── data/                      # packs/*.json, liveops_schedule.json,
│                              # cards_manifest.json, custom_cards_manifest.json
├── cards/{final_48,custom_family}/   # 48-card WebP album + keepsakes
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
