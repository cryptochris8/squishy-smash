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
    if (_decayLeft > 0) {
      _decayLeft -= dt;
      if (_decayLeft <= 0) {
        _streak = 0;
        _decayLeft = 0;
      }
    }
  }

  void reset() {
    _streak = 0;
    _decayLeft = 0;
  }
}
