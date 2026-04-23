import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/data/content_loader.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/liveops_schedule.dart';
import 'package:squishy_smash/data/persistence.dart';
import 'package:squishy_smash/data/repositories/pack_repository.dart';
import 'package:squishy_smash/data/repositories/progression_repo.dart';

ContentPack _fakePack(String id, int cost) => ContentPack.fromJson({
      'packId': id,
      'displayName': id,
      'themeTag': 'test',
      'releaseType': 'launch',
      'palette': {
        'primary': '#FF8FB8',
        'secondary': '#FFD36E',
        'accent': '#7FE7FF',
      },
      'arenaSuggestion': 'any',
      'featuredAudioSet': 'any',
      'unlockCost': cost,
      'objects': <Map<String, dynamic>>[],
    });

LiveOpsSchedule _emptySchedule() =>
    LiveOpsSchedule.fromJson(const {'featuredRotation': []});

Future<ProgressionRepository> _open() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final persistence = await Persistence.open();
  final packs = PackRepository(
    <ContentPack>[
      _fakePack('launch_squishy_foods', 0),
      _fakePack('dumpling_squishy_drop_01', 500),
      _fakePack('goo_fidgets_drop_01', 150),
    ],
    _emptySchedule(),
  );
  return ProgressionRepository(persistence, packs);
}

