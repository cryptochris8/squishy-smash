# Squishy Smash — Drop Rate Tuning & Pity System Spec for Claude Code

## Purpose
This document tells Claude Code exactly how to tune collection drop rates so Squishy Smash feels:
- rewarding early
- exciting in the middle
- prestigious late
- never too stingy
- never too easy to complete

This file is designed to work with the launch rarity map:
- 48 total collectibles
- 3 packs of 16
- 8 common / 4 rare / 3 epic / 1 legendary per pack

---

# Core tuning philosophy

The collection system should create this emotional curve:

## First session
“Nice, I’m unlocking things quickly.”

## First few days
“I’m still getting good stuff, but now I’m chasing specifics.”

## Mid-term play
“I really want that missing epic.”

## Long-term
“I’m still working toward the legendary, but it feels possible.”

That means:
- early unlocks should be generous
- duplicates should not feel awful
- late rarity should feel meaningful
- legendary drops should be difficult, but protected by pity

---

# 1. Base reveal rarity model

Claude should separate the system into:
1. base rarity odds
2. progression gating
3. duplicate protection
4. pity logic
5. session-based soft boosts
6. optional rewarded boosts

Do not rely on raw RNG alone.

---

# 2. Recommended base rarity odds

These are the default reveal odds once a pack is fully unlocked for all rarity tiers.

## Base reveal odds
- Common: 68%
- Rare: 22%
- Epic: 8%
- Legendary: 2%

These are starting points, not the only governing factor.

Important:
- Legendary should not actually feel like a flat 2% at all times
- Gating and pity should control real player experience more than raw probability

---

# 3. Early progression gating

Claude should prevent top-tier collection completion too quickly.

## Early phase rules
During the first several reveals in a pack:
- heavily favor commons
- lightly allow rares
- block epics and legendaries until minimum engagement thresholds are met

### Suggested unlock gates by pack
#### Common
- available immediately

#### Rare
- available after 3 reveals in that pack
- or after 1 short session in that pack

#### Epic
- available after 10 reveals in that pack
- or after 2–3 sessions
- or after first meaningful combo milestone

#### Legendary
- available after 20 reveals in that pack
- or after clear pack engagement threshold
- never realistically available in the first few minutes unless via special controlled event

This keeps early flow exciting without making the pack feel empty too fast.

---

# 4. Recommended practical player-experience tuning

## First 5–8 reveals in a pack
Expected experience:
- mostly commons
- maybe 1 rare
- no legendary
- epic unlikely or gated off

## First 15–20 reveals
Expected experience:
- most commons collected
- 1–3 rares found
- maybe first epic
- legendary still feels distant

## 25–40 reveals
Expected experience:
- commons mostly done
- rares mostly underway
- epics become the chase
- legendary becomes possible but still special

## 40+ reveals
Expected experience:
- remaining items are mostly epic/legendary gaps
- pity systems start doing real work
- progression feels deliberate, not random

---

# 5. Duplicate handling

Claude should never let duplicates feel like “nothing happened.”

## Recommended duplicate behavior
When a player gets a duplicate collectible:
- award coins
- award soft-currency shards
- increase pity meter slightly
- optionally award progression toward a guaranteed rare/epic roll

## Suggested duplicate rewards by rarity
- duplicate common → small coin reward
- duplicate rare → medium coin reward + pity boost
- duplicate epic → larger reward + rare/epic token fragment
- duplicate legendary → prestige duplicate reward or convert to premium collectible shard

This reduces frustration and makes repeated play still feel useful.

---

# 6. Pity system recommendations

Claude should implement pity at multiple levels.

## A. Rare pity
Guarantee at least one rare within:
- every 6–8 reveals without a rare+

### Recommended setting
- guarantee rare if no rare or better after 7 reveals

---

## B. Epic pity
Guarantee an epic within:
- every 18–22 reveals without an epic+

### Recommended setting
- guarantee epic if no epic or legendary after 20 reveals

---

## C. Legendary pity
Guarantee a legendary within:
- every 45–60 reveals without a legendary in that pack

### Recommended setting
- guarantee legendary if no legendary after 50 reveals in that pack

This is long enough to preserve prestige, but short enough that committed players don’t quit.

---

# 7. Soft pity ramping

Claude should not only hard-guarantee.  
Claude should also increase the chance gradually before the guarantee point.

## Example legendary soft pity
If no legendary has dropped in a pack:
- reveals 1–24: use base legendary odds
- reveals 25–34: increase legendary chance slightly
- reveals 35–44: increase again
- reveals 45–49: noticeably higher
- reveal 50: guaranteed legendary

This makes the system feel fairer and less abrupt.

## Example epic soft pity
If no epic/legendary:
- reveals 1–10: normal
- reveals 11–15: slight increase
- reveals 16–19: stronger increase
- reveal 20: guaranteed epic

---

# 8. Recommended tuning table

## Global recommended pack-based pity settings

| Rarity | Base Odds | Unlock Gate | Soft Pity Starts | Hard Pity |
|---|---:|---:|---:|---:|
| Common | 68% | immediate | n/a | n/a |
| Rare | 22% | 3 reveals | 5 reveals | 7 reveals |
| Epic | 8% | 10 reveals | 14 reveals | 20 reveals |
| Legendary | 2% | 20 reveals | 25 reveals | 50 reveals |

Claude should treat these as default config values and make them data-driven for tuning.

