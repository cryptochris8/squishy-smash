# Squishy Smash — Enhancement Plan for Claude Code

## Goal
Use the existing TestFlight build as the foundation and improve **game feel, virality, retention, and reward pacing** without overcomplicating the product.

The app already has a strong base:
- cute toy-like squishy characters
- clean vertical mobile presentation
- readable score/combo UI
- solid themed pack structure
- strong reveal-background moments

The next stage is to make every tap feel **juicier, more satisfying, and more worth recording**.

---

## Priority Framework

### P0 = Do now
High-impact improvements that most directly improve feel and clip-worthiness.

### P1 = Do next
Important quality and retention improvements after the core feel gets stronger.

### P2 = Later
Expansion and depth systems that matter, but should not come before core tactile satisfaction.

---

# P0 Enhancements

## 1) Increase hit impact and tactile feel
### Problem
Current interactions are cute and readable, but some hits still feel visually soft.

### Goals
Make every touch feel more physical, reactive, and addictive.

### Claude tasks
- Increase squash/stretch on impact
- Add a faster recoil/bounce response
- Add tiny overshoot after the rebound
- Add a sharper “snap” at burst threshold
- Add a slightly stronger pause-free response so touch feels immediate

### Implementation ideas
- Increase deformation amplitude by ~10–25%
- Add a brief scale overshoot after impact
- Use a short easing curve for impact, then spring back
- Differentiate normal hit vs stronger hit vs burst-prep hit

### Desired player feeling
“Every tap matters and feels satisfying.”

---

## 2) Upgrade particles from generic dots to themed splats
### Problem
Current particles work, but they still feel closer to placeholders than premium tactile VFX.

### Goals
Make particles reinforce the squishy/ASMR fantasy.

### Claude tasks
Replace generic circular particles with themed particle presets such as:
- goo droplets
- jelly splats
- soft puff clouds
- sticky blobs
- burst rings
- tiny stretch droplets
- soft sparkle garnish for rare moments

### Per-theme recommendations
#### Squishy Foods
- cream droplets
- dumpling steam puffs
- sauce splats
- sesame sparkle accents

#### Goo & Fidgets
- glossy gel blobs
- sticky droplets
- translucent bursts
- squish rings

#### Creepy-Cute Creatures
- soft magical dust
- pastel burst puffs
- glow confetti
- cute “spirit goo” splats

### Desired player feeling
“This feels custom and premium, not generic.”

---

## 3) Push the contrast between calm state and reveal state
### Problem
The calm backgrounds are good, but reveal mode should feel much more special.

### Goals
Create a strong visual payoff when something important happens.

### Claude tasks
- Make calm state remain readable and relaxed
- Make reveal state much brighter, stronger, and more dramatic
- Add brief overlay flash on reveal triggers
- Add reveal shimmer pulse
- Add more contrast in lighting, glow, and aura when rare/reveal moments occur

### Reveal ideas
- brighter skybox swap
- brief bloom pulse
- reveal aura around active squishy
- rare particle palette shift
- light beam / shimmer moment
- 1–2 second emotional “special event” read

### Desired player feeling
“Whoa, something special just happened.”

---

## 4) Enlarge the active squishy on screen
### Problem
The active squishy appears slightly too small for a tactile game.

### Goals
Improve visual intimacy and make the object feel more touchable.

### Claude tasks
- Test scaling active squishies up by 10–15%
- Keep center composition clean
- Ensure larger scale does not interfere with UI readability
- Rebalance particle spread after scaling

### Desired player feeling
“The toy feels closer and more satisfying to interact with.”

---

# P1 Enhancements

## 5) Add stronger facial and emotional reactions
### Problem
The characters are cute, but they can do more work emotionally.

### Goals
Increase personality, collectibility, and watchability.

### Claude tasks
Add reaction states such as:
- startled face on stronger hit
- dizzy face after repeated hits
- wink or smile after successful burst
- strained “about to pop” face
- rare reveal joy face
- sleepy or calm idle face before play begins

### Rules
- Keep reactions fast and readable
- Do not overanimate every hit
- Reserve special expressions for strong interactions and reveals

### Desired player feeling
“These squishies have personality.”

---

## 6) Make progression toward burst/reveal more obvious
### Problem
The top bar is clean, but the anticipation could be stronger.

### Goals
Help players feel the reward building.

### Claude tasks
Enhance the progress/multiplier bar with:
- subtle glow while filling
- pulse at thresholds
- slight color shift near reveal
- tiny shimmer when multiplier increases
- threshold feedback at combo milestones

