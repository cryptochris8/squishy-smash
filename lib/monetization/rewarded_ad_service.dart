/// Placement IDs for rewarded ad offers. These are internal tags the
/// analytics funnel keys off; a production ad SDK adapter would map
/// each placement to its own ad unit ID.
abstract final class AdPlacement {
  /// Offered at end-of-round: "watch a short ad, get +1 boost token."
  static const String roundEndBoost = 'round_end_boost';

  /// Offered inside the Shop next to the Remove Ads CTA — "prefer free
  /// boosts? watch an ad for a one-shot reveal boost."
  static const String shopOffer = 'shop_offer';

  /// Offered on the Collection screen: "watch for pity meter nudge
  /// toward your rarest missing tier."
  static const String pityNudge = 'pity_nudge';

  static const List<String> all = [roundEndBoost, shopOffer, pityNudge];
}

/// What the player gets for watching a rewarded ad. Kept separate from
/// the IAP ProductReward so analytics can key off "ad_reward_type"
/// without confusion.
enum AdRewardType { boostToken, coins, pityStep }

class AdReward {
  const AdReward({required this.type, required this.amount});
  final AdRewardType type;
  final int amount;
}

/// Outcome of a rewarded ad show attempt.
enum AdOutcome {
  /// Ad played to completion — reward is due.
  completed,

  /// User dismissed before the reward threshold. No reward.
  dismissedEarly,

  /// Inventory or network issue — no ad shown, no reward.
  unavailable,

  /// Declined at the offer dialog (never kicked off loading).
  declined,
}

class AdResult {
  const AdResult({required this.outcome, this.errorMessage});
  final AdOutcome outcome;
  final String? errorMessage;
  bool get didReward => outcome == AdOutcome.completed;
}

/// Rewarded ad gateway. Real implementations (AdMob, AppLovin, Unity
/// LevelPlay) will wrap their SDKs with this interface; the stub is
/// used by tests and by builds before the SDK is wired up, so the
/// offer UX can be exercised without burning real impressions.
abstract class RewardedAdService {
  /// Ask the SDK whether a rewarded ad for [placement] is cached and
  /// ready to show. If false, the offer UI should be suppressed so the
  /// player never taps a non-functional "Watch ad" button.
  Future<bool> isReady(String placement);

  /// Show a rewarded ad for [placement]. Completes when the ad flow
  /// terminates one way or another.
  Future<AdResult> show(String placement);
}

/// Tests + pre-SDK production. Always reports `ready` and always
/// completes with a reward unless the caller injects a different
/// [nextOutcome]. Tracks every call in [showLog] so integration tests
/// can assert on analytics funnels without an ad SDK.
class StubRewardedAdService implements RewardedAdService {
  StubRewardedAdService({this.alwaysReady = true});

  bool alwaysReady;
  AdOutcome? nextOutcome;

  final List<String> showLog = <String>[];
  final List<String> readyProbeLog = <String>[];

  @override
  Future<bool> isReady(String placement) async {
    readyProbeLog.add(placement);
    return alwaysReady;
  }

  @override
  Future<AdResult> show(String placement) async {
    showLog.add(placement);
    final outcome = nextOutcome ?? AdOutcome.completed;
    nextOutcome = null;
    return AdResult(outcome: outcome);
  }
}
