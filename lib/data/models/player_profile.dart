class PlayerProfile {
  PlayerProfile({
    required this.coins,
    required this.unlockedPackIds,
    required this.bestScore,
    required this.bestCombo,
    this.sessionCount = 0,
  });

  int coins;
  Set<String> unlockedPackIds;
  int bestScore;
  int bestCombo;

  /// Monotonic count of gameplay rounds the player has started. Used as
  /// the `session_index` dimension on level_start analytics events.
  int sessionCount;

  factory PlayerProfile.empty() => PlayerProfile(
        coins: 0,
        unlockedPackIds: <String>{'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
        sessionCount: 0,
      );
}
