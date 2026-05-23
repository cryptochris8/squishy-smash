# Book #2 — The Lost Sparkle — Concept Lock

*Draft 2026-05-23. Requires user signoff before any production work (manuscript drafting, art pipeline, environment plates). Once locked, the items in this doc are invariant until either (a) the manuscript surfaces a contradiction or (b) the user explicitly reopens them.*

## What it is

A 40-page, 8.5×8.5 paperback narrative storybook — the first plot in the Squishy Smash universe. Three Common squishies from three packs cross borders for the first time to restore the Sparkle. Ensemble cast: 3 protagonists, 9 Rares as guides, 9 Epics as visual showpieces, 3 Legendaries as frame, 24 Commons as crowd-spread cameos. All 48 characters used; only 3–6 named in the prose.

## Format & price
- **Trim:** 8.5 × 8.5 in (matches Book #1)
- **Pages:** 40 (≈18 story spreads + front/back matter)
- **Price:** $12.99 paperback
- **Audience:** ages 4–8 (sweet spot 5–7)
- **Reading mode:** read-aloud (lap / classroom), independent re-read from age 7

## The parent problem this solves
Book #1 is a reference; *The Lost Sparkle* is a ritual. A single arc with a Big Pop the child can shout along to, and a final line the parent says on autopilot by month three. The story closes the loop Book #1 opens — once your kid loves these 48 characters, you need a way to put them to bed.

## Story spine (locked, from `STORYBOOK_DISCOVERY.md` §2)
1. Pack-Land at peace. The Sparkle holds.
2. The Sparkle flickers. Three shards drift, one into each pack-world.
3. Soft Dumpling (Pudding Hills), Goo Ball (Goo Coast), and Blushy Bun Bunny (Moonlit Hollow) cross pack borders for the first time.
4. Three-act middle: one pack-world per act. Rares speak as guides; Epics gate the obstacles; Commons populate the spreads.
5. The Cores fuse the shards. The Sparkle returns brighter — because friendship across packs made it whole.

## The Big Pop (climax mechanic)
**"EVERYBODY SQUISH!"** — shout-line at spreads 12–13 of 18. The child performs the bit every read. Predictability is the feature.

## The Pact line
Per `STORY_BIBLE.md` §9: *"Every pop is a hello. Every hello comes back."* Appears once near the climax. Not before, not twice.

## Voice & format invariants (do not relitigate)
- Squishkeeper narrates, never drawn (`STORY_BIBLE.md` §7)
- Italic only when the Squishkeeper speaks
- Periods, not em dashes (sound parentheticals exempted, per Book #1 precedent)
- Adventurous opening → soft-landing close (`STORY_BIBLE.md` §6)
- No villain. Tension comes from situation, not opposition.
- Signature squishes (Sploink / Pmf / thup) honored in dialogue

## Final-spread candidate (for user signoff)
> *"And tomorrow, another wobble. They always come back."*

Distills the Pact, lives in the Squishkeeper voice, sayable on autopilot. Open to redirection — the user has final say on the close line.

## KDP positioning (from `STORYBOOK_DISCOVERY.md` §4)
**Categories:** Friendship/Social Skills (primary) → Imaginary Creatures → Humorous Stories.
**Keywords:** squishy storybook ages 4 to 8 / kawaii bedtime story / kids friendship book / cute monster picture book / gentle bedtime adventure.

## Critical path (what gates everything else)
**Environment plates first.** Three pack-world background paintings — Pudding Hills, Goo Coast, Moonlit Hollow — reusable across all 18 spreads. **Nothing else can begin until these exist.** Specifically: no spread comp, no manuscript layout, no cover work.

After plates, in order:
1. Character-cutout pipeline (alpha-mask existing 48 cards via `tools/remove_sprite_backgrounds.py`)
2. Pose / expression variants for the 3 protagonists (≥3 each — neutral, scared, triumphant)
3. Spread compositor (extend `book/build/` or fork to `book2/build/`)
4. Manuscript draft, ~600–900 words across 18 spreads
5. Spread-by-spread layout
6. Cover
7. KDP packaging (interior.pdf + cover_wrap.pdf) — expect at least one rejection round per `project_book_live`

## Non-goals (the things that will tempt scope creep)
- No Squishkeeper visual treatment of any kind
- No villain or antagonist
- No Book 6 Squishkeeper-canon spoilers (deliberate incompleteness rule)
- No second KDP listing setup until manuscript v1 is approved
- No discount on the soft-landing close — read #47 is the test

## Suggested first concrete step (post-signoff)
**Spread-1 visual proof of concept.** Composite Soft Dumpling, Goo Ball, and Blushy Bun Bunny onto a temp Pudding Hills plate (a placeholder painting or quick AI comp), and draft the 30–50 words of opening prose for that spread. ~2 hours. Validates the cutout-on-plate look and the opening voice before committing to the full plate pipeline.

---
*Draft for user review. Sign off, edit, or send back. Everything in this doc becomes invariant once signed.*
