# Book 2 Visual Plan — Synthesis of 4-Track Research (2026-05-25)

*Drafted after four parallel research tracks: picture-book craft fundamentals, AI generation pipeline, exemplar audit of recent kawaii/soft picture books, and a scene-by-scene 18-spread re-composition brief. Each track's full output is preserved in this folder. This document is the **decision-ready synthesis** — the seven things that matter most and the five decisions you need to make before regen begins.*

---

## The 7 highest-leverage moves (cross-cut across all 4 tracks)

### 1. Generate native 2:1 — never stitch two square plates
Your current pipeline (1024×1024 FLUX plates composited in PIL) is the wrong primitive for facing-pair print. Stitching produces seams no feathering hides — lighting direction, palette midpoint, and atmospheric perspective never quite meet. Single biggest quality lever in the whole regen. *(Source: AI pipeline track + research 04 brief.)*

### 2. Build a character model sheet BEFORE any spread regen
3 protagonists × 6 expressions × 4 angles = ~72 reference frames, hand-curated to ~8 keepers, then frozen as the single source of truth for every subsequent spread. Inconsistent character features is a documented KDP rejection reason. *(Source: craft + AI pipeline tracks, converging.)*

### 3. One "signature hue" drives the entire chroma curve
Per Vashti Harrison's *Big* (2024 Caldecott Medal): pick one anchor color tied to the story's emotional engine. **Recommendation: the Sparkle itself** — a candy-bright lavender or mint. Then:
- Spreads 1–6: full saturation (world at peace)
- Spreads 7–11: progressive desaturation (Sparkle is going missing — not darker, just *flatter*)
- Spread 12 (climax): signature hue floods back at maximum saturation
- Spreads 13–18: softens toward warm dusk for the bedtime close

This is the single best craft move surfaced by the research. *(Source: craft + exemplar tracks, converging.)*

### 4. The shout-line is hand-lettered, integrated as composition
"EVERYBODY SQUISH!" is the visual zenith of the book. Don't typeset it — letter it into the art (Pete Oswald *Bad Seed* technique). Treat it as a comic-grammar shout balloon: characters' faces partially behind the letters, letters bouncing on a curved baseline, radial bursts emanating from the letterforms. The shout-line *is* the composition on Spread 12, not text-on-top-of-composition.

Bonus: consider a **cumulative-chant manuscript revision** (Wonky Donkey / Bear Snores On pattern) — each of the three pack-worlds contributes a chant-word in their respective spreads, then they all unify in the climax. ~30–50 words added; materially improves read-aloud + highest TikTok-virality leverage. **This would reopen one locked manuscript element — your call.** *(Source: craft + exemplar tracks.)*

### 5. The hand-paint cleanup pass (15–30 min/spread, Procreate/Photoshop) is NON-OPTIONAL
This is the single line research drew brightest: it's the difference between "obviously AI" and "trade-publishable." Knock back background micro-detail, add intentional dry-brush texture at focal silhouettes, re-paint eyes as a single warm dot (not the AI default "glassy bead"), fix any gutter intrusions. ~6 hours of work across 18 spreads. Cannot be skipped; cannot be automated. *(Source: AI pipeline track, with strong consensus across cited sources.)*

### 6. Style anchor: Klassen-meets-Christian-Robinson (recommended)
Limited warm palette, simple geometric character forms, flat color blocks with restrained texture, soft North-window light. NOT Sendak (too dark for our audience), NOT Alemagna (too European-art-school for a 4–8 crossover), NOT cartoon-outline (too cheap for the Caldecott-aware register we want). The exemplar reference closest to where we should land aesthetically is **Vashti Harrison's *Big*** — chalk-pastel + digital, no hard outlines, forms built from shaded mass. *(Source: AI pipeline + exemplar tracks, converging.)*

### 7. The 18-spread composition brief is concrete and ready to execute
The 04 brief in this folder specifies per-spread: composition concept, gutter strategy (with literal x-coordinate placements), prose-band position/height/font/word-count, page-turn rhythm, what changes from v1, and production tasks. The hardest **narrative-design** work is done. What's left is production execution. Highlights:
- **Spread 4** (the border) — gutter IS the composition (the binding becomes the boundary between Pudding Hills and Goo Coast). Originally awkward at 1:1; will be the spread that benefits *most* from 2:1.
- **Spread 11 → 12** — the most page-turn-load-bearing moment in the book. Spread 11 ends with the trio huddled scared in the dark, the prose ends "*trembled*"; the reader's body leans in; turn delivers the shout-line explosion. The entire book is choreographed around this one page-turn.
- **Spreads 1 and 14** — circle-back compositions; same camera, same atmosphere, different chroma (peace → restored brighter peace). Reinforces the satisfaction of resolution.
- **Spread 18** — quietest spread in the book; deliberately thinnest text band; Squishkeeper voice surfaces in italic. Bedtime close.

---

## Cross-cutting tensions surfaced

