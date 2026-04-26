# Squishy Smash — Pre-Launch Audit Synthesis

*Synthesis of 19 specialist subagents run in parallel before v0.1.1 App Store submission. Last run: 2026-04-25.*

## Verdict

**Not ready to submit.** The build in `main` will either be rejected on a privacy form mismatch or ship a binary that materially contradicts the published privacy policy. The fixes are real work — not five minutes — but every P0 below has a concrete file:line and a defined fix path, and the codebase itself is otherwise in unusually good shape (clean architecture, zero `TODO/FIXME` markers, healthy dependency tree, ~576 tests passing, well-disciplined service surface).

**Three independent agents (Security, Backend, Coordinator)** converged on the same root cause: the `FeatureFlags.iapsEnabled = false` gate only hides UI. The underlying AdMob, ATT, and IAP services still construct, initialize, and make network calls at every cold start. That's the heart of P0.

**Strengths to preserve** — don't lose these in the fix pass:
- Architecture is healthy and consistent (StatefulWidget + setState everywhere, single ServiceLocator, single persistence boundary, JSON-driven pack list, IAP cleanly stubable)
- All 14 dependencies are current with no CVEs and confirmed iOS 26 compatibility
- Persistence migrations v0→v4 are individually well-tested (576 unit tests, healthy distribution tests on rarity)
- No hardcoded secrets in repo, no unauthorized network calls beyond Sentry/AdMob/IAP
- Service surface is well-typed (PurchaseResult, BurstOutcome, SessionStartResult)

---

## P0 — Submission Blockers (must fix before clicking Submit)

### Privacy / App Review rejection-causing

**P0.1 AdMob still bundled, initialized, and pre-loading at every launch** — flagged by Security + Backend independently
- `pubspec.yaml:21-22` ships `google_mobile_ads ^5.2.0` + `app_tracking_transparency ^2.0.6`
- `lib/core/service_locator.dart:110-120` instantiates `AdMobRewardedAdService()` and calls `consent.ensureConsentAndInit()` at every mobile bootstrap
- `lib/monetization/admob_rewarded_ad_service.dart:25` fires a `_preload()` in the constructor → outbound HTTPS to `googleads.g.doubleclick.net` on every cold start
- `ios/Runner/Info.plist:50-83` ships `GADApplicationIdentifier`, `NSUserTrackingUsageDescription`, and 20 `SKAdNetworkItems`
- `android/app/src/main/AndroidManifest.xml:35-37` mirrors the AdMob meta-data
- Privacy policy at `website/public/privacy.html:56,98-103` claims "no in-game ads, no third-party SDKs, ATT prompt does not appear"
- **Fix:** add `FeatureFlags.adsEnabled = false` flag mirroring `iapsEnabled`. In `service_locator.dart`, gate the entire `AdMobRewardedAdService`/`ConsentController.ensureConsentAndInit()` path behind it; fall back to `StubRewardedAdService()`. Remove `google_mobile_ads` + `app_tracking_transparency` from `pubspec.yaml` for v0.1.1 (or scope behind a build flavor). Strip `GADApplicationIdentifier`, `NSUserTrackingUsageDescription`, and the entire `SKAdNetworkItems` array from `Info.plist` and AdMob meta-data from `AndroidManifest.xml`.

**P0.2 IAP service initializes at boot regardless of feature flag** — Backend + Architect
- `lib/core/service_locator.dart:97` selects `RealIapService()` whenever `Platform.isIOS || Platform.isAndroid`
- `service_locator.dart:102` immediately calls `iap.loadProducts(ProductIds.launchLoaded)` → StoreKit `SKProductsRequest` → network call to Apple
- The `FeatureFlags.iapsEnabled` gate only hides UI surfaces, not service init
- **Fix:** in `service_locator.dart` replace the platform check with `if (FeatureFlags.iapsEnabled && (Platform.isIOS || Platform.isAndroid))` so the service stays a stub when the flag is off, and skip `loadProducts` entirely.

**P0.3 Sentry default behaviors send beyond "Crash Data"** — Security + Backend
- `lib/main.dart:64-72` sets only `dsn` + `tracesSampleRate = 0.0`
- Default Sentry behavior sends `session_start`/`session_end` envelopes and "App Hang" / "App Start" events — none of which are "Crash Data" per Apple's nutrition-label terminology
- **Fix:** add to `SentryFlutter.init` options: `enableAutoSessionTracking = false`, `enableAppHangTracking = false`, `enableUserInteractionBreadcrumbs = false`, `attachScreenshot = false`, `sendDefaultPii = false`.

### Build pipeline

