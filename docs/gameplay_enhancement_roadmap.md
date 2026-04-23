# Squishy Smash — Claude Code Gameplay Enhancement Roadmap

## Purpose
This document tells Claude Code exactly how to improve Squishy Smash beyond the current strong TestFlight core.

Current strengths:
- strong cute squishy visual identity
- good skyboxes and reveal moments
- appealing sound/voice direction
- clean mobile presentation
- satisfying core tap loop
- themed content packs already feel promising

Main goal:
Turn the game from a polished prototype into a **high-retention, highly shareable, monetizable mobile game** by improving gameplay depth without losing simplicity.

---

# Core strategic principle

Do **not** make the game complicated.

Instead, deepen the experience through:
1. stronger tactile feedback
2. clearer reward loops
3. better variety between squishy types
4. collectible rare moments
5. short-session goals
6. stronger progression motivation

The game should remain:
- simple
- tactile
- premium-feeling
- collectible
- easy to replay
- easy to understand instantly

---

# Recommended gameplay enhancements

## 1. Add a clear reward loop
### Why
Players need to feel they are progressing toward something every session.

### Claude tasks
Implement a progression loop where gameplay contributes toward unlocking:
- new squishies
- rare variants
- new skyboxes
- reveal effects
- sound packs
- collection shelf items
- cosmetic themes

### Product goal
Every short session should still feel productive.

---

## 2. Add a rare reveal system
### Why
Rare reveals are one of the strongest drivers of:
- surprise
- retention
- “one more try” behavior
- shareable moments
- monetization potential

### Claude tasks
Implement a reveal rarity system with tiers:
- common
- rare
- epic
- legendary

Possible reveal outcomes:
- golden dumpling
- galaxy jelly
- rainbow goo creature
- sparkle edition squishy
- seasonal limited variant
- hidden core / mystery center

### Rules
- rare moments must be visually obvious
- rare moments should feel earned
- add pity logic so players do not feel unlucky forever

### Suggested system
- reveal chance rises slightly with combo performance
- reward ads can optionally grant one boosted reveal chance roll
- starter packs can include one guaranteed rare

---

## 3. Differentiate squishy behavior types
### Why
If all squishies react the same way, gameplay becomes repetitive too fast.

### Claude tasks
Create material behavior profiles so each squishy class feels distinct.

### Suggested behavior profiles
#### Dumpling
- soft bounce
- subtle puff
- warm dense squish
- cozy feel

#### Jelly Cube
- wobble-heavy
- translucent burst
- delayed jiggle recoil
- glossy splat

#### Goo Ball
- sticky stretch
- elastic pull
- delayed burst snap
- wet audio profile

#### Mochi
- dense press
- low thud
- slower rebound
- minimal splatter

#### Stress Ball
- strong elastic recoil
- firmer resistance
- more satisfying snap-back

#### Creepy-Cute Creature
- emotional facial reactions
- sparkle burst
- playful rare reveal treatment

### Technical instruction
All behavior types should be data-driven from pack/object definitions, not hardcoded by screen.

---

## 4. Make combo matter more
### Why
Combo should affect more than score alone.

### Claude tasks
Tie combo count into:
- reveal chance
- particle intensity
- skybox state
- rare event chance
- score multiplier
- coin multiplier
- voice line triggers
- burst intensity

### Suggested thresholds
- combo 3 = light charge feedback
- combo 6 = stronger glow + enhanced particles
- combo 10 = reveal-ready state
- combo 15+ = mega-burst state

### Product goal
Players should feel rewarded for maintaining rhythm.

---

## 5. Add haptics
### Why
Haptics will significantly improve tactile feel.

### Claude tasks
Implement:
- light haptic on normal squish
- medium haptic on strong hit
- burst haptic on successful burst
- reveal haptic on rare or major reveal
- subtle UI haptic on reward/claim actions

### Important
Keep haptics tasteful and not excessive.

---

## 6. Add mini-goals / missions
### Why
Short goals improve return sessions and session extension.

### Claude tasks
Implement daily/rotating goals such as:
- squish 10 dumplings
- trigger 3 reveals
- reach combo x5
- burst 5 goo creatures
- unlock one rare variant
- finish one themed challenge

