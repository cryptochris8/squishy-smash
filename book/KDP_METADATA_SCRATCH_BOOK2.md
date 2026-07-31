# KDP Submission Scratch — Squishy Smash: The Lost Sparkle (Volume 2)

*Copy-paste-ready text for the KDP paperback submission form. Keep this open in another tab while filling out KDP. Mirror of [`KDP_METADATA_SCRATCH.md`](KDP_METADATA_SCRATCH.md) — same shape, Book-2-specific values.*

**Source of truth:**
- Locked decisions: byline + ISBN per the `book-byline-isbn-locked` memory (no `[DECISION PENDING]` placeholders this round).
- Concept lock: [`BOOK2_CONCEPT_DRAFT.md`](BOOK2_CONCEPT_DRAFT.md) (story spine, format, voice rules).
- Voice + canonical lines: [`STORY_BIBLE.md`](STORY_BIBLE.md).
- Manuscript: [`manuscript/book2_manuscript_draft.md`](manuscript/book2_manuscript_draft.md).
- Submission walkthrough (same steps as Book 1): [`KDP_SUBMISSION_WALKTHROUGH.md`](KDP_SUBMISSION_WALKTHROUGH.md). Treat this run as a *Volume 2 in an existing series*, NOT a first-submission — the Series field is the key new piece of data and binds Book 2 to Book 1's series page on Amazon.

---

## 1. Identity fields

| Field | Value | Notes |
|---|---|---|
| **Language** | English | |
| **Book Title** | `Squishy Smash` | exact case — MUST match Book 1's Title field exactly or the series won't bind |
| **Subtitle** | `The Lost Sparkle` | KDP indexes both as searchable; the differentiator from Book 1 is here |
| **Series name** | `Squishy Smash` | exact match to Book 1's Series field. This is what attaches Vol 2 to the series page on Amazon. |
| **Volume** | `2` | |
| **Edition** | *(leave blank — KDP assumes 1st)* | |
| **Author (Primary)** | `Christopher Ryan Campbell` | locked per memory `book-byline-isbn-locked` |
| **Contributors** | *(none — skip)* | |

---

## 2. Description (paste into the Description field)

> **REVISED 2026-07-31 (ads prerequisite — the live listing still has the OLD copy; re-paste both versions below into KDP):** removed the "hand-illustrated" claim (no production-method claims anywhere — compliance + venue-safety), added trim size + explicit "(ages 4-8)", softened two overclaims ("by month three", "every single time"). See `docs/marketing/amazon_ads_launch_plan.md` §2.

**Strategy:** Different from Book 1's. Book 1 was a character catalog, so its description was a feature list (48 cards, map, tracker, checklist). Book 2 is a *narrative storybook* — the description has to read like a story tease, not a spec sheet. Lead with the story hook, deliver the read-aloud promise (EVERYBODY SQUISH! is the central kid moment), reassure the parent (gentle, no villain, soft landing, repeatable), close with the universe context for buyers who own Book 1.

### Plain-text reading version (~290 words / ~1,850 chars)

```
A bedtime story for kids who love squishies, soft adventures, and the kind of book they ask you to read again. And again. And again.

When the Sparkle that holds the world together flickers and splits into three glowing shards, three little squishies — one from each of the three magical packs — must cross borders for the very first time and bring it back together.

Soft Dumpling from Pudding Hills.
Goo Ball from Goo Coast.
Blushy Bun Bunny from Moonlit Hollow.

None of them have ever left home. None of them have ever met. And the only way to save the Sparkle is to find each other first.

Inside this 40-page, 8.5 x 8.5 paperback (ages 4-8):

• A complete read-aloud story across 18 full-color picture-book spreads
• A built-in shout-along moment — "EVERYBODY SQUISH!" — for kids who like to join in
• A soft, predictable bedtime ending, the kind you'll soon know by heart
• Cameo appearances from over a dozen Squishy Smash characters

Why kids ask for it again: it's a real adventure with a Big Pop in the middle. The pages get bigger, then quieter, then bigger again — the rhythm a good read-aloud is supposed to have.

Why parents pick it up: no villain, no scary beats, no rage-bait. Just three small friends being brave together, and a closing line that lands gently.

This is Book 2 in the Squishy Smash series. Book 1 — Meet the Squishies — is the character field guide; Book 2 is their first story.

Every pop is a hello. Every hello comes back.

— The Squishkeeper
```

