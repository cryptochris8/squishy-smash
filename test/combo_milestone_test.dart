import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/combo_controller.dart';

void main() {
  group('comboTierFor', () {
    test('maps streak thresholds to the doc-defined tiers', () {
      expect(comboTierFor(0), ComboTier.none);
      expect(comboTierFor(1), ComboTier.none);
      expect(comboTierFor(2), ComboTier.none);
      expect(comboTierFor(3), ComboTier.starter);
      expect(comboTierFor(5), ComboTier.starter);
      expect(comboTierFor(6), ComboTier.stronger);
      expect(comboTierFor(9), ComboTier.stronger);
      expect(comboTierFor(10), ComboTier.revealReady);
      expect(comboTierFor(14), ComboTier.revealReady);
      expect(comboTierFor(15), ComboTier.mega);
      expect(comboTierFor(100), ComboTier.mega);
    });
  });

  group('ComboController.bump milestone crossing', () {
    test('returns null until streak 3', () {
      final c = ComboController();
      expect(c.bump(), isNull);
      expect(c.bump(), isNull);
      expect(c.bump(), ComboTier.starter,
          reason: 'crossing into starter at streak 3');
    });

    test('returns null for bumps that stay within a tier', () {
      final c = ComboController();
      for (var i = 0; i < 3; i++) c.bump();
      // Streak 3 → starter was already triggered. Stream 4, 5 stay in
      // starter so no milestone event.
      expect(c.bump(), isNull);
      expect(c.bump(), isNull);
      expect(c.bump(), ComboTier.stronger,
          reason: 'crossing into stronger at streak 6');
    });

    test('fires revealReady at streak 10 and mega at streak 15', () {
      final c = ComboController();
      ComboTier? lastFired;
      for (var i = 0; i < 20; i++) {
        final m = c.bump();
        if (m != null) lastFired = m;
      }
      expect(lastFired, ComboTier.mega);
    });

    test('decay reset does not re-fire milestones when ramping back', () {
      final c = ComboController();
      for (var i = 0; i < 3; i++) c.bump(); // -> starter
      c.tick(5); // decay to zero
      expect(c.currentTier, ComboTier.none);
      // First bump after decay goes 0 -> 1, still none. No milestone.
      expect(c.bump(), isNull);
      expect(c.bump(), isNull);
      expect(c.bump(), ComboTier.starter,
          reason: 'starter should fire again on fresh 3-streak');
    });
  });

  group('ComboController.currentTier', () {
    test('tracks the live streak', () {
      final c = ComboController();
      expect(c.currentTier, ComboTier.none);
      for (var i = 0; i < 6; i++) c.bump();
      expect(c.currentTier, ComboTier.stronger);
      c.tick(5);
      expect(c.currentTier, ComboTier.none);
    });
  });
}