### Rewards
- coins
- cosmetic unlock currency
- guaranteed rare chance token
- new skybox fragments
- voice pack sample unlock

### Product goal
Players should always have “one more reason” to keep playing.

---

## 7. Add a light progression/meta layer
### Why
The game needs identity beyond endless tapping.

### Claude tasks
Add simple meta systems:
- collection shelf
- reveal history
- rarity book
- best combo stat
- best session score
- rarest squishy found
- progress toward completing themed packs

### Important
Keep the meta layer elegant and low-friction.

---

## 8. Improve session start speed
### Why
Players should reach satisfying interaction very quickly.

### Claude tasks
- remember last selected pack
- allow one-tap resume into latest theme
- reduce menu friction
- make first burst/reveal happen sooner in early sessions
- streamline pack selection flow

### Product goal
The game should feel instantly replayable.

---

# ElevenLabs strategy

## Guiding principle
Use ElevenLabs strategically, not constantly.

This is an ASMR-adjacent satisfying game, so too much voice will hurt the feel.

---

## Best ElevenLabs use cases

### 1. Rare event voice stingers
Use sparingly for:
- “Rare reveal!”
- “Mega burst!”
- “That one was special.”
- “So satisfying.”
- “Perfect squish.”

### 2. Whisper-style ASMR voice pack
Create an optional whisper-light pack for:
- reveal moments
- rare moments
- unlock claims
- special challenge completion

### 3. Pack-specific voice flavor
Examples:
- Squishy Foods = cozy/cute voice tone
- Goo & Fidgets = playful bubbly tone
- Creepy-Cute Creatures = mischievous whisper tone

### 4. Trailer/promo narration
Use ElevenLabs to power:
- TikTok promo voiceovers
- App Store preview narration
- short-form hooks
- paid ad narration

### 5. Unlockable announcer packs
Potential monetization later:
- cute announcer
- sleepy ASMR announcer
- playful hype announcer
- spooky-cute announcer

---

## Voice usage rules
- no constant talking
- no repeated spammy callouts
- keep lines short
- prioritize premium tactile SFX over voice
- reserve voice for milestone moments

---

# Monetization-friendly gameplay enhancements

## Strongest early monetization hooks
- no ads purchase
- starter bundle
- limited themed packs
- cosmetic unlocks
- optional voice packs
- optional sound packs
- extra reveal chance item via rewarded ad

## Avoid
- aggressive interstitials
- too many currencies
- confusing economy
- paywalls that block the core satisfying loop

---

# Claude implementation priorities

## P0
Claude should build these first:
1. rare reveal system
2. collection / unlock loop
3. differentiated squishy behavior profiles
4. stronger combo rewards
5. haptics

## P1
Claude should build next:
1. missions / daily goals
2. collection shelf
3. seasonal limited drops
4. unlockable voice packs
5. light progression system

## P2
Claude should build later:
1. challenge mode
2. timed mode
3. event mode
4. replay/share highlight mode
5. larger social or competitive systems

---

# Technical guidance for Claude

## Data-driven design
All of the following should come from structured content data:
- squishy type
- behavior profile
- rarity table
- reveal outcomes
- audio profile
- particle preset
- skybox theme
- reward table
- mission definitions

Do not hardcode content theme logic directly into gameplay code.

---

## Suggested new schema categories
Add or extend:
- `behaviorProfile`
- `rarityProfile`
- `missionSet`
- `rewardTable`
- `voiceProfile`
- `hapticProfile`
- `revealVariant`
- `packProgression`

---

# Success metrics after these changes
Claude should help instrument and validate:
- time to first burst
- time to first reveal
- average combo achieved
- reveal trigger frequency
- rare reveal rate
- missions completed per session
- return rate after unlock moments
- rewarded ad opt-in rate
- collection progress per user
- session count per day

---

# Final directive
The next major evolution of Squishy Smash should be:

**core loop + reward loop + rare reveal loop**

That means:
1. squish
2. build combo
3. trigger reveal
4. unlock something
5. chase rare variant
6. repeat

Claude should preserve the game’s simplicity while making it more rewarding, more collectible, and more satisfying to replay.