### HTML version (paste this one into the KDP Description field)

KDP's description field accepts `<b>`, `<i>`, `<br>`, `<ul><li>`. Bold + bullets dramatically improve scannability.

```html
<b>A bedtime story for kids who love squishies, soft adventures, and the kind of book they ask you to read again. And again. And again.</b>
<br><br>
When the Sparkle that holds the world together flickers and splits into three glowing shards, three little squishies — one from each of the three magical packs — must cross borders for the very first time and bring it back together.
<br><br>
<b>Soft Dumpling</b> from Pudding Hills.<br>
<b>Goo Ball</b> from Goo Coast.<br>
<b>Blushy Bun Bunny</b> from Moonlit Hollow.
<br><br>
None of them have ever left home. None of them have ever met. And the only way to save the Sparkle is to find each other first.
<br><br>
<b>Inside this 40-page, 8.5 x 8.5 paperback (ages 4-8):</b>
<ul>
<li>A complete read-aloud story across 18 full-color picture-book spreads</li>
<li>A built-in shout-along moment — <b>"EVERYBODY SQUISH!"</b> — for kids who like to join in</li>
<li>A soft, predictable bedtime ending, the kind you'll soon know by heart</li>
<li>Cameo appearances from over a dozen Squishy Smash characters</li>
</ul>
<b>Why kids ask for it again:</b> it's a real adventure with a Big Pop in the middle. The pages get bigger, then quieter, then bigger again — the rhythm a good read-aloud is supposed to have.
<br><br>
<b>Why parents pick it up:</b> no villain, no scary beats, no rage-bait. Just three small friends being brave together, and a closing line that lands gently.
<br><br>
This is <b>Book 2</b> in the Squishy Smash series. Book 1 — <i>Meet the Squishies</i> — is the character field guide; Book 2 is their first story.
<br><br>
<i>Every pop is a hello. Every hello comes back.</i>
<br>
— The Squishkeeper
```

### Promotional text (170 char limit)

```
The Sparkle has flickered. Three brave little squishies must find each other to bring it back. A read-aloud bedtime adventure for ages 4–8.
```

*(141 chars. KDP allows you to edit this WITHOUT re-review — swap in seasonal copy whenever useful.)*

---

## 3. Keywords (7 slots — paste one per slot)

```
1. squishy storybook ages 4 to 8
2. kawaii bedtime story
3. kids friendship book
4. cute monster picture book
5. gentle bedtime adventure
6. soft picture book read aloud
7. kids ensemble story book
```

*Don't waste a slot on the title, subtitle, or series name — KDP indexes those automatically. Don't reuse Book 1's keywords verbatim; the books should win different searches so they don't cannibalize each other on a single keyword.*

---

## 4. Categories (pick 3 in this order)

Per `BOOK2_CONCEPT_DRAFT.md` §KDP positioning — same primary as Book 1 (the series brand is strongest in Friendship/Social Skills) but the secondaries lean into the storybook angle:

1. **Children's Books → Growing Up & Facts of Life → Friendship, Social Skills**
   *(BISAC JUV039020 — same primary as Book 1; series ranks compound here)*
2. **Children's Books → Animals → Imaginary Creatures**
   *(BISAC JUV002020 — toy-adjacent parent demographic)*
3. **Children's Books → Humorous Stories**
   *(lower competition, high conversion for read-aloud picture books)*

If KDP's tree has shifted and an exact path is missing, search the picker for "Friendship," "Imaginary Creatures," and "Humor" and pick the closest match. All three must remain under **Children's Books** (not generic Fiction).

