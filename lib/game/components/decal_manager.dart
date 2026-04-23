import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

import '../../core/constants.dart';

class _DecalSplat extends PositionComponent with HasPaint {
  _DecalSplat({
    required Color color,
    required double radius,
    ui.Image? image,
  })  : _radius = radius,
        _image = image {
    paint = Paint()..color = color.withValues(alpha: 0.85);
  }

  final double _radius;
  final ui.Image? _image;

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
    final img = _image;
    if (img != null) {
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, _radius * 2, _radius * 2);
      final imgPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: paint.color.a)
        ..filterQuality = FilterQuality.medium;
      canvas.drawImageRect(img, src, dst, imgPaint);
    } else {
      canvas.drawCircle(Offset(_radius, _radius), _radius, paint);
    }
  }
}

class DecalManager extends Component {
  final Queue<_DecalSplat> _live = Queue<_DecalSplat>();
  final Random _rng = Random();
  final Map<String, ui.Image> _spriteCache = <String, ui.Image>{};

  /// Decal presets the manager pre-warms at load time. Subset and ordering
  /// must stay aligned with `tools/generate_decals.py` so every PNG
  /// produced by the generator gets cached. A missing sprite simply falls
  /// back to the procedural circle render in `_DecalSplat.render`.
  static const List<String> _knownPresets = <String>[
    'cool_blue_smear',
    'cream_smudge',
    'green_goo_smear',
    'purple_monster_splat',
    'gold_mythic_splat',
    'soft_peach_splat',
    'pink_soup_burst',
    'blue_jelly_burst',
    'cream_puff_burst',
    'green_goo_burst',
    'purple_monster_burst',
  ];

  @override
  Future<void> onLoad() async {
    for (final preset in _knownPresets) {
      try {
        _spriteCache[preset] = await Flame.images.load('decals/$preset.png');
      } catch (_) {
        // PNG missing/broken — splat will fall back to procedural circle.
      }
    }
  }

  void spawn(Vector2 position, {required String preset}) {
    final splat = _DecalSplat(
      color: _colorForPreset(preset),
      radius: 26 + _rng.nextDouble() * 22,
      image: _spriteCache[preset],
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
      case 'gold_mythic_splat':
        return const Color(0xCCFFD15C);
      case 'soft_peach_splat':
      default:
        return const Color(0xCCFF8FB8);
    }
  }
}
