You are building the MVP for an iOS-first casual mobile game called **Squishy Smash**.

Read all markdown files in this implementation pack first, then produce the game in a clean, scalable architecture.

## Product Summary
Squishy Smash is a short-session, satisfying smash game inspired by the core instant-gratification loop of Rage Smash, but refocused around:
- squishy and deformable objects
- strong popping / splatting / goo feedback
- meme-inspired content drops
- ASMR and antistress appeal
- clip-friendly visuals for TikTok / Reels

## Technical Direction
Default to **Flutter + Flame** unless you can clearly justify a better stack for this exact game.
The game should be iPhone-first.

## Build Requirements
1. Create a playable MVP with:
   - main menu
   - gameplay scene
   - results screen
   - shop / packs screen
2. Implement a reusable content-driven object system using JSON config.
3. Add at least 3 launch packs:
   - Squishy Foods
   - Goo & Fidgets
   - Creepy-Cute Creatures
4. Add touch interactions:
   - tap smash
   - drag slam
   - hold-to-crush
5. Add score and combo system.
6. Add particles, splats, and simple decals.
7. Add sound manager with layered hit / burst events.
8. Add haptics mapping for iPhone.
9. Add simple unlock progression using coins and local persistence.
10. Structure code so new content packs can be added without rewriting core gameplay.

## Game Feel Rules
- Prioritize feel over realistic physics.
- Every hit should create visual, audio, and tactile payoff.
- The first 5 seconds of gameplay must already feel satisfying.
- Use bright readable visuals and exaggerated squash-and-stretch.

## Content Rules
- Do not use copyrighted character names or direct copies.
- Create original creepy-cute and squishy object designs.
- Keep all trend-inspired content original and safely distinct.

## MVP Deliverables
- functioning codebase
- clean folder structure
- sample JSON-driven content system
- placeholder assets clearly labeled where custom final art/audio should be inserted
- notes for where ElevenLabs audio and Arts.io visuals should be plugged in
- concise README for running and extending the project

## Engineering Quality
- production-minded naming
- modular systems
- avoid overengineering
- optimize for fast iteration and future content drops

## After MVP
Once the playable foundation works, generate:
- a list of polish improvements
- a list of App Store asset needs
- a list of social clip capture moments
