import '../../data/models/content_pack.dart';
import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';

/// Per-pack acquisition gating — determines which rarity tiers are
/// eligible to spawn from a given pack based on the player's per-pack
/// burst history.
///
/// Semantics:
///   * Common and rare tiers are always unlocked (packs should feel
///     immediately rewarding).
///   * Epic is gated behind [PackProgression.epicUnlockRareBursts]
///     rare-or-better bursts in that pack.
///   * Legendary (the [Rarity.mythic] enum variant) is gated behind
///     [PackProgression.legendaryUnlockEpicBursts] epic bursts.
///
/// Packs with [PackProgression.isGated] == false skip gating entirely,
/// preserving back-compat with content authored before the rarity map.
class PackProgressionGate {
  const PackProgressionGate();

  /// Is [tier] eligible to spawn from [pack] given the player's
  /// per-pack burst counters?
  bool isTierUnlocked({
    required ContentPack pack,
    required Rarity tier,
    required int rareBurstsInPack,
    required int epicBurstsInPack,
  }) {
    final gating = pack.progression;
    if (!gating.isGated) return true;
    switch (tier) {
      case Rarity.common:
      case Rarity.rare:
        return true;
      case Rarity.epic:
        return rareBurstsInPack >= gating.epicUnlockRareBursts;
      case Rarity.mythic:
        return epicBurstsInPack >= gating.legendaryUnlockEpicBursts;
    }
  }

  /// Filter [objectsByPack] down to only objects whose tier is
  /// currently unlocked for their pack. Objects from ungated packs
  /// pass through unchanged.
  List<GatedObject> filterPool({
    required List<GatedObject> objectsByPack,
    required Map<String, int> rareBurstsByPack,
    required Map<String, int> epicBurstsByPack,
  }) {
    return objectsByPack.where((entry) {
      return isTierUnlocked(
        pack: entry.pack,
        tier: entry.def.rarity,
        rareBurstsInPack: rareBurstsByPack[entry.pack.packId] ?? 0,
        epicBurstsInPack: epicBurstsByPack[entry.pack.packId] ?? 0,
      );
    }).toList(growable: false);
  }
}

/// A [SmashableDef] paired with the pack it came from, so gating and
/// per-pack burst tracking can resolve pack context at spawn time
/// without snaking the ID through every layer.
class GatedObject {
  const GatedObject({required this.def, required this.pack});

  final SmashableDef def;
  final ContentPack pack;

  String get packId => pack.packId;
}
