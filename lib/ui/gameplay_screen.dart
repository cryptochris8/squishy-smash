import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/feature_flags.dart';
import '../core/routes.dart';
import '../core/service_locator.dart';
import '../analytics/events.dart';
import '../data/models/rarity.dart';
import '../game/components/hud_overlay.dart';
import '../game/share_capture.dart';
import '../game/squishy_game.dart';
import 'widgets/reward_toast_overlay.dart';
import 'widgets/starter_bundle_popup.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with WidgetsBindingObserver {
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
      onFirstRareReveal: _handleFirstRareReveal,
    );
    // Observe iOS lifecycle so a force-quit / Cmd-swipe / OS-kill
    // mid-round doesn't drop the in-flight progression. Pre-fix
    // (P1.2): debounced 400 ms saves on bursts could be lost on
    // termination, and best-score / best-combo for the round were
    // only persisted via _endRound() — never reached on backgrounding.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On iOS the system may give us only ~5 seconds after a
    // background transition before suspending the app, so flush
    // synchronously rather than relying on a debounced save firing.
    // We also force-finalize any in-flight round so best-score /
    // best-combo for that session lands even if the player never
    // returns.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _game.finalizeRoundIfActive();
      // Fire-and-forget: persistence.flushPending awaits its own
      // setString, but we cannot await across a lifecycle callback.
      // Best-effort is acceptable — at worst we lose the same data
      // we'd have lost without the observer.
      ServiceLocator.persistence.flushPending();
    }
  }

  void _handleFirstRareReveal() {
    // Hard-gate: with IAPs disabled at build time (v0.1.1 ships with
    // FeatureFlags.iapsEnabled == false because no products are
    // configured in App Store Connect), DON'T show a paywall popup
    // whose Buy button would fail. Apple guideline 2.3.1 — every
    // visible purchase surface must work or the build gets rejected.
    if (!FeatureFlags.iapsEnabled) return;

    // Fires on the Flame tick when the player's very first rare+ burst
    // resolves. Defer to the next frame so the popup doesn't try to
    // build during a Flame update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Guard against re-showing if the profile already claimed the
      // bundle via the Shop path earlier in the same round.
      if (ServiceLocator.progression.profile.starterBundleClaimed) return;
      StarterBundlePopup.show(context);
    });
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
          RewardToastOverlay(events: _game.rewardEvents),
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
