import 'dart:math';

import 'package:flame/components.dart';

class ScreenShake extends Component {
  ScreenShake({required this.camera});

  final CameraComponent camera;
  final Random _rng = Random();
  double _remaining = 0;
  double _intensity = 0;
  late final Vector2 _origin;
  bool _captured = false;

  void shake({double duration = 0.18, double intensity = 8}) {
    if (!_captured) {
      _origin = camera.viewfinder.position.clone();
      _captured = true;
    }
    _remaining = duration;
    _intensity = intensity;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_captured) return;
    if (_remaining > 0) {
      _remaining -= dt;
      camera.viewfinder.position = _origin +
          Vector2(
            (_rng.nextDouble() - 0.5) * 2 * _intensity,
            (_rng.nextDouble() - 0.5) * 2 * _intensity,
          );
    } else {
      camera.viewfinder.position = _origin;
    }
  }
}
