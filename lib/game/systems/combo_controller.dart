import '../../core/constants.dart';

/// Visual/audio "feel" tier derived from a raw hit streak. Maps to the
/// tuning-doc thresholds — "combo 3 = tiny pulse, 6 = stronger glow,
/// 10 = reveal-ready, 15+ = mega burst".
enum ComboTier { none, starter, stronger, revealReady, mega }

ComboTier comboTierFor(int streak) {
  if (streak >= 15) return ComboTier.mega;
  if (streak >= 10) return ComboTier.revealReady;
  if (streak >= 6) return ComboTier.stronger;
  if (streak >= 3) return ComboTier.starter;
  return ComboTier.none;
}

class ComboController {
  int _streak = 0;
  int peak = 0;
  double _decayLeft = 0;
  bool _wasLostThisTick = false;

  int get streak => _streak;

  int get multiplier {
    if (_streak < 3) return 1;
    final raw = (_streak ~/ 3) + 1;
    return raw.clamp(1, Tunables.comboMaxMultiplier);
  }

  double get fill {
    if (Tunables.comboDecay.inMilliseconds == 0) return 0;
    return (_decayLeft / (Tunables.comboDecay.inMilliseconds / 1000)).clamp(0.0, 1.0);
  }

  /// Current milestone tier from [_streak]. Drives HUD styling and
  /// particle accents.
  ComboTier get currentTier => comboTierFor(_streak);

  /// True for exactly the tick in which the decay timer just expired
  /// and zeroed the streak. Cleared at the top of the next [tick] so
  /// callers (SquishyGame → selection haptic, HUD → multiplier flash)
  /// get a one-shot signal per loss event — GAME_POLISH_AUDIT.md P1-F.
  /// Pre-fix the streak silently reset to 0 with no visual or haptic
  /// cue, so players never learned that timing was a skill.
  bool get wasLostThisTick => _wasLostThisTick;

  /// Register a successful hit. Returns the tier just crossed if this
  /// bump moved the streak into a higher milestone (so callers can
  /// fire a one-shot feedback stinger), or null if the tier didn't
  /// change.
  ComboTier? bump() {
    final before = comboTierFor(_streak);
    _streak += 1;
    if (_streak > peak) peak = _streak;
    _decayLeft = Tunables.comboDecay.inMilliseconds / 1000;
    final after = comboTierFor(_streak);
    return after != before ? after : null;
  }

  void tick(double dt) {
    // Clear the one-shot loss flag at the top of each tick so the
    // caller sees it true for exactly one frame and false thereafter.
    _wasLostThisTick = false;
    if (_decayLeft > 0) {
      _decayLeft -= dt;
      if (_decayLeft <= 0) {
        // Only flag a loss if there was actually a streak to lose —
        // ticking a freshly reset controller (streak already 0) is a
        // no-op, not a loss event.
        if (_streak > 0) _wasLostThisTick = true;
        _streak = 0;
        _decayLeft = 0;
      }
    }
  }

  void reset() {
    _streak = 0;
    _decayLeft = 0;
    _wasLostThisTick = false;
  }
}
