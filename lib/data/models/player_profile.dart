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
    this.hasRemoveAds = false,
    this.starterBundleClaimed = false,
    Map<Rarity, int>? guaranteedRevealTokens,
    Set<String>? purchasedSkus,
    Map<String, int>? cardBurstCounts,
    Set<String>? cardsPurchased,
    Set<String>? claimedAchievements,
    Set<String>? grandfatheredCards,
    Set<String>? packMilestonesClaimed,
  })  : guaranteedRevealTokens = guaranteedRevealTokens ?? <Rarity, int>{},
        purchasedSkus = purchasedSkus ?? <String>{},
        unlockedArenaKeys =
            unlockedArenaKeys ?? <String>{'mochi_sunset_beach'},
        discoveredSmashableIds = discoveredSmashableIds ?? <String>{},
        totalBurstsByPack = totalBurstsByPack ?? <String, int>{},
        rareDryByPack = rareDryByPack ?? <String, int>{},
        epicDryByPack = epicDryByPack ?? <String, int>{},
        legendaryDryByPack = legendaryDryByPack ?? <String, int>{},
        cardBurstCounts = cardBurstCounts ?? <String, int>{},
        cardsPurchased = cardsPurchased ?? <String>{},
        claimedAchievements = claimedAchievements ?? <String>{},
        grandfatheredCards = grandfatheredCards ?? <String>{},
        packMilestonesClaimed = packMilestonesClaimed ?? <String>{};

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

  /// Remove-ads entitlement — set to true after a successful purchase
  /// of the `remove_ads` non-consumable IAP. Persists across relaunch.
  bool hasRemoveAds;

  /// True after the player has successfully purchased the
  /// `starter_bundle_v1` IAP. Non-consumable — one per player.
  bool starterBundleClaimed;

  /// Queue of forced-tier reveal tokens. When the player has any tokens
  /// of a given tier, the next spawn will bypass normal weighting and
  /// force an object of that tier. Consumed on spawn. Granted by the
  /// Starter Bundle ("guaranteed rare") or future premium offers.
  Map<Rarity, int> guaranteedRevealTokens;

  /// All non-consumable + consumable SKU IDs the player has purchased
  /// in their lifetime. Used for analytics (`was_first_purchase` param)
  /// and restore-purchases reconciliation. Does not count consumables
  /// that have been used up — this is the "receipt history" set.
  Set<String> purchasedSkus;

  /// Per-card burst counter, keyed by card_number (e.g., "001/048").
  /// Drives the "play to earn" path: a card unlocks once its counter
  /// crosses the rarity-specific threshold (Common 1, Rare 3, Epic 7,
  /// Legendary 15 — see `CardUnlockThresholds.requiredBursts`). Bumped
  /// in `ProgressionRepository.incrementBurstForCard` whenever a player
  /// bursts a smashable that maps to this card.
  Map<String, int> cardBurstCounts;

  /// Card numbers the player has unlocked directly with coins. Independent
  /// of `cardBurstCounts` and `claimedAchievements` — any single non-empty
  /// path is enough to mark a card unlocked.
  Set<String> cardsPurchased;

  /// Achievement IDs the player has claimed (and received the reward for).
  /// Used both to render the achievement progress shelf and to gate
  /// achievement-rewarded cards in the unlock derivation.
  Set<String> claimedAchievements;

  /// Card numbers that were unlocked under a previous economy config
  /// and should stay unlocked even if a re-tightened threshold would
  /// otherwise lock them. Populated on the v3 → v4 migration: any card
  /// already meeting its (old) burst threshold gets snapshotted here
  /// so a player who completed 80% of the album under v0.1.0 doesn't
  /// see those cards re-lock when v0.1.1 raises the bar. Once-unlocked-
  /// always-unlocked is the contract.
  Set<String> grandfatheredCards;

  /// Composite keys "packId:percent" for pack-completion milestones
  /// the player has already crossed and been rewarded for. Idempotent —
  /// a milestone fires exactly once per pack.
  Set<String> packMilestonesClaimed;

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
        hasRemoveAds: false,
        starterBundleClaimed: false,
        guaranteedRevealTokens: <Rarity, int>{},
        purchasedSkus: <String>{},
        cardBurstCounts: <String, int>{},
        cardsPurchased: <String>{},
        claimedAchievements: <String>{},
        grandfatheredCards: <String>{},
        packMilestonesClaimed: <String>{},
      );
}
