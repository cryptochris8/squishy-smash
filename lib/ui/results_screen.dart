import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import 'gameplay_screen.dart';
import 'widgets/big_button.dart';
import 'widgets/floating_mascot.dart';

/// Round-end summary. Three-agent convergence in GAME_POLISH_AUDIT.md
/// (game-feel P1-D, UX #4, UI #1) flagged the previous version as the
/// single weakest moment in the game — a static four-row text list with
/// undifferentiated buttons. This redesign:
///   * animates the score from 0 → final over 1.5 s so the round's
///     headline number lands as an event, not a number;
///   * surfaces a "NEW BEST!" badge with a scale-in animation when the
///     round beat the player's prior best;
///   * promotes the score to a display-tier font size so it visually
///     wins over the secondary stats;
///   * drops in a [FloatingMascot] in the dead space between the stats
///     and the CTA stack, matching the menu's idle visual rhythm;
///   * adds a "See the Shop (+N) →" tertiary CTA when the round earned
///     coins, addressing UX #2 (no bridge from results to the spend
///     side of the loop).
///
/// All animations honor `MediaQuery.disableAnimations` (reduce-motion).
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, this.argsOverride});

  /// Test/preview seam: when supplied, used in place of the route's
  /// `ModalRoute.settings.arguments`. Lets widget tests bypass the
  /// `Navigator.pushReplacementNamed(arguments:)` plumbing.
  final ResultsArgs? argsOverride;

  /// Mascot shown in the dead space between stats and CTAs. Reuses the
  /// menu's legendary-tier hero so the player's "I came from the menu,
  /// I'm going back to the menu" mental loop has visual continuity.
  static const String _kResultsMascotAsset =
      'assets/cards/final_48/016_Celestial_Dumpling_Core.webp';

  @override
  Widget build(BuildContext context) {
    final args = argsOverride
        ?? ModalRoute.of(context)?.settings.arguments as ResultsArgs?;
    final score = args?.score ?? 0;
    final combo = args?.combo ?? 0;
    final coins = args?.coinsEarned ?? 0;
    final best = args?.bestScore ?? 0;
    final isNewBest = args?.isNewBest ?? false;
    final newCards = args?.cardsDiscoveredThisRound ?? 0;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Headline(),
              const SizedBox(height: 8),
              if (isNewBest)
                _NewBestBadge(reduceMotion: reduceMotion)
              else
                const SizedBox(height: 32),
              const SizedBox(height: 12),
              _ScoreDisplay(score: score, reduceMotion: reduceMotion),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: FloatingMascot(
                    assetPath: _kResultsMascotAsset,
                    width: 160,
                    glowColor: isNewBest ? Palette.cream : Palette.pink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StatStrip(combo: combo, coins: coins, best: best),
              const SizedBox(height: 20),
              BigButton(
                label: 'PLAY AGAIN',
                color: Palette.pink,
                onTap: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.play),
              ),
              const SizedBox(height: 10),
              BigButton(
                label: 'MENU',
                color: Palette.jellyBlue,
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.menu,
                  (_) => false,
                ),
              ),
              if (newCards > 0) ...[
                const SizedBox(height: 6),
                _SeeCollectionLink(newCards: newCards),
              ],
              if (coins > 0) ...[
                // Tighter gap when stacked under the Collection bridge
                // so the two-link stack stays inside the safe area on
                // smaller screens (iPhone SE class).
                SizedBox(height: newCards > 0 ? 0 : 6),
                _SeeShopLink(coins: coins),
              ] else if (newCards == 0)
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    // Pink + drop-shadow rather than flat white — the UI agent flagged
    // the original headline as "no visual container or accent." The
    // shadow uses the same pink at low alpha so it reads as a soft
    // glow on the dark canvas, not a hard offset.
    return const Text(
      'NICE MESS',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: Palette.pink,
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: Color(0x66FF8FB8),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _NewBestBadge extends StatelessWidget {
  const _NewBestBadge({required this.reduceMotion});
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    // Pill uses jellyBlue to (a) avoid the cream-on-cream contrast
    // collapse that drowned out the ✨ glyphs (yellow stars on yellow
    // pill were invisible at glance), (b) hand off cleanly to the
    // jellyBlue MENU button below for visual rhythm, and (c) free
    // cream to remain the score's accent color above without two
    // cream surfaces fighting. Warm celebration accent still lives
    // on the mascot glow tint (cream when isNewBest).
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.jellyBlue,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Palette.jellyBlue.withValues(alpha: 0.55),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        '✨ NEW BEST! ✨',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 1.2,
        ),
      ),
    );
    if (reduceMotion) {
      // Same visual footprint, no scale animation, so the celebration
      // is still readable for players with reduce-motion on without
      // burning a frame budget on a tween they won't see anyway.
      return Center(child: pill);
    }
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: pill,
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({required this.score, required this.reduceMotion});
  final int score;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final number = reduceMotion
        ? Text(
            '$score',
            style: const TextStyle(
              fontSize: 88,
              fontWeight: FontWeight.w900,
              color: Palette.cream,
              height: 0.95,
              letterSpacing: -2,
            ),
          )
        : TweenAnimationBuilder<int>(
            // Score counts 0 → final over 1.5 s. Linear curve looks
            // jerky on tens-of-thousands scores; using Curves.easeOut
            // makes the counter sprint at first then settle, which
            // matches how a slot-machine roll feels in the hand.
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Text(
                '$value',
                style: const TextStyle(
                  fontSize: 88,
                  fontWeight: FontWeight.w900,
                  color: Palette.cream,
                  height: 0.95,
                  letterSpacing: -2,
                ),
              );
            },
          );
    return Column(
      children: [
        number,
        const SizedBox(height: 4),
        const Text(
          'SCORE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.combo,
    required this.coins,
    required this.best,
  });
  final int combo;
  final int coins;
  final int best;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCell(label: 'COMBO', value: 'x$combo'),
        _StatDivider(),
        _StatCell(label: 'COINS', value: '+$coins'),
        _StatDivider(),
        _StatCell(label: 'BEST', value: '$best'),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

/// CV-2 bridge — surfaces the Collection screen as the natural next
/// destination when the round produced new discoveries. Without this,
/// the emotional peak of "I just found new squishies" ended at a
/// dead-end results screen and the player had no path to inspect the
/// thing they just earned.
class _SeeCollectionLink extends StatelessWidget {
  const _SeeCollectionLink({required this.newCards});
  final int newCards;

  @override
  Widget build(BuildContext context) {
    final label = newCards == 1
        ? 'See your new squishy →'
        : 'See your $newCards new squishies →';
    return Semantics(
      button: true,
      label: 'See your collection. You discovered $newCards this round.',
      excludeSemantics: true,
      child: Center(
        child: TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.collection),
          style: TextButton.styleFrom(
            foregroundColor: Palette.lavender,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeShopLink extends StatelessWidget {
  const _SeeShopLink({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'See the Shop. You earned $coins coins.',
      excludeSemantics: true,
      child: Center(
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.shop),
          style: TextButton.styleFrom(
            foregroundColor: Palette.cream,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          child: Text(
            'See the Shop (+$coins) →',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
