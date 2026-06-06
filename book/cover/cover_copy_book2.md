# Squishy Smash — Book 2 Cover Copy

**Production target:** KDP paperback wrap cover, 8.5 × 8.5 in trim, 40-page interior, premium-color paper, matte finish.

**Cover wrap PDF dimensions** (single PDF that includes back + spine + front, with bleed):
- Width: **17.3439 in** (back 8.5 + spine 0.0939 + front 8.5 + 0.125 left bleed + 0.125 right bleed)
- Height: **8.75 in** (8.5 + 0.125 top + 0.125 bottom)
- Spine width formula: `pages × 0.002347` for premium-color paper. 40 × 0.002347 = **0.0939 in**. Computed live by `book/build/config.py` `SPINE_W_IN` once `INTERIOR_PAGES=40` is parameterized for Book 2.

**Spine warning:** at 40 pages the spine is well under KDP's ~80-page threshold for spine text — brand-color band only, no text. Same approach as Book 1.

**KDP barcode safe zone:** KDP auto-overlays the barcode at the lower-right of the back cover, in a 2 × 1.2 in area positioned 0.25 in from trim edges. Keep this zone empty.

**Companion canonical docs:** [`KDP_METADATA_SCRATCH_BOOK2.md`](../KDP_METADATA_SCRATCH_BOOK2.md) (KDP submission metadata), [`STORY_BIBLE.md`](../STORY_BIBLE.md) (voice + canon), [`BOOK2_CONCEPT_DRAFT.md`](../BOOK2_CONCEPT_DRAFT.md) (story spine + locked decisions), [`manuscript/book2_manuscript_draft.md`](../manuscript/book2_manuscript_draft.md) (final 928-word manuscript).

**Decisions locked here come from** the 2026-05-29 three-agent typography research (memory: `book2-text-system-locked`). These are the rules; deviation requires a new design call.

---

## 1. Strategy departure from Book 1

Book 1's `cover_copy.md` (Meet the Squishies) is a **catalog cover**: bright character cards on a flat starry-night, Fredoka wordmark typeset in ReportLab, three-card panel grid on the back. Correct for a character reference book.

Book 2 is a **storybook**. The cover system shifts to follow the Christopher Denise *Knight Owl* / *Knight Owl & Early Bird* series convention — the closest in-market analogue for what Book 2 is doing typographically and tonally:

- Custom-tuned serif series wordmark (NOT Fredoka), pre-rendered and **locked as a series asset** that Books 3–5 inherit
- Painterly Knight-Owl-style dusk-warm hero scene (not deep night)
- Cream type on dark sky for premium reverse-out contrast
- Storyteller-voice back cover (not card-grid catalog back)

Both styles are official Squishy Smash visual languages — the catalog book and the storybook line — same as the Squishmallows / Pokémon / Sanrio precedent of multiple visual treatments for the same characters.

---

## 2. FRONT COVER

### Title block (typeset overlay, NOT painted into the art)

The wordmark is composited on top of the painterly hero by the build pipeline. The hero scene is generated text-free in Nano Banana Pro with a directive to reserve clean wash-sky in the top third for the title — this isolates typography risk from the painterly art.

**SQUISHY SMASH** — series mark
- Font: **Recoleta Bold** (Latinotype, ~$60 single-weight license).
  - Free-font fallback for v1 if license is skipped: **Fraunces Black** (Google Fonts) — chunky display serif, close enough match.
  - **Fredoka stays off Book 2's front cover.** Fredoka is the game/catalog branding; Recoleta signals storybook.
