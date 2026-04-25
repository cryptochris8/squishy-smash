# Archive: Claude Kickoff Pack

These docs were the **original greenfield kickoff bundle** for Squishy Smash, from before the project shipped. They describe the *intended* MVP — three packs, tap/drag interactions, JSON-driven content, simple progression — which has since been delivered, and in most areas significantly exceeded.

## Why these are archived (not deleted)

They remain useful as historical context for new contributors who want to understand the original product thinking. Specifically:

- **`01_product_brief.md`** — original audience + tone framing. Still accurate.
- **`02_game_loop_and_systems.md`** — proposed five-interaction model (tap, drag, **rapid slap**, **crush hold**, **flick throw**) and three modes (**Quick Smash**, **Combo Rush**, **Burst Lab**). Only Quick Smash + tap/drag shipped. The other interactions and modes are forward-looking ideas if the team wants to expand depth.
- **`03_content_pipeline.md`** — original schema and "weekly drop" cadence. The live schema is richer (see `lib/data/models/content_pack.dart`); the weekly-drop cadence is aspirational, not committed.
- **`04_audio_vfx_plan.md`** — proposed 4 light + 4 medium + 3 burst + 2 goo variants per object. Currently we ship 3 squish + 1 burst per object. Future audio expansion target.
- **`05_ios_build_spec.md`** — pre-implementation architecture. All shipped through v0.5+. The proposed analytics event taxonomy (`session_start`, `round_complete`, etc.) was superseded by the richer event surface in `lib/analytics/events.dart`.
- **`claude_one_shot_prompt.md`** — meta-prompt for greenfield rebuild. **Do not run** — would clobber 4 packs + 48 named squishies.

## Live design docs (use these, not the archive)

- `docs/squishy_smash_enhancement_plan_for_claude.md` — game-feel enhancement plan
- `docs/gameplay_enhancement_roadmap.md` — current gameplay roadmap
- `docs/collectible_rarity_map.md` — 48-item collection design (canonical)
- `docs/squishy_smash_drop_rate_tuning_and_pity_system_for_claude.md` — pity + drop rates (canonical)
- `docs/squishy_smash_monetization_spec_for_claude.md` — monetization (canonical)
- `docs/squishy_smash_branding_logo_icon_brief_for_claude.md` — branding direction (canonical)
- `docs/squishy_smash_asset_production_pack_for_claude.md` — asset pipeline
- `docs/app_store_listing.md` — App Store ASO copy
- `docs/launch_punch_list.md` — submission blockers
- `docs/elevenlabs_prompt_sheet.md` — audio prompts (in-game + marketing VO)
- `docs/tiktok_campaign.md` — social campaign plan
- `docs/ip_guardrails.md` — naming + IP policy

## Schema authority

The **live JSONs** at `assets/data/packs/*.json` and `assets/data/liveops_schedule.json` are the authoritative content shape. If anything in these archived briefs conflicts with what's parsed by `lib/data/models/content_pack.dart` and `lib/data/models/liveops_schedule.dart`, the code wins.

## ⚠️ Stale sample configs (do not copy)

Two sample JSON files in this folder are **out of date**:

- `sample_content_pack.json` — missing `packProgression` block, missing per-object `rarity` field, points at non-existent asset paths (`assets/objects/...`, `audio/jelly/...`, `.wav` files). If copied as a starting template the resulting pack would silently treat every object as common — `RarityPitySelector` falls back to common when `rarity` is absent, so no rare/epic/legendary would ever spawn from that pack.
- `sample_liveops_schedule.json` — three rotation rows with stale `weekOf` dates and a stale `promoLabel`.

**If you're authoring a new pack or schedule, copy from the live JSONs instead:**

- New pack template: `assets/data/packs/launch_squishy_foods.json` — covers every rarity tier with `behaviorProfile`, explicit `rarity`, and a populated `packProgression` block. Minimal shape the runtime accepts cleanly.
- New rotation entry: append to `assets/data/liveops_schedule.json` matching the existing row shape (`weekOf`, `featuredPack`, `eventModifier`, `promoLabel`).
