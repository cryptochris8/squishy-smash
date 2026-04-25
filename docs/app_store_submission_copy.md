# Squishy Smash — App Store Submission Pack

Copy-paste-ready text for App Store Connect submission. Each section
is sized to Apple's character limits as of 2026. Replace the
**[FILL IN]** placeholders before pasting.

---

## App name

```
Squishy Smash
```

*(30 char limit — currently 13)*

---

## Subtitle

```
Squish, pop, collect cards
```

*(30 char limit — currently 26. Pairs verb energy with the collection
hook so the listing reads as both a fidget toy and a collectible.)*

---

## Promotional text

```
48 collectible cards across 3 themed packs. Earn them through play, milestones, or save coins for the one you want — three ways to complete the album.
```

*(170 char limit — currently 156. This field can be updated WITHOUT
re-review, so use it for short-term promo copy. Swap in featured
weeks, holiday events, etc.)*

---

## Description

```
Soft, satisfying, and a little weird in the best way.

Tap to squish. Pop to collect. Every squishy reacts with a juicy
ASMR-flavored crunch, splat, or wobble — chosen specifically because
it sounds like the kind of thing you'd watch a TikTok video of for
no real reason.

THE COLLECTION
48 hand-illustrated cards across three themed packs:
• Squishy Foods — dumplings, mochi, jelly buns, glittery sweets
• Goo & Fidgets — stress orbs, jelly pads, plasma blobs
• Creepy-Cute Creatures — bunnies, ghosts, fang critters, plush familiars

Plus a hidden Keepsakes section for personal/family cards.

THREE WAYS TO UNLOCK
Every card has three independent paths:
• Earn through play — burst the matching squishy a few times
• Save coins and buy it — scaled prices reward real saving
• Achievement rewards — streaks, combos, milestones grant bonus cards

Pick whichever feels right. A kid who hates grinding can save up.
A kid who hates spending can grind. The album fills either way.

BUILT FOR FAMILIES
• No ads in the core loop
• No accounts required
• Local save only — your progress lives on your device
• Haptics, mute, and accessibility toggles
• Brief, calm sessions — perfect for the in-between

WHAT MAKES IT FEEL GOOD
• Real squash-and-stretch deformation (no stiff sprite swaps)
• Particle bursts, splat decals, gentle screen shakes
• Combo meter that rewards rhythm without punishing speed
• Pack milestones — a coin reward every 25% of an album you fill
• Rare reveal moments with their own skybox flash and "whoa" beat

Squishy Smash is a fidget toy you can keep in your pocket. It will
not save the world. It will just feel nice.

Free. Forever offline-friendly. No log-ins, no follow buttons.
```

*(4,000 char limit — currently ~1,750. Plenty of room to add or trim.)*

---

## Keywords

```
squish,asmr,satisfying,tap,pop,mochi,slime,plush,collect,cute,kids,family,fidget,relax
```

*(100 char limit — currently 92. Apple's keyword field excludes the
words in your title and subtitle, so don't repeat "squishy" / "smash"
/ "cards" here.)*

---

## What's New (version 0.1.1)

```
First public release of the collection album!

NEW
• 48 collectible cards across three themed packs
• Three unlock paths: play, achievements, or coin purchase
• Pack-completion milestones — coin rewards at 25 / 50 / 75 / 100%
• Floating reward toasts that celebrate every duplicate burst and milestone you cross
• Hero squishy bobbing on the menu so the title screen feels alive

REBALANCED
• Cards take noticeably longer to fully complete (we played with kids; they were too fast)
• Anti-spam: hammering the same squishy no longer trivializes the economy — the ASMR still pops, but rewards space out
• Coin prices anchored to real session earn rates so saving up actually means something

QUALITY
• In-app diagnostics screen for triaging issues (Settings → Diagnostics)
• Crash reporting via Sentry on real release builds
• Bundled fonts so the typography lands even on a fresh first launch
```

*(4,000 char limit — used room for both feature highlights and the
"why we changed it" beat that humanizes the patch notes.)*

---

