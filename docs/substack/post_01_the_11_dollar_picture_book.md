# The $11 Picture Book

*How a Spartanburg dad of three girls made a 40-page kids' book using AI — after five pipelines failed.*

---

I want to start with the receipt, because it's the part nobody believes:

**Total spend to produce the interior art for my second picture book: $10.97.**

A traditional picture book illustration budget runs **$3,000 to $20,000**. That's not a typo. That's the range a publisher quotes a working illustrator for a 32-to-40 page book in 2026 — and it's why most indie picture book authors never make it past Book 1.

I'm not posting this to gloat about cost. I'm posting because the *journey* to that number is what made it possible — and I think it's worth telling honestly, including the four times I almost gave up.

## How this started

I live in Spartanburg, SC. I have three girls — 8, 8, and 6 — who are the reason any of this exists. They love viral squishy dumpling toys. They love the Needoh squishies at Five Below. They live on Roblox, which I play with them because that's how I learn what's interesting to kids their age. You don't pattern-match from the outside looking in. You sit on the couch at 7pm and let them lead a build.

Last year I started building a mobile game called **Squishy Smash** — tap-to-pop, collect 48 cute characters across three packs. The girls were the focus group. Twin 8-year-olds will not lie to you about what's fun.

The mobile game shipped to the App Store earlier this year. Then I wrote a character compendium book — *Squishy Smash: Meet the Squishies* — and shipped it to Amazon paperback in May. Last week I shipped Book 2, the actual story: *The Lost Sparkle*.

Book 2 is the one this post is about. Because Book 2 almost didn't happen.

## The problem

Here's the thing about picture books that nobody tells you: **the art is everything, and the art has to be consistent.**

If Soft Dumpling looks like a slightly different character on every page — different ears, different blush, different expression — kids feel it instantly. Picture books work because every spread is the same world. Break character continuity and the whole emotional thread snaps.

So I needed 18 full-bleed watercolor spreads. Three protagonist characters. Same character continuity across every page. Same painterly style. Same lighting cosmology.

I was not going to spend $20,000.

I tried to make it work with AI.

## The five pivots

### Pivot 1 — Multi-character LoRA (failed)

The obvious move. Train a custom LoRA on my three protagonists, then generate spreads. I trained one for ~$2 on Replicate.

The output looked like brown bears speaking gibberish. The character features bled together. Triggers fused. The model was confidently producing characters that were not *any* of mine.

Two days lost. Moved on.

### Pivot 2 — FLUX Kontext + a painterly LoRA (failed)

Smarter idea: use one model to lock the silhouette, another to repaint into watercolor.

Two-pass image-to-image. First pass: lock the character pose. Second pass: paint it in Knight-Owl style.

Each pass re-interpreted my characters differently. Soft Dumpling had three ears in one spread, four fingers on a flipper-arm in another. Character continuity across 18 spreads collapsed completely.

Three days. Moved on.

### Pivot 3 — Canny ControlNet (partial)

If the problem is the model reinterpreting silhouettes, lock the silhouettes harder. Canny edge maps from clean character references. ControlNet weight cranked.

This worked for silhouettes. It did not work for *style* — the painterly Knight-Owl watercolor I needed. The output was characters that looked correct but flat, like coloring book pages.

### Pivot 4 — Depth ControlNet (partial)

Same idea, depth maps instead of edges. Better volumetric form. Better lighting transfer.

Worked for single spreads. Broke at batch scale — the color palette drifted, the text overlay placement got weird, the spreads stopped matching as a sequence.

Four pivots in. Sunk cost was ~$80. I was tempted to call it and hire a real illustrator for Book 3.

### Pivot 5 — Nano Banana Pro (it worked)

Google released Gemini 3 Pro Image Preview (internally called "Nano Banana Pro") in late May. It's a multi-modal model that can take **multiple reference images** and generate a new image conditioned on all of them.

The methodology I landed on:

- Pass in three protagonist references (one painterly hero shot each)
- Pass in the existing card art for any cameo character that appears
- Specify 21:9 facing-pair aspect ratio (so two pages of the book read as one continuous spread)
- Write one prompt per spread describing the scene
- Generate, review, accept or reroll

It produced character-consistent painterly spreads. The hero protagonists looked the same on every page. The cameos used the existing card-art references. The 21:9 format meant facing pages flowed continuously across the gutter.

**Total cost across all 18 spreads: $10.97.**

Plus another ~$2 for the cover hero shot.

The book — *The Lost Sparkle* — went live on Amazon paperback on June 2nd.

## What this actually means

I want to be honest about three things, because the AI-picture-book discourse is full of bad takes from both sides.

**One.** The art is not "free." I spent ~80 hours on the pipeline (over five attempts), another ~30 hours on layout, typography, manuscript editing, cover composition, and KDP submission. The dollars went down but the time was real.

**Two.** This does not replace illustrators. Knight-Owl, the painterly style I anchored to, is a real human's work. The model learned from real human painters. What this *does* mean is that the floor for indie picture-book production drops from $20K to ~$11 — which means thousands of stories that would have died at the budget step now get to exist.

**Three.** The moat for me isn't the workflow. Within six months everyone will know how to do this. The moat is the *story*. The Squishy Smash universe — the characters, the cosmology, the game-book-app cross-product — is the durable position. The pipeline was just the gate to get there.

## What's next

Six books are planned in this series. Book 3 (*Bakery Hollow Mystery*) goes deep on the Squishy Foods crew. Books 4 and 5 each do the same for the other two character worlds (Goo Cove and Twilight Thicket). Book 6 brings everyone back together.

The girls are already drawing characters for Book 3 on the kitchen table. I have 15 paperback copies of *The Lost Sparkle* arriving next week — most are going to local Spartanburg bookstores (Hub City is the first call), some to libraries, a couple to schools, two to local press.

This Substack is where I'll document the rest. The good runs and the bad ones. What the bookstores say. What the libraries say. What the girls say when I read them a draft.

Subscribe if you want to follow the build. Or just to see if a solo dad with twin 8-year-olds and a 6-year-old can actually move 1,000 copies of a picture book this summer.

Both books are on Amazon:
- *Squishy Smash: Meet the Squishies* — [B0H219KX2X](https://www.amazon.com/dp/B0H219KX2X)
- *Squishy Smash: The Lost Sparkle* — [B0H3QP7ZPH](https://www.amazon.com/dp/B0H3QP7ZPH)

The free 5:37 read-along is on [YouTube](https://youtu.be/_0_s3P6uN-o).

The mobile game is on the [App Store](https://apps.apple.com/us/app/squishy-smash/id6762549537). Android Play Store submission is in review as of this week.

Every pop is a hello.

— Chris

*P.S. — In the next post I'll show the actual side-by-side: a Pivot 2 spread vs. the Pivot 5 spread that replaced it. The difference is the entire reason this book exists.*
