# Squishy Smash — Monetization Spec for Claude Code

## Purpose
This document defines the recommended monetization system for Squishy Smash.

The goal is to maximize:
- player retention
- player satisfaction
- revenue per user
- lifetime value
- fairness
- App Store friendliness

without damaging the core fantasy of the game:
- satisfying
- tactile
- relaxing
- collectible
- replayable

This spec is designed for a casual mobile game with:
- optional collection chase
- reveal-based rewards
- themed content packs
- strong potential for rewarded ad monetization
- long-term cosmetic/content expansion

---

# 1. Core monetization strategy

## Recommended launch monetization model
Launch Squishy Smash with:

1. Rewarded ads
2. One-time Remove Ads purchase
3. Low-priced starter bundle
4. Optional consumable currency/reveal boosts later
5. Cosmetic and themed premium bundles later

## Strategic principle
Do not make monetization feel aggressive.

The game should never feel like:
- an ad machine
- pay-to-win
- frustrating by design
- a forced monetization funnel

It should feel like:
- fun first
- rewarding to play for free
- convenient to pay
- exciting to collect
- fair to spend on

---

# 2. Recommended launch monetization stack

## A. Rewarded Ads
This should be the main ad monetization mechanic at launch.

### Why
Rewarded ads are opt-in and fit the game much better than forced interruptions.

### Good rewarded ad use cases
Claude should support rewarded ads for:
- boosted reveal odds on next drop
- extra coins
- pity meter boost
- duplicate conversion bonus
- mission reroll
- extra reveal roll
- bonus collection progress shard
- second chance after a near-miss moment

### Important rules
- rewarded ads must always be optional
- rewarded ads should feel helpful, not required
- do not gate core fun behind watching ads
- do not make legendary collection feel impossible without ads

---

## B. One-time Remove Ads purchase
This should exist at launch.

### Product type
- Non-consumable purchase

### What it should do
- remove forced/interstitial ads if any are used
- preserve the option to watch rewarded ads voluntarily
- optionally add a small premium perk like daily bonus coins or one free boosted reveal per day

### Why
This is a proven simple monetization path for casual mobile games.
It gives players a clean “I like this enough to remove friction” option.

### Recommended pricing
Start testing around:
- $2.99
- optionally test $3.99
- possibly $4.99 later if user love is strong

Most likely best starting point:
- $2.99 or $3.99

---

## C. Starter Bundle
This should also exist at or near launch.

### Purpose
Convert highly engaged early players quickly without requiring a large spend.

### Good starter bundle contents
- coins
- one guaranteed rare collectible
- one premium skybox or cosmetic
- one reveal boost token
- optionally Remove Ads discounted bundle later

### Recommended pricing
- $1.99
or
- $2.99

### Best initial approach
Start simple:
- Starter Bundle = $1.99
- includes:
  - coins
  - guaranteed rare
  - one cosmetic bonus

---

# 3. Monetization systems to add later

## A. Consumable coin packs
These can come after core retention is proven.

### Good use cases
- cosmetic unlocks
- collection boosts
- pack rerolls
- reveal bonus tokens

### Recommended pack ladder later
- Small coin pack
- Medium coin pack
- Large coin pack

Do not overbuild this at launch.

---

## B. Themed premium bundles
Excellent fit for Squishy Smash later.

### Examples
- Cozy Foods Pack
- Galaxy Goo Bundle
- Spooky Cute Bundle
- Holiday Reveal Pack

### Good contents
- exclusive cosmetic variant
- themed skybox
- sound pack
- reveal boost tokens
- collection bonus shard

These are better for this game than heavy pay-to-win systems.

---

## C. Optional premium voice packs
A strong future monetization path using ElevenLabs content.

### Examples
- Cozy whisper announcer
- Sleepy ASMR pack
- Playful hype pack
- Mischievous spooky pack

Important:
Keep voice packs optional and cosmetic-feeling.

---

## D. Seasonal event bundles
Great post-launch monetization path.

Examples:
- Halloween pack
- Holiday sweets pack
- Summer squish pack
- Galaxy goo event pack

This is where the game can grow revenue without harming fairness.

---

# 4. Ad strategy recommendations

## Recommended ad priority
### Launch
1. Rewarded ads
2. Remove Ads IAP
3. Very limited interstitial testing only if necessary

### Strong recommendation
Avoid aggressive interstitial usage at first.

Why:
The game’s brand is satisfying and collectible.
Too many forced ads will:
- hurt retention
- hurt ASMR/game feel
- reduce session quality
- create frustration
- lower long-term conversion

If interstitials are used, they should be:
- sparse
- carefully timed
- never after every reveal
- never during strong momentum

---

## Best interstitial rules if used at all
Claude should enforce:
- never show on first session
- never show before first major reveal
- never show after every round
- use frequency caps
- only trigger at natural stopping points

### Possible safe interstitial moments
- after multiple sessions
- after a completed run/challenge
- after leaving a reward screen
- not during strong momentum

---

# 5. Recommended launch SKU map

Claude should support this initial store structure:

## Launch SKUs
### Non-consumable
- remove_ads

### Starter offer
- starter_bundle_v1

### Optional future consumables
- coins_small
- coins_medium
- coins_large
- boosted_reveal_token_pack
- epic_shard_pack

### Optional future cosmetics
- premium_voice_pack_cozy
- premium_voice_pack_spooky
- skybox_bundle_galaxy
- theme_bundle_holiday

