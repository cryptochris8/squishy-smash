import 'player_profile.dart';
import 'rarity.dart';

/// A criterion the player can satisfy to make an achievement eligible
/// to claim. Pure: `isMetBy(profile)` derives eligibility entirely from
/// already-persisted state, so the detector can run any time.
sealed class AchievementCriteria {
  const AchievementCriteria();
  bool isMetBy(PlayerProfile profile);
}

/// "Burst your first squishy." Eligible once `discoveredSmashableIds`
/// is non-empty.
class FirstBurstCriteria extends AchievementCriteria {
  const FirstBurstCriteria();
  @override
  bool isMetBy(PlayerProfile p) => p.discoveredSmashableIds.isNotEmpty;
}

/// "Reach a streak of N consecutive days." Uses `longestStreak` so
/// players who hit the threshold then miss a day still keep the
/// achievement eligible.
class StreakCriteria extends AchievementCriteria {
  const StreakCriteria(this.days) : assert(days > 0);
  final int days;
  @override
  bool isMetBy(PlayerProfile p) => p.longestStreak >= days;
}

/// "Hit a combo of N or higher in one round." Uses `bestCombo`
/// (lifetime peak) so the trophy isn't lost on the next round's reset.
class BestComboCriteria extends AchievementCriteria {
  const BestComboCriteria(this.combo) : assert(combo > 0);
  final int combo;
  @override
  bool isMetBy(PlayerProfile p) => p.bestCombo >= combo;
}

/// "Score N or more in a single round." Uses lifetime `bestScore`.
class BestScoreCriteria extends AchievementCriteria {
  const BestScoreCriteria(this.score) : assert(score > 0);
  final int score;
  @override
  bool isMetBy(PlayerProfile p) => p.bestScore >= score;
}

/// "Burst N squishies across all packs and rounds." Sums the per-pack
/// burst counter for a lifetime total.
class TotalBurstsCriteria extends AchievementCriteria {
  const TotalBurstsCriteria(this.total) : assert(total > 0);
  final int total;
  @override
  bool isMetBy(PlayerProfile p) =>
      p.totalBurstsByPack.values.fold<int>(0, (a, b) => a + b) >= total;
}

/// "Discover your first Mythic-tier squishy."
class FirstMythicEverCriteria extends AchievementCriteria {
  const FirstMythicEverCriteria();
  @override
  bool isMetBy(PlayerProfile p) => p.rarestSeen.index >= Rarity.mythic.index;
}

// ---------------------------------------------------------------- rewards

/// What the player receives when an achievement is claimed. Different
/// reward shapes pull on different repository methods (coin grant,
/// guaranteed-reveal token, direct card unlock), so the dispatcher in
/// ProgressionRepository switches on the runtime type.
sealed class AchievementReward {
  const AchievementReward();
}

class CoinReward extends AchievementReward {
  const CoinReward(this.coins) : assert(coins > 0);
  final int coins;
}

class GuaranteedRevealReward extends AchievementReward {
  const GuaranteedRevealReward({required this.tier, this.count = 1})
      : assert(count > 0);
  final Rarity tier;
  final int count;
}

/// Direct card unlock. Side-effect-free — the card-number is recorded
/// indirectly: the achievement claim is the receipt, and
/// `unlockedCardNumbersFromAchievements` derives the unlock set on
/// demand by walking claimed achievements with this reward type.
class CardUnlockReward extends AchievementReward {
  const CardUnlockReward(this.cardNumber);
  final String cardNumber;
}

// ---------------------------------------------------------------- entry

class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    required this.reward,
  });

  final String id;
  final String name;
  final String description;
  final AchievementCriteria criteria;
  final AchievementReward reward;
}

/// Walk all [achievements] and return the card_numbers that are
/// unlocked because the player has claimed an achievement carrying a
/// `CardUnlockReward`. Pure derivation — no persistence needed beyond
/// the existing `claimedAchievements` set.
Set<String> unlockedCardNumbersFromAchievements({
  required Iterable<Achievement> achievements,
  required Set<String> claimedIds,
}) {
  final out = <String>{};
  for (final a in achievements) {
    if (!claimedIds.contains(a.id)) continue;
    final r = a.reward;
    if (r is CardUnlockReward) out.add(r.cardNumber);
  }
  return out;
}
