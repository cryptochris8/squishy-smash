import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/analytics/events.dart';
import 'package:squishy_smash/core/analytics_stub.dart';
import 'package:squishy_smash/data/models/rarity.dart';

/// Recording analytics sink for assertions. Keeps every (name, params)
/// tuple in call order.
class RecordingAnalytics implements Analytics {
  final List<(String, Map<String, Object?>)> calls =
      <(String, Map<String, Object?>)>[];

  @override
  void event(String name, [Map<String, Object?> params = const {}]) {
    calls.add((name, Map<String, Object?>.from(params)));
  }

  (String, Map<String, Object?>) get last => calls.last;

  String get lastName => last.$1;
  Map<String, Object?> get lastParams => last.$2;
}

void main() {
  group('GameEvents core loop', () {
    test('tutorialBegin emits the right name with no params', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).tutorialBegin();
      expect(sink.lastName, 'tutorial_begin');
      expect(sink.lastParams, isEmpty);
    });

    test('levelStart carries pack_id and session_index', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).levelStart(packId: 'dumpling_squishy', sessionIndex: 4);
      expect(sink.lastName, 'level_start');
      expect(sink.lastParams, {
        'pack_id': 'dumpling_squishy',
        'session_index': 4,
      });
    });

    test('levelEnd carries full summary fields', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).levelEnd(
        packId: 'dumpling_squishy',
        smashes: 28,
        durationMs: 60000,
        success: true,
      );
      expect(sink.lastParams, {
        'pack_id': 'dumpling_squishy',
        'smashes': 28,
        'duration_ms': 60000,
        'success': true,
      });
    });

    test('objectSmashed serializes rarity as its token', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).objectSmashed(
        objectId: 'dumplio',
        packId: 'dumpling_squishy',
        comboCount: 7,
        rarity: Rarity.mythic,
      );
      expect(sink.lastName, 'object_smashed');
      expect(sink.lastParams['rarity'], 'mythic');
      expect(sink.lastParams['combo_count'], 7);
    });
  });

  group('GameEvents monetization', () {
    test('adRewardEarned carries placement, type, amount', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).adRewardEarned(
        placement: 'round_end_double_coins',
        rewardType: 'coins',
        amount: 50,
      );
      expect(sink.lastName, 'ad_reward_earned');
      expect(sink.lastParams, {
        'placement': 'round_end_double_coins',
        'reward_type': 'coins',
        'amount': 50,
      });
    });

    test('earnVirtualCurrency uses firebase recommended param names', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).earnVirtualCurrency(
        currencyName: 'coins',
        value: 8,
        source: 'burst',
      );
      expect(sink.lastName, 'earn_virtual_currency');
      expect(sink.lastParams['virtual_currency_name'], 'coins');
      expect(sink.lastParams['value'], 8);
      expect(sink.lastParams['source'], 'burst');
    });

    test('spendVirtualCurrency uses firebase recommended param names', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).spendVirtualCurrency(
        currencyName: 'coins',
        value: 500,
        itemName: 'pack_dumpling_squishy',
      );
      expect(sink.lastName, 'spend_virtual_currency');
      expect(sink.lastParams['virtual_currency_name'], 'coins');
      expect(sink.lastParams['item_name'], 'pack_dumpling_squishy');
    });
  });

  group('GameEvents retention', () {
    test('shareClip serializes rarity and destination', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).shareClip(
        objectId: 'dumplio',
        destination: 'tiktok',
        rarity: Rarity.epic,
      );
      expect(sink.lastName, 'share_clip');
      expect(sink.lastParams['destination'], 'tiktok');
      expect(sink.lastParams['rarity'], 'epic');
      expect(sink.lastParams['object_id'], 'dumplio');
    });

    test('settingsChanged forwards arbitrary value types', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).settingsChanged(setting: 'haptics', value: true);
      expect(sink.lastParams, {'setting': 'haptics', 'value': true});
      GameEvents(sink).settingsChanged(setting: 'music_volume', value: 0.6);
      expect(sink.lastParams, {'setting': 'music_volume', 'value': 0.6});
    });
  });

  group('GameEvents retention / collection meta', () {
    test('duplicateAwarded carries rarity + coin payload', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).duplicateAwarded(
        objectId: 'dumplio',
        packId: 'launch_squishy_foods',
        rarity: Rarity.rare,
        coinsAwarded: 10,
      );
      expect(sink.lastName, 'duplicate_awarded');
      expect(sink.lastParams['rarity'], 'rare');
      expect(sink.lastParams['coins_awarded'], 10);
    });

    test('pityTriggered serializes forced tier as token', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).pityTriggered(
        packId: 'launch_squishy_foods',
        forcedTier: Rarity.mythic,
        bursts: 50,
      );
      expect(sink.lastName, 'pity_triggered');
      expect(sink.lastParams['forced_tier'], 'mythic');
      expect(sink.lastParams['bursts_in_pack'], 50);
    });

    test('firstEpicFound + firstLegendaryFound are distinct events', () {
      final sink = RecordingAnalytics();
      GameEvents(sink)
          .firstEpicFound(packId: 'goo', objectId: 'plasma_goo_ball');
      GameEvents(sink).firstLegendaryFound(
          packId: 'goo', objectId: 'singularity_goo_core');
      expect(sink.calls.map((c) => c.$1).toList(),
          ['first_epic_found', 'first_legendary_found']);
    });

    test('packProgressUpdated reports discovered/total', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).packProgressUpdated(
        packId: 'launch_squishy_foods',
        discovered: 7,
        total: 16,
      );
      expect(sink.lastName, 'pack_progress_updated');
      expect(sink.lastParams['discovered'], 7);
      expect(sink.lastParams['total'], 16);
    });

    test('boostGranted + boostUsed serialize source + pack', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).boostGranted(source: 'session_streak_7', tokensAfter: 1);
      expect(sink.lastName, 'boost_granted');
      expect(sink.lastParams['source'], 'session_streak_7');
      GameEvents(sink).boostUsed(packId: 'goo_fidgets_drop_01');
      expect(sink.lastName, 'boost_used');
      expect(sink.lastParams['pack_id'], 'goo_fidgets_drop_01');
    });
  });

  group('GameEvents error', () {
    test('assetLoadFailed carries path + error', () {
      final sink = RecordingAnalytics();
      GameEvents(sink).assetLoadFailed(
        assetPath: 'audio/food/dumplio_burst_01.mp3',
        error: 'MissingPluginException',
      );
      expect(sink.lastName, 'asset_load_failed');
      expect(sink.lastParams['asset_path'],
          'audio/food/dumplio_burst_01.mp3');
    });
  });

  group('NoOpAnalytics passthrough', () {
    test('events are silently dropped', () {
      const sink = NoOpAnalytics();
      final events = GameEvents(sink);
      // Should not throw.
      events.levelStart(packId: 'x', sessionIndex: 0);
      events.shareClip(
          objectId: 'o', destination: 'd', rarity: Rarity.common);
      events.settingsChanged(setting: 's', value: 1);
    });
  });
}
