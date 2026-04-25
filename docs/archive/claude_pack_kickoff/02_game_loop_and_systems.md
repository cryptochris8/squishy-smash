# 02 — Game Loop and Systems

## Core Gameplay Loop
1. Object spawns into a compact arena
2. Player taps, slaps, drags, crushes, or flicks object
3. Object deforms and reacts with squish physics
4. Audio layers trigger: squish, pop, goo, splat
5. Particles and wall decals appear
6. Combo or destruction meter increases
7. Object bursts, splits, or flies away
8. Next object spawns quickly

This loop must feel good within seconds.

## Session Length
- Ideal session: **10–60 seconds**
- A single object interaction: **1–5 seconds**
- Rounds should be fast enough to encourage “one more try” behavior

## Core Interaction Types
### 1. Tap Smash
Single tap applies force and deformation.

### 2. Drag Slam
Player pulls object slightly and releases to slam it into a wall or floor.

### 3. Rapid Slap
Repeated taps build combo speed and overfill the burst meter.

### 4. Crush Hold
Press and hold compresses object until pop threshold is reached.

### 5. Flick Throw
Swipe to send object into arena boundaries for impact-based reactions.

## Object States
Each object should support some or all of these:
- idle
- deforming
- over-compressed
- leaking
- splitting
- bursting
- post-splat residue
- destroyed / cleared

## Object Categories
### A. Squishy Foods
Examples:
- dumpling
- jelly cube
- mochi blob
- soup dumpling parody object
- pudding cup
- boba stress orb

### B. Goo & Fidgets
Examples:
- stress ball
- gel cube
- bubble pod
- slime capsule
- goo donut

### C. Creepy-Cute Originals
Examples:
- gremlin plush blob
- snaggletooth squish sprite
- sleepy goblin gummy
- wink monster puff

## Arena Design
A simple contained play area is enough for MVP.
Recommended layout:
- foreground object zone
- back wall for splat decals
- slight camera depth illusion
- edges that objects can bounce into

Possible themes:
- candy lab
- slime kitchen
- weird toy room

## Scoring
### Suggested Formula
- base points for interaction
- bonus for burst threshold reached
- combo multiplier for speed
- style bonus for wall splat or multi-hit bounce

Example:
`score = base_hit + burst_bonus + combo_multiplier + trick_bonus`

## Combo Meter
The combo meter should rise when the player chains actions quickly.
It drops if the player pauses too long.

Good combo triggers:
- 3 quick hits
- drag slam after tap combo
- burst after over-compression

## Progression
### Coins
Award coins for:
- round completion
- combo thresholds
- first-time object destruction
- daily objectives

### Unlocks
Players unlock:
- new object packs
- arenas
- audio packs
- splat trails / cosmetic VFX

## Difficulty Scaling
Difficulty should come from:
- tougher objects with higher burst thresholds
- objects that bounce more
- mini-goals such as “burst in under 3 seconds”
- chain rounds with no missed interactions

## Modes
### Mode 1 — Quick Smash
Endless rotating objects, best for MVP.

### Mode 2 — Combo Rush
Timer-based mode focused on keeping a streak alive.

### Mode 3 — Burst Lab
Objects have unique burst requirements and hidden reactions.

## Reward Design
Every action should create feedback in at least 3 layers:
1. visual deformation
2. sound
3. particles or decal result

## MVP Success Criteria
The first playable should be considered successful if:
- the object deformation feels responsive
- the pop/burst is satisfying
- players understand the loop without tutorial friction
- one round can be clipped into a short social video
