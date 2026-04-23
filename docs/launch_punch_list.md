# Squishy Smash — Launch Punch List

**Snapshot date:** 2026-04-22
**Current shipped tag:** v0.2.1 (skybox PNG optimization + in-app load-failure diagnostic)
**Estimated overall completion:** ~70–75% to App Store submission

---

## ✅ Done (no more generation needed)

| Category | Status |
|---|---|
| **Character sprites (FLUX)** | 17/17 done — 1024×1024 with transparent alpha |
| **Thumbnails** | 17/17 done — 256×256 |
| **Skyboxes (Blockade Labs)** | 16/16 done — all 8 arena themes × calm + reveal |
| **Voice-over audio (ElevenLabs)** | 11/11 done — ASMR idle, mega, rare/epic/mythic reveals |
| **Object burst sounds** | 11/11 done — one big burst per object |
| **iOS app icon** | Custom 1024×1024, all required sizes generated |
| **Codemagic CI/CD for iOS** | Working (v0.2.1 shipped through it) |
| **Core game loop** | Plays end-to-end, browser-confirmed |

---

## 🎙 Audio still to generate in ElevenLabs (41 files)

All light *impact* sounds — squishes, hits, ticks. Each object has 3–5 squish variants currently sitting at 8 KB stub sizes.

- **27 food impact sounds** — squish/hit/tick variants for: dumplio, jellyzap, poppling, steamy, puffkin, dimpa, boblet, moshi, soupy, gobble, gold_dumplio
- **7 goo squeeze/pop variants** — slimeorb, goodrop, popzee
- **7 creature vocalizations** — squishkin snickers, snagglet squeaks, gloomp giggles
- **6 UI stingers** — back, button_tap, coin_ding, confirm, pack_select, settings_toggle (unlock_chime + reveal_stinger already done)

> Game runs without these — `SoundVariantPicker` falls back to the burst sound or silence. Tactile depth on every tap improves once filled in.

---

## 🎨 Visual art still to generate

### Decals (~11 presets needed)
Currently only `assets/images/decals/PLACEHOLDER.md`. `DecalManager` falls back to colored circles.

- `pink_soup_burst`
- `blue_jelly_burst`
- `soft_peach_splat`
- `cool_blue_smear`
- `cream_smudge`
- `cream_puff_burst`
- `green_goo_burst`
- `green_goo_smear`
- `purple_monster_burst`
- `purple_monster_splat`
- `gold_mythic_splat`

### UI kit
Also placeholder-only at `assets/images/ui/PLACEHOLDER.md`. Buttons, frames, badges. Game uses Flutter Material defaults today — functional but not branded.

---

## 🚫 App Store submission blockers (Apple will reject without these)

| Item | Status | Notes |
|---|---|---|
| **Privacy manifest** (`ios/Runner/PrivacyInfo.xcprivacy`) | ❌ Missing | Required since May 2024 |
| **5 screenshots × 6.7″ iPhone** | ❌ Missing | |
| **5 screenshots × 6.5″ iPhone** | ❌ Missing | |
| **5 screenshots × 5.5″ iPhone** | ❌ Missing | |
| **Custom launch screen** | ❌ Default white Flutter logo | Replace `LaunchImage.imageset/*` |
| **App Store description / keywords** | ❌ Not written | Plain-English pitch in memory is the raw material |
| **Age rating questionnaire** | ❌ Not done | Likely 4+ |
| **Support URL & privacy policy URL** | ❌ Not configured | |
| **App preview video** | ❌ Not recorded | Optional but recommended |

---

## 🔧 Technical TODOs (non-blocking for iOS submission)

- **Android release signing** — currently signs releases with debug keys. Two `TODO` comments in `android/app/build.gradle.kts`. Blocks Play Store ever.
- **Analytics sink** — `NoOpAnalytics` is wired everywhere. Drop in Sentry (one DSN, no native config) or Firebase Analytics + Crashlytics for telemetry. The hooks (`assetLoadFailed`, `levelStart`, etc.) are already in place; just bind a real sink in `ServiceLocator.bootstrap()`.
- **`share_capture_test.dart` test timeout** — hangs 10 min on Windows headless because `pumpAndSettle()` waits for frames the headless framebuffer never produces. Fix: add `pumpAndSettle(Duration(seconds: 5))` and skip on Windows.
- **Test coverage gaps** — every UI screen and the main `SquishyGame` class have zero tests. Not blocking, but worth a pass before submission.

---

## 📊 Realistic prioritized punch list to submit

1. **Privacy manifest** — ~30 min (copy Apple's template, declare `share_plus`)
2. **Custom launch screen** — ~1 hr (branded splash matching game palette)
3. **5+ screenshots** — ~2–3 hrs (Codemagic screenshot step on iPhone 15 Pro Max simulator, or browser-rendered at correct resolutions)
4. **App Store listing copy** — ~1 hr (derive from the saved plain-English pitch)
5. **Age rating + support URL + privacy policy URL** — ~1 hr
6. **Polish: 41 ElevenLabs squish files** — ~2–4 hrs (batch generation + QA)
7. **Polish: decal PNGs** — ~1–2 hrs (image gen)

**Bare-minimum-to-submit:** ~6 hours of focused work (mostly screenshots + privacy manifest)
**Polished-feeling launch:** ~12–15 hours (adds missing audio + decals)

> Decal/UI placeholders and Android signing are *not* iOS App Store blockers — ship those in a v0.3 post-launch.

---

## 🎯 Quick wins available right now (no external assets needed)

- Draft the `PrivacyInfo.xcprivacy` file
- Draft the App Store listing copy from the in-memory pitch
- Fix the share_capture test timeout
- Wire Sentry as the analytics sink so the next TestFlight build self-reports failures
