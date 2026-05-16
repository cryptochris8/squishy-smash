import 'package:flutter_test/flutter_test.dart';

import 'package:squishy_smash/game/components/screen_shake.dart';

/// Pins the linear-falloff envelope curve added in P1-B
/// (GAME_POLISH_AUDIT.md). Pre-fix `update()` held flat amplitude
/// for the whole shake window then snapped back to origin — the
/// biggest moments (mythic at intensity=14, duration=0.22) felt like
/// a phone vibrating on a table instead of a detonation. The new
/// envelope multiplies the random offset by `remaining / duration`
/// so amplitude decays smoothly to zero.
///
/// Testing the envelope function alone (not the camera coupling)
/// keeps these tests Flame-free and deterministic.
void main() {
  group('ScreenShake.computeEnvelope', () {
    test('at t=0 (full remaining), envelope is 1.0 (full intensity)', () {
      expect(ScreenShake.computeEnvelope(0.22, 0.22), 1.0);
    });

    test('at the halfway point, envelope is 0.5 (half intensity)', () {
      expect(ScreenShake.computeEnvelope(0.11, 0.22), closeTo(0.5, 1e-9));
    });

    test('at t=duration (zero remaining), envelope is 0.0 (silent)', () {
      expect(ScreenShake.computeEnvelope(0.0, 0.22), 0.0);
    });

    test('clamps negative remaining to 0 — the post-window safety belt',
        () {
      // update() decrements _remaining by dt and only resets to
      // origin on the *next* tick if it crossed zero. The envelope
      // must clamp to 0 for that one frame so the shake doesn't
      // briefly invert.
      expect(ScreenShake.computeEnvelope(-0.01, 0.22), 0.0);
    });

    test('returns 0 when duration is zero or negative — degenerate guard',
        () {
      // Prevents divide-by-zero if someone calls shake(duration: 0).
      expect(ScreenShake.computeEnvelope(1.0, 0.0), 0.0);
      expect(ScreenShake.computeEnvelope(1.0, -0.5), 0.0);
    });

    test('envelope decays monotonically across the window', () {
      const total = 0.28; // mega-burst duration
      double prev = double.infinity;
      for (var i = 0; i <= 10; i++) {
        final remaining = total * (1.0 - i / 10);
        final env = ScreenShake.computeEnvelope(remaining, total);
        expect(env, lessThanOrEqualTo(prev),
            reason: 'envelope must never increase as time passes');
        prev = env;
      }
      // Sanity: end at zero.
      expect(prev, 0.0);
    });
  });
}
