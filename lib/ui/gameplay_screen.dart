import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../analytics/events.dart';
import '../data/models/rarity.dart';
import '../game/components/hud_overlay.dart';
import '../game/share_capture.dart';
import '../game/squishy_game.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late final SquishyGame _game;
  final GlobalKey _captureKey = GlobalKey();
  late final ShareCaptureService _share;
  late final GameEvents _events;

  @override
  void initState() {
    super.initState();
    _share = ShareCaptureService(_captureKey);
    _events = GameEvents(ServiceLocator.analytics);
    _game = SquishyGame(
      onRoundEnd: _handleRoundEnd,
      onMythicReveal: _handleMythicReveal,
    );
  }

  void _handleRoundEnd(int score, int combo, int coinsEarned) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.results,
      arguments: ResultsArgs(score: score, combo: combo, coinsEarned: coinsEarned),
    );
  }

  void _handleMythicReveal() {
    // Fires on the Flame tick; defer UI work to next frame to avoid
    // building during a build/layout phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showMythicShareSheet();
    });
  }

  void _showMythicShareSheet() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3B2F4F),
        content: const Row(
          children: <Widget>[
            Icon(Icons.auto_awesome, color: Color(0xFFFFD15C)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mythic! Save this clip?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'SHARE',
          textColor: const Color(0xFFFFD15C),
          onPressed: () => _shareNow(Rarity.mythic),
        ),
      ),
    );
  }

  Future<void> _shareNow(Rarity tier) async {
    final seed = DateTime.now().millisecondsSinceEpoch;
    final caption = switch (tier) {
      Rarity.mythic => ShareCaptions.forMythic(seed),
      Rarity.epic || Rarity.rare => ShareCaptions.forEpic(seed),
      Rarity.common => ShareCaptions.forGeneric(seed),
    };
    final result = await _share.shareSnapshot(caption: caption);
    _events.shareClip(
      objectId: 'session_capture',
      destination: result?.raw ?? 'unknown',
      rarity: tier,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          RepaintBoundary(
            key: _captureKey,
            child: GameWidget(game: _game),
          ),
          IgnorePointer(child: HudOverlay(game: _game)),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.ios_share,
                        color: Colors.white70),
                    tooltip: 'Share this moment',
                    onPressed: () => _shareNow(Rarity.common),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
