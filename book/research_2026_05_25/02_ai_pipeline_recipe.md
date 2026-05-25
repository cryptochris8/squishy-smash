# Squishy Smash: The Lost Sparkle — Picture-Book Regen Technical Recipe

*Research output, 2026-05-25. AI generation pipeline for 2:1 facing-pair picture-book quality.*

Target: 18 facing-pair spreads, 8.5×17in at 300 DPI (~5100×2550 px), trade-publishable picture-book quality, KDP-publishable, ages 4–8.

## 1. Tool choice — picking the generator

The 2026 model landscape has bifurcated: **FLUX 2 tunes hard toward photorealism, while Midjourney v7/v8 retains a clear lead for artistic / illustrative / painterly output.** For a soft, painterly children's book in the Klassen / Sendak / Alemagna lineage, FLUX-vanilla is the wrong tail.

FLUX has the better commercial-illustration-specific tooling stack (Kontext multi-image, dev LoRA training, Kontext LoRA). The right answer is **mixed pipeline**:

- **Primary generator:** Midjourney v8.1 ($30/mo Standard, ~900 image jobs; or $60 Pro for Stealth Mode — recommended for commercial book work)
- **Consistency engine:** FLUX.1 Kontext [pro] via fal.ai (~$0.04–0.08/image) or FLUX Kontext LoRA trained on 4–8 character sheets ($1–3 one-time)
- **Backup / volume:** FLUX 2 [dev] at fal.ai ($0.012/MP, ~$0.03 per 4MP image) for backgrounds-only and texture passes

**Cost reality:** 18-spread regen with 4 generations per spread (72 generations) = ~$3 on FLUX or ~one month of MJ Standard amortized. Existing $1.25 spend was cheap because of low resolution + PIL compositing. Quality bar requires you to spend more — **budget $30–60 in tooling**.

Skip: Sora (dead in 2026), DALL-E (not competitive), Imagen 4 (best for text-in-image, irrelevant), Recraft (vector/flat, wrong for painterly).

## 2. Aspect ratio and resolution — the actual numbers

**Picture-book spread math:** 8.5×17in trim + 0.125" bleed each side → 8.625×17.25in canvas → 300 DPI = **5,175 × 2,587 px** for final delivery.

**What to generate at:**
- **Midjourney v7/v8:** `--ar 2:1` is fully supported. Generate at 2:1 native.
- **FLUX.1 dev / Kontext / FLUX 2:** native 2:1 works; target ~1408×704 or 1536×768 (1MP sweet spot). Wider risks compositional duplication ("two heroes, one on each side" failure).
- **FLUX 2 [pro]/[max]:** up to 4MP natively → 2048×1024 or 2816×1408 at 2:1.

**Native wide vs stitch two squares:** **Generate native 2:1.** Stitching produces seams no feathering hides — lighting direction, palette midpoint, atmospheric perspective never quite meet. **Your current PIL-composited pipeline is the wrong primitive for the regen.**

**Upscaling for print:** Generate at 1536–2048 wide, then upscale to ≥5100 wide. **Topaz Gigapixel ($99 one-time)** is the 2026 workhorse for fine-art-print upscaling — preserves brush/paint texture without inventing detail. Magnific (Creative mode invents detail; use only Precision). Avoid Photoshop's generative upscale for print.

Per spread: $0.04 × 4 candidates + $0.10 Gigapixel = ~$0.30. 18 spreads ≈ $5–6 + MJ subscription.

## 3. Style consistency — what actually works

**Tier 1 — works reliably in 2026:**
1. **Custom LoRA trained on a 15–30 image character/style sheet.** FLUX 2 [dev] LoRA training on fal.ai ~$2–5 one-time, 85–95% feature retention across long runs. Gold standard.
2. **Midjourney `--sref` + `--cref` with `--cw 80–100`.** Lock one or two SREF codes for the whole book. Degrades on extreme pose changes.
3. **FLUX.1 Kontext [pro] multi-image.** Up to 10 reference images, ~$0.08/image. Degradation after 6 iterative edits — treat each spread as a fresh Kontext call from master sheet.

**Tier 2 — partial wins:** IP-Adapter + same seed (drifts), prompt-only consistency (50% hit rate).

**Tier 3 — still wishful:** "Just use the same seed" (no longer works on FLUX 2), stacking ControlNet pose+style+character (output goes flat — pick two).

**Recommended for Squishy Smash:** Train one FLUX.1 Kontext LoRA on 8 hand-selected reference frames of Soft Dumpling + Goo Ball + Blushy Bun Bunny + sparkle motif + world palette (~$3, one-time). Generate all 18 spreads via FLUX Kontext [pro] with this LoRA + one consistent SREF-style anchor. Roundtrip cover + 3 most emotional spreads through MJ v8.1 with `--cref --sref`.

## 4. Gutter-safe composition

- Gutter loss ≈ 0.375" for KDP perfect-bound at 32 pages (≈112 px at 300 DPI per side)
- **No face in the gutter.** Cardinal rule.
- **No diagonal/horizontal lines crossing the gutter.** They misalign at bind.

**Prompting clause to add to every spread:**
> "...composition: two-thirds rule, main subject offset to the left third (or right third), central foreground clear of figures, deliberate negative space across the vertical center axis, secondary elements tolerating center, no face or hand within central 8% of image width..."

**Split spreads (action left, reaction right):** prompt the split explicitly:
> "...diptych composition, two characters on opposite sides of frame separated by a natural vertical element (tree trunk / waterfall / shaft of light), each character framed in their respective half..."