---

# 6. Best pricing recommendations

## Launch pricing recommendation
### Remove Ads
- $2.99 starting test
- backup test: $3.99

### Starter Bundle
- $1.99
or
- $2.99

### Future premium bundles
- $2.99–$5.99 depending on content depth

### Future coin/reveal consumables
Keep entry pricing approachable:
- $0.99
- $1.99
- $4.99
- $9.99 ladder later if needed

---

# 7. Free player fairness rules

Claude should preserve a strong free-player experience.

## Required fairness principles
- core gameplay must be enjoyable without paying
- collection progress must be possible without paying
- rare items must still be possible without spending
- rewarded ads must help, not gate
- paid users get convenience, speed, cosmetics, or comfort
- paid users should not completely bypass the soul of the game

### Target feeling for free users
“I can enjoy and progress in this game.”

### Target feeling for paying users
“I’m getting convenience, personalization, and smoother progression.”

---

# 8. Best monetization loop for Squishy Smash

The ideal loop is:

1. player enjoys core squishing
2. player starts collecting
3. player wants more reveals / better odds / more comfort
4. player sees optional rewarded ads
5. player either watches ads or buys convenience
6. player eventually buys Remove Ads or a Starter Bundle
7. later they buy themed cosmetics/bundles

This is much healthier than:
- overwhelming players with forced ads
- trying to sell too much too early
- making the game feel manipulative

---

# 9. Claude implementation priorities

## P0 Monetization
Claude should implement first:
1. rewarded ad placements
2. Remove Ads non-consumable
3. Starter Bundle
4. duplicate reward economy
5. monetization analytics events

## P1 Monetization
Claude should implement next:
1. boosted reveal consumables
2. cosmetic bundle support
3. pack-specific premium offers
4. optional daily bonus for Remove Ads owners

## P2 Monetization
Claude should implement later:
1. premium voice packs
2. seasonal premium events
3. larger coin ladders
4. offer personalization
5. win-back offers

---

# 10. Analytics requirements

Claude should log monetization behavior clearly.

## Required events
- ad_reward_offer_shown
- ad_reward_offer_accepted
- ad_reward_offer_declined
- rewarded_ad_completed
- remove_ads_viewed
- remove_ads_purchased
- starter_bundle_viewed
- starter_bundle_purchased
- shop_opened
- shop_item_viewed
- shop_item_purchased
- paywall_closed
- duplicate_reward_granted
- reveal_boost_used

## Recommended parameters
- placement
- session_number
- pack_id
- collection_progress_percent
- combo_count
- rarity_context
- price
- currency
- was_first_purchase
- days_since_install

---

# 11. Best timing for monetization prompts

Claude should avoid showing monetization prompts too early or too aggressively.

## Good moments to present offers
- after player experiences satisfying core loop
- after first rare reveal
- after duplicate frustration moment with helpful alternative
- after collection interest is obvious
- after player voluntarily engages with rewards
- after multiple sessions, not instantly

## Bad moments
- before core fun is felt
- before first reveal
- during intense flow
- after every loss or every round
- during onboarding overload

---

# 12. Suggested starter bundle trigger logic

Claude can show the Starter Bundle when:
- player has completed first few reveals
- player has shown collection interest
- player has seen at least one rare
- player has played enough to understand the value

Good trigger example:
- after first rare reveal + collection screen visit

This makes the offer feel relevant, not random.

---

# 13. Suggested Remove Ads upsell logic

Claude can show Remove Ads when:
- player has seen enough ads to understand the value
- player has returned for multiple sessions
- player is clearly engaged

Do not hard-sell too early.

Possible helpful framing:
- “Love Squishy Smash? Remove ads and keep the squish flow smooth.”

Optional bonus:
- include tiny daily perk for purchasers

---

# 14. Duplicate-based monetization opportunity

Since duplicates are inevitable, Claude should use them intelligently.

## Free path
Duplicates convert into:
- coins
- shards
- pity progression

## Paid/boost path
Optional purchases or rewarded boosts can:
- increase duplicate conversion rate
- grant extra reveal roll
- give reroll token
- give boosted reveal chance

This makes duplicates less frustrating and monetizable in a player-friendly way.

---

# 15. What Claude should avoid

Claude should avoid:
- aggressive interstitial spam
- monetization before the player feels the core magic
- too many shop currencies
- selling direct legendary access too early
- making rewarded ads feel mandatory
- making Remove Ads the only monetization path
- subscriptions at launch unless the content cadence becomes very strong later

---

# 16. Recommended launch monetization summary

## Best launch model
- Free core game
- Rewarded ads for optional boosts
- Remove Ads one-time purchase
- Starter Bundle low-cost conversion offer

## Best initial prices
- Remove Ads: $2.99
- Starter Bundle: $1.99 or $2.99

## Best future expansion
- premium cosmetic bundles
- seasonal packs
- voice packs
- reveal boost consumables

---

# 17. Final directive for Claude

Claude should monetize Squishy Smash in a way that protects the game’s identity.

The experience should feel:
- premium
- fair
- satisfying
- collectible
- low-friction

Best launch plan:
1. rewarded ads as primary ad system
2. Remove Ads as one-time non-consumable
3. low-priced Starter Bundle
4. cosmetics and premium bundles later

This should produce a monetization system that earns money without breaking the squish flow.
