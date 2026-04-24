import '../../game/systems/arena_registry.dart';
import '../models/player_profile.dart';
import '../models/rarity.dart';
import '../persistence.dart';
import '../streak_calculator.dart';
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

  /// Increment session counter + advance the multi-day streak. Call at
  /// the start of each gameplay round, before the level_start analytics
  /// event fires. Returns a [SessionStartResult] describing any streak
  /// milestone the player just crossed (so the caller can fire a
  /// boost_granted event + show a toast).
  Future<SessionStartResult> noteSessionStart({DateTime? now}) async {
    profile.sessionCount += 1;
    final today = todayLocalIso(now ?? DateTime.now());
    final update = const StreakCalculator().compute(
      today: today,
      lastPlayDate: profile.lastPlayDate,
      currentStreak: profile.currentStreak,
    );
    profile.currentStreak = update.newStreak;
    if (update.newStreak > profile.longestStreak) {
      profile.longestStreak = update.newStreak;
    }
    profile.lastPlayDate = today;
    var boostGranted = false;
    if (update.milestoneReached) {
      profile.boostTokens += 1;
      boostGranted = true;
    }
    await _persistence.saveProfile(profile);
    return SessionStartResult(
      streak: update.newStreak,
      milestone: update.milestoneReached ? update.milestone : 0,
      boostTokenAwarded: boostGranted,
    );
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

  /// Record a burst for the pack-level progression system. Always
  /// bumps total-bursts-in-pack (drives unlock gates). Also advances
  /// the pity dry-streak counters for every tier, resetting the
  /// counter for the burst's tier or higher.
  ///
  /// Repeat bursts count — a player bursting the same rare three
  /// times clears the rare-pity streak three times over, and still
  /// adds three toward the epic unlock gate.
  Future<void> noteBurstForPack({
    required String packId,
    required Rarity rarity,
  }) async {
    profile.totalBurstsByPack[packId] =
        (profile.totalBurstsByPack[packId] ?? 0) + 1;

    final rareDry = profile.rareDryByPack[packId] ?? 0;
    final epicDry = profile.epicDryByPack[packId] ?? 0;
    final legendaryDry = profile.legendaryDryByPack[packId] ?? 0;

    profile.rareDryByPack[packId] =
        rarity.index >= Rarity.rare.index ? 0 : rareDry + 1;
    profile.epicDryByPack[packId] =
        rarity.index >= Rarity.epic.index ? 0 : epicDry + 1;
    profile.legendaryDryByPack[packId] =
        rarity == Rarity.mythic ? 0 : legendaryDry + 1;

    await _persistence.saveProfile(profile);
  }

  int totalBurstsInPack(String packId) =>
      profile.totalBurstsByPack[packId] ?? 0;

  int rareDryInPack(String packId) => profile.rareDryByPack[packId] ?? 0;

  int epicDryInPack(String packId) => profile.epicDryByPack[packId] ?? 0;

  int legendaryDryInPack(String packId) =>
      profile.legendaryDryByPack[packId] ?? 0;

  /// Consume one boost token. Returns true if a token was available
  /// (and the caller should apply the boost), false otherwise.
  Future<bool> consumeBoostToken() async {
    if (profile.boostTokens <= 0) return false;
    profile.boostTokens -= 1;
    await _persistence.saveProfile(profile);
    return true;
  }

  /// Grant a boost token from a named source — session-streak
  /// milestone, duplicate legendary, rewarded ad (later), etc.
  Future<void> grantBoostToken() async {
    profile.boostTokens += 1;
    await _persistence.saveProfile(profile);
  }
}

/// Reported back from [ProgressionRepository.noteSessionStart] so the
/// Flutter caller can show streak UX without re-reading the profile.
class SessionStartResult {
  const SessionStartResult({
    required this.streak,
    required this.milestone,
    required this.boostTokenAwarded,
  });

  final int streak;
  final int milestone; // 3, 7, 14, 30, or 0 if no milestone
  final bool boostTokenAwarded;
}