**Craft purity vs. commercial reality.** The Caldecott-tier exemplars (Klassen, Sam & Dave, Du Iz Tak?) preach restraint; the commercial juggernauts (Bad Seed, Don't Push the Button, Knight Owl) preach saturation and cute-character punch. **Synthesis position:** Aim for Vashti Harrison's *Big* register — Caldecott-respected but commercially scoped. Limited warm palette, soft chalk-pastel, but with the chroma flooding at the climax that retail picture books reward.

**Concept-doc locks vs. craft improvements.** BOOK2_CONCEPT_DRAFT.md says the story spine + format + voice rules are invariant. The cumulative-chant suggestion (move #4) and any palette shifts that affect prose would touch invariants. The concept doc itself explicitly permits reopens "(b) the user explicitly reopens them." **Synthesis position:** the cumulative-chant is the only invariant-touching suggestion worth raising — every other move stays inside the lock.

**Manuscript was built for square renders with prose baked in.** Best practice is to keep type as live type (InDesign / Affinity), not raster. The existing renders compile prose into the PNG. **Synthesis position:** the regen pipeline must separate art (FLUX/MJ → PNG, no text) from typography (Affinity Publisher → final PDF). Existing renders are abandoned for production purposes (preserved at git tag `book2-format-A-snapshot`).

**Skepticism flag on specific tool/model claims.** Some specific claims in the AI-pipeline research (e.g., "Midjourney v8.1", "FLUX 2 [pro] supports 4MP", "Topaz Gigapixel $99 one-time", "Feb 2026 SCOTUS Thaler decline") should be verified before spending. The agent had web access but the rapid-fire 2026 AI landscape evolves weekly. **Spot-check current pricing and feature claims on the official sites before committing to a subscription.**

---

## Five decisions you need to make before regen starts

### Decision A — Tool stack + budget tier

| Tier | What's in it | Cost | Risk/Tradeoff |
|---|---|---|---|
| **Minimal** | FLUX dev/Kontext on fal.ai + free LoRA training | ~$10 | Research says FLUX-vanilla skews photoreal in 2026; lower aesthetic ceiling. Cheapest. |
| **Mid (recommended)** | Midjourney Standard ($30/mo) + FLUX Kontext on fal.ai (~$10) + Topaz Gigapixel ($99 one-time if not owned) | ~$50–140 | Research's recommended path; best aesthetic-per-dollar ratio. |
| **Premium** | Midjourney Pro ($60/mo Stealth Mode) + FLUX + Gigapixel + Magnific Pro month ($39) | ~$200 | Every tool maxed; Pro Stealth keeps generations private (matters if you don't want the prompts indexed). |

### Decision B — Cumulative-chant manuscript revision?
Add ~30–50 words distributed across spreads 6, 8, 10 + restructured 12 to build a chant the climax breaks. Materially improves read-aloud + TikTok-virality. Touches the "voice invariants" lock — your explicit reopen.

### Decision C — Style anchor approval
- **Klassen-meets-Christian-Robinson** (recommended) — limited warm palette, geometric form, restrained texture
- **Vashti Harrison's *Big*** — soft chalk-pastel + digital, no outlines, shaded mass
- **Christopher Denise's Knight Owl** — pencil + digital, cinematic firelight, dramatic chiaroscuro
- **Custom direction** — describe what you want

### Decision D — Hand-paint pass — who and when
~6 hours total (18 spreads × 20 min average) of Procreate or Photoshop work. Not skippable per research. Do you have Procreate set up? Is this work you do (you have the visual eye + the device) or do we need to outsource?

### Decision E — Page count
Concept doc locks 40pp. C-format math: 1 title + 1 copyright + 1 dedication + 36 spreads (18 × 2 facing pages) + 1 back matter = 40 ✓. Stay at 40, or invest in 44 for proper back matter (Book 1 callback + author bio on separate pages)? Spine width recomputes either way.

---

## Suggested next concrete step (if you approve the plan)

**Day 1 — Character model sheet.** Generate 30–40 candidates of Soft Dumpling + Goo Ball + Blushy Bun Bunny in the chosen style anchor at 2:1 (or 1:1 for character sheets, then assemble). ~$5–15. Hand-select 8 keepers, mild Procreate touch-up. This is the LoRA training input AND the visual canon for the rest of the regen.

I can write the FLUX/MJ prompts for the sheet generation; you run the calls and select winners (since I can't see image quality in real time). 1 working day end-to-end.

After the sheet is locked: LoRA training (Day 1 evening, $3, 30 min) → spread regen (Days 2–4, $6 compute, 4 candidates per spread) → upscale (Day 5) → hand-paint pass (Days 6–8) → interior PDF assembly + cover + KDP upload (Days 9–10).

**Total project: 9–10 working days. Total spend: ~$50–150 depending on tier.**

---

## Where the four research files live

- `00_SYNTHESIS_visual_plan.md` — this document
- `01_picture_book_craft_brief.md` — picture-book fundamentals (gutter, pacing, color, character anchoring, type, 6 books to study)
- `02_ai_pipeline_recipe.md` — tool choice, aspect/resolution math, style consistency, gutter prompting, AI-tell removal, KDP disclosure
- `03_exemplar_audit.md` — 10 published exemplars from 2017–2025 with steal/avoid notes + 7-bullet synthesis
- `04_scene_recomposition_brief.md` — per-spread 2:1 composition brief (gutter strategy, prose placement, page-turn rhythm, what changes from v1, production tasks) — the operational document for the regen
