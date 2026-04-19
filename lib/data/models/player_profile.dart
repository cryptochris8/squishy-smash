class PlayerProfile {
  PlayerProfile({
    required this.coins,
    required this.unlockedPackIds,
    required this.bestScore,
    required this.bestCombo,
  });

  int coins;
  Set<String> unlockedPackIds;
  int bestScore;
  int bestCombo;

  factory PlayerProfile.empty() => PlayerProfile(
        coins: 0,
        unlockedPackIds: <String>{'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
      );
}
