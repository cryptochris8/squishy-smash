import 'models/achievement.dart';
import 'models/player_profile.dart';

/// Pure scanner: given a list of achievements + the current player
/// profile, returns the achievements whose criteria are satisfied AND
/// the player has not yet claimed. Caller is responsible for calling
/// `ProgressionRepository.grantAchievement` on each returned entry to
/// apply the reward.
///
/// Side-effect free, deterministic, cheap to call. Run after any event
/// that could move state across a threshold: round end, mythic burst,
/// streak update, card-burst increment.
class AchievementDetector {
  const AchievementDetector();

  List<Achievement> detectEligible({
    required Iterable<Achievement> achievements,
    required PlayerProfile profile,
  }) {
    final claimed = profile.claimedAchievements;
    return [
      for (final a in achievements)
        if (!claimed.contains(a.id) && a.criteria.isMetBy(profile)) a,
    ];
  }
}
