import '../../data/models/content_pack.dart';
import '../../data/models/rarity.dart';
import '../../data/models/smashable_def.dart';

/// Per-pack acquisition gating — determines which rarity tiers are
/// eligible to spawn based on how many total bursts the player has
/// accumulated in a pack. Semantics follow the tuning-doc:
///
///   * Common — always unlocked.
///   * Rare — unlocked after [UnlockGates.rare] total bursts in the pack.
///   * Epic — unlocked after [UnlockGates.epic] total bursts in the pack.
///   * Legendary ([Rarity.mythic] enum) — unlocked after
///     [UnlockGates.legendary] total bursts in the pack.
///
/// Repeated bursts of the same object still count toward unlocks so
/// small pools of low-tier objects naturally gate top-tier drops.
class PackProgressionGate {
  const PackProgressionGate();

  /// Is [tier] eligible to spawn from [pack] given the player's total
  /// burst count in that pack?
  bool isTierUnlocked({
    required ContentPack pack,
    required Rarity tier,
    required int totalBurstsInPack,
  }) {
    return totalBurstsInPack >= pack.progression.unlockGates.gateFor(tier);
  }

  /// Filter [objectsByPack] down to the objects whose tier is currently
  /// unlocked in their owning pack.
  List<GatedObject> filterPool({
    required List<GatedObject> objectsByPack,
    required Map<String, int> totalBurstsByPack,
  }) {
    return objectsByPack.where((entry) {
      return isTierUnlocked(
        pack: entry.pack,
        tier: entry.def.rarity,
        totalBurstsInPack: totalBurstsByPack[entry.pack.packId] ?? 0,
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
