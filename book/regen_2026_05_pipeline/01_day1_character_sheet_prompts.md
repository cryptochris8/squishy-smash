# Day 1 — Character Model Sheet Production Guide

*Locked 2026-05-25. Build a hand-illustrated character sheet for the three protagonists in Vashti Harrison chalk-pastel + digital style, anchored to existing 3D card art via Midjourney `--cref`. This sheet becomes the LoRA training input AND the visual canon for the rest of the regen.*

---

## What you do today

1. **Subscribe to Midjourney Standard** ($30/month) — https://www.midjourney.com/account if not already. Cancel after 1 month if you don't continue with MJ for ongoing work; we only need ~1 month of access.
2. **Upload 3 character reference images to a public host** (Imgur is easiest, free, no account needed for anonymous uploads — https://imgur.com/upload). You'll get a URL for each that MJ can read.

   Files to upload:
   - `C:/Users/chris/Squishy-smash/squishy_smash/assets/cards/final_48/001_Soft_Dumpling.webp`
   - `C:/Users/chris/Squishy-smash/squishy_smash/assets/cards/final_48/017_Goo_Ball.webp`
   - `C:/Users/chris/Squishy-smash/squishy_smash/assets/cards/final_48/033_Blushy_Bun_Bunny.webp`

3. **Run the 18 prompts below** in Midjourney (Discord `/imagine` or web app). 4 candidates per prompt = 72 generations total. ~30 min at MJ Fast speed.
4. **Hand-select the 8 best** (mix across all 3 characters and pose variants — see selection criteria at the bottom).
5. **Send me back the 8 winner URLs** (drag from MJ → reply in chat). I'll use them to write the LoRA training brief (Day 1 evening, ~30 min, ~$3 on fal.ai).

---

## How the prompts work

Each prompt has three parts:

1. **Style anchor** (constant across all 18): the Vashti Harrison chalk-pastel language
2. **Character description** (varies per protagonist): silhouette + color + key features
3. **Pose / angle** (varies per shot)

Plus MJ flags to lock everything:
- `--cref [URL]` — character reference (locks face/silhouette/color to your 3D card art)
- `--cw 100` — character weight maxed (strong adherence to the reference)
- `--ar 1:1` — square aspect for character sheets
- `--sv 4` — style variation diversity (a bit of range across the 4 candidates per prompt)

---

## The 18 prompts

**STYLE ANCHOR** (used in every prompt below — paste verbatim):

```
soft chalk pastel and digital children's picture book illustration, no hard outlines, forms built from shaded mass, warm peach and cream palette, soft North-window light, matte finish, in the style of Vashti Harrison's "Big"
```

Replace `<SD_REF>` with your Soft Dumpling Imgur URL, `<GB_REF>` with Goo Ball's, `<BB_REF>` with Blushy Bun Bunny's.

### Soft Dumpling — 6 shots

```
1. /imagine soft round pink dumpling character, gentle neutral expression, simple round eyes, standing on plain cream background, front view, [STYLE ANCHOR] --cref <SD_REF> --cw 100 --ar 1:1 --sv 4

2. /imagine soft round pink dumpling character, gentle neutral expression, three-quarter view, slight head tilt, plain cream background, [STYLE ANCHOR] --cref <SD_REF> --cw 100 --ar 1:1 --sv 4

3. /imagine soft round pink dumpling character, scared expression, eyes wide, slight tremble, soft pink shoulders pulled in, front view, plain cream background, [STYLE ANCHOR] --cref <SD_REF> --cw 100 --ar 1:1 --sv 4

4. /imagine soft round pink dumpling character, triumphant pose, joyful expression, eyes bright, sense of mid-bounce, plain cream background, [STYLE ANCHOR] --cref <SD_REF> --cw 100 --ar 1:1 --sv 4

5. /imagine soft round pink dumpling character, sleepy expression, eyes half-closed, peaceful, three-quarter view, plain cream background, [STYLE ANCHOR] --cref <SD_REF> --cw 100 --ar 1:1 --sv 4

6. /imagine soft round pink dumpling character walking, gentle forward motion, neutral expression, profile side view, plain cream background, [STYLE ANCHOR] --cref <SD_REF> --cw 100 --ar 1:1 --sv 4
```

### Goo Ball — 6 shots

```
7. /imagine round glossy blue jelly character, neutral curious expression, simple round eyes, standing on plain cream background, front view, [STYLE ANCHOR] --cref <GB_REF> --cw 100 --ar 1:1 --sv 4

8. /imagine round glossy blue jelly character, neutral curious expression, three-quarter view, slight head tilt, plain cream background, [STYLE ANCHOR] --cref <GB_REF> --cw 100 --ar 1:1 --sv 4

9. /imagine round glossy blue jelly character, scared expression, eyes wide, slight quiver, plain cream background, front view, [STYLE ANCHOR] --cref <GB_REF> --cw 100 --ar 1:1 --sv 4

10. /imagine round glossy blue jelly character, triumphant mid-bounce, joyful expression, eyes bright, sense of motion and splat-bounce, plain cream background, [STYLE ANCHOR] --cref <GB_REF> --cw 100 --ar 1:1 --sv 4

11. /imagine round glossy blue jelly character, looking up in awe, gentle expression, head tilted upward, plain cream background, [STYLE ANCHOR] --cref <GB_REF> --cw 100 --ar 1:1 --sv 4

12. /imagine round glossy blue jelly character walking, gentle forward motion, neutral expression, profile side view, plain cream background, [STYLE ANCHOR] --cref <GB_REF> --cw 100 --ar 1:1 --sv 4
```

### Blushy Bun Bunny — 6 shots

```
13. /imagine soft lavender rabbit character with rosy pink cheeks, gentle neutral expression, simple round eyes, standing on plain cream background, front view, [STYLE ANCHOR] --cref <BB_REF> --cw 100 --ar 1:1 --sv 4

14. /imagine soft lavender rabbit character with rosy pink cheeks, gentle neutral expression, three-quarter view, slight head tilt, plain cream background, [STYLE ANCHOR] --cref <BB_REF> --cw 100 --ar 1:1 --sv 4

15. /imagine soft lavender rabbit character with rosy pink cheeks, scared expression, eyes wide, ears pulled back slightly, plain cream background, front view, [STYLE ANCHOR] --cref <BB_REF> --cw 100 --ar 1:1 --sv 4

16. /imagine soft lavender rabbit character with rosy pink cheeks, triumphant brave expression, eyes bright, paws raised, sense of leadership, plain cream background, [STYLE ANCHOR] --cref <BB_REF> --cw 100 --ar 1:1 --sv 4

17. /imagine soft lavender rabbit character with rosy pink cheeks, sleepy peaceful expression, eyes closed, ears soft, plain cream background, [STYLE ANCHOR] --cref <BB_REF> --cw 100 --ar 1:1 --sv 4

18. /imagine soft lavender rabbit character with rosy pink cheeks, hopping pose, mid-air, eyes bright, side view, plain cream background, [STYLE ANCHOR] --cref <BB_REF> --cw 100 --ar 1:1 --sv 4
```

---

## Selection criteria — which 8 to keep

You'll have ~72 candidates (4 per prompt × 18 prompts). Pick **8** that satisfy these criteria:

1. **Character recognition.** Set the candidate next to its source 3D card. Can a 5-year-old tell it's the same character? If not, reject.
2. **Style consistency.** Across the 8 winners, the chalk-pastel-medium feel should be uniform. Pick 8 that share medium signature, not 8 from 8 different aesthetics.
3. **Pose diversity.** Aim for: 3 neutrals (one per character), 2 triumphant (Spreads 9 + 12), 2 scared (Spreads 3 + 11), 1 sleepy/quiet (Spread 18). If a character's scared shot isn't great, pick the next neutral.
4. **Expression clarity.** The eyes must convey the emotion at a glance. Vague-staring eyes = reject even if everything else is good.
5. **Anti-AI hygiene.** Check fingers/limbs (Squishies have minimal hands — easy win), check for mirror highlight artifacts on the body, check for any "concept art" lighting drama (god rays, lens flare) that shouldn't be there.

---

## What you send back

Reply with the 8 Midjourney image URLs (the public-share URL from each generation, accessible from MJ's web app or via right-click → "Copy Image Link"). Format:

```
1. Soft Dumpling neutral: <URL>
2. Soft Dumpling triumphant: <URL>
3. Soft Dumpling scared: <URL>
4. Goo Ball neutral: <URL>
5. Goo Ball triumphant: <URL>
6. Blushy Bun Bunny neutral: <URL>
7. Blushy Bun Bunny triumphant: <URL>
8. Blushy Bun Bunny scared: <URL>
```

(Adjust labels to match your actual picks.)

---

## Time / cost reality

- **Subscribe + reference upload:** ~10 min
- **Run 18 prompts at MJ Fast:** ~30 min wall time (most of it is queue + waiting)
- **Hand-select the 8 winners:** ~20 min
- **Send URLs back:** ~5 min

**Total Day 1 (your side):** ~1 hour.

**Cost:** $30/month MJ Standard (your single 18-prompt batch uses ~5% of monthly Fast hours; you'll have plenty of headroom for any redo passes).

---

## If anything goes weird

- **MJ rejects `--cref` URL:** the URL probably needs to be a direct image link (ends in `.jpg`/`.png`/`.webp`). Imgur's "Image Address" right-click works; the share-page URL doesn't.
- **All candidates ignore the reference and look like generic Vashti Harrison kids:** increase `--cw` is already at max; try `--cref [URL] --cw 100 --iw 1.5` (image weight too).
- **Style is too literal / cartoony / loses the chalk-pastel feel:** add `painterly chalk pastel texture, visible brush stroke, soft mass shading` to the style anchor.
- **You can't decide between two candidates:** send me both URLs labeled "tie A" / "tie B"; I'll judge on style-consistency criteria.

---

## Next step after this

Once you send the 8 URLs, I produce Day 1 evening deliverable: **LoRA training brief** for fal.ai. You upload the 8 images + ~10 of your existing 3D card art images to fal.ai → FLUX.1 [dev] LoRA trainer → ~30 min training → LoRA ID returned. Then Day 2 starts: I write per-spread FLUX prompts, you generate.
