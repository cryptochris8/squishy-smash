import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/anti_spam_cooldown.dart';

void main() {
  group('AntiSpamCooldown — first-burst behavior', () {
    test('first burst on a smashable is never suppressed', () {
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      expect(
        cd.shouldSuppress(smashableId: 'dumplio', nowMs: 0),
        isFalse,
      );
    });

    test('cooldownMs == 0 disables throttling entirely', () {
      // The "off switch" — JSON shipping cooldownMs=0 must not
      // suppress anything, even immediately after a credit.
      final cd = AntiSpamCooldown(cooldownMs: 0);
      cd.markCredited(smashableId: 'dumplio', nowMs: 0);
      expect(
        cd.shouldSuppress(smashableId: 'dumplio', nowMs: 1),
        isFalse,
      );
      expect(
        cd.shouldSuppress(smashableId: 'dumplio', nowMs: 100),
        isFalse,
      );
    });
  });

  group('AntiSpamCooldown — within cooldown window', () {
    test('a burst inside the window is suppressed', () {
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      cd.markCredited(smashableId: 'dumplio', nowMs: 5000);
      expect(
        cd.shouldSuppress(smashableId: 'dumplio', nowMs: 5500),
        isTrue,
      );
    });

    test('the boundary (exactly at cooldown elapsed) is NOT suppressed', () {
      // Strict less-than: burst at cooldownMs after credit credits
      // again. Avoids a "feels broken at exactly 1.000s" cliff.
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      cd.markCredited(smashableId: 'dumplio', nowMs: 0);
      expect(
        cd.shouldSuppress(smashableId: 'dumplio', nowMs: 1000),
        isFalse,
      );
    });

    test('a burst just past the window is NOT suppressed', () {
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      cd.markCredited(smashableId: 'dumplio', nowMs: 0);
      expect(
        cd.shouldSuppress(smashableId: 'dumplio', nowMs: 1001),
        isFalse,
      );
    });
  });

  group('AntiSpamCooldown — per-smashable independence', () {
    test('cooldown on one smashable does not affect another', () {
      // Varied play (kid taps dumplio, then jellyzap) must NOT be
      // throttled. Anti-spam targets repeated-same-object hammering.
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      cd.markCredited(smashableId: 'dumplio', nowMs: 0);
      expect(
        cd.shouldSuppress(smashableId: 'jellyzap', nowMs: 100),
        isFalse,
        reason: 'different smashable id should not be throttled',
      );
    });

    test('only credited bursts update the timestamp', () {
      // The simulation: tap1 credited at t=0, tap2/tap3/tap4 all
      // suppressed (within window of t=0), tap5 at t=1000 credits
      // again. The timestamp doesn't slide forward on suppressed
      // taps — that would let a spam-tapper extend their cooldown
      // indefinitely.
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      cd.markCredited(smashableId: 'dumplio', nowMs: 0);
      // Suppressed taps don't call markCredited.
      expect(cd.shouldSuppress(smashableId: 'dumplio', nowMs: 200),
          isTrue);
      expect(cd.shouldSuppress(smashableId: 'dumplio', nowMs: 800),
          isTrue);
      // At 1000ms, credit again.
      expect(cd.shouldSuppress(smashableId: 'dumplio', nowMs: 1000),
          isFalse);
    });
  });

  group('AntiSpamCooldown — spam-rate simulation', () {
    test('5 taps/sec for 5 seconds yields ~5 credits at 1s cooldown', () {
      // Real-world model: kid hammers at 5 taps/sec, cooldownMs=1000.
      // Expected credits: 6 (at t = 0, 1000, 2000, 3000, 4000, 5000).
      // The remaining 19 taps are suppressed.
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      var credits = 0;
      for (var t = 0; t <= 5000; t += 200) {
        if (!cd.shouldSuppress(smashableId: 'dumplio', nowMs: t)) {
          cd.markCredited(smashableId: 'dumplio', nowMs: t);
          credits++;
        }
      }
      expect(credits, 6,
          reason: '5 taps/sec spam over 5 seconds with 1s cooldown '
              'should credit ~6 times (at 0, 1, 2, 3, 4, 5 seconds)');
    });

    test('normal play (1 tap per 1.5s) is never throttled', () {
      // Sanity: a normal play cadence on the same smashable is below
      // the cooldown rate, so nothing gets suppressed.
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      var credits = 0;
      for (var t = 0; t <= 7500; t += 1500) {
        if (!cd.shouldSuppress(smashableId: 'dumplio', nowMs: t)) {
          cd.markCredited(smashableId: 'dumplio', nowMs: t);
          credits++;
        }
      }
      expect(credits, 6, // 0, 1500, 3000, 4500, 6000, 7500
          reason: '1.5s cadence with 1s cooldown should never suppress');
    });
  });

  group('AntiSpamCooldown.reset', () {
    test('clears all tracked timestamps', () {
      final cd = AntiSpamCooldown(cooldownMs: 1000);
      cd.markCredited(smashableId: 'dumplio', nowMs: 0);
      cd.reset();
      expect(
        cd.shouldSuppress(smashableId: 'dumplio', nowMs: 100),
        isFalse,
        reason: 'after reset, the smashable should look brand-new',
      );
    });
  });
}