**Do NOT use** "Children's Books → Activities, Crafts & Games → Games" — wrong shelf for a storybook and hurts discoverability.

---

## 5. Reading age + price + paperback specs

| Field | Value |
|---|---|
| **Reading Age** | 4–8 |
| **Grade Range** | Preschool–3 |
| **Trim Size** | 8.5 × 8.5 in (under "Specify your own" — NOT under "Most Popular") |
| **Bleed** | Yes — "Bleed (PDF only)" |
| **Paper** | Premium Color |
| **Cover Finish** | Matte |
| **Page Count** | 40 |
| **Royalty Plan** | 60% (only paperback option) |
| **List Price (USD)** | `$12.99` (per `BOOK2_CONCEPT_DRAFT.md` §Format & price — matches Book 1's $12.99) |
| **Other Marketplaces** | Set automatic prices (KDP localizes for UK/DE/JP via current FX) |
| **Expanded Distribution** | **OFF for launch** (preserve full Amazon royalty; toggle on later if a library or bookstore wants in) |
| **Pre-order** | Release for sale now |

**Page count math:** Page 1 title (recto), Page 2 copyright (verso), Page 3 dedication (recto), Pages 4–39 = 18 spreads (verso-recto pairs), Page 40 back matter (verso). Total = 40.

**Spine width:** 40 × 0.002347 = **0.0939 in** (vs Book 1's 0.108). Cover wrap width = 8.5 + 0.0939 + 8.5 + 0.25 = **17.344 in**. Computed live in `book/build/config.py` once `INTERIOR_PAGES` is updated to 40 (currently 46 for Book 1 — must be parameterized or forked for Book 2; see KDP packaging task).

---

## 6. Locked decisions (no [DECISION PENDING] this round)

### 6.1 Author byline → **`Christopher Ryan Campbell`**

Locked 2026-05-25. Memory `book-byline-isbn-locked` is the canonical source. Use this exact spelling on:
- KDP Author (Primary) field
- Copyright page (`© 2026 Christopher Ryan Campbell. All rights reserved.`)
- Back-matter author bio

If Book 1's live byline differs (Book 1's metadata scratch never recorded the actual choice), a one-edit republish of Book 1 to align the bylines is an option — discuss separately if the series fails to bind on Amazon.

### 6.2 ISBN → **Free KDP ISBN**

Locked 2026-05-25. Amazon assigns. Same path as Book 1.

---

## 7. Privacy + age rating questionnaire (same as Book 1 — Book 2 is gentler if anything)

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Gambling and Contests | None |
| Unrestricted Web Access | No |
| User Generated Content | No |

Result: **4+**.

---

## 8. Pre-submit gut-check (Volume-2-specific)

Beyond the standard `PROOF_CHECKLIST.md` items, verify before clicking submit:

- [ ] **Title + Series fields exactly match Book 1.** If `Squishy Smash` differs by even a trailing space or case, Amazon will create a separate series page and Book 2 won't appear alongside Book 1.
- [ ] **The byline field exactly matches what's intended for the long-term series byline.** Mixing `Christopher Ryan Campbell` with `Squishy Smash` across volumes splits the Author Central page.
- [ ] **Page count in pubspec matches the interior PDF's actual page count.** KDP rejects on mismatch.
- [ ] **Description doesn't oversell Book 1's mechanics** (no "48 cards" claims — that's Book 1's feature, this is the storybook).
- [ ] **Expect 1 KDP rejection round** per [`project-book-live`] memory. Book 1 hit one; budget for it on Book 2 too.

---

## Why this differs from Book 1's scratch doc

Book 1's `KDP_METADATA_SCRATCH.md` was a *first-submission* template — it included options for unset decisions (byline A/B/C, ISBN A/B), a strategy explainer for the description differing from the back cover, etc. Book 2's scratch is a *second-volume-in-series* template: most decisions are already locked, the metadata shape is established, and the new variables are story-specific copy + the Series binding fields. Keep this asymmetry — future Volume 3 should fork off Book 2's scratch, not Book 1's.
