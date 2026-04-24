import '../analytics/events.dart';
import '../data/repositories/progression_repo.dart';
import 'rewarded_ad_service.dart';

/// Orchestrates the full rewarded-ad offer flow end-to-end:
///
///   UI surfaces the offer -> offerShown() [analytics fires]
///   Player accepts       -> showAd() [analytics fires, SDK spins up]
///   Player declines      -> offerDeclined() [analytics fires]
///   Ad completes         -> grant applied + analytics fires
///
/// Centralising this means the gameplay / shop / collection surfaces
/// all use the same funnel without copying boilerplate.
class AdOfferController {
  AdOfferController({
    required this.ads,
    required this.progression,
    required this.events,
  });

  final RewardedAdService ads;
  final ProgressionRepository progression;
  final GameEvents events;

  /// Fire when the offer surface is shown to the player but they
  /// haven't taken any action yet. [sessionNumber] is typically
  /// profile.sessionCount at the moment of the offer.
  void offerShown(String placement, {required int sessionNumber}) {
    events.adRewardOfferShown(
      placement: placement,
      sessionNumber: sessionNumber,
    );
  }

  /// Fire when the player explicitly dismisses the offer without
  /// watching.
  void offerDeclined(String placement, {required int sessionNumber}) {
    events.adRewardOfferDeclined(
      placement: placement,
      sessionNumber: sessionNumber,
    );
  }

  /// Run the full "accept offer -> show ad -> apply reward" flow.
  /// Returns true if the ad played and the reward was granted.
  Future<bool> watchForReward(
    String placement, {
    required AdReward reward,
    required int sessionNumber,
  }) async {
    events.adRewardOfferAccepted(
      placement: placement,
      sessionNumber: sessionNumber,
    );
    final ready = await ads.isReady(placement);
    if (!ready) return false;
    final result = await ads.show(placement);
    if (!result.didReward) return false;
    await _applyReward(reward);
    events.rewardedAdCompleted(
      placement: placement,
      rewardType: _rewardTypeToken(reward.type),
      amount: reward.amount,
    );
    return true;
  }

  Future<void> _applyReward(AdReward reward) async {
    switch (reward.type) {
      case AdRewardType.boostToken:
        await progression.grantBoostToken(count: reward.amount);
        break;
      case AdRewardType.coins:
        await progression.awardCoins(reward.amount);
        break;
      case AdRewardType.pityStep:
        // Pity step is handled by advancing the appropriate dry
        // counter — for now we bump the shared boost token since
        // the pity selector already consumes boost tokens to bias
        // rare+. A full implementation can tune per-tier later.
        await progression.grantBoostToken(count: reward.amount);
        break;
    }
  }

  String _rewardTypeToken(AdRewardType t) {
    switch (t) {
      case AdRewardType.boostToken:
        return 'boost_token';
      case AdRewardType.coins:
        return 'coins';
      case AdRewardType.pityStep:
        return 'pity_step';
    }
  }
}
