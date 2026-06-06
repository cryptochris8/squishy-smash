# Squishy Smash — Book 2 KDP Submission Walkthrough

A step-by-step "click here, then here" guide for taking Book 2's compressed PDFs from local to a live Amazon listing. **Book 2-specific** — for Book 1 see [`KDP_SUBMISSION_WALKTHROUGH.md`](KDP_SUBMISSION_WALKTHROUGH.md).

**Companion docs:**
- [`KDP_METADATA_SCRATCH_BOOK2.md`](KDP_METADATA_SCRATCH_BOOK2.md) — copy-paste-ready Book 2 form values
- [`PROOF_CHECKLIST.md`](PROOF_CHECKLIST.md) — pre-submit page-by-page verification

**Assumes:**
- KDP account already set up (Book 1 lives at `amazon.com/dp/B0H219KX2X`)
- Both Book 2 PDFs are built and compressed (see §0.0 below)
- ~30–45 minutes uninterrupted (faster than Book 1 since most metadata is series-inherited)

---

## 0. Pre-submit gates (do these BEFORE opening KDP)

### 0.0 — File checklist (Book 2-specific paths)

Both PDFs were compressed 2026-06-01. Upload these (NOT the uncompressed masters):

| File to upload | Local path | Size |
|---|---|---|
| Interior | `book/build_book2/out/interior_compressed.pdf` | 44.9 MB |
| Cover wrap | `book/build_book2/out/cover_wrap_compressed.pdf` | 1.5 MB |

- [ ] Both files exist at the paths above
- [ ] Both PDFs open cleanly in a viewer (Acrobat / Edge / Preview)
- [ ] You have spot-checked the cover wrap visually (typography legible, no JPEG mush)

### 0.1 — Page count + spine math are already locked

Book 2 is **40 pages**. Spine width is **0.0939 in** (40 × 0.002347 for premium color). The cover wrap was built against this — DO NOT regenerate the cover without also re-checking the spine value matches.

- [ ] Confirm `interior_compressed.pdf` opens as a 40-page document (not 38, not 42)
- [ ] If you ever rebuild the cover, re-run `python book/build_book2/compress_cover.py` so the compressed version stays in sync

### 0.2 — Barcode safe zone is empty

Book 2's `build_cover.py` does not draw a barcode-zone outline (the outline was a Book-1 design-aid only — we never added it to the Book 2 builder). KDP will auto-overlay its barcode in the lower-right 2 × 1.2 in of the back cover.

- [ ] Open the back cover (left half of the wrap) and confirm the lower-right region is clear (no text, no logo, just deep indigo background)

### 0.3 — Have the metadata scratch open

Open [`KDP_METADATA_SCRATCH_BOOK2.md`](KDP_METADATA_SCRATCH_BOOK2.md) in another tab. You'll paste from it into KDP's form fields.

---

## 1. Start the new title

1. Log in at <https://kdp.amazon.com>
2. From your **Bookshelf**, click **+ Create** at the top
3. Choose **Paperback**
   - ⚠️ NOT **Hardcover** — KDP hardcover requires 75+ pages and Book 2 is 40. Hardcover for picture books goes through IngramSpark instead. Flagged as a future follow-up in [[hardcover-via-ingramspark]] memory.

You'll land on the three-step submission flow:

> **Paperback Details → Paperback Content → Paperback Rights & Pricing**

---

## 2. Paperback Details (Step 1 of 3)

### Language

**English**

### Book Title

- **Title:** `Squishy Smash`
- **Subtitle:** `The Lost Sparkle`

⚠️ The Title field MUST be `Squishy Smash` — exact case, exact spelling, no trailing space. If it differs from Book 1's Title field by even a character, the series binding silently fails and Book 2 won't appear next to Book 1 on Amazon.

### Series

- Click **Add a series** → **Add to an existing series** (NOT "Create a new series")
- Pick **Squishy Smash** from the dropdown (it was created when Book 1 went live)
- **Volume number:** `2`

If the existing series doesn't appear in the dropdown:
- KDP's series dropdown takes a few minutes to refresh after Book 1's listing was last touched
- Try refreshing the page
- Last-resort: type `Squishy Smash` into the "Create new series" field — Amazon will merge them post-publication if the title strings match exactly

