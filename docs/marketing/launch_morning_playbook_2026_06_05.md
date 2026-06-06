# Launch Morning Playbook — 2026-06-05

The Substack post fires at **7:00 AM ET tomorrow.** The first 90 minutes after publish are the highest-leverage window for cross-channel push. Everything you need is pre-written below — paste and send.

**Set an alarm for 7:00 AM ET.** Be at the laptop with coffee by 7:15 AM ET. The full sequence takes ~75 min.

---

## 7:00 AM ET — Substack post auto-publishes

Substack handles this automatically. You'll get a confirmation email saying it's live.

Check the post once on `squishysmash.substack.com` from a fresh browser/incognito to confirm it actually rendered.

---

## 7:15 AM ET — Substack Note (3 min)

Substack Notes is the in-platform Twitter-like feed where new readers find writers. This is the highest-conversion-to-subscribers post you'll make.

In Substack, click **Create → Note** (left sidebar). Paste:

```
I made a children's picture book for $10.97.

Industry baseline: $3,000 to $20,000.

5 AI pipelines failed before the 6th one worked. Wrote the whole journey today — including the four times I almost gave up.

[link to your Substack post]
```

After pasting, **attach the share-card image** (`assets/substack/post01_card_1456x816.png`) by clicking the image icon in the Note composer. The image is the scroll-stopper; don't post the Note without it.

Hit **Post Note.**

---

## 7:30 AM ET — X thread + pin (8 min)

Open X (Twitter). Post the thread below as 7 separate tweets, replying to each previous one.

### Tweet 1 (the hook — this is the one that travels)
```
I made a children's picture book for $10.97.

The traditional illustration budget for a 40-page book is $3,000 to $20,000.

Here's what 5 AI pipelines (4 failed, 1 worked) taught me about indie kid lit.

🧵
```
**Attach the share-card image** to tweet 1.

### Tweet 2
```
Setup: I have three girls (twin 8-year-olds + a 6-year-old) in Spartanburg, SC. They're the test audience for a picture book series I started last year.

Book 2 just shipped on Amazon Monday. Book 1 was May.

Squishy Smash, original IP.
```

### Tweet 3
```
The problem with AI picture books: character continuity.

If Soft Dumpling looks like a slightly different character on every page, kids feel it instantly. Picture books work because every spread is the same world.

5 attempts to crack this.
```

### Tweet 4
```
1. Multi-character LoRA — characters fused into brown bears speaking gibberish
2. FLUX Kontext + painterly LoRA — characters reinterpreted differently each spread
3. Canny ControlNet — silhouettes locked but style flat
4. Depth ControlNet — single spreads worked, batches broke
```

### Tweet 5
```
5. Nano Banana Pro (Gemini 3 Pro Image Preview) with multi-image reference.

Three protagonist refs in, painterly Knight-Owl style locked, 21:9 facing-pair format. Generated 18 character-consistent spreads.

$10.97 total. Book live on Amazon June 2.
```

### Tweet 6
```
Honest about three things:

1. The art isn't "free" — ~80 hours of failed pipelines went into the $11 cost
2. This doesn't replace illustrators, it lowers the indie floor
3. The moat is the IP (Squishy Smash universe), not the workflow
```

### Tweet 7 (the close + CTA)
```
Full write-up — every failure in detail, what worked, what I'd do differently:

[link to Substack post]

The book is on Amazon:
amazon.com/dp/B0H3QP7ZPH

The game is on the App Store:
squishysmash.com
```

### After posting
1. **Pin tweet 1** to your profile (click the "…" on tweet 1 → "Pin to profile"). Leave pinned for 7 days.
2. **Reply to your own thread** later in the day with one more tweet if it gains traction: "Update — [link to read-along YouTube video]" or similar.

---

## 7:45 AM ET — Reddit post, ONE subreddit (10 min)

**Pick ONE** — multi-cross-posting in a day is a spam signal. My recommendation:

### Primary recommendation: r/aiArt
Wide audience, supportive of indie AI use cases, the "5 pivots" angle is exactly what hits there.

### Subject
```
I made a 40-page children's picture book with AI for $11. Here are the 5 pipelines I tried before one worked.
```

### Body
```
Hey r/aiArt — long-time lurker, first real post.

I'm a Spartanburg, SC dad and indie developer who shipped a children's picture book on Amazon last week. The whole interior cost $10.97 in AI generation credits, vs the $3K-20K traditional illustrator budget.

The hard part wasn't generation cost. It was **character continuity across 18 spreads.** If your three protagonist characters look slightly different every page, picture books fall apart.

I tried 5 pipelines before one worked:

1. Multi-character LoRA — failed at character continuity (the characters fused into each other)
2. FLUX Kontext + painterly LoRA two-pass — characters got reinterpreted differently per spread
3. Canny ControlNet — silhouettes locked but style flat
4. Depth ControlNet — single spreads worked, batches broke
5. Nano Banana Pro (Gemini 3 Pro Image Preview) with multi-image reference — solved it

The methodology that worked: pass in three protagonist hero shots as references + the existing card art for any cameo character + 21:9 facing-pair format. One prompt per spread, ~$0.60/spread.

I wrote up the full journey (failures + what worked) on my Substack today: [link]

The book itself is here for anyone curious: amazon.com/dp/B0H3QP7ZPH

Happy to AMA about the pipeline, the cost reality, or the indie-publishing implications.
```