**P0.4 `pubspec.yaml:4` says `version: 0.1.0+1`** — DevOps + Documentation + Coordinator
- App Store Connect will accept the IPA as v0.1.0, not v0.1.1
- **Fix:** bump to `version: 0.1.1+1` before tagging.

**P0.5 No `v0.1.1` git tag exists** — Coordinator
- Codemagic `ios-release` only fires on `v*` tag push; latest tag is `v0.8.0` (a stale dev tag)
- **Fix:** after P0.4, tag `v0.1.1` and push.

**P0.6 `codemagic.yaml:105` references nonexistent `/Users/builder/export_options.plist`** — DevOps
- Fresh Codemagic runner build will fail with "export options plist not found"
- **Fix:** either remove the `--export-options-plist` flag (Flutter generates one from the applied profile) or write the plist explicitly in a script step before the build.

**P0.7 No dSYM upload to Sentry** — DevOps
- Release config produces dSYMs but no script invokes `sentry-cli upload-dif`
- Every release crash will arrive as un-symbolicated hex addresses; Sentry becomes cosmetic
- **Fix:** add post-build step in `codemagic.yaml`:
  ```
  sentry-cli debug-files upload \
    --org $SENTRY_ORG --project $SENTRY_PROJECT \
    --auth-token $SENTRY_AUTH_TOKEN \
    build/ios/archive/Runner.xcarchive/dSYMs
  ```
  Add `SENTRY_ORG`, `SENTRY_PROJECT`, `SENTRY_AUTH_TOKEN` to the `smash` Codemagic variable group.

### First impressions / data integrity

**P0.8 Default Flutter launch image (white-on-white)** — Frontend Architecture + UI Design
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` is the 68-byte stock placeholder
- `ios/Runner/Base.lproj/LaunchScreen.storyboard:22` declares `backgroundColor red=1 green=1 blue=1` (pure white)
- App scaffold is `#120B17`; players (and Apple reviewer) see a white flash → dark scaffold every cold start
- **Fix:** author a 1242×2688 brand splash on `#120B17` with the SQUISHY SMASH wordmark in Fredoka, replace the three LaunchImage PNGs, and change storyboard background to the bgDeep equivalent (`red=0.071 green=0.043 blue=0.090`).

**P0.9 Collection screen OOM risk on iPhone** — Performance
- `lib/ui/collection_screen.dart:318` calls `Image.asset(card.assetPath, fit: BoxFit.cover)` for all 48 full-resolution PNGs without `cacheWidth`/`cacheHeight`
- 200-400 MB of decoded RGBA in memory at once
- **Fix:** pass `cacheWidth: 256` for the grid, OR switch to the existing `assets/images/thumbnails/*_thumb.png` set (~50 KB each).

