import 'rarity.dart';

/// Coin reward when a pack hits a given discovered-percentage tier.
class PackMilestone {
  const PackMilestone({required this.percent, required this.coinReward})
      : assert(percent > 0 && percent <= 100),
        assert(coinReward >= 0);

  final int percent;
  final int coinReward;

  factory PackMilestone.fromJson(Map<String, dynamic> json) => PackMilestone(
        percent: (json['percent'] as num).toInt(),
        coinReward: (json['coinReward'] as num).toInt(),
      );
}

/// Single source of truth for all tunable economy values. Loaded from
/// `assets/data/economy.json` at boot via `EconomyConfigLoader`.
///
/// **Why JSON instead of Dart constants?** A balance change becomes a
/// single-file edit — no Dart compile, no risk of accidentally
/// reverting unrelated commits when rolling back. The "kill switch"
/// for any rebalance is editing one file and shipping a new build.
///
/// Every field has a hardcoded default so a missing or malformed JSON
/// loads as the launch baseline rather than crashing the app. The
/// values match what shipped in v0.1.0 — keep them in sync if the
/// "factory default" experience changes.
class EconomyConfig {
  const EconomyConfig({
    this.burstThresholds = const RarityTunable<int>(
      common: 1,
      rare: 3,
      epic: 7,
      legendary: 15,
    ),
    this.coinPrices = const RarityTunable<int>(
      common: 50,
      rare: 200,
      epic: 750,
      legendary: 2500,
    ),
    this.duplicateCoinBonus = const RarityTunable<int>(
      common: 2,
      rare: 10,
      epic: 25,
      legendary: 50,
    ),
    this.antiSpamCooldownMs = 0,
    this.packMilestones = const <PackMilestone>[],
  });

  final RarityTunable<int> burstThresholds;
  final RarityTunable<int> coinPrices;
  final RarityTunable<int> duplicateCoinBonus;

  /// Per-smashable cooldown in milliseconds. Bursts on the same id
  /// within this window play full ASMR feedback but grant zero coins
  /// and zero card-burst progress. Silent throttle, never visible to
  /// the player. 0 disables anti-spam entirely.
  final int antiSpamCooldownMs;

  /// Pack completion percentages that fire one-shot coin rewards.
  /// Empty list disables milestones.
  final List<PackMilestone> packMilestones;

  // -- Convenience accessors ---------------------------------------

  int requiredBurstsFor(Rarity r) => burstThresholds.forRarity(r);
  int coinPriceFor(Rarity r) => coinPrices.forRarity(r);
  int duplicateCoinBonusFor(Rarity r) => duplicateCoinBonus.forRarity(r);

  // -- JSON ---------------------------------------------------------

  /// Defensive parser. A field missing or malformed falls back to
  /// the const default, never throws — losing one tunable shouldn't
  /// take down boot.
  factory EconomyConfig.fromJson(Map<String, dynamic> json) {
    return EconomyConfig(
      burstThresholds: RarityTunable<int>.fromJson(
        json['burstThresholds'] as Map<String, dynamic>?,
        fallback: const RarityTunable<int>(
          common: 1, rare: 3, epic: 7, legendary: 15,
        ),
      ),
      coinPrices: RarityTunable<int>.fromJson(
        json['coinPrices'] as Map<String, dynamic>?,
        fallback: const RarityTunable<int>(
          common: 50, rare: 200, epic: 750, legendary: 2500,
        ),
      ),
      duplicateCoinBonus: RarityTunable<int>.fromJson(
        json['duplicateCoinBonus'] as Map<String, dynamic>?,
        fallback: const RarityTunable<int>(
          common: 2, rare: 10, epic: 25, legendary: 50,
        ),
      ),
      antiSpamCooldownMs: ((json['antiSpamCooldownMs']
                  as Map<String, dynamic>?)?['value'] as num?)
              ?.toInt() ??
          0,
      packMilestones: (((json['packMilestones']
                  as Map<String, dynamic>?)?['thresholds'] as List?) ??
              const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(PackMilestone.fromJson)
          .toList(growable: false),
    );
  }
}

/// Tier-keyed value used by burst thresholds, prices, and dupe bonuses.
/// JSON uses the player-facing key `"legendary"` (with `"mythic"`
/// accepted as an alias to match `rarityFromToken`'s contract).
class RarityTunable<T extends num> {
  const RarityTunable({
    required this.common,
    required this.rare,
    required this.epic,
    required this.legendary,
  });

  final T common;
  final T rare;
  final T epic;
  final T legendary;

  T forRarity(Rarity r) {
    switch (r) {
      case Rarity.common:
        return common;
      case Rarity.rare:
        return rare;
      case Rarity.epic:
        return epic;
      case Rarity.mythic:
        return legendary;
    }
  }

  factory RarityTunable.fromJson(
    Map<String, dynamic>? json, {
    required RarityTunable<T> fallback,
  }) {
    if (json == null) return fallback;
    T pick(String key, T fallbackValue) {
      final raw = json[key];
      if (raw is num) return raw as T;
      return fallbackValue;
    }

    // Top-tier alias: prefer `legendary`, fall back to `mythic`,
    // then to the const default.
    final topRaw = json['legendary'] ?? json['mythic'];
    final topTier = topRaw is num ? topRaw as T : fallback.legendary;

    return RarityTunable<T>(
      common: pick('common', fallback.common),
      rare: pick('rare', fallback.rare),
      epic: pick('epic', fallback.epic),
      legendary: topTier,
    );
  }
}
