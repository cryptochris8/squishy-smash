# Squishy Smash — Card Economy & Progression Balancing Spec for Claude

## Purpose
Refine Squishy Smash so it stays:
- fun immediately
- satisfying to tap
- ASMR-forward
- collectible
- rewarding over time

This balancing pass should not turn the game into a high-skill strategy game.

Instead, the goal is:

**easy fun + slower collection completion + better long-term retention + future monetization support**

---

# 1. What the playtest revealed

The user let daughters ages 8, 8, and 6 playtest the game.

## Result
They had a blast and enjoyed:
- fast tapping
- squishy feedback
- sound effects
- visual rewards
- collection excitement

## Problem discovered
They were able to earn roughly 80% of the squishies/cards too quickly by:
- tapping very fast
- using little to no strategy
- brute-forcing the collection loop

This means:
- rarity loses meaning
- collection completion happens too fast
- long-term retention weakens
- monetization options become less valuable later

---

# 2. Core design principle going forward

Claude should preserve the core identity of Squishy Smash:

- tactile
- cute
- ASMR-like
- low-friction
- satisfying
- collectible

Do not overcorrect into a hard or stressful game.

Instead, Claude should add economy friction, not heavy gameplay frustration.

### Correct design direction
Keep:
- easy tapping
- rich feedback
- satisfying squish loop
- rewarding collection moments

Adjust:
- drop pacing
- rarity pacing
- coin economy
- direct card acquisition balance
- spam-tap efficiency

---

# 3. New collection philosophy

Players should be able to unlock cards in two main ways:

## A. Gameplay unlocks
Players can still earn squishies/cards through normal play.

## B. Coin-based acquisition
Players can also purchase rarer cards or targeted content by spending coins they earn.

This is the correct hybrid structure because it provides:
- randomness and excitement
- player choice
- better progression
- better future monetization support

---

# 4. Goals of the new system

Claude should rebalance toward these goals:

1. players should still unlock things early and often
2. common cards should remain satisfying to obtain
3. rare/epic/legendary cards should take longer
4. players should feel progress even when they do not get a rare card
5. coin accumulation should feel meaningful
6. targeted purchases should feel valuable, not mandatory
7. full collection completion should take much longer than current playtest results

---

# 5. Recommended rarity pacing

Claude should treat rarities differently.

## Common
- should unlock fairly often
- should create early momentum
- should keep young players engaged quickly

## Rare
- should feel noticeably less common
- should be exciting but still attainable

## Epic
- should feel special
- should require more sessions or deliberate saving

## Legendary
- should feel rare and memorable
- should not drop frequently from random gameplay

---

# 6. Recommended acquisition structure

## Gameplay drops
Gameplay should primarily reward:
- commons
- occasional rares
- very infrequent epics
- extremely rare legendaries

## Coin purchases
The coin system should allow:
- purchase of specific cards
- purchase of specific packs
- purchase of rotating featured cards
- purchase of rerolls or premium reveals later if desired

This gives players some control without making random rewards irrelevant.

---

# 7. Recommended economy model

Claude should implement or tune the following economy loop:

## Player actions
- tap and squish
- earn score
- earn coins
- unlock occasional card drops
- convert duplicates into value
- save for desired rarer cards

## Reward outputs
- coins
- random card drops
- duplicate compensation
- milestone rewards
- pack completion bonuses

---

# 8. Duplicate handling

Duplicates should never feel useless.

Claude should make duplicates convert into something useful, such as:
- coins
- card dust / shards
- progress toward pack rewards
- progress toward pity meter

Recommended default:
- convert duplicates into coins automatically

This prevents bad luck from feeling empty.

---

# 9. Shop / purchase structure

Claude should create a simple card shop structure.

## Recommended shop options
### Option A — Rotating featured card
- one featured card at a time
- changes daily or every few days

### Option B — Pack-based purchase
- buy a specific pack card roll using coins

### Option C — Direct card purchase
- buy specific rare/epic/legendary cards once unlocked in the catalog or when featured

Recommended approach:
- keep direct purchase limited mostly to rare+ cards or featured cards
- do not let the player instantly buy the whole collection too cheaply

---

# 10. Example price tiers

Claude can tune exact values, but use this philosophy:

- Common: very cheap or mostly gameplay-earned only
- Rare: moderate cost
- Epic: expensive enough to require saving
- Legendary: premium coin goal

