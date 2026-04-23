import 'rarity.dart';

class PlayerProfile {
  PlayerProfile({
    required this.coins,
    required this.unlockedPackIds,
    required this.bestScore,
    required this.bestCombo,
    this.sessionCount = 0,
    Set<String>? unlockedArenaKeys,
    this.activeArenaKey = 'mochi_sunset_beach',
    this.rollsSinceRare = 0,
    this.rollsSinceEpic = 0,
    this.rollsSinceMythic = 0,
    Set<String>? discoveredSmashableIds,
    this.rarestSeen = Rarity.common,
    Map<String, int>? rareBurstsByPack,
    Map<String, int>? epicBurstsByPack,
  })  : unlockedArenaKeys =
            unlockedArenaKeys ?? <String>{'mochi_sunset_beach'},
        discoveredSmashableIds = discoveredSmashableIds ?? <String>{},
        rareBurstsByPack = rareBurstsByPack ?? <String, int>{},
        epicBurstsByPack = epicBurstsByPack ?? <String, int>{};

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

  /// Spawns since the player last rolled a rare-or-better smashable.
  /// Drives pity logic so unlucky streaks eventually force a rare+.
  int rollsSinceRare;

  /// Spawns since the last epic-or-better smashable.
  int rollsSinceEpic;

  /// Spawns since the last mythic.
  int rollsSinceMythic;

  /// Smashable IDs the player has burst at least once. Source of truth
  /// for the collection shelf / rarity book meta layer.
  Set<String> discoveredSmashableIds;

  /// Highest rarity tier the player has ever bursted. Shown on the
  /// "rarest squishy found" stat — monotonically non-decreasing.
  Rarity rarestSeen;

  /// Count of rare-or-better bursts per pack. Drives epic-tier
  /// unlock gating. Keys are pack IDs; missing key = 0.
  Map<String, int> rareBurstsByPack;

  /// Count of epic-or-better bursts per pack. Drives legendary-tier
  /// unlock gating.
  Map<String, int> epicBurstsByPack;

  factory PlayerProfile.empty() => PlayerProfile(
        coins: 0,
        unlockedPackIds: <String>{'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
        sessionCount: 0,
        unlockedArenaKeys: <String>{'mochi_sunset_beach'},
        activeArenaKey: 'mochi_sunset_beach',
        rollsSinceRare: 0,
        rollsSinceEpic: 0,
        rollsSinceMythic: 0,
        discoveredSmashableIds: <String>{},
        rarestSeen: Rarity.common,
        rareBurstsByPack: <String, int>{},
        epicBurstsByPack: <String, int>{},
      );
}
