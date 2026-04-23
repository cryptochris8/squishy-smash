import '../../game/systems/arena_registry.dart';
import '../models/player_profile.dart';
import '../models/rarity.dart';
import '../persistence.dart';
import 'pack_repository.dart';

class ProgressionRepository {
  ProgressionRepository(this._persistence, this._packs)
      : profile = _persistence.loadProfile();

  final Persistence _persistence;
  final PackRepository _packs;
  PlayerProfile profile;

  bool isUnlocked(String packId) => profile.unlockedPackIds.contains(packId);

  bool isArenaUnlocked(String arenaKey) =>
      profile.unlockedArenaKeys.contains(arenaKey);

  Future<bool> tryUnlock(String packId) async {
    final pack = _packs.byId(packId);
    if (pack == null || isUnlocked(packId)) return false;
    if (profile.coins < pack.unlockCost) return false;
    profile.coins -= pack.unlockCost;
    profile.unlockedPackIds.add(packId);
    // Auto-grant the arena bundled with this pack so the player walks
    // straight into the new backdrop after purchase. No extra coin cost.
    for (final theme in ArenaRegistry.all) {
      if (theme.bundledWithPack == packId) {
        profile.unlockedArenaKeys.add(theme.key);
      }
    }
    await _persistence.saveProfile(profile);
    return true;
  }

  /// Unlock a standalone arena SKU (one that isn't bundled with a
  /// pack). Returns false if the arena doesn't exist, is already
  /// unlocked, or the player can't afford it. Pack-bundled arenas are
  /// not purchasable here — they come free with their pack.
  Future<bool> tryUnlockArena(String arenaKey) async {
    if (!ArenaRegistry.isKnown(arenaKey)) return false;
    if (isArenaUnlocked(arenaKey)) return false;
    final theme = ArenaRegistry.byKey(arenaKey);
    if (!theme.isStandalone) return false;
    if (profile.coins < theme.cost) return false;
    profile.coins -= theme.cost;
    profile.unlockedArenaKeys.add(arenaKey);
    await _persistence.saveProfile(profile);
    return true;
  }

  /// Set the arena rendered behind gameplay. Returns false (no-op) if
  /// the player doesn't own the arena yet.
  Future<bool> setActiveArena(String arenaKey) async {
    if (!isArenaUnlocked(arenaKey)) return false;
    if (profile.activeArenaKey == arenaKey) return true;
    profile.activeArenaKey = arenaKey;
    await _persistence.saveProfile(profile);
    return true;
  }

  Future<void> awardCoins(int n) async {
    profile.coins += n;
    await _persistence.saveProfile(profile);
  }

  Future<void> recordRound({required int score, required int combo}) async {
    var dirty = false;
    if (score > profile.bestScore) {
      profile.bestScore = score;
      dirty = true;
    }
    if (combo > profile.bestCombo) {
      profile.bestCombo = combo;
      dirty = true;
    }
    if (dirty) await _persistence.saveProfile(profile);
  }

  /// Increment and persist [PlayerProfile.sessionCount]. Call at the
  /// start of each gameplay round, before the level_start analytics
  /// event fires, so `session_index` matches what the round logs.
  Future<void> noteSessionStart() async {
    profile.sessionCount += 1;
    await _persistence.saveProfile(profile);
  }

  /// Persist the advanced pity counters after a spawn roll. The
  /// selector is pure; this method just writes back the new values.
  Future<void> noteSpawnRoll({
    required int rollsSinceRare,
    required int rollsSinceEpic,
    required int rollsSinceMythic,
  }) async {
    profile.rollsSinceRare = rollsSinceRare;
    profile.rollsSinceEpic = rollsSinceEpic;
    profile.rollsSinceMythic = rollsSinceMythic;
    await _persistence.saveProfile(profile);
  }

  /// Mark a smashable as discovered the first time the player bursts
  /// it. Returns true if this was a new discovery (so callers can fire
  /// a one-shot VFX/analytics event), false if it was already known.
  /// Also advances [PlayerProfile.rarestSeen] monotonically.
  Future<bool> markDiscovered({
    required String smashableId,
    required Rarity rarity,
  }) async {
    final added = profile.discoveredSmashableIds.add(smashableId);
    var bumpedRarest = false;
    if (rarity.index > profile.rarestSeen.index) {
      profile.rarestSeen = rarity;
      bumpedRarest = true;
    }
    if (added || bumpedRarest) {
      await _persistence.saveProfile(profile);
    }
    return added;
  }

  /// Record a burst for pack-level acquisition gating. Bumps the
  /// rare-bursts counter when [rarity] is rare+ and the epic-bursts
  /// counter when it's epic+. Callers should invoke this on every
  /// rare+ burst regardless of whether the object was newly
  /// discovered — repeat bursts count toward unlock thresholds.
  Future<void> noteBurstForPack({
    required String packId,
    required Rarity rarity,
  }) async {
    if (rarity.index < Rarity.rare.index) return;
    profile.rareBurstsByPack[packId] =
        (profile.rareBurstsByPack[packId] ?? 0) + 1;
    if (rarity.index >= Rarity.epic.index) {
      profile.epicBurstsByPack[packId] =
          (profile.epicBurstsByPack[packId] ?? 0) + 1;
    }
    await _persistence.saveProfile(profile);
  }

  int rareBurstsInPack(String packId) =>
      profile.rareBurstsByPack[packId] ?? 0;

  int epicBurstsInPack(String packId) =>
      profile.epicBurstsByPack[packId] ?? 0;
}
