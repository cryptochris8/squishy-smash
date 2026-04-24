import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Full-screen white bloom flash triggered on a reveal-tier burst.
/// Opacity ramps 0 -> [peakOpacity] -> 0 over [duration] using a
/// triangle curve with an early peak (t≈0.22) so the flash feels
/// punchy rather than lingering.
///
/// Scales by rarity at the caller:
///   rare    -> 0.35 peak, 400ms
///   epic    -> 0.50 peak, 500ms
///   mythic  -> 0.65 peak, 700ms (adds an emotional "held" beat)
class RevealBloom extends PositionComponent {
  RevealBloom({
    required Vector2 arenaSize,
    required this.peakOpacity,
    required this.duration,
  }) : super(size: arenaSize, priority: 9999);

  final double peakOpacity;
  final Duration duration;

  double _elapsed = 0;

  /// Pure triangle-curve helper (exposed static so tests can verify
  /// the alpha envelope without instantiating the component).
  static double bloomShape(double t) {
    if (t <= 0 || t >= 1) return 0.0;
    const peak = 0.22;
    if (t < peak) return t / peak;
    return 1.0 - ((t - peak) / (1.0 - peak));
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration.inMilliseconds / 1000) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final totalSec = duration.inMilliseconds / 1000;
    if (totalSec <= 0) return;
    final t = (_elapsed / totalSec).clamp(0.0, 1.0);
    final shape = bloomShape(t);
    final alpha = (shape * peakOpacity * 255).round().clamp(0, 255);
    if (alpha == 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Color.fromARGB(alpha, 255, 255, 255),
    );
  }
}
