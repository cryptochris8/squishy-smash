import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/economy_config.dart';
import 'package:squishy_smash/data/models/liveops_schedule.dart';
import 'package:squishy_smash/data/pack_milestones.dart';
import 'package:squishy_smash/data/persistence.dart';
import 'package:squishy_smash/data/repositories/pack_repository.dart';
import 'package:squishy_smash/data/repositories/progression_repo.dart';

const _milestones25 = PackMilestone(percent: 25, coinReward: 50);
const _milestones50 = PackMilestone(percent: 50, coinReward: 100);
const _milestones75 = PackMilestone(percent: 75, coinReward: 200);
const _milestones100 = PackMilestone(percent: 100, coinReward: 500);
const _allTiers = [
  _milestones25,
  _milestones50,
  _milestones75,
  _milestones100,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('packMilestoneClaimKey format', () {
    test('uses "packId:percent" — pinning the contract', () {
      // Both pack_milestones.dart and ProgressionRepository use this
      // key shape. If we ever change it, both readers must change in
      // lockstep — pinning here catches a one-sided edit.
      expect(
        packMilestoneClaimKey(packId: 'launch_squishy_foods', percent: 50),
        'launch_squishy_foods:50',
      );
    });
  });

  group('evaluatePackMilestoneCrossings', () {
    test('fires only milestones whose threshold has been reached', () {
      // Player at 12/16 = 75% — should fire 25, 50, 75 but not 100.
      final newCrossings = evaluatePackMilestoneCrossings(
        packId: 'launch_squishy_foods',
        discoveredCount: 12,
        totalInPack: 16,
        alreadyClaimedKeys: const <String>{},
        milestones: _allTiers,
      );
      expect(newCrossings.map((m) => m.percent), [25, 50, 75]);
    });

    test('skips already-claimed milestones (idempotent re-evaluation)',
        () {
      // Same 75% state but the player has claimed 25/50 already.
      // Only 75 should fire.
      final newCrossings = evaluatePackMilestoneCrossings(
        packId: 'launch_squishy_foods',
        discoveredCount: 12,
        totalInPack: 16,
        alreadyClaimedKeys: const {
          'launch_squishy_foods:25',
          'launch_squishy_foods:50',
        },
        milestones: _allTiers,
      );
      expect(newCrossings.map((m) => m.percent), [75]);
    });

    test('returns empty when no milestones are configured', () {
      final newCrossings = evaluatePackMilestoneCrossings(
        packId: 'launch_squishy_foods',
        discoveredCount: 16,
        totalInPack: 16,
        alreadyClaimedKeys: const <String>{},
        milestones: const <PackMilestone>[],
      );
      expect(newCrossings, isEmpty);
    });

    test('safely handles totalInPack=0 (no divide-by-zero)', () {
      final newCrossings = evaluatePackMilestoneCrossings(
        packId: 'empty_pack',
        discoveredCount: 0,
        totalInPack: 0,
        alreadyClaimedKeys: const <String>{},
        milestones: _allTiers,
      );
      expect(newCrossings, isEmpty);
    });

    test('boundary: exactly 25% fires the 25% milestone', () {
      // 4/16 = 25% — the threshold itself should trigger.
      final newCrossings = evaluatePackMilestoneCrossings(
        packId: 'launch_squishy_foods',
        discoveredCount: 4,
        totalInPack: 16,
        alreadyClaimedKeys: const <String>{},
        milestones: _allTiers,
      );
      expect(newCrossings.map((m) => m.percent), [25]);
    });

    test('rounds down: 3/16 (18%) does NOT fire the 25% milestone', () {
      // (100 * 3) ~/ 16 = 18, below 25.
      final newCrossings = evaluatePackMilestoneCrossings(
        packId: 'launch_squishy_foods',
        discoveredCount: 3,
        totalInPack: 16,
        alreadyClaimedKeys: const <String>{},
        milestones: _allTiers,
      );
      expect(newCrossings, isEmpty);
    });

    test('isolates packs — same percent on different packs are '
        'independent', () {
      final newCrossings = evaluatePackMilestoneCrossings(
        packId: 'goo_fidgets_drop_01',
        discoveredCount: 8,
        totalInPack: 16,
        // The 50% milestone has been claimed for a DIFFERENT pack.
        alreadyClaimedKeys: const {'launch_squishy_foods:50'},
        milestones: _allTiers,
      );
      expect(newCrossings.map((m) => m.percent), [25, 50]);
    });
  });

  group('ProgressionRepository.awardPackMilestone', () {
    Future<ProgressionRepository> open() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final p = await Persistence.open();
      final packs = PackRepository(
        <ContentPack>[],
        LiveOpsSchedule.fromJson(const {'featuredRotation': []}),
      );
      return ProgressionRepository(p, packs);
    }

    test('first call adds the key + awards coins', () async {
      final repo = await open();
      expect(repo.profile.coins, 0);
      final landed = repo.awardPackMilestone(
        packId: 'launch_squishy_foods',
        milestone: _milestones50,
      );
      expect(landed, isTrue);
      expect(repo.profile.coins, 100);
      expect(
        repo.profile.packMilestonesClaimed,
        contains('launch_squishy_foods:50'),
      );
    });

    test('second call is a no-op (idempotent — no double-grant)',
        () async {
      final repo = await open();
      repo.awardPackMilestone(
        packId: 'launch_squishy_foods',
        milestone: _milestones50,
      );
      // Second call same args.
      final landed = repo.awardPackMilestone(
        packId: 'launch_squishy_foods',
        milestone: _milestones50,
      );
      expect(landed, isFalse);
      expect(repo.profile.coins, 100,
          reason: 'idempotent — coins must not double-grant');
    });

    test('different milestones on the same pack each fire', () async {
      final repo = await open();
      repo.awardPackMilestone(
        packId: 'launch_squishy_foods',
        milestone: _milestones25,
      );
      repo.awardPackMilestone(
        packId: 'launch_squishy_foods',
        milestone: _milestones100,
      );
      expect(repo.profile.coins, 50 + 500);
      expect(repo.profile.packMilestonesClaimed, {
        'launch_squishy_foods:25',
        'launch_squishy_foods:100',
      });
    });
  });
}
