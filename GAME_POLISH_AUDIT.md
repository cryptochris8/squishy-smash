# Squishy Smash — Game Polish Audit

*Synthesis of 5 parallel specialist subagents (game-feel, UX, UI, performance, competitive research) run against v0.1.2 on 2026-05-16, after book shipped on KDP and before the Reddit launch (~2026-05-29).*

*Sister doc: `PRELAUNCH_AUDIT.md` (2026-04-25) covers the original pre-App-Store rejection sweep — all its P0 + most P1 items shipped. This doc is the v0.1.3 polish pass.*

---

## Verdict

The game is in good shape. The April audit's structural issues are closed. What's left is **player-felt polish**: the moments players see most often (results screen, first-run, mythic reveals) are still weaker than the rest of the experience. The single biggest opportunity is the **results screen** — three independent agents (game-feel, UX, UI) converged on it as the weakest moment in the entire game.

The competitive landscape (Antistress, Pop It 3D, Fidget Toys ASMR, Taba Paw, Jelly Shift, Mystery Dumpling TikTok phenomenon) confirms the *moat* is the 48-card collection meta-game — no direct competitor combines a signature tactile mechanic with a named-rarity collectible system and ASMR-grade audio + haptics. But the moat is also invisible to new players in the first 5 minutes, which is a discovery problem more than a polish problem.

---

## Cross-Agent Convergence (highest conviction)

These are findings 2+ agents independently flagged. Highest confidence; ship these first.

