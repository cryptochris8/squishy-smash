# Squishy Smash — App Store Listing Draft

Source: derived from the plain-English pitch in memory (`plain_english_pitch.md`). Treat this as a working draft; tighten before paste-into-App-Store-Connect.

---

## App name (≤ 30 chars)

**Squishy Smash** _(13 chars)_

## Subtitle (≤ 30 chars)

Pick one — A/B test in promo creative if unsure:

- **Tap. Squish. Pop. Repeat.** _(25)_  ← recommended primary
- Satisfying ASMR pops & splats _(29)_  ← from kickoff brief, strong "satisfying" search alignment
- ASMR for your fingers _(22)_
- Squish, pop, splat, share. _(26)_
- 60 seconds of satisfying. _(26)_

## Promotional text (≤ 170 chars, editable without resubmission)

> NEW: 8 dumpling squishables, voice-over reveals, and the mythic Gold Dumplio. Smash, splat, share. The most satisfying 60 seconds in your pocket.

_(149 chars — leaves room to swap in seasonal pack callouts each LiveOps week)_

## Description (≤ 4000 chars)

```
Tap. Squish. Pop. Repeat.

Squishy Smash is the satisfying-video feeling, made interactive. Tap a
jelly dumpling, drag your finger across a goo blob, hold down on a
creepy-cute creature — it stretches, jiggles, and finally POPS in a
burst of color, goo splatters, an ASMR squelch, and a buzz in your hand.

You've got 60 seconds. Go.

That's the whole game. No puzzles. No enemies. No story. No way to lose.
Just the satisfying part of a game, with the boring parts cut out.

WHY IT FEELS SO GOOD
• Real squelches, pops, and ASMR voice reactions — not generic blips
• Haptic feedback that's different for every tap, drag, and burst
• Goo splats that stay on screen, particles that fly, screen shake on
  big hits
• A tiny thrill every time a rare, epic, or mythic version appears —
  the arena flashes, a voice goes "oooooh," and you can save the clip
  to share

WHAT'S IN THE BOX
• 48 squishables across 3 themed launch packs (squishy foods, goo &
  fidgets, creepy-cute creatures) plus the Dumpling Squishy Drop
  weekly event pack
• 8 unique arena skyboxes that crossfade on rare reveals
• 4 rarity tiers (common, rare, epic, legendary) — every pack ends
  with one prestige legendary
• Earn most squishies by playing. Optional starter bundle unlocks a
  guaranteed rare for new players who want a quick start.

WHO IT'S FOR
Anyone who watches slime videos, soap-cutting clips, or kinetic-sand
TikToks. Anyone who needs two minutes of brain quiet between meetings,
classes, or scrolls. Anyone who likes things that go pop.

WHAT IT'S NOT
A skill game. A grind. A pay-to-win. A subscription. A platformer. A
strategy game. A roguelike. We didn't build any of that, on purpose.

A stress ball, a slime video, and a claw machine had a baby. Open it
while you wait for coffee. Smash for two minutes. Feel a little better.
Put it down.
```

_(~1,750 chars — well under cap; room to extend with new packs)_

## Keywords (≤ 100 chars total, comma-separated, no spaces after commas)

```
asmr,squish,smash,satisfying,slime,pop,fidget,relax,stress,oddlysatisfying,one tap,jelly
```

_(94 chars including commas — leaves a little room. "oddlysatisfying" is the actual searched compound term, not "oddly satisfying")_

## Screenshot copy

Five-screenshot strategy adopted from the kickoff ASO brief. Each shot
pairs a one-line headline with a clear visual hero — keep text large
and readable on a 6.5" preview thumbnail.

| # | Headline (≤ 32 chars) | Visual direction |
|---|---|---|
| 1 | **SMASH THE SQUISHIEST OBJECTS** | Giant burst moment with bright pastel particles |
| 2 | **POPS, SPLATS, AND ASMR CHAOS** | Close-up of a goo burst with wall decals lingering |
| 3 | **UNLOCK WEIRD NEW PACKS** | Three pack cards (foods, goo, creepy-cute) side by side |
| 4 | **BUILD HUGE COMBOS FAST** | Combo meter at mega tier (lime green) with rapid burst sequence |
| 5 | **SATISFYING INSTANT GAMEPLAY** | Finger interacting with a squishy mid-deform |

Per Apple's spec we need these at 6.7", 6.5", and 5.5" iPhone
resolutions (5 each = 15 total). The overlay copy is the same across
sizes; just re-render at the target resolution.

## App preview video direction

