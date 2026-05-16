import 'package:flutter_test/flutter_test.dart';

import 'package:squishy_smash/game/systems/combo_controller.dart';
import 'package:squishy_smash/game/systems/score_controller.dart';

void main() {
  test('ComboController bumps multiplier by 1 every 3 hits', () {
    final c = ComboController();
    expect(c.multiplier, 1);
    c.bump();
    c.bump();
    expect(c.multiplier, 1);
    c.bump();
    expect(c.multiplier, 2);
    c.bump();
    c.bump();
    c.bump();
    expect(c.multiplier, 3);
  });

  test('ComboController decays after timeout', () {
    final c = ComboController();
    for (var i = 0; i < 4; i++) {
      c.bump();
    }
    expect(c.multiplier, greaterThan(1));
    c.tick(5);
    expect(c.multiplier, 1);
  });

  // GAME_POLISH_AUDIT.md P1-F: pre-fix the streak silently reset to 0
  // with no visual or haptic cue, so players never learned that
  // timing was a skill. wasLostThisTick is now a one-shot flag the
  // game loop reads to fire a selection haptic exactly once per loss.
  test('ComboController.wasLostThisTick fires the tick decay zeros out',
      () {
    final c = ComboController();
    for (var i = 0; i < 3; i++) {
      c.bump();
    }
    expect(c.wasLostThisTick, isFalse,
        reason: 'no loss before the decay window expires');
    // First tick — large enough to push the decay timer below zero.
    c.tick(5);
    expect(c.wasLostThisTick, isTrue,
        reason: 'must fire exactly the tick the streak resets');
    // Subsequent tick clears the flag.
    c.tick(0.1);
    expect(c.wasLostThisTick, isFalse,
        reason: 'flag is a one-shot — must clear on the next tick');
  });

  test('ComboController.wasLostThisTick does NOT fire on a fresh ctrl',
      () {
    // Ticking a controller that never had a streak is a no-op, not a
    // loss event — otherwise the very first frame of every round
    // would phantom-fire the haptic.
    final c = ComboController();
    c.tick(5);
    expect(c.wasLostThisTick, isFalse);
  });

  test('ComboController.reset() clears wasLostThisTick', () {
    final c = ComboController();
    c.bump();
    c.tick(5); // sets _wasLostThisTick = true
    expect(c.wasLostThisTick, isTrue);
    c.reset();
    expect(c.wasLostThisTick, isFalse);
  });

  test('ScoreController applies multiplier', () {
    final s = ScoreController();
    s.addHit(10, multiplier: 1);
    s.addBurst(20, multiplier: 3);
    expect(s.total, 10 + 60);
  });
}
