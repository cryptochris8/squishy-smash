# Squishy Smash — Cover Copy v1

**Production target:** KDP paperback wrap cover, 8.5 × 8.5 in trim, 32-page interior, color paper.

**Cover wrap PDF dimensions** (single PDF that includes back + spine + front, with bleed):
- Width: 17.325 in (back 8.5 + spine 0.075 + front 8.5 + 0.125 left bleed + 0.125 right bleed)
- Height: 8.75 in (8.5 + 0.125 top + 0.125 bottom)
- Spine width formula: `pages × 0.002347` for color paper. 32 × 0.002347 = 0.0751 in. Round to 0.075.

**Spine warning:** at 32 pages, KDP recommends *no spine text* — the spine is too thin to print legibly. Treat the spine as a brand-color stripe only.

**KDP barcode safe zone:** KDP auto-overlays the barcode at the lower-right of the back cover, in a 2 × 1.2 in area positioned 0.25 in from trim edges. Keep this zone empty in our art.

---

## FRONT COVER

### Title block (centered, upper third)

**SQUISHY SMASH**

*Meet the Squishies*

A Character Adventure Book

### Hero art (lower two-thirds)

Recommendation: a 3-mascot cluster pulled from `assets/cards/final_48/`:
- `001_Soft_Dumpling.webp` (Squishy Foods)
- `017_Goo_Ball.webp` (Goo & Fidgets)
- `033_Blushy_Bun_Bunny.webp` (Creepy-Cute Creatures)

This puts one face from each pack on the front, telegraphing the book's structure at a glance.

### Lower-corner mark (optional)

A small "Volume 1" or "Book One" tag, bottom-right inside safe area. Useful if a sequel is on the roadmap.

---

## BACK COVER

### Headline (top, centered)

**48 squishies. 3 magical packs. One bouncy world.**

### Body blurb (under headline, centered, ~80 words)

Step into the world of Squishy Smash, where the softest snacks, the glossiest goos, and the cutest little creatures are ready to bounce, wobble, and shine.

From cozy little Soft Dumpling to the legendary Mythic Plush Familiar, every page bursts with brand-new squishy friends to meet, share, and love.

Open the book. Pick a pack. Find your favorite.

### Pack callouts (three small panels in a row)

**Squishy Foods** — warm, tasty, sweet
*art: 001 Soft Dumpling*

**Goo & Fidgets** — glossy, bouncy, satisfying
*art: 017 Goo Ball*

**Creepy-Cute Creatures** — spooky-sweet magical friends
*art: 033 Blushy Bun Bunny*

### Footer block (bottom of back cover, above barcode safe zone)

Ages 4 and up

squishysmash.com

© 2026 Squishy Smash

---

## SPINE

Brand-color band only. No text at this page count.

Recommended fill: brand pink `#FF8FB8` or background `#120B17`. Match whichever the front cover uses as its primary fill so the wrap reads as one continuous piece.

---

## Cover palette (matches in-app + website)

| Token | Hex | Use |
|---|---|---|
| `bg` | `#120B17` | Deep background, dramatic mode |
| `pink` | `#FF8FB8` | Primary mascot accent |
| `cream` | `#FFD36E` | Title highlight, glow |
| `jelly_blue` | `#7FE7FF` | Goo pack accent |
| `lavender` | `#C98BFF` | Creepy-cute pack accent |
| `lime` | `#B6FF5C` | Squishy Foods pack accent |

## Display font

**Fredoka** (variable, 300–700). Bundled at `website/public/fonts/Fredoka.ttf` — same TTF used across the marketing site and static legal pages, so the book brand-matches.

## Open decisions before final layout

1. **Hero art arrangement** — confirm the 3-mascot cluster (001 + 017 + 033). Alternative: single hero (just Soft Dumpling).
2. **Volume tag** — yes/no on "Book One" / "Volume 1" to signal a series.
3. **Author byline** — back cover currently shows publisher only. Add personal author name?
4. **Background mode** — light pastel front cover or deep `#120B17` "starry night" front cover? Both work; the in-app menu uses the dark mode.
