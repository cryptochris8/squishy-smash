# Squishy Smash — Claude Code Implementation Pack

This pack is designed to help Claude Code build **Squishy Smash**, a simple iOS-first casual game inspired by the satisfying destruction loop of Rage Smash, but adapted for **viral meme-energy, squishy physics, ASMR audio, and fast content drops**.

## Core Goal
Build a **simple, replayable, satisfying smash game** with:
- short-session gameplay (5–20 seconds)
- juicy squish / pop / splat feedback
- meme-inspired content packs that can be swapped in without rewriting the core game
- iOS App Store positioning around **squishy, satisfying, ASMR, antistress, and meme-style chaos**

## What This Pack Includes
- `01_product_brief.md` — product vision, audience, positioning
- `02_game_loop_and_systems.md` — gameplay systems and progression
- `03_content_pipeline.md` — reusable content architecture for weekly drops
- `04_audio_vfx_plan.md` — ElevenLabs, Arts.io, particles, splats, impact feel
- `05_ios_build_spec.md` — recommended technical structure for an MVP
- `06_app_store_aso.md` — App Store title, subtitle, keywords, screenshots, metadata ideas
- `07_tiktok_campaign.md` — short-form launch strategy and hooks
- `08_ip_and_trend_guardrails.md` — how to ride trends without copying protected IP
- `prompts/claude_one_shot_prompt.md` — direct Claude Code build prompt
- `config/sample_content_pack.json` — example content data structure
- `config/sample_liveops_schedule.json` — example live content rotation schedule

## Recommended MVP
Ship the first version with **three content sets**:
1. Squishy Foods
2. Goo & Fidgets
3. Creepy-Cute Monsters (inspired by internet toy energy, but original)

## Recommended Technical Direction
Because the broader Athlete Domains ecosystem already uses Flutter heavily, the easiest path is:
- **Flutter + Flame** for the core game loop
- Sprite-based 2D gameplay
- JSON-driven content packs
- Local-first MVP with room for Remote Config later

If Claude believes another iOS-friendly stack is meaningfully better for this exact game feel, it can justify that decision, but the default recommendation is Flutter + Flame for reuse and speed.

## Product Thesis
The winning move is **not** to build a single meme game.
The winning move is to build a **meme-ready satisfying game engine** that can absorb new internet trends every week through content packs, sounds, and visuals.
