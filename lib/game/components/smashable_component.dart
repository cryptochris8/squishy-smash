import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart' show SpriteAnimationTicker;
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/painting.dart';

import '../../core/constants.dart';
import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';
import '../render/object_painters.dart';

class SmashableComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  SmashableComponent({
    required this.def,
    required this.onImpact,
    required this.onBurst,
  });

  final SmashableDef def;
  final void Function(SmashableComponent self, double force) onImpact;
  final void Function(SmashableComponent self) onBurst;

  // Bumped from 64 (+12.5%) for closer, more touchable scale per the
  // Juice Pass plan — squishies feel like physical objects rather than
  // distant icons. Arena is 360×640 so 144×144 still leaves clearance.
  static const double _baseRadius = 72;
  double _pressure = 0;
  bool _bursting = false;
  final Vector2 _baseScale = Vector2.all(1);
  Vector2 _holdAnchor = Vector2.zero();
  bool _holding = false;

  Sprite? _sprite;

  /// Pre-rendered 3D squash cycle (Meshy model -> Blender squash rig).
  /// Mythic-tier only: 3 sheets ship today, ~220 KB each. Lower tiers
  /// keep the procedural ScaleEffect squash.
  SpriteAnimation? _squishAnim;
  SpriteAnimationTicker? _squishTicker;
  double _squishCellAspect = 1;

  /// Cell count baked into every sheet by tools/render3d/pack_squish_sheet.py.
  static const int _squishFrameCount = 13;
  static const double _squishFps = 30;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(_baseRadius * 2);
    // P1-E: pop into existence instead of materialising at full size.
    // Start at zero scale and ride an elasticOut curve to _baseScale
    // over 220 ms — the overshoot at the tail gives the squishy a
    // "boing" arrival that reads as a physical object dropping in,
    // not a sprite snapping on. Pre-fix the very first squishy on a
    // new install was a static object sitting on the screen with no
    // hook moment; this animates every spawn including the first.
    scale = Vector2.zero();
    add(ScaleEffect.to(
      _baseScale.clone(),
      EffectController(duration: 0.22, curve: Curves.elasticOut),
    ));
    _sprite = await _tryLoadSprite(def.sprite);
    if (def.rarity == Rarity.mythic) {
      _squishAnim = await _tryLoadSquishAnimation(def.cardNumber);
    }
  }

  /// Loads the pre-rendered squash cycle for this smashable's card, keyed
  /// by card number (`"016/048"` -> `anim/card_016_squish.webp`). Returns
  /// null when the smashable has no card or the sheet isn't bundled —
  /// callers fall back to the ScaleEffect squash, so a missing sheet can
  /// never break gameplay.
  Future<SpriteAnimation?> _tryLoadSquishAnimation(String? cardNumber) async {
    if (cardNumber == null) return null;
    final n = int.tryParse(cardNumber.split('/').first);
    if (n == null) return null;
    final path = 'anim/card_${n.toString().padLeft(3, '0')}_squish.webp';
    try {
      final image = await Flame.images.load(path);
      final cellWidth = image.width / _squishFrameCount;
      _squishCellAspect = cellWidth / image.height;
      return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: _squishFrameCount,
          stepTime: 1 / _squishFps,
          textureSize: Vector2(cellWidth, image.height.toDouble()),
          loop: false,
        ),
      );
    } catch (e) {
      debugPrint('SmashableComponent: squish sheet load failed for '
          '$path — ScaleEffect squash will be used ($e)');
      return null;
    }
  }

  /// Flame.images caches by path relative to `assets/images/`. Pack JSONs
  /// reference `assets/images/objects/X.webp`; strip the prefix so the
  /// cache resolves correctly. Returns null on any load failure so the
  /// procedural [ObjectPainter] fallback renders instead.
  Future<Sprite?> _tryLoadSprite(String assetPath) async {
    const prefix = 'assets/images/';
    final normalized = assetPath.startsWith(prefix)
        ? assetPath.substring(prefix.length)
        : assetPath;
    try {
      final image = await Flame.images.load(normalized);
      return Sprite(image);
    } catch (e) {
      debugPrint('SmashableComponent: sprite load FAILED for '
          '$normalized — falling back to ObjectPainter ($e)');
      return null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final ticker = _squishTicker;
    if (ticker != null) {
      ticker.update(dt);
      if (ticker.done()) _squishTicker = null;
    }
  }

  @override
  void render(Canvas canvas) {
    final ticker = _squishTicker;
    if (ticker != null) {
      // Cells are bottom-registered and wider than the resting sprite
      // (the squash bulges sideways), so keep the height at the normal
      // footprint, let the width overflow symmetrically, and pin the
      // bottom edge to the resting sprite's ground line.
      final h = _baseRadius * 2;
      final w = h * _squishCellAspect;
      ticker.getSprite().render(
            canvas,
            position: Vector2((size.x - w) / 2, size.y - h),
            size: Vector2(w, h),
          );
      return;
    }
    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(
        canvas,
        size: Vector2.all(_baseRadius * 2),
      );
      return;
    }
    ObjectPainter.paint(canvas, _baseRadius, def);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_bursting) return;
    final force = 0.4 + def.deformability * 0.6;
    _applyHit(force);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_bursting) return;
    _holding = true;
    _holdAnchor = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_bursting || !_holding) return;
    final dragDist = (event.localEndPosition - _holdAnchor).length;
    final crushFactor = (dragDist / 80).clamp(0.0, 1.0);
    _pressure = (_pressure + crushFactor * 0.04 * def.deformability)
        .clamp(0.0, 1.0);
    // Bumped from 0.5/0.4 for a more dramatic crush — at full pressure
    // the squishy goes to 0.4×1.5 (was 0.5×1.4), so the "about to pop"
    // shape reads stronger.
    final compression = 1.0 - (_pressure * 0.6);
    final stretch = 1.0 + (_pressure * 0.5);
    scale = Vector2(stretch, compression);
    if (_pressure >= def.burstThreshold) _burst();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_bursting) return;
    _holding = false;
    final velocity = event.velocity;
    if (velocity.length > 600) {
      _applyHit(min(1.0, velocity.length / 1500.0));
    } else {
      _relax();
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _holding = false;
    _relax();
  }

  void _applyHit(double force) {
    _pressure = (_pressure + force * 0.5 * def.deformability).clamp(0.0, 1.0);
    final anim = _squishAnim;
    if (anim != null) {
      // Mythic tier: play the pre-rendered 3D squash cycle instead of the
      // procedural ScaleEffect. Clear any in-flight scale effects first so
      // the cycle isn't double-deformed by a previous tap's recovery.
      children.whereType<Effect>().toList().forEach((e) => e.removeFromParent());
      scale.setFrom(_baseScale);
      _squishTicker = anim.createTicker();
      onImpact(this, force);
      if (_pressure >= def.burstThreshold) _burst();
      return;
    }
    // Punchier squash/stretch — tap (force ≈ 0.4) lands at (1.22, 0.83);
    // full force lands at (1.55, 0.58). Was (1.18, 0.86) / (1.45, 0.65).
    final squash = 1.0 - (force * 0.42);
    final stretch = 1.0 + (force * 0.55);
    // Tiny overshoot in the OPPOSITE axes for snap feel — the squishy
    // briefly bulges the way it was just compressed before elasticOut
    // settles it. Magnitude scales with hit force so light taps don't
    // ping-pong.
    final overshootSquash = 1.0 + (force * 0.10);
    final overshootStretch = 1.0 - (force * 0.08);
    add(SequenceEffect(
      <Effect>[
        ScaleEffect.to(
          Vector2(stretch, squash),
          EffectController(duration: 0.05, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2(overshootStretch, overshootSquash),
          EffectController(duration: 0.09, curve: Curves.easeInOut),
        ),
        ScaleEffect.to(
          _baseScale,
          EffectController(
            duration: Tunables.squashRecover.inMilliseconds / 1000,
            curve: Curves.elasticOut,
          ),
        ),
      ],
    ));
    onImpact(this, force);
    if (_pressure >= def.burstThreshold) _burst();
  }

  void _relax() {
    add(ScaleEffect.to(
      _baseScale,
      EffectController(
        duration: Tunables.squashRecover.inMilliseconds / 1000,
        curve: Curves.elasticOut,
      ),
    ));
  }

  void _burst() {
    if (_bursting) return;
    _bursting = true;
    onBurst(this);
  }

}
