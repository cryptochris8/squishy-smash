import 'dart:async';

import 'package:flutter/material.dart';

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

  ({int score, int mult, double fill}) _readGame() {
    try {
      return (
        score: widget.game.score.total,
        mult: widget.game.combo.multiplier,
        fill: widget.game.combo.fill,
      );
    } catch (_) {
      return (score: 0, mult: 1, fill: 0.0);
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
                Text(
                  'x${data.mult}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: data.mult > 1 ? const Color(0xFFFFD36E) : Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: data.fill,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFFFF8FB8),
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
