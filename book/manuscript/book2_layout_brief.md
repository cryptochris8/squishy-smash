# Book 2 — Per-Spread Layout Brief

*Synthesized 2026-05-30 from the per-spread text-placement audit agent. This document is the input that the interior PDF build pipeline reads to typeset prose on each of the 18 painterly spreads. Coordinates are in spread working-pixel space (1584 × 672 per spread); the build scales them up to print resolution (6336 × 2688).*

## Working coordinate system

- Spread dimensions: 1584 × 672 (working) / 6336 × 2688 (print, 4×)
- Gutter centered at x = 792
- LEFT third safe band: roughly x = 60–500
- RIGHT third safe band: roughly x = 1084–1524
- Gutter no-fly zone: x = 500–1084 (text must NEVER cross)

## Type system (locked)

- **Body:** Bookmania Regular (Adobe Fonts), 18pt / 26pt leading, ragged-right, color-keyed per-spread (NEVER pure #000)
- **Italic body:** Bookmania Italic — sound words, dialogue beats, Pact line, Squishkeeper voice
- **Painterly italic (S10 chant payoff):** Bookmania Black Italic, scale +30%
- **Climax shout (S12):** hand-painted "EVERYBODY SQUISH!" generated separately via NBP, alpha-keyed, composited
- **Banned:** pure-black type, hard white box, hard drop shadow, stroke/outline letters

## Final L/R rhythm (with overrides for painted-composition reasons)

| Spread | Zone | Technique | Reason |
|---|---|---|---|
| 1 | L | b wash panel | active brushwork — needs panel |
| 2 | L | a negative space | clean wash, right side has Sparkle + shards |
| 3 | triptych bottom | b 3-panel wash | parallel structure |
| 4 | L | b wash panel | border seam at x≈600 forces L |
| 5 | R | a negative space | load-bearing line wants the cleanest sky |
| 6 | R | b wash panel | clear Mochi cameo at x≈1370 |
| 7 | L | c reverse-out | Galaxy Dumpling deep-value zone |
| 8 | R | b wash panel | trio crowds in, cap panel above heads |
| 9 | R | b wash panel | mid-air SD on left, R sky is cleaner |
| 10 | R | c reverse-out | lower-right deep Moonlit-Hollow shadow |
| 11 | L | c reverse-out | confirmed deep-value across entire L third |
| 12 | L bottom | b small panel | small lead-in only; shout painted on burst |
| 13 | R | b wash panel | below the Mythic Familiar |
| 14 | L | a negative space | SD silhouette at lower-L, place above her |
| 15 | triptych bottom | b 3-panel wash | mirror S3 closure |
| 16 | R | b wash panel | tight collage; compact panel works |
| 17 | L | b wash panel | warm/light values allow low-opacity panel |
| 18 | R | a negative space | calmest expanse in the book; sleeping bedtime spread |

**Balance:** 8 left, 8 right, 2 triptych-bottom. Eye gets balanced rhythm across the book.

**Technique distribution:** 4× negative-space · 11× wash panel · 3× reverse-out. Reverse-out concentrates in the "dark act" (S7 Galaxy Dumpling + S10/S11 Moonlit Hollow) — coherent visual rule the reader internalizes: **dark spreads carry cream type**.

---

## Per-spread layout instructions

### Spread 1 — Three Places at Peace

- **Words:** 52
- **Zone:** LEFT third
- **Box (x, y, w, h):** (72, 60, 440, 360)
- **Technique:** (b) scumbled wash panel — left third is active peach pudding-hills brushwork; no calm zone for 52 words
- **Text color:** `#4A2E1E` (deepest cocoa-brown ridge shadow)
- **Wash panel:** `#FBEEDB` @ 84% opacity, 28px Gaussian feather
- **Notes:** Do not pass x=520. Sparkle rays land at (790, 130) — the narrative anchor stays clear.

### Spread 2 — The Flicker

- **Words:** 53
- **Zone:** LEFT third *(override of suggested R)*
- **Box:** (90, 380, 430, 250)
- **Technique:** (a) painted negative space — lower-left is soft peach wash, cleanest zone in the book
- **Text color:** `#4B3E5C` (deepest dusk-violet hill silhouette)
- **Notes:** Override reason: right carries Sparkle + 3 shards + lit village — text there would occlude. Stay x ≥ 90 to respect deckle edge.

### Spread 3 — Three Look Up *(TRIPTYCH)*

- **Words:** 47
- **Zone:** distributed bottom-band, three parallel panels
- **Boxes:**
  - Panel A: (40, 540, 460, 100) — "In Pudding Hills, Soft Dumpling looked up."
  - Panel B: (562, 540, 460, 100) — "In Goo Coast, Goo Ball looked up."
  - Panel C: (1084, 540, 460, 100) — "In Moonlit Hollow, Blushy Bun Bunny looked up."
  - Closing italic line ("None of them had ever left home before. But each of them, very quietly, decided it was time.") runs at y=620, broken naturally so it doesn't cross the inter-panel seams.
- **Technique:** (b) scumbled wash panel × 3, each keyed to its panel's palette
- **Text colors:** A `#5A3322` (pudding shadow) · B `#1F4A55` (goo shadow) · C `#3A2F58` (moonlit violet)
- **Wash panel:** uniform `#F6EBD8` @ 86%, feathered

### Spread 4 — At the Border

- **Words:** 56
- **Zone:** LEFT third *(override of "border special")*
- **Box:** (72, 80, 440, 280)
- **Technique:** (b) scumbled wash panel — cream trees in upper-L are densely painted; panel preserves orchard texture
- **Text color:** `#5B2F1C` (deepest peach-shadow under Soft Dumpling)
- **Wash panel:** `#F9EAD2` @ 82%, feathered
- **Notes:** Italic *Sploink* / *Pmf* dialogue beats land naturally at end of block, above the syrup-river seam.

### Spread 5 — Three *(load-bearing closing line)*

- **Words:** 61
- **Zone:** RIGHT third *(override — see below)*
- **Box:** (1064, 80, 460, 330)
- **Technique:** (a) painted negative space — upper-right is pale lavender-cream sky wash, cleanest available surface in the book
- **Text color:** `#3D2A4A` (deep plum-brown sampled from Moonlit-Hollow horizon at far right — forward-leaning hint of pack 3)
- **Notes:** Override reason: load-bearing closing line ("three different feelings standing on a boundary nobody had ever crossed") deserves the cleanest surface. Compose line breaks so "three different feelings / standing on a boundary / nobody had ever crossed" lands as three lines — typography mirrors the trio.

### Spread 6 — Into Pudding Hills *(chant launches: Pmf)*

- **Words:** 78
- **Zone:** RIGHT third
- **Box:** (1064, 70, 460, 420)
- **Technique:** (b) scumbled wash panel — upper-R has sunset wash + orchard mid-distance + tiny Sparkle Mochi at (1370, 270)
- **Text color:** `#5C2E18` (deepest orchard trunk-brown)
- **Wash panel:** `#FAE9CD` @ 82%, feathered. Crop panel right edge at x ≈ 1330 so Sparkle Mochi remains visible.
- **Chant treatment:** italic *Pmf, Pmf* sound-words on their own line at end, slightly indented, with +6pt above breathing room.

### Spread 7 — The First Shard

- **Words:** 67
- **Zone:** LEFT third
- **Box:** (60, 380, 430, 270)
- **Technique:** (c) reverse-out cream — deep-value zone runs continuously through lower-L (Galaxy Dumpling purple + dark orchard foliage)
- **Text color:** `#F5E7CD` (warm cream sampled from apple-tree highlights — NOT pure white)
- **Notes:** No panel — foliage texture dense enough that a panel would fight. Stay y ≥ 380 + x ≤ 490.

### Spread 8 — Into Goo Coast *(chant: Pmf, Sploink)*

- **Words:** 66
- **Zone:** RIGHT third
- **Box:** (1064, 60, 460, 230)
- **Technique:** (b) scumbled wash panel — fits above trio's heads
- **Text color:** `#1F4655` (deep teal-brown sampled from bubble-tide shadow at lower-L)
- **Wash panel:** `#F2EBDA` @ 84%, feathered. Panel bottom stops at y=290 to clear bunny ear at x ≈ 1320.
- **Chant treatment:** italic *Pmf, Sploink* on final emphasized line. Glitter Goo Ball cameo at (140, 175) sits clear in L third.

### Spread 9 — The Second Shard

- **Words:** 60
- **Zone:** RIGHT third *(override)*
- **Box:** (1084, 130, 440, 220)
- **Technique:** (b) scumbled wash panel
- **Text color:** `#2A4060` (deep navy-brown sampled from underwater shadow)
- **Wash panel:** `#F8EAD0` @ 82%, feathered
- **Notes:** Override reason: mid-air Soft Dumpling occupies LEFT mid-bounce. R sky is cleaner above the bunny's bounce. Panel starts y=130 to clear bunny ear at x ≈ 1200. Central shard at (~780, 130) is the focal point — text-block stays right of x=1084.

### Spread 10 — Into Moonlit Hollow *(chant payoff: Pmf, Sploink, Thup)*

- **Words:** 82
- **Zone:** RIGHT third
- **Box:** (1064, 380, 460, 280)
- **Technique:** (c) reverse-out cream — lower-R is deep purple forest-edge shadow with mushrooms; consistently low values
- **Text color:** `#F1E4C8` (warm cream sampled from moon face + mushroom highlights)
- **Chant treatment:** full payoff *Pmf. Sploink. Thup.* lands on the final line in italic at +30% scale (Bookmania Italic upsized — ceremonial leading 28pt), feels like a chant. Bunny silhouette at (1290, 90–540) sits right of text-block right edge if capped at x=1500.

### Spread 11 — The Deepest Grove

- **Words:** 56
- **Zone:** LEFT third
- **Box:** (60, 60, 440, 280)
- **Technique:** (c) reverse-out cream — confirmed deep-value across entire L third (trunks + forest-deep shadow runs `#1E1838` → `#2A1F44`)
- **Text color:** `#F4E6C6` (warm cream sampled from Glow Ghost Puff's lit body — thematic tie: the cream IS the warmth in the dark grove)
- **Notes:** Glow Ghost Puff at (650, 60–340) sits clear of L third. Repeated "almost" lines get +1pt looser leading (27pt) to make the mood pause sit.

### Spread 12 — Everybody Squish *(climax)*

- **Words:** 49 body prose + hand-lettered "EVERYBODY SQUISH!" painted separately
- **Zone:** LEFT third, BOTTOM band only (small lead-in)
- **Box:** (60, 470, 460, 180)
- **Technique:** (b) scumbled wash panel — small, low-opacity so burst is not visually cut
- **Text color:** `#2A1A38` (deep midnight-violet sampled from bottom-L ground shadow)
- **Wash panel:** `#F6E9CB` @ 80%, feathered, kept small
- **Notes:** The hand-painted "EVERYBODY SQUISH!" shout is composited on top of the burst at y ≈ 100–250 (separate asset). Italic *PMF! SPLOINK! THUP!* sound-effects sit in the body block on final lines, italic small-caps emphasis. The italic Pact line ("*Every pop is a hello. Every hello comes back.*") closes the body block with +8pt above.

### Spread 13 — The Three Cores

- **Words:** 55
- **Zone:** RIGHT third
- **Box:** (1064, 430, 460, 220)
- **Technique:** (b) scumbled wash panel — below the Mythic Familiar (upper-R at 900–1130, 0–250)
- **Text color:** `#3A2A18` (warm bark-brown sampled from right-side trunk)
- **Wash panel:** `#F7EAD0` @ 84%, feathered
- **Notes:** Cores naming ("Celestial Dumpling Core. Singularity Goo Core. Mythic Plush Familiar.") on its own line with period rhythm preserved + small additional leading for ceremonial feel.

### Spread 14 — The Sparkle, Brighter

- **Words:** 29
- **Zone:** LEFT third
- **Box:** (80, 380, 440, 200) *(reframed from agent's options for the cleanest fit)*
- **Technique:** (a) painted negative space — lower-L is pale hill + soft horizon + small Soft Dumpling silhouette
- **Text color:** `#6A3A1A` (warm sienna-brown — warmest member of palette, fits "warmer than S1" voice note)
- **Notes:** Soft Dumpling silhouette at x=180–280; place type above her. 29 words breathe; 3-4 lines max. Keep the Sparkle's rays visually heroic.

### Spread 15 — Going Home *(TRIPTYCH — mirror of S3)*

- **Words:** 40
- **Zone:** distributed bottom-band, three parallel panels
- **Boxes:**
  - Panel A: (40, 550, 460, 100) — "Soft Dumpling carried a little bit of the light home to Pudding Hills."
  - Panel B: (562, 550, 460, 100) — "Goo Ball carried a little bit of the light home to Goo Coast."
  - Panel C: (1084, 550, 460, 100) — "Blushy Bun Bunny carried a little bit of the light home to Moonlit Hollow."
- **Technique:** (b) scumbled wash panel × 3 — mirrors S3 exactly for parallel rhythm closure
- **Text colors:** A `#5A3322` · B `#1F4A55` · C `#3A2F58` *(same as S3)*
- **Wash panel:** uniform `#F6EBD8` @ 86%, feathered *(same as S3)*
- **Notes:** Panels strictly y ≥ 550 so the little glow each character carries (chest/hand area) is not occluded.

### Spread 16 — Three Homecomings

- **Words:** 24
- **Zone:** RIGHT third
- **Box:** (1084, 480, 460, 160)
- **Technique:** (b) scumbled wash panel — tight collage of all three pack homes; little negative space; 24 words = compact panel works
- **Text color:** `#3A2F58` (deep moonlit-violet — gentlest of the three palettes for closing voice)
- **Wash panel:** `#F4ECD8` @ 86%, feathered
- **Notes:** Three "Each home..." sentences set as three lines for parallel structure — 24 words fit cleanly at 18/26. Panel top y ≥ 480 clears bunny crowd-cameo at (1200, 350–540).

### Spread 17 — Three Borders, Touching

- **Words:** 40
- **Zone:** LEFT third
- **Box:** (90, 440, 420, 200)
- **Technique:** (b) scumbled wash panel — values warm/light enough that low-opacity panel sits cleanly
- **Text color:** `#6A2D1A` (deep pudding-cherry-brown sampled from cherry stems)
- **Wash panel:** `#F9EBCD` @ 80%, feathered. Panel bottom y ≤ 620 clears cherry-pudding at (40, 540–650).
- **Notes:** Three "Soft Dumpling visits / Goo Ball has tried / Blushy Bun Bunny is teaching" sentences with clear paragraph breaks for rhythm — protagonists' final naming wants visual structure.

### Spread 18 — The Close *(bedtime closure)*

- **Words:** 26
- **Zone:** RIGHT third
- **Box:** (1090, 280, 440, 220)
- **Technique:** (a) painted negative space — right two-thirds are luminous open peach-sienna sunset wash, calmest expanse in the book
- **Text color:** `#7A3A18` (warm sienna sampled from deep sunset hill shadow — warmest deep tone in the book, fits bedtime mood)
- **Notes:** First sentence ("The Sparkle is the light that comes from being found.") sits in upright Bookmania Regular. The italic Squishkeeper close ("*I have been there for every wobble. And tomorrow, another wobble. They always come back.*") runs below in Bookmania Italic with +2pt leading (28pt) to feel slower. Text-block top y=280 sits BELOW the Sparkle star at y=165. Soft Dumpling sleeping at (300, 280–520) sits clear in L third — do not place type left.

---

## Cumulative chant escalation across S6 → S8 → S10 → S12

Per the locked typography system:

| Spread | Chant text | Treatment |
|---|---|---|
| S6 | *Pmf, Pmf* | Bookmania Italic at body size (18pt), end-of-block on own line, slight indent, +6pt above |
| S8 | *Pmf, Sploink* | Bookmania Italic at body size, end-of-block on own line, +6pt above, slightly bolder weight inferred via Bookmania Semibold Italic if available, else Italic |
| S10 | *Pmf. Sploink. Thup.* | Bookmania Italic upsized to 22pt, ceremonial leading 28pt, on its own line, treat as chant payoff |
| S12 | *PMF! SPLOINK! THUP!* | Bookmania Black Italic ALL CAPS at 28pt, sound-effect chorus within the body block + the hand-painted "EVERYBODY SQUISH!" shout (separate NBP asset) sits on the burst above |

## Pact line treatment

The line **"Every pop is a hello. Every hello comes back."** appears once, at the end of the S12 body block, in Bookmania Italic, +8pt above, color-keyed to the S12 dusk palette (`#2A1A38`).

## Squishkeeper closing voice

The italic Squishkeeper voice closes the book at S18 (*"I have been there for every wobble. And tomorrow, another wobble. They always come back."*). This is the only S18 italic moment. Loose leading (28pt) makes it bedtime-slow.

---

## Build-pipeline data layout

When the interior build script consumes this brief, it should structure the data as something like:

```python
SPREADS_LAYOUT = {
    1: {"zone": "L", "box": (72, 60, 440, 360), "technique": "wash_panel",
        "text_color": "#4A2E1E", "wash_color": "#FBEEDB", "wash_opacity": 0.84,
        "wash_feather": 28, "notes": "Do not pass x=520; Sparkle rays land at (790, 130)"},
    2: {"zone": "L", "box": (90, 380, 430, 250), "technique": "negative_space",
        "text_color": "#4B3E5C", ...},
    # ... etc through 18
    3: {"zone": "triptych_bottom", "panels": [...], "technique": "wash_panel_3up", ...},
    15: {"zone": "triptych_bottom", "panels": [...], ...},
}
```

The pipeline scales coordinates from working res (1584×672) to print res (6336×2688) by 4×.

---

## Cross-references

- Manuscript: [`book2_manuscript_draft.md`](book2_manuscript_draft.md) — the 18 spreads' prose
- Front + back matter: [`book2_front_back_matter.md`](book2_front_back_matter.md) — pp 1-3 + p40
- Cover system: [`../cover/cover_copy_book2.md`](../cover/cover_copy_book2.md) — typography + palette
- Source spreads: `C:\Users\chris\Squishy-smash\book2_final_spreads\spread_NN.png` (working res, 1584×672)
- Print spreads: `C:\Users\chris\Squishy-smash\book2_final_spreads_print\spread_NN.png` (print res, 6336×2688)