### Alternative subreddits if r/aiArt feels wrong
- **r/picturebooks** — angle: "indie author's take on AI tools in picture book production" (more risk — subreddit may have mixed feelings about AI illustration)
- **r/StableDiffusion** — angle: "Character continuity across an 18-spread picture book — what 5 ControlNet/LoRA approaches taught me"
- **r/IndieDev** — angle: "Solo dev shipping book + game in 7 weeks. AMA on cross-product IP-building"

After posting: **stay nearby for 1-2 hours** to answer comments. Reddit threads die without engagement in the first 90 min.

---

## 8:00 AM ET — Press send: 4 emails (20 min)

Open `docs/marketing/press_pitch_emails.md` — every email is paste-ready. Send all four within the same 20-minute window:

1. **Spartanburg Herald-Journal** features desk
2. **Kidding Around Greenville** — `maria@kiddingaroundgreenville.com`
3. **WYFF + WSPA** — via their "Send a Story Idea" forms
4. **Studio SC on SC Public Radio** — via their Contact / Story Ideas form

**Important:** before sending each, replace `(your phone)` in the signature with your actual cell number.

**Attach to each:**
- The 1-page sell sheet (`docs/marketing/sell_sheet_book2.pdf`)
- A link to (not attachment of) the print-res author photo
- Amazon links + YouTube read-along link in the body

**Do NOT attach the match-cut video to print/radio pitches** — only TV (WYFF/WSPA).

---

## 8:30 AM ET — Hub City Bookshop form (10 min)

Open `docs/marketing/hub_city_event_request_draft.md` and submit via the Google Form at:

```
https://docs.google.com/forms/d/e/1FAIpQLSewsAwkkl65G_TcS0EjI6GeT_DdMjK3w8wLH2LU7HJtob78EA/viewform
```

Paste each field's pre-written content. The whole thing takes 10 minutes.

After submitting, screenshot the confirmation page (Google Forms doesn't always email a copy).

---

## 8:45 AM ET — Video uploads (15 min)

Open `docs/marketing/match_cut_video_storyboard.md` for the upload guide. Upload the 22-second match-cut video (`docs/marketing/match_cut_video.mp4`) to:

1. **TikTok** — use the "Squishy Smash" brand account. Add a trending sound (search "Dru meets Gru" first). Caption + hashtags from the storyboard.
2. **Instagram Reels** — cross-post from TikTok's built-in share or re-upload
3. **YouTube Shorts** — title: `Soft Dumpling lives in a book AND a game. 📖➡️📱 #Shorts`
4. **X** — drop as a standalone post, caption: "Soft Dumpling lives in two places now. The book on Amazon. The game on the App Store. Made the whole thing solo in Spartanburg, SC. Every pop is a hello. 💛 [link to Substack]"

---

## ~9:30 AM ET — You're done. Walk away.

Total active time: ~75 minutes.

The launch is now in flight. Don't refresh subscriber counts every 10 minutes — it's terrible for your nervous system and doesn't help anyone. Check in twice today: noon and 5 PM. Reply to any comments / DMs / press responses, then close the laptop.

---

## What to watch over the next 7 days

| When | What | Why |
|---|---|---|
| Day 1 evening | Check email replies from press | Local press sometimes responds same-day if the angle's strong |
| Day 2 | First Substack subscriber stats | Email open rate + click rate, not raw count, is what matters |
| Day 3-5 | Reddit thread followups | If r/aiArt thread got traction, the conversation usually peaks day 2-3 |
| Day 7 | Substack growth chart | Look for the subscriber curve; if flat, post #2 plan adjusts |
| Day 8 | Press follow-up emails | Send the prepared bump emails to any press contacts who haven't replied |
| Day 10 | Books arrive in mail | Inventory check + start consignment drops to Hub City + others |

---

## What NOT to do tomorrow

- Don't change the post copy at 6:55 AM — late edits introduce typos
- Don't post a SECOND piece of content the same day (dilutes the launch signal)
- Don't refresh sub count obsessively (it's evening before you check, period)
- Don't reply to negative comments emotionally — sleep on anything that stings
- Don't extend the Substack section assignment, paid tier setup, or any "wouldn't it be nice if" features. Just ship the launch.

---

## Cross-references

- Substack post body: `docs/substack/post_01_the_11_dollar_picture_book.md`
- Substack assets: `assets/substack/`
- Press pitches: `docs/marketing/press_pitch_emails.md`
- Hub City form draft: `docs/marketing/hub_city_event_request_draft.md`
- Video storyboard: `docs/marketing/match_cut_video_storyboard.md`
- Sell sheet PDF: `docs/marketing/sell_sheet_book2.pdf`
- Match-cut video: `docs/marketing/match_cut_video.mp4`
