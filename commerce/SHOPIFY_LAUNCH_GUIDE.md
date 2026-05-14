# Squishy Smash — Shopify + POD Launch Guide

A complete plan for opening a Squishy Smash merchandise store on Shopify using a print-on-demand (POD) backend. Covers the **product line catalog** (the WHAT), the **print-ready design files** (already generated and sitting in `commerce/print_ready/`), and the **Shopify + Printful setup walkthrough** (the HOW — sequenced step by step).

**Architecture decision:** Shopify Basic ($39/mo) + Printful (free, $0 inventory). Every product in v1 ships from Printful — we never touch inventory, packing, or fulfillment. Customer orders → Shopify → auto-routes to Printful → Printful prints + ships in our branding. This keeps cash outlay near zero until orders prove the line.

**Defer for v2:** plushies (high MOQ, parked decision), enamel pins (separate manufacturer), printed coloring book (needs line-art versions of all 48 characters — separate asset pipeline).

---

## A. Product Line Catalog (v1 launch)

14 products across 5 categories. Each row lists the design used, where its print-ready file lives, suggested retail, and Printful's wholesale cost (so you can see margins).

### A.1 Apparel

| Product | Design | Print-ready file | Variants | Retail | Wholesale | Margin |
|---|---|---|---|---|---|---|
| Adult Tee — The Pact ★ | Canonical Pact line, typography only (bible-canon brand piece) | `commerce/print_ready/tee_pact_line.png` | S–3XL · Black, Heather Plum | $26.99 | ~$11 | ~$16 |
| Adult Tee — Squishy Smash Wordmark | Brand wordmark on dark + sparkle scatter | `commerce/print_ready/tee_wordmark.png` | S–3XL · Black, Heather Plum, Cream | $24.99 | ~$11 | ~$14 |
| Adult Tee — Mythic Plush Familiar | The legendary squishy as hero | `commerce/print_ready/tee_mythic_familiar.png` | S–3XL · Black, Cream | $26.99 | ~$11 | ~$16 |
| Kids Tee — Blushy Bun Bunny | Cover-star squishy, kid favorite | `commerce/print_ready/tee_kids_blushy_bun.png` | 2T–YXL · Pink, Black | $21.99 | ~$10 | ~$12 |
| Kids Tee — Soft Dumpling | Foods pack hero | `commerce/print_ready/tee_kids_soft_dumpling.png` | 2T–YXL · Cream, Pink | $21.99 | ~$10 | ~$12 |
| Hoodie (Adult) — Wordmark | Wordmark + sparkle scatter | `commerce/print_ready/tee_wordmark.png` (reuse) | S–3XL · Black, Heather Plum | $44.99 | ~$26 | ~$19 |
| Hoodie (Adult) — The Pact ★ | Pact line on dark, ideal for cozy/adult buyer | `commerce/print_ready/tee_pact_line.png` (reuse) | S–3XL · Black, Heather Plum | $46.99 | ~$26 | ~$21 |
| Tote Bag — 3-Pack Mascot Trio | Goo Ball + Blushy Bun Bunny + Soft Dumpling cluster | `commerce/print_ready/tote_3_pack_trio.png` | One size · Natural canvas | $19.99 | ~$10 | ~$10 |

★ = bible-canonical Pact line piece per `book/STORY_BIBLE.md` §2 — the most evergreen designs in the catalog. No character art; works regardless of which squishy is the customer's favorite.

### A.2 Stickers

| Product | Design | Print-ready file | Variants | Retail | Wholesale | Margin |
|---|---|---|---|---|---|---|
| Sticker — The Pact ★ | Canonical Pact line on dark, sparkle scatter | `commerce/print_ready/sticker_pact_line.png` | 5 × 5 in glossy | $4.99 | ~$2 | ~$3 |
| Sticker Sheet — Squishy Foods | All 16 Foods squishies, die-cut layout | `commerce/print_ready/sticker_sheet_squishy_foods.png` | 8.5 × 11 in glossy | $9.99 | ~$3 | ~$7 |
| Sticker Sheet — Goo & Fidgets | All 16 Goo squishies | `commerce/print_ready/sticker_sheet_goo_fidgets.png` | 8.5 × 11 in glossy | $9.99 | ~$3 | ~$7 |
| Sticker Sheet — Creepy-Cute Creatures | All 16 Creepy-Cute squishies | `commerce/print_ready/sticker_sheet_creepy_cute.png` | 8.5 × 11 in glossy | $9.99 | ~$3 | ~$7 |
| Holographic Single — Mythic Plush Familiar | Largest, foil-finish | `commerce/print_ready/sticker_solo_mythic_familiar.png` | 4 × 5 in holographic | $5.99 | ~$2 | ~$4 |

