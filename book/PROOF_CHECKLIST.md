# Squishy Smash — KDP Proof + Upload Checklist

A pass/fail checklist for taking the generated `interior.pdf` + `cover_wrap.pdf` from "draft proof" to "click submit" inside KDP. Work it top to bottom; do not skip ahead.

---

## 0. Before you open KDP

- [ ] Latest build is fresh: `python book/build/test_build.py` runs green
- [ ] Both PDFs exist at `book/build/out/`
- [ ] You have a quiet 30-min window — KDP's previewer takes time to load and you don't want to rush past a wonky page

---

## 1. Interior PDF — page-flip review

Open `interior.pdf` and confirm each page reads as expected. Walk it in spread pairs (5–6 together, 7–8 together, etc.):

- [ ] **Page 1** — half-title shows "SQUISHY SMASH" centered on dark background, no leakage off the page
- [ ] **Page 2** — solid brand color, no stray text
- [ ] **Page 3** — title page: "SQUISHY / SMASH / Meet the Squishies / A Character Adventure Book" + 3-mascot cluster (Soft Dumpling 001, Goo Ball 017, Blushy Bun Bunny 033)
- [ ] **Page 4** — copyright text legible, brand bunny icon visible bottom-right
- [ ] **Pages 5–6** — Welcome spread: headline left, three-color "sweet/gooey/spooky-cute" block right
- [ ] **Pages 7–8** — three pack panels stacked, each with three card thumbnails + tinted background
- [ ] **Pages 9–10** — Squishy Foods intro: text left, character collage right
- [ ] **Pages 11–12** — Soft Dumpling hero (with flavor line) + Jelly Bun & Peach Mochi
- [ ] **Pages 13–14** — Syrup Cube + Cream Puff + Rice Ball Squish hero (with flavor line)
- [ ] **Pages 15–16** — Marshmallow Puff + Pudding Pop + Strawberry Dumpling + Rainbow Jelly Bun
- [ ] **Pages 17–18** — Foods premium: Sparkle Mochi + Golden Syrup Cube + Galaxy Dumpling | Crystal Mochi + Neon Dessert Blob + Celestial Dumpling Core ✴
- [ ] **Pages 19–20** — Goo & Fidgets intro
- [ ] **Pages 21–22** — Goo Ball + Bubble Blob | Stretch Cube + Soft Stress Orb
- [ ] **Pages 23–24** — Jelly Pad + Sticky Pop Ball | Wobble Drop + Squish Capsule
- [ ] **Pages 25–26** — Goo premium: 4-up | 4-up (Singularity Goo Core ✴ at end)
- [ ] **Pages 27–28** — Creepy-Cute Creatures intro
- [ ] **Pages 29–30** — 8 creatures across 4-up | 4-up
- [ ] **Pages 31–32** — Creature finale: 4-up | 4-up (Mythic Plush Familiar ✴ at end)

For each page:

- [ ] Important art and text sit *inside* the trim line (no critical content within ~3/8 in of the page edge — that's the safety zone)
- [ ] No card image is squashed, stretched, or cropped weirdly
- [ ] Character names match the card art
- [ ] No placeholder "[missing]" boxes — every card asset rendered

If anything's wrong: edit `book/build/config.py` (text changes) or `book/build/build_interior.py` (layout changes), re-run `python book/build/test_build.py`.

---

## 2. Cover wrap — print-side review

Open `cover_wrap.pdf`:

- [ ] Reads left-to-right as **back cover → spine → front cover** (back is on the LEFT)
- [ ] Front cover wordmark (SQUISHY pink / SMASH cream) is centered and readable
- [ ] 3-mascot cluster appears across the lower front cover, evenly spaced
- [ ] Back cover headline and 80-word blurb are legible
- [ ] Three pack callouts each show: tinted panel + card thumbnail + pack name + short blurb
- [ ] "Ages 4 and up — squishysmash.com — © 2026" footer is present
- [ ] **Dashed barcode safe zone** is visible at lower-right of back cover. KDP will overlay the real barcode here. Confirm nothing important sits inside that box.
- [ ] Spine is a thin pink band, no text (correct — 32 pages is too thin for spine print)
- [ ] Total cover width is 17.325 in, height 8.75 in (printed at the bottom of the test output)

⚠️ **Before final upload:** comment out the dashed barcode outline in `build_cover.py` (`draw_back_cover` function, near `# Barcode safe zone — visible outline ONLY in this draft proof`). The outline is a designer aid; KDP will still print it if it's there.

---

## 3. KDP previewer pass

After uploading both PDFs to KDP, the previewer is the source of truth. Walk every page in the previewer:

- [ ] No "low resolution" warnings on any image
- [ ] No "text outside trim" or "content in unsafe area" warnings
- [ ] Spread pairs read as designed (left page faces correct right page — KDP may flip page 1 to the right side)
- [ ] Cover wrap snaps to KDP's spine width (KDP will reject if spine width ≠ `pages × 0.002347`; we've set 0.075 in for 32 color pages)
- [ ] Cover barcode preview lands inside our reserved safe zone (lower-right back cover)

If KDP flags page 1 as starting on the wrong side: that's because KDP forces page 1 onto the right (recto). Insert a blank page before page 1 in the manuscript, or accept the shift — the reading order won't change.

---

## 4. Metadata + listing inputs

KDP also needs:

- [ ] **Title:** Squishy Smash: Meet the Squishies
- [ ] **Subtitle:** A Character Adventure Book
- [ ] **Series:** Squishy Smash (Book One) — opt in if you want to seed sequels
- [ ] **Author:** [TBD — confirm whether to use a personal name or "Squishy Smash"]
- [ ] **Description:** ~150-word back-cover blurb (reuse the back cover body + headline)
- [ ] **Keywords (7 max):** suggestions — `squishy characters book`, `kids collectible book`, `cute monster book`, `dessert characters`, `kawaii book for kids`, `creature character book`, `picture book ages 4-8`
- [ ] **Categories (3 max):** Children's Picture Books > Animals > Imaginary Creatures, Children's Books > Activities & Games > Collectibles, Children's Books > Humor
- [ ] **Age range:** 4–8
- [ ] **Grade range:** Preschool–3
- [ ] **Language:** English
- [ ] **Print ISBN:** select "Get a free KDP ISBN" unless you've purchased one separately
- [ ] **Publication date:** today (KDP defaults to first published date)

---

## 5. Pricing + royalty

- [ ] **Print royalty plan:** 60% (the only plan KDP offers for paperback)
- [ ] **List price:** $9.99–$14.99 USD is typical for an 8.5 × 8.5 in 32-page color paperback
- [ ] **Minimum price (printing cost):** KDP shows this in the pricing step — keep $1+ above it
- [ ] **Expanded distribution:** ON if you want libraries + bookstores to be able to order, OFF if you want max royalty per sale (Amazon-only)

---

## 6. After submitting

- [ ] Order an author proof copy ($printing cost only) and physically inspect before announcing
- [ ] Update `website/` to add a "Books" page or callout once the live Amazon URL exists
- [ ] Add the book to the support page FAQ ("Can I buy the book? Yes — link.")
- [ ] Cross-post the launch to @squishy_smash on X with a back cover screenshot

---

## Open decisions still pending

These don't block the proof step but should be locked before final upload:

1. **Author byline** — personal name or "Squishy Smash" only?
2. **ISBN** — KDP free vs purchased?
3. **Title page mascot** — confirm the 3-mascot cluster (alternative: single Soft Dumpling hero)
4. **Background mode** — current dark `#120B17` matches in-app; light pastel variant possible
5. **Section dividers** — currently the pack-intro spreads (9–10, 19–20, 27–28) act as dividers. Stronger separation = trim one premium card per pack to budget a dedicated divider page.