Example relative pricing model:
- Common = 1x
- Rare = 4x
- Epic = 10x
- Legendary = 20x+

Exact values should depend on actual coin earn rate.

---

# 11. Coin earn rate philosophy

Claude should make sure coin earnings feel:
- steady
- visible
- satisfying
- worth chasing

But coin gain should not be so high that players can buy all rare cards too quickly.

### Good coin outcome
Players should feel:
- “I’m getting closer”
- “I can save up for the one I want”
- “duplicates still help me”

### Bad coin outcome
Players should feel:
- “I can instantly buy everything”
- or
- “I never earn enough for anything”

Claude should target the middle ground.

---

# 12. Anti-spam balancing

A major issue found in playtesting:
players could rapidly tap with little strategy and still progress too fast.

Claude should reduce the effectiveness of pure spam tapping without ruining responsiveness.

## Good solutions
- brief per-squishy cooldown window
- reduced reward from repeated ultra-fast taps
- combo bonus for varied or cleaner play
- light accuracy/timing bonus
- streak bonuses tied to play quality
- diminishing returns on mindless spam

## Avoid
- heavy penalties
- harsh failure states
- anything that makes the game feel stressful or slow

The player should still be able to tap fast and have fun.
Claude should simply avoid letting spam trivialize the economy.

---

# 13. Keep the game ASMR-first

The game was built more as:
- an ASMR experience
- a satisfying tap toy
- a sensory collectible experience

It was not built as a deep strategy game.

Claude should preserve that identity.

That means:
- satisfying sounds remain central
- visual squish feedback remains strong
- playful rewarding feel remains intact
- the collection system deepens retention, but does not overpower the vibe

---

# 14. Suggested progression layers

Claude should support multiple progression layers at once.

## Layer 1 — Immediate fun
- squish feedback
- sounds
- particles
- quick rewards

## Layer 2 — Session progression
- coins earned per run
- occasional card drops
- milestones

## Layer 3 — Long-term progression
- full collection completion
- pack completion
- rare/epic/legendary targeting
- shop purchases
- future monetization systems

This layered structure is healthier than letting the collection finish almost immediately.

---

# 15. Pack completion incentives

Claude should consider adding:
- pack completion percentage
- milestone rewards by pack
- small coin bonus for pack milestones
- cosmetic bonus for full pack completion later

This encourages longer engagement without requiring hardcore strategy.

---

# 16. Recommended hidden balancing tools

Claude should structure the economy so future tuning is easy.

Use data-driven config values for:
- rarity drop rates
- coin earn rates
- duplicate conversion rate
- shop prices
- featured rotation timing
- pity meter thresholds if added later

This allows quick tuning after future kid/family playtests.

---

# 17. Pity / mercy system recommendation

To avoid frustration, Claude should consider a soft pity system for higher rarity cards.

Examples:
- after X drops without a rare+, improve odds slightly
- after Y drops without an epic, guarantee stronger reward
- after enough duplicates, unlock targeted purchase discount

This keeps rare rewards exciting while protecting against bad luck.

---

# 18. Monetization readiness

This new hybrid system also supports stronger monetization in the future.

Claude should structure the economy so it could later support:
- rewarded ads for bonus coins
- ad-based rerolls
- premium coin packs
- premium featured bundles
- battle pass / collection pass
- ad removal plus passive coin bonus

Important:
the free core loop should still feel generous and fun.

---

# 19. Immediate implementation recommendation

Claude should make the following balancing pass now:

1. reduce random drop generosity for higher rarities
2. keep common card drops fairly generous
3. add or refine coin-based targeted acquisition
4. auto-convert duplicates into coins
5. soften the impact of rapid spam tapping on progression speed
6. expose all economy values in configuration for fast tuning
7. keep the overall game feel fast, joyful, and ASMR-rich

---

# 20. Final directive for Claude

Claude should rebalance Squishy Smash so that:

- kids still have fun immediately
- the game still feels satisfying and low-friction
- the collection no longer completes too quickly
- rare cards feel truly valuable
- coins become meaningful
- players can either get lucky through gameplay or save for what they want
- the economy supports future monetization without harming the current fun-first experience

The ideal outcome is:

**fun right away, rewarding over time, meaningful rarity, and strong future monetization support**
