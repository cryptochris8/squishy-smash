# Squishy Smash — App Store Listing Draft

Source: derived from the plain-English pitch in memory (`plain_english_pitch.md`). Treat this as a working draft; tighten before paste-into-App-Store-Connect.

---

## App name (≤ 30 chars)

**Squishy Smash** _(13 chars)_

## Subtitle (≤ 30 chars)

Pick one — A/B test in promo creative if unsure:

- **Tap. Squish. Pop. Repeat.** _(25)_  ← recommended primary
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

WHAT'S IN THE BOX (v0.2)
• 17 squishables across 4 themed packs — squishy foods, goo fidgets,
  creepy-cute creatures, dumplings
• 8 unique arena skyboxes that crossfade on rare reveals
• 4 rarity tiers (common, rare, epic, mythic) including the mythic
  Gold Dumplio
• Earn coins to unlock new packs — no real-money in-app purchases

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

## Open questions to resolve before paste-into-ASC

1. **Real support URL + privacy policy URL** — neither domain page exists yet. ~30 min to set up two static landing pages on athletedomains.com.
2. **Subtitle pick** — "Tap. Squish. Pop. Repeat." is the recommendation; confirm.
3. **Made for Kids: yes/no** — recommendation: **no** (avoids COPPA review burden; content is still kid-safe regardless).
4. **In-app purchases** — currently zero; revenue model is "earn coins by playing." Confirm that's the launch position (vs. adding a pack-unlock IAP for $0.99).
