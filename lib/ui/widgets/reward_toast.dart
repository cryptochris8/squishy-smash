import 'package:flutter/material.dart';

import '../../game/systems/reward_event.dart';

/// Brief floating "+N coins · reason!" callout. Drifts up ~40 px,
/// fades to transparent, auto-removes itself after [lifetime].
///
/// Self-contained — the parent overlay can spawn one and call
/// [onComplete] when it's safe to drop the entry from the active
/// list. No external state.
///
/// Picked simple over slick: a single sequenced animation (translate
/// + opacity) with no springs, no particles, no haptics. Kid-readable
/// at first glance, doesn't compete with the action behind it.
class RewardToast extends StatefulWidget {
  const RewardToast({
    super.key,
    required this.event,
    required this.onComplete,
    this.lifetime = const Duration(milliseconds: 1500),
    this.driftPx = 40.0,
  });

  final RewardEvent event;
  final VoidCallback onComplete;
  final Duration lifetime;
  final double driftPx;

  @override
  State<RewardToast> createState() => _RewardToastState();
}

class _RewardToastState extends State<RewardToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.lifetime,
    );
    // Two-phase opacity: fade in fast (first 15%), hold, fade out
    // over the last 30%. The "hold" middle is where the kid actually
    // reads the number.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);
    // Linear upward drift over the full lifetime — eased on the
    // outer ends so the toast slows to a stop as it fades.
    _translate = Tween<double>(begin: 0.0, end: -widget.driftPx).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = Color(widget.event.tint);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _translate.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tint, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: tint, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.event.coinAmount}',
                    style: TextStyle(
                      color: tint,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.event.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
