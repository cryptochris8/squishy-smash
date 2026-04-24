import 'dart:async';

import 'package:flutter/material.dart';

import '../systems/combo_controller.dart';
import '../squishy_game.dart';

class HudOverlay extends StatefulWidget {
  const HudOverlay({super.key, required this.game});

  final SquishyGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  ({int score, int mult, double fill, ComboTier tier}) _readGame() {
    try {
      return (
        score: widget.game.score.total,
        mult: widget.game.combo.multiplier,
        fill: widget.game.combo.fill,
        tier: widget.game.combo.currentTier,
      );
    } catch (_) {
      return (score: 0, mult: 1, fill: 0.0, tier: ComboTier.none);
    }
  }

  /// Color + size styling for the multiplier text driven by the
  /// current combo milestone tier. Matches the tuning-doc intent:
  /// higher combo should feel progressively more charged.
  ({Color color, double fontSize, FontWeight weight}) _multStyleFor(
      ComboTier tier) {
    switch (tier) {
      case ComboTier.none:
        return (color: Colors.white70, fontSize: 22, weight: FontWeight.w700);
      case ComboTier.starter:
        return (
          color: const Color(0xFFFFD36E),
          fontSize: 24,
          weight: FontWeight.w800,
        );
      case ComboTier.stronger:
        return (
          color: const Color(0xFFFFB05C),
          fontSize: 28,
          weight: FontWeight.w900,
        );
      case ComboTier.revealReady:
        return (
          color: const Color(0xFFFF8FB8),
          fontSize: 32,
          weight: FontWeight.w900,
        );
      case ComboTier.mega:
        return (
          color: const Color(0xFFB6FF5C),
          fontSize: 36,
          weight: FontWeight.w900,
        );
    }
  }

  Color _barColorFor(ComboTier tier) {
    switch (tier) {
      case ComboTier.none:
      case ComboTier.starter:
        return const Color(0xFFFF8FB8);
      case ComboTier.stronger:
        return const Color(0xFFFFD36E);
      case ComboTier.revealReady:
        return const Color(0xFFC98BFF);
      case ComboTier.mega:
        return const Color(0xFFB6FF5C);
    }
  }

  /// On-screen banner shown only when the skybox failed to load — gives a
  /// TestFlight tester (no Mac, no device console) something concrete to
  /// screenshot and report back. Returns null when everything loaded.
  Widget? _skyboxDiagnostic() {
    try {
      final sky = widget.game.skybox;
      if (!sky.hasLoadFailure) return null;
      final lines = <String>[
        'SKYBOX LOAD FAILED — theme=${sky.theme.key}',
        if (sky.calmError != null) 'calm: ${sky.calmError}',
        if (sky.revealError != null) 'reveal: ${sky.revealError}',
      ];
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xCC8B0000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: lines
              .map((line) => Text(
                    line,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.3,
                    ),
                  ))
              .toList(growable: false),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _readGame();
    final diag = _skyboxDiagnostic();
    final multStyle = _multStyleFor(data.tier);
    final barColor = _barColorFor(data.tier);
    final barHeight = data.tier == ComboTier.mega ? 12.0 : 8.0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${data.score}',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 140),
                  style: TextStyle(
                    fontSize: multStyle.fontSize,
                    fontWeight: multStyle.weight,
                    color: multStyle.color,
                  ),
                  child: Text('x${data.mult}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: barHeight,
                      child: LinearProgressIndicator(
                        minHeight: barHeight,
                        value: data.fill,
                        backgroundColor: Colors.white12,
                        color: barColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (diag != null) ...[
              const SizedBox(height: 12),
              diag,
            ],
          ],
        ),
      ),
    );
  }
}