### Combo milestone suggestions
- combo 3 = tiny pulse
- combo 6 = stronger glow
- combo 10 = reveal-ready visual treatment
- combo 15+ = “mega burst” look

### Desired player feeling
“I can feel something building.”

---

## 7) Build a stronger sound identity
### Problem
The current visual direction strongly suggests that audio can become a major differentiator.

### Goals
Create a signature ASMR sound stack for the game.

### Claude tasks
Create layered sound categories:
- wet squish
- soft pop transient
- splat tail
- jelly wobble
- sticky peel
- goo burst
- reward chime
- rare reveal shimmer
- occasional whisper-close voice stinger

### Audio rules
- prioritize tactile sounds over narration
- voice should be rare, not constant
- avoid annoying repetition
- use multiple variants per sound type
- keep core gameplay sounding intimate, soft, and satisfying

### Example sound stack ideas
#### Normal hit
- soft pop
- thumb/finger thud
- micro squish

#### Drag squish
- sticky peel
- elastic stretch
- wet body squish

#### Burst
- crack
- wet pop
- splat tail
- tiny shimmer

#### Rare reveal
- reveal chime
- airy shimmer
- whisper line

### Desired player feeling
“I want to hear that again.”

---

# P2 Enhancements

## 8) Make rare moments feel more earned and collectible
### Problem
Rare moments already look promising, but they can become more memorable.

### Goals
Increase excitement, retention, and shareability.

### Claude tasks
- Add stronger rare-core or rare-variant reveal treatment
- Add micro pause or anticipation beat before rare reveal
- Use unique rare particle palette
- Add a collectible card, badge, or shelf reward after reveal
- Make rare moments easy to distinguish instantly from standard reveals

### Desired player feeling
“I got something rare and I want to show it.”

---

## 9) Improve session start speed and first 30 seconds
### Problem
The app should get players into satisfying interaction extremely fast.

### Goals
Reduce friction and improve first-session retention.

### Claude tasks
- Let the player quickly jump back into last selected pack
- Reduce unnecessary delay between menu and gameplay
- Consider auto-loading last used pack on relaunch
- Ensure the first reveal/burst happens quickly enough to hook users

### Desired player feeling
“I’m instantly back in the fun.”

---

# Specific Product Direction from Visual Review

## What already looks strong
- themed packs make the game feel larger than a single gimmick
- score and combo ramp gives momentum
- toy-like squishies are cute and readable
- reveal backgrounds create premium-feeling moments
- clean UI avoids clutter

## What now matters most
Not “make it prettier.”
Instead:
- make every tap feel more reactive
- make special moments more dramatic
- make rewards happen on a satisfying cadence
- make the game more recordable and shareable

---

# Recommended Sprint Order

## Sprint 1 — Juice Pass
Claude should prioritize:
1. stronger squash/stretch
2. better recoil and rebound
3. improved burst snap
4. larger active squishy scale
5. upgraded themed particles

## Sprint 2 — Reward Pass
Claude should prioritize:
1. stronger reveal transition
2. progress bar anticipation effects
3. facial reaction states
4. rare reveal treatment
5. stronger combo threshold feedback

## Sprint 3 — Audio Pass
Claude should prioritize:
1. layered tactile SFX system
2. multiple sound variations
3. rare reveal chimes
4. occasional whisper lines
5. audio balancing to preserve ASMR feel

## Sprint 4 — Retention Pass
Claude should prioritize:
1. faster first-session hook
2. better return-to-last-pack flow
3. stronger rare/collection motivation
4. more visible reward pacing
5. easier “one more session” loop

---

# Metrics to Watch After Changes
After each round of changes, compare:
- session length
- first burst timing
- reveal trigger rate
- combo frequency
- replay/share intent
- tester comments about “satisfying” feel
- tester comments about repetition or boredom

If possible, instrument:
- time to first burst
- time to first reveal
- average combo achieved
- percentage of sessions that hit reveal state
- particle-heavy frame performance
- audio trigger counts by type

---

# Claude Build Notes
Claude should not overbuild new systems before improving tactile quality.

## Do first
- hit feel
- particle feel
- reveal contrast
- facial personality
- sound design identity

## Do second
- reward clarity
- rare moment treatment
- faster session start

## Do later
- deeper meta systems
- more content breadth
- larger monetization systems

---

# Final Direction
Squishy Smash already looks like a real app with strong visual potential.

The next leap is to turn it from:
- cute and polished

into:
- irresistibly tactile
- emotionally rewarding
- visually explosive in special moments
- satisfying enough that players want to record and share it

That should be the guiding principle for the next Claude Code sprint.
