import 'dart:math';

import 'package:flame/components.dart';

class ScreenShake extends Component {
  ScreenShake({required this.camera});

  final CameraComponent camera;
  final Random _rng = Random();
  double _remaining = 0;
  double _durationStart = 0;
  double _intensity = 0;
  late final Vector2 _origin;
  bool _captured = false;

  void shake({double duration = 0.18, double intensity = 8}) {
    if (!_captured) {
      _origin = camera.viewfinder.position.clone();
      _captured = true;
    }
    _remaining = duration;
    // GAME_POLISH_AUDIT.md P1-B: cache the start duration so update()
    // can derive a linear-falloff envelope (`_remaining / _durationStart`).
    // Without the envelope, the previous version held flat amplitude
    // for the whole window then snapped back — the biggest moments
    // (mythic at intensity=14) felt like a phone vibrating on a table
    // instead of a detonation.
    _durationStart = duration;
    _intensity = intensity;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_captured) return;
    if (_remaining > 0) {
      _remaining -= dt;
      final envelope = computeEnvelope(_remaining, _durationStart);
      camera.viewfinder.position = _origin +
          Vector2(
            (_rng.nextDouble() - 0.5) * 2 * _intensity * envelope,
            (_rng.nextDouble() - 0.5) * 2 * _intensity * envelope,
          );
    } else {
      camera.viewfinder.position = _origin;
    }
  }

  /// Linear falloff envelope: full intensity at t=0, zero at t=duration.
  /// Extracted as a pure static so the falloff curve can be locked by
  /// `test/screen_shake_test.dart` without needing a CameraComponent.
  /// Clamped because `remaining` can briefly go slightly negative
  /// before the update() else-branch resets to origin on the next tick.
  static double computeEnvelope(double remaining, double total) {
    if (total <= 0) return 0.0;
    return (remaining / total).clamp(0.0, 1.0);
  }
}