### A.3 Drinkware

| Product | Design | Print-ready file | Variants | Retail | Wholesale | Margin |
|---|---|---|---|---|---|---|
| Mug — The Pact ★ | Pact line stacked on the front face, sparkles wrap to the back | `commerce/print_ready/mug_pact_wrap.png` | 11 oz, 15 oz · Black or Dark ceramic | $17.99 | ~$8 | ~$10 |
| Mug — Soft Dumpling | Side-wrap design with mascot + tagline | `commerce/print_ready/mug_soft_dumpling_wrap.png` | 11 oz, 15 oz · White ceramic | $17.99 | ~$8 | ~$10 |
| Mug — Squishy Smash Wordmark | Brand wrap | `commerce/print_ready/mug_wordmark_wrap.png` | 11 oz, 15 oz · White ceramic | $17.99 | ~$8 | ~$10 |

### A.4 Wall Art

| Product | Design | Print-ready file | Variants | Retail | Wholesale | Margin |
|---|---|---|---|---|---|---|
| Poster — All 48 Squishies Grid | The collector wall art, 6 × 8 grid | `commerce/print_ready/poster_all_48_grid.png` | 12×18 in, 18×24 in matte | $19.99 / $29.99 | ~$8 / ~$13 | ~$11 / ~$16 |

---

## B. Print-Ready File Specifications

> **Regenerating the files:** the print-ready PNGs total ~100 MB and are gitignored (regeneratable from source). Run `python tools/generate_merch_designs.py` to produce them — output lands in `commerce/print_ready/`. Same policy as the book PDFs (`book/build/out/`).

All print-ready PNGs are at **300 DPI** with transparent or correctly-colored backgrounds depending on the product type. Sizes match Printful's design-area specs:

| File suffix | Pixel dimensions | Print size @ 300 DPI | Use |
|---|---|---|---|
| `_tee_*.png` | 4500 × 5400 px | 15 × 18 in | T-shirt + hoodie front print (12 × 16 in print area + bleed) |
| `_tote_*.png` | 4200 × 4200 px | 14 × 14 in | Tote bag front print |
| `_sticker_sheet_*.png` | 2550 × 3300 px | 8.5 × 11 in | Cut-to-shape sticker sheets (kiss-cut) |
| `_sticker_solo_*.png` | 1500 × 1500 px | 5 × 5 in | Individual die-cut sticker |
| `_mug_*.png` | 2700 × 1125 px | 9 × 3.75 in | Mug wrap (standard 11 oz / 15 oz) |
| `_poster_*.png` | 5400 × 7200 px | 18 × 24 in | Premium poster (largest variant; 12 × 18 in scales down cleanly) |

**Why 300 DPI:** Printful auto-rejects designs below ~150 DPI for apparel and below 200 DPI for posters. 300 gives headroom for any zoom/crop the customer might trigger inside Printful's design tool.

**Why transparent bg on apparel:** Printful prints DTG (direct-to-garment); transparent backgrounds let the shirt color show through. Solid-bg designs print as a colored rectangle on the shirt — looks like a sticker, not a print.

---

## C. Shopify + Printful Setup Walkthrough

### Step 1 — Open the Shopify store

If you don't have one yet:

