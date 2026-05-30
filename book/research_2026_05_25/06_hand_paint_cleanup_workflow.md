# Hand-Paint Cleanup Pass — What It Actually Involves

*Drafted 2026-05-25. Concrete workflow for the non-optional ~6 hour cleanup pass across 18 spreads. Helps the author judge whether to do it themselves, hire it out, or accept a lower quality bar.*

---

## Why this exists

Research (02_ai_pipeline_recipe.md §5) drew a bright line: **the difference between "obviously AI" and trade-publishable picture-book art in 2026 is a 15–30 minute hand-paint pass per spread.** It's not optional; it's the only thing standing between AI-rendered output and the kind of art a parent flips through at Barnes & Noble without rolling their eyes. Topaz Gigapixel upscaling doesn't fix it. A more expensive AI model doesn't fix it. Time spent in Procreate or Photoshop fixes it.

---

## The 7-step cleanup checklist (applied per spread)

For each of the 18 spreads, work through this list. First few spreads will take 30+ minutes; by spread 6 you'll be at ~15. Total: ~6 hours across the book.

### 1. Eye repaint (5 min)
**AI tell:** "Glassy bead" eyes with mirrored highlights, predictable circular pupils, eyes that don't quite face where the head is.
**Fix:** Zoom in to each protagonist's face. Replace the eye with a **single warm dot** (Klassen technique) or a soft oval with one matte highlight. The eye is the entire emotional vocabulary in a picture book — if you only fix one thing, fix this.
**Tools:** Procreate's monoline brush at 50% pressure, or Photoshop's pencil tool. Pick the color from the existing eye, then darken 1–2 stops.

### 2. Silhouette brush texture (3 min)
**AI tell:** Character edges are uniformly sharp / vector-feeling. Reads as "rendered" rather than "drawn."
**Fix:** Run a **dry-brush** or **gouache** brush at low opacity (20–30%) along the character's outline, only on the side facing the light. Adds the intentional "imperfect edge" that hand-painted picture books have. Don't be precious — irregular is the goal.
**Tools:** Procreate "Gouache" brush set (or any wet-media brush), Photoshop's "Kyle's Bonus Chunky Charcoal."

### 3. Background micro-detail knock-back (5 min)
**AI tell:** FLUX/MJ love to add tiny decorative detail everywhere — extra flowers, extra leaves, fussy texture on tree bark, weird repeating patterns in clouds.
**Fix:** Select the background layer (or anywhere not focal). Apply **Gaussian blur 2–4 px** to the periphery, OR paint over the fussy detail with the same brand color at 60% opacity. The eye should land on the protagonist, not on what's behind them.
**Tools:** Procreate's lasso select + blur, Photoshop's curves + blur on a selection.

### 4. Gutter cleanup (2 min)
**AI tell:** Critical detail accidentally ended up in the center 8% of the canvas (the binding zone).
**Fix:** Overlay a 8%-wide red stripe down the center for reference. If any face/hand/focal eye lands in it: select that element, **content-aware move** it 100–150 px to the left or right. If it can't move (e.g., a body splits the gutter): regenerate that specific spread — don't try to fix it manually.
**Tools:** Photoshop's Content-Aware Move tool (industry standard), or Procreate's selection + move with healing afterward.

### 5. Color correction to chroma curve (3 min)
**AI tell:** Spread's overall saturation doesn't match where it should be on the Sparkle-chroma curve (Spreads 1–6 full, 7–11 desaturated, 12 flood, 13–18 warm dusk).
**Fix:** Apply a **Curves** or **Hue/Saturation** adjustment layer. For desaturating spreads, drop saturation 10–25%. For climax flood, push lavender/mint saturation +20%. For dusk close, warm shift everything toward orange/peach.
**Tools:** Procreate's Curves + Hue/Sat sliders, Photoshop's adjustment layers (non-destructive — keep the originals).

### 6. Focal eye-line sharpening (2 min)
**AI tell:** Eyes feel slightly soft / out-of-focus relative to the rest of the face.
**Fix:** Duplicate the layer. Apply **Unsharp Mask** at 50–80% strength, then mask it to apply ONLY to the eyes (not the whole face). Subtle sharpening on eyes is what makes a character feel **alive** vs. **rendered**.
**Tools:** Photoshop's Unsharp Mask + layer mask, Procreate's sharpen brush mode.