## Category

- **Primary:** Games > Casual
- **Secondary (optional):** Games > Family

---

## Age rating

**4+** — no objectionable content, no in-app ads, no user-to-user
communication, no web browser, no third-party tracking. The IAP
section is currently scaffolded but not active in v0.1.1.

When the App Store Age Rating questionnaire asks:

| Category | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Gambling and Contests | None |
| Unrestricted Web Access | No |
| User Generated Content | No |

Result: **4+**

---

## Support URL

```
[FILL IN — e.g. https://squishysmash.app/support  or a GitHub Issues page]
```

Apple requires a working URL. Easiest options:
- A simple page on your existing domain (if you have one)
- A GitHub Issues page on the public repo
- A Notion / Linktree page with an email contact

---

## Marketing URL (optional but recommended)

```
[FILL IN — e.g. https://squishysmash.app]
```

Point this at the marketing website I'm enhancing in parallel.

---

## Privacy Policy URL (REQUIRED)

```
[FILL IN — must be a working URL]
```

Apple requires this even for offline games. Quick path: a single-page
privacy policy hosted on Netlify or your domain. Suggested content:

> Squishy Smash does not collect, store, or transmit any personally
> identifiable information. Game progress and settings are saved
> locally on your device and never leave it. Optional crash reports
> may be sent via Sentry to help us fix bugs; these reports include
> error stack traces and device model but no personal data.

Save that as `privacy.html`, host on Netlify, paste the URL.

---

## Privacy "Data Collection" questionnaire

App Store Connect → App Privacy section. Answer:

| Question | Answer |
|---|---|
| Does your app collect data? | **Yes** (Sentry crash reports only) |
| Diagnostics → Crash Data | Linked to: NO. Used for: App Functionality |
| Diagnostics → Performance Data | NOT collected (we disabled `tracesSampleRate`) |
| Identifiers / Contact Info / Health / Browsing History | NOT collected |

If you decide to ship without Sentry-DSN configured for v0.1.1,
answer "Does your app collect data?" → **No**, which is the simplest
path.

---

## Screenshots

Apple as of 2026 accepts **6.7"** or **6.9"** display-class screenshots
and uses them for all sizes. Submitting 6.9" is the safest current
default — covers everything.

### Required dimensions

| Display class | Pixels (portrait) | Devices |
|---|---|---|
| **6.9"** (preferred) | 1320 × 2868 | iPhone 16 Pro Max |
| **6.7"** (alternate) | 1290 × 2796 | iPhone 15/16 Plus, 14/15/16 Pro Max |

If App Store Connect prompts for additional sizes, also provide:
- **6.5"**: 1242 × 2688 (iPhone 11 Pro Max, XS Max)
- **5.5"**: 1242 × 2208 (iPhone 8 Plus — rare in 2026)

### Captures to take (6 minimum, 10 max)

Take all from a real iPhone running a TestFlight build. Hide the
debug banner if your build is debug — release builds don't show it.

#### 1. Menu / Title (the launch impression)
**Caption overlay:** *"Tap. Squish. Collect."*
- Show the SQUISHY SMASH title, the bobbing Celestial Dumpling
  Core mascot, the four colored buttons, the coin badge.
- Take it on a fresh-install profile so it shows 0 coins (signals
  "you start from zero").

#### 2. Mid-burst gameplay (the satisfying moment)
**Caption overlay:** *"Squish. Pop. Splat."*
- Time the screenshot for the frame just after a squishy bursts —
  particles flying, decal landing, score ticking up, combo meter
  pulsing.
- Pick a Mochi or Dumpling (warmest visuals).

#### 3. Mythic reveal (the "whoa" moment)
**Caption overlay:** *"Hunt for the rare ones."*
- Trigger a Legendary burst (you may need to set
  `cardBurstCounts['016/048']: 39` via the diagnostics test
  override, or just play until it happens).
- The screenshot needs the skybox reveal + bloom flash visible.
  This is the single most-different-from-other-tap-games shot.