- Treatment: Custom-tuned letterforms — slightly redrawn terminals via PIL so it reads hand-cut, not raw font-dropped (the #1 amateur tell)
- Color: warm cream `#F5E9D0`
- Shadow: ~0.5 px soft palette-brown shadow, color sampled from the painting's deepest warm shadow. **NEVER pure black** — pure-black shadow on warm painterly art is the second-most-common amateur tell.
- Size: ~140 pt-equivalent uppercase at print resolution, tracking tight (−15 to −25 units)
- Position: top third of the cover, centered horizontally, inside safe area

**The Lost Sparkle** — volume tag
- Font: **EB Garamond Italic** (already in brand stack)
- Color: dusty gold `#E4C46C`
- Size: ~40% of the SQUISHY SMASH height
- Position: centered baseline directly beneath the wordmark
- Optional accent: tiny painted sparkle glyph on either side, sampled from the hero scene

**Locked series asset:** the rendered SQUISHY SMASH wordmark gets saved as `book/assets/wordmark_series.png` (4× print resolution, transparent background). Books 3, 4, 5 drop this exact PNG into their cover-wrap script unchanged. Only the volume tag swaps per book.

### Hero art (lower two-thirds — painterly scene)

**Composition:** trio meeting at a border with the lost Sparkle as a glowing accent. Storytelling staging, not character lineup.

- **Soft Dumpling** — slightly forward, the thumbnail anchor. Neutral pose, gentle smile.
- **Goo Ball** — supporting, slightly behind and to one side.
- **Blushy Bun Bunny** — supporting, opposite side from Goo Ball, completing the trio triangle.
- **The Sparkle** — a glowing warm-gold accent in the sky above the trio (smaller than the wordmark, larger than a normal star). Painted, not typeset.

**Generation pipeline:** same Nano Banana Pro multi-image-reference setup used for the 18 interior spreads (`book2_pipeline_2026_05_29/04_production_batch_21x9.py`), with these changes for the cover:
- `image_config.aspect_ratio="1:1"` (cover trim is 8.5×8.5, not 21:9)
- 3 protagonist refs (Soft Dumpling, Goo Ball, Bun neutral poses from `_tmp_mj_winners/`)
- Prompt directive: *"reserve clean upper third with soft watercolor wash for title space, no text in image, no letters, no words, no book cover artifacts"*
- Style tail: same Christopher Denise watercolor+gouache lane established for the interior

### Backdrop (the palette shift)

Knight-Owl-style **dusk-warm**, NOT Book 1's deep night.

| Token | Hex | Use |
|---|---|---|
| `cover_sky_top` | `#1B2440` | Deep teal-indigo at top of sky, holds the wordmark's reverse-out contrast |
| `cover_sky_mid` | `#3D3155` | Warm-leaning indigo bridge into horizon |
| `cover_horizon` | `#E4A56C` | Warm dusk glow at horizon line |
| `cover_lowlight` | `#F5C97A` | Brightest horizon point, sparkle echo |
| `wordmark_cream` | `#F5E9D0` | SQUISHY SMASH letterforms |
| `volume_gold` | `#E4C46C` | "The Lost Sparkle" letterforms |

Bridge to Book 1: same cream-on-dark contrast system for the wordmark; same character identities; same series wordmark file (when Books 3+ ship). Different lighting + staging + tone signals "storybook chapter, not catalog volume 2."

### Volume tag (lower-right corner, inside safe area)

Small **"BOOK TWO"** tag in Recoleta Caps 9pt, letter-spaced 80 units, color `#E4C46C`. Confirms a series and primes returning buyers.

### Author byline (bottom, subtle)

**Christopher Ryan Campbell** — centered above the lower trim safe zone, EB Garamond Caps 9pt, letter-spaced 50 units, color `#F5E9D0` at 70% opacity. Subtle, not a hero element.

---

## 3. BACK COVER

**Drop Book 1's three-card panel grid.** The card grid is catalog convention and reads wrong for a storybook. Replace with the Knight Owl / Candlewick storybook layout.

### Vignette (upper third, centered)

Small painted vignette ~2.5 × 2.5 in: the **lost Sparkle alone** glowing in painted darkness. Silent atmosphere, no characters. Generated by the same NBP pipeline.

### Headline (mid-upper, centered)

> *A sparkle goes missing. Three new friends go looking.*

- Font: **EB Garamond Italic**
- Size: 22 pt
- Color: `#E4C46C` (volume gold)
- Width: ~5 in, centered

### Body blurb (centered under headline)

~70 words, storyteller voice (NOT marketing voice — the storyteller is the Squishkeeper persona).

> When the last Sparkle of the Squishy World flickers and splits into three, Soft Dumpling sets out into the warm dark to find the missing light. Along the way she meets a curious Goo Ball and a Blushy Bun Bunny — and discovers that some sparkles are only found when three first feelings remember each other.
>
> *Every pop is a hello. Every hello comes back.*

- Font: **Sorts Mill Goudy** (NEW — replaces EB Garamond for body text on Book 2 going forward, see §5 type-system note)
- Size: 11 pt / 15 pt leading
- Color: `#F5E9D0` (cream)
- Width: max 4 in, centered
- Last line italic (the Pact, see [`STORY_BIBLE.md`](../STORY_BIBLE.md) §2)

### Series footer (above barcode safe zone, left side)

**SQUISHY SMASH · BOOK TWO**

- Font: Recoleta Caps 8 pt, letter-spaced 80 units
- Color: `#E4C46C`
- Position: left side of the lower strip, well clear of the KDP barcode safe zone

### Far-bottom metadata (centered above bottom trim)

**Ages 4–8 · squishysmash.com · © 2026 Christopher Ryan Campbell**

- Font: Sorts Mill Goudy Caps 7 pt
- Color: `#5A4A6E` (subdued, doesn't fight the storybook tone)
- Centered above the lower trim safe zone

### Barcode safe zone

Lower-right 2 × 1.2 in, 0.25 in inset from trim edges. **Reserved empty** — KDP auto-overlays its own barcode. The `build_cover.py` debug-outline rect is OFF for production (was disabled in Book 1's final build; preserve that).

---

## 4. SPINE

**No spine text** — 40 pages is well under KDP's ~80-page text threshold. Brand pink `#FF8FB8` band only, full bleed, matches Book 1's spine treatment so the books shelf as a coherent series.

---

## 5. The Book 2 type system (new, for the storybook line)

**Book 2 type system (UPDATED 2026-05-30 after user activated Adobe CC):** Single-family typography centered on the Bookmania family (Mark Simonson, Adobe Fonts) — display + body + italic from one family, a Candlewick/Walker-tier hallmark of premium picture book production. Bookmania is a modern descendant of Bookman Oldstyle, which historically *was* the mid-century American picture book body workhorse.

| Surface | Font | Notes |
|---|---|---|
| Cover series mark | Bookmania Black (Adobe Fonts) | Locked across series. ~80% width. |
| Cover volume tag | EB Garamond Italic | 42% of series mark height. (Kept for warmth + italic distinction.) |
| Cover small caps (BOOK TWO, byline) | Bookmania (Black) Caps + EB Garamond Caps for byline | Letter-spaced 50–80 units. |
| Back-cover headline | EB Garamond Italic | 22 pt, volume gold. |
| Back-cover blurb body | Bookmania Regular | 11/15 pt, cream. |
| Interior body prose (18 spreads) | **Bookmania Regular** | 18/26 pt, ragged-right, palette-brown sampled per spread. |
| Interior italic (Squishkeeper voice + sound words) | **Bookmania Italic** | Same size as body. |
| Cumulative chant escalation (S6 → S8 → S10 → S12) | Bookmania Italic body → Bookmania Black Italic at S10 chant payoff (22pt) → Bookmania Black Italic ALL CAPS at S12 (28pt) | Same letterform DNA, escalating scale + weight. |
| Climax shout S12 ("EVERYBODY SQUISH!") | NBP-generated painterly hand-lettering | Alpha-keyed, composited on the burst. |

**Why Bookmania over Sorts Mill Goudy** (the prior pick): family unity with the cover wordmark, larger x-height + open counters that survive watercolor wash at 18pt better, true drawn italic across all weights for the chant escalation. EB Garamond stays only as the volume-tag italic + back-cover headline italic + byline small caps — both for warmth contrast and to keep one elegant counterpoint to the chunky Bookmania.

**Per-spread interior layout** is fully prescribed in [`../manuscript/book2_layout_brief.md`](../manuscript/book2_layout_brief.md) — per-spread (x, y, w, h) coordinate boxes + placement technique + sampled palette colors for all 18 spreads. The build pipeline reads from this.

Fredoka stays for Book 1 (catalog) and in-game/marketing surfaces. Caveat Brush stays as the accent letterer for the cumulative chant. The Squishy Smash brand owns multiple typographic identities — same characters, different lanes.

---

## 6. Locked decisions

1. **Wordmark technique:** Recoleta Bold typeset + custom-tuned, NOT hand-lettered for v1 (Path A from the 2026-05-29 decision). Path B (commission a real letterer) is an open upgrade for any future version — the cover-wrap script just swaps one PNG asset.
2. **Hero composition:** trio meeting at a border with painted Sparkle accent. Soft Dumpling slight-forward thumbnail anchor.
3. **Sky palette:** dusk-warm `#1B2440 → #E4A56C → #F5C97A`, NOT Book 1's deep night `#120B17`.
4. **Body font for storybook line:** Sorts Mill Goudy (free), NOT EB Garamond. EB Garamond keeps a smaller role for italic headlines + accents.
5. **Back cover layout:** Knight Owl / Candlewick storybook style, NOT Book 1's three-card panel grid.
6. **Spine:** brand pink band, no text. Matches Book 1.
7. **Byline:** Christopher Ryan Campbell (locked per `book-byline-isbn-locked` memory).
8. **Series wordmark asset:** locked PNG at `book/assets/wordmark_series.png`. Books 3, 4, 5 inherit.

---

## 7. Production order (for the cover-build pipeline)

1. **Procure Recoleta Bold license** OR pin Fraunces Black as v1 fallback
2. **Render the wordmark** in PIL with custom-tuned terminals → `book/assets/wordmark_series.png` (transparent, 4× resolution)
3. **Generate the front-cover hero** via Nano Banana Pro (same pipeline as interior spreads, 1:1 aspect, dusk-warm prompt, top-third title space reserved)
4. **Generate the back-cover Sparkle vignette** via NBP
5. **Fork `book/build/build_cover.py` → `book/build/build_cover_book2.py`** (or parameterize INTERIOR_PAGES + add a `book` arg) to:
   - Read `wordmark_series.png` for the front title overlay
   - Skip the T1_title route (Book 1 path); composite the NBP hero + wordmark + volume tag directly
   - Replace `draw_back_cover` with Knight-Owl-style vignette + headline + Sorts-Mill-Goudy blurb + series footer
   - Use 40-page spine math (0.0939 in)
6. **Output `cover_wrap.pdf`** at 17.3439 × 8.75 in
7. **Pre-submit gut check** against `PROOF_CHECKLIST.md` + [`KDP_METADATA_SCRATCH_BOOK2.md`](../KDP_METADATA_SCRATCH_BOOK2.md) §8 Volume-2-specific checks

---

*Drafted 2026-05-29 from the parallel-agent typography research synthesis. Decisions sign-off'd by user the same day. Update only if a manuscript or production constraint surfaces a contradiction.*