1. Go to <https://www.shopify.com/free-trial> and start the **3-day free trial** (no card required for the trial)
2. After trial: pick **Basic** ($39/mo) — supports unlimited products, gives you the full product/inventory/order management you'll need for v1
3. Store name: `Squishy Smash` (this becomes your Shopify subdomain — `squishy-smash.myshopify.com` — which we'll later route through `shop.squishysmash.com`)

If you already have a Shopify store from a prior project, just create new collections and skip ahead to Step 2.

### Step 2 — Install the Printful app

1. From your Shopify admin → **Apps** → **Visit Shopify App Store**
2. Search **Printful: Print-on-Demand** → click **Add app**
3. Authorize the install — this connects Printful's order webhook to Shopify

Printful is free; you only pay wholesale per item shipped.

### Step 3 — Configure Printful

Inside the Printful dashboard (printful.com after the install bridges your accounts):

1. **Stores → Squishy Smash → Settings** — confirm your Shopify store is listed and connected
2. **Billing** — add a card (Printful charges your card when an order ships, then you've already collected from the customer via Shopify, so cash flow is positive immediately)
3. **Branding → Add packing slip logo** — upload `branding/logo/squishy_smash_logo_primary.png`. This logo prints on every packing slip Printful includes in customer shipments. Free.
4. **Branding → Inside neck label** (apparel only) — Printful charges $2.49/garment to swap their tag for a custom Squishy Smash one. Skip for v1; revisit when monthly volume justifies.

### Step 4 — Create products in Printful (one product type at a time)

For each row in section A above:

1. **Stores → Squishy Smash → Add product**
2. Pick the product type matching the row (e.g., **Unisex Heavy Cotton Tee**)
3. Pick the brand model — **Gildan 5000** for adult tees is the most cost-effective default
4. Choose colors per the Variants column in section A
5. Upload the print-ready file from `commerce/print_ready/` (the file path in section A)
6. In Printful's design tool, click **Center** + **Fit to print area** — should auto-snap; if the design looks tiny, your file's pixel dimensions don't match what Printful expects (cross-check with section B)
7. Click **Generate mockups** — Printful renders ~10 angles (front, back, lifestyle). These are the images that appear on Shopify.
8. **Pricing** tab → enter the retail price from section A. Printful auto-calculates your profit per sale.
9. **Description** tab → paste the matching listing copy from section D below
10. Click **Submit to store** — Printful pushes the product into Shopify automatically

Repeat for all 14 products. Budget: ~5 minutes per product = ~70 minutes total for a clean batch.

### Step 5 — Storefront polish (Shopify side)

1. **Online Store → Themes** — start with **Dawn** (free, fast, mobile-clean). Pick a theme later only if Dawn limits something specific.
2. **Customize → Colors** — set the brand palette so the storefront matches the app/website:
   - Background: `#120B17`
   - Primary accent (buttons): `#FF8FB8`
   - Secondary accent (highlights): `#FFD36E`
   - Text on dark: `#FFFFFF` body, `#FFD36E` highlights
3. **Customize → Typography** — set headers to **Fredoka** if the theme allows custom Google Fonts; otherwise pick a friendly rounded substitute (Quicksand, Comfortaa, Nunito).
4. **Online Store → Navigation** — main menu: `Apparel`, `Stickers`, `Drinkware`, `Wall Art`, `About`. Match the categories in section A.
5. **Online Store → Pages** — create:
   - **About** — reuse the plain-English pitch (`memory/plain_english_pitch.md`) as the body
   - **Shipping & Returns** — Printful handles shipping; standard policy is "ships from US in 3–5 business days, free returns on defects only" (POD doesn't accept change-of-mind returns the way inventory stores do)
   - **Contact** — point at `support@squishysmash.com`
6. **Settings → Domains** — add `shop.squishysmash.com`:
   - In your Namecheap DNS for `squishysmash.com`, add a CNAME: `shop` → `shops.myshopify.com`
   - In Shopify, click **Verify domain** after the DNS propagates (~30 min to a few hours)
7. **Settings → Checkout** — enable **Apple Pay** and **Shop Pay** (default-on; enables one-tap checkout on iOS, which is your primary channel)

### Step 6 — Tax + shipping

1. **Settings → Taxes and duties → United States** — toggle **Collect sales tax automatically**. Shopify uses the customer's shipping address to compute the right state/local rate.
2. **Settings → Shipping and delivery → Shipping zones**:
   - Create a **Domestic (US)** zone — set rates as **Carrier-calculated** so Printful's actual ship cost passes through to the customer at checkout
   - Create an **International** zone — restrict to ~10 high-trust markets first (CA, UK, AU, DE, FR, JP, NL, SE, NZ, IE) until you know your fraud-flag patterns
3. **Settings → Locations** — confirm the Printful warehouse location appears as a fulfillment location (auto-added when you connected Printful)

### Step 7 — Pre-launch checklist

- [ ] All 14 products are live in Shopify with mockups, descriptions, prices
- [ ] Test order placed (use Shopify's **Bogus Gateway** test mode, OR place a real order with **Printful coupon code 20OFF** and ship it to yourself)
- [ ] Mobile preview looks clean (most traffic from your iOS app and X profile will be mobile)
- [ ] Footer has working links: About, Shipping & Returns, Contact, Privacy
- [ ] Privacy policy posted (Shopify generates a default — edit the auto-generated text under **Settings → Policies**)
- [ ] Site analytics: install **Shopify's built-in** + Google Analytics 4 (`Settings → Apps and sales channels → Google & YouTube`)

### Step 8 — Launch

1. Push the live URL: `https://shop.squishysmash.com`
2. Add a **Shop** link to:
   - The marketing site (`website/`) — main nav + a CTA on the home page
   - The X bio (`@squishy_smash`)
   - The support page FAQ
   - The book back cover blurb? *(probably not — keeps the book product-pure)*
3. Soft-launch post on X with the wordmark tee + the all-48 poster as the lead images (those two flagship products do the most franchise-signaling)
4. Watch the first week's data; the items that don't move can be paused or repriced without inventory penalty (POD's main advantage)

---

## D. Listing Copy (paste-ready for each product)

Voice direction (from `memory/brand_and_social_presence.md`): *Casual, lowercase-friendly, slightly self-effacing. Family-safe, not saccharine.*

### Apparel

**Adult Tee — Squishy Smash Wordmark**

> Soft tee, soft squishies. The Squishy Smash wordmark in our signature blush pink, scattered with a few stray sparkles for the people who notice details.
>
> Unisex fit, ringspun cotton, printed on demand so we never run out and you never get one that's been sitting in a warehouse for 18 months.

**Adult Tee — Mythic Plush Familiar**

> The rarest squishy in the deck. If you've pulled one in-game, you know — and now you can wear it.
>
> Fan-favorite mythic on a soft unisex tee. The kind of shirt people stop you in line for.

**Kids Tee — Blushy Bun Bunny**

> Tiny paws, rosy cheeks, and a bounce that melts hearts. Blushy Bun Bunny is the cover star of our character book, and now she's your kid's favorite shirt.
>
> Soft cotton kids' tee, made to survive the playground.

**Kids Tee — Soft Dumpling**

> The first squishy. The softest. The one every Squishy Smash collection starts with.
>
> Soft Dumpling on a kids' tee — warm, sweet, and impossible not to hug.

**Hoodie — Squishy Smash Wordmark**

> Hood up, squishies in. The wordmark hoodie for the season when the air gets a little crisp and a soft squishy sounds like the right idea.
>
> Heavyweight blend, kangaroo pocket, drawstring hood. Sized true.

**Tote Bag — 3-Pack Mascot Trio**

> One bag, three squishies. Goo Ball, Blushy Bun Bunny, and Soft Dumpling — one face from each pack — because picking just one was impossible.
>
> Natural canvas, gusseted bottom, sized for a grocery run or a stack of library books.

### Stickers

**Sticker Sheet — Squishy Foods**

> All 16 Squishy Foods squishies, kiss-cut on a single 8.5 × 11 sheet. Peel them out one at a time or stick the whole sheet on something flat.
>
> Glossy finish, weather-resistant. Goes great on water bottles, laptops, and notebooks.

**Sticker Sheet — Goo & Fidgets**

> The whole Goo & Fidgets pack on one sheet. Glossy. Bouncy. Stickable.
>
> 16 individual kiss-cut stickers, perfect for trading or hoarding.

**Sticker Sheet — Creepy-Cute Creatures**

> Spooky and sweet — all 16 Creepy-Cute Creatures on one sheet. The Squishkeeper's full Moonlit Hollow roster, ready to peel.

**Holographic Single — Mythic Plush Familiar**

> The legendary mythic squishy, in a single oversized holographic die-cut sticker. Catches the light. Earns the look.

### Drinkware

**Mug — Soft Dumpling**

> Wraps the cozy little Soft Dumpling around an 11 oz (or 15 oz) ceramic mug. Microwave-safe, dishwasher-safe, squishy-safe.
>
> Made for slow mornings.

**Mug — Squishy Smash Wordmark**

> The brand wordmark in pink and cream, wrapping a clean white mug. The "I love this little world" mug for people who quietly want everyone to ask.

### Wall Art

**Poster — All 48 Squishies Grid**

> Every squishy. Every pack. One poster. The full collector's wall — 48 characters in an 8 × 6 grid on premium matte stock.
>
> Sized 12 × 18 in or 18 × 24 in. The bigger one is the obvious choice.

---

## E. Common Issues + Fixes

| Issue | Fix |
|---|---|
| Printful flags a design as "low resolution" | The PNG was downscaled before upload. Re-grab from `commerce/print_ready/` — those files are at full 300 DPI |
| Shopify product is missing the Printful mockup images | Inside Printful → product → **Generate mockups** → wait 60s → click **Sync to Shopify**. Mockups don't push automatically on first creation |
| Customer says shipping is slow | POD has a 2–5 day **production** time before shipping. Set expectations in product descriptions: "ships in 5–10 business days." Already baked into the listing copy above |
| Customer wants to return a tee that fits weird | POD policy: returns only for defects/printing errors, not change-of-mind. Refund + reorder in their corrected size. Cost is yours; budget ~3% returns rate into pricing |
| The brand colors look duller in print than on screen | CMYK vs RGB compression — bright pink (`#FF8FB8`) prints muted. Already accounted for in the print-ready files; just verify the first physical sample. If too dull, ask Printful for a color-correction reprint (free first time) |
| Sticker sheet kiss-cut alignment off | Some die-cut services (StickerMule especially) need the cut path embedded as a separate layer/file. Printful auto-detects from transparent backgrounds — the sheets in `print_ready/` are pre-formatted for that. If switching to StickerMule, regenerate with explicit cut paths |

---

## F. Deferred (v2 / future)

These were considered for v1 but parked. Reactivate when v1 sales data justifies the inventory commitment.

### F.1 Plushies (parked)

The most-asked-for product when there's an audience. **High capital outlay**: $300–1k MOQ per design × 48 characters = ~$15–50k upfront. Better path: pick the top 4–6 sellers from v1 sticker/tee data, run a **Kickstarter** to validate demand, then commit a bulk order. Memory note: `memory/3d_models_parked.md` covers the AI 3D model exploration that would feed this.

### F.2 Coloring book (separate KDP project)

Different from the character book we just shipped. Needs **line-art versions of all 48 squishies** — current cards are fully-rendered with shading and don't convert cleanly. Either:
- Commission a line-art pass from a kids' book illustrator (~$500–1500 total), OR
- Generate via image-to-line-art AI conversion + manual cleanup

When ready, publish via the same KDP pipeline that produced `book/build/out/interior.pdf`. Suggested title: *Squishy Smash Coloring Book — Color Your Squishies*.

### F.3 Enamel pins

Smaller than plushies but still hit MOQ ($500–1500 per design from a manufacturer). Best as a **3-pin pack — one per pack** rather than 48 individual pins. Wait for v2.

### F.4 Phone cases / laptop sleeves

Printful supports them, but they need design files at unusual aspect ratios (e.g., iPhone 15 Pro Max is 1284 × 2778). Generate when you've decided whether they're worth the per-product effort vs the broader-appeal items already in v1.

### F.5 Vinyl figurines

Similar to plushies — meaningful upfront tooling. Same Kickstarter validation play.

---

## G. File index

```
commerce/
├── SHOPIFY_LAUNCH_GUIDE.md       (this file)
└── print_ready/
    ├── tee_pact_line.png         (4500 × 5400) — ★ canonical Pact-line tee + hoodie
    ├── tee_wordmark.png          (4500 × 5400) — adult + hoodie wordmark
    ├── tee_mythic_familiar.png   (4500 × 5400) — adult mythic tee
    ├── tee_kids_blushy_bun.png   (4500 × 5400) — kids Blushy Bun Bunny
    ├── tee_kids_soft_dumpling.png (4500 × 5400) — kids Soft Dumpling
    ├── tote_3_pack_trio.png      (4200 × 4200) — tote bag trio
    ├── sticker_pact_line.png     (1500 × 1500) — ★ canonical Pact-line sticker
    ├── sticker_sheet_squishy_foods.png    (2550 × 3300)
    ├── sticker_sheet_goo_fidgets.png      (2550 × 3300)
    ├── sticker_sheet_creepy_cute.png      (2550 × 3300)
    ├── sticker_solo_mythic_familiar.png   (1500 × 1500) — holographic single
    ├── mug_pact_wrap.png         (2700 × 1125) — ★ canonical Pact-line mug
    ├── mug_soft_dumpling_wrap.png         (2700 × 1125)
    ├── mug_wordmark_wrap.png              (2700 × 1125)
    └── poster_all_48_grid.png             (5400 × 7200)
```

---

*Companion docs: `book/KDP_SUBMISSION_WALKTHROUGH.md` (book-side launch) · `memory/brand_and_social_presence.md` (palette, voice, font) · `memory/plain_english_pitch.md` (About-page copy)*
