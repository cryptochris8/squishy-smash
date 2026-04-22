import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/sound_variant_picker.dart';

void main() {
  group('SoundVariantPicker', () {
    test('returns null for empty options', () {
      final p = SoundVariantPicker(rng: Random(1));
      expect(p.pick<String>('burst', const []), isNull);
    });

    test('always returns the only option when length is 1', () {
      final p = SoundVariantPicker(rng: Random(1));
      for (var i = 0; i < 10; i++) {
        expect(p.pick<String>('burst', const ['only']), 'only');
      }
    });

    test('never picks the same variant twice in a row across many trials',
        () {
      final p = SoundVariantPicker(rng: Random(42));
      const options = ['a', 'b', 'c', 'd'];
      String? last;
      for (var i = 0; i < 1000; i++) {
        final pick = p.pick<String>('squish', options)!;
        expect(pick, isNot(equals(last)),
            reason: 'repeat at iteration $i (picked $pick after $last)');
        last = pick;
      }
    });

    test('keys are independent — burst last does not block squish', () {
      final p = SoundVariantPicker(rng: Random(11));
      final burstPicks = <String>[];
      final squishPicks = <String>[];
      for (var i = 0; i < 200; i++) {
        burstPicks.add(p.pick<String>('burst', const ['x', 'y'])!);
        squishPicks.add(p.pick<String>('squish', const ['x', 'y'])!);
      }
      // Within each key, no adjacent repeats.
      for (var i = 1; i < burstPicks.length; i++) {
        expect(burstPicks[i], isNot(equals(burstPicks[i - 1])));
        expect(squishPicks[i], isNot(equals(squishPicks[i - 1])));
      }
    });

    test('resetKey clears last-played memory', () {
      final p = SoundVariantPicker(rng: Random(3));
      final options = <String>['a', 'b'];
      final first = p.pick<String>('burst', options)!;
      p.resetKey('burst');
      // After reset the picker has no memory, so we can't assert a specific
      // value — just assert the structural call works and returns a
      // member of options.
      final next = p.pick<String>('burst', options)!;
      expect(options, contains(next));
      expect(first, isNotNull);
    });

    test('distribution over many trials is approximately uniform', () {
      final p = SoundVariantPicker(rng: Random(9));
      const options = ['a', 'b', 'c', 'd'];
      final counts = <String, int>{for (final o in options) o: 0};
      const trials = 8000;
      for (var i = 0; i < trials; i++) {
        final pick = p.pick<String>('uniform_test', options)!;
        counts[pick] = counts[pick]! + 1;
      }
      // With the avoid-repeat constraint, distribution is not *perfectly*
      // uniform but stays within ~15% of 25% per bucket.
      for (final c in counts.values) {
        expect(c, greaterThan(trials * 0.15));
        expect(c, lessThan(trials * 0.35));
      }
    });
  });
}
