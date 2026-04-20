import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart';

import '../../core/constants.dart';

class _DecalSplat extends PositionComponent with HasPaint {
  _DecalSplat({required Color color, required double radius})
      : _radius = radius {
    paint = Paint()..color = color.withValues(alpha: 0.85);
  }

  final double _radius;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(_radius * 2);
    add(OpacityEffect.fadeOut(
      EffectController(duration: Tunables.decalFade.inMilliseconds / 1000),
      onComplete: removeFromParent,
    ));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(_radius, _radius), _radius, paint);
  }
}

class DecalManager extends Component {
  final Queue<_DecalSplat> _live = Queue<_DecalSplat>();
  final Random _rng = Random();

  void spawn(Vector2 position, {required String preset}) {
    final splat = _DecalSplat(
      color: _colorForPreset(preset),
      radius: 26 + _rng.nextDouble() * 22,
    )..position = position + Vector2((_rng.nextDouble() - 0.5) * 24, 8);
    parent?.add(splat);
    _live.add(splat);
    while (_live.length > Tunables.decalCap) {
      final old = _live.removeFirst();
      old.removeFromParent();
    }
  }

  Color _colorForPreset(String preset) {
    switch (preset) {
      case 'cool_blue_smear':
        return const Color(0xCC7FE7FF);
      case 'cream_smudge':
        return const Color(0xCCFFE6BD);
      case 'green_goo_smear':
        return const Color(0xCCB6FF5C);
      case 'purple_monster_splat':
        return const Color(0xCCB084F2);
      case 'soft_peach_splat':
      default:
        return const Color(0xCCFF8FB8);
    }
  }
}
