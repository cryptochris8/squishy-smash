import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/data/models/player_profile.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Persistence defaults', () {
    test('first-launch profile unlocks only the launch pack', () async {
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 0);
      expect(profile.bestScore, 0);
      expect(profile.bestCombo, 0);
      expect(profile.sessionCount, 0);
      expect(profile.unlockedPackIds, <String>{'launch_squishy_foods'});
    });

    test(
        'first-launch profile has empty discovery + per-pack maps + common '
        'rarest-seen', () async {
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.discoveredSmashableIds, isEmpty);
      expect(profile.rarestSeen, Rarity.common);
      expect(profile.totalBurstsByPack, isEmpty);
      expect(profile.rareDryByPack, isEmpty);
      expect(profile.epicDryByPack, isEmpty);
      expect(profile.legendaryDryByPack, isEmpty);
    });

    test('first-launch profile unlocks only the launch arena', () async {
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.unlockedArenaKeys, <String>{'mochi_sunset_beach'});
      expect(profile.activeArenaKey, 'mochi_sunset_beach');
    });

    test('haptics defaults on, mute defaults off', () async {
      final p = await Persistence.open();
      expect(p.hapticsEnabled, isTrue);
      expect(p.muted, isFalse);
    });
  });

  group('Persistence round-trip', () {
    test('saveProfile → loadProfile preserves every field', () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 1234,
        unlockedPackIds: <String>{
          'launch_squishy_foods',
          'dumpling_squishy_drop_01',
        },
        bestScore: 9876,
        bestCombo: 42,
        sessionCount: 7,
        unlockedArenaKeys: <String>{
          'mochi_sunset_beach',
          'candy_cloud_kitchen',
          'neon_fidget_arcade',
        },
        activeArenaKey: 'neon_fidget_arcade',
        discoveredSmashableIds: <String>{'dumplio', 'jellyzap', 'slimeorb'},
        rarestSeen: Rarity.epic,
      );
      await p.saveProfile(profile);

      final reloaded = p.loadProfile();
      expect(reloaded.coins, 1234);
      expect(reloaded.unlockedPackIds, {
        'launch_squishy_foods',
        'dumpling_squishy_drop_01',
      });
      expect(reloaded.bestScore, 9876);
      expect(reloaded.bestCombo, 42);
      expect(reloaded.sessionCount, 7);
      expect(reloaded.unlockedArenaKeys, {
        'mochi_sunset_beach',
        'candy_cloud_kitchen',
        'neon_fidget_arcade',
      });
      expect(reloaded.activeArenaKey, 'neon_fidget_arcade');
      expect(reloaded.discoveredSmashableIds,
          {'dumplio', 'jellyzap', 'slimeorb'});
      expect(reloaded.rarestSeen, Rarity.epic);
    });

    test('per-pack progression maps round-trip through JSON encoding',
        () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 0,
        unlockedPackIds: const <String>{'launch'},
        bestScore: 0,
        bestCombo: 0,
        totalBurstsByPack: <String, int>{
          'launch_squishy_foods': 42,
          'goo_fidgets_drop_01': 7,
        },
        rareDryByPack: <String, int>{'launch_squishy_foods': 4},
        epicDryByPack: <String, int>{'launch_squishy_foods': 13},
        legendaryDryByPack: <String, int>{'launch_squishy_foods': 28},
      );
      await p.saveProfile(profile);

      final reloaded = p.loadProfile();
      expect(reloaded.totalBurstsByPack, {
        'launch_squishy_foods': 42,
        'goo_fidgets_drop_01': 7,
      });
      expect(reloaded.rareDryByPack, {'launch_squishy_foods': 4});
      expect(reloaded.epicDryByPack, {'launch_squishy_foods': 13});
      expect(reloaded.legendaryDryByPack, {'launch_squishy_foods': 28});
    });

    test('settings toggles round-trip', () async {
      final p = await Persistence.open();
      await p.setHapticsEnabled(false);
      await p.setMuted(true);
      final reloaded = await Persistence.open();
      expect(reloaded.hapticsEnabled, isFalse);
      expect(reloaded.muted, isTrue);
    });
  });
}
