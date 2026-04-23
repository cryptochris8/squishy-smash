class PlayerProfile {
  PlayerProfile({
    required this.coins,
    required this.unlockedPackIds,
    required this.bestScore,
    required this.bestCombo,
    this.sessionCount = 0,
    Set<String>? unlockedArenaKeys,
    this.activeArenaKey = 'mochi_sunset_beach',
  }) : unlockedArenaKeys =
            unlockedArenaKeys ?? <String>{'mochi_sunset_beach'};

  int coins;
  Set<String> unlockedPackIds;
  int bestScore;
  int bestCombo;

  /// Monotonic count of gameplay rounds the player has started. Used as
  /// the `session_index` dimension on level_start analytics events.
  int sessionCount;

  /// Arena themes the player owns — either auto-granted via a pack
  /// unlock (every ArenaTheme.bundledWithPack) or purchased standalone
  /// in the shop. Defaults to just `mochi_sunset_beach` (matches the
  /// free launch pack).
  Set<String> unlockedArenaKeys;

  /// Arena key currently rendered behind the action — picked from
  /// `unlockedArenaKeys` via the Settings screen. Defaults to
  /// `mochi_sunset_beach` for new players.
  String activeArenaKey;

  factory PlayerProfile.empty() => PlayerProfile(
        coins: 0,
        unlockedPackIds: <String>{'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
        sessionCount: 0,
        unlockedArenaKeys: <String>{'mochi_sunset_beach'},
        activeArenaKey: 'mochi_sunset_beach',
      );
}
