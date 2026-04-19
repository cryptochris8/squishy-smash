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

  test('ScoreController applies multiplier', () {
    final s = ScoreController();
    s.addHit(10, multiplier: 1);
    s.addBurst(20, multiplier: 3);
    expect(s.total, 10 + 60);
  });
}
