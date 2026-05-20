# R-1 "Share Your Pull" — Full Video Capture: Implementation Plan

Status: **draft / not started** — gated on the product decision in
"Gating risk" below. Source audit item: R-1 in `GAME_POLISH_AUDIT.md`.

## Goal

When a player pulls a mythic, let them share a **video clip** of the
reveal — including the few seconds *before* the pull — to
TikTok/Reels/Shorts via the native share sheet. This replaces the
static screenshot in the existing "Save this clip?" flow.

Rationale: Squishy Smash's growth model is video-native social
virality (creator-seeding, trend-energy packs). A static screenshot
discards the motion — skybox crossfade, shake, gold particle spray —
that makes the mythic moment shareable.

## Core technical decision: capturing "the seconds before"

A Flame game renders to one surface, so screen recording captures it
cleanly. The hard part is the **rolling buffer** — having footage of
the moments *before* the mythic, which can't be predicted.

| Platform | Approach | Notes |
|----------|----------|-------|
| iOS | ReplayKit `RPScreenRecorder.startClipBuffering` / `exportClipToURL(duration:)` (iOS 15+) | Purpose-built rolling buffer — keeps ~last 15s, export last N on demand. Exactly what R-1 needs. |
| Android | MediaProjection — record continuously from round start, trim a trailing window on mythic | No native rolling buffer; needs a foreground service + post-trim (MediaMuxer or ffmpeg). |

**Recommendation: ship iOS-first.** ReplayKit clip buffering delivers
R-1 cleanly; Android is a materially different, heavier build. The
product is iOS-first anyway (Codemagic -> TestFlight -> App Store).
Treat Android as Phase 2.

The common `flutter_screen_recording` plugin is start/stop only — it
does **not** expose ReplayKit clip buffering. This needs a **custom
platform channel** (a thin local plugin), not an off-the-shelf
package.

## Architecture

New `ClipCaptureService`, parallel to the existing
`ShareCaptureService` in `lib/game/share_capture.dart`:

```
ClipCaptureService
 |- startBuffering()      -> MethodChannel -> RPScreenRecorder.startClipBuffering
 |- exportClip(seconds)   -> exportClipToURL -> returns a temp .mp4 path
 |- stopBuffering()
```

Native side: a small Swift class behind a
`MethodChannel("squishy/clip_capture")`, plus an Android stub for
Phase 2.

## Integration points (all already exist in the codebase)

1. **Round start** — `GameplayScreen.initState` / `SquishyGame.onLoad`:
   call `startBuffering()`.
2. **Mythic reveal** — `onMythicReveal` already fires
   (`squishy_game.dart` -> `GameplayScreen._handleMythicReveal`). On
   that callback, call `exportClip(~12s)`.
3. **Share** — the existing "Save this clip?" `SnackBar`
   (`_showMythicShareSheet`) SHARE action: swap
   `ShareCaptureService.shareSnapshot` for sharing the exported
   `.mp4` via `Share.shareXFiles`. Captions (`ShareCaptions.forMythic`)
   are reused as-is.
4. **Round end / dispose** — `_endRound` + the lifecycle observer:
   `stopBuffering()`.
5. **Graceful fallback** — if buffering failed/unsupported (iOS <15,
   permission denied), fall back to the current screenshot path. No
   regression to the existing share flow.

## Native configuration

- **iOS Info.plist**: `NSPhotoLibraryAddUsageDescription` (only if
  also offering save-to-camera-roll). **Do not record the mic** — app
  audio only — so no `NSMicrophoneUsageDescription` and a cleaner
  privacy story for a kids' app.
- **`PrivacyInfo.xcprivacy`**: declare any new required-reason API
  usage.
- **Codemagic**: no new CocoaPods if this stays a pure
  platform-channel + ReplayKit (a system framework) — minimal CI
  change.
- **Android (Phase 2)**: `FOREGROUND_SERVICE` +
  `FOREGROUND_SERVICE_MEDIA_PROJECTION`, a foreground service, and the
  per-session MediaProjection consent dialog.

## Gating risk — App Store review (resolve BEFORE coding)

**Is the app submitted under Apple's "Made for Kids" category?** If
yes, a share-to-social feature is heavily scrutinized and may require
parental gating or be disallowed outright. This is a product/legal
decision that **gates the whole feature** — answer it before any
code. If it is a general 4+ app (not the Kids category), R-1 is fine
with normal care.

## Other risks

- **No-Mac iteration loop**: every native iOS change cycles through
  Codemagic -> TestFlight -> physical iPhone (~15+ min). Screen
  recording cannot be validated in a simulator. Budget for slow
  iteration — this is the single biggest schedule risk.
- ReplayKit shows a system recording indicator and a first-use
  permission prompt — expected, but verify it does not disrupt the
  mythic moment.
- Clip export is async (~1-2s) — the "Save this clip?" SnackBar must
  show a brief "preparing..." state.

## Phasing

| Phase | Work | Est. |
|-------|------|------|
| 0 | Resolve the Made-for-Kids review question | product decision |
| 1 | Spike: ReplayKit clip buffering through a platform channel, on a real device | 0.5-1 day |
| 2 | `ClipCaptureService` + native iOS channel + mythic-flow integration + fallback | 1.5-2 days |
| 3 | iOS native config, permission UX, Codemagic, TestFlight validation | 1 day (+ slow iteration) |
| 4 | *(later)* Android MediaProjection + foreground service + trim | 2-3 days |
| 5 | *(optional)* Branded end-card — needs `ffmpeg_kit_flutter` for compositing; defer, the hashtag caption carries branding for v1 | 1 day |

**iOS-only R-1: ~3-4 focused days.** Branded video compositing
(Phase 5) is deliberately deferred — it adds a heavy ffmpeg
dependency; the share caption + `#squishysmash` does the branding job
for launch.

## Open decisions before this becomes real work

1. Made-for-Kids App Store category — gates the whole feature.
2. Confirm iOS-first / Android-later is acceptable.
3. Confirm app audio is captured but microphone is not.
