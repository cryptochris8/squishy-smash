# 03 — Content Pipeline

## Objective
Design the game so Claude Code can build the **core interaction engine once**, while all future trend updates happen mostly through data, assets, sounds, and light tuning.

## Content Strategy
The game should be content-driven, not hardcoded around one meme.
That means every object pack should be definable through structured configuration.

## Content Unit
Each object should have:
- unique ID
- display name
- category
- visual asset references
- deformation behavior values
- burst thresholds
- sound mappings
- particle mappings
- decal mappings
- score values
- rarity / unlock logic

## Recommended JSON Structure
See `config/sample_content_pack.json` for an example.

## Required Object Fields
- `id`
- `name`
- `category`
- `themeTag`
- `sprite`
- `thumbnail`
- `deformability`
- `elasticity`
- `burstThreshold`
- `gooLevel`
- `impactSounds`
- `burstSound`
- `particlePreset`
- `decalPreset`
- `coinReward`
- `unlockTier`
- `searchTags`

## Pack Structure
A content pack should contain:
- metadata
- color palette
- object list
- matching arena suggestion
- featured audio set
- release window

## Suggested Pack Types for Launch
### 1. Squishy Foods Pack
Keywords:
- dumpling
- jelly
- mochi
- pudding
- squish snack

### 2. Goo Fidgets Pack
Keywords:
- stress ball
- gel cube
- slime
- pop pod
- anti stress

### 3. Creepy-Cute Creatures Pack
Keywords:
- cute monster
- odd plush
- mischievous blob
- spooky cute

## Weekly Drop Model
Each week, push one of the following:
- 3 new objects
- 1 new sound set
- 1 mini event theme
- 1 featured arena skin

This creates freshness without requiring a whole new game.

## Live Ops Ideas
- Weekend “goo storm” modifier
- Double coin food pack weekend
- Limited-time seasonal packs
- daily featured object

## Search-Oriented Metadata Tags
Each object should have extra tags that support internal analytics and creative planning.
Examples:
- `asmr`
- `satisfying`
- `squishy`
- `stress-relief`
- `meme-inspired`
- `burst`
- `pop`

## Asset Production Workflow
1. Choose trend direction
2. Convert trend into original object concept
3. Generate concept art in Arts.io
4. Produce sprite / layered art
5. Create sound set in ElevenLabs or edit recorded sound layers
6. Add JSON entry
7. Tune burst, elasticity, and goo values
8. Add to featured rotation

## Important Rule
No content pack should depend on copyrighted names or characters.
Instead, create **adjacent energy**:
- “creepy-cute blind-box monster vibe” instead of a specific branded figure
- “viral squishy dumpling toy energy” instead of a direct toy clone

## Long-Term Benefit
This architecture lets the game chase fast-moving internet attention while keeping the underlying code stable.
