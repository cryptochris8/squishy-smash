# Squishy Smash — Google Play Console Submission Pack

Copy-paste-ready text for Google Play Console. Adapted from the iOS
App Store pack (`docs/app_store_submission_copy.md`) and trimmed to
fit Play's character limits.

Generated 2026-06-03 alongside the first signed AAB.

---

## App name

```
Squishy Smash
```

*(50 char limit on Play — currently 13)*

---

## Short description

```
Every pop is a hello. 48 squishy friends to find through play, milestones, or coins.
```

*(80 char limit — currently 80 exactly. This is the line shown in
search results and the "more apps" rail. Make it count.)*

**Alternative (76 chars):** `Tap, squish, and collect 48 adorable squishies — pure ASMR satisfaction.`

---

## Full description

```
Every pop is a hello. Every hello comes back.

Squishy Smash is a soft, satisfying tap-to-pop game starring 48 squishy characters — dumplings, goos, and creepy-cute creatures who only show up when you find them.

WHAT IT FEELS LIKE
Tap to squish. Drag to stretch. Hold to crush. Every squishy reacts with its own juicy ASMR-flavored crunch, splat, or wobble — chosen to sound like the kind of thing you'd watch a TikTok video of for no real reason.

THE COLLECTION
48 hand-illustrated cards across three themed packs:
• Squishy Foods — dumplings, mochi, jelly buns, glittery sweets
• Goo & Fidgets — stress orbs, jelly pads, plasma blobs
• Creepy-Cute Creatures — bunnies, ghosts, fang critters, plush familiars

Plus a hidden Keepsakes section for personal/family cards.

THREE WAYS TO UNLOCK
Every card has three independent paths:
• Find them through play — pop the matching squishy a few times
• Save coins and pick the one you want
• Achievement rewards — streaks, combos, milestones grant bonus cards

A kid who hates grinding can save up. A kid who hates spending can grind. The album fills either way.

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

Squishy Smash is a fidget toy you can keep in your pocket. It will not save the world. It will just feel nice.

Every pop is a hello. Every hello comes back.

Free. Forever offline-friendly. No log-ins, no follow buttons.
```

*(4,000 char limit — currently ~1,850. Same body copy as iOS for
brand consistency.)*

---

## App category

- **Type:** Game
- **Category:** Casual
- **Tags (max 5):** Casual, Family, Collection, Cute, Relaxing

---

## Content rating

Run the IARC questionnaire in Play Console. Expected answers:

| Question | Answer |
|---|---|
| Violence | None |
| Sexuality | None |
| Language | None |
| Controlled substances | None |
| Crude humor | None |
| Gambling | None — no real-money chance mechanics |
| User-to-user communication | No |
| Personal info shared | No |
| Location shared | No |
| Digital purchases | Yes (scaffolded; not active in current build) |
| Mature/realistic content | No |

**Expected result:** Everyone / 3+ across all regions (PEGI 3, ESRB Everyone, USK 0, etc.)

---

## Target audience and content

**Target age groups (multi-select):** Ages 13+ AND 18+

**IMPORTANT — do NOT check "Ages 5 and Under" or "Ages 6–8" or "Ages 9–12".** Per `project_app_store_category.md`, the deliberate decision is to ship in the general Casual category and stay OUT of the "Designed for Families" / "Made for Kids" program. Reason: it limits monetization options (no contextual ads in the future, stricter data rules) and forces COPPA-strict treatment even though the content is family-friendly.

If Play asks "Does your app unintentionally appeal to children?" — answer **No**. The game is designed to appeal to ALL ages but is targeted at teens and adults seeking ASMR satisfaction; it just happens to be family-safe.

---

## Data safety form

Play Console → App content → Data safety.

**For the AAB built 2026-06-03 (no `--dart-define=SENTRY_DSN`):** Sentry is compiled in but inactive — no DSN means no network calls. Answer:

| Section | Answer |
|---|---|
| Does your app collect or share any user data? | **No** |

That's the entire form. Submit and move on. No follow-up questions.

**If a future build IS shipped with Sentry DSN active**, change the answer to "Yes" and fill the table below:

| Section | Answer |
|---|---|
| Does your app collect or share any user data? | **Yes** |
| Is all data encrypted in transit? | **Yes** (Sentry uses HTTPS) |
| Can users request data deletion? | **Yes** (data is locally stored; clearing app data deletes everything) |

The only data type collected with Sentry active is:

