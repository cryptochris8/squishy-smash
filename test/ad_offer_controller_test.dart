import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/analytics/events.dart';
import 'package:squishy_smash/core/analytics_stub.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/liveops_schedule.dart';
import 'package:squishy_smash/data/persistence.dart';
import 'package:squishy_smash/data/repositories/pack_repository.dart';
import 'package:squishy_smash/data/repositories/progression_repo.dart';
import 'package:squishy_smash/monetization/ad_offer_controller.dart';
import 'package:squishy_smash/monetization/rewarded_ad_service.dart';

LiveOpsSchedule _emptySchedule() =>
    LiveOpsSchedule.fromJson(const {'featuredRotation': []});

class RecordingAnalytics implements Analytics {
  final List<(String, Map<String, Object?>)> calls = [];
  @override
  void event(String name, [Map<String, Object?> params = const {}]) {
    calls.add((name, Map<String, Object?>.from(params)));
  }

  List<String> get eventNames => calls.map((c) => c.$1).toList();
}

Future<
    (
      ProgressionRepository repo,
      StubRewardedAdService ads,
      RecordingAnalytics sink,
      AdOfferController controller,
    )> _setup() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final persistence = await Persistence.open();
  final packs = PackRepository(<ContentPack>[], _emptySchedule());
  final repo = ProgressionRepository(persistence, packs);
  final ads = StubRewardedAdService();
  final sink = RecordingAnalytics();
  final events = GameEvents(sink);
  final controller = AdOfferController(
    ads: ads,
    progression: repo,
    events: events,
  );
  return (repo, ads, sink, controller);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StubRewardedAdService', () {
    test('isReady reflects alwaysReady flag + logs probes', () async {
      final ads = StubRewardedAdService(alwaysReady: false);
      expect(await ads.isReady(AdPlacement.roundEndBoost), isFalse);
      ads.alwaysReady = true;
      expect(await ads.isReady(AdPlacement.shopOffer), isTrue);
      expect(ads.readyProbeLog, [
        AdPlacement.roundEndBoost,
        AdPlacement.shopOffer,
      ]);
    });

    test('show returns completed by default + records the placement',
        () async {
      final ads = StubRewardedAdService();
      final result = await ads.show(AdPlacement.roundEndBoost);
      expect(result.outcome, AdOutcome.completed);
      expect(result.didReward, isTrue);
      expect(ads.showLog, [AdPlacement.roundEndBoost]);
    });

    test('nextOutcome override forces a single non-reward result', () async {
      final ads = StubRewardedAdService();
      ads.nextOutcome = AdOutcome.dismissedEarly;
      final first = await ads.show(AdPlacement.pityNudge);
      expect(first.didReward, isFalse);
      // override resets, second call completes cleanly
      final second = await ads.show(AdPlacement.pityNudge);
      expect(second.didReward, isTrue);
    });
  });

  group('AdOfferController.watchForReward', () {
    test('full success path grants a boost token + fires full funnel',
        () async {
      final (repo, _, sink, controller) = await _setup();
      expect(repo.profile.boostTokens, 0);
      final ok = await controller.watchForReward(
        AdPlacement.roundEndBoost,
        reward: const AdReward(type: AdRewardType.boostToken, amount: 1),
        sessionNumber: 3,
      );
      expect(ok, isTrue);
      expect(repo.profile.boostTokens, 1);
      expect(sink.eventNames, [
        'ad_reward_offer_accepted',
        'rewarded_ad_completed',
      ]);
    });

    test('coin reward path grants coins', () async {
      final (repo, _, _, controller) = await _setup();
      final ok = await controller.watchForReward(
        AdPlacement.shopOffer,
        reward: const AdReward(type: AdRewardType.coins, amount: 50),
        sessionNumber: 1,
      );
      expect(ok, isTrue);
      expect(repo.profile.coins, 50);
    });

    test('ad not ready returns false + fires accepted but no completion',
        () async {
      final (repo, ads, sink, controller) = await _setup();
      ads.alwaysReady = false;
      final ok = await controller.watchForReward(
        AdPlacement.roundEndBoost,
        reward: const AdReward(type: AdRewardType.boostToken, amount: 1),
        sessionNumber: 2,
      );
      expect(ok, isFalse);
      expect(repo.profile.boostTokens, 0);
      expect(sink.eventNames, ['ad_reward_offer_accepted']);
    });

    test('dismissed-early outcome skips reward + completion event',
        () async {
      final (repo, ads, sink, controller) = await _setup();
      ads.nextOutcome = AdOutcome.dismissedEarly;
      final ok = await controller.watchForReward(
        AdPlacement.pityNudge,
        reward: const AdReward(type: AdRewardType.boostToken, amount: 1),
        sessionNumber: 5,
      );
      expect(ok, isFalse);
      expect(repo.profile.boostTokens, 0);
      // accepted fires but rewarded_ad_completed does NOT
      expect(sink.eventNames, ['ad_reward_offer_accepted']);
    });
  });

  group('AdOfferController.offerShown / offerDeclined', () {
    test('shown fires the right analytics event with session number',
        () async {
      final (_, _, sink, controller) = await _setup();
      controller.offerShown(AdPlacement.roundEndBoost, sessionNumber: 7);
      expect(sink.eventNames, ['ad_reward_offer_shown']);
      expect(sink.calls.single.$2['session_number'], 7);
      expect(sink.calls.single.$2['placement'], 'round_end_boost');
    });

    test('declined fires the right analytics event', () async {
      final (_, _, sink, controller) = await _setup();
      controller.offerDeclined(AdPlacement.shopOffer, sessionNumber: 2);
      expect(sink.eventNames, ['ad_reward_offer_declined']);
      expect(sink.calls.single.$2['placement'], 'shop_offer');
    });
  });
}
