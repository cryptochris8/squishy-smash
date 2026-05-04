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

One central hero + two supporting characters, asymmetric size hierarchy (not equal-weight cluster). Pulled from `assets/cards/final_48/`:

- **Central hero (largest, ~55–60% of art zone):** `001_Soft_Dumpling.webp` (Squishy Foods) — most universally appealing, brand-recognizable, soft warm pink reads strongest at thumbnail size
- **Lower-left supporting (~25%):** `017_Goo_Ball.webp` (Goo & Fidgets) — jelly-blue accent
- **Lower-right supporting (~25%):** `033_Blushy_Bun_Bunny.webp` (Creepy-Cute Creatures) — lavender accent

The hierarchy gives a clear focal point (parent eye lands on the hero in ~1 second) while still telegraphing all three packs.

### Backdrop

Light pastel world-blend (NOT the deep `#120B17` starry-night used in the in-app menu — the book cover and the app menu should feel like sibling pieces, not identical).

Backdrop should subtly layer hints of all three packs:
- soft dessert clouds (warm pink/cream)
- glossy goo swirls (jelly-blue)
- spooky-cute sparkle motifs (lavender)
- ambient magical sparkle dust throughout

Treatment: bright but not messy. Backdrop supports the characters; it never competes for attention.

### Volume tag (lower-right, inside safe area)

Small "Book One" tag. Confirms a series and primes returning buyers for sequels (`Squishy Smash: Squishy Foods`, `Squishy Smash: Goo & Fidgets`, etc.).

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

Fill: brand pink `#FF8FB8` (matches the light-mode front cover so the wrap reads as one continuous piece).

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

## Locked decisions

1. **Hero arrangement** — single central hero (Soft Dumpling) + two supporting (Goo Ball lower-left, Blushy Bun Bunny lower-right). Asymmetric hierarchy, not equal-weight cluster.
2. **Volume tag** — yes, small "Book One" tag at bottom-right inside safe area.
3. **Author byline** — publisher only at this stage (subtle, near bottom). Personal author name can be added later if desired — one-line edit.
4. **Background mode** — light pastel world-blend with hints of all three packs and ambient sparkle. The deep starry-night look stays reserved for the in-app menu so cover and app feel like siblings rather than duplicates.