### Edition number

Leave blank (1st edition assumed).

### Author

**Primary Author:** `Christopher Ryan Campbell`

Locked per [[book-byline-isbn-locked]] memory and the print byline in `book2_front_back_matter.md` §p2 (Copyright). Must match what's printed on p1 (Title page) + p2 (Copyright) + p40 (back matter).

⚠️ If Book 1's live byline on KDP differs from `Christopher Ryan Campbell`, you have two paths:
- **Accept the split** for now and republish Book 1 later to align (low priority unless the Author Central page splits visibly).
- **Republish Book 1's metadata** now to match — this is a metadata edit, not a content republish, so it's quick and doesn't trigger a new review.

### Contributors

None.

### Description

Use the HTML version from [`KDP_METADATA_SCRATCH_BOOK2.md`](KDP_METADATA_SCRATCH_BOOK2.md) §2. Paste into the Description field. KDP supports `<b>`, `<i>`, `<br>`, `<ul><li>` — the scratch doc's HTML version uses these for scannability.

### Publishing Rights

**I own the copyright and I hold the necessary publishing rights.**

### Reading Age + Grade Range

- **Ages:** 4–8
- **Grades:** Preschool–3

### Categories

Pick exactly 3, in this order (per [`KDP_METADATA_SCRATCH_BOOK2.md`](KDP_METADATA_SCRATCH_BOOK2.md) §4):

1. **Children's Books → Growing Up & Facts of Life → Friendship, Social Skills**
2. **Children's Books → Animals → Imaginary Creatures**
3. **Children's Books → Humorous Stories**

Same primary as Book 1 — series ranks compound when both volumes sit on the same primary BISAC.

### Keywords (up to 7)

Paste from [`KDP_METADATA_SCRATCH_BOOK2.md`](KDP_METADATA_SCRATCH_BOOK2.md) §3, one per slot:

1. `squishy storybook ages 4 to 8`
2. `kawaii bedtime story`
3. `kids friendship book`
4. `cute monster picture book`
5. `gentle bedtime adventure`
6. `soft picture book read aloud`
7. `kids ensemble story book`

Different from Book 1's keywords by design — the books should win different searches so they don't cannibalize each other.

### Pre-order

**Release my book for sale now.**

Click **Save and Continue**.

---

## 3. Paperback Content (Step 2 of 3)

### Print ISBN