### CV-1. Results screen is the single weakest moment in the game
- **Game-feel (P1-D):** "static text list, no animation, no NEW BEST celebration" — `lib/ui/results_screen.dart:28-56`
- **UX (#4):** "the emotional peak of the round ends with a cold spreadsheet and two undifferentiated big buttons" — no bridge to Collection or Shop
- **UI (#1):** "no visual container or accent... score is plain white, Best Score and Score render at nearly the same visual weight (22 vs 18)"

### CV-2. Collection discovery loop is invisible to new players
- **UX (#1, #5):** No onboarding, no "How it works" overlay, no path from results → collection. Empty collection screen has no PLAY shortcut.
- **Research (recommendation #2):** Daily Mystery Pack with streak counter — converts the 48-card meta into a daily-return reason. The category leader (Antistress, 88K reviews) wins on volume but loses on retention loop; Squishy Smash's *moat is the collection*, and players don't see it.

### CV-3. Launch flash still unfixed in player-felt sense
- **UX (#3):** White flash before dark scaffold. P0.8 shipped technically but no brand splash was authored. "Reads as 'app crashed and restarted' to a Reddit player who just installed."

---

## P1 — Ship in v0.1.3 (pre-Reddit-launch window, target TestFlight by 2026-05-22)

### Game-Feel
- **P1-A. ASMR idle VO is fully dead code.** `voice_line_registry.dart:41-47` warms 5 idle VO clips at boot; `dispatcherMap` doesn't include them and no call site plays them. Add `_idleTimer` in `SquishyGame.update(dt)` — reset on impact/burst, fire after ~3 s silence, gate to once per 8 s. **Effort: S.**
- **P1-B. Screen shake has no falloff curve.** `screen_shake.dart:26-38` — flat amplitude for the whole window, then snaps back. Replace with `envelope = _remaining / _durationStart`; multiply offset. Mythic at `intensity=14` becomes a detonation, not a phone vibrator. **Effort: S.**
- **P1-C. Mythic/rare/common haptics all fire identical `HapticFeedback.heavyImpact()`.** `feedback_dispatcher.dart:113-129`. Add `doublePulse()` / `triplePulse()` to `HapticsManager` (80 ms gap, `Future.delayed` is fine here). Tier them: common = single, rare/epic = double, mythic = triple. **Effort: S.**
- **P1-D. Results screen redesign.** See CV-1. Animate score count-up (1.5 s Tween), add "NEW BEST!" badge on personal-best, drop in `FloatingMascot`, add colored accent headline. **Effort: M.**
- **P1-E. No anticipation beat before first spawn.** `squishy_game.dart:258` — `spawner.requestSpawn(0)` fires immediately. New installers see a static squishy. Bump first-spawn delay 0 → 0.5 s; add `ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.22, curve: Curves.elasticOut))` from `scale=0`. **Effort: S.**
- **P1-F. Combo decay reset is silent.** `combo_controller.dart:51-56` — `_streak` silently resets when `_decayLeft` hits 0. Players don't learn that timing matters. Expose `bool comboLost`; fire selection haptic + brief red flash on multiplier text. **Effort: S.**

### UX
- **UX-1. First-run "How it works" overlay.** Single dismissible frame on first launch, persisted flag. Two lines + OK CTA. Highest churn driver for Reddit-acquired users. **Effort: S–M.**
- **UX-2. Results-screen "See your new card" / "See Shop" ghost buttons.** When `coinsEarned > 0` or a card was discovered this round, surface the bridge. PLAY AGAIN stays primary pink CTA. **Effort: S.** (Pairs with P1-D.)
- **UX-3. First-card-unlock celebration.** Currently identical to "+1 coin DUPLICATE" toast. Reuse the mythic-reveal animation pattern (full-bleed, named, rarity-colored, brief pause). Gate on profile-first-card flag. **Effort: M.**
- **UX-4. Empty Collection state with PLAY shortcut.** `collection_screen.dart:92-93` — when `unlockedTotal == 0`, sticky banner "Tap PLAY to start smashing and unlock cards." **Effort: S.**
- **UX-5. Brand-matched launch image.** Author `1242×2688` `#120B17` splash with Fredoka wordmark. Replace `LaunchImage.imageset/` PNGs. Update storyboard background. **Effort: M.**

### UI / Visual
- **UI-1. Card-number contrast fix (WCAG AA failure).** `collection_screen.dart:356` — 9 sp at `alpha: 0.5` on near-black ≈ 4.2:1 (need 4.5:1). Bump to opaque, promote to 11 sp. **Effort: XS.**
- **UI-2. About-screen AppBar consistency.** `about_screen.dart:29` — only screen with `bgSurface` AppBar; every other uses transparent. **Effort: XS.**
- **UI-3. Shop price loading placeholder.** Async `_loadPrices` leaves cost pills blank. Add `"..."` or shimmer. **Effort: S.**
- **UI-4. About-screen version constant lag.** `about_screen.dart:20` hardcodes `'0.1.1'`; live build is `0.1.2`. Wire `PackageInfo.fromPlatform()` or `--dart-define`. **Effort: XS.**

### Performance
- **PERF-1. Skybox PNGs → WebP.** `assets/images/arenas/` is 14.9 MB / 18 PNGs. Lossy q90 saves ~7–8 MB IPA. `cwebp -q 90 *.png` + pubspec path update. **Effort: S.**
- **PERF-2. Object + thumbnail PNGs → WebP.** Same pattern, saves another ~4–5 MB IPA. **Effort: S.**
- **PERF-3. Cache `Paint`/`Shader` in `SkyboxComponent` + `RevealBloom`.** Both allocate `Paint()` per frame; SkyboxComponent also re-creates gradient shaders every frame. Promote to fields, mutate color. Eliminates ~3–5 small allocs/frame. **Effort: S.**
- **PERF-4. Move screen-recording MP4s out of `assets/images/`.** Two MP4s (~153 MB combined) currently sit under assets — not bundled because `assets/images/` isn't in pubspec as a glob, but a future pubspec edit could ship them. `git mv` to `scratch/` or `docs/`. **Effort: XS.**

---

## P2 — Next cycle (v0.2.0, ~3 weeks post-launch)

### Big-feature additions from competitive research
- **R-1. Share Your Pull (mythic clip auto-export).** Trigger 3-second auto-captured screen recording + screenshot composite after mythic/gold reveal; pre-load share sheet. Directly mirrors Mystery Dumpling unboxing format (500M TikTok views). **Effort: M–L.** (Highest expected social ROI of the v0.2.0 features.)
- **R-2. Daily Mystery Pack + streak counter.** One free pack-attempt per day with visible streak + day-7/day-14 escalating bonuses. Monopoly GO's signature retention lever. **Effort: M–L.**
- **R-3. Today's Squishy (rotating featured creature).** Daily/weekly featured creature with extra particle FX, unique smash sound, 2x card-fragment drop. Gives Reddit launch posts a specific timely hook ("today's featured is the Eyeball, crunch is wild"). **Effort: M.**
- **R-4. Pawprint-hunt cross-media unlock.** Already planned (`memory/pawprint_hunt_cross_media.md`). Book ships 2026-05-16 means book buyers now hold the trigger. Code-entry UI + reward all 3 mythics. Direct book→game funnel. **Effort: M.**

### Game-feel P2
- **P2-A. Spawn position jitter.** `squishy_game.dart:341` — always `(size.x * 0.5, size.y * 0.55)`. Jitter X by ±20%, Y by ±8%. **Effort: S.**
- **P2-B. Decal opacity fade curve.** `decal_manager.dart:29-32` — linear fade looks like "cleaned." `Curves.easeIn` keeps splats present longer. **Effort: S.**
- **P2-C. Per-rarity particle burst tiers.** `particle_manager.dart:13` — common→mythic step-up is visually imperceptible. Spawn second burst call with larger spread + tier color for rare+. **Effort: M.**
- **P2-D. Menu screen ambient audio.** Currently dead silent until PLAY. **Effort: M.**

### UI / Design-system P2
- **DS-1. Consolidate near-blacks.** `#120B17`, `#1A1320`, `#1E0E2A`, `#1A0F23` all within 10 lightness points. Pick two max (bg + surface + maybe modal), name them. **Effort: M.**
- **DS-2. `AppTheme.radii` + `AppSpacing` constants.** 9 distinct radius values + 122 hardcoded spacing values across 13 files. Collapse to 4 radii (pill=999, card=16, button=12, inner=8) and 5 spacing tokens (xs=8, sm=12, md=16, lg=24, xl=32). **Effort: M.**
- **DS-3. Brand glyphs replacing stock Material icons.** Coin, lock, share, fire, sparkle, check. `Icons.check_circle` appears 5x across the UI. **Effort: M–L.**
- **DS-4. `SwitchListTile` brand theming.** Add `activeColor: Palette.toxicLime` + `trackOutlineColor` at theme level. **Effort: XS.**

### UX P2
- **UX-6. Burst-progress copy.** `collection_screen.dart:501-516` — "3/5 bursts" → "Smash it 3 more times in a round." Burst is internal jargon. **Effort: XS.**
- **UX-7. Collection filter cognitive load.** Add live "Showing X of 48" count + single "Clear filters" pill when any filter active. **Effort: S.**
- **UX-8. Arena unlock flow.** `shop_screen.dart:334` — "switch in Settings" breaks reward moment. Auto-activate with undo snackbar. **Effort: S.**
- **UX-9. About-screen link affordance.** Add `Icons.copy` + "Copied to clipboard" snackbar so tap target is discoverable. **Effort: S.**
- **UX-10. HUD round-progress label.** First-time players don't know what the fill bar is or that it ends the round. Add one-time label or final-3s countdown. **Effort: S.**

### Performance P2
- **PERF-5. MP3 → AAC audio re-encode.** 265 MP3s = 3.5 MB → ~2.4 MB IPA. flame_audio supports AAC natively. **Effort: M (batch ffmpeg + pubspec path update).**
- **PERF-6. Pre-warm object sprites in `SquishyGame.onLoad()`.** Eliminates first-spawn hitches (5–20 ms each) on first encounter with new creature. **Effort: S.**
- **PERF-7. `Image.asset` `cacheWidth` in `floating_mascot.dart:139`.** Minor RGBA overalloc. **Effort: XS.**
- **PERF-8. `CollectionScreen.build()` recomputes unlock status every rebuild.** Cache in state. **Effort: S.**
- **PERF-9. Per-frame `Paint()` alloc in `_DecalSplat.render()` and `RevealBloom.render()`.** Promote to fields. **Effort: S.**

---

## P3 — Nice-to-have / backlog

- **P3-A. RevealBloom tinted by rarity.** Always white flash; tint epic→lavender, mythic→gold for color-coded payoff. `reveal_bloom.dart:48`. **Effort: S.**
- **P3-B. Share button uses generic captions.** `gameplay_screen.dart:251` — manual share always passes `Rarity.common`. Pass actual rarity through. **Effort: S.**
- **P3-C. Skybox `debugPrint` in release builds.** `skybox_component.dart:62-67` — wrap in `kDebugMode` or route through `DiagnosticsService`. **Effort: XS.**
- **P3-D. Settings `SwitchListTile` font-weight w500.** Only w500 in entire codebase (rest is w600+). Promote to w600. **Effort: XS.**

---

## Competitive Landscape (May 2026 snapshot)

### Direct competitors

| App | Mechanic | Traction | Their edge | Our edge |
|---|---|---|---|---|
| **Antistress – Relaxing Games** (Moreno Maio) | 50+ tactile toys, freemium | 4.8★ / 88K reviews; weekly updates | Breadth; $4.99 ad-removal | Collection meta-game; thematic universe |
| **Pop It 3D – ASMR** (Weave App's) | 100+ rotating pop-it levels | 4.9★ / 7 reviews; stalled | 3D rotation more dynamic | Polished rarity; distinct creatures |
| **Fidget Toys ASMR Games** (Sajjad) | Slice/cut/shred slime | Couldn't verify | Aggressive destruction | Rarity collectibles; production polish |
| **Satisfying ASMR Fidget Game** (Sajjad) | 30+ mini-games variety pack | 5.0★ / 1 review; nascent | Variety | Everything (production quality) |
| **Taba Paw Squish Antistress** (DMLSGames) | Squeeze + sell-for-coins | 4.48★ / 52 votes; web/Android | Coin economy + customization slider | Card-based rarity hook |
| **Jelly Shift** (SayGames) | Morph jelly through openings | Mid-size publisher | Beautiful physics + skill | Collection; ASMR identity; reveal moment |

**Category insight:** No competitor combines (a) signature tactile mechanic + (b) named-rarity collectible cards + (c) ASMR-grade audio/haptics. The collection layer is Squishy Smash's genuine moat.

### Hot category patterns (May 2026)

1. **Rarity-reveal as shareable content.** RMS USA's physical Mystery Squishy Dumpling → 500M TikTok views by 2025; Golden Ticket Edition launched 2026-05-07. ([source](https://www.businesswire.com/news/home/20260507733888/), [source](https://theretaildata.com/viral-hit-to-retail-powerhouse-rms-usas-mystery-dumpling-keeps-selling-out/))
2. **Gacha-adjacent rare-pull celebration clips.** TikTok gaming 2026 — rare pulls outperform other mobile formats. ([Viryze](https://viryze.com/blog/tiktok-gaming-trends-2026))
3. **LiveOps seasonal events as primary retention.** Monopoly GO runs simultaneous seasons + main events + flash events + daily Quick Wins. 60%+ of top-grossing casual revenue 2025–2026 is LiveOps. ([PC Games N](https://www.pcgamesn.com/monopoly-go/events), [StudioKrew](https://studiokrew.com/blog/mobile-game-monetization-models-2026/))
4. **Daily streak loops are table stakes.**
5. **Short-form video discovery — 15s clips, open on the payoff.** Don't build up; open on the pop. ([Viryze](https://viryze.com/blog/tiktok-gaming-trends-2026))

### Reddit + TikTok content targets

| Subreddit | Subs | Notes |
|---|---|---|
| r/oddlysatisfying | 8.6M | **No product/YouTube links allowed.** Only viable if a clip goes organically viral without branding. |
| r/ASMR | — | Audio-forward content allowed. Frame goo-pop as "satisfying sound design." |
| r/iosgaming | — | Developer flair required; gameplay footage mandatory. **Primary launch target for 2026-05-29.** |
| r/indiegaming | 478K | "Here's what I built" narrative posts work. |
| r/MobileGaming | — | Lower bar than r/iosgaming. Secondary target. |
| r/playmygame | — | Open to any launch stage; relaxed rules. Good warm-up. |

**TikTok hooks:** Open on the pop (no build-up). 6–15 seconds. Stack: `#oddlysatisfying #ASMRgame #satisfying #mobilegame`.

**Reddit account state:** Fresh account active 2026-04-29; non-promo karma-build through ~2026-05-29 per `memory/reddit_account_state.md`. May 29 is appropriately past 30-day credibility threshold.

---

## Two-pass execution plan

**Pass 1 — v0.1.3 polish drop (5–7 days, target TestFlight 2026-05-22):**

CV-1 + CV-3 + the P1 list above. Tests for each behavior change per the user's "tests required for every new behavior" rule. Player-felt across the session; low surprise risk.

**Pass 2 — v0.2.0 feature additions (post-Reddit-launch, ~3 weeks):**

R-1 (Share Your Pull) first — it converts the game's strongest existing beat into self-marketing content. Then R-4 (pawprint cross-media — now urgent since book is live), then R-2 (Daily Pack) once we have real launch data to balance economy against. R-3 (Today's Squishy) as a LiveOps lever once R-2 ships.

---

## Appendix — agent run summaries

| Agent | Top finding | Effort | Player-visible? |
|---|---|---|---|
| Game-feel | ASMR idle VO is dead code (P1-A) | S | Yes — first-90s hook |
| Game-feel | Screen shake flat amplitude (P1-B) | S | Yes — every burst |
| Game-feel | Mythic haptic same as common (P1-C) | S | Yes — rare moments |
| UX | First-run "How it works" overlay (#1) | S–M | Yes — first 5 min |
| UX | Results-screen → collection bridge (#4) | S | Yes — every round end |
| UI | Card-number WCAG AA failure (#1 fix list) | XS | Yes — Collection screen |
| UI | Results-screen flat hierarchy (#1 polish list) | M | Yes — every round end |
| Perf | Skybox PNG → WebP (-7–8 MB IPA) | S | Indirect — download size |
| Perf | Cache `Paint`/`Shader` per-frame allocs | S | Indirect — frame consistency |
| Research | Share Your Pull (Mystery Dumpling parallel) | M–L | Yes — viral hook |
| Research | Daily Mystery Pack + streak | M–L | Yes — retention loop |
| Research | Today's Squishy featured rotation | M | Yes — Reddit post hook |
