# Book 2 — Front + Back Matter

*Drafted 2026-05-30. Captures the prose for the 4 non-spread pages of the 40-page interior: Title (p1), Copyright (p2), Dedication (p3), Back matter (p40). Layout notes are for the interior PDF build pipeline ([Task #6]).*

**Voice rule:** these pages are in the **human author's voice**, not the Squishkeeper's. The Squishkeeper closes the book at Spread 18 (p39) — the back matter is functional, not narrative. Italic should be used sparingly here; reserve it for the dedication.

**Type system** (per [`book2-text-system-locked`] memory + [`cover_copy_book2.md`] §5):
- Display: **Bookmania Black** (Adobe Fonts) — for SQUISHY SMASH wordmark on title page
- Italic display: **EB Garamond Italic** — for "The Lost Sparkle" volume tag
- Body: **Sorts Mill Goudy** (Google Fonts, free) — copyright, dedication, back matter
- Small caps: **EB Garamond Caps** — byline, headers

---

## Page 1 — Title (recto)

Quieter version of the cover front. Centered, generous vertical breathing room. No full hero art — just the wordmark + a small painted Sparkle accent.

**Layout:**
- Background: solid cream (`#F5E9D0`) — matches the cover cream so it bridges from the cover into the interior
- Vertical centering: title block at ~40% from top, byline at ~70%, imprint at ~88%
- Small painted Sparkle ornament at ~25% from top — extracted from the back-cover vignette as a small spot

**Text:**

```
[small painted Sparkle, ~0.6 in tall, centered]


SQUISHY SMASH

[Bookmania Black, ~50% of cover wordmark size,
 same warm cream palette but on cream background — switch
 to deep palette-brown ink #4A2D24 so it reads on cream]


The Lost Sparkle

[EB Garamond Italic, dusty gold #E4C46C scaled down ~50% from cover]


Christopher Ryan Campbell

[EB Garamond small caps, letter-spaced 50 units,
 deep palette-brown #4A2D24]


[Imprint line at bottom, smaller still]
Athlete Domains, LLC
```

**Notes for the build pipeline:**
- Title typography on cream background needs to switch from cream → deep palette-brown ink (`#4A2D24`) so the wordmark reads. Cover wordmark uses cream-on-indigo; title page uses ink-on-cream. Same letterforms, inverted contrast.
- The small painted Sparkle can be cropped from `book/cover/book2_back_vignette_LOCKED_print.png` — take the central ~25% × 25% region, alpha-key the dark background, you get a transparent Sparkle ornament.

---

## Page 2 — Copyright (verso)

Standard picture-book copyright page. Sparse, functional, tasteful.

**Layout:**
- Background: cream (`#F5E9D0`)
- Top-left aligned text, sitting in the upper-left third of the page
- Sorts Mill Goudy body at 9pt / 13pt leading
- Color: deep palette-brown `#4A2D24` at 100% opacity

**Text:**

```
SQUISHY SMASH: The Lost Sparkle
Book Two in the Squishy Smash series

Copyright © 2026 Christopher Ryan Campbell.
All rights reserved.

No part of this book may be reproduced or transmitted in any form or by any means, electronic or mechanical, including photocopying, recording, or by any information storage and retrieval system, without written permission from the publisher, except for brief quotations in a review.

This is a work of fiction. All characters, places, and events are products of the author's imagination.

ISBN: [assigned by KDP at submission]

First Edition: 2026

Athlete Domains, LLC
squishysmash.com

Printed in the United States of America.
```

**Notes for the build pipeline:**
- ISBN placeholder gets filled in by KDP automatically — leave as `[assigned by KDP at submission]` until the actual ISBN is known, then republish if you want it printed. Many indie titles ship without printed ISBN (KDP only requires it in the metadata, not on the page).
- The line about "Squishy Smash, the three packs..." trademark notice is **optional** — only add if you've actually filed trademark applications. Default: skip it.

---

## Page 3 — Dedication (recto)

Short, centered, italic. The single moment in the front matter where the human author's tenderness surfaces.

**Layout:**
- Background: cream
- Vertically centered (about 45% from top)
- Horizontally centered
- Sorts Mill Goudy Italic at 14pt / 20pt leading
- Color: deep palette-brown `#4A2D24`
- Max 3 lines

**Text (locked 2026-06-01):**

```
For my partner and our three daughters —
the comfort, the brave-cuddle,
and all the sparkle.
You are why I went looking.
```

The three nouns ("comfort," "brave-cuddle," "sparkle") echo the three places named on Spread 1 (Pudding Hills, Goo Coast, Moonlit Hollow + the Sparkle that lights them) — so the dedication doubles as story DNA without spoiling the plot. The closing line ("You are why I went looking") mirrors the trio's quiet decision on Spread 3 ("each of them, very quietly, decided it was time").

---

## Page 4 (= p40) — Back Matter (verso)

Two stacked elements: Book 1 callback (top half), author bio (bottom half). Closes the book with one more soft moment + a cross-sell hook for the buyer who picked up Book 2 first.

**Layout:**
- Background: cream
- Top half (y=10% to y=50%): Book 1 callback
- Divider at y≈52% — thin painted line in dusty gold `#E4C46C` at 60% opacity, centered, ~1.5 in wide
- Bottom half (y=55% to y=92%): About the Author
- Sorts Mill Goudy body throughout, sizes specified per block

**Text:**

### Block 1 — Book 1 callback (upper half)

**Headline** (EB Garamond Caps, 14pt, letter-spaced 80 units, dusty gold `#E4C46C`, centered):
```
HAVE YOU MET ALL FORTY-EIGHT?
```

**Body** (Sorts Mill Goudy, 11pt/15pt, palette-brown, centered, max 3.5 in wide):
```
Squishy Smash: Meet the Squishies is the companion field guide — forty-eight soft-shaped friends across three magical packs, each with their own signature squish and a story all their own. The Squishkeeper has been waiting to introduce you.

Available wherever books are sold.
amazon.com/dp/B0H219KX2X
```

### Divider

Thin painted gold rule, ~1.5 inches wide, centered.

### Block 2 — About the Author (lower half)

**Headline** (EB Garamond Caps, 12pt, letter-spaced 80 units, dusty gold, centered):
```
ABOUT THE AUTHOR
```

**Author photo** (round-cropped, ~1.2 in diameter, centered, sits above the bio).
Source: `book/assets/author_photo.jpg` — copied from the developer-portfolio
public/images/profile.jpg. Round-crop + slight warm tint to match the cream palette.

**Body** (Sorts Mill Goudy / Bookmania body, 10pt/14pt, palette-brown, centered, max 3.5 in wide):
```
Christopher Ryan Campbell is the creator of Squishy Smash, a soft-shaped universe of plush characters, magical packs, and gentle adventures. He builds the world across iOS, picture books, and short illustrated tales for readers who like their adventures soft.

He lives in Spartanburg, South Carolina, with his partner and three stepdaughters.

He is also the author of *The Red Brick Road*, a fantasy reimagining of the Land of Oz for older readers.
```

**Closing line** (italic, smaller, centered):
```
Find Squishy Smash at squishysmash.com or @CryptoChris8 on TikTok.
```

**Notes for the build pipeline:**
- Bio expanded 2026-06-01 (was: intentionally vague brand-only bio). New copy adds location/family, an "also by" callout for *The Red Brick Road*, and the TikTok handle for the cross-channel funnel.
- The Book 1 callback's `amazon.com/dp/B0H219KX2X` URL matches the canonical ASIN per [`project-book-live`] memory. Confirmed live since 2026-05-16.
- The "wherever books are sold" line is technically accurate (KDP also lists on .co.uk, .de, etc.) — leaves room for future channels.
- Divider moved from y=0.54 → y=0.48 to give the bottom half more vertical room for the photo + expanded bio.

---

## Word counts (for the build pipeline's layout fit checks)

| Page | Block | Words |
|---|---|---|
| 1 | Title page | 7 |
| 2 | Copyright | ~110 |
| 3 | Dedication (default) | 16 |
| 4 | Book 1 callback | 50 |
| 4 | Author bio | 47 |

All comfortably fit single-page layouts at the specified type sizes.

---

## Cross-references

- Manuscript: [`book2_manuscript_draft.md`](book2_manuscript_draft.md) — the 18 interior spreads
- Locked decisions: [`KDP_METADATA_SCRATCH_BOOK2.md`](../KDP_METADATA_SCRATCH_BOOK2.md) — KDP metadata
- Cover system: [`../cover/cover_copy_book2.md`](../cover/cover_copy_book2.md) — typography + palette
- Story voice: [`../STORY_BIBLE.md`](../STORY_BIBLE.md) §6 — the Squishkeeper voice (NOT used on these pages)