**Use a free KDP ISBN** (matches Book 1's choice; locked per [[book-byline-isbn-locked]]).

### Publication date

Leave blank — KDP fills in today's date when the book goes live.

### Print Options

| Setting | Value | Why |
|---|---|---|
| **Ink and Paper Type** | **Premium Color** | Watercolor spread art needs the higher DPI; Standard Color prints muddy |
| **Trim Size** | **8.5 × 8.5 in** (square) | Found under **Specify your own**, NOT under "Most Popular Trim Sizes" |
| **Bleed Settings** | **Bleed (PDF only)** | Every spread is full-bleed painterly art |
| **Paperback Cover Finish** | **Matte** | Industry standard for picture books; glossy reflects under store lights |

### Manuscript

1. Click **Upload paperback manuscript**
2. Upload `book/build_book2/out/interior_compressed.pdf` (44.9 MB)
3. Wait for KDP's green checkmark — it scans for low-res images, trim violations, and font issues

⚠️ KDP **may flag** font-embedding issues for Bookmania (OpenType-CFF). The interior pipeline renders all type as PIL pixel art and embeds it as JPEG inside the PDF — no live font references in the PDF — so this should be a non-issue. If a font warning appears anyway, the warning is spurious and can be ignored (the rendered text is rasterized, not glyph-referenced).

### Book Cover

1. Click **Use a cover that I already have (Print-ready cover only)**
2. Upload `book/build_book2/out/cover_wrap_compressed.pdf` (1.5 MB)

⚠️ KDP previewer is the first place spine-width mismatches surface. If it complains, double-check that the wrap was built with `INTERIOR_PAGES = 40` (it was — confirm by looking at `build_book2/build_cover.py` line ~30). The expected wrap dimensions are 17.3439 × 8.75 in.

### Book Preview

1. Click **Launch Previewer** — opens in a new tab; 2–5 min to process
2. Walk every page:
   - **p1 title** — wordmark crispness, sparkle accent, byline visible
   - **p2 copyright** — imprint reads "Athlete Domains, LLC" (updated 2026-05-30, not "Squishy Smash, Inc.")
   - **p3 dedication** — 4-line italic centered, small sparkle below
   - **p4–p39 spreads** — every spread reads through with text legible against painting
   - **p40 back matter** — round author photo with cream vignette, bio + Spartanburg line + "Also by The Red Brick Road" italic + TikTok closing line
3. Check the cover preview:
   - Spine band is the only pink element; no text on spine
   - Front: SQUISHY SMASH wordmark + "The Lost Sparkle" italic + trio on horizon + Sparkle accent
   - Back: Sparkle vignette upper third, headline, blurb, pact italic, series footer lower-left, subdued metadata far-bottom, barcode zone clear lower-right
4. Click **Approve** when satisfied

⚠️ **Most likely rejection on Book 2**: per [[project-book-live]] precedent, Book 1 hit one rejection round. Budget the same for Book 2. Common causes flagged in §5 below.

Click **Save and Continue**.

---

## 4. Paperback Rights & Pricing (Step 3 of 3)

### Territories

**All territories (worldwide rights).**

### Pricing, Royalty, and Distribution

| Setting | Value |
|---|---|
| **Primary Marketplace** | Amazon.com (US) |
| **Royalty Plan** | **60%** (only paperback option) |
| **List Price (USD)** | **`$12.99`** (matches Book 1; per [[book2-text-system-locked]] § format) |
| **Other Marketplaces** | **Set automatic prices** |
| **Expanded Distribution** | **OFF** for launch |

Printing cost at 40-page premium color + matte ≈ $4.30. Royalty per sale at $12.99 ≈ ($12.99 × 0.6) − $4.30 ≈ **$3.49**.

If you toggle Expanded Distribution later (so the book reaches libraries / brick-and-mortar via Ingram-adjacent channels), royalty per non-Amazon sale drops by roughly half because the channel takes a cut. Worth doing later when library inquiries come in — see [[hardcover-via-ingramspark]] for the broader hardcover-via-Ingram path.

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

- [ ] **Order an Author Proof Copy** as soon as it appears on your Bookshelf. Cost = printing cost only (~$4.30 + shipping). Inspect physically:
  - Watercolor pastels print slightly warmer than screen — confirm the dusk-warm cover doesn't shift unpleasantly
  - Matte ink reads slightly muted vs the PDF — confirm body type is still comfortable to read at 18pt
  - Spine alignment — the 0.0939 in spine is thin; some manufacturing tolerance is normal
  - Round author photo on p40 — confirm the cream vignette held through print (could ghost or band on cheap stock)
- [ ] Watch your KDP email inbox for review-rejection notes. They're specific and actionable. Fix the source PDF, re-upload, no penalty.

### Once approved

- [ ] Live Amazon URL appears on your Bookshelf (`amazon.com/dp/B0XXXXXXX`)
- [ ] **Update the website's Books section** — replace the "Book Two coming soon to Amazon" placeholder in `website/src/components/Books.tsx` with the real ASIN-based URL. Add a `BOOK2_AMAZON_URL` constant to `website/src/constants/links.ts` mirroring the existing `AMAZON_BOOK_URL` (Book 1) pattern.
- [ ] **Update the YouTube read-along description** — add the Book 2 Amazon link to the "Get the Book" section
- [ ] **Update the TikTok teaser bio link** — point @CryptoChris8 bio to the Amazon URL
- [ ] **Claim the book in Amazon Author Central** — same author profile as Book 1; this lets the bio shown on the listing pull from Author Central

---

## 6. Common rejection reasons (and the fix)

| Rejection | Likely cause for Book 2 | Fix |
|---|---|---|
| Cover spine width doesn't match interior page count | Cover was built when `INTERIOR_PAGES` was set to a value other than 40 | Confirm `build_book2/build_cover.py` line ~30 reads `INTERIOR_PAGES = 40`, rebuild via `python build_cover.py && python compress_cover.py`, re-upload cover only |
| Image quality below 300 DPI | A spread PNG was rendered at lower res by accident | Confirm `out/pages/page_NN.png` is 2625×2625 pixels (not smaller); rerun the spread renderer if needed |
| Bleed setting mismatch | Wrong "Bleed" toggle picked on the form | Re-pick **Bleed (PDF only)** in §3 Print Options |
| Trim size outside KDP's allowed sizes | "Most Popular" tab doesn't show 8.5 × 8.5 | Switch to **Specify your own** and enter 8.5 / 8.5 manually |
| Barcode safe-area violation | Something in the lower-right back cover landed in the 2 × 1.2 in zone | Open `cover_wrap_compressed.pdf` and confirm lower-right is empty deep-indigo |
| Font embedding warning | Spurious — our PDFs have rasterized text only | Likely safe to ignore. If KDP blocks, regenerate `interior_compressed.pdf` from a fresh shell |
| Title text on cover doesn't match metadata | KDP cross-checks "SQUISHY SMASH" against the Title field | Confirm Title is exactly `Squishy Smash` (capitalization in metadata is fine differing from cover's all-caps wordmark) |

