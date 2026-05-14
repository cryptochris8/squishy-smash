# KDP Submission Scratch — Squishy Smash: Meet the Squishies

*Copy-paste-ready text for the KDP paperback submission form. Keep this open in another tab while filling out KDP — the form is long, the session can time out, and re-typing into a web form under pressure is how typos land in your published listing.*

**Source of truth:**
- Voice + canonical lines: `book/STORY_BIBLE.md`
- Submission walkthrough (step-by-step click-through): `book/KDP_SUBMISSION_WALKTHROUGH.md`
- Proof checklist (what to verify before clicking submit): `book/PROOF_CHECKLIST.md`

**Two decisions you need to lock before pasting anything:** see §6.

---

## 1. Identity fields

| Field | Value | Notes |
|---|---|---|
| **Language** | English | |
| **Book Title** | `Squishy Smash` | exact case |
| **Subtitle** | `Meet the Squishies` | KDP indexes both as searchable; subtitle does NOT go in the title field |
| **Series name** | `Squishy Smash` | enables the franchise — Volume 2 / 3 will attach to the same series page |
| **Volume** | `1` | |
| **Edition** | *(leave blank — KDP assumes 1st)* | |
| **Author (Primary)** | **[DECISION PENDING]** — see §6 | |
| **Contributors** | *(none — skip)* | |

---

## 2. Description (paste into the Description field)

```
A field guide to forty-eight squishy friends from the soft, silly, sparkly world of Squishy Smash.

Long ago, the very first wobble rolled across the Squishy World — and the Squishkeeper began to write it all down. This is that book.

Meet Soft Dumpling, Goo Ball, Blushy Bun Bunny, and forty-five other squishies across three magical packs:

• SQUISHY FOODS — warm, tasty, sweet
• GOO & FIDGETS — glossy, bouncy, satisfying
• CREEPY-CUTE CREATURES — spooky-sweet magical friends

Every page is a hello. Every squishy is a feeling soft enough to hold.

Inside you'll find:
• 48 hand-illustrated character cards
• A pull-out map of the Squishy World
• A Squishy Tracker so you can mark every friend you meet
• Three legendary mythics — a dumpling that taught the stars to glow, a goo that bends gravity, and a guardian who watches over every lost squishy

A bright, collectible character book for ages 4 and up — perfect for fans of soft toys, squishy crazes, and the kind of story you read again and again.

Every pop is a hello. Every hello comes back.
```

*(KDP description field accepts limited HTML: `<b>`, `<i>`, `<br>`, `<ul><li>`. The plain-text bullets above work fine — KDP renders the `•` correctly. ~1,100 characters; KDP limit is 4,000.)*

---

## 3. Keywords (7 slots — paste one per slot)

```
1. squishy characters book
2. kids collectible book
3. cute monster book
4. dessert characters book
5. kawaii kids book
6. creature collection book
7. picture book ages 4 to 8
```

*Don't waste a slot on the title or subtitle — KDP indexes those automatically and rejects keyword overlap.*

---

## 4. Categories (pick 3 in this order)

Per the storybook market research (May 2026) — the Friendship/Social Skills subcategory is where indie character IP can reasonably reach a Top-5K Books rank.

1. **Children's Books → Growing Up & Facts of Life → Friendship, Social Skills**
   *(BISAC JUV039020 — highest-traffic reachable subcategory for indie character IP)*
2. **Children's Books → Animals → Imaginary Creatures**
   *(BISAC JUV002020 — toy-adjacent parent demographic)*
3. **Children's Books → Humorous Stories**
   *(lower competition, high conversion for character-ensemble books)*

If KDP's tree has shifted and an exact path is missing, search the picker for "Friendship," "Imaginary Creatures," and "Humor" and pick the closest match. All three must remain under **Children's Books** (not generic Fiction).

**Do NOT use** "Children's Books → Activities, Crafts & Games → Games" — wrong shelf for a character book and hurts discoverability.

---

## 5. Reading age + price

| Field | Value |
|---|---|
| **Reading Age** | 4–8 |
| **Grade Range** | Preschool–3 |
| **Trim Size** | 8.5 × 8.5 in (under "Specify your own" — NOT under "Most Popular") |
| **Bleed** | Yes — "Bleed (PDF only)" |
| **Paper** | Premium Color |
| **Cover Finish** | Matte |
| **Royalty Plan** | 60% (only paperback option) |
| **List Price (USD)** | `$12.99` (launch suggestion; min KDP enforces ~$5; $14.99 starts to feel premium) |
| **Other Marketplaces** | Set automatic prices (KDP localizes for UK/DE/JP via current FX) |
| **Expanded Distribution** | **OFF for launch** (preserve full Amazon royalty; toggle on later if a library or bookstore wants in) |
| **Pre-order** | Release for sale now |

---

## 6. Two decisions to lock before submitting

These don't block the build — they block the form. Decide each before you log into KDP.

### 6.1 Author byline

Current default (per `book/cover/cover_copy.md` §3): **"Squishy Smash"** (publisher-only, subtle).

Options:
- **A. Publisher only** — `Squishy Smash` appears as the author. Cleanest brand-as-author framing; keeps personal identity out of the public listing.
- **B. Personal name** — your real name. Standard self-pub move; useful if you want Author Central / Goodreads to attach to a personal profile.
- **C. Pen name** — neither of the above. Useful if you may write outside the Squishy Smash brand later and don't want the lines crossed.

Cover art doesn't change either way — KDP metadata is independent of the cover PDF. You can also add a credit later (KDP allows author edits post-publish).

**Locked answer: __________________________**

### 6.2 ISBN

Options:
- **A. Free KDP ISBN** *(walkthrough recommendation)* — Amazon assigns one. Locks the book to KDP's distribution channels; you can't sell this exact ISBN off-Amazon. For Volume 1, this is the lowest-friction path.
- **B. Bowker-purchased ISBN** — ~$125 for one. Useful only if you plan to distribute the same edition through IngramSpark, bookstores, or libraries under your own imprint.

Default for self-pub Volume 1 is **A. Free KDP ISBN**.

**Locked answer: __________________________**

---

## 7. Privacy + age rating questionnaire

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

Result: **4+** (matches the iOS app's rating).

---

## 8. Post-submit checklist

Once KDP shows "Your book is being reviewed":

- [ ] Order an Author Proof Copy from Bookshelf (~$5 + shipping). Ships while review runs.
- [ ] Watch your KDP inbox for any rejection notes (page-quality, trim, font embedding). Common fixes are in `KDP_SUBMISSION_WALKTHROUGH.md` §"Common rejection reasons."
- [ ] Once approved + live Amazon URL appears:
  - [ ] Add to `website/` — "Books" page or homepage callout
  - [ ] Add to support FAQ ("Can I buy the book? Yes — link.")
  - [ ] Cross-post to `@squishy_smash` on X with the back-cover screenshot
  - [ ] Claim the title in Amazon Author Central (optional but adds legitimacy)

---

*Generated 2026-05-13 from STORY_BIBLE-aligned copy. Update if the bible, walkthrough, or proof checklist drift.*
