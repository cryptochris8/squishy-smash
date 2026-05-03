import 'combo_controller.dart';

/// Source-of-truth for the combo-milestone chime asset paths bundled with
/// the game. [FeedbackDispatcher.comboChimes] is populated from this, and
/// [SoundManager.warm] pre-caches them at boot so the first milestone in a
/// session doesn't stutter waiting for asset load.
///
/// All paths are relative to `assets/` and use the `audio/...` convention
/// that [SoundManager._normalize] strips before calling `flame_audio`.
///
/// Tier → chime mapping mirrors [comboTierFor] from combo_controller.dart:
///   ComboTier.starter      (streak 3)  → combo_3_*
///   ComboTier.stronger     (streak 6)  → combo_6_*
///   ComboTier.revealReady  (streak 10) → combo_10_*
///   ComboTier.mega         (streak 15) → combo_15_*
///   ComboTier.none                     → no chime
class ComboSoundRegistry {
  ComboSoundRegistry._();

  static const List<String> tierStarter = <String>[
    'audio/sfx/combo/combo_3_a.mp3',
    'audio/sfx/combo/combo_3_b.mp3',
  ];

  static const List<String> tierStronger = <String>[
    'audio/sfx/combo/combo_6_a.mp3',
    'audio/sfx/combo/combo_6_b.mp3',
  ];

  static const List<String> tierRevealReady = <String>[
    'audio/sfx/combo/combo_10_a.mp3',
    'audio/sfx/combo/combo_10_b.mp3',
  ];

  static const List<String> tierMega = <String>[
    'audio/sfx/combo/combo_15_a.mp3',
    'audio/sfx/combo/combo_15_b.mp3',
  ];

  /// Flat list of every bundled chime path. Passed to [SoundManager.warm]
  /// so the first milestone hit doesn't stutter waiting for asset load.
  static List<String> get allPaths => <String>[
        ...tierStarter,
        ...tierStronger,
        ...tierRevealReady,
        ...tierMega,
      ];

  /// Map keyed by [ComboTier] for direct lookup in
  /// [FeedbackDispatcher.comboChimes]. [ComboTier.none] is intentionally
  /// not present — the dispatcher should never reach a chime lookup for
  /// `none` (the call site filters that out before dispatching).
  static Map<ComboTier, List<String>> get dispatcherMap =>
      <ComboTier, List<String>>{
        ComboTier.starter: tierStarter,
        ComboTier.stronger: tierStronger,
        ComboTier.revealReady: tierRevealReady,
        ComboTier.mega: tierMega,
      };
}
