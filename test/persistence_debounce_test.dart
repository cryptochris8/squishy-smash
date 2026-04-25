import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/data/models/player_profile.dart';
import 'package:squishy_smash/data/persistence.dart';

PlayerProfile _profile({required int coins}) => PlayerProfile(
      coins: coins,
      unlockedPackIds: const {'launch_squishy_foods'},
      bestScore: 0,
      bestCombo: 0,
    );

/// Helper: run [body] inside a FakeAsync zone and pump microtasks +
/// elapse the given [tick]. shared_preferences (in-memory mock) writes
/// resolve on microtask flushes, so each `elapse` also processes any
/// pending awaits the saveProfile path may have queued.
void _runFake(FakeAsync async_, Duration tick) {
  async_.flushMicrotasks();
  async_.elapse(tick);
  async_.flushMicrotasks();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Persistence.scheduleSave debouncing', () {
    test('does not write before the debounce window elapses', () {
      fakeAsync((async_) {
        late Persistence p;
        Persistence.open().then((v) => p = v);
        async_.flushMicrotasks();

        p.scheduleSave(_profile(coins: 999));

        // Advance to just before the debounce fires.
        _runFake(async_, Persistence.saveDebounce - const Duration(milliseconds: 50));

        // No write yet — re-open should still see the empty profile.
        late Persistence p2;
        Persistence.open().then((v) => p2 = v);
        async_.flushMicrotasks();
        expect(p2.loadProfile().coins, 0);
      });
    });

    test('writes once after the debounce window elapses', () {
      fakeAsync((async_) {
        late Persistence p;
        Persistence.open().then((v) => p = v);
        async_.flushMicrotasks();

        p.scheduleSave(_profile(coins: 777));

        _runFake(async_, Persistence.saveDebounce + const Duration(milliseconds: 50));

        late Persistence p2;
        Persistence.open().then((v) => p2 = v);
        async_.flushMicrotasks();
        expect(p2.loadProfile().coins, 777);
      });
    });

    test('rapid-fire scheduleSave calls collapse into one write', () {
      fakeAsync((async_) {
        late Persistence p;
        Persistence.open().then((v) => p = v);
        async_.flushMicrotasks();

        // Burst of 5 schedules in rapid succession with the latest
        // value being the only one that should land on disk.
        for (var i = 1; i <= 5; i++) {
          p.scheduleSave(_profile(coins: i * 100));
          _runFake(async_, const Duration(milliseconds: 50));
        }
        // None of those should have written yet (still inside debounce
        // since each schedule resets the timer).
        late Persistence midCheck;
        Persistence.open().then((v) => midCheck = v);
        async_.flushMicrotasks();
        expect(midCheck.loadProfile().coins, 0,
            reason: 'rapid schedules must coalesce — nothing written yet');

        // Now let the timer fire.
        _runFake(async_, Persistence.saveDebounce + const Duration(milliseconds: 50));

        late Persistence after;
        Persistence.open().then((v) => after = v);
        async_.flushMicrotasks();
        expect(after.loadProfile().coins, 500,
            reason: 'only the last scheduled value should persist');
      });
    });
  });

  group('Persistence.flushPending', () {
    test('writes the pending profile immediately', () async {
      final p = await Persistence.open();
      p.scheduleSave(_profile(coins: 4242));
      await p.flushPending();

      // No timer wait needed — flushPending should have written now.
      final p2 = await Persistence.open();
      expect(p2.loadProfile().coins, 4242);
    });

    test('is a no-op when nothing is pending', () async {
      final p = await Persistence.open();
      // No scheduleSave first — flushPending should resolve cleanly.
      await p.flushPending();
      // And not have written anything spurious.
      final p2 = await Persistence.open();
      expect(p2.loadProfile().coins, 0);
    });

    test('cancels the pending debounce timer (no double-write)', () {
      fakeAsync((async_) {
        late Persistence p;
        Persistence.open().then((v) => p = v);
        async_.flushMicrotasks();

        p.scheduleSave(_profile(coins: 100));
        // Trigger flush before the debounce timer fires.
        p.flushPending();
        async_.flushMicrotasks();

        // Now mutate the profile externally and write a different
        // value through saveProfile — if the canceled timer fires,
        // it would clobber this value with 100.
        p.scheduleSave(_profile(coins: 200));
        _runFake(async_, Persistence.saveDebounce + const Duration(milliseconds: 50));

        late Persistence p2;
        Persistence.open().then((v) => p2 = v);
        async_.flushMicrotasks();
        expect(p2.loadProfile().coins, 200,
            reason: 'flushPending must have canceled the prior timer');
      });
    });
  });

  group('Persistence.saveProfile cancels pending debounce', () {
    test('a direct saveProfile after scheduleSave wins (no double-write)', () {
      fakeAsync((async_) {
        late Persistence p;
        Persistence.open().then((v) => p = v);
        async_.flushMicrotasks();

        // Schedule a debounced write of 111 coins.
        p.scheduleSave(_profile(coins: 111));
        // Then immediately overwrite with a direct save of 222.
        p.saveProfile(_profile(coins: 222));
        async_.flushMicrotasks();

        // Let the (now-canceled) debounce timer's window pass.
        _runFake(async_, Persistence.saveDebounce + const Duration(milliseconds: 50));

        late Persistence p2;
        Persistence.open().then((v) => p2 = v);
        async_.flushMicrotasks();
        expect(p2.loadProfile().coins, 222,
            reason: 'direct saveProfile must cancel the pending timer '
                'so the older buffered value cannot overwrite it');
      });
    });
  });
}
