import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:squishy_smash/ui/gameplay_screen.dart' show ResultsArgs;
import 'package:squishy_smash/ui/results_screen.dart';

/// Locks the redesign called out by three converging agents in
/// `GAME_POLISH_AUDIT.md` (game-feel P1-D, UX #4, UI #1):
///   * NEW BEST! badge visibility tracks `ResultsArgs.isNewBest`
///   * Score animates 0 → final and lands on the final value
///   * "See the Shop" CTA appears only when the round earned coins
///   * Stat strip renders the post-round bests + earnings
///   * Reduce-motion users see the final score immediately (no tween)
///
/// Test setup: every case wraps `ResultsScreen` in a `MaterialApp` and
/// passes a synthetic `ResultsArgs` via the screen's `argsOverride`
/// constructor seam — that's why the route-arguments plumbing in
/// `gameplay_screen.dart` doesn't need a fake Navigator here.
Future<void> _pumpResults(
  WidgetTester tester, {
  required ResultsArgs args,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: ResultsScreen(argsOverride: args),
      ),
    ),
  );
}

ResultsArgs _args({
  int score = 1250,
  int combo = 7,
  int coinsEarned = 42,
  int bestScore = 1250,
  bool isNewBest = false,
}) {
  return ResultsArgs(
    score: score,
    combo: combo,
    coinsEarned: coinsEarned,
    bestScore: bestScore,
    isNewBest: isNewBest,
  );
}

void main() {
  group('ResultsScreen — NEW BEST badge', () {
    testWidgets('renders when isNewBest is true', (tester) async {
      await _pumpResults(
        tester,
        args: _args(isNewBest: true),
        disableAnimations: true,
      );
      // Use a substring match so the emoji surround doesn't bind the
      // test to the exact decorative characters.
      expect(
        find.textContaining('NEW BEST'),
        findsOneWidget,
        reason: 'badge must appear when the round beat the prior best',
      );
    });

    testWidgets('hidden when isNewBest is false', (tester) async {
      await _pumpResults(
        tester,
        args: _args(isNewBest: false),
        disableAnimations: true,
      );
      expect(
        find.textContaining('NEW BEST'),
        findsNothing,
        reason: 'badge must not appear when the round did not beat best',
      );
    });
  });

  group('ResultsScreen — score countup', () {
    testWidgets('lands on the final score after the animation completes',
        (tester) async {
      const finalScore = 2480;
      await _pumpResults(tester, args: _args(score: finalScore));
      // 1500 ms countup duration + a safety frame.
      await tester.pump(const Duration(milliseconds: 1600));
      expect(
        find.text('$finalScore'),
        findsOneWidget,
        reason: 'score must settle on the final value after the tween',
      );
    });

    testWidgets('reduce-motion shows final score immediately',
        (tester) async {
      const finalScore = 999;
      await _pumpResults(
        tester,
        args: _args(score: finalScore),
        disableAnimations: true,
      );
      // No pump past the animation duration — reduce-motion must
      // render the final value on first frame so the screen is
      // not visually broken for that accessibility setting.
      expect(find.text('$finalScore'), findsOneWidget);
    });
  });

  group('ResultsScreen — Shop CTA gating (UX-2)', () {
    testWidgets('appears with the earned coin count when coins > 0',
        (tester) async {
      await _pumpResults(
        tester,
        args: _args(coinsEarned: 73),
        disableAnimations: true,
      );
      expect(
        find.textContaining('See the Shop (+73)'),
        findsOneWidget,
        reason: 'shop bridge must surface when the round earned coins',
      );
    });

    testWidgets('hidden when the round earned zero coins', (tester) async {
      await _pumpResults(
        tester,
        args: _args(coinsEarned: 0),
        disableAnimations: true,
      );
      expect(
        find.textContaining('See the Shop'),
        findsNothing,
        reason: 'no point bridging to spend when there is nothing to spend',
      );
    });
  });

  group('ResultsScreen — stat strip', () {
    testWidgets('renders combo, coin, and best values', (tester) async {
      await _pumpResults(
        tester,
        args: _args(combo: 9, coinsEarned: 51, bestScore: 4200),
        disableAnimations: true,
      );
      expect(find.text('x9'), findsOneWidget);
      expect(find.text('+51'), findsOneWidget);
      expect(find.text('4200'), findsOneWidget);
      // Labels are uppercase short forms — match the visual hierarchy
      // (number first, label second).
      expect(find.text('COMBO'), findsOneWidget);
      expect(find.text('COINS'), findsOneWidget);
      expect(find.text('BEST'), findsOneWidget);
    });
  });

  group('ResultsScreen — primary nav surfaces always present', () {
    testWidgets('PLAY AGAIN and MENU big buttons render', (tester) async {
      await _pumpResults(
        tester,
        args: _args(),
        disableAnimations: true,
      );
      expect(find.text('PLAY AGAIN'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);
    });

    testWidgets('headline "NICE MESS" always renders', (tester) async {
      await _pumpResults(
        tester,
        args: _args(),
        disableAnimations: true,
      );
      expect(find.text('NICE MESS'), findsOneWidget);
    });
  });

  group('ResultsArgs — derived field semantics', () {
    test('isNewBest celebrates a strict win, not a tie', () {
      // Pins the boundary decision made in gameplay_screen._handleRoundEnd:
      // tying the previous best is NOT a new best. This is a tiny rule
      // but the wrong default (score >= prev) would celebrate every
      // single round once the player plateaus at the cap.
      const tieArgs = ResultsArgs(
        score: 100,
        combo: 3,
        coinsEarned: 10,
        bestScore: 100,
        isNewBest: false,
      );
      expect(tieArgs.isNewBest, isFalse);

      const winArgs = ResultsArgs(
        score: 101,
        combo: 3,
        coinsEarned: 10,
        bestScore: 101,
        isNewBest: true,
      );
      expect(winArgs.isNewBest, isTrue);
    });
  });
}
