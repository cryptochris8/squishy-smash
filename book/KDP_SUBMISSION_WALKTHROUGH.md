# Squishy Smash — KDP Submission Walkthrough

A step-by-step "click here, then here" guide for taking `interior.pdf` + `cover_wrap.pdf` from your local build to a live Amazon listing. Companion to `PROOF_CHECKLIST.md` (which covers WHAT to verify); this covers HOW to actually submit.

**Assumes:**

- You already have a KDP account (account, tax interview, and payout setup are skipped)
- Both PDFs are built and have passed `PROOF_CHECKLIST.md`
- You have ~45 minutes uninterrupted (KDP saves drafts but the form is long)

---

## 0. Pre-submit gates (do these BEFORE opening KDP)

These will trip you up at submission if not handled first:

### 0.1 — Spine width must match actual interior page count

KDP computes spine width as `pages × 0.002347` for color paper. If your `cover_wrap.pdf` was built against a different page count, KDP rejects the cover.

- [ ] Confirm `book/build/config.py` has `INTERIOR_PAGES` set to the **actual** page count of `interior.pdf` (not a stale value from a prior build)
- [ ] Rebuild the cover wrap if you changed it: `python book/build/build_cover.py`
- [ ] Re-verify: `book/build/out/cover_wrap.pdf` should be a single PDF whose width matches `(8.5 + 8.5 + spine + 0.25) in`

### 0.2 — Remove the dashed barcode-zone outline from the cover

The barcode safe-zone outline in `build_cover.py` is a designer aid. KDP prints whatever is in your PDF — including that outline. Comment out the outline draw call before generating the production cover.

### 0.3 — Approve `interior.pdf` against `PROOF_CHECKLIST.md`

Walk every page, every spread. KDP's previewer is good but slow; catching layout bugs locally saves a re-upload cycle.

### 0.4 — Have these ready in a scratch doc

You'll need to paste these into KDP's form fields. Drafting them in advance is faster than typing into a web form under a session timer:

- Book description (~150 words, expanded from the back-cover blurb)
- 7 keyword phrases
- 3 chosen categories
- Author/publisher name as it should appear

---

## 1. Start the new title

1. Log in at <https://kdp.amazon.com>
2. From your **Bookshelf**, click **+ Create** at the top
3. Choose **Paperback** (not Kindle eBook, not Hardcover)

You'll land on the three-step submission flow:

> **Paperback Details → Paperback Content → Paperback Rights & Pricing**

Each step has a **Save and Continue** button at the bottom. Drafts auto-save, but if your session times out mid-step you may have to re-paste a few fields — keep your scratch doc open.

---

## 2. Paperback Details (Step 1 of 3)

### Language

**English**

### Book Title

- **Title:** `Squishy Smash`
- **Subtitle:** `Meet the Squishies`

⚠️ KDP treats title and subtitle as separate fields and BOTH become searchable. "Meet the Squishies" goes in the subtitle field, NOT in the title.

### Series

- Click **Add a series**
- **Series name:** `Squishy Smash`
- **Volume number:** `1`

This sets up the franchise so future books (`Squishy Smash: Squishy Foods`, etc.) attach to the same series page on Amazon — readers who liked Vol 1 see Vol 2 as a "Next in the series" prompt automatically.

### Edition number

Leave blank (1st edition assumed).

### Author

Per the locked decision in `book/cover/cover_copy.md` §3 — using publisher only ("Squishy Smash") for now. Paste that in the Primary Author field.

If you'd rather use a personal name or pen name, enter it here. The back cover doesn't need to change either way; KDP's metadata is independent of cover art.

### Contributors

None. (Skip unless adding co-author / illustrator credit.)

### Description

Use a ~150-word version of the back-cover blurb from `book/cover/cover_copy.md`. Expand the existing 80-word blurb by adding 1–2 sentences about the three packs and what a parent will find inside.

KDP's description field accepts limited HTML: `<b>`, `<i>`, `<br>`, and `<ul><li>`. Don't bother styling for v1 — plain text reads cleanly.

### Publishing Rights

Choose: **I own the copyright and I hold the necessary publishing rights.**

### Reading Age + Grade Range

- **Ages:** 4–8
- **Grades:** Preschool–3

### Categories

KDP forces you to pick from a fixed tree (NOT free text). Click **Choose categories** and pick up to 3.

**Primary placement strategy** (per the storybook market research, May 2026 — friendship-themed character books over-index in the Friendship/Social Skills subcategory, where a Top-5K Books ranking is reachable for indie IP):