5–15 seconds max. Open with the **biggest burst and best sound** in
the first 0.5 seconds. Do not waste the first 2 seconds on menus or
the logo — App Store auto-plays previews silent and players bail
fast if nothing visual lands. End on a clean burst with a half-beat
of silence (lets the audio breathe in the App Preview audio mix).

## What's New (release notes for v0.2.x)

```
v0.2: Now with sound, soul, and Gold Dumplio.

• 11 ASMR voice-over reveal stingers
• 8 themed arena skyboxes that flash on rare reveals
• Rarity tiers: common, rare, epic, mythic (Gold Dumplio is real)
• 60+ object squish/pop sounds
• Save and share your mythic burst clips
• Performance: skyboxes optimized 55% smaller for faster install
```

## Required URLs

| Field | Value |
|---|---|
| **Support URL** | https://athletedomains.com/squishysmash/support _(needs setup — landing page with email + FAQ)_ |
| **Marketing URL** | _(optional — leave blank for v0.2 launch, add when athletedomains.com/squishysmash exists)_ |
| **Privacy Policy URL** | https://athletedomains.com/squishysmash/privacy _(needs setup — see PRIVACY POLICY TEMPLATE below)_ |

## Category

- **Primary:** Games → Casual
- **Secondary:** Games → Arcade

## Age rating: 4+

Questionnaire answers (all "None"):

| Item | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None _(creepy-cute, not scary)_ |
| Sexual Content & Nudity | None |
| Alcohol, Tobacco, or Drug Use References | None |
| Simulated Gambling | None _(coins earned, never purchased)_ |
| Medical/Treatment Information | None |
| Unrestricted Web Access | No |
| Made for Kids | _Recommend: NO_ — keeps you off the COPPA-compliance hook even though content is kid-safe |

## Privacy Nutrition Label

Until a real analytics sink is wired:

| Category | Answer |
|---|---|
| Data Used to Track You | **None** |
| Data Linked to You | **None** |
| Data Not Linked to You | **None** |

_(All player data — coins, scores, settings — stays on-device via shared_preferences. Nothing leaves the device. The moment Sentry/Firebase is wired in, revisit this and likely add "Diagnostics" under "Data Not Linked to You".)_

---

## Privacy Policy URL — minimum content template

If you don't have one yet, the shortest legitimate privacy policy for an app that collects nothing looks like:

```
Squishy Smash Privacy Policy
Last updated: 2026-04-22

Squishy Smash does not collect, store, or transmit any personal
information. All player progress (coins, scores, settings) is stored
locally on your device via Apple's standard preference system and
never leaves your phone.

The app uses Apple's standard share sheet (UIActivityViewController)
when you choose to share a screenshot of your gameplay. This action
is initiated by you, and the screenshot leaves the app only via the
destination you select (Messages, Mail, Photos, etc.).

We do not use third-party analytics, advertising, or tracking
technologies in the current release.

If this changes in a future version, this policy will be updated and
the App Store privacy nutrition label will be updated to match.

Contact: [your email]
```

Host that as a static page at the Privacy Policy URL above and you're submission-ready on the privacy axis.

---

## Live-ops update note strategy

App Store update notes are one of the few free organic surfaces — use
them to telegraph freshness. Each release note should lead with a
new-content hook (not a bug-fix list).

Recurring slots to surface:

- New squishies in the rotation (which pack, which tier)
- New themed event modifier ("Goo Storm Weekend", "Mythic Hour", etc.)
- New arena skybox or background palette
- New audio/voice/sound packs as they ship
- Performance / haptics improvements when they're player-felt
  ("smoother bursts, snappier combos") — never as the lede

Trending search terms (e.g., a TikTok meme spike) are best surfaced
in update notes + screenshot text, NOT in the static metadata, since
they cool off faster than ASO indexing reacts.

---

## Open questions to resolve before paste-into-ASC

1. **Real support URL + privacy policy URL** — squishysmash.com is now live (Netlify). Need static `/support` and `/privacy` routes. Privacy policy template lives below — copy into a `web/` page or host on Netlify directly.
2. **Subtitle pick** — "Tap. Squish. Pop. Repeat." remains the recommendation; "Satisfying ASMR pops & splats" is the alt for an ad-creative A/B test.
3. **Made for Kids: yes/no** — recommendation: **no** (avoids COPPA review burden; content is still kid-safe regardless).
4. **In-app purchases** — _superseded by v0.7.0+:_ Remove Ads ($2.99) + Starter Bundle ($1.99) are now scaffolded in code. Need to create those products in App Store Connect before submission. Privacy nutrition label needs updating to reflect ad SDK presence (AdMob added in v0.8.0 — non-personalized ads with UMP consent).