**Validation:** before approving, overlay a 225-px-wide red stripe down the center. If a face/hand/critical detail lands inside → reject and re-roll.

## 5. Removing the AI tells

**FLUX-specific:** FLUX does not honor traditional negative prompts (trained with flow matching at CFG=1). **Frame everything positively.**

**Positive-frame anti-AI vocabulary that works:**
- Pro: "visible brush-stroke", "cold-press paper texture", "ink-line outline with watercolor wash", "flat areas of color", "limited 8-color palette", "imperfect pencil under-drawing", "gouache opacity", "registration-offset ink line", "matte finish"
- Avoid: "detailed", "intricate", "hyperrealistic", "8k", "cinematic", "trending on artstation", "concept art", "epic lighting", "octane render"
- Lighting: "soft North-window light", "even diffused light", "no specular highlights"
- For hands: don't say "hands" if not visible. Squishies often have no hands → free win.

**Inpainting pass:** ADetailer + YOLO face/hand detection in ComfyUI. Inpaint at 0.35–0.45 denoise. 5–10 min per spread.

**Hand-paint pass (the "trade publisher tell"):** the difference between obviously-AI and publishable is a **15-minute Procreate/Photoshop pass per spread**: knock back background micro-detail, add intentional dry-brush at focal silhouettes, re-paint eyes as a single warm dot. **Not optional.**

## 6. Painterly style language that lands

- **Klassen-adjacent:** `"limited palette of deep forest greens, warm browns, ivory cream, soft graphite texture, ink-and-gouache, simple geometric character shapes with one expressive eye, hand-cut paper feel, matte finish"`
- **Christian Robinson-adjacent:** `"flat cut-paper collage shapes, warm earth-tone palette, geometric simplified figures, no rendered shading, hand-cut edge irregularities, mid-century picture-book influence"`

For Squishy Smash: **Klassen-meets-Christian-Robinson** — limited warm palette, simple geometric character forms, flat color blocks with restrained texture. Not Sendak (too dark), not Alemagna (too European-art-school for 4–8 audience).

**Living-illustrator naming:** Commercial gray zone. Safer 2026 practice: invoke *the technique* and *the era*, not the named living artist. "Warm limited-palette flat-color picture book illustration in the spirit of mid-century children's books" gets 80% there.

## 7. Commercial reality check — KDP and disclosure

- **KDP accepts AI-illustrated children's books in 2026, with mandatory disclosure.** Required checkbox at upload.
- Disclosure not shown to readers on product page.
- Quality bar same as hand-illustrated: 300 DPI, sRGB, flattened, **consistent character features.** Inconsistent characters is a documented rejection reason.
- Removal risk is for **non-disclosure**, not AI use.
- **Copyright:** unmodified AI output is not copyrightable in US (Feb 2026 SCOTUS Thaler). Hand-paint cleanup gives defensible compilation/derivative copyright.
- **Midjourney commercial license:** included with any paid tier. Corporate tier required only at $1M+ annual revenue.

## Concrete pipeline for the 18-spread regen

1. **Character/style sheet day (Day 1, $5–15):** Generate 30–40 candidates in MJ v8.1 in Klassen-Robinson hybrid, `--ar 2:1 --cw 100 --sv 4`. Hand-select 8 best, mild Procreate touch-up.
2. **LoRA train (Day 1, ~$3, 30 min):** Upload 8 sheets to fal.ai → FLUX.1 [dev] LoRA training. Save LoRA ID.
3. **Spread generation (Days 2–4, ~$6):** For each spread:
   - Prompt: `[scene] + [composition clause §4] + [style vocab §6] --ar 2:1`
   - Tool: FLUX.1 Kontext [pro] on fal.ai with trained LoRA + master style reference
   - 4 candidates × $0.04 = $0.16/spread
   - Hero spreads (cover, climax, resolution): also MJ v8.1 with `--cref --sref` for comparison
4. **Upscale (Day 5):** All 18 finals through Topaz Gigapixel "Standard v2" to ≥5175×2587.
5. **Hand-paint pass (Days 6–8, time-only):** 15–30 min per spread. **Non-skippable.**
6. **Gutter validation:** overlay center red stripe.
7. **KDP upload:** check AI-image disclosure box.

**Total budget:** $30–60 in tooling + ~$10 compute. Time: 5–8 working days.

## Honest limits

- 18 spreads is at the upper edge of LoRA + Kontext consistency. Budget 2–3 re-rolls.
- An experienced AD will spot AI in 30 seconds in 2026. Bar isn't "fool an AD" — it's "feel cohesive for ages 4–8 readers, disclosure honest enough for scrutiny."
- Biggest quality gain over current $1.25 pipeline isn't the model — it's **generating native 2:1 instead of stitching squares** + **hand-paint pass.**

## Sources

- cliprise.app — Best AI Image Generator 2026 comparison
- Flowith — Midjourney V7 vs Flux
- Black Forest Labs — FLUX.1 Kontext announcement
- programminginsider.com — AI Character Consistency 2026
- neolemon.com — KDP AI Disclosure Policy 2026
- terms.law — Midjourney Commercial Use Rights 2026
- LetsEnhance — Top 5 AI Image Upscalers 2026
- arxiv 2507.07133 — Generative Panoramic Image Stitching
- midlibrary.io — Jon Klassen Midjourney style reference