1. **Children's Books → Growing Up & Facts of Life → Friendship, Social Skills** — highest-traffic subcategory reachable for indie character IP (maps to BISAC JUV039020)
2. **Children's Books → Animals → Imaginary Creatures** — toy-adjacent parent demographic (BISAC JUV002020)
3. **Children's Books → Humorous Stories** — lower competition, high conversion for character-ensemble books

⚠️ Amazon's category tree shifts occasionally. If a path above is missing, search the picker for "Friendship," "Imaginary Creatures," and "Humor" and pick the closest match. Keep all three under **Children's Books** (not generic Fiction).

**Avoid** "Activities, Crafts & Games → Games" — this is a poor fit (the book has no game/activity content) and hurts discoverability in the character-book search lane.

### Keywords (up to 7)

Paste these one per slot:

1. `squishy characters book`
2. `kids collectible book`
3. `cute monster book`
4. `dessert characters book`
5. `kawaii kids book`
6. `creature collection book`
7. `picture book ages 4 to 8`

These were tuned for the launch audience (parents searching for character books for young kids). Don't waste a slot on the title itself — Amazon already indexes that.

### Pre-order

Pick **Release my book for sale now**. Skip pre-order — first books usually launch better with immediate availability than with a build-up period that has no email list to drive.

Click **Save and Continue**.

---

## 3. Paperback Content (Step 2 of 3)

### Print ISBN

Two paths:

- **Free KDP ISBN** *(recommended)* — Amazon assigns one. Locks the book to KDP's distribution channels; can't be used for non-Amazon sales of this exact ISBN
- **Use my own ISBN** — purchase from Bowker (~$125). Useful only if you plan to distribute the same edition through other channels

For Volume 1: **Free KDP ISBN**.

### Publication date

Leave blank — KDP fills in today's date when the book goes live.

### Print Options

- **Ink and Paper Type:** **Premium Color**
  - NOT Standard Color. Our pages have full-bleed pastels and gradients; Standard's lower DPI prints muddy on character art
- **Trim Size:** **8.5 × 8.5 in** (square)
  - May appear under **Specify your own** rather than "Most Popular Trim Sizes"
- **Bleed Settings:** **Bleed (PDF only)**
  - Our interior has full-bleed background art on every page
- **Paperback Cover Finish:** **Matte**
  - Glossy reflects under store lights and looks cheap; matte feels premium and is industry-standard for kids' character books

### Manuscript

1. Click **Upload paperback manuscript**
2. Upload `book/build/out/interior.pdf`
3. Wait for the green checkmark — KDP scans for low-res images, trim violations, and font issues. Errors appear inline with the page number

### Book Cover

1. Click **Use a cover that I already have (Print-ready cover only)**
2. Upload `book/build/out/cover_wrap.pdf`

⚠️ Confirm the dashed barcode-zone outline is removed (gate 0.2 above). KDP prints whatever is in the PDF.

### Book Preview

1. Click **Launch Previewer** — opens in a new tab; takes 2–5 minutes to process
2. Walk every page top-to-bottom in the previewer
3. Watch for:
   - Yellow warning icons on any page (click for the specific issue)
   - Cover spine alignment to KDP's auto-detected width — should match `pages × 0.002347` for our color-paper spec
   - Barcode preview lands inside our reserved bottom-right zone of the back cover
4. Click **Approve** when satisfied

⚠️ **Common previewer rejection: spine-width mismatch.** If you see this, KDP's detected page count differs from what your cover was built for. Fix in `book/build/config.py` (`INTERIOR_PAGES = <new count>`), regenerate `cover_wrap.pdf`, and re-upload only the cover.

Click **Save and Continue**.

---

## 4. Paperback Rights & Pricing (Step 3 of 3)

### Territories

**All territories (worldwide rights)**

### Pricing, Royalty, and Distribution

**Primary Marketplace:** Amazon.com (US)

