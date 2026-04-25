import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/squishy_game.dart';
import 'package:squishy_smash/game/systems/combo_controller.dart';

void main() {
  group('composeHudSnapshot quantization', () {
    test('rounds fill to the nearest 1% (down)', () {
      final snap = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.123,
        tier: ComboTier.none,
      );
      expect(snap.fill, 0.12);
    });

    test('rounds fill to the nearest 1% (up)', () {
      final snap = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.567,
        tier: ComboTier.none,
      );
      expect(snap.fill, 0.57);
    });

    test('clamps fill above 1.0 to 1.0', () {
      final snap = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 1.4,
        tier: ComboTier.none,
      );
      expect(snap.fill, 1.0);
    });

    test('clamps fill below 0.0 to 0.0', () {
      final snap = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: -0.3,
        tier: ComboTier.none,
      );
      expect(snap.fill, 0.0);
    });

    test('passes through score, mult, and tier untouched', () {
      final snap = composeHudSnapshot(
        score: 12345,
        mult: 7,
        fill: 0.5,
        tier: ComboTier.mega,
      );
      expect(snap.score, 12345);
      expect(snap.mult, 7);
      expect(snap.tier, ComboTier.mega);
    });
  });

  group('HudSnapshot record equality', () {
    test('two snapshots with identical fields are equal', () {
      final a = composeHudSnapshot(
        score: 100,
        mult: 2,
        fill: 0.5,
        tier: ComboTier.starter,
      );
      final b = composeHudSnapshot(
        score: 100,
        mult: 2,
        fill: 0.5,
        tier: ComboTier.starter,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('snapshots that quantize to the same fill are equal', () {
      // 0.501 and 0.504 both quantize to 0.50 — equality short-circuit
      // means the HUD won't rebuild for sub-percent jitter.
      final a = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.501,
        tier: ComboTier.none,
      );
      final b = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.504,
        tier: ComboTier.none,
      );
      expect(a, equals(b));
    });

    test('a tier change produces a non-equal snapshot', () {
      final a = composeHudSnapshot(
        score: 100,
        mult: 2,
        fill: 0.5,
        tier: ComboTier.starter,
      );
      final b = composeHudSnapshot(
        score: 100,
        mult: 2,
        fill: 0.5,
        tier: ComboTier.stronger,
      );
      expect(a, isNot(equals(b)));
    });

    test('a score change produces a non-equal snapshot', () {
      final a = composeHudSnapshot(
        score: 100,
        mult: 1,
        fill: 0.0,
        tier: ComboTier.none,
      );
      final b = composeHudSnapshot(
        score: 101,
        mult: 1,
        fill: 0.0,
        tier: ComboTier.none,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('ValueNotifier<HudSnapshot> notification semantics', () {
    test('writing an equal snapshot does NOT fire listeners', () {
      final initial = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.0,
        tier: ComboTier.none,
      );
      final notifier = ValueNotifier<HudSnapshot>(initial);
      var fires = 0;
      notifier.addListener(() => fires++);

      // Same field values — record equality short-circuits.
      notifier.value = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.0,
        tier: ComboTier.none,
      );
      expect(fires, 0);

      // Sub-percent fill jitter that quantizes to the same value.
      notifier.value = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.0049,
        tier: ComboTier.none,
      );
      expect(fires, 0,
          reason: 'fill 0.0049 quantizes to 0.00 — equal to current');
    });

    test('writing a changed snapshot fires listeners exactly once', () {
      final notifier = ValueNotifier<HudSnapshot>(
        composeHudSnapshot(
          score: 0,
          mult: 1,
          fill: 0.0,
          tier: ComboTier.none,
        ),
      );
      var fires = 0;
      notifier.addListener(() => fires++);

      notifier.value = composeHudSnapshot(
        score: 50,
        mult: 1,
        fill: 0.0,
        tier: ComboTier.none,
      );
      expect(fires, 1);

      notifier.value = composeHudSnapshot(
        score: 50,
        mult: 2,
        fill: 0.0,
        tier: ComboTier.starter,
      );
      expect(fires, 2);
    });

    test('1% fill movement fires a notification', () {
      final notifier = ValueNotifier<HudSnapshot>(
        composeHudSnapshot(
          score: 0,
          mult: 1,
          fill: 0.50,
          tier: ComboTier.none,
        ),
      );
      var fires = 0;
      notifier.addListener(() => fires++);

      notifier.value = composeHudSnapshot(
        score: 0,
        mult: 1,
        fill: 0.51,
        tier: ComboTier.none,
      );
      expect(fires, 1, reason: '1% fill change should fire');
    });
  });
}