### 7. AI-tell sweep (3 min)
**Visual scan checklist** — eyeball each spread for these:
- **Finger count** on any visible hand (Squishies often have no hands → free win for us, but check guides/Epics)
- **Mirror highlights** on plush body — should be ONE specular dot, not two symmetrical ones
- **Repeated pattern** in foliage/cloud/water texture — if you can see a copy-paste seam, paint over it with a varied stroke
- **Eyes that don't track** the focal action — if the protagonist is looking at the shard, the eye should be aimed at it, not vacant
- **"Concept art" lighting** — dramatic god-rays, lens flare, depth-of-field bokeh. If present, knock back the lighting effect by half.

**Fix for each:** Spot-painting. Same brushes used above. Goal: eliminate anything that breaks the "this is a hand-painted picture book" illusion.

---

## Per-spread time budget (realistic)

| Spread type | Estimated time | Why |
|---|---|---|
| Wide environmental (1, 2, 14) | 20 min | More background to knock back; gutter cleanup more careful |
| Trio walking (6, 8, 10) | 15 min | Standard checklist applies cleanly |
| Triptych (3, 15) | 25 min | Three sub-panels = 3× character cleanup |
| Climax (12) | 35 min | Hand-letter integration adds time; chroma flood; multiple character focal points |
| Soft close (18) | 20 min | Subtle color work + warm-dusk shift critical |
| All other spreads | 15 min | Standard |

**Total estimate: 5.5–7 hours across 18 spreads.** First 3 spreads take longer as you build muscle memory; later spreads are faster.

---

## Tools — what you actually need

**Recommended primary:** **Procreate** ($12.99 one-time on iPad). Industry standard for picture-book digital cleanup. If you have an iPad + Apple Pencil already, this is the cheapest, fastest, most ergonomic option. Brush library handles all 7 steps natively.

**Alternative:** **Photoshop** (Creative Cloud $22.99/mo). More powerful for Steps 4 (content-aware move) and 6 (unsharp mask + mask), but heavier interface. Use if you already have CC.

**Free alternatives:** **Krita** (free, desktop). Photopea (free, browser). Both can do the workflow but neither has Procreate's brush ergonomics. Acceptable if budget-constrained.

**What you do NOT need:** Wacom tablet (a mouse can do this work, even if slower). After Effects. Illustrator. Any AI-touchup tool — those would just re-AI-ify the cleanup you just did.

---

## Realism check — can you do this?

**Yes if:**
- You have an iPad + Apple Pencil already (you've worked with Procreate before)
- You can dedicate 1–2 hour blocks across a week (no need to do it all in one sitting)
- You have a decent eye for what looks "off" — the work is more taste than technical skill

**Probably not if:**
- You've never used Procreate/Photoshop and don't want to learn
- You expect to do this in one evening (you'd burn out by spread 6)
- You can't get into the headspace of "fix one small thing at a time, don't precious about it"

**Honest assessment:** This is the kind of work that's straightforward but tedious. The skill bar is low (it's not illustration; it's cleanup); the patience bar is medium. Most authors who do their own AI-art cleanup find the first 3 spreads frustrating and the last 15 meditative.

---

## If you outsource

**Where to find help:** Fiverr, Upwork, ArtStation Marketplace. Search for "AI art cleanup," "picture book finisher," "illustration touch-up." Look for portfolios that show before/after; avoid anyone who claims to "regenerate the art" — you want a finisher, not a re-illustrator.

**Cost range:** $50–150 per spread for trade-quality cleanup. **18 spreads = $900–2,700.** That's a real budget item.

**Risk:** Quality varies wildly. Get a single-spread paid sample ($50–80) from 2–3 finalists before committing the full job. Worth the $200 to de-risk.

**Turnaround:** 1–2 weeks for a careful single-illustrator job. Faster only if you're paying premium ($150/spread).

---

## What happens if you skip the pass entirely

The book ships, but:
- Visible AI artifacts on most spreads (glassy eyes, fussy backgrounds, vector edges)
- Lower Amazon review average (parents notice, even if they can't articulate why)
- Lower TikTok shareability (videos do close-ups; close-ups expose AI tells)
- Disqualifies for any future trade-publisher conversations (an AD will spot it instantly)

**Acceptable if:** the project's purpose is fast-ship companion volume, not flagship picture book.
**Not acceptable if:** the goal is "the most amazing picture book ever" (your phrasing earlier).

---

## Decision

- **I'll do it** — I write the per-spread cleanup notes as part of the regen pipeline; you execute spread-by-spread alongside.
- **Outsource** — I help you draft the Fiverr/Upwork brief + portfolio criteria.
- **Skip** — I document the quality trade-off in the project memory and we ship without the pass.
