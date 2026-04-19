import '../../core/constants.dart';

class ComboController {
  int _streak = 0;
  int peak = 0;
  double _decayLeft = 0;

  int get multiplier {
    if (_streak < 3) return 1;
    final raw = (_streak ~/ 3) + 1;
    return raw.clamp(1, Tunables.comboMaxMultiplier);
  }

  double get fill {
    if (Tunables.comboDecay.inMilliseconds == 0) return 0;
    return (_decayLeft / (Tunables.comboDecay.inMilliseconds / 1000)).clamp(0.0, 1.0);
  }

  void bump() {
    _streak += 1;
    if (_streak > peak) peak = _streak;
    _decayLeft = Tunables.comboDecay.inMilliseconds / 1000;
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
