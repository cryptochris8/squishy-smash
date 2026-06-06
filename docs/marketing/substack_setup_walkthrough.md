# Substack Setup Walkthrough — squishysmash.substack.com

Step-by-step claim + setup, designed to be completed in one ~45 min sitting and then leave the post #1 scheduled for 7-9am ET tomorrow.

**You'll need these files staged before you start:**

| Substack field | File | Specs |
|---|---|---|
| Logo / avatar | `assets/substack/logo_512.png` | 512×512, opaque |
| Cover / banner | `assets/substack/cover_banner_1500x500.png` | 1500×500 |
| Post #1 hero / share card | `assets/substack/post01_card_1456x816.png` | 1456×816 |
| Post #1 body | `docs/substack/post_01_the_11_dollar_picture_book.md` | ~1400 words |

---

## STEP 1 — Account + publication creation (5 min)

1. Go to **https://substack.com/signup** (or **substack.com** → "Start writing")
2. Sign up with **chriscam8@gmail.com** — easiest is Google sign-in (it'll auto-fill name, avatar)
3. After signup, Substack drops you in a "Create your publication" flow
4. **Publication name:** `Squishy Smash`
5. **URL / subdomain:** Type `squishysmash` — Substack will tell you immediately if it's taken. If taken (unlikely), fall back to `squishysmashbooks` or `chriscampbell`
6. **Author byline:** Click your name in the corner → Account → Profile → set "Name" to **Chris Campbell** (less formal than the book byline — Substack tone is conversational)
7. Skip the "import existing subscribers" step — you have none yet

Done with this step when you see your blank publication dashboard at `squishysmash.substack.com`.

---

## STEP 2 — Branding (10 min)

Go to **Settings → Basics** (gear icon, left sidebar).

### Logo
- Click "Upload" under **Logo**
- Upload `assets/substack/logo_512.png` (the bunny mascot on Squishy pink)
- Substack will crop to square — should fit as-is

### Cover photo / hero
- Scroll to **Cover photo**
- Upload `assets/substack/cover_banner_1500x500.png` (three protagonists under the sparkle)
- This shows at the top of your publication's home page

### Description / tagline
Two fields here, each with a different role.

**Short description** (the under-title tagline, ~80 chars):
```
Every pop is a hello. — Building a children's IP from the kitchen table.
```

**About** (longer — used for the publication's "About" page and shown to potential subscribers):
```
Squishy Smash is a kids' picture book series + mobile game built by Chris Campbell — a Spartanburg, SC writer with a fiancée and three daughters (twin 8-year-olds and a 6-year-old, who are the in-house test audience).

This newsletter is the build-in-public side of the project. I write about what it actually takes to ship a children's IP from one kitchen table:

- The craft of the books — what works, what doesn't, what costs $11 vs $20K
- The game on the App Store (and now Google Play)
- The strange/wonderful journey of writing for kids who will tell you the truth
- Field notes from local bookstores, libraries, and one very honest 6-year-old

Two books are live now on Amazon:
• Squishy Smash: Meet the Squishies — amazon.com/dp/B0H219KX2X
• Squishy Smash: The Lost Sparkle — amazon.com/dp/B0H3QP7ZPH

The game is at squishysmash.com.

Subscribe to follow the build. Free, infrequent (1-2 posts/week), and the only ask is: tell me what you'd buy next.
```

### Color theme
Settings → Brand colors:
- Primary accent: pick **gold** (#E2A85F) — matches the brand and the wordmark in the share cards
- Or leave Substack default if you'd rather not fuss

### Save Settings → Basics

---

## STEP 3 — Categories + sections (5 min)

### Category (helps Substack put you in their discovery rails)
Settings → Discover → **Category: Books**

Optional secondary: **Family** or **Technology** (only one is allowed in the primary slot; pick Books — it gets you on the BookTok-adjacent rails).

### Sections (optional but recommended)
Settings → Sections. Substack lets you publish into "sections" — subscribers can opt into specific ones. For an IP with multiple verticals this is useful long-term. Create three:

1. **The Craft** — slug `craft` — for production posts ($11 vs $20K, pipelines, etc.)
2. **Field Notes** — slug `field` — for bookstores, libraries, kid-feedback posts  
3. **Drops** — slug `drops` — for new book/game release announcements

You can always add more later. Don't gate any of them — all free.

Post #1 will go into **The Craft**.

---

## STEP 4 — Connect X / Twitter for Notes cross-posting (3 min)

Settings → Account → Connected accounts → **X (Twitter)** → Connect.

Use your existing X handle. This enables one-click cross-posting of Substack Notes to X. Notes is Substack's Twitter-like feature; it's HOW new readers find you. Don't skip this.

---

## STEP 5 — Email-capture widget for squishysmash.com (5 min)

Settings → Embeds → **Subscribe form** → copy the iframe code.

I can wire this into the website next session. For now just save the iframe somewhere or screenshot it. The code looks like:

```html
<iframe src="https://squishysmash.substack.com/embed" width="480" height="320" style="border:1px solid #EEE; background:white;" frameborder="0" scrolling="no"></iframe>
```

---

## STEP 6 — Paste post #1 (15 min)

This is the big one.

1. Click **New post** (top right)
2. **Title:** `The $11 Picture Book`
3. **Subtitle:** `How a Spartanburg dad of three girls made a 40-page kids' book using AI — after five pipelines failed.`
4. **Section:** assign to **The Craft** (from STEP 3)

### Body

Open `docs/substack/post_01_the_11_dollar_picture_book.md` in any markdown viewer (VS Code preview works) and **copy the body** from below the title/subtitle through the end. 

Paste into Substack's body. Substack's editor accepts markdown reasonably well — but verify these specific things after paste:

- **Headings** rendered as proper H2 (not bold paragraph text). Add `##` formatting if it's flat.
- **Bullet points** in "The five pivots" section render as a list (not paragraphs)
- The **Amazon links + YouTube link + App Store link** at the end are live hyperlinks, not plain text

### Hero image
At the top of the post, click "Add image" and upload `assets/substack/post01_card_1456x816.png`. This is the share-card image — Substack uses it as the og:image for X/Reddit/LinkedIn previews.

### SEO / sharing
Substack auto-generates the meta description from the first paragraph. The first sentence is "I want to start with the receipt, because it's the part nobody believes" — that's a strong hook for the X share. Don't change unless you want to.

### Tags (optional)
Add 3-5: `picturebook`, `indieauthor`, `aiart`, `kidlit`, `buildinpublic`

---

## STEP 7 — Schedule for tomorrow 7-9am ET (2 min)

Click the **Schedule** button (next to Publish in the top right). Set:

- **Date:** tomorrow (2026-06-05)
- **Time:** **7:00 AM ET** is the recommended slot — research consensus is morning posts get the best open rates, and East Coast 7am catches Europe in late morning. If you'd rather sleep in, 8:00 AM ET works almost as well.

Set "Send email AND publish to web" (both — default).

After scheduling: Substack will email you 15 min before send confirming it's about to go out. You can still cancel/edit during that window.

---

## STEP 8 — Pre-launch sanity check (3 min)

Before you walk away, open the post **preview** in a private/incognito window (Substack provides a preview URL). Look specifically for:

- Hero image renders at the top
- The "$10.97" number stands out (not lost in body text)
- Hyperlinks all click through correctly
- Mobile preview (Substack shows both) — first 3 paragraphs are readable without scrolling

If anything's off, edit. If clean, you're done. Substack will email it tomorrow morning at 7am ET, then publish to your homepage at the same moment.

---

## After it sends — same day actions

Once the post goes live tomorrow morning:

1. **Cross-post to X** as a thread:
   ```
   I made a children's picture book for $10.97.
   
   The traditional illustration budget for a 40-page book is $3,000 to $20,000.
   
   Here's what 5 AI pipelines (4 failed, 1 worked) taught me about indie kid lit:
   
   [link to Substack post]
   ```
   Pin this tweet for 7 days.

2. **Post on Substack Notes** — short version of the same hook. Notes is internal Substack discovery; even a 2-line note can drive 50-200 new subs from inside the platform.

3. **Reddit** — pick ONE subreddit for first launch:
   - r/picturebooks — angle: "I'm an indie author, here's what 5 AI pipelines taught me"
   - r/IndieDev — angle: "Solo dev shipping book + game in 7 weeks. AMA on the IP-build approach"
   - r/StableDiffusion — angle: "5 pipelines to make a character-consistent picture book. What worked"

   Pick ONE — Reddit cross-posting the same link to multiple subs in a day is a spam signal.

4. **TikTok / Reels** — the match-cut video goes up the SAME day (already built). Caption mentions "the story behind these books is up on Substack today."

5. **Email old contacts** — anyone you've talked to about Squishy Smash gets a personal note today (not a marketing blast). 5-10 individual emails. "Hey, finally writing about this — would love to hear what you think."

---

## What to NOT do on day 1

- Don't enable paid subscriptions on day 1. Start free, build the list, add paid in 3-6 months when you have 500+ subs and a clear "what they'd pay for" thesis.
- Don't post a second piece for at least 5-7 days. Day-1 traffic should focus on ONE post for SEO + share momentum.
- Don't agonize over the design. Substack defaults are fine. Iterate later.
- Don't add custom domain ($50/yr) on day 1. squishysmash.substack.com is the right URL until you cross 1,000 subs.

---

## Cross-references

See `docs/substack/post_01_the_11_dollar_picture_book.md` for the post body. See `assets/substack/` for the prepared assets. See `docs/marketing/press_pitch_emails.md` for the parallel press send going out tomorrow morning.
