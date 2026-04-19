import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../core/constants.dart';
import '../../data/models/smashable_def.dart';

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

  static const double _baseRadius = 64;
  double _pressure = 0;
  bool _bursting = false;
  final Vector2 _baseScale = Vector2.all(1);
  late Paint _bodyPaint;
  late Paint _innerPaint;
  Vector2 _holdAnchor = Vector2.zero();
  bool _holding = false;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(_baseRadius * 2);
    _bodyPaint = Paint()..color = _paletteFromCategory(def.category);
    _innerPaint = Paint()..color = _bodyPaint.color.withOpacity(0.55);
    scale = _baseScale;
  }

  @override
  void render(Canvas canvas) {
    final radius = _baseRadius;
    canvas.drawCircle(Offset(radius, radius), radius, _bodyPaint);
    canvas.drawCircle(
      Offset(radius * 0.65, radius * 0.55),
      radius * 0.45,
      _innerPaint,
    );
    final highlight = Paint()..color = const Color(0x66FFFFFF);
    canvas.drawCircle(
      Offset(radius * 0.55, radius * 0.45),
      radius * 0.18,
      highlight,
    );
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
    final compression = 1.0 - (_pressure * 0.5);
    final stretch = 1.0 + (_pressure * 0.4);
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
    final squash = 1.0 - (force * 0.35);
    final stretch = 1.0 + (force * 0.45);
    add(SequenceEffect(
      <Effect>[
        ScaleEffect.to(
          Vector2(stretch, squash),
          EffectController(duration: 0.06, curve: Curves.easeOut),
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

  Color _paletteFromCategory(String category) {
    switch (category) {
      case 'goo_fidget':
        return const Color(0xFFB6FF5C);
      case 'creepy_cute':
        return const Color(0xFFB084F2);
      case 'squishy_food':
      default:
        return const Color(0xFFFF8FB8);
    }
  }
}