---

# 9. Session-based tuning boosts

Claude should make the system feel better for engaged players without being obviously manipulative.

## Suggested session bonuses
### Session streak bonus
If the player returns multiple days:
- slightly improved rare chance
- slight pity acceleration
- or guaranteed “boosted reveal” token

### Long-session bonus
If a player stays engaged longer in a session:
- slightly better reveal odds after milestone actions
- or bonus reveal meter fill

### Combo bonus
Higher combos can slightly influence:
- rare chance
- epic chance
- special reveal likelihood
- collectible shard bonus

Important:
Do not make combo skill the only path to good drops. Casual players still need a fair route.

---

# 10. Rewarded ad boost design

Rewarded ads are useful, but they should feel optional and fair.

## Good rewarded boosts
Claude can offer:
- +1 boosted reveal
- increased rare/epic chance for next reveal
- pity meter boost
- extra roll after reveal
- duplicate reward multiplier

## Avoid
- locking normal fun behind ads
- requiring ads for legendaries
- making free path feel bad

### Recommended rewarded boost tuning
- next reveal: +8% rare, +3% epic, +0.5% legendary
- or +1 pity step on epic/legendary tracks
- or one extra reveal roll using boosted odds

---

# 11. Paid bundle fairness

Claude should keep premium offers attractive but not predatory.

## Good premium bundle ideas
- guaranteed rare starter bundle
- guaranteed epic seasonal pack
- cosmetic bundle with bonus reveal token
- no ads + reveal token bundle

## Important
Do not sell direct legendary access too early.
Legendary items should retain prestige.

Possible exception later:
- event-limited legendary path that still requires gameplay

---

# 12. Anti-completion protection

Claude should actively prevent the collection from being finished too fast.

## Rules
- no legendary in first short play burst unless explicitly event-controlled
- epics should not flood early
- duplicates should appear naturally once commons are partly collected
- late-game should narrow down into rare/epic/legendary chase
- each pack should have its own progression curve

---

# 13. Pack-specific tuning flavor

Claude can vary the feel slightly by pack.

## Squishy Foods
Design feel:
- friendliest onboarding pack
- slightly more generous early commons/rares
- cozy and welcoming

### Suggested tuning
- easier first rare
- smoother early unlock pace

## Goo & Fidgets
Design feel:
- slightly more combo-reactive
- more skill-linked reveal excitement

### Suggested tuning
- stronger combo-based bonus influence

## Creepy-Cute Creatures
Design feel:
- slightly more mysterious
- stronger long-tail chase

### Suggested tuning
- rare/epic reveals feel more surprising
- legendary feels most prestigious here

---

# 14. Example config model

Claude should make this tunable via JSON or config data.

Example structure:

```json
{
  "rarityConfig": {
    "common": {
      "baseOdds": 0.68
    },
    "rare": {
      "baseOdds": 0.22,
      "unlockAfterReveals": 3,
      "softPityStart": 5,
      "hardPity": 7
    },
    "epic": {
      "baseOdds": 0.08,
      "unlockAfterReveals": 10,
      "softPityStart": 14,
      "hardPity": 20
    },
    "legendary": {
      "baseOdds": 0.02,
      "unlockAfterReveals": 20,
      "softPityStart": 25,
      "hardPity": 50
    }
  }
}
```

Claude should support pack overrides as needed.

---

# 15. Instrumentation requirements

Claude should log enough analytics to tune this system after launch.

## Required events
- reveal_started
- reveal_completed
- rarity_awarded
- duplicate_awarded
- pity_counter_incremented
- pity_counter_triggered
- boosted_reveal_used
- ad_boost_accepted
- ad_boost_declined
- pack_progress_updated
- first_epic_found
- first_legendary_found

## Required parameters
- pack_id
- session_id
- reveal_index_in_pack
- rarity_awarded
- was_duplicate
- rare_pity_count
- epic_pity_count
- legendary_pity_count
- combo_count
- was_boosted
- days_since_first_open

---

# 16. KPI expectations

Claude should help tune toward these experiential outcomes:

## Healthy signs
- players unlock multiple commons early
- rares appear often enough to feel exciting
- epics feel memorable
- legendarys feel prestigious but attainable
- duplicate frustration stays low
- pack completion stretches across multiple sessions

## Warning signs
- most of the collection is unlocked in one round
- players stop after commons dry up
- no epic appears for too long
- legendary chase feels hopeless
- duplicates feel worthless
- rewarded boosts feel mandatory

---

# 17. Recommended launch defaults

Claude should start with these defaults:

## Launch tuning defaults
- Common: 68%
- Rare: 22%
- Epic: 8%
- Legendary: 2%

## Unlock gates
- Rare after 3 reveals
- Epic after 10 reveals
- Legendary after 20 reveals

## Hard pity
- Rare: 7
- Epic: 20
- Legendary: 50

## Soft pity
- Rare starts at 5
- Epic starts at 14
- Legendary starts at 25

These are strong initial production values for beta tuning.

---

# 18. Final directive for Claude

Implement the reveal economy so that:
- early progression feels generous
- mid-game becomes a chase
- late-game becomes prestige
- duplicates still matter
- luck is softened by pity
- paid and ad boosts feel optional, not required

The player should never feel:
- “I already got everything”
or
- “I’ll never get the good stuff”

The target feeling is:
rewarding, fair, exciting, and hard to fully complete.
