import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Idle hero image that bobs gently on the menu screen so the empty
/// space between the title and the action buttons doesn't read as
/// "unfinished app." Pure cosmetic — no game-state coupling.
///
/// Behavior:
///   * Repeating sine bob on a 2.5s period, ±[bobAmplitude] px.
///   * Pauses when the app is backgrounded via [WidgetsBindingObserver]
///     so we don't drive frames that nobody can see — small but real
///     battery savings, especially on iPhones that aggressively
///     throttle background CPU.
///   * Soft pink glow under the card to lift it off the dark canvas.
///   * Falls back to a transparent box if the asset is missing so the
///     menu never fails to render — the rest of the layout is fine
///     without the mascot.
class FloatingMascot extends StatefulWidget {
  const FloatingMascot({
    super.key,
    required this.assetPath,
    this.width = 180,
    this.bobAmplitude = 6.0,
    this.bobDuration = const Duration(milliseconds: 2500),
    this.glowColor = const Color(0xFFFF8FB8),
  });

  final String assetPath;
  final double width;

  /// Vertical bob travel in logical pixels (peak-to-zero, not peak-to-
  /// peak). 6 px feels alive without crossing into "drifting away."
  final double bobAmplitude;

  /// One full sine cycle. Slower = calmer. 2.5s lands in the
  /// "breathing" range.
  final Duration bobDuration;

  /// Soft underglow color. Defaults to brand pink so the card pops
  /// against the deep purple-black background.
  final Color glowColor;

  @override
  State<FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<FloatingMascot>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: widget.bobDuration,
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Battery sanity: stop the animation when the app is hidden, then
    // resume on return. A paused AnimationController draws no frames.
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // sin(2π·t) → smooth periodic bob with no discontinuity at the
        // loop boundary (sin(2π) == sin(0)). Cleaner than reverse-mode
        // tween, which can show a tiny hitch at the reversal point.
        final dy = math.sin(_controller.value * 2 * math.pi) *
            widget.bobAmplitude;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.width,
        child: AspectRatio(
          // Card art is shipped at 1086×1448 — honor that aspect ratio
          // so the mascot looks like a card, not a stretched square.
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.30),
                  blurRadius: 36,
                  spreadRadius: -2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