**P0.10 Corrupted v4 blob silently resets v3+ player progress** — Database
- `lib/data/persistence.dart:117-123, 308-350` falls back to `_loadLegacyProfile()` on any malformed blob
- For players who installed at v3 (v0.1.0+), there are no legacy keys on disk — fallback returns empty profile (coins=0, no purchasedSkus, no milestone-claimed)
- Paying customer who hits a corrupted blob loses their `remove_ads`/Starter Bundle entitlement until they tap Restore Purchases (most won't know to)
- **Fix:** detect "blob corrupted but raw bytes exist" and refuse silent overwrite. Surface a diagnostic event via `DiagnosticsService` so Sentry sees corruption rates. Add a `profile.blob_v3.bak` rotated-snapshot key one save behind the live blob.

### Listing / paste-risk

**P0.11 `docs/launch_punch_list.md` and `docs/app_store_listing.md` are stale and contradict shipped state** — Documentation + Coordinator
- Risk of pasting wrong description / release notes into App Store Connect
- **Fix:** delete both files, OR prepend "SUPERSEDED — see `docs/app_store_submission_copy.md`" banner to each.

**P0.12 App Store Connect URL placeholders** — Coordinator + Documentation
- `docs/app_store_submission_copy.md:165-174` still has `[YOUR-NETLIFY-DOMAIN]` placeholders
- **Fix:** at submit time in App Store Connect, paste the real `squishysmash.com` URLs into Privacy Policy URL, Support URL, and Marketing URL fields. (Don't need to edit the markdown file — just don't paste it raw.)

---

## P1 — Should fix before submission (real bugs, first-impression polish)

### Game-feel and UX (high-impact, low-cost)

**P1.1 Mute setting not applied at startup** — Code Review
- `lib/game/systems/sound_manager.dart:10` hardcodes `SoundManager.muted = false`; persisted value only applies after Settings interaction
- Player who muted the app and relaunches hears full volume
- **Fix:** in `ServiceLocator.bootstrap()`, after `sounds = SoundManager()`, set `sounds.muted = persistence.muted`.

**P1.2 Force-quit mid-round drops the round entirely** — Game Dev + Code Review + Database
- No `WidgetsBindingObserver` / `didChangeAppLifecycleState` listener anywhere in `lib/game/` or `lib/ui/gameplay_screen.dart`
- A kid Cmd-swipes mid-round → `bestScore`/`bestCombo` and any debounced (≤400 ms) saves vanish
- **Fix:** in `gameplay_screen.dart`, observe lifecycle; on `paused`/`detached` call `_endRound()` (or `_finalizeIfActive`) and `progression.flushPending()`.

**P1.3 Reveal stinger is dead code** — Game Dev
- `lib/game/systems/ui_sound_registry.dart:42` has `revealStinger`, asset exists at `assets/audio/ui/ui_reveal_stinger_01.mp3`, but zero callers
- First mythic feels like a louder common
- **Fix:** in `FeedbackDispatcher._fireRevealBurst` (`feedback_dispatcher.dart:101`), layer `UiSoundRegistry.revealStinger` for `rarity.index >= Rarity.epic.index` before the VO line, ducked under by 3-4 dB.

**P1.4 Mythic SHARE snackbar too short and not child-dismissible** — UX
- `lib/ui/gameplay_screen.dart:81-107` — 6 s SnackBar, no visible dismiss, gameplay continues underneath
- 5-year-old can't read "Mythic! Save this clip?" in 6 s
- **Fix:** extend to 10 s with a visible close X, OR replace with a kid-readable modal ("You found a SUPER RARE! Show grown-up?") with big yes/no.

**P1.5 Gameplay close X has no confirmation** — UX
- `gameplay_screen.dart:148-151` — kid taps corner X, run is gone with no warning
- **Fix:** wrap with confirm dialog ("Quit and lose your score?") or animate a run-end summary first.

**P1.6 Tap targets undersized on gameplay HUD** — UX + Accessibility
- Default `IconButton` is 48 dp tappable but icons are tiny in `Colors.white70` against busy backgrounds
- **Fix:** bump `iconSize: 32`, add `padding: EdgeInsets.all(12)`, gap of 16 px between Share and Close icons.

**P1.7 Boost token auto-spends silently on round start** — Game Dev
- `squishy_game.dart:223` arms `_useBoostOnNextSpawn = true` if `boostTokens > 0` with no UI
- Player has no affordance to save a token; it gets vaporized inside the first spawn
- **Fix:** gate behind a "Use Boost (1 left)" pre-round toggle, or only auto-arm on a `pendingBoostUse` flag set by an explicit menu tap.

**P1.8 Duplicate commons reward 0 coins AND no toast** — Game Dev
- Anti-spam silently throttles same-id repeats; combined with `economy.json:23` `common: 0` duplicate bonus, kid taps Soft Dumpling 4× and sees no coins, no toast
- Feels broken
- **Fix:** even on suppressed/0-coin commons, briefly pulse a "+1 burst" counter, or set duplicate-common floor to 1 coin.

**P1.9 Mythic odds drift to ~1/50 from compounding boosts** — Game Dev
- Default `RarityOdds.legendary = 0.02` × `softBoost` × `comboBoost` × `tokenBoost` can push effective rate ~3.9× at combo 8
- No test pins "across N=10000 rolls, mythic rate ≤ 1/150"
- **Fix:** add `test/rarity_distribution_simulation_test.dart` running 10k picks at neutral combo; consider `legendary: 0.008` or capping mythic combo boost.

### Accessibility

**P1.10 No reduce-motion handling anywhere** — Accessibility
- Zero hits for `MediaQuery.disableAnimations` in `lib/`
- Mascot, reward toast, mythic burst FX, particle bloom, screen shake all ignore the system flag
- **Fix:** read `MediaQuery.of(context).disableAnimations` at app root and pipe through an `InheritedWidget` to mascot, toast, and `ParticleManager`.

**P1.11 No Dynamic Type / text-scale support** — Accessibility
- All `TextStyle` use fixed `fontSize:` (e.g., menu title 44, HUD score 44, BigButton 22)
- Apple HIG expects Dynamic Type unless the app has a written exemption
- **Fix:** use `Theme.of(context).textTheme.X` instead of hardcoded sizes; let MediaQuery flow.

**P1.12 HUD score has no semantic label** — Accessibility + UX
- VoiceOver reads bare number with no context
- **Fix:** wrap with `Semantics(label: 'Score: ${data.score}', liveRegion: true)`.

**P1.13 CoinBadge contrast fail** — Accessibility
- `lib/ui/widgets/coin_badge.dart` — cream text on cream-tinted pill drops below 3:1 contrast
- Also reads "16" not "16 coins" to VoiceOver
- **Fix:** switch text to white or darken to `0xFFB07A00`; wrap with `Semantics(label: '$coins coins')`.

### Performance

**P1.14 SentryFlutter.init blocks first frame** — Performance
- `lib/main.dart:66` awaits `SentryFlutter.init` synchronously
- **Fix:** use `SentryFlutter.init(... appRunner: () => runApp(...))` so the SDK doesn't gate the first frame.

**P1.15 Sounds.warm() blocks bootstrap** — Performance
- `lib/core/service_locator.dart:85` awaits all 200+ MP3 loads
- 1-2 s startup hit
- **Fix:** `unawaited(sounds.warm(...))` — play path already tolerates cache miss.

**P1.16 Object PNGs at 1024×1024, render at 144 px** — Performance
- 48 files × ~300 KB = ~15 MB; downsampling to 512×512 cuts to ~4 MB and halves texture memory
- **Fix:** re-export `assets/images/objects/*.png` at 512×512.

### Missing/inconsistent UI

**P1.17 No About screen exists despite being referenced** — UX + UI Design
- `lib/core/routes.dart` has menu/play/results/shop/settings/collection — no `about` route
- App Store metadata typically links to it
- **Fix:** add `AboutScreen` (credits, version, support email `chriscam8@gmail.com`, X handle `@squishy_smash`, privacy link), register `/about` route.

**P1.18 Brand palette duplicated as raw hex 30+ times** — Frontend Architecture + UI Design
- `Palette` exists at `lib/core/constants.dart:22-51` but `Grep "Palette\."` returns zero hits in `lib/ui/`
- Drift already happening (`#FFD15C` vs `#FFD36E`, `#1A0F23` vs `#1A1320`)
- **Fix:** replace `Color(0xFFFF8FB8)` → `Palette.pink`, etc., across `lib/ui/`.

**P1.19 Settings → Diagnostics route bypass** — Frontend Architecture
- `lib/ui/settings_screen.dart:73-79` uses `Navigator.push(MaterialPageRoute(...))` with hardcoded import
- Every other navigation uses named routes
- **Fix:** add `diagnostics: '/diagnostics'` to `AppRoutes`, use `Navigator.pushNamed`.

**P1.20 Mythic snackbar is visually disconnected from RewardToast family** — UI Design
- `gameplay_screen.dart:78-108` flat plum SnackBar; `widgets/reward_toast.dart:90-103` translucent black + tinted glow + 999-radius pill
- Three "celebration" surfaces should share one visual atom
- **Fix:** extract a `CelebrationToast` widget consumed by mythic, reward, and duplicate-burst.

### Test gaps

**P1.21 No widget smoke tests for 3 main screens** — Testing
- `GameplayScreen`, `ShopScreen`, `ResultsScreen` not built/pumped anywhere
- Apple reviewer hits this path first
- **Fix:** one `pumpWidget` test per screen with mocked `ServiceLocator`.

**P1.22 No integration test of `_handleBurst` orchestration** — Testing
- The burst→reveal→coin grant→discovery→pack-progress pipeline has no test of the wiring
- Regression that breaks the call into `progression.markDiscovered` would pass all current tests
- **Fix:** add a Flame integration test simulating one burst end-to-end.

### Logging hygiene

**P1.23 `debugPrint` for asset-load failures** — Debug
- Multiple sites: `content_loader.dart:59,69`, `card_manifest_loader.dart:45,59`, `economy_config_loader.dart:32`, `consent_controller.dart`, `iap_service_real.dart`
- Errors invisible to Sentry; battery + log noise in production
- **Fix:** replace with `ServiceLocator.diagnostics.record(source: '...', error: e, stack: st)`.

---

## P2 — Post-launch backlog (defer)

- ChangeNotifier wrapper over `PlayerProfile` (architect — required for v0.2 IAP async UI updates)
- Pack ID list de-duplicated (`pubspec.yaml:50-53` ↔ `content_loader.dart:33-38`)
- Hardcoded magic numbers → `Tunables.X` (combo decay, round duration, particle counts)
- Sealed `RewardEvent` hierarchy when 3rd variant lands
- `collection_screen.dart` (720 LOC) and `squishy_game.dart` (599 LOC) split
- `cardRarityColor` shim removal (4 callers)
- Spacing / radius design tokens (50 hardcoded `EdgeInsets`/`SizedBox` values)
- Brand-shaped icons (coin, lock, share, fire, sparkle, check) replacing stock Material
- Audio `mp3` → `aac` (~30% size win)
- README rewrite + `CHANGELOG.md` (Documentation)
- AppLifecycleState observer for ATT/UMP errors → Sentry (Code Review)
- Consumable `awardCoins` dedupe via session-scoped event-id ring buffer (Database)
- AdMob/IAP/ATT re-introduction strategy for v0.2 (with privacy nutrition label update)
- `analysis_options.yaml` exclude `build/**` (Refactoring — small but easy)

---

## Two-pass execution plan

**Pass 1 (P0 — pre-submit, 1-2 days):**

1. Add `FeatureFlags.adsEnabled = false` constant
2. Gate AdMob construction + IAP `loadProducts` behind both flags in `service_locator.dart`
3. Strip AdMob/ATT keys from `Info.plist` and `AndroidManifest.xml`
4. Remove `google_mobile_ads` + `app_tracking_transparency` from `pubspec.yaml` (or scope to flavor)
5. Tighten Sentry init options (autoSessionTracking off, etc.)
6. Bump `pubspec.yaml` to `0.1.1+1`
7. Brand-match `LaunchImage.imageset/` and `LaunchScreen.storyboard` background
8. Fix `collection_screen.dart:318` with `cacheWidth: 256`
9. Add corruption-detect-and-snapshot path in `persistence.dart`
10. Fix `codemagic.yaml` export-options-plist reference + add dSYM upload step
11. Confirm `SENTRY_DSN` populated in Codemagic `smash` group; add `SENTRY_ORG`/`PROJECT`/`AUTH_TOKEN`
12. Delete or supersede-banner `docs/launch_punch_list.md` and `docs/app_store_listing.md`
13. Run `flutter test` — all green
14. Tag `v0.1.1`, push, wait for Codemagic build
15. Install on device, run smoke test (menu → 1 round → mythic reveal → share → collection → settings)
16. Submit to App Store Connect with the real `squishysmash.com` URLs pasted in

**Pass 2 (P1 — quality polish, 2-3 days, parallel-able):**

The 23 P1 items split cleanly along three tracks:
- **Game-feel** (P1.1, P1.2, P1.3, P1.4, P1.5, P1.6, P1.7, P1.8, P1.9) — game-dev work
- **Accessibility** (P1.10, P1.11, P1.12, P1.13) — focused a11y pass
- **Polish + perf + tests** (P1.14–P1.23) — incremental

Pass 2 doesn't have to block submission; it can ship as a v0.1.2 patch within 1-2 weeks of v0.1.1's launch.

---

## Appendix — agent IDs and source

19 specialist agents ran in parallel against the codebase at HEAD. Source transcripts are in this conversation.

| Specialty | Findings (CRITICAL/MAJOR/MINOR) | Verdict |
|---|---|---|
| Code Review | 0/5/4 | Healthy |
| Security | 2/2/4 | NOT ready (privacy mismatch) |
| Performance | 2/6/5 | NOT ready (OOM risk) |
| Testing/QA | 0/4/3 | Healthy with gaps |
| Game Dev | 2/5/5 | Healthy (game feel polish) |
| UX | 3/6/6 | Major (UX polish needed) |
| DevOps | 3/3/4 | NOT ready (build pipeline) |
| Accessibility | 3/5/4 | Major (a11y polish) |
| Debug | 0/2/4 | Healthy |
| Architect | 0/3/5 | Healthy → v0.2 |
| Refactoring | 0/0/4 | Very clean |
| Frontend Architecture | 0/4/6 | Major (launch flash) |
| UI Design | 2/5/7 | Major (launch + palette) |
| Documentation | 4/5/3 | Stale docs risk |
| Database | 1/4/4 | NOT ready (data loss vector) |
| API Design | 0/5/4 | Healthy → v0.2 |
| Backend (network) | 3/2/0 | Confirms P0.1-P0.3 |
| Research (deps) | 0/0/4 | Healthy |
| Project Coordinator | 0/0/0 | Verdict: NOT ready, P0 list |

**Consensus across multiple agents** (≥2 agents flagged the same issue):
- Privacy mismatch (Security + Backend)
- Pubspec version (DevOps + Documentation + Coordinator)
- Launch image (Frontend Architecture + UI Design)
- About screen missing (UX + UI Design)
- Reduce-motion / Dynamic Type (Accessibility — single agent but high-confidence)
- AppLifecycle observer missing (Code Review + Game Dev + Database)
- Stale launch docs (Documentation + Coordinator)
