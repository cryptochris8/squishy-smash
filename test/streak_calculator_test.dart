import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/streak_calculator.dart';

void main() {
  const calc = StreakCalculator();

  group('StreakCalculator.compute', () {
    test('first ever launch (null lastPlayDate) starts streak at 1', () {
      final update = calc.compute(
        today: '2026-04-23',
        lastPlayDate: null,
        currentStreak: 0,
      );
      expect(update.newStreak, 1);
      expect(update.milestoneReached, isFalse);
    });

    test('same-day replay keeps streak stable', () {
      final update = calc.compute(
        today: '2026-04-23',
        lastPlayDate: '2026-04-23',
        currentStreak: 5,
      );
      expect(update.newStreak, 5);
      expect(update.milestoneReached, isFalse);
    });

    test('consecutive day increments streak', () {
      final update = calc.compute(
        today: '2026-04-24',
        lastPlayDate: '2026-04-23',
        currentStreak: 1,
      );
      expect(update.newStreak, 2);
      expect(update.milestoneReached, isFalse);
    });

    test('two-day gap resets streak to 1', () {
      final update = calc.compute(
        today: '2026-04-25',
        lastPlayDate: '2026-04-23',
        currentStreak: 10,
      );
      expect(update.newStreak, 1);
      expect(update.milestoneReached, isFalse);
    });

    test('week-long gap still resets to 1', () {
      final update = calc.compute(
        today: '2026-05-01',
        lastPlayDate: '2026-04-23',
        currentStreak: 4,
      );
      expect(update.newStreak, 1);
    });

    test('crosses a month boundary correctly', () {
      final update = calc.compute(
        today: '2026-05-01',
        lastPlayDate: '2026-04-30',
        currentStreak: 2,
      );
      expect(update.newStreak, 3);
      expect(update.milestoneReached, isTrue,
          reason: 'day 3 is a milestone');
    });

    test('malformed previous date treated as reset', () {
      final update = calc.compute(
        today: '2026-04-24',
        lastPlayDate: 'not-a-date',
        currentStreak: 6,
      );
      expect(update.newStreak, 1);
    });
  });

  group('StreakCalculator milestone detection', () {
    test('hits 3/7/14/30 cleanly on first reach', () {
      for (final milestone in [3, 7, 14, 30]) {
        final update = calc.compute(
          today: '2026-05-01',
          lastPlayDate: '2026-04-30',
          currentStreak: milestone - 1,
        );
        expect(update.newStreak, milestone);
        expect(update.milestoneReached, isTrue,
            reason: 'streak reaching $milestone should fire milestone');
        expect(update.milestone, milestone);
      }
    });

    test('intermediate days (4, 5, 6, 8, 9, 15, 29) do NOT fire', () {
      for (final day in [4, 5, 6, 8, 9, 15, 29]) {
        final update = calc.compute(
          today: '2026-05-01',
          lastPlayDate: '2026-04-30',
          currentStreak: day - 1,
        );
        expect(update.milestoneReached, isFalse,
            reason: 'day $day should not fire a milestone');
      }
    });

    test('re-entering same-day on a milestone does not re-fire', () {
      // Player already at streak 3. They played today (same day),
      // launching the app again. No milestone re-fire.
      final update = calc.compute(
        today: '2026-04-23',
        lastPlayDate: '2026-04-23',
        currentStreak: 3,
      );
      expect(update.newStreak, 3);
      expect(update.milestoneReached, isFalse);
    });
  });

  group('todayLocalIso', () {
    test('formats year-month-day with zero padding', () {
      expect(todayLocalIso(DateTime(2026, 1, 5)), '2026-01-05');
      expect(todayLocalIso(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });
}
