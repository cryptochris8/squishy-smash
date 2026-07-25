# Claude Code Build Instructions

## Mission
Create the final Squishy Smash Licensing & Manufacturing Deck using the content and constraints in this package.

## Required Workflow
1. Review all markdown files.
2. Inventory all supplied assets.
3. Choose the strongest available visual for each slide.
4. Build the presentation with editable text and images.
5. Create a consistent master style.
6. Export PPTX and PDF.
7. Validate every slide visually.
8. Fix overflow, clipping, font, or alignment issues.

## Technical Requirements
- 16:9 widescreen
- Approximately 12 to 15 slides
- Editable text and images
- No text overflow
- No low-resolution image stretching
- No unsupported font dependencies
- Include speaker notes only if they add practical value

## Content Rules
- Use the copy as a strong starting point, but tighten wording when needed.
- Preserve factual accuracy.
- Use “proposed,” “planned,” or “potential” for anything not yet launched.
- Do not fabricate sales, downloads, audience size, retail partners, patents, trademarks, or manufacturing relationships.
- Do not claim the 3D models are automatically mold-ready.
- Do not present estimated manufacturing costs as confirmed quotes.

## Visual Quality Check
For every slide verify:
- Is the headline readable at a glance?
- Is there one clear focal point?
- Is the character artwork large enough?
- Is all text inside safe margins?
- Does the slide look like part of the same deck?
- Are placeholders clearly labeled?

## Suggested File Structure for Generated Source
- `src/deck.js` or equivalent
- `src/theme.js`
- `src/helpers.js`
- `output/*.pptx`
- `output/*.pdf`

## Final Deliverables
- Squishy_Smash_Licensing_Manufacturing_Deck.pptx
- Squishy_Smash_Licensing_Manufacturing_Deck.pdf
- Optional preview images for each slide
- A short `BUILD_NOTES.md` describing missing assets and any assumptions