#### 4. Collection album (the meta-game)
**Caption overlay:** *"48 cards. 3 packs. Three ways to unlock."*
- Show the album with maybe ~12 cards unlocked, the rest as
  silhouettes. Pack filter chips visible.
- The mix of unlocked vs locked communicates "there's more here."

#### 5. Card detail with progress bars (the path forward)
**Caption overlay:** *"Earn through play, achievements, or coins."*
- Tap into a locked Rare card. Show the bottom-sheet with the
  burst-progress bar (e.g., 5/8) and the "BUY FOR 400 COINS"
  button.
- Three-path system in one screen.

#### 6. Pack milestone toast (the "I made progress" beat)
**Caption overlay:** *"Every milestone earns coins."*
- Capture the floating "+100 Pack 50%!" toast mid-animation.
- Hardest one to time — you may need to fake the state via
  diagnostics or replay attempts.

### Optional extra captures

#### 7. Settings + accessibility
**Caption overlay:** *"Built for families."*
- Show haptics, mute, and arena picker. Communicates "no
  predatory monetization, you're in control."

#### 8. Results screen
**Caption overlay:** *"Best score. Best combo."*
- After a strong round — useful for replay-loop framing.

### Tips for the captures

1. **Status bar:** clean it up via Xcode's Simulator → "Override
   Status Bar" or the [QuickTime trick]. iPhone shows full battery,
   strong signal, no notifications.
2. **No debug banner:** make sure you're capturing a release build
   (TestFlight automatically gives you this).
3. **Letterbox-safe:** Apple's screenshots show the full screen
   including the notch / island. Don't trim them.
4. **PNG over JPEG:** Apple accepts both but PNG keeps the WebP
   card art crisp.
5. **One pass per device class:** capture all six on an iPhone 16
   Pro Max (or whatever you have access to). Use the same
   resolution for all uploads to that class.

---

## Submission checklist

Before clicking "Submit for Review":

- [ ] All 6+ screenshots uploaded for the primary display class
- [ ] Description, keywords, subtitle, promo text pasted in
- [ ] Privacy Policy URL working (test in incognito)
- [ ] Support URL working
- [ ] Age rating questionnaire complete → 4+
- [ ] Privacy "Data Collection" questionnaire complete
- [ ] App version, build number match the TestFlight build you're
      promoting (currently v0.1.1 / build 11+)
- [ ] At least one Internal Tester has installed and confirmed the
      build runs (you've done this)
- [ ] Privacy Manifest (`PrivacyInfo.xcprivacy`) is valid in the
      build (already validated in pre-flight tests)
- [ ] App Review notes (optional): explain the no-account, offline
      design so reviewers know what to expect

---

## App Review notes (paste this into the optional notes field)

```
Squishy Smash is an offline single-player tap-to-squish game with a
collectible card album. No account creation, no in-app chat, no
user-generated content, and no third-party advertising. All player
progress is stored locally via SharedPreferences. Optional crash
reporting via Sentry is gated on a build-time flag and contains no
personal information.

The game is designed for casual play in short sessions and is suitable
for families with children. There are no purchases enabled in v0.1.1
(the IAP scaffolding is present but disabled).

Test instructions:
1. Open the app — title screen with bobbing card mascot appears.
2. Tap PLAY — gameplay starts immediately. Tap or drag squishies to
   pop them. Each round lasts 60 seconds.
3. Tap COLLECTION — see the 48-card album. Tap any card to view
   unlock progress.
4. Tap SHOP — see purchasable packs and arenas (free in this build).
5. Tap SETTINGS → DIAGNOSTICS — view the in-app diagnostic log
   (will be empty unless an error occurred).

No login, no setup, no PII required.
```

---

## What I (Claude) am doing in parallel

Updating the marketing website at `website/` with:
- The 48-card collection gallery
- Updated copy reflecting the v0.1.1 economy + new mascot
- A "What's New" section
- Polish around the Hero, Core Loop, and Collection sections

You'll see commits land on `main` while you're working on this doc.

---

*Generated 2026-04-25. Update this file alongside any future
release.*
