import 'dart:math';

import '../../data/models/content_pack.dart';
import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';
import 'pack_progression_gate.dart';

/// Picks the next smashable from a filtered pool, applying per-pack
/// pity ramps + combo boost on top of each pack's configured tier
/// share odds.
///
/// Weight derivation for each pool entry:
///
///   base       = pack.baseOdds.shareFor(tier) / pack.countAtTier(tier)
///                (per-object share of the tier's probability mass)
///   soft_boost = linear ramp from 0 at soft-pity to +1.0 at hard-pity
///                using the pack's dry-streak counter for this tier
///   combo      = (combo_multiplier - 1) * comboBoostPerStep
///                (rare+ tiers only)
///   weight     = max(0, base * (1 + soft_boost + combo) * SCALE)
///
/// Hard-pity exclusion: when a pack's dry counter is >= hard-pity for
/// a tier, lower-tier objects in that same pack are weighted 0, forcing
/// the tier (unless its unlock gate is closed, which
/// [PackProgressionGate] handles upstream).
///
/// If every object in the pool ends up at weight 0, the selector falls
/// back to a uniform pick so spawns never stall.
class RarityPitySelector {
  const RarityPitySelector({this.comboBoostPerStep = 0.2});

  /// Boost added to rare+ object weights per step of combo above 1.
  /// At combo 8 (default cap) this yields a +1.4x multiplier.
  final double comboBoostPerStep;

  /// Pick the next object. [pool] should already have been filtered
  /// through [PackProgressionGate] for unlock gates.
  SmashableDef pick({
    required List<GatedObject> pool,
    required Map<String, int> rareDryByPack,
    required Map<String, int> epicDryByPack,
    required Map<String, int> legendaryDryByPack,
    int comboMultiplier = 1,
    Random? rng,
  }) {
    if (pool.isEmpty) {
      throw ArgumentError('RarityPitySelector.pick: pool is empty');
    }
    final rnd = rng ?? Random();
    final weights = <int>[];
    for (final entry in pool) {
      weights.add(_weightFor(
        entry,
        rareDry: rareDryByPack[entry.packId] ?? 0,
        epicDry: epicDryByPack[entry.packId] ?? 0,
        legendaryDry: legendaryDryByPack[entry.packId] ?? 0,
        comboMultiplier: comboMultiplier,
      ));
    }
    final total = weights.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      // Degenerate — every candidate was excluded or zeroed. Uniform
      // fallback so the game keeps spawning.
      return pool[rnd.nextInt(pool.length)].def;
    }
    var roll = rnd.nextInt(total);
    for (var i = 0; i < pool.length; i++) {
      roll -= weights[i];
      if (roll < 0) return pool[i].def;
    }
    return pool.last.def;
  }

  /// Advance per-pack dry counters after a pick. Increments every
  /// counter for the picked pack, then resets any counter whose tier
  /// was hit (or exceeded). Returns the new (rare, epic, legendary)
  /// values for that pack.
  (int rare, int epic, int legendary) advanceCountersForPack({
    required Rarity pickedRarity,
    required int rareDry,
    required int epicDry,
    required int legendaryDry,
  }) {
    final nextRare =
        pickedRarity.index >= Rarity.rare.index ? 0 : rareDry + 1;
    final nextEpic =
        pickedRarity.index >= Rarity.epic.index ? 0 : epicDry + 1;
    final nextLegendary =
        pickedRarity == Rarity.mythic ? 0 : legendaryDry + 1;
    return (nextRare, nextEpic, nextLegendary);
  }

  int _weightFor(
    GatedObject entry, {
    required int rareDry,
    required int epicDry,
    required int legendaryDry,
    required int comboMultiplier,
  }) {
    final def = entry.def;
    final pack = entry.pack;
    final pity = pack.progression.pity;

    // Hard-pity exclusion — force rarer tier by zeroing weaker ones.
    // Mythic/legendary hard pity beats epic which beats rare.
    if (legendaryDry >= pity.legendaryHard && def.rarity != Rarity.mythic) {
      return 0;
    }
    if (epicDry >= pity.epicHard && def.rarity.index < Rarity.epic.index) {
      return 0;
    }
    if (rareDry >= pity.rareHard && def.rarity == Rarity.common) {
      return 0;
    }

    // Per-object base share of the tier's probability mass.
    if (def.dropWeight != null) {
      // Author override — bypass derivation, use the literal weight.
      return _applyBoosts(
        baseScaled: def.dropWeight! * _boostScale,
        rarity: def.rarity,
        rareDry: rareDry,
        epicDry: epicDry,
        legendaryDry: legendaryDry,
        comboMultiplier: comboMultiplier,
        pity: pity,
      );
    }
    final tierCount = pack.countAtTier(def.rarity);
    if (tierCount == 0) return 0;
    final tierShare = pack.progression.baseOdds.shareFor(def.rarity);
    final base = tierShare / tierCount;  // fraction per object
    final baseScaled = (base * _weightScale).round();
    return _applyBoosts(
      baseScaled: baseScaled,
      rarity: def.rarity,
      rareDry: rareDry,
      epicDry: epicDry,
      legendaryDry: legendaryDry,
      comboMultiplier: comboMultiplier,
      pity: pity,
    );
  }

  int _applyBoosts({
    required int baseScaled,
    required Rarity rarity,
    required int rareDry,
    required int epicDry,
    required int legendaryDry,
    required int comboMultiplier,
    required PityThresholds pity,
  }) {
    if (rarity == Rarity.common) return baseScaled;
    final (soft, hard) = pity.forTier(rarity);
    final dry = switch (rarity) {
      Rarity.rare => rareDry,
      Rarity.epic => epicDry,
      Rarity.mythic => legendaryDry,
      Rarity.common => 0,
    };
    final softBoost = dry <= soft
        ? 0.0
        : ((dry - soft) / (hard - soft).clamp(1, 10000)).clamp(0.0, 1.0);
    final comboBoost =
        ((comboMultiplier - 1).clamp(0, 1000)) * comboBoostPerStep;
    final scaled = baseScaled * (1 + softBoost + comboBoost);
    return scaled.round();
  }
}

// Scale factors so per-object fractions round to meaningful ints.
const int _weightScale = 10000;
const int _boostScale = 1;
