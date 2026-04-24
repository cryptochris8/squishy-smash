import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/components/reveal_bloom.dart';

void main() {
  group('RevealBloom.bloomShape', () {
    test('is 0 at the endpoints', () {
      expect(RevealBloom.bloomShape(0), 0);
      expect(RevealBloom.bloomShape(1), 0);
    });

    test('peaks at t = 0.22', () {
      final atPeak = RevealBloom.bloomShape(0.22);
      final beforePeak = RevealBloom.bloomShape(0.1);
      final afterPeak = RevealBloom.bloomShape(0.5);
      expect(atPeak, closeTo(1.0, 1e-9));
      expect(beforePeak, lessThan(atPeak));
      expect(afterPeak, lessThan(atPeak));
    });

    test('rises monotonically before the peak', () {
      double? prev;
      for (final t in [0.0, 0.05, 0.1, 0.15, 0.2, 0.22]) {
        final v = RevealBloom.bloomShape(t);
        if (prev != null) {
          expect(v, greaterThanOrEqualTo(prev),
              reason: 'bloomShape should be non-decreasing to peak');
        }
        prev = v;
      }
    });

    test('falls monotonically after the peak', () {
      double? prev;
      for (final t in [0.22, 0.3, 0.5, 0.7, 0.9, 1.0]) {
        final v = RevealBloom.bloomShape(t);
        if (prev != null) {
          expect(v, lessThanOrEqualTo(prev),
              reason: 'bloomShape should be non-increasing after peak');
        }
        prev = v;
      }
    });

    test('clamps safely for out-of-range inputs', () {
      expect(RevealBloom.bloomShape(-0.1), 0);
      expect(RevealBloom.bloomShape(1.5), 0);
    });
  });
}