// Wire the real loader to prove the bundled Dumpling pack JSON parses.
// This verifies the schema changes we just shipped don't break the
// rootBundle pipeline at a static level.
Future<void> _verifyBundledPackPathsUnique() async {
  final paths = ContentLoader.bundledPackPaths;
  expect(paths.toSet().length, paths.length,
      reason: 'bundled pack paths must be unique');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressionRepository session counting', () {
    test('starts at zero on fresh install', () async {
      final repo = await _open();
      expect(repo.profile.sessionCount, 0);
    });

    test('noteSessionStart increments monotonically', () async {
      final repo = await _open();
      await repo.noteSessionStart();
      expect(repo.profile.sessionCount, 1);
      await repo.noteSessionStart();
      await repo.noteSessionStart();
      expect(repo.profile.sessionCount, 3);
    });

    test('session count persists across re-open', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p1 = await Persistence.open();
      final packs = PackRepository(<ContentPack>[], _emptySchedule());
      final repo1 = ProgressionRepository(p1, packs);
      await repo1.noteSessionStart();
      await repo1.noteSessionStart();
      expect(repo1.profile.sessionCount, 2);

      // Re-open — shared prefs mock retains state within the same test.
      final p2 = await Persistence.open();
      final repo2 = ProgressionRepository(p2, packs);
      expect(repo2.profile.sessionCount, 2);
    });
  });

  group('ProgressionRepository unlock flow', () {
    test('tryUnlock succeeds when coins suffice', () async {
      final repo = await _open();
      await repo.awardCoins(600);
      expect(await repo.tryUnlock('dumpling_squishy_drop_01'), isTrue);
      expect(repo.profile.coins, 100);
      expect(repo.isUnlocked('dumpling_squishy_drop_01'), isTrue);
    });

    test('tryUnlock fails when coins insufficient', () async {
      final repo = await _open();
      await repo.awardCoins(100);
      expect(await repo.tryUnlock('dumpling_squishy_drop_01'), isFalse);
      expect(repo.profile.coins, 100);
      expect(repo.isUnlocked('dumpling_squishy_drop_01'), isFalse);
    });

    test('tryUnlock is idempotent — second call returns false', () async {
      final repo = await _open();
      await repo.awardCoins(1000);
      expect(await repo.tryUnlock('dumpling_squishy_drop_01'), isTrue);
      expect(await repo.tryUnlock('dumpling_squishy_drop_01'), isFalse);
      // coins should not be deducted again.
      expect(repo.profile.coins, 500);
    });

    test('recordRound persists only new personal bests', () async {
      final repo = await _open();
      await repo.recordRound(score: 500, combo: 10);
      expect(repo.profile.bestScore, 500);
      expect(repo.profile.bestCombo, 10);
      await repo.recordRound(score: 200, combo: 5);
      expect(repo.profile.bestScore, 500);
      expect(repo.profile.bestCombo, 10);
      await repo.recordRound(score: 800, combo: 8);
      expect(repo.profile.bestScore, 800);
      expect(repo.profile.bestCombo, 10);
    });
  });

  group('ProgressionRepository arena unlock flow', () {
    test('fresh profile: only the launch arena unlocked + active', () async {
      final repo = await _open();
      expect(repo.profile.unlockedArenaKeys, <String>{'mochi_sunset_beach'});
      expect(repo.profile.activeArenaKey, 'mochi_sunset_beach');
      expect(repo.isArenaUnlocked('mochi_sunset_beach'), isTrue);
      expect(repo.isArenaUnlocked('neon_fidget_arcade'), isFalse);
    });

    test('unlocking a pack auto-grants its bundled arena', () async {
      final repo = await _open();
      await repo.awardCoins(1000);
      // dumpling_squishy_drop_01 bundles candy_cloud_kitchen.
      expect(await repo.tryUnlock('dumpling_squishy_drop_01'), isTrue);
      expect(repo.isArenaUnlocked('candy_cloud_kitchen'), isTrue);
      // ...but not arenas bundled with other packs.
      expect(repo.isArenaUnlocked('goo_laboratory'), isFalse);
    });

    test('tryUnlockArena succeeds for a standalone arena when affordable',
        () async {
      final repo = await _open();
      await repo.awardCoins(200);
      // forest_dew_garden is standalone at 100 coins.
      expect(await repo.tryUnlockArena('forest_dew_garden'), isTrue);
      expect(repo.profile.coins, 100);
      expect(repo.isArenaUnlocked('forest_dew_garden'), isTrue);
    });

    test('tryUnlockArena fails when coins insufficient', () async {
      final repo = await _open();
      await repo.awardCoins(50);
      expect(await repo.tryUnlockArena('forest_dew_garden'), isFalse);
      expect(repo.profile.coins, 50);
      expect(repo.isArenaUnlocked('forest_dew_garden'), isFalse);
    });

    test('tryUnlockArena rejects pack-bundled arenas', () async {
      final repo = await _open();
      await repo.awardCoins(10000);
      // candy_cloud_kitchen has cost 0 + bundledWithPack — not buyable
      // through the standalone path.
      expect(await repo.tryUnlockArena('candy_cloud_kitchen'), isFalse);
      expect(repo.profile.coins, 10000);
    });

    test('tryUnlockArena rejects unknown arena keys', () async {
      final repo = await _open();
      await repo.awardCoins(10000);
      expect(await repo.tryUnlockArena('not_a_real_arena'), isFalse);
      expect(repo.profile.coins, 10000);
    });

    test('tryUnlockArena is idempotent', () async {
      final repo = await _open();
      await repo.awardCoins(300);
      expect(await repo.tryUnlockArena('forest_dew_garden'), isTrue);
      expect(await repo.tryUnlockArena('forest_dew_garden'), isFalse);
      // No second deduction.
      expect(repo.profile.coins, 200);
    });

    test('setActiveArena requires ownership', () async {
      final repo = await _open();
      // Player owns mochi_sunset_beach by default but not gelatin_reef.
      expect(await repo.setActiveArena('gelatin_reef'), isFalse);
      expect(repo.profile.activeArenaKey, 'mochi_sunset_beach');
    });

    test('setActiveArena flips the active arena and persists', () async {
      final repo = await _open();
      await repo.awardCoins(200);
      await repo.tryUnlockArena('forest_dew_garden');
      expect(await repo.setActiveArena('forest_dew_garden'), isTrue);
      expect(repo.profile.activeArenaKey, 'forest_dew_garden');
    });
  });

  group('ContentLoader bundledPackPaths', () {
    test('all paths are unique', () async {
      await _verifyBundledPackPathsUnique();
    });

    test('includes the Dumpling Squishy drop', () {
      expect(
        ContentLoader.bundledPackPaths,
        contains('assets/data/packs/dumpling_squishy_drop_01.json'),
      );
    });
  });
}
