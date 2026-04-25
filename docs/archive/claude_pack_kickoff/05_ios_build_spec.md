# 05 — iOS Build Spec

## Recommended MVP Stack
### Default Recommendation
- **Flutter** for app shell and cross-project familiarity
- **Flame** for 2D game loop, collision, animation, and effects
- local JSON-driven content configuration
- optional Firebase / Remote Config later for live content tuning

## Why This Fits
This is a compact casual game, not a heavy 3D world.
The goal is speed, iteration, and content agility.
Flutter + Flame should be enough for:
- responsive touch input
- simple arena physics feel
- animated sprites
- particles
- score / menu UI
- haptics and audio

## MVP Scene Breakdown
### 1. Splash / Loading
- game logo
- featured pack banner

### 2. Main Menu
- Play
- Shop
- Packs
- Settings

### 3. Gameplay Scene
- central object spawn area
- score display
- combo meter
- quick-use boost slot optional later

### 4. Results Screen
- score
- combo best
- coins earned
- share-worthy stat callout

### 5. Shop / Pack Screen
- unlock objects
- featured pack card
- arena skins
- sound pack previews optional later

## Architecture Suggestion
### Presentation Layer
- Flutter menus and non-game UI

### Game Layer
- Flame game scene
- entity system for smashable objects
- particle manager
- sound manager
- haptics manager
- combo and score controllers

### Data Layer
- JSON config loader
- unlock state storage
- local persistence

## Key Systems to Implement First
1. object spawn manager
2. touch input controller
3. squash / deform reaction controller
4. burst threshold logic
5. particle emission system
6. sound event dispatcher
7. score and combo system
8. unlock persistence

## Object Implementation Model
Each object should expose:
- sprite / animation
- deform state
- hit response curve
- burst conditions
- burst result package

## Performance Notes
Keep the MVP efficient by:
- using 2D sprites rather than full dynamic 3D
- capping simultaneous decals and particles
- pooling particle systems
- compressing audio assets smartly
- avoiding overbuilt physics simulation where fake juice will look better anyway

## Important Feel Rule
The game should favor **game feel** over realistic physics.
If fake squash-and-stretch feels better than strict simulation, choose the fake version.

## Analytics Events
Track these from day one:
- session_start
- round_complete
- object_destroyed
- burst_type_triggered
- combo_peak
- pack_selected
- shop_viewed
- pack_unlocked
- ad_viewed if added later
- share_intent if added later

## Monetization Framework
### Initial Monetization
- rewarded ad for bonus coins
- unlockable packs via coins
- small IAP pack bundles later

### Good Early IAP Candidates
- Starter Squish Bundle
- Creepy-Cute Bundle
- Infinite Goo visual pack

## UI Principles
- big readable buttons
- minimal text during play
- tactile menu transitions
- playful oversized object cards in store

## MVP Milestone Order
### Milestone 1
Single object, tap interaction, sound, burst

### Milestone 2
3–5 object types, score, combo, particles

### Milestone 3
pack system, menus, unlocks, simple shop

### Milestone 4
launch polish, haptics, app store assets, analytics
