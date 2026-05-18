# Squishy Smash — KDP Proof + Upload Checklist

A pass/fail checklist for taking the generated `interior.pdf` + `cover_wrap.pdf` from "draft proof" to "click submit" inside KDP. Work it top to bottom; do not skip ahead.

---

## 0. Before you open KDP

- [ ] Latest build is fresh: `python book/build/test_build.py` runs green
- [ ] Both PDFs exist at `book/build/out/`
- [ ] You have a quiet 30-min window — KDP's previewer takes time to load and you don't want to rush past a wonky page

---

## 1. Interior PDF — page-flip review

Open `interior.pdf` and confirm each page reads as expected. Source of truth for the sequence is `book/build/build_interior.py:PAGE_RENDERERS` (46 pages, Phase-4 every-character expansion).

**Front matter (pages 1–6):**

- [ ] **Page 1 (T1_title)** — title page: "SQUISHY SMASH / Meet the Squishies" wordmark on dark `#120B17` starfield. Tagline + mascot composition matches `cover/cover_copy.md`.
- [ ] **Page 2 (T2_imprint)** — copyright + imprint text legible, brand bunny icon visible
- [ ] **Page 3 (T3_narrator)** — Squishkeeper letter; flavor sign-off "— the Squishkeeper" reads correctly aligned
- [ ] **Page 4 (T_map)** — pack-world map; all three pack regions visible and labeled
- [ ] **Page 5 (T4_pack_index_left)** — pack index left half (Squishy Foods listing)
- [ ] **Page 6 (T4_pack_index_right)** — pack index right half (Goo & Fidgets + Creepy-Cute Creatures listing)

**Squishy Foods (pages 7–19, 13 pages, 16 characters):**

- [ ] **Page 7 (T5_pack_portal)** — Squishy Foods portal page
- [ ] **Page 8 (T6_pack_scene)** — Squishy Foods scene/establishing spread
- [ ] **Pages 9–13 (T8_featured solos)** — Soft Dumpling, Jelly Bun, Peach Mochi, Cream Puff, Rice Ball Squish — one per page, on parchment plate
- [ ] **Pages 14–18 (T9_premium_duo)** — Syrup Cube + Marshmallow Puff | Pudding Pop + Strawberry Dumpling | Rainbow Jelly Bun + Sparkle Mochi (mid-pack note "Halfway through the Pudding Hills") | Golden Syrup Cube + Galaxy Dumpling | Crystal Mochi + Neon Dessert Blob
- [ ] **Page 19 (T10_mythic_finale)** — Celestial Dumpling Core ✴ — gold halo, velvet background, vignette present

**Goo & Fidgets (pages 20–32, 13 pages, 16 characters):**

- [ ] **Page 20 (T5_pack_portal)** — Goo & Fidgets portal
- [ ] **Page 21 (T6_pack_scene)** — Goo & Fidgets scene
- [ ] **Pages 22–26 (T8_featured solos)** — Goo Ball, Bubble Blob, Stretch Cube, Soft Stress Orb, Jelly Pad
- [ ] **Pages 27–31 (T9_premium_duo)** — Sticky Pop Ball + Wobble Drop | Squish Capsule + Glitter Goo Ball | Shockwave Blob + Frost Gel Cube (mid-pack note "Halfway down the Goo Coast") | Prism Stress Orb + Plasma Goo Ball | Aurora Stretch Cube + Cosmic Jelly Pad
- [ ] **Page 32 (T10_mythic_finale)** — Singularity Goo Core ✴

**Creepy-Cute Creatures (pages 33–45, 13 pages, 16 characters):**

- [ ] **Page 33 (T5_pack_portal)** — Creepy-Cute Creatures portal
- [ ] **Page 34 (T6_pack_scene)** — Creepy-Cute Creatures scene
- [ ] **Pages 35–39 (T8_featured solos)** — Blushy Bun Bunny, Squish Bat, Puff Ghost, Sleepy Slime Pet, Wobble Kitty
- [ ] **Pages 40–44 (T9_premium_duo)** — Tiny Blob Monster + Soft Fang Critter | Round Eared Creature + Star-Eyed Bunny | Moon Bat Blob + Glow Ghost Puff (mid-pack note "Halfway through Moonlit Hollow") | Candy Fang Creature + Dream Eater Squish | Arcane Wobble Kitty + Phantom Jelly Beast
- [ ] **Page 45 (T10_mythic_finale)** — Mythic Plush Familiar ✴

**Back matter (page 46):**

