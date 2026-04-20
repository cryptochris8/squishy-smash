import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../game/components/hud_overlay.dart';
import '../game/squishy_game.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late final SquishyGame _game;

  @override
  void initState() {
    super.initState();
    _game = SquishyGame(onRoundEnd: _handleRoundEnd);
  }

  void _handleRoundEnd(int score, int combo, int coinsEarned) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.results,
      arguments: ResultsArgs(score: score, combo: combo, coinsEarned: coinsEarned),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          IgnorePointer(child: HudOverlay(game: _game)),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultsArgs {
  const ResultsArgs({required this.score, required this.combo, required this.coinsEarned});
  final int score;
  final int combo;
  final int coinsEarned;
}