| Data type | Collected? | Shared? | Required? | Purpose |
|---|---|---|---|---|
| Crash logs | Yes | Yes (with Sentry) | No (optional) | App functionality |
| Diagnostics | No | — | — | — |
| Performance | No (tracesSampleRate disabled) | — | — | — |
| Personal info | No | — | — | — |
| Location | No | — | — | — |
| Financial info | No | — | — | — |
| Messages | No | — | — | — |
| Photos/videos | No | — | — | — |
| Audio | No | — | — | — |
| Files | No | — | — | — |
| Calendar / Contacts | No | — | — | — |
| App activity | No | — | — | — |
| Web browsing | No | — | — | — |
| Device IDs | No | — | — | — |

If Sentry DSN is NOT compiled into this release, answer the first question "No" — simplest, fastest review path.

---

## Privacy Policy URL (REQUIRED for all apps)

```
https://squishysmash.com/privacy
```

If the custom domain isn't live yet, use the Netlify default:
```
https://[your-netlify-subdomain].netlify.app/privacy
```

The page already exists at `website/public/privacy.html`. Same URL Apple accepted.

---

## App access

**Is all functionality available without restriction?** Yes.
- No login or account required
- No region locks
- No in-app paywalls blocking core features

If Play asks for test credentials → "Not applicable, the app opens directly to the main menu."

---

## Ads

**Does your app contain ads?** No.

Even if Sentry is enabled, Sentry is NOT advertising; it's crash reporting. Do not check the ads box.

---

## In-app purchases

**Does your app offer in-app purchases?** 

- v1.x — **No** (IAP scaffolding is present but disabled)
- Future versions — **Yes** when IAP is activated; products will mirror App Store IDs

If you check "Yes," Play asks for a starting price range — pick "Free items only" if all purchases are gated as add-ons, or set the lowest planned price.

---

## Store listing — graphic assets

All built in this branch; located at `assets/google_play/`:

| Asset | Spec | Built? | Source |
|---|---|---|---|
| **App icon** | 512×512 PNG, 32-bit, opaque | ✅ `icon_512.png` | `website/public/icon-512.png` + brand pink fill |
| **Feature graphic** | 1024×500 PNG/JPG, opaque | ✅ `feature_graphic_1024x500.png` | `assets/website_hero/pack_squishy_foods.png` + wordmark |
| **Phone screenshots** | 16:9 or 9:16, 320–3840 px long edge | ✅ 10 in `screenshots/` | iOS captioned shots padded to 9:16 |
| **Tablet 7"** screenshots | Optional | ❌ Skip for v1 | — |
| **Tablet 10"** screenshots | Optional | ❌ Skip for v1 | — |

---

## What's New (release notes for first Play submission)

```
Squishy Smash on Android — first release!

Tap. Squish. Collect. Every pop is a hello.

• 48 hand-illustrated cards across 3 themed packs
• Three unlock paths: play, achievements, or save coins
• Cozy menu music + round timer + vivid rare effects
• No ads, no accounts, fully offline
• Built for families

Thanks for squishing! 💕
```

*(500 char limit — currently 350. Keep it warm + brand-consistent.)*

---

## Submission walkthrough (Play Console)

Once everything above is uploaded and forms are filled:

1. **Internal testing first** (Release → Internal testing → Create release)
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Add yourself + 1-2 testers to the email allowlist
   - Hit "Review and roll out" — internal testing has no review wait
   - Install via the opt-in link and validate one full play loop on a real Android device

2. **Production release** (Release → Production → Create release)
   - Same AAB or a "promote to production" from internal
   - First-time apps get a manual review (~3-7 days) plus an age-rating delay
   - Subsequent updates often clear in <24 hours

3. **App content checklist** (must be 100% green before submit)
   - Privacy Policy ✅
   - App access ✅
   - Ads ✅
   - Content rating ✅
   - Target audience and content ✅
   - News apps ✅ (No)
   - COVID-19 contact tracing ✅ (No)
   - Data safety ✅
   - Government apps ✅ (No)
   - Financial features ✅ (No)
   - Health ✅ (No)

---

## Cross-references

- iOS copy pack: `docs/app_store_submission_copy.md`
- Android keystore + signing setup: memory `android-keystore-setup`
- App Store category decision: memory `app-store-category-decision`
- Release versioning: memory `release-versioning`
- Privacy/support pages: `website/public/privacy.html`, `website/public/support.html`
