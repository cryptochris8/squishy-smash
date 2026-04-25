import '../../game/systems/arena_registry.dart';
import '../card_unlock.dart';
import '../models/achievement.dart';
import '../models/card_entry.dart';
import '../models/economy_config.dart';
import '../models/player_profile.dart';
import '../models/rarity.dart';
import '../pack_milestones.dart';
import '../persistence.dart';
import '../streak_calculator.dart';
import 'pack_repository.dart';

class ProgressionRepository {
  ProgressionRepository(
    this._persistence,
    this._packs, {
    EconomyConfig? economy,
  })  : _economy = economy ?? const EconomyConfig(),
        profile = _persistence.loadProfile();

  final Persistence _persistence;
  final PackRepository _packs;
  final EconomyConfig _economy;
  PlayerProfile profile;

  /// Read-only accessor so callers can pull the same config the repo
  /// itself uses (e.g., the album UI's price display + unlock checks).
  EconomyConfig get economy => _economy;

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

  /// Flush any buffered profile writes from the debounced hot path
  /// (awardCoins, noteBurstForPack, markDiscovered). Call at
  /// round-end or on app backgrounding to guarantee in-memory state
  /// is on disk before the caller proceeds.
  Future<void> flushPending() => _persistence.flushPending();

  Future<void> awardCoins(int n) async {
    profile.coins += n;
    _persistence.scheduleSave(profile);
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
      _persistence.scheduleSave(profile);
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
  ///
  /// Contract: the in-memory `profile` map mutations below are the
  /// source of truth the pity selector reads from — they happen
  /// synchronously and the persist step is a debounced schedule, not
  /// an awaited write. `SquishyGame` relies on this so the very next
  /// `_selectNextSmashable` call sees the updated dry-streak counters
  /// without waiting for disk I/O. Call `flushPending` at round end
  /// to guarantee the batched write has landed.
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

    _persistence.scheduleSave(profile);
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
  Future<void> grantBoostToken({int count = 1}) async {
    profile.boostTokens += count;
    await _persistence.saveProfile(profile);
  }

  // -- Monetization entitlements -------------------------------------

  /// Set the remove-ads flag. Idempotent — calling twice doesn't
  /// double-charge or double-grant anything.
  Future<void> setRemoveAds(bool value) async {
    if (profile.hasRemoveAds == value) return;
    profile.hasRemoveAds = value;
    await _persistence.saveProfile(profile);
  }

  Future<void> markSkuPurchased(String sku) async {
    profile.purchasedSkus.add(sku);
    await _persistence.saveProfile(profile);
  }

  bool get hasAnyPurchase => profile.purchasedSkus.isNotEmpty;

  /// Queue N forced-tier reveal tokens. The pity selector consumes one
  /// from the map on next spawn, forcing an object of that tier
  /// regardless of normal weighting.
  Future<void> grantGuaranteedReveal(Rarity rarity, {int count = 1}) async {
    profile.guaranteedRevealTokens[rarity] =
        (profile.guaranteedRevealTokens[rarity] ?? 0) + count;
    await _persistence.saveProfile(profile);
  }

  /// Pop one token from the guaranteedRevealTokens queue. Returns the
  /// rarity that should be forced on the next spawn, or null if the
  /// queue is empty. Prefers rarer tiers when multiple are queued so
  /// the player feels the "save this for something special" effect.
  Future<Rarity?> consumeGuaranteedReveal() async {
    for (final r in [Rarity.mythic, Rarity.epic, Rarity.rare]) {
      final count = profile.guaranteedRevealTokens[r] ?? 0;
      if (count > 0) {
        profile.guaranteedRevealTokens[r] = count - 1;
        if (profile.guaranteedRevealTokens[r] == 0) {
          profile.guaranteedRevealTokens.remove(r);
        }
        await _persistence.saveProfile(profile);
        return r;
      }
    }
    return null;
  }

  int guaranteedRevealsOf(Rarity rarity) =>
      profile.guaranteedRevealTokens[rarity] ?? 0;

  /// Mark the Starter Bundle as claimed. Prevents the paywall from
  /// re-triggering on future sessions.
  Future<void> markStarterBundleClaimed() async {
    profile.starterBundleClaimed = true;
    await _persistence.saveProfile(profile);
  }

  // -- Card collection (3-path unlock system) -----------------------

  /// Bump the per-card burst counter for [cardNumber]. Cheap path —
  /// debounced through the same scheduleSave mechanism as other hot-path
  /// mutations. Returns the new count so callers can detect the
  /// just-crossed-threshold moment for one-shot UI/analytics.
  int incrementBurstForCard(String cardNumber) {
    final next = (profile.cardBurstCounts[cardNumber] ?? 0) + 1;
    profile.cardBurstCounts[cardNumber] = next;
    _persistence.scheduleSave(profile);
    return next;
  }

  int cardBurstCount(String cardNumber) =>
      profile.cardBurstCounts[cardNumber] ?? 0;

  /// Direct coin purchase of a card. Returns true if the purchase
  /// landed (sufficient coins + not already purchased), false otherwise.
  /// Idempotent — a second call after a successful purchase is a no-op
  /// that returns false (no double-charge).
  Future<bool> tryPurchaseCard({
    required String cardNumber,
    required int costCoins,
  }) async {
    if (profile.cardsPurchased.contains(cardNumber)) return false;
    if (profile.coins < costCoins) return false;
    profile.coins -= costCoins;
    profile.cardsPurchased.add(cardNumber);
    await _persistence.saveProfile(profile);
    return true;
  }

  bool isCardPurchased(String cardNumber) =>
      profile.cardsPurchased.contains(cardNumber);

  /// Convenience: purchase [card] at the canonical rarity-tuned price
  /// from [CardCoinPrice]. Reads the price through this repo's
  /// [EconomyConfig] so a JSON tweak is the single source of truth.
  Future<bool> tryPurchaseCardAtRarityPrice(CardEntry card) =>
      tryPurchaseCard(
        cardNumber: card.cardNumber,
        costCoins: CardCoinPrice.coinsFor(card.rarity, config: _economy),
      );

  /// Mark an achievement as claimed. Idempotent. Caller is responsible
  /// for awarding the actual reward (coins / token / card unlock) — this
  /// method only persists the "this player has claimed it" bit.
  Future<bool> claimAchievement(String achievementId) async {
    final added = profile.claimedAchievements.add(achievementId);
    if (added) await _persistence.saveProfile(profile);
    return added;
  }

  bool hasClaimedAchievement(String achievementId) =>
      profile.claimedAchievements.contains(achievementId);

  /// Atomically claim a pack milestone + award its coins. Idempotent —
  /// a milestone can fire only once per pack across the lifetime of
  /// the profile. Returns true if the claim landed (newly crossed),
  /// false if the player had already claimed this milestone.
  bool awardPackMilestone({
    required String packId,
    required PackMilestone milestone,
  }) {
    final key = packMilestoneClaimKey(
      packId: packId,
      percent: milestone.percent,
    );
    if (!profile.packMilestonesClaimed.add(key)) return false;
    profile.coins += milestone.coinReward;
    _persistence.scheduleSave(profile);
    return true;
  }

  /// Atomic claim + reward. Returns the reward that was applied, or
  /// null if the achievement was already claimed (idempotent — no
  /// double-grant). Each reward variant routes to the matching repo
  /// method so coin/token/card paths stay in one place.
  ///
  /// Note: `CardUnlockReward` doesn't trigger a separate write because
  /// the unlock derives from the claim itself — see
  /// `unlockedCardNumbersFromAchievements` in achievement.dart.
  Future<AchievementReward?> grantAchievement(
      Achievement achievement) async {
    final added = profile.claimedAchievements.add(achievement.id);
    if (!added) return null;
    final reward = achievement.reward;
    switch (reward) {
      case CoinReward r:
        profile.coins += r.coins;
      case GuaranteedRevealReward r:
        profile.guaranteedRevealTokens[r.tier] =
            (profile.guaranteedRevealTokens[r.tier] ?? 0) + r.count;
      case CardUnlockReward _:
        // No additional state change — the card unlock is derived
        // from the claimed achievement set on demand. The claim itself
        // is the receipt.
        break;
    }
    await _persistence.saveProfile(profile);
    return reward;
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
