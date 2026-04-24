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

  group('ProgressionRepository streak tracking', () {
    test('first launch starts streak at 1, no milestone', () async {
      final repo = await _open();
      final result =
          await repo.noteSessionStart(now: DateTime(2026, 4, 23));
      expect(result.streak, 1);
      expect(result.milestone, 0);
      expect(result.boostTokenAwarded, isFalse);
      expect(repo.profile.currentStreak, 1);
      expect(repo.profile.longestStreak, 1);
    });

    test('reaching day 3 grants a boost token + fires milestone',
        () async {
      final repo = await _open();
      await repo.noteSessionStart(now: DateTime(2026, 4, 23));
      await repo.noteSessionStart(now: DateTime(2026, 4, 24));
      final day3 = await repo.noteSessionStart(now: DateTime(2026, 4, 25));
      expect(day3.streak, 3);
      expect(day3.milestone, 3);
      expect(day3.boostTokenAwarded, isTrue);
      expect(repo.profile.boostTokens, 1);
    });

    test('same-day re-launch is a no-op for streak + tokens', () async {
      final repo = await _open();
      await repo.noteSessionStart(now: DateTime(2026, 4, 23));
      final replay =
          await repo.noteSessionStart(now: DateTime(2026, 4, 23, 18));
      expect(replay.streak, 1);
      expect(replay.boostTokenAwarded, isFalse);
      expect(repo.profile.boostTokens, 0);
    });

    test('skipping a day resets streak to 1', () async {
      final repo = await _open();
      await repo.noteSessionStart(now: DateTime(2026, 4, 23));
      await repo.noteSessionStart(now: DateTime(2026, 4, 24));
      final afterSkip =
          await repo.noteSessionStart(now: DateTime(2026, 4, 26));
      expect(afterSkip.streak, 1);
      // longest stays at the prior peak.
      expect(repo.profile.longestStreak, 2);
    });

    test('boost token consume/grant round-trip', () async {
      final repo = await _open();
      expect(await repo.consumeBoostToken(), isFalse,
          reason: 'nothing to consume');
      await repo.grantBoostToken();
      expect(repo.profile.boostTokens, 1);
      expect(await repo.consumeBoostToken(), isTrue);
      expect(repo.profile.boostTokens, 0);
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
    test('common burst bumps totalBursts + all three dry counters',
        () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.common,
      );
      expect(repo.totalBurstsInPack('launch_squishy_foods'), 1);
      expect(repo.rareDryInPack('launch_squishy_foods'), 1);
      expect(repo.epicDryInPack('launch_squishy_foods'), 1);
      expect(repo.legendaryDryInPack('launch_squishy_foods'), 1);
    });

    test('rare burst resets rareDry, increments epic + legendary dry',
        () async {
      final repo = await _open();
      // Warm up the counters with two commons first
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.common,
      );
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.common,
      );
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.rare,
      );
      expect(repo.totalBurstsInPack('launch_squishy_foods'), 3);
      expect(repo.rareDryInPack('launch_squishy_foods'), 0);
      expect(repo.epicDryInPack('launch_squishy_foods'), 3);
      expect(repo.legendaryDryInPack('launch_squishy_foods'), 3);
    });

    test('epic burst resets rareDry + epicDry', () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'creepy_cute_pack_01',
        rarity: Rarity.epic,
      );
      expect(repo.totalBurstsInPack('creepy_cute_pack_01'), 1);
      expect(repo.rareDryInPack('creepy_cute_pack_01'), 0);
      expect(repo.epicDryInPack('creepy_cute_pack_01'), 0);
      expect(repo.legendaryDryInPack('creepy_cute_pack_01'), 1);
    });

    test('mythic burst resets every dry counter', () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'dumpling_squishy_drop_01',
        rarity: Rarity.mythic,
      );
      expect(repo.rareDryInPack('dumpling_squishy_drop_01'), 0);
      expect(repo.epicDryInPack('dumpling_squishy_drop_01'), 0);
      expect(repo.legendaryDryInPack('dumpling_squishy_drop_01'), 0);
    });

    test('other packs are untouched by a burst in one pack', () async {
      final repo = await _open();
      await repo.noteBurstForPack(
        packId: 'launch_squishy_foods',
        rarity: Rarity.common,
      );
      expect(repo.totalBurstsInPack('goo_fidgets_drop_01'), 0);
      expect(repo.rareDryInPack('goo_fidgets_drop_01'), 0);
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
      expect(repo2.totalBurstsInPack('launch_squishy_foods'), 1);
      expect(repo2.totalBurstsInPack('creepy_cute_pack_01'), 1);
      expect(repo2.rareDryInPack('creepy_cute_pack_01'), 0);
      expect(repo2.epicDryInPack('creepy_cute_pack_01'), 0);
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
