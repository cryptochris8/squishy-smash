import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:squishy_smash/game/systems/idle_voice_trigger.dart';

/// Pins the silence/cooldown logic for the ASMR idle VO trigger
/// (GAME_POLISH_AUDIT.md P1-A). The 5 idle whispers warmed at boot
/// were dead code until this trigger landed; these tests make sure
/// the silence detector, the cooldown gate, and the user-interaction
/// reset all stay correctly wired through future refactors.
///
/// Tests use a seeded [Random] so the picked path is deterministic
/// — otherwise the "returns a line" assertions could pass by luck
/// while a real bug returned the wrong path.
void main() {
  const lines = <String>[
    'audio/vo/vo_asmr_idle_a.mp3',
    'audio/vo/vo_asmr_idle_b.mp3',
    'audio/vo/vo_asmr_idle_c.mp3',
  ];

  group('IdleVoiceTrigger', () {
    test('returns null before silence threshold elapses', () {
      final t = IdleVoiceTrigger(
        lines: lines,
        rng: Random(42),
        silenceThreshold: 3.0,
      );
      // Tick to 2.99 s of accumulated silence — still under the
      // threshold, so nothing should fire.
      expect(t.tick(1.0), isNull);
      expect(t.tick(1.0), isNull);
      expect(t.tick(0.99), isNull);
    });

    test('fires a line the first frame the silence threshold crosses',
        () {
      final t = IdleVoiceTrigger(
        lines: lines,
        rng: Random(42),
        silenceThreshold: 3.0,
      );
      t.tick(1.0);
      t.tick(1.0);
      // Crossing 3.0s in this tick should fire.
      final pick = t.tick(1.0);
      expect(pick, isNotNull);
      expect(lines.contains(pick), isTrue,
          reason: 'returned path must come from the configured pool');
    });

    test('respects cooldown — no fire during the post-fire window', () {
      final t = IdleVoiceTrigger(
        lines: lines,
        rng: Random(42),
        silenceThreshold: 3.0,
        cooldown: 8.0,
      );
      // Cross threshold, fire once.
      t.tick(1.0);
      t.tick(1.0);
      expect(t.tick(1.0), isNotNull);
      // Silence keeps accumulating — but cooldown should suppress
      // any further fire until 8 s have passed.
      for (var i = 0; i < 7; i++) {
        expect(t.tick(1.0), isNull,
            reason: 'cooldown must suppress fires for 8 s after a play');
      }
    });

    test('fires again once cooldown elapses + silence re-crosses', () {
      final t = IdleVoiceTrigger(
        lines: lines,
        rng: Random(42),
        silenceThreshold: 3.0,
        cooldown: 8.0,
      );
      // First fire: silence reaches 3.0 on the second tick. After
      // the fire silenceAccum resets to 0 and cooldown arms at 8.0.
      t.tick(1.5);
      expect(t.tick(1.5), isNotNull,
          reason: 'first fire is the moment silence crosses threshold');
      // Cooldown 8.0, silence 0. Tick silently for 7 s — silence
      // accumulates the whole time, but cooldown gates every tick.
      // (silence crosses 3 s at tick #3 but cooldown is still > 0.)
      for (var i = 0; i < 7; i++) {
        expect(t.tick(1.0), isNull,
            reason: 'cooldown must gate fires during its window');
      }
      // 7 s elapsed → cooldown is 1, silence is 7. One more 1.0s
      // tick brings cooldown to exactly 0 and silence to 8, which
      // satisfies both gates, so the trigger fires on that tick.
      final pick = t.tick(1.0);
      expect(pick, isNotNull,
          reason: 'after cooldown + sustained silence, must re-fire');
    });

    test('reset() clears silence so an interaction stops a pending fire',
        () {
      final t = IdleVoiceTrigger(
        lines: lines,
        rng: Random(42),
        silenceThreshold: 3.0,
      );
      // Build up 2.9 s of silence — close to firing.
      t.tick(1.0);
      t.tick(1.0);
      t.tick(0.9);
      // Player taps. Silence accumulator should clear.
      t.reset();
      // Even ticking another 2.5 s should not fire — total silence
      // since reset is only 2.5 s.
      expect(t.tick(1.0), isNull);
      expect(t.tick(1.0), isNull);
      expect(t.tick(0.5), isNull);
    });

    test('reset() does NOT clear an active cooldown', () {
      // The cooldown is a "minimum gap between plays" guarantee.
      // A player who taps right after a fire shouldn't unlock the
      // next fire any sooner than they would have by staying still.
      final t = IdleVoiceTrigger(
        lines: lines,
        rng: Random(42),
        silenceThreshold: 3.0,
        cooldown: 8.0,
      );
      // Fire once: silence reaches 3.0 on second tick.
      t.tick(1.5);
      expect(t.tick(1.5), isNotNull);
      // Player interacts immediately after the fire.
      t.reset();
      // Tick well past the silence threshold (4 s) but still inside
      // the 8 s cooldown — must not fire.
      for (var i = 0; i < 4; i++) {
        t.tick(1.0);
      }
      expect(t.tick(0.001), isNull,
          reason: 'reset() must not bypass an in-flight cooldown');
    });

    test('empty lines pool never fires — defensive against registry edit',
        () {
      final t = IdleVoiceTrigger(
        lines: const <String>[],
        rng: Random(42),
        silenceThreshold: 0.5,
      );
      // Tick well past any plausible threshold.
      for (var i = 0; i < 20; i++) {
        expect(t.tick(1.0), isNull);
      }
    });

    test('seeded RNG picks deterministically — same seed, same path', () {
      final a = IdleVoiceTrigger(lines: lines, rng: Random(7));
      final b = IdleVoiceTrigger(lines: lines, rng: Random(7));
      // Same silence elapsed, same seed → same pick.
      a.tick(2.0);
      b.tick(2.0);
      final pickA = a.tick(2.0);
      final pickB = b.tick(2.0);
      expect(pickA, equals(pickB));
    });
  });
}
