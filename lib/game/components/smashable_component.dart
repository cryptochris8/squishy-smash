import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/painting.dart';

import '../../core/constants.dart';
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

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(_baseRadius * 2);
    scale = _baseScale;
    _sprite = await _tryLoadSprite(def.sprite);
  }

  /// Flame.images caches by path relative to `assets/images/`. Pack JSONs
  /// reference `assets/images/objects/X.png`; strip the prefix so the
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
  void render(Canvas canvas) {
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