- [ ] **Page 46 (T_tracker)** — Squishy Tracker checklist; all 48 character slots present

**Per-page checks (apply to every page):**

- [ ] Important art and text sit *inside* the trim line (no critical content within ~3/8 in of the page edge — that's the safety zone)
- [ ] No card image is squashed, stretched, or cropped weirdly
- [ ] Character names match the card art
- [ ] No placeholder "[missing]" boxes — every card asset rendered
- [ ] Page-number folio is visible and consistent corner-to-corner

If anything's wrong: edit `book/build/config.py` (text changes) or `book/build/page_templates.py` / `build_interior.py` (layout changes), re-run `python book/build/test_build.py`.

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
- [ ] Spine is a thin pink band, no text (correct — 46 pages is still under KDP's ~80-page threshold for spine text)
- [ ] Total cover width is ~17.358 in (8.5 + 0.108 + 8.5 + 0.25), height 8.75 in (printed at the bottom of the test output)

⚠️ **Before final upload:** comment out the dashed barcode outline in `build_cover.py` (`draw_back_cover` function, near `# Barcode safe zone — visible outline ONLY in this draft proof`). The outline is a designer aid; KDP will still print it if it's there.

---

## 3. KDP previewer pass

After uploading both PDFs to KDP, the previewer is the source of truth. Walk every page in the previewer:

- [ ] No "low resolution" warnings on any image
- [ ] No "text outside trim" or "content in unsafe area" warnings
- [ ] Spread pairs read as designed (left page faces correct right page — KDP may flip page 1 to the right side)
- [ ] Cover wrap snaps to KDP's spine width (KDP will reject if spine width ≠ `pages × 0.002347`; we've set ~0.108 in for 46 color pages, computed live in `book/build/config.py:SPINE_W_IN`)
- [ ] Cover barcode preview lands inside our reserved safe zone (lower-right back cover)

If KDP flags page 1 as starting on the wrong side: that's because KDP forces page 1 onto the right (recto). Insert a blank page before page 1 in the manuscript, or accept the shift — the reading order won't change.

---

## 4. Metadata + listing inputs

KDP also needs:

- [ ] **Title:** Squishy Smash: Meet the Squishies
- [ ] **Subtitle:** Meet the Squishies
- [ ] **Series:** Squishy Smash (Book One) — opt in if you want to seed sequels
- [ ] **Author:** [TBD — confirm whether to use a personal name or "Squishy Smash"]
- [ ] **Description:** ~150-word back-cover blurb (reuse the back cover body + headline)
- [ ] **Keywords (7 max):** suggestions — `squishy characters book`, `kids collectible book`, `cute monster book`, `dessert characters`, `kawaii book for kids`, `creature character book`, `picture book ages 4-8`
- [ ] **Categories (3 max):** Children's Books > Growing Up & Facts of Life > Friendship/Social Skills, Children's Books > Animals > Imaginary Creatures, Children's Books > Humorous Stories
- [ ] **Age range:** 4–8
- [ ] **Grade range:** Preschool–3
- [ ] **Language:** English
- [ ] **Print ISBN:** select "Get a free KDP ISBN" unless you've purchased one separately
- [ ] **Publication date:** today (KDP defaults to first published date)

---

## 5. Pricing + royalty

- [ ] **Print royalty plan:** 60% (the only plan KDP offers for paperback)
- [ ] **List price:** $9.99–$14.99 USD is typical for an 8.5 × 8.5 in 46-page color paperback
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

These are the only remaining decisions before final upload. Everything else has been locked.

1. **Author byline** — personal name or "Squishy Smash" only? (Current default per `cover/cover_copy.md` §3: publisher-only "Squishy Smash". Personal name can be added later; KDP metadata is independent of cover art so this only blocks the KDP form, not the cover PDF.)
2. **ISBN** — KDP free vs purchased? (Walkthrough recommends free KDP ISBN for Volume 1. Buy a Bowker ISBN only if you plan to distribute the same edition off-Amazon.)

### Resolved (no longer pending)

- ✅ **Title page mascot** — 3-mascot cluster (Soft Dumpling / Goo Ball / Blushy Bun Bunny) is locked. Front cover mirrors the interior title page composition per `cover/cover_copy.md` §4.
- ✅ **Background mode** — dark `#120B17` starry-night locked across cover + interior per `cover/cover_copy.md` §4.
- ⏸ **Section dividers** — current pack-intro spreads (T5 + T6) act as dividers. Adding dedicated divider pages would require trimming a premium card per pack. Parked as a v1.1 elevation; not a v1 blocker.