---

## 7. Differences from Book 1's submission

These are the Book 2-specific deltas. Everything else matches Book 1.

| Aspect | Book 1 | Book 2 |
|---|---|---|
| Subtitle | Meet the Squishies | The Lost Sparkle |
| Page count | 46 | 40 |
| Spine width | 0.108 in | 0.0939 in |
| Cover wrap width | 17.341 in | 17.3439 in |
| Volume | 1 | 2 |
| ISBN | KDP-assigned | KDP-assigned |
| Imprint on copyright page | Squishy Smash, Inc. | **Athlete Domains, LLC** *(updated 2026-05-30)* |
| Byline | `Christopher Ryan Campbell` | `Christopher Ryan Campbell` (locked, same) |
| Categories | Friendship / Imaginary Creatures / Humor | Friendship / Imaginary Creatures / Humor (same — series rank compound) |
| Build script | `book/build/build_interior.py` + `build_cover.py` | `book/build_book2/build_interior.py` + `build_cover.py` |
| Compressed file paths | `book/build/out/*_compressed.pdf` | `book/build_book2/out/*_compressed.pdf` |

---

## 8. Reference values (single source of truth for KDP form fields)

| Field | Value |
|---|---|
| Title | Squishy Smash |
| Subtitle | The Lost Sparkle |
| Series | Squishy Smash |
| Volume | 2 |
| Author (Primary) | Christopher Ryan Campbell |
| Language | English |
| Pages | 40 |
| Trim | 8.5 × 8.5 in (Specify your own) |
| Bleed | Yes — Bleed (PDF only) |
| Paper | Premium Color |
| Cover finish | Matte |
| Ages | 4–8 |
| Grades | Preschool–3 |
| Royalty plan | 60% |
| Suggested launch price (USD) | $12.99 |
| Expanded distribution | OFF (toggle ON later if needed) |
| ISBN | Free KDP ISBN |
| Pre-order | Release for sale now |
| Categories | Friendship/Social Skills · Imaginary Creatures · Humorous Stories |
| Spine width | 0.0939 in (40 × 0.002347) |
| Cover wrap dimensions | 17.3439 × 8.75 in |
| Interior file | `book/build_book2/out/interior_compressed.pdf` (44.9 MB) |
| Cover file | `book/build_book2/out/cover_wrap_compressed.pdf` (1.5 MB) |

---

## 9. Post-launch follow-ups (tracked in memory)

- **Update website's Books section** with real Amazon URL (placeholder currently reads "Book Two coming soon to Amazon")
- **Update YouTube read-along description** with Book 2 Amazon link
- **Update TikTok @CryptoChris8 bio link**
- **Consider IngramSpark hardcover** — flagged in [[hardcover-via-ingramspark]] memory. Triggers: library inquiries, paperback >100 sales, Q4 gift season, or Book 3 launch bundling.
- **Build-in-public Substack arc** — flagged in [[book2-build-in-public-strategy]] memory. Trigger: paperback live + 2-3 weeks of organic data.

---

*Drafted 2026-06-01. Source of truth: this session's compressed-PDF outputs. Future sequel walkthroughs (Book 3+) should fork from this doc, not from Book 1's.*
