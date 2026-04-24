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
    Set<String>? discoveredSmashableIds,
    this.rarestSeen = Rarity.common,
    Map<String, int>? totalBurstsByPack,
    Map<String, int>? rareDryByPack,
    Map<String, int>? epicDryByPack,
    Map<String, int>? legendaryDryByPack,
    this.lastPlayDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.boostTokens = 0,
  })  : unlockedArenaKeys =
            unlockedArenaKeys ?? <String>{'mochi_sunset_beach'},
        discoveredSmashableIds = discoveredSmashableIds ?? <String>{},
        totalBurstsByPack = totalBurstsByPack ?? <String, int>{},
        rareDryByPack = rareDryByPack ?? <String, int>{},
        epicDryByPack = epicDryByPack ?? <String, int>{},
        legendaryDryByPack = legendaryDryByPack ?? <String, int>{};

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

  /// Smashable IDs the player has burst at least once. Source of truth
  /// for the collection shelf / rarity book meta layer.
  Set<String> discoveredSmashableIds;

  /// Highest rarity tier the player has ever bursted. Shown on the
  /// "rarest squishy found" stat — monotonically non-decreasing.
  Rarity rarestSeen;

  /// Total bursts per pack. Drives unlock-gate progression (rare/epic/
  /// legendary tiers unlock after N total reveals in that pack).
  Map<String, int> totalBurstsByPack;

  /// Reveals since the player last saw a rare-or-better in this pack.
  /// Drives the rare pity soft/hard thresholds.
  Map<String, int> rareDryByPack;

  /// Reveals since the last epic-or-better in this pack.
  Map<String, int> epicDryByPack;

  /// Reveals since the last legendary in this pack.
  Map<String, int> legendaryDryByPack;

  /// Date string (yyyy-MM-dd in local time) of the last gameplay
  /// round the player completed. Null for fresh installs. Used to
  /// advance or reset [currentStreak] on app launch.
  String? lastPlayDate;

  /// Consecutive-day play streak. Increments when the player returns
  /// the day after [lastPlayDate], resets to 1 on any longer gap.
  int currentStreak;

  /// Longest streak ever achieved — read-only trophy stat.
  int longestStreak;

  /// Unused boost tokens. Each token adds a +50% multiplier to rare+
  /// weights for a single spawn pick when consumed. Tokens are granted
  /// on streak milestones or (later) from rewarded-ad views.
  int boostTokens;

  factory PlayerProfile.empty() => PlayerProfile(
        coins: 0,
        unlockedPackIds: <String>{'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
        sessionCount: 0,
        unlockedArenaKeys: <String>{'mochi_sunset_beach'},
        activeArenaKey: 'mochi_sunset_beach',
        discoveredSmashableIds: <String>{},
        rarestSeen: Rarity.common,
        totalBurstsByPack: <String, int>{},
        rareDryByPack: <String, int>{},
        epicDryByPack: <String, int>{},
        legendaryDryByPack: <String, int>{},
        lastPlayDate: null,
        currentStreak: 0,
        longestStreak: 0,
        boostTokens: 0,
      );
}
