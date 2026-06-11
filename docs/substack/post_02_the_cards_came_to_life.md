# The Night My Trading Cards Became 3D Models

*48 characters, one overnight batch, zero modeling skills — and the 7-day ban that came with it.*

---

I want to start with the timing, because it's the part I still don't quite believe:

**It took about three minutes per character to turn a flat trading card into a fully textured 3D model. All 48 characters ran overnight while I slept.**

For context: a single character model from a freelance 3D artist runs $50–$300, and a 48-character set is the kind of line item that ends indie projects. I checked that pricing months ago, filed it under "someday," and moved on.

Then my daughters changed the requirements.

## How this started

If you read the [$11 picture book post](#), you know the shape of this project: I'm a Spartanburg dad of three girls — twin 8-year-olds and a 6-year-old — building a character universe called **Squishy Smash**. A mobile game on the App Store. Two picture books on Amazon. Forty-eight collectible characters across three pastel packs.

The girls live on Roblox. So this month I started building Squishy Smash *as a Roblox game* — a cozy, kid-safe collector world where you wander three lands and gently squish sleepy friends awake.

And here's the thing about Roblox: it's 3D. My characters weren't.

Everything in the Squishy Smash universe flows from one canonical source — the 48 trading cards. Every card is a finished render: the character, the pose, the lighting, the little scene details. The cards are the *truth*. The books reference them. The game sprites were restyled to match them. But a card is a flat image, and my kids wanted to walk up to Soft Dumpling and pat her on the head.

## The pipeline (it's almost embarrassingly short)

1. **Crop.** A small script crops the hero art out of each card — same window every time, since the cards share a template.
2. **Generate.** Each crop goes to Meshy, an image-to-3D service with an API. About three minutes later: a textured 3D model, with the character's face, blush, and gloss baked in. The script ran all 48 in an overnight batch, four at a time, resumable if anything failed.
3. **Import.** The models land in Roblox as mesh parts, textures already attached. Scale them, face them the right way, done.

That's it. That's the whole thing. The dumpling kept her bamboo steamer. The galaxy dumpling kept its tiny Saturn. The models aren't approximations of the cards — they're the cards, with a third dimension.

I opened the first one expecting the usual AI-pipeline disappointment (see: the five failed pipelines from the last post). Instead I just sat there grinning at a rotating dumpling.

## The part where it went sideways

This is a build-in-public journal, so here's the failure, told straight.

When you upload a 3D model to Roblox, its texture gets extracted and reviewed as a standalone image. A texture file is the model's "skin" unwrapped flat — imagine peeling an orange and pressing the peel onto paper. Out of context, it's abstract islands of color.

One of my 48 textures — scrambled patches of a pink, cream, and blush kawaii character — got auto-flagged by Roblox's moderation classifier as **"Sexual Content."**

My account: **banned for seven days.** Mid-build. For a children's game about hugging dumplings.

I appealed the same morning — and to Roblox's credit, a human looked at it and overturned the ban the same day. Seven-day sentence, served in hours. The remaining models went up afterward the careful way: one upload every eight minutes, each texture eyeballed first.

The lessons are still real, and I'd rather you learn them from my ban than yours:

- **Never batch-upload to a moderated platform.** Trickle one asset at a time, especially at first.
- **Look at every auto-generated file before it leaves your machine.** I reviewed every *model* carefully. I never looked at the unwrapped *textures* — the one artifact a classifier actually reviews.
- Automated moderation reads pink-and-skin-toned abstract shapes the way you'd fear. Plan for it.

The live game stayed up the whole time — my girls kept playing. But for one long morning I thought a children's game about hugging dumplings had cost me my account for a week. That's the honest cost of building on a moderated platform: sometimes you pay it for a texture file you never looked at.

## The unlock I didn't see coming

Here's where it gets interesting, and why this post isn't really about Roblox.

While the ban clock ticks, the 48 models are just... sitting on my disk. And it turns out a 3D model is not a Roblox asset. It's a **brand asset**. The model is the product; everything else is photography.

So I built a photo studio. A scripted one — Blender running headless, no GUI, same camera and lighting rig for every character, tuned once against the original card art until the renders matched the brand look. Now one command photographs any character:

- **360° turntable spins** — short, loopable videos for TikTok and Shorts. Forty-eight characters of content from one render pass.
- **An interactive 3D viewer for the website** — kids can grab Soft Dumpling in the browser and spin her. No squishy brand has that.
- **Real squish animation for the app** — pre-rendered squash-and-wobble frames, so the most satisfying moment in the game gets actual 3D deformation instead of a stretched flat image.
- **Print-resolution renders** — stickers, coloring book covers, future merch.

One overnight Meshy run. Five product surfaces.

## What I'm being honest about

**One.** The 3D textures are a copy of a copy. A model generated *from* a card render is slightly softer than the card itself — especially faces. I tested replacing the app's card art with 3D renders and the answer was no: the originals stay. 3D wins on *motion*, not stills. Knowing where a tool loses is as valuable as knowing where it wins.

**Two.** Image-to-3D worked this well because the source art was strong and consistent. The cards did the hard work months ago. Garbage cards in, garbage models out.

**Three.** Same as last time: the workflow is not the moat. Anyone can point Meshy at a character image next month. The 48 characters, the books, the game, the world my daughters helped build — that's the moat. The models are just the newest door into it.

## What's next

All 48 models are live in the Roblox game now. The 3D viewer goes live on [squishysmash.com](https://www.squishysmash.com). The first turntable spins hit TikTok this week. And the four-player family playtest — three girls, one dad, one shared world — is the real test of the whole Roblox build.

Subscribe if you want to see whether the girls approve the 3D dumpling, and what 48 spinning squishies do for a tiny brand's reach.

Both books are on Amazon:
- *Squishy Smash: Meet the Squishies* — [B0H219KX2X](https://www.amazon.com/dp/B0H219KX2X)
- *Squishy Smash: The Lost Sparkle* — [B0H3QP7ZPH](https://www.amazon.com/dp/B0H3QP7ZPH)

The mobile game is on the [App Store](https://apps.apple.com/us/app/squishy-smash/id6762549537).

Every pop is a hello.

— Chris

*P.S. — Next post gets the side-by-side everyone asks for: the flat trading card next to its 3D model, same character, same steamer basket. The card came first. It always does.*

<!-- DRAFT NOTES (delete before publishing):
- [ ] Fill exact Meshy cost: STATE.md logs ~30 credits/character; confirm plan tier + $ before quoting a number. The "$50-300/character freelance" range is industry-typical; sanity-check before publish.
- [ ] Link the $11 post URL in the second paragraph (placeholder "#").
- [ ] Attach images: card vs 3D hero side-by-side (soft_dumpling), the turntable GIF, contact sheet of all 48 renders, (optional) the redacted ban email screenshot.
- [ ] Appeal resolution is now baked in (granted + lifted same day, 2026-06-10). Confirm the "one upload every eight minutes" trickle detail matches what actually ran before publishing.
-->
