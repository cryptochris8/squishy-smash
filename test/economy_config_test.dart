import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/economy_config_loader.dart';
import 'package:squishy_smash/data/models/economy_config.dart';
import 'package:squishy_smash/data/models/rarity.dart';

class _FakeAssets {
  final Map<String, String> _bodies = {};
  final Map<String, Object> _errors = {};
  void put(String path, String body) => _bodies[path] = body;
  void fail(String path, Object err) => _errors[path] = err;
  Future<String> read(String path) async {
    if (_errors.containsKey(path)) throw _errors[path]!;
    if (_bodies.containsKey(path)) return _bodies[path]!;
    throw StateError('No fake asset for $path');
  }
}

void main() {
  // Needed for the "Bundled JSON loads via rootBundle" group below.
  // Pure-Dart groups don't need it but it's harmless.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EconomyConfig const defaults match v0.1.0 baseline', () {
    // The defaults are the kill-switch — if a JSON load fails, the
    // app falls back to these. They must mirror what shipped in
    // v0.1.0 so nothing changes silently.
    test('burst thresholds: 1 / 3 / 7 / 15', () {
      const c = EconomyConfig();
      expect(c.requiredBurstsFor(Rarity.common), 1);
      expect(c.requiredBurstsFor(Rarity.rare), 3);
      expect(c.requiredBurstsFor(Rarity.epic), 7);
      expect(c.requiredBurstsFor(Rarity.mythic), 15);
    });

    test('coin prices: 50 / 200 / 750 / 2500', () {
      const c = EconomyConfig();
      expect(c.coinPriceFor(Rarity.common), 50);
      expect(c.coinPriceFor(Rarity.rare), 200);
      expect(c.coinPriceFor(Rarity.epic), 750);
      expect(c.coinPriceFor(Rarity.mythic), 2500);
    });

    test('duplicate coin bonus: 2 / 10 / 25 / 50', () {
      const c = EconomyConfig();
      expect(c.duplicateCoinBonusFor(Rarity.common), 2);
      expect(c.duplicateCoinBonusFor(Rarity.rare), 10);
      expect(c.duplicateCoinBonusFor(Rarity.epic), 25);
      expect(c.duplicateCoinBonusFor(Rarity.mythic), 50);
    });

    test('anti-spam cooldown defaults to 0 (disabled)', () {
      const c = EconomyConfig();
      expect(c.antiSpamCooldownMs, 0);
    });

    test('pack milestones default to empty (disabled)', () {
      const c = EconomyConfig();
      expect(c.packMilestones, isEmpty);
    });
  });

  group('EconomyConfig.fromJson — full payload', () {
    test('parses every field at the new "Option B" target values', () {
      final c = EconomyConfig.fromJson(<String, dynamic>{
        'schemaVersion': 1,
        'burstThresholds': {
          'common': 3, 'rare': 8, 'epic': 20, 'legendary': 40,
        },
        'coinPrices': {
          'common': 100, 'rare': 400, 'epic': 1500, 'legendary': 5000,
        },
        'duplicateCoinBonus': {
          'common': 0, 'rare': 15, 'epic': 40, 'legendary': 100,
        },
        'antiSpamCooldownMs': {'value': 1000},
        'packMilestones': {
          'thresholds': [
            {'percent': 25, 'coinReward': 50},
            {'percent': 50, 'coinReward': 100},
            {'percent': 100, 'coinReward': 500},
          ],
        },
      });
      expect(c.requiredBurstsFor(Rarity.common), 3);
      expect(c.requiredBurstsFor(Rarity.mythic), 40);
      expect(c.coinPriceFor(Rarity.epic), 1500);
      expect(c.duplicateCoinBonusFor(Rarity.common), 0);
      expect(c.antiSpamCooldownMs, 1000);
      expect(c.packMilestones, hasLength(3));
      expect(c.packMilestones[0].percent, 25);
      expect(c.packMilestones[0].coinReward, 50);
    });
  });

  group('EconomyConfig.fromJson — defensive parsing', () {
    test('missing top-level keys fall back to const defaults', () {
      final c = EconomyConfig.fromJson(<String, dynamic>{});
      // Same as the const default — losing one field doesn't take
      // down the whole config.
      expect(c.requiredBurstsFor(Rarity.common), 1);
      expect(c.coinPriceFor(Rarity.mythic), 2500);
      expect(c.antiSpamCooldownMs, 0);
      expect(c.packMilestones, isEmpty);
    });

    test('partial rarity tunable falls back per-tier', () {
      final c = EconomyConfig.fromJson(<String, dynamic>{
        'burstThresholds': {'common': 5},
        // Other tiers omitted — should keep defaults.
      });
      expect(c.requiredBurstsFor(Rarity.common), 5);
      expect(c.requiredBurstsFor(Rarity.rare), 3);
      expect(c.requiredBurstsFor(Rarity.epic), 7);
      expect(c.requiredBurstsFor(Rarity.mythic), 15);
    });

    test('"mythic" key parses as alias for "legendary"', () {
      // Backward-compat with the existing Rarity terminology aliasing.
      final c = EconomyConfig.fromJson(<String, dynamic>{
        'burstThresholds': {'mythic': 99},
      });
      expect(c.requiredBurstsFor(Rarity.mythic), 99);
    });

    test('"legendary" key wins over "mythic" when both present', () {
      // Same precedence as the rest of the codebase — `legendary` is
      // canonical, `mythic` is the legacy alias.
      final c = EconomyConfig.fromJson(<String, dynamic>{
        'burstThresholds': {'legendary': 99, 'mythic': 1},
      });
      expect(c.requiredBurstsFor(Rarity.mythic), 99);
    });
  });

  group('EconomyConfigLoader resilience', () {
    test('a missing asset falls back to the const default', () async {
      final fake = _FakeAssets();
      fake.fail(kEconomyConfigPath, StateError('not bundled'));
      final c = await EconomyConfigLoader().load(readAsset: fake.read);
      expect(c.requiredBurstsFor(Rarity.common), 1);
      expect(c.antiSpamCooldownMs, 0);
    });

    test('malformed JSON falls back to the const default', () async {
      final fake = _FakeAssets();
      fake.put(kEconomyConfigPath, '{ not valid json');
      final c = await EconomyConfigLoader().load(readAsset: fake.read);
      expect(c.requiredBurstsFor(Rarity.common), 1);
    });

    test('a future schemaVersion falls back to the const default',
        () async {
      // Version mismatch is a "newer config than this app build can
      // read" condition. Safer to ship default behavior than to
      // attempt-and-mis-parse.
      final fake = _FakeAssets();
      fake.put(kEconomyConfigPath, '''
        {"schemaVersion": 999, "burstThresholds": {"common": 99}}
      ''');
      final c = await EconomyConfigLoader().load(readAsset: fake.read);
      expect(c.requiredBurstsFor(Rarity.common), 1,
          reason: 'future schemaVersion must NOT apply the new value');
    });

    test('valid v1 JSON loads through the loader cleanly', () async {
      final fake = _FakeAssets();
      fake.put(kEconomyConfigPath, '''
        {
          "schemaVersion": 1,
          "burstThresholds": {"common": 7, "rare": 14, "epic": 28, "legendary": 56}
        }
      ''');
      final c = await EconomyConfigLoader().load(readAsset: fake.read);
      expect(c.requiredBurstsFor(Rarity.common), 7);
      expect(c.requiredBurstsFor(Rarity.mythic), 56);
    });
  });

  group('Bundled assets/data/economy.json round-trip', () {
    late final EconomyConfig shipped;
    setUpAll(() async {
      shipped = await EconomyConfigLoader().load();
    });

    test('the shipped JSON parses cleanly through the loader', () {
      // If a future edit malforms the JSON, the loader silently falls
      // back to the const default and several of the assertions below
      // would still pass (some shipped values match defaults). This
      // top-level test is just a "nothing crashed" guard.
      expect(shipped, isNotNull);
    });

    test('shipped burst thresholds match the v0.1.1 rebalance values', () {
      // Pin the shipped numbers. Editing the JSON is fine — but the
      // edit must come with an intentional update to this test so a
      // sloppy "fix the typo" doesn't silently revert the rebalance.
      expect(shipped.requiredBurstsFor(Rarity.common), 3);
      expect(shipped.requiredBurstsFor(Rarity.rare), 8);
      expect(shipped.requiredBurstsFor(Rarity.epic), 20);
      expect(shipped.requiredBurstsFor(Rarity.mythic), 40);
    });

    test('shipped coin prices match the v0.1.1 rebalance values', () {
      expect(shipped.coinPriceFor(Rarity.common), 100);
      expect(shipped.coinPriceFor(Rarity.rare), 400);
      expect(shipped.coinPriceFor(Rarity.epic), 1500);
      expect(shipped.coinPriceFor(Rarity.mythic), 5000);
    });

    test('shipped duplicate bonuses tick visibly without inflating', () {
      // P1.8 lift: common dupes pay 1 coin (was 0). The wallet now
      // ticks visibly when a player taps a known character — pre-fix
      // a 0-coin pop with no toast and no sound felt like a bug to
      // playtesters. The anti-spam cooldown still throttles same-id
      // repeats so spam-tap inflation stays contained.
      expect(shipped.duplicateCoinBonusFor(Rarity.common), 1,
          reason: 'common dupes pay 1 coin — non-zero so the toast '
              'fires, low enough that the anti-spam cooldown caps '
              'inflation');
      expect(shipped.duplicateCoinBonusFor(Rarity.rare), 15);
      expect(shipped.duplicateCoinBonusFor(Rarity.epic), 40);
      expect(shipped.duplicateCoinBonusFor(Rarity.mythic), 100);
    });

    test('shipped anti-spam cooldown is 1000ms (per-smashable)', () {
      expect(shipped.antiSpamCooldownMs, 1000);
    });

    test('shipped pack milestones are 25/50/75/100% with rising coin '
        'rewards', () {
      expect(shipped.packMilestones, hasLength(4));
      expect(shipped.packMilestones.map((m) => m.percent),
          [25, 50, 75, 100]);
      // Rewards should be monotonically increasing — bigger payout
      // for the harder-to-reach tiers.
      final rewards =
          shipped.packMilestones.map((m) => m.coinReward).toList();
      for (var i = 1; i < rewards.length; i++) {
        expect(rewards[i], greaterThan(rewards[i - 1]),
            reason: 'milestone rewards must be strictly increasing');
      }
    });
  });
}
