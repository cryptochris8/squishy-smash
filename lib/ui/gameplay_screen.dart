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
        // P1.4 — extended from 6 s to 10 s. Six seconds was too
        // short for a 5-year-old to read "Mythic! Save this clip?"
        // and react. Snackbar is also user-dismissible (showCloseIcon)
        // so a parent can swipe it away if they're mid-round.
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3B2F4F),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        content: const Row(
          children: <Widget>[
            Icon(Icons.auto_awesome, color: Color(0xFFFFD36E)),
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
          textColor: const Color(0xFFFFD36E),
          onPressed: () => _shareNow(Rarity.mythic),
        ),
      ),
    );
  }

  /// Confirm-before-quit dialog for the gameplay close X. Pre-fix
  /// (P1.5) tapping the corner X dropped the run silently — a kid
  /// who fat-fingered it lost their score with no warning. Returns
  /// true if the player confirmed; false otherwise.
  Future<bool> _confirmQuitRound() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1320),
        title: const Text(
          'Quit this round?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "You'll keep coins and discoveries you've already earned, "
          'but your score and combo for this round will reset.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Keep playing',
              style: TextStyle(color: Color(0xFFFFD36E)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Quit',
              style: TextStyle(color: Color(0xFFFF8FB8)),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleClosePressed() async {
    final confirmed = await _confirmQuitRound();
    if (!confirmed) return;
    if (!mounted) return;
    // Finalize so coins / discoveries / best-score from this partial
    // session land in profile before navigating away.
    await _game.finalizeRoundIfActive();
    if (!mounted) return;
    Navigator.pop(context);
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
              // P1.6 — bumped iconSize 24 → 32 and added 12 px padding
              // (each IconButton is now 56x56 hit area). Pre-fix the
              // default icon at white70 against a busy gameplay
              // background was effectively invisible and easy to
              // miss-tap.
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.ios_share),
                    iconSize: 32,
                    color: Colors.white,
                    tooltip: 'Share this moment',
                    padding: const EdgeInsets.all(12),
                    onPressed: () => _shareNow(Rarity.common),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 32,
                    color: Colors.white,
                    tooltip: 'Close this round',
                    padding: const EdgeInsets.all(12),
                    onPressed: _handleClosePressed,
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
