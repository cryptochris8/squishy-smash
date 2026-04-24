# Squishy Smash — Claude Code Asset Production Pack
#
# Purpose:
# This file tells Claude Code exactly how to integrate the new Squishy Smash
# branding assets into the Flutter/iOS project, organize exports, and prepare
# the app for App Store / TestFlight / marketing usage.

## Objective
Integrate the new logo and icon direction into the production pipeline cleanly and consistently.

Assets now conceptually available:
- primary logo with mascot
- bunny/cream icon candidate
- pink mascot icon candidate
- dumpling reveal icon candidate

Main goals:
1. wire branding into Flutter project structure
2. prepare iOS app icon export pipeline
3. prepare splash/menu branding usage
4. prepare marketing/export folders
5. keep the system scalable for A/B tests and future seasonal updates

---

# 1. Project asset structure

Claude should create or verify the following structure:

```text
assets/
  branding/
    logo/
      squishy_smash_logo_primary.png
      squishy_smash_logo_transparent.png
      squishy_smash_logo_lockup_horizontal.png
      squishy_smash_logo_lockup_vertical.png
    icon/
      squishy_smash_icon_bunny_v1.png
      squishy_smash_icon_pink_v1.png
      squishy_smash_icon_dumpling_v1.png
    splash/
      splash_background_gradient.png
      splash_logo_centered.png
    social/
      squishy_smash_title_card_v1.png
      squishy_smash_creator_card_v1.png
    store/
      app_store_feature_graphic_v1.png
      screenshot_frame_pack_foods_v1.png
      screenshot_frame_goo_v1.png
      screenshot_frame_creepycute_v1.png
```

If some files do not exist yet, Claude should create TODO placeholders and document them clearly.

---

# 2. Flutter pubspec integration

Claude should update `pubspec.yaml` so branding assets are properly bundled.

Recommended section:

```yaml
flutter:
  assets:
    - assets/branding/logo/
    - assets/branding/icon/
    - assets/branding/splash/
    - assets/branding/social/
    - assets/branding/store/
```

Claude should keep branding assets separate from gameplay object assets for cleanliness.

---

# 3. App icon production workflow

## Recommended primary icon
Start with:
- `squishy_smash_icon_bunny_v1.png`

## A/B candidates
Also keep ready:
- `squishy_smash_icon_pink_v1.png`
- `squishy_smash_icon_dumpling_v1.png`

## Claude tasks
Claude should:
1. place source icon art into the branding/icon folder
2. prepare iOS icon exports from the chosen source image
3. document how to swap icon candidates quickly for future testing
4. preserve original master icon file at highest available resolution

---

# 4. iOS icon export requirements

Claude should prepare a production-ready icon workflow for iOS.

## Required sizes to export
Claude should generate the icon sizes needed for iPhone AppIcon sets, including common sizes such as:
- 20x20
- 29x29
- 40x40
- 60x60
- 58x58
- 76x76
- 80x80
- 87x87
- 120x120
- 152x152
- 167x167
- 180x180
- 1024x1024

Claude should verify the exact Contents.json/AppIcon set structure required by the current Flutter+iOS project.

## Recommended output structure
```text
ios/Runner/Assets.xcassets/AppIcon.appiconset/
  Icon-App-20x20@1x.png
  Icon-App-20x20@2x.png
  Icon-App-20x20@3x.png
  Icon-App-29x29@1x.png
  Icon-App-29x29@2x.png
  Icon-App-29x29@3x.png
  Icon-App-40x40@1x.png
  Icon-App-40x40@2x.png
  Icon-App-40x40@3x.png
  Icon-App-60x60@2x.png
  Icon-App-60x60@3x.png
  Icon-App-76x76@1x.png
  Icon-App-76x76@2x.png
  Icon-App-83.5x83.5@2x.png
  Icon-App-1024x1024@1x.png
  Contents.json
```

Claude should update this cleanly and preserve a backup if icons are already present.

---

# 5. Splash screen usage

## Branding recommendation
Use the new primary logo with mascot for the splash/loading screen.

## Claude tasks
Claude should:
- create a splash composition using a soft pink/blue/purple gradient background
- center the primary logo cleanly
- maintain breathing room around the logo
- keep the splash elegant and premium, not cluttered

## Desired feel
The splash should communicate:
- cute
- polished
- premium
- mobile-native
- collectible toy energy

---

# 6. Main menu branding usage

Claude should update the menu/header flow so the branding is consistent.

## Recommended usage
- primary logo on the home/menu screen
- icon mascot optionally reused for profile/avatar/loading markers
- pack section headers styled to match the brand palette
- soft rounded cards and glow accents aligned with logo aesthetics

## Avoid
- overly large logo that pushes gameplay too far down
- overly busy header areas
- mismatched typography or harsh UI colors

---

# 7. Store and marketing derivatives

Claude should prepare a reusable marketing system from the new art direction.

## Recommended outputs
Create templates for:
- App Store screenshots
- App preview opening slate
- TikTok/Reels title cards
- creator promo cards
- TestFlight announcement visuals
- social post feature graphics

## Suggested folder structure
```text
marketing/
  app_store/
  testflight/
  tiktok/
  creators/
  social_posts/
```

---

# 8. A/B testing support

Claude should structure the branding system so icon and splash variants can be swapped easily.

## Test plan
### Icon test 1
- bunny icon vs pink icon

### Icon test 2
- bunny icon vs dumpling icon

### Logo test
- logo with mascot vs cleaner mascot-less version later

### Background test
- softer gradient vs stronger contrast gradient

## Implementation rule
Keep source files and export scripts organized so changing the icon does not require manual project surgery every time.

---

# 9. Naming and versioning rules

Claude should use clean versioned naming:

## Examples
- `squishy_smash_logo_primary_v1.png`
- `squishy_smash_icon_bunny_v1.png`
- `squishy_smash_icon_bunny_v2.png`
- `squishy_smash_icon_pink_v1.png`
- `squishy_smash_splash_v1.png`

Do not overwrite master concept files without versioning.

---

# 10. Recommended Flutter integration tasks

Claude should implement these tasks in order:

## P0
1. create branding asset folders
2. add/update pubspec asset references
3. place primary logo and primary icon source files
4. generate iOS icon set from primary icon
5. update splash branding
6. update main menu/header to use new logo

## P1
1. prepare pink icon export set
2. prepare dumpling icon export set
3. create reusable screenshot/title-card templates
4. create social/testflight marketing asset placeholders

## P2
1. add seasonal icon/logo support
2. prepare automated asset export script
3. prepare icon swap documentation for future A/B testing

---

# 11. Automation recommendation

Claude should create a simple internal asset prep script if helpful.

Possible responsibilities:
- resize source icon into required iOS outputs
- validate folder existence
- copy chosen branding asset into production paths
- generate/update AppIcon `Contents.json` if needed
- document which icon is currently active

Possible file:
```text
tool/generate_ios_icons.dart
```

or a small script in:
```text
scripts/generate_ios_icons.py
```

Use whichever is most practical for the current codebase.

---

# 12. Final directive for Claude

Claude should treat the new Squishy Smash logo and icon system as production branding, not throwaway concept art.

Priority:
1. make branding integration clean
2. make the bunny icon the initial production test
3. keep pink and dumpling variants ready
4. prepare export structure for App Store and marketing
5. keep everything versioned and easy to swap

The branding should now consistently communicate:

**cute + premium + satisfying + collectible + polished mobile game**
