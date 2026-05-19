/// Pure streak-bookkeeping logic. Call [compute] on app launch with
/// today's date (in local time, as `yyyy-MM-dd`) plus the player's
/// [lastPlayDate] and [currentStreak]. Returns the new streak state
/// and whether a milestone boost token should be awarded.
///
/// Rules:
///   * first ever launch (lastPlayDate == null) → streak = 1
///   * same calendar day as last play → no change
///   * exactly one day later → streak++
///   * any other gap → streak = 1 (reset)
///
/// Milestone boosts are granted when the updated streak crosses into
/// one of {3, 7, 14, 30}. A player who returns on day 3 gets one
/// token; they do NOT get a second token when their streak passes 3
/// again after a reset unless they actually reach day 3 anew.
class StreakCalculator {
  const StreakCalculator();

  static const List<int> milestoneDays = [3, 7, 14, 30];

  StreakUpdate compute({
    required String today,
    required String? lastPlayDate,
    required int currentStreak,
  }) {
    if (lastPlayDate == null) {
      return const StreakUpdate(
        newStreak: 1,
        milestoneReached: false,
        milestone: 0,
      );
    }
    if (lastPlayDate == today) {
      return StreakUpdate(
        newStreak: currentStreak,
        milestoneReached: false,
        milestone: 0,
      );
    }
    final newStreak =
        _isConsecutive(lastPlayDate, today) ? currentStreak + 1 : 1;
    final hitMilestone = milestoneDays.contains(newStreak) &&
        !milestoneDays.contains(currentStreak);
    return StreakUpdate(
      newStreak: newStreak,
      milestoneReached: hitMilestone && newStreak > currentStreak,
      milestone: hitMilestone ? newStreak : 0,
    );
  }

  bool _isConsecutive(String yesterday, String today) {
    // Defensive parse; if either string is malformed, treat as reset.
    // Compare strictly in calendar-date space — Duration.inDays uses
    // fixed 86400s units, so a 23h DST-forward or 25h DST-back gap
    // could read as 0 or 2 days for a real one-calendar-day delta and
    // bork the streak silently.
    try {
      final yParts = yesterday.split('-').map(int.parse).toList();
      final tParts = today.split('-').map(int.parse).toList();
      if (yParts.length != 3 || tParts.length != 3) return false;
      // DateTime(y, m, d + 1) normalizes month/year overflow, so this
      // is safe across month and year boundaries (Apr 31 -> May 1).
      final yNext = DateTime(yParts[0], yParts[1], yParts[2] + 1);
      return yNext.year == tParts[0] &&
          yNext.month == tParts[1] &&
          yNext.day == tParts[2];
    } catch (_) {
      return false;
    }
  }
}

class StreakUpdate {
  const StreakUpdate({
    required this.newStreak,
    required this.milestoneReached,
    required this.milestone,
  });

  final int newStreak;
  final bool milestoneReached;
  final int milestone;
}

/// Format the current local date as `yyyy-MM-dd` — matches the
/// [DateTime.parse]-compatible shape used by [StreakCalculator].
String todayLocalIso(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
