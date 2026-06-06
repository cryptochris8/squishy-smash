# Match-Cut Video v1 — "Every pop is a hello."

22-second portrait (1080×1920) silent MP4 — built 2026-06-04.

**Output file:** `docs/marketing/match_cut_video.mp4` (~4 MB)

---

## Beat sheet

| Time | Beat | Visual | Purpose |
|---|---|---|---|
| 0.0-1.0s | Cover zoom-in | Book 2 cover, slow Ken Burns | Brand frame |
| 1.0-4.0s | Book spread reveal | Spread 18 watercolor, pan toward Soft Dumpling face | Hook |
| 4.0-5.0s | **HOLD** | Soft Dumpling face, frozen | The match-cut anchor |
| 5.0-7.5s | **MATCH CUT** | Celestial Dumpling 3D card art, zoom + pulse | The reveal — same character, two textures |
| 7.5-12.5s | Gameplay | mythic.mp4 gameplay (cropped to portrait) | Proves the game is real |
| 12.5-15.0s | Match cut back | Spread 18 zooms out to wide | Brings you back to the story |
| 15.0-18.0s | Cover + tagline | Book 2 cover + "Every pop is a hello." | The brand-mark message |
| 18.0-22.0s | End title | Squishy Smash / THE LOST SPARKLE / on Amazon now | CTA |

## Why this works (per the viral playbook research)

- **Same character, two textures** is the cross-promo pattern that doesn't read sales-y — you're showing TWO sides of one IP, not advertising
- **Match-cut at 5s** is the retention spike beat — viewers scrolling who reach 5s typically finish
- **Texture contrast** (watercolor → 3D) is the proven pattern in cute-collection content
- **Silent by design** — you pick a trending TikTok sound at upload; that's the 2026-correct move

## How to upload

### TikTok (brand account — Squishy Smash)
1. Open TikTok, hit + → Upload
2. Pick `match_cut_video.mp4`
3. Add Sound — **search "Dru meets Gru"** (Despicable Me clip currently spiking on character-debut content). Alternative: any soft coconut-tap or bubble-pop ASMR sound currently in your "For You" feed.
4. Caption (under 150 chars): `Soft Dumpling has two lives. The book is on Amazon. The game is on the App Store. Every pop is a hello. 💛`
5. Hashtags: `#picturebook #booktok #squishies #indieauthor #kidsbooks #asmr #satisfying #mobilegame #spartanburgsc #amazonbooks`
6. Cover thumb: scrub to 16s (the cover+tagline beat) and save as cover
7. Disable comments? **No** — comments fuel the algorithm
8. Cross-post to Instagram Reels? **Yes** — it's a free re-publish

### YouTube Shorts
1. Same video, same caption shortened
2. YT Shorts rewards original audio + retention — keep silent OR add light ambient music
3. Hashtags in description: `#Shorts #picturebook #squishies #SquishySmash #indieauthor`
4. Title: `Soft Dumpling lives in a book AND a game. 📖➡️📱 #Shorts`
5. **Add an end screen** linking to your read-along video (free retention to your main YouTube channel)

### Instagram Reels
1. Cross-post from TikTok (built-in via TikTok app) OR re-upload
2. **Use a TikTok sound** still works on Reels but lag by ~24h vs TikTok
3. Caption can be longer than TikTok — add the Amazon links

### X / Twitter
1. Drop the video as a standalone post
2. Quote-pin to your profile
3. Caption: `Soft Dumpling lives in two places now — a children's book and a mobile game. Made the whole thing solo in Spartanburg, SC. Every pop is a hello. 💛 [link to substack]`

### Reddit
- r/picturebooks — caption: "I made my second picture book this year (40 pages, watercolor). Here's a 22s match-cut showing the same character in book + game forms. Happy to AMA on the AI pipeline I used."
- r/StableDiffusion / r/aiArt — focus on the cross-medium IP angle
- r/IndieDev — focus on the game + book combo as IP-builder play

## How to iterate

The script is at `tools/marketing/build_match_cut_video.py`. To make v2:

- Change `SPREAD18` to a different `_preview_spread*.jpg` if you want a different match target
- Change `DUMPLING_3D` to any 1024×1024 hero shot at `assets/website_hero/`
- Change `gameplay_clip(p, start=8.0, duration=5.0)` to use a different segment of mythic.mp4
- Run `python tools/marketing/build_match_cut_video.py`
- Output overwrites the same file

## Variant ideas for the next 3 videos (per viral playbook agent)

1. **"POV: you found the last Dumplio in the box"** — 12s, screen-recorded game pack opening, last slot empty, then pop. Trending sound. Personal TikTok (@CryptoChris8).
2. **"Read it. Play it. Same Squishy."** — 18s, texture-first 6× zoom on watercolor → page turn → game burst → tagline card. YouTube Shorts (search-durable).
3. **Build-in-public clip** — 30s, side-by-side of Pivot 2 (failed FLUX) vs Pivot 5 (NBP). Promotes the Substack post. X + Reddit.
