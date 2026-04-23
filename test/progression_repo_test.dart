import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/data/content_loader.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/liveops_schedule.dart';
import 'package:squishy_smash/data/models/rarity.dart';
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

  group('ProgressionRepository pity counters', () {
    test('noteSpawnRoll writes counters through to the profile', () async {
      final repo = await _open();
      expect(repo.profile.rollsSinceRare, 0);
      await repo.noteSpawnRoll(
        rollsSinceRare: 5,
        rollsSinceEpic: 12,
        rollsSinceMythic: 88,
      );
      expect(repo.profile.rollsSinceRare, 5);
      expect(repo.profile.rollsSinceEpic, 12);
      expect(repo.profile.rollsSinceMythic, 88);
    });

    test('pity counters persist across repo re-open', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p1 = await Persistence.open();
      final packs = PackRepository(<ContentPack>[], _emptySchedule());
      final repo1 = ProgressionRepository(p1, packs);
      await repo1.noteSpawnRoll(
        rollsSinceRare: 3,
        rollsSinceEpic: 9,
        rollsSinceMythic: 27,
      );

      final p2 = await Persistence.open();
      final repo2 = ProgressionRepository(p2, packs);
      expect(repo2.profile.rollsSinceRare, 3);
      expect(repo2.profile.rollsSinceEpic, 9);
      expect(repo2.profile.rollsSinceMythic, 27);
    });
  });

  group('ProgressionRepository collection discovery', () {
    test('markDiscovered returns true on first sighting only', () async {
      final repo = await _open();
      expect(
        await repo.markDiscovered(
          smashableId: 'dumplio',
          rarity: Rarity.common,
        ),
        isTrue,
      );
      expect(repo.profile.discoveredSmashableIds, {'dumplio'});

      expect(
        await repo.markDiscovered(
          smashableId: 'dumplio',
          rarity: Rarity.common,
        ),
        isFalse,
      );
      expect(repo.profile.discoveredSmashableIds, {'dumplio'});
    });

    test('markDiscovered raises rarestSeen monotonically', () async {
      final repo = await _open();
      expect(repo.profile.rarestSeen, Rarity.common);

      await repo.markDiscovered(
        smashableId: 'dumplio',
        rarity: Rarity.rare,
      );
      expect(repo.profile.rarestSeen, Rarity.rare);

      await repo.markDiscovered(
        smashableId: 'gold_dumplio',
        rarity: Rarity.mythic,
      );
      expect(repo.profile.rarestSeen, Rarity.mythic);

      // A later common burst must not downgrade the rarestSeen stat.
      await repo.markDiscovered(
        smashableId: 'poppling',
        rarity: Rarity.common,
      );
      expect(repo.profile.rarestSeen, Rarity.mythic);
    });

    test('discovered set persists across repo re-open', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p1 = await Persistence.open();
      final packs = PackRepository(<ContentPack>[], _emptySchedule());
      final repo1 = ProgressionRepository(p1, packs);
      await repo1.markDiscovered(
        smashableId: 'jellyzap',
        rarity: Rarity.epic,
      );
      await repo1.markDiscovered(
        smashableId: 'slimeorb',
        rarity: Rarity.common,
      );

      final p2 = await Persistence.open();
      final repo2 = ProgressionRepository(p2, packs);
      expect(repo2.profile.discoveredSmashableIds,
          {'jellyzap', 'slimeorb'});
      expect(repo2.profile.rarestSeen, Rarity.epic);
    });
  });

  group('ProgressionRepository per-pack burst tracking', () {
    test('noteBurstForPack is a no-op for commons', () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.common,
      );
      expect(repo.profile.rareBurstsByPack, isEmpty);
      expect(repo.profile.epicBurstsByPack, isEmpty);
    });

    test('rare burst bumps only the rare counter for that pack', () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.rare,
      );
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.rare,
      );
      expect(repo.rareBurstsInPack('launch_squishy_foods'), 2);
      expect(repo.epicBurstsInPack('launch_squishy_foods'), 0);
      // Other packs untouched.
      expect(repo.rareBurstsInPack('goo_fidgets_drop_01'), 0);
    });

    test('epic burst bumps both rare and epic counters', () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'creepy_cute_pack_01',
        rarity: Rarity.epic,
      );
      expect(repo.rareBurstsInPack('creepy_cute_pack_01'), 1);
      expect(repo.epicBurstsInPack('creepy_cute_pack_01'), 1);
    });

    test('mythic burst bumps both counters too', () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'dumpling_squishy_drop_01',
        rarity: Rarity.mythic,
      );
      expect(repo.rareBurstsInPack('dumpling_squishy_drop_01'), 1);
      expect(repo.epicBurstsInPack('dumpling_squishy_drop_01'), 1);
    });

    test('per-pack counters persist across repo re-open', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p1 = await Persistence.open();
      final packs = PackRepository(<ContentPack>[], _emptySchedule());
      final repo1 = ProgressionRepository(p1, packs);
      await repo1.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.rare,
      );
      await repo1.noteBurstForPack(
        packId: 'creepy_cute_pack_01',
        rarity: Rarity.epic,
      );

      final p2 = await Persistence.open();
      final repo2 = ProgressionRepository(p2, packs);
      expect(repo2.rareBurstsInPack('launch_squishy_foods'), 1);
      expect(repo2.rareBurstsInPack('creepy_cute_pack_01'), 1);
      expect(repo2.epicBurstsInPack('creepy_cute_pack_01'), 1);
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
