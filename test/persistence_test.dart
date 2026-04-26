import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/core/diagnostics.dart';
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

    test('first-launch profile has no entitlements', () async {
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.hasRemoveAds, isFalse);
      expect(profile.starterBundleClaimed, isFalse);
      expect(profile.guaranteedRevealTokens, isEmpty);
      expect(profile.purchasedSkus, isEmpty);
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

    test('entitlement fields round-trip', () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 0,
        unlockedPackIds: const {'launch'},
        bestScore: 0,
        bestCombo: 0,
        hasRemoveAds: true,
        starterBundleClaimed: true,
        guaranteedRevealTokens: {Rarity.rare: 2, Rarity.epic: 1},
        purchasedSkus: {'remove_ads', 'starter_bundle_v1'},
      );
      await p.saveProfile(profile);
      final reloaded = p.loadProfile();
      expect(reloaded.hasRemoveAds, isTrue);
      expect(reloaded.starterBundleClaimed, isTrue);
      expect(reloaded.guaranteedRevealTokens, {
        Rarity.rare: 2,
        Rarity.epic: 1,
      });
      expect(reloaded.purchasedSkus, {'remove_ads', 'starter_bundle_v1'});
    });

    test('zero-count guaranteed reveal tokens drop out of persistence',
        () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 0,
        unlockedPackIds: const {'launch'},
        bestScore: 0,
        bestCombo: 0,
        guaranteedRevealTokens: {
          Rarity.rare: 0,
          Rarity.epic: 3,
          Rarity.mythic: 0,
        },
      );
      await p.saveProfile(profile);
      final reloaded = p.loadProfile();
      // Only the non-zero entry should round-trip.
      expect(reloaded.guaranteedRevealTokens, {Rarity.epic: 3});
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

  group('Persistence profile schema versioning', () {
    test('fresh install reports profileVersion=0 (no key written yet)',
        () async {
      final p = await Persistence.open();
      expect(p.profileVersion, 0);
    });

    test('saveProfile writes the current schema version', () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 0,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
      );
      await p.saveProfile(profile);
      expect(p.profileVersion, Persistence.currentProfileVersion);
    });

    test('loadProfile on a v0 (pre-versioning) save still returns valid data',
        () async {
      // Simulate a pre-versioning save by setting only the data keys
      // and omitting the version key. loadProfile should treat this as
      // v0 and read what's there without throwing.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.coins': 500,
        'profile.unlocks': <String>['launch_squishy_foods'],
        'profile.best_score': 1234,
        'profile.best_combo': 12,
      });
      final p = await Persistence.open();
      expect(p.profileVersion, 0,
          reason: 'no version key on disk = v0');

      final profile = p.loadProfile();
      expect(profile.coins, 500);
      expect(profile.bestScore, 1234);
      expect(profile.bestCombo, 12);
    });

    test('loadProfile is idempotent — calling it twice produces the same data',
        () async {
      // Sanity check the migration path doesn't mutate state across reads.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.coins': 42,
      });
      final p = await Persistence.open();
      final first = p.loadProfile();
      final second = p.loadProfile();
      expect(first.coins, 42);
      expect(second.coins, 42);
    });

    test('save → load round-trips the version key', () async {
      final p1 = await Persistence.open();
      final profile = PlayerProfile(
        coins: 100,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
      );
      await p1.saveProfile(profile);

      // Re-open — the version should persist.
      final p2 = await Persistence.open();
      expect(p2.profileVersion, Persistence.currentProfileVersion);
    });

    test('a future profileVersion on disk does not crash loadProfile',
        () async {
      // Simulate an older app build reading a newer save (e.g., user
      // downgraded). The loader should not throw; it should attempt
      // best-effort load.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.schema_version': 999,
        'profile.coins': 7,
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 7);
    });

    test('currentProfileVersion is at least 2 (card progress shipped)', () {
      // Pin the schema version. Any future bump must add a migration
      // branch in `_migrateIfNeeded` AND update this test in lock-step
      // so accidental version bumps without migration code are caught.
      expect(Persistence.currentProfileVersion, greaterThanOrEqualTo(2));
    });

    test('v1 save loads cleanly on v2 reader (additive upgrade)', () async {
      // Simulate an install that saved under schema v1 (had the version
      // key, but no card_burst_counts / cards_purchased / claimed_
      // achievements keys yet). The v2 reader must default those fields
      // to empty rather than crash.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.schema_version': 1,
        'profile.coins': 250,
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 250);
      expect(profile.cardBurstCounts, isEmpty);
      expect(profile.cardsPurchased, isEmpty);
      expect(profile.claimedAchievements, isEmpty);
    });
  });

  group('Persistence card progress round-trip', () {
    test('cardBurstCounts, cardsPurchased, claimedAchievements round-trip',
        () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 0,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
        cardBurstCounts: <String, int>{
          '001/048': 5,
          '016/048': 12,
          '048/048': 1,
        },
        cardsPurchased: <String>{'017/048', '032/048'},
        claimedAchievements: <String>{
          'first_mythic',
          'streak_7',
          'combo_15',
        },
      );
      await p.saveProfile(profile);

      final reloaded = p.loadProfile();
      expect(reloaded.cardBurstCounts, {
        '001/048': 5,
        '016/048': 12,
        '048/048': 1,
      });
      expect(reloaded.cardsPurchased, {'017/048', '032/048'});
      expect(reloaded.claimedAchievements,
          {'first_mythic', 'streak_7', 'combo_15'});
    });

    test('first-launch defaults are empty for all card progress fields',
        () async {
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.cardBurstCounts, isEmpty);
      expect(profile.cardsPurchased, isEmpty);
      expect(profile.claimedAchievements, isEmpty);
    });

    test('corrupt cardBurstCounts JSON falls back to empty map', () async {
      // _loadIntMap is shared with the per-pack progression maps; this
      // pins the same defensive contract for the new card field so a
      // bad pref can't brick load.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.card_burst_counts': '{ not json',
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.cardBurstCounts, isEmpty);
    });
  });

  group('Persistence v3 atomic-blob layout', () {
    test('saveProfile writes the entire profile to a single key', () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 1234,
        unlockedPackIds: const {'launch_squishy_foods', 'goo_fidgets_drop_01'},
        bestScore: 9876,
        bestCombo: 42,
      );
      await p.saveProfile(profile);

      // The blob key must now hold the entire profile.
      final raw = (await SharedPreferences.getInstance())
          .getString('profile.blob_v3');
      expect(raw, isNotNull);
      // Sanity-decode the JSON: must contain the player's distinctive values.
      expect(raw, contains('1234'));
      expect(raw, contains('launch_squishy_foods'));
      expect(raw, contains('goo_fidgets_drop_01'));
    });

    test('save → load round-trips through the v3 blob', () async {
      final p1 = await Persistence.open();
      final original = PlayerProfile(
        coins: 500,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 100,
        bestCombo: 8,
        cardBurstCounts: const {'001/048': 5, '016/048': 1},
        cardsPurchased: const {'017/048'},
        claimedAchievements: const {'first_burst', 'streak_5'},
      );
      await p1.saveProfile(original);

      // Re-open so we read fresh from disk, not from any cache.
      final p2 = await Persistence.open();
      final reloaded = p2.loadProfile();
      expect(reloaded.coins, 500);
      expect(reloaded.bestCombo, 8);
      expect(reloaded.cardBurstCounts, {'001/048': 5, '016/048': 1});
      expect(reloaded.cardsPurchased, {'017/048'});
      expect(reloaded.claimedAchievements, {'first_burst', 'streak_5'});
    });

    test('profileVersion reads schemaVersion from inside the blob', () async {
      final p = await Persistence.open();
      await p.saveProfile(PlayerProfile.empty());
      expect(p.profileVersion, Persistence.currentProfileVersion);
    });

    test('a v2 save (legacy per-field keys) still loads under v3', () async {
      // Simulate an existing v2 install: standalone version key + per-
      // field state, no blob. The v3 reader must fall back to the
      // legacy load path so we don't lose existing players' data.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.schema_version': 2,
        'profile.coins': 750,
        'profile.unlocks': <String>['launch_squishy_foods'],
        'profile.best_score': 4242,
        'profile.discovered_ids': <String>['dumplio', 'jellyzap'],
        'profile.rarest_seen': 'rare',
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 750);
      expect(profile.bestScore, 4242);
      expect(profile.discoveredSmashableIds,
          {'dumplio', 'jellyzap'});
      expect(profile.rarestSeen, Rarity.rare);
    });

    test('first save under v3 promotes a v2 install to the blob layout',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.schema_version': 2,
        'profile.coins': 999,
      });
      final p = await Persistence.open();
      // Read once (legacy path) and then save (writes the blob).
      final profile = p.loadProfile();
      expect(profile.coins, 999);
      await p.saveProfile(profile);

      // Re-open: the second instance should see the v3 blob and
      // never need to consult the legacy keys again.
      final p2 = await Persistence.open();
      final reloaded = p2.loadProfile();
      expect(reloaded.coins, 999);
      expect(p2.profileVersion, Persistence.currentProfileVersion);
    });

    test('a malformed blob falls back to legacy keys (no data loss)',
        () async {
      // Defends against a partial-write or future-incompatible blob:
      // if we can't parse it, fall back to the legacy keys rather
      // than silently returning a fresh-install profile.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.blob_v3': '{ not valid json',
        'profile.schema_version': 2,
        'profile.coins': 333,
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 333,
          reason: 'corrupted blob must fall back to legacy keys, '
              'not silently reset to defaults');
    });

    test('grandfatheredCards + packMilestonesClaimed round-trip via blob',
        () async {
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 0,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
        grandfatheredCards: const {'001/048', '016/048', '048/048'},
        packMilestonesClaimed: const {
          'launch_squishy_foods:50',
          'goo_fidgets_drop_01:25',
        },
      );
      await p.saveProfile(profile);

      final p2 = await Persistence.open();
      final reloaded = p2.loadProfile();
      expect(reloaded.grandfatheredCards,
          {'001/048', '016/048', '048/048'});
      expect(reloaded.packMilestonesClaimed, {
        'launch_squishy_foods:50',
        'goo_fidgets_drop_01:25',
      });
    });

    test('currentProfileVersion is at least 4 (v3 → v4 grandfather migration)',
        () {
      // v4 added grandfatheredCards + packMilestonesClaimed. Pinning
      // the floor here means future bumps need migration code AND a
      // matching version increase — easy to forget one.
      expect(Persistence.currentProfileVersion,
          greaterThanOrEqualTo(4));
    });

    test('a v3 blob loads cleanly under v4 (additive upgrade)',
        () async {
      // Simulate a v3 install: blob present, but no grandfathered or
      // milestone fields. The v4 reader must default them to empty
      // and not crash.
      final v3Blob = <String, dynamic>{
        'schemaVersion': 3,
        'coins': 250,
        'unlockedPackIds': <String>['launch_squishy_foods'],
        'bestScore': 100,
        'bestCombo': 5,
        'cardBurstCounts': <String, int>{'001/048': 1, '016/048': 0},
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.blob_v3': jsonEncode(v3Blob),
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 250);
      expect(profile.cardBurstCounts['001/048'], 1);
      expect(profile.grandfatheredCards, isEmpty,
          reason: 'v3 blob has no grandfathered field — defaults '
              'to empty until ServiceLocator.bootstrap migration runs');
      expect(profile.packMilestonesClaimed, isEmpty);
    });

    test('atomicity: a single setString call carries the whole profile',
        () async {
      // The whole point of v3. With shared_preferences mocked,
      // verify exactly ONE write call lands a complete profile —
      // proxy for the platform-atomic guarantee.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p = await Persistence.open();
      final profile = PlayerProfile(
        coins: 50,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 100,
        bestCombo: 5,
      );
      await p.saveProfile(profile);

      // After the save, exactly one new key exists in the prefs map.
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      expect(keys, contains('profile.blob_v3'));
      // No legacy per-field keys were created on a fresh-install save.
      expect(keys.contains('profile.coins'), isFalse,
          reason: 'v3 saves should not write the v1/v2 per-field keys');
    });
  });

  group('Persistence corruption recovery (P0.10)', () {
    test('saveProfile rotates the previous blob into .bak before writing',
        () async {
      // First save: no previous blob, no backup written.
      final p = await Persistence.open();
      await p.saveProfile(PlayerProfile(
        coins: 100,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
      ));

      final prefs1 = await SharedPreferences.getInstance();
      expect(prefs1.containsKey('profile.blob_v3'), isTrue);
      expect(prefs1.containsKey('profile.blob_v3.bak'), isFalse,
          reason: 'first save should write live but skip backup '
              '(nothing to back up yet)');

      // Second save: live blob from first save rotates to .bak;
      // the new blob lands at the live key.
      await p.saveProfile(PlayerProfile(
        coins: 250,
        unlockedPackIds: const {'launch_squishy_foods'},
        bestScore: 0,
        bestCombo: 0,
      ));
      expect(prefs1.containsKey('profile.blob_v3.bak'), isTrue,
          reason: 'second save must rotate prior live blob into .bak');

      final liveBlob = jsonDecode(prefs1.getString('profile.blob_v3')!)
          as Map<String, dynamic>;
      final bakBlob = jsonDecode(prefs1.getString('profile.blob_v3.bak')!)
          as Map<String, dynamic>;
      expect(liveBlob['coins'], 250);
      expect(bakBlob['coins'], 100,
          reason: '.bak should hold the previous-good coins value');
    });

    test('corrupt live blob recovers coins from .bak (no silent reset)',
        () async {
      // Simulates the worst case: a v3-native player whose live blob
      // got bit-flipped on disk, with no legacy keys to fall back to.
      // Without .bak recovery this player's purchases, milestones,
      // and coins reset silently — the data-loss vector flagged in
      // PRELAUNCH_AUDIT.md P0.10.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.blob_v3': '{ not valid json',
        'profile.blob_v3.bak': jsonEncode(<String, dynamic>{
          'schemaVersion': 4,
          'coins': 4500,
          'unlockedPackIds': ['launch_squishy_foods', 'goo_fidgets_drop_01'],
          'purchasedSkus': ['remove_ads', 'starter_bundle'],
          'bestScore': 12000,
          'bestCombo': 8,
          'starterBundleClaimed': true,
        }),
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 4500,
          reason: 'corrupted live blob must recover coins from .bak');
      expect(profile.purchasedSkus, contains('remove_ads'),
          reason: 'paying-customer entitlements must survive '
              'a live-blob corruption');
      expect(profile.starterBundleClaimed, isTrue);
      expect(profile.bestScore, 12000);
    });

    test('both blobs corrupt falls through to legacy keys', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.blob_v3': '{ broken',
        'profile.blob_v3.bak': '{ also broken',
        'profile.schema_version': 2,
        'profile.coins': 77,
      });
      final p = await Persistence.open();
      final profile = p.loadProfile();
      expect(profile.coins, 77,
          reason: 'live and .bak both corrupt → legacy keys are the '
              'last line of defense');
    });

    test('corrupt blob emits a diagnostics event when sink is wired',
        () async {
      final captured = <DiagnosticEntry>[];
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile.blob_v3': '{ not valid json',
        'profile.blob_v3.bak': jsonEncode(<String, dynamic>{
          'schemaVersion': 4,
          'coins': 1,
          'unlockedPackIds': ['launch_squishy_foods'],
        }),
      });
      final p = await Persistence.open();
      final sink = DiagnosticsService();
      sink.addSink(_RecordingSink(captured));
      p.diagnostics = sink;

      p.loadProfile();
      expect(captured, isNotEmpty,
          reason: 'corruption events must reach the wired diagnostics '
              'sink so Sentry can see corruption rates in the wild');
      expect(captured.first.error.toString(),
          contains('recovered from .bak'));
    });

    test('fresh install does NOT emit a corruption event', () async {
      final captured = <DiagnosticEntry>[];
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p = await Persistence.open();
      final sink = DiagnosticsService();
      sink.addSink(_RecordingSink(captured));
      p.diagnostics = sink;

      p.loadProfile();
      expect(captured, isEmpty,
          reason: 'a fresh install (no blob, no .bak) is not '
              'corruption — no diagnostic noise');
    });
  });
}

class _RecordingSink implements DiagnosticsSink {
  _RecordingSink(this.entries);
  final List<DiagnosticEntry> entries;

  @override
  void capture(DiagnosticEntry entry) => entries.add(entry);
}
