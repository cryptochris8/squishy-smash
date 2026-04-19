import 'package:flutter/material.dart';

import '../squishy_game.dart';

class HudOverlay extends StatefulWidget {
  const HudOverlay({super.key, required this.game});

  final SquishyGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  late final Ticker _ticker = Ticker(_onTick);

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final score = widget.game.score.total;
    final mult = widget.game.combo.multiplier;
    final fill = widget.game.combo.fill;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$score',
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
                  'x$mult',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: mult > 1 ? const Color(0xFFFFD36E) : Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: fill,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFFFF8FB8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Ticker {
  Ticker(this._cb);
  final void Function(Duration) _cb;
  Stopwatch? _sw;
  bool _running = false;

  void start() {
    _running = true;
    _sw = Stopwatch()..start();
    _loop();
  }

  Future<void> _loop() async {
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _cb(_sw!.elapsed);
    }
  }

  void dispose() {
    _running = false;
  }
}
