import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';
import '../../core/constants.dart';

class ParticleManager extends Component {
  final Random _rng = Random();

  void burst(Vector2 position, {required String preset, double intensity = 0.7}) {
    final color = _colorForPreset(preset);
    final count = (28 + intensity * 36).round();
    // One Paint shared across all particles in the burst. Pre-fix this
    // allocated a Paint + Color per particle (28-65 per burst), all
    // immediately eligible for GC at burst end. The paint is read-only
    // inside Flame's CircleParticle so sharing is safe.
    final sharedPaint = _paintForColor(color);
    final particle = Particle.generate(
      count: count,
      lifespan: 0.9,
      generator: (i) {
        final angle = _rng.nextDouble() * pi * 2;
        final speed = 80 + _rng.nextDouble() * 220 * intensity;
        final velocity = Vector2(cos(angle), sin(angle)) * speed;
        return AcceleratedParticle(
          acceleration: Vector2(0, 480),
          speed: velocity,
          child: CircleParticle(
            radius: 3 + _rng.nextDouble() * 5,
            paint: sharedPaint,
          ),
        );
      },
    );
    parent?.add(ParticleSystemComponent(particle: particle, position: position));
  }

  /// Cached `Paint` per preset color. The set of presets is closed
  /// (6 entries) and Paint+Color allocation is the single biggest
  /// short-lived allocation in the burst path. Cached lazily so the
  /// game doesn't pay for paints it never uses.
  final Map<int, Paint> _paintCache = <int, Paint>{};

  Paint _paintForColor(Color color) {
    final faded = color.withValues(alpha: 0.9);
    final key = faded.toARGB32();
    return _paintCache.putIfAbsent(key, () => Paint()..color = faded);
  }

  Color _colorForPreset(String preset) {
    switch (preset) {
      case 'blue_jelly_burst':
        return Palette.jellyBlue;
      case 'cream_puff_burst':
        return const Color(0xFFFFE6BD);
      case 'green_goo_burst':
        return Palette.toxicLime;
      case 'purple_monster_burst':
        return const Color(0xFFB084F2);
      case 'gold_mythic_burst':
        return const Color(0xFFFFD15C);
      case 'pink_soup_burst':
      default:
        return Palette.pink;
    }
  }
}
