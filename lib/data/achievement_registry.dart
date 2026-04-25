import 'models/achievement.dart';
import 'models/rarity.dart';

/// The starter set of 8 achievements shipped at launch. Hardcoded
/// rather than loaded from JSON because each achievement's criteria is
/// a Dart class — a JSON-driven schema would either constrain criteria
/// to a small DSL or require dynamic dispatch. Adding more achievements
/// later is just appending to this list.
///
/// Reward design rationale:
///   - Most achievements grant coins or guaranteed-reveal tokens so
///     they accelerate the existing economy + pity systems rather
///     than gating brand-new mechanics.
///   - One achievement (`first_mythic_ever`) grants a direct card
///     unlock as the example pattern for "achievements that unlock
///     cards." Picked the Creepy-Cute Legendary (card 048) since it's
///     thematically the splashiest in the collection — a fitting
///     trophy for the player's first Mythic moment.
const List<Achievement> starterAchievements = <Achievement>[
  Achievement(
    id: 'first_burst',
    name: 'First Squish',
    description: 'Burst your very first squishy.',
    criteria: FirstBurstCriteria(),
    reward: CoinReward(25),
  ),
  Achievement(
    id: 'streak_5',
    name: 'Five-Day Squisher',
    description: 'Play five days in a row.',
    criteria: StreakCriteria(5),
    reward: GuaranteedRevealReward(tier: Rarity.rare),
  ),
  Achievement(
    id: 'streak_7',
    name: 'Lucky Seven',
    description: 'Play seven days in a row.',
    criteria: StreakCriteria(7),
    reward: GuaranteedRevealReward(tier: Rarity.epic),
  ),
  Achievement(
    id: 'streak_14',
    name: 'Fortnight Fanatic',
    description: 'Play fourteen days in a row.',
    criteria: StreakCriteria(14),
    reward: GuaranteedRevealReward(tier: Rarity.mythic),
  ),
  Achievement(
    id: 'combo_15',
    name: 'Combo Champion',
    description: 'Hit a 15+ combo in a single round.',
    criteria: BestComboCriteria(15),
    reward: CoinReward(100),
  ),
  Achievement(
    id: 'score_1000',
    name: 'Four-Digit Squisher',
    description: 'Score 1,000 or more in a single round.',
    criteria: BestScoreCriteria(1000),
    reward: CoinReward(75),
  ),
  Achievement(
    id: 'total_bursts_100',
    name: 'Century Squisher',
    description: 'Burst 100 squishies across all your rounds.',
    criteria: TotalBurstsCriteria(100),
    reward: CoinReward(200),
  ),
  Achievement(
    id: 'first_mythic_ever',
    name: 'Legendary Discovery',
    description: 'Burst your first Legendary squishy.',
    criteria: FirstMythicEverCriteria(),
    // Direct card unlock — your first Legendary discovery earns the
    // Mythic Plush Familiar (card 048) as a trophy.
    reward: CardUnlockReward('048/048'),
  ),
];
