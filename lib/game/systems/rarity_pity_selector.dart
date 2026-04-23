import 'dart:math';

import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';

/// Picks the next smashable from a pool, factoring in two overlays on
/// top of each object's base drop weight:
///
///   * **Pity** — per-tier counters of rolls since the player last saw
///     that tier. Past a soft threshold the tier's weight ramps up; past
///     a hard threshold it's forced (all weaker tiers are excluded).
///   * **Combo reveal boost** — sustained combo multiplier scales
///     rare-and-better weights up so in-the-zone players see more
///     reveal moments.
///
/// Pure logic — no global state, no I/O. The caller owns the pity
/// counters on `PlayerProfile` and advances them via [advanceCounters]
/// after each pick.
class RarityPitySelector {
  const RarityPitySelector({
    this.rareSoftPity = 15,
    this.rareHardPity = 30,
    this.epicSoftPity = 80,
    this.epicHardPity = 200,
    this.mythicSoftPity = 500,
    this.mythicHardPity = 1000,
    this.comboBoostPerStep = 0.2,
  });

  /// Rolls without a rare+ before rare weights begin ramping.
  final int rareSoftPity;

  /// Rolls without a rare+ after which commons are excluded entirely.
  final int rareHardPity;

  final int epicSoftPity;
  final int epicHardPity;

  final int mythicSoftPity;
  final int mythicHardPity;

  /// Added to rare+ weight multiplier per step of combo above 1.
  /// Default 0.2 means combo 8 gives +1.4× on top of the base weight.
  final double comboBoostPerStep;

  /// Pick the next smashable from [pool], factoring in pity counters
  /// and combo boost. [comboMultiplier] should match
  /// `ComboController.multiplier` (1..N).
  ///
  /// Throws [ArgumentError] if [pool] is empty.
  SmashableDef pick({
    required List<SmashableDef> pool,
    required int rollsSinceRare,
    required int rollsSinceEpic,
    required int rollsSinceMythic,
    int comboMultiplier = 1,
    Random? rng,
  }) {
    if (pool.isEmpty) {
      throw ArgumentError('RarityPitySelector.pick: pool is empty');
    }
    return weightedPick<SmashableDef>(
      items: pool,
      weightOf: (d) => _effectiveWeight(
        d,
        rollsSinceRare: rollsSinceRare,
        rollsSinceEpic: rollsSinceEpic,
        rollsSinceMythic: rollsSinceMythic,
        comboMultiplier: comboMultiplier,
      ),
      rng: rng,
    );
  }

  /// Returns the new (rollsSinceRare, rollsSinceEpic, rollsSinceMythic)
  /// after a pick of [pickedRarity]. Every pick increments every
  /// counter, and each counter is reset when its tier (or higher) is
  /// hit — so a mythic resets all three, a rare resets only rare.
  (int, int, int) advanceCounters({
    required Rarity pickedRarity,
    required int rollsSinceRare,
    required int rollsSinceEpic,
    required int rollsSinceMythic,
  }) {
    final nextRare =
        pickedRarity.index >= Rarity.rare.index ? 0 : rollsSinceRare + 1;
    final nextEpic =
        pickedRarity.index >= Rarity.epic.index ? 0 : rollsSinceEpic + 1;
    final nextMythic =
        pickedRarity == Rarity.mythic ? 0 : rollsSinceMythic + 1;
    return (nextRare, nextEpic, nextMythic);
  }

  int _effectiveWeight(
    SmashableDef def, {
    required int rollsSinceRare,
    required int rollsSinceEpic,
    required int rollsSinceMythic,
    required int comboMultiplier,
  }) {
    final base = def.effectiveDropWeight;

    // Hard-pity exclusions: bar all tiers weaker than whatever the
    // pity has promised. Mythic hard-pity beats epic hard-pity which
    // beats rare hard-pity.
    if (rollsSinceMythic >= mythicHardPity && def.rarity != Rarity.mythic) {
      return 0;
    }
    if (rollsSinceEpic >= epicHardPity &&
        def.rarity.index < Rarity.epic.index) {
      return 0;
    }
    if (rollsSinceRare >= rareHardPity && def.rarity == Rarity.common) {
      return 0;
    }

    if (def.rarity == Rarity.common) return base;

    final (soft, hard, count) = switch (def.rarity) {
      Rarity.rare => (rareSoftPity, rareHardPity, rollsSinceRare),
      Rarity.epic => (epicSoftPity, epicHardPity, rollsSinceEpic),
      Rarity.mythic => (mythicSoftPity, mythicHardPity, rollsSinceMythic),
      Rarity.common => (0, 1, 0),
    };

    final softBoost = count <= soft
        ? 0.0
        : 2.0 * ((count - soft) / (hard - soft)).clamp(0.0, 1.0);
    final comboBoost =
        ((comboMultiplier - 1).clamp(0, 1000)) * comboBoostPerStep;

    final scaled = base * (1 + softBoost + comboBoost);
    return scaled.round();
  }
}