**Royalty Plan:** 60% (the only paperback option — there's no 70% tier for print)

**List Price (USD) — suggested launch: `$12.99`**

KDP shows the **printing cost** below the price field (~$4.85 for our spec). Royalty per sale ≈ (price × 0.6) − printing cost.

At $12.99: ~$7.79 royalty share × 0.6 ≈ **~$4.67 per sale.**

Don't go below KDP's enforced minimum (the form blocks it). Going above $14.99 starts to feel premium for a 46-page kids' character book at thumbnail glance — savings here come from word-of-mouth, not margin.

**Other Marketplaces:** click **Set automatic prices** — KDP localizes the price for UK/DE/JP/etc. using current exchange rates. Setting them manually is more work for marginal gain on a launch title.

**Expanded Distribution (toggle):**

- **ON** — opens the book to libraries, brick-and-mortar bookstores, and online retailers (B&N, BAM, Books-A-Million). Trade-off: lower royalty per non-Amazon sale because the channel takes a cut
- **OFF** — Amazon-only, full 60% royalty on every sale

**Recommendation for launch: OFF.** Keep full margin while you build awareness. Switch to ON later if a bookstore reaches out or you want to seed library copies.

### Book Lending (Kindle MatchBook)

Doesn't apply to print-only.

### Terms & Conditions

Check the box.

### Submit

Click **Publish Your Paperback Book**.

---

## 5. Post-submit

KDP shows: *"Your book is being reviewed."* Typical review window: **24–72 hours**.

### Within the review window

- [ ] **Order an Author Proof Copy** from your Bookshelf (link appears once review starts). Cost = printing cost only (~$5 + shipping). Ship to yourself. Inspect physically:
  - Colors print warmer than screen
  - Matte ink reads slightly muted vs the PDF preview
  - Spine alignment is real, not approximated
  - Page edges may show very faint trim variation — confirm no important art sits within the safety zone
- [ ] Watch your KDP email inbox for review-rejection notes. They're specific and actionable (e.g., "page 14 image is below 300 DPI"). Fix the source PDF, re-upload, no penalty for revisions

### Once approved

- [ ] Live Amazon URL appears on your Bookshelf (`amazon.com/dp/B0XXXXXXX`)
- [ ] Update `website/` to add a "Books" page or a homepage callout — this is now real product
- [ ] Add the book to the support page FAQ ("Can I buy the book? Yes — link.")
- [ ] Cross-post the launch to `@squishy_smash` on X with a back-cover screenshot
- [ ] Claim the book in **Amazon Author Central** under your author profile (optional but adds legitimacy and lets you edit the bio shown on the listing)

---

## Common rejection reasons (and the fix)

| Rejection | Fix |
|---|---|
| Cover spine width doesn't match interior page count | Update `INTERIOR_PAGES` in `book/build/config.py`, run `python book/build/build_cover.py`, re-upload only the cover |
| Image quality below 300 DPI on page X | Identify the asset (usually a card render at `assets/cards/final_48/`); confirm source webp is full-resolution, not downsampled |
| Bleed setting mismatch | Cover should be 17.325+ × 8.75 in (with bleed); interior should be 8.75 × 8.75 in (with bleed). Both are pre-set in our config — check `INTERIOR_PAGES` first |
| Trim size outside KDP's allowed sizes | 8.5 × 8.5 is supported but lives under **Specify your own** rather than "Most Popular." Re-pick using manual entry |
| Barcode safe-area violation | Re-render `cover_wrap.pdf` and confirm nothing important (text, logo, art) sits in the lower-right 2 × 1.2 in zone of the back cover |
| Font embedding warning | ReportLab embeds Fredoka by default; if KDP flags a font, rebuild from a clean state to refresh the embed |

---

## Sequel-launch fast path

When Volume 2 is ready (`Squishy Smash: Squishy Foods`, etc.):

1. From Bookshelf → **+ Create** → **Paperback** (NOT "Add new edition" — we want a new title in the existing series, not a revision of Vol 1)
2. In Step 1 → **Add a series** → pick the existing series **Squishy Smash** → Volume **2**
3. Most metadata reuses cleanly: categories, age range, keywords, pricing, royalty, expanded-distribution choice
4. New for each volume: title, subtitle, description, cover wrap, interior PDF
5. Rebuild `interior.pdf` and `cover_wrap.pdf` for the new content; everything else can be near-cloned from this listing

---

## Reference values (single source of truth for KDP form fields)

| Field | Value |
|---|---|
| Title | Squishy Smash |
| Subtitle | Meet the Squishies |
| Series | Squishy Smash |
| Volume | 1 |
| Trim | 8.5 × 8.5 in (square) |
| Pages | (whatever `interior.pdf` actually contains — verify before submit) |
| Bleed | Yes |
| Paper | Premium Color |
| Cover finish | Matte |
| Ages | 4–8 |
| Grades | Preschool–3 |
| Language | English |
| Royalty plan | 60% |
| Suggested launch price (USD) | $12.99 |
| Expanded distribution | OFF (toggle ON later if needed) |
| ISBN | Free KDP ISBN |
| Pre-order | Release for sale now |

---

*Companion docs: `PROOF_CHECKLIST.md` (verification gates) · `cover/cover_copy.md` (cover specification) · `ELEVATION_PLAN.md` (interior layout strategy)*
