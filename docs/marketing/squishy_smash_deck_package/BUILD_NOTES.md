# Build Notes — Squishy Smash Licensing & Manufacturing Deck

Built 2026-07-25 from the handoff package in
`docs/marketing/Squishy_Smash_Licensing_Manufacturing_Deck_Claude_Package.zip`.

## Deliverables

| File | Notes |
|---|---|
| `output/Squishy_Smash_Licensing_Manufacturing_Deck.pptx` | Editable. 17 slides, 13.333×7.5 in. 9.6 MB. |
| `output/Squishy_Smash_Licensing_Manufacturing_Deck.pdf` | **Send this one.** 17 pages, 13.333×7.5 in, brand font embedded. 6.4 MB. |
| `output/previews/*.png` | 1280×720 preview of every slide. |
| `output/Squishy_Smash_Licensing_Manufacturing_Deck.html` | Source of the PDF; open in any browser. |

15 core slides + 2 appendices (A: full 48-character gallery, B: manufacturer RFQ).

## How it is built

```
py   src/stage_assets.py     # pull + convert real brand assets from the repo
node src/deck.js             # -> PPTX
node src/build_html.js       # -> HTML  (then Chrome --print-to-pdf -> PDF)
```

- `src/content.js` — all slide copy, single source of truth.
- `src/theme.js` — palette and type scale.
- `src/helpers.js` — layout primitives (aspect-preserving image fit, panels, tags).
- `src/deck.js` — the 17 layouts.
- `src/build_html.js` — replays the *same* layout functions against a recorder
  and paints the result as HTML. **The PPTX and PDF cannot drift apart**; there
  is no second copy of the layout code.

## Assets — no placeholders were needed

The package's `assets/` folder was empty, so everything was pulled from the live
repo by `src/stage_assets.py` (30 files, 7.3 MB staged). All WebP was converted
to PNG/JPEG because PowerPoint does not reliably support WebP.

| Deck element | Source |
|---|---|
| Logo | `branding/logo/squishy_smash_logo_primary.png` (corners rounded — the master is a hard-edged rectangle that read as a pasted box on the dark cover) |
| Character renders | `website/public/models/posters/*.webp` — real renders of the six GLB 3D models |
| 48-card grid | `assets/cards/final_48/` via `assets/data/cards_manifest.json` |
| Trading card | `assets/cards/final_48/033_Blushy_Bun_Bunny.webp` |
| App screenshots | `screenshots/captioned/` |
| Roblox | `website/public/roblox-lost-sparkle.jpg` |

Colours are the official palette read from `lib/core/constants.dart` (`Palette`),
not the fallback palette in `docs/03_DESIGN_SYSTEM.md` — the design doc says to
prefer official brand colours when available. The five brand accents are tuned
for the app's near-black background, so on the deck's light slides they are used
for fills and shapes only; text uses darkened variants that hold contrast.

## Fonts — deliberate split

Fredoka is **not installed** on this machine, and `docs/05` requires "no
unsupported font dependencies."

- **PDF** embeds Fredoka (from `assets/google_fonts/Fredoka.ttf`). A PDF carries
  its own glyphs, so it renders with correct brand typography on any machine.
- **PPTX** uses Trebuchet MS / Arial — both ship with Windows *and* macOS, so the
  editable file opens correctly for any recipient with no font substitution or
  layout shift.

If you want Fredoka in the PPTX too, install the font on every machine that will
open it, then change `FONT.pptxHead`/`pptxBody` in `src/theme.js` and rebuild.

## Validation performed

- Every slide rendered at 1280×720 and reviewed by eye.
- Automated in-browser check on all 17 slides, in **both** font modes: flags any
  text box whose content overflows its own height and any element leaving the
  slide. **Result: 0 issues in both modes.** The checker was verified against
  two injected faults first, so the clean result is meaningful rather than a
  silently-broken test.
- PDF verified: 17 pages, MediaBox exactly 13.333×7.5 in, Fredoka embedded.

Three real bugs were caught and fixed during review: the "Multi-character
collector set" pill was rendering underneath the card panel with its label
hidden (slide 10); the appendix gallery's caption was buried under the bottom
row of cards (slide 16); and near-white characters were washing out on white
cards, since fixed with tinted discs behind every character render.

## Placeholders

**None remain.** The deck is complete and ready to send. Contact block (slide 15
and the copyright line):

| | |
|---|---|
| Contact | Christopher Ryan Campbell |
| Company | Athlete Domains, LLC |
| Email | support@squishysmash.com |
| Website | www.squishysmash.com |
| Phone | 864-606-2284 |

© 2026 Christopher Ryan Campbell / Athlete Domains, LLC. All rights reserved.

The email is the public support inbox — **swap it in `CONTACT` in
`src/content.js`** if you would rather route licensing enquiries somewhere
dedicated.

## Accuracy rules applied

Per `docs/05`, the deck makes no claim about sales, downloads, audience size,
retail partners, patents or trademarks, and quotes no costs or lead times.
Everything unlaunched is worded "proposed", "planned" or "target". The 3D models
are described as "a starting point for design-for-manufacturing review — not
finished tooling geometry", never as mold-ready.

Verified before use: 48 characters and the 24/12/9/3 rarity split (counted from
`cards_manifest.json`), six GLB models, both book ASINs, App Store ID
`6762549537`, Roblox place `105594294243426`.

**Pilot lineup:** the six characters proposed for the Founders Series are exactly
the six that already have 3D models. That is a defensible reason to pick them
rather than an arbitrary choice, and it happens to cover all three packs and
both ends of the rarity range.

---

## Please check these before sending it to anyone

Three things I could not resolve from the repo. None block the deck, but two of
them touch the actual value proposition of a *licensing* pitch.

1. **3D model licensing — verify before handing GLBs to a factory.**
   `tools/render3d/blender_render_squishy.py` documents the models as Meshy
   image-to-3D generated from the card art. Nothing in the repo records which
   Meshy tier was used. Meshy's free tier licenses output under CC BY 4.0, which
   requires attribution and is not suitable as the basis of a commercial
   product; commercial ownership requires a paid tier. The deck offers to supply
   these models to a manufacturer, so confirm the tier and keep the receipt.

2. **Copyright in the character artwork.** The 48 card arts and the sprites were
   AI-generated (FLUX, then Nano Banana / Gemini for the June restyle). The US
   Copyright Office position is that purely AI-generated images lack the human
   authorship needed for registration. That matters more here than it does for
   the game or the books, because a licensing deal is fundamentally a sale of
   rights. The deck deliberately makes **no** ownership, trademark or
   registration claim anywhere — it says "original characters", which describes
   the creative work without asserting a legal status. Worth a conversation with
   an IP attorney before signing anything.

3. **Age rating contradiction.** The deck proposes "ages 4–10" and labels it
   proposed, per the brief. Note that `docs/app_store_submission_copy.md`
   declares 4+ while `docs/google_play_submission_copy.md` declares 13+/18+ for
   the same binary. Unrelated to the toy's eventual age grade, but if a partner
   looks up either store listing the inconsistency is visible.

One deck-specific caveat: the three squish sheets in `assets/images/anim/` are
tightly-cropped, over-exposed head crops and were not usable, so the deck uses
the GLB poster renders instead. If you want proper front/side/back turntables for
a factory, they would need a fresh Blender pass — Blender is not installed on
this machine.
