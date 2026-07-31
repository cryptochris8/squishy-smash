# Amazon Ads Launch Plan — Squishy Smash (both books)

*Drafted 2026-07-31. Sponsored Products only (KDP author, no Brand Registry — Sponsored Brands/Display are not available to us, and that's fine). Ads flagship = Book 2 "The Lost Sparkle" (B0H3QP7ZPH); Book 1 "Meet the Squishies" (B0H219KX2X) runs a small discovery presence and the defensive cross-target. All US marketplace to start.*

*Method note: drafted by four parallel research passes + an adversarial verification pass; all flagged contradictions and unverified facts were reconciled into this single document. Anything tagged `[VERIFY IN CONSOLE]` is a detail Amazon changes often or that we could not confirm from here — trust the console over this doc for those.*

---

## 0. The economics (everything else follows from these numbers)

| | Book 2 | Book 1 |
|---|---|---|
| List price | $12.99 | $12.99 |
| KDP printing (premium color) | ~$3.65 (40 pg band) | ~$3.86 (46 pg) |
| **Royalty per sale** | **~$4.14** | **~$3.93** |
| **Breakeven ACOS** | **~32%** | **~30%** |

Verify exact printing costs in the KDP pricing dashboard once; the rest of this plan keys off ~$4.14.

At a realistic $0.50–0.80 CPC, breakeven needs ~14.5% conversion from cold traffic — almost no picture book does that. So the plan **deliberately runs above breakeven early** (data + reviews + series halo + flywheel entry are assets the ACOS number never sees), with time-boxed tolerances and hard kill criteria so "strategic loss" can't quietly become "just losing." A both-books order = ~$8.07 royalty on one paid click; the series is the moat.

**Honest category framing:** color picture books are one of the hardest paid categories on Amazon. The realistic win condition is ads at a modest controlled loss (~$100–200/month net of tracked royalties) buying review velocity, organic rank, series-page traffic, and families entering the game/site flywheel — with true halo-inclusive economics meaningfully better than the dashboard shows.

---

## 1. THE GATE LADDER — when spend turns on (one answer, used everywhere)

- **Gate 1 — NOW (before listing fixes even):** nothing but `SS-B2-AUTO-Discovery` at a **$2–3/day trickle**. Its job is search-term data collection and a slow drip of sales-that-become-reviews. Priced as research, not customer acquisition.
- **Gate 2 — at 5+ reviews on Book 2 AND the §2 listing checklist passing:** open the remaining four campaigns → the full **$14/day** configuration (§3).
- **Gate 3 — at 10–15 reviews AND proven converting terms:** scale winners toward **$18–20/day** per the scaling rules in §3. No calendar obligation — if nothing earns a raise, $14 stays $14.

---

## 2. Prerequisites gate — the listing is the conversion machine; ads only buy the visit

### 2.1 Description fix (Book 2) — required before Gate 2
The live description claims "18 **hand-illustrated** picture-book spreads." Remove that claim (and any production-method claim) everywhere. The revised plain-text + KDP-HTML descriptions are staged in [`../../book/KDP_METADATA_SCRATCH_BOOK2.md`](../../book/KDP_METADATA_SCRATCH_BOOK2.md) §2 — copy-paste into KDP → Book 2 → edit details. Changes: "hand-illustrated" → "full-color"; added trim + explicit "(ages 4-8)"; softened two overclaims. Description edits don't trigger re-review but take up to ~72h to propagate.

Also sweep the claim from anywhere else it appears: A+ drafts, series page, Author Central blurbs, website copy.

### 2.2 A+ Content (free conversion upgrade, via KDP Bookshelf → Marketing tab)
KDP authors get A+ Content without Brand Registry. Build for Amazon.com first; the builder's own specs are the authority on module names/pixel sizes `[VERIFY IN CONSOLE]`. Three modules:

1. **World banner** (full-width image header + text). One warm hero image (the trio + the Sparkle, recomposited from locked art at print resolution). Headline: *"Every pop is a hello."* Body: 2–3 sentences of plain parent language — soft storybook universe, no villains, engineered for read-aloud. No production-method claims, no superlatives, no review quotes.
2. **Spread showcase** (3 images + captions): the EVERYBODY SQUISH! spread ("the shout-along moment kids join in on") · the trio finding each other ("three friends from three lands, brave together") · the final quiet spread ("the soft landing that ends bedtime gently"). Export from the NEW reprint interior, downsampled; captions describe the reading experience only.
3. **Series comparison chart** (the workhorse — each column links to an ASIN, the only in-listing cross-sell surface we control). Book 1 vs Book 2 rows: What it is (field guide, 48 friends / their first adventure story) · Best for (browse-anytime / bedtime read-aloud) · How you read it (dip in anywhere / start to finish) · Ages (4–8 both) · Format · Series order. Clone verbatim onto Book 1's A+.

Compliance: no third-party trademarks anywhere in A+ (Squishmallows especially), no price/promo language, alt-text on every image. Check mobile stacking after approval — the comparison chart is the module most likely to cramp.

### 2.3 Reviews — the wait-or-spend math, and the TOS-safe plan
Books under ~5 reviews convert poorly from cold traffic. Quantified at $0.60 CPC: 3% conversion = $20/sale (~150% ACOS); 7% = $8.60 (~66%); 10% = $6 (~46%). **Spending before reviews roughly doubles-to-triples cost per sale.** Hence the gate ladder: trickle now, real budget at 5+, scale at 10–15.

**Hard lines (Amazon detects and punishes):** no incentivized reviews — no coins, Magic Words, cosmetics, or anything of value for a review (keep the Roblox flywheel completely out of the ask); no swaps or purchased reviews; **no family or household members** (the daughters, grandparents, fiancée, close friends are OFF the list even if they genuinely love it); never ask for a *positive* review, only an honest one; no gating. Books carve-out that IS allowed: free advance/review copies, review never required, recipients asked to note the free copy. Note: reviewers need ~$50 of Amazon spend in the trailing 12 months to post at all. **The "Request a Review" button is Seller Central only — KDP authors don't have it; don't plan around it.**

**Four channels, in order:**
1. **Back-matter ask — rides the reprint.** The printed book currently has NO review ask (verified: `book/manuscript/book2_front_back_matter.md` — page 40 is the Book 1 cross-sell + bio only). Add one short block + QR to page 40 before the KDP republish: *"If this story earned a spot in your bedtime rotation, a short honest review on Amazon helps other families find it."* QR → the review-composer URL (`amazon.com/review/create-review?asin=B0H3QP7ZPH` pattern) `[VERIFY it resolves logged-out before print]`; fall back to the product URL. Yield: expect roughly **1 review per 30–100 copies** (a QR ask beats the ~1/100 organic baseline; plan on the low side). Slow but permanent.
2. **Sparkle Letter** (parent-gated email list): one dedicated send when the reprint republishes ("the art got a glow-up…"), then a permanent one-line P.S. in every letter.
3. **Launch-morning push aimed at the reprint republish as the event** — Sparkle Letter, Discord, TikTok followers, non-relative playtest families. Say the honesty rules out loud publicly ("honest reviews only; if we're related, please don't review — Amazon forbids it"). Expect **0–5 reviews** depending on how many genuine past buyers the audience actually contains.
4. **ARC squad ("Squishy Reader Squad")**: 10–15 parents via the list/Discord, free digital ARC, ask = "an honest review when you're done, if you're willing" — never required, never chased twice, never family, disclosure requested. Realistic follow-through 30–50% → 3–7 reviews over 3–4 weeks.

**Timeline to 10+:** realistically day 45–75, and give it +2–4 weeks of slack — the channels above have honest variance.

### 2.4 Pre-spend audit checklist (run on the LIVE pages, not the KDP preview)
- [ ] Series page: both ASINs bound, order correct (1 = Meet the Squishies, 2 = The Lost Sparkle), no placeholder text.
- [ ] Categories on both listings match intent (B2: Friendship/Social Skills, Imaginary Creatures, Humorous Stories) under Best Sellers Rank.
- [ ] "Reading age 4 – 8 years" visible in Product details on BOTH (gift buyers and ads relevance key off it).
- [ ] Look Inside enabled on both; after the reprint republish, confirm it serves the NEW art (it can lag days).
- [ ] Cover thumbnail squint-test at ~100px next to Knight Owl / The Bad Seed / Don't Push the Button in a real search.
- [ ] Revised description renders correctly on desktop AND mobile app; "hand-illustrated" gone everywhere.
- [ ] Backend keywords: all 7 slots filled, NO trademarked brand names (fine as paid ad keywords, forbidden in backend metadata). Current slots are clean.
- [ ] $12.99 buy box sane; check for weird third-party/used offers.
- [ ] Product details accurate (B2: 40 pg, 8.5×8.5; B1: 46 pg).
- [ ] A+ live on both; comparison chart links to the right ASINs; mobile stacking clean.
- [ ] Author Central: both books claimed under one Christopher Ryan Campbell profile, photo + bio present.
- [ ] Review hygiene: nothing on either listing from an obviously connected account.
- [ ] Incognito pass: view both listings logged out — what does a cold gift-buyer see above the fold?
- [ ] Allow ~72h after any KDP edit before flipping ads on.

---

## 3. Campaign architecture — five campaigns, one bid table

**Naming:** `SS-[B1|B2]-[AUTO|KW|PT]-[role]`. Put all campaigns in one Portfolio "Squishy Smash Launch" (Portfolios can set an optional hard monthly cap `[VERIFY IN CONSOLE]`). **One ad group per campaign, one book per ad group — always.** Budget control lives at the campaign level; one source + one book + one intent keeps every report unambiguous. Five simple campaigns beat two clever ones for a solo operator doing 30-minute weekly reviews.

**Bidding strategy everywhere: Dynamic bids — down only.** Fixed bids overpay; "up and down" hands Amazon permission to double bids on unproven targets. Placement adjustments stay 0% until a week-6+ top-of-search experiment on proven Exact terms. Adjust bids in $0.05–0.10 steps, weekly at most. Floor $0.30, ceiling $0.90 — above $0.90 the click math stops working for a $4.14 royalty.

| Campaign | Gate | $/day | Default bids | Contents |
|---|---|---|---|---|
| `SS-B2-AUTO-Discovery` | **1 (now)** | $2–3 → $4 at Gate 2 | close $0.55 · loose $0.40 · substitutes $0.45 · complements $0.35 | The data engine. All four targeting groups on. |
| `SS-B2-KW-Phrase` | 2 | $3 | $0.45 default; per-group overrides below | ~60–80 seed keywords from §4 groups 1–6 (phrase variants) |
| `SS-B2-KW-Exact` | 2 | $2 (grows via harvest) | day-one exacts per §4; harvested terms at their converting CPC +10% | Launches with only the 5–10 highest-confidence exacts; becomes the best campaign by week 8 |
| `SS-B2-PT-Comps` | 2 | $3 | tiered: $0.60 / $0.50 / $0.40 (+ $0.45 defensive) | Product targets from §5 tiers A–C **+ defensive target on B0H219KX2X** |
| `SS-B1-AUTO-Discovery` | 2 | $2 | $0.40 all groups | Field-guide discovery; catches "48 characters / collector" queries |
| `SS-B1-PT-OwnB2` | week 5–6 | $1–2 | $0.40–0.45 | Book 1 ad on Book 2's page: "collect all 48 friends" — the other half of the defensive cross |
| Category campaigns (per book) | week 6+ | ≤20% of total combined | $0.30–0.35 | §5.4 — mining, not profit |

Gate-2 total: **$14/day (~$420/month ceiling)**. Reality: book campaigns at conservative bids commonly spend 40–70% of budget early — expect a real first-month outlay of **$250–400**. If a campaign chronically underspends, the fix is a bid raise on its best targets, not a budget raise.

**Scaling rule (Gate 3):** raise a campaign 20–30% at a time, at most weekly, only when it BOTH spends full budget most days AND holds trailing-3-week ACOS at target (or produces harvestable winners). The 14-day attribution window means recent days always under-report — never scale or cut on less than 2 settled weeks. Natural week-8 shape: Exact + PT-Comps at $5–8/day each; AUTO shrinks to a $2–3 always-on prospector.

**ACOS targets, time-boxed:** months 1–2, accept up to ~60% on Exact/PT and up to ~100% on AUTO/Phrase (paid research). Month 3+, ratchet Exact/PT toward 40–45% and prune what can't get there. Why running above breakeven early is rational, not cope: (1) **series halo** — a Book 2 ad that later sells Book 1 from the series page contributes $3.93 the dashboard never credits; (2) **reviews compound** — a 60%-ACOS sale that moves the book from 4 to 10 reviews buys a permanent conversion upgrade; (3) **flywheel** — every book in a household carries magic-word codes into the game and site, priced at $0 by the dashboard.

---

## 4. Seed keywords — paste-ready, deduped, lowercase

These six intent groups are the **seed lists for `SS-B2-KW-Phrase` and `SS-B2-KW-Exact`** (not separate campaigns). Start phrase-heavy; promote to exact on proof (2+ orders). Bids below the observed $0.50–0.80 CPC band (gift group especially) are **deliberately cheap-or-silent** — expect thin impressions there and treat any spend as a bargain; the escape valve is the +$0.10 no-impressions nudge in §6.

**Group 1 — Squishy & toy-adjacent brand terms (+ own-brand defense).** The shopper typing "squishmallow book" is our exact buyer looking for the aesthetic their kid already loves. Targeting "squishmallows" as a PAID keyword is standard and allowed — it must never appear in our listing/backend/A+. The ad buys placement next to the official tie-in books, not instead of them. Own-brand terms are near-free clicks that defend the listing and catch flywheel traffic.
*Exact $0.55 on the core + own-brand at $0.25; phrase $0.40 on variants; cap $0.80.*
`squishmallow book · squishmallows book · squishmallow books for kids · squishmallow picture book · squishmallow story book · squishmallow storybook · squishmallow books for girls · squishmallow bedtime book · squishy book · squishy books for kids · squishy story book · squishy book for girls · squishies book · books about squishies · kawaii squishy book · squishy character book · squishy smash · squishy smash book · squishy smash the lost sparkle · squishy smash lost sparkle · meet the squishies book · squishy smash meet the squishies`

**Group 2 — Bedtime & read-aloud.** The book is engineered for this occasion; the age-qualified long tail does the targeting. *Phrase $0.35; promote proven converters to exact $0.45; cap $0.60.*
`bedtime stories for kids · bedtime books for kids · bedtime stories for 4 year olds · bedtime stories for 5 year olds · bedtime stories for 6 year olds · bedtime picture book · calming bedtime books for kids · gentle bedtime story · goodnight books for kids · sleepy time books for kids · books to read at bedtime · preschool bedtime books · kindergarten bedtime books · read aloud books for kids · read aloud books for kindergarten · read aloud books for preschoolers · best read aloud picture books · funny read aloud books for kids · interactive books for kids · story books for 4 year olds · story books for 5 year olds · story books for 6 year olds · picture books for 4 year olds · picture books for 5 year olds · picture books for 6 year olds`

**Group 3 — Friendship & feelings.** Matches our JUV039020 placement and the actual theme; parents and teachers buy on message fit; back-to-school bump is now. *Phrase $0.35; cap $0.55.*
`friendship books for kids · friendship picture book · books about friendship for kids · friendship books for kindergarten · friendship books for preschoolers · kindness books for kids · picture books about kindness · books that teach kindness · books about making friends · friendship stories for children · books about teamwork for kids · books about working together for kids · books about cooperation for kids · books about helping others for kids · social emotional books for kids · sel books for kindergarten · social skills books for kids · feelings books for kids`

**Group 4 — Cute creatures, kawaii & friendly monsters.** The aesthetic self-selects buyers — CTR/CVR here tends to beat generic terms. *Phrase $0.40; exact $0.50 on "cute monster book" + "kawaii books for kids" day one; cap $0.65. Watch "monster books for kids" for scary-intent bleed.*
`cute monster book · monster books for kids · friendly monster book · monster picture book · not scary monster book for kids · silly monster book · little monster book · cute monster stories for kids · kawaii book · kawaii books for kids · kawaii picture book · cute books for kids · cute picture books · books with cute characters · imaginary creatures book for kids · magical creatures book for kids · fantasy picture books for kids · bunny books for kids · dumpling book for kids`

**Group 5 — Gift occasion & age-browse.** Gift buyers convert on a $12.99 premium-color square paperback, but the pure gift heads are mostly TOY intent — lowest bids in the account, own group so their higher ACOS can't contaminate other data. Seasonal terms pause off-season. *Phrase only $0.25–0.30; hard cap $0.45; expect to cull half by week 4.*
`book gifts for kids · gift books for children · books for 4 year old girl · books for 5 year old girl · books for 6 year old girl · books for 7 year old girl · books for girls age 5 · gifts for 4 year old girl · gifts for 5 year old girl · gifts for 6 year old girl · birthday gift for 5 year old girl · birthday books for kids · book for granddaughter · picture book gift · stocking stuffer books for kids · easter basket books for kids · kindergarten graduation gift book`

**Group 6 — Comp-title searches.** Proven picture-book buyers in exactly our tone; we win the cheap mid-page impression, never top-of-search premium. *Exact $0.45 on titles/authors (navigational); phrase $0.35 on "books like x" (genuine discovery — best converters here); cap $0.60.*
`knight owl book · knight owl christopher denise · books like knight owl · the bad seed book · the good egg book · the cool bean book · jory john books · food group books · books like the bad seed · dont push the button · dont push the button book · bill cotter books · bear snores on · bear snores on book · karma wilson books · press here book · herve tullet books · books like press here · the wonky donkey · wonky donkey book · little elliot big city · pokko and the drum · hot dog doug salati · big vashti harrison`

**Negative keywords — campaign-level negative phrase, all campaigns** (checked: none collide with any bid keyword; "inch" cheaply kills squishmallow size-variant toy queries like "16 inch"; "roblox" deliberately NOT negated — brand-aware searchers may include it; negate only if the report shows waste):
`free · pdf · download · printable · coloring · coloring book · coloring pages · activity book · workbook · sticker book · stickers · kindle · kindle unlimited · audiobook · audible · board book · baby · toddler · for adults · adults · chapter book · graphic novel · spanish · plush · plushies · stuffed animal · slime · fidget · stress ball · toy · toys · inch · gift card · lego · barbie · used`

---

## 5. Product targeting (`SS-B2-PT-Comps` + expansions)

Rule zero: **never hand-type an ASIN** except our own two. Find every target by searching title + author in the console picker and add what the console itself surfaces.

### 5.1 Tier A — Bullseye: official Squishmallows & plush-brand tie-in books ($0.60, range $0.55–0.75)
The shopper on these pages is literally our buyer. Product targeting a trademark's detail pages is fully allowed (the trademark line only forbids their name in OUR listing text/backend/A+). Lowest volume, best true-comp conversion — the most likely profitable tier. Honest math: at ~$4.14 royalty, breakeven CPC is ~$0.33 at 8% CVR — $0.60 is a deliberate launch overpay for data. After 2 weeks: raise winners toward $0.90, cut 20-click/0-order targets to $0.40 or pause.
Console searches: **"Squishmallows Squish and Seek"** (search-and-find, ages 4–8 — closest single comp), **"Squishmallows Official Collectors Guide"** (mirrors Book 1's field-guide format; add every edition that surfaces), **"Squishmallows book"** (add EVERY children's picture-book/storybook result on pages 1–2; the official line keeps growing — re-run monthly), **"Care Bears picture book"**, **"Beanie Boos book"** (add only genuine official-brand kids' picture books; verify on each detail page). Target every format/edition the console shows — each is a separate targetable product.

### 5.2 Tier B — Close comps: gentle cute-creature read-alouds ($0.50, range $0.45–0.60)
Same occasion: bedtime-safe, no villain, cute-creature ensemble. Early ACOS realistically 40–70% while reviews gather; treat sub-45% targets as keepers. ISBNs below are verified cross-checks (the console search is still how you add them):
- **Bear Snores On** — Karma Wilson & Jane Chapman (9780689831874) — closest narrative comp (gentle cumulative ensemble → cozy sleep); add the whole 12+ book Bear series, series buyers are collection-minded like ours
- **Knight Owl** — Christopher Denise (9780316310628) + sequels — NYT #1 cozy small-hero series
- **Little Elliot, Big City** — Mike Curato (9781627796989) — tiny cute creature, belonging
- **Pokko and the Drum** — Matthew Forsythe (9781481480390) — illustration-first buyers
- **Hot Dog** — Doug Salati (9780593308431) — calming arc, gentle-book Caldecott traffic

### 5.3 Tier C — Interactive read-aloud engine ($0.40, range $0.35–0.45; cap its share, it can eat spend)
Sells on PARTICIPATION — exactly the "EVERYBODY SQUISH!" hook — but these mega-franchises anchor their own pages and often sit at $5–9, so our $12.99 fights a visible price gap. Reach + data play; every order is a bonus.
- **Don't Push the Button!** — Bill Cotter (9781402287466) + sequels/holiday editions
- **Press Here** — Hervé Tullet (9780811879545)
- **The Wonky Donkey** — Craig Smith — the viral-granny read-aloud audience is literally grandparents buying for 4–8s

### 5.4 Optional expansions (week 6+, only if Tiers A–B are behaving)
- **Tier D — big-reach bestsellers** ($0.35, ~15% of budget max): the Food Group series (add The Bad Seed / The Good Egg / The Cool Bean / The Smart Cookie as SEPARATE targets so the report shows which converts), Big — Vashti Harrison (9780316353229). Worst economics in the account by design; kill without guilt at 3–4 weeks if nothing converts.
- **Category campaigns** (one per book, $0.30–0.35, ≤20% of total spend combined): in the product-targeting tab's category picker choose the children's nodes matching our placements (Friendship/Social Skills, Imaginary Creatures/Monsters, Humorous) + Bedtime & Dreaming (highest-intent occasion; we don't need to be shelved there to target it). Node display names differ from JUV codes `[VERIFY IN CONSOLE]`. Refine price range to ~$8.99–16.99 so we never render next to $4.99 board books, and add a review-rating refinement once we have reviews `[VERIFY refinement options]`. Their real job is MINING: harvest every converting ASIN from the report into Tier A/B monthly as an exact product target at a higher bid; exclude repeat click-eaters `[VERIFY negative product targeting availability]`.

### 5.5 The defensive cross (both directions, explicit)
- **At Gate 2:** inside `SS-B2-PT-Comps`, add a product target on **B0H219KX2X** (our Book 1) at $0.45 — a Book 1 browser sees "now read their adventure."
- **Week 5–6:** launch `SS-B1-PT-OwnB2` targeting **B0H3QP7ZPH** at $0.40–0.45 — a Book 2 browser sees "meet all 48 friends."
Why it earns its slot: (1) the sponsored carousel on our pages will be filled by SOMEONE — competitors will target us exactly the way we target them in Tier A; self-filling those slots keeps the browse loop inside the series; (2) it's the warmest traffic in the account — near-best CVR whenever it serves, and a both-books order is ~$8.07 royalty on one click; (3) every cross-sale strengthens the series page, doubles the chance a household finds the magic words, and feeds Amazon's own also-bought graph. Amazon won't serve a book's ad on its own page, so the CROSS pattern is the entire mechanic — a one-book catalog can't do this; the two-book series is a real ads moat. Expect near-dormant spend until traffic grows; it scales itself. Ceiling: whatever keeps this ad group under ~25% ACOS.

---

## 6. Weekly optimization routine — weeks 1–8 (30–45 min, same day each week)

**Standing rule:** judge trailing data ending 5+ days ago. 14-day attribution means this week's clicks haven't finished reporting orders — the classic solo-author error is panic-cutting a keyword three days before its sales post.

**Weeks 1–2 — hands off, eyes open.** No bid changes, no harvesting. Only: skim search terms twice, negative-exact anything clearly wrong-audience on sight ("squishmallow 16 inch plush", unrelated media), and confirm campaigns actually spend — near-zero impressions after 5–6 days → nudge bids +$0.10.

**Weeks 3–8 — the loop, in order:**
1. **Harvest (the engine).** Pull search terms for AUTO + Phrase. Any term with 1+ orders: add as EXACT to `SS-B2-KW-Exact` at its converting CPC +10%, and negative-exact it in the source campaign (funnels future traffic through the one place you control its bid; stops your own campaigns bidding against each other). Harvest converting ASINs from AUTO's substitutes/complements rows into `SS-B2-PT-Comps`.
2. **Negate waste — kill criteria, correct math.** At $0.60 CPC, breakeven (32% ACOS = spend equals one $4.14 royalty) is ~7 clicks per sale; 100% ACOS (spend equals the full $12.99 price) is ~21 clicks. The thresholds sit between:
   - Search terms: negative-exact at **10+ clicks, 0 orders** (~$6–8). Honesty: a genuinely-good 10%-converting term goes 0-for-10 ~35% of the time — you'll occasionally kill an innocent; at this budget that's still the right trade.
   - Chosen keywords/product targets: pause at **15–20 clicks, 0 orders** (~$9–13 = 2–3 royalties), after the 14-day window has settled. Keywords aggregate many queries — slightly more rope.
   - Relevance kills: high impressions + CTR under ~0.2% = the cover doesn't fit that query; no bid fixes it; pause.
3. **Bid nudges** ($0.05–0.10, only with 2+ orders or clear signals): ACOS ≤45% → +; 60–100% → − (diet, don't kill a converter); >100% twice running → pause; zero impressions all week → +$0.10 or accept irrelevance.
4. **Log one line per campaign** (date, spend, orders, ACOS, changes) in a plain spreadsheet. Week-over-week memory is the whole game; the console hides trends.

**Milestones:** wk 3 first harvest · wk 4 first kills execute · wk 5–6 launch `SS-B1-PT-OwnB2` + first budget shifts if earned · wk 6+ category campaigns + top-of-search experiment on proven exacts · wk 8 formal review, ratchet ACOS targets down, decide scale/hold/fix-the-listing.

---

## 7. What success actually looks like (and the pre-committed kill condition)

**Day 30:** ~$250–400 spent · 400–700 clicks · **8–25 ad-attributed copies** · blended ACOS 60–120% — normal, not failure. Real deliverables: a search-term map of the 10–20 queries/pages that actually sell this book, 2–5 new reviews, Exact seeded with proven terms, first organic-rank movement. Red flag worth acting on: conversion under ~2% across hundreds of clicks *despite 5+ reviews* — that's a page/cover problem; pause and fix the listing. Ads amplify a page; they never fix one.

**Day 60:** Exact + PT carrying 40–60% of spend at materially better efficiency · blended ACOS drifting into 45–70% · a handful of individual keywords at/below 32% · 25–60 cumulative ad-attributed copies plus uncredited series-halo and organic sales. That is a genuinely good 60-day outcome in this category.

**Kill condition, decided now so it isn't rationalized later:** if after 60 days and ~$600–800 total spend there are zero repeat-converting keywords AND the page converts under 2% with reviews in place — stop spending and fix the product (cover, description, price test, A+) before buying another click.

---

## 8. Console setup order (Chris's manual actions)

1. KDP → Book 2 → edit details → paste the revised description (staged in the metadata scratch doc §2). Same session: verify backend keywords/categories/age range. Allow ~72h.
2. KDP Bookshelf → Marketing tab → A+ Content → build the three modules (§2.2) → submit for both books.
3. Reprint interior: add the review-ask block + QR to page 40 before the republish (§2.3.1) — one file change while the reprint is already awaiting upload.
4. advertising.amazon.com (reached via KDP Promote & Advertise) → confirm card on file → create Portfolio "Squishy Smash Launch" (+ monthly cap if offered).
5. Create `SS-B2-AUTO-Discovery` ($2–3/day, down-only, four groups at §3 bids, negatives from §4) → **this is the only live campaign until Gate 2.**
6. At 5+ Book 2 reviews + checklist green: create the four Gate-2 campaigns per §3–5.
7. Same weekday every week: run §6 for 30–45 minutes.

*Companion docs: the corrected listing copy lives in `book/KDP_METADATA_SCRATCH_BOOK2.md`; the wider organic flywheel is `marketing/GO_VIRAL_PLAN.md` in the Roblox repo (note: its "Request a Review button" reference is a Seller Central feature KDP authors don't get — corrected here).*
