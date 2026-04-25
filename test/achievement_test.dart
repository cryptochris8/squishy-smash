import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/data/achievement_detector.dart';
import 'package:squishy_smash/data/achievement_registry.dart';
import 'package:squishy_smash/data/models/achievement.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/liveops_schedule.dart';
import 'package:squishy_smash/data/models/player_profile.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/persistence.dart';
import 'package:squishy_smash/data/repositories/pack_repository.dart';
import 'package:squishy_smash/data/repositories/progression_repo.dart';

LiveOpsSchedule _emptySchedule() =>
    LiveOpsSchedule.fromJson(const {'featuredRotation': []});

Future<ProgressionRepository> _open() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final persistence = await Persistence.open();
  final packs = PackRepository(<ContentPack>[], _emptySchedule());
  return ProgressionRepository(persistence, packs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Achievement criteria evaluation', () {
    test('FirstBurstCriteria — false when discovered set is empty', () {
      final p = PlayerProfile.empty();
      expect(const FirstBurstCriteria().isMetBy(p), isFalse);
    });

    test('FirstBurstCriteria — true after any discovery', () {
      final p = PlayerProfile.empty()
        ..discoveredSmashableIds.add('dumplio');
      expect(const FirstBurstCriteria().isMetBy(p), isTrue);
    });

    test('StreakCriteria checks longestStreak (so trophy is sticky)', () {
      final p = PlayerProfile.empty()
        ..currentStreak = 1 // streak broken today
        ..longestStreak = 7; // but the lifetime peak is still 7
      expect(const StreakCriteria(7).isMetBy(p), isTrue);
      expect(const StreakCriteria(14).isMetBy(p), isFalse);
    });

    test('BestComboCriteria triggers at exactly the threshold', () {
      final p = PlayerProfile.empty()..bestCombo = 15;
      expect(const BestComboCriteria(15).isMetBy(p), isTrue);
      expect(const BestComboCriteria(16).isMetBy(p), isFalse);
    });

    test('BestScoreCriteria triggers at exactly the threshold', () {
      final p = PlayerProfile.empty()..bestScore = 1000;
      expect(const BestScoreCriteria(1000).isMetBy(p), isTrue);
      expect(const BestScoreCriteria(1001).isMetBy(p), isFalse);
    });

    test('TotalBurstsCriteria sums across all packs', () {
      final p = PlayerProfile.empty()
        ..totalBurstsByPack.addAll({
          'launch_squishy_foods': 60,
          'goo_fidgets_drop_01': 30,
          'creepy_cute_pack_01': 20,
        });
      // Total = 110 ≥ 100
      expect(const TotalBurstsCriteria(100).isMetBy(p), isTrue);
      expect(const TotalBurstsCriteria(200).isMetBy(p), isFalse);
    });

    test('FirstMythicEverCriteria — only Mythic counts', () {
      final p = PlayerProfile.empty()..rarestSeen = Rarity.epic;
      expect(const FirstMythicEverCriteria().isMetBy(p), isFalse);
      p.rarestSeen = Rarity.mythic;
      expect(const FirstMythicEverCriteria().isMetBy(p), isTrue);
    });
  });

  group('AchievementDetector', () {
    test('returns achievements that are met but not yet claimed', () {
      const detector = AchievementDetector();
      final p = PlayerProfile.empty()
        ..discoveredSmashableIds.add('dumplio')
        ..bestCombo = 15;
      final eligible = detector.detectEligible(
        achievements: starterAchievements,
        profile: p,
      );
      final ids = eligible.map((a) => a.id).toSet();
      expect(ids, containsAll({'first_burst', 'combo_15'}));
      expect(ids, isNot(contains('streak_5')),
          reason: 'streak not met');
    });

    test('skips achievements already in claimedAchievements', () {
      const detector = AchievementDetector();
      final p = PlayerProfile.empty()
        ..discoveredSmashableIds.add('dumplio')
        ..claimedAchievements.add('first_burst');
      final eligible = detector.detectEligible(
        achievements: starterAchievements,
        profile: p,
      );
      expect(eligible.any((a) => a.id == 'first_burst'), isFalse,
          reason: 'already claimed — must not return again');
    });

    test('returns nothing on a fresh profile (no criteria met yet)', () {
      const detector = AchievementDetector();
      final eligible = detector.detectEligible(
        achievements: starterAchievements,
        profile: PlayerProfile.empty(),
      );
      expect(eligible, isEmpty);
    });
  });

  group('starterAchievements registry shape', () {
    test('exposes exactly 8 achievements', () {
      expect(starterAchievements, hasLength(8));
    });

    test('every achievement id is unique', () {
      final ids = starterAchievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every name and description is non-empty', () {
      for (final a in starterAchievements) {
        expect(a.name, isNotEmpty, reason: a.id);
        expect(a.description, isNotEmpty, reason: a.id);
      }
    });

    test('any CardUnlockReward references a valid manifest format', () {
      // Pin the format so a typo in the registry doesn't silently
      // produce a card_number that no CardEntry will ever match.
      for (final a in starterAchievements) {
        final r = a.reward;
        if (r is CardUnlockReward) {
          expect(r.cardNumber, matches(RegExp(r'^\d{3}/048$')),
              reason: '${a.id} has malformed cardNumber: ${r.cardNumber}');
        }
      }
    });
  });

  group('ProgressionRepository.grantAchievement', () {
    test('claims the achievement and applies a coin reward', () async {
      final repo = await _open();
      const ach = Achievement(
        id: 'test_coins',
        name: 'Test Coins',
        description: 'd',
        criteria: FirstBurstCriteria(),
        reward: CoinReward(50),
      );
      expect(repo.profile.coins, 0);
      final result = await repo.grantAchievement(ach);
      expect(result, isA<CoinReward>());
      expect(repo.profile.coins, 50);
      expect(repo.hasClaimedAchievement('test_coins'), isTrue);
    });

    test('claims the achievement and grants a guaranteed-reveal token',
        () async {
      final repo = await _open();
      const ach = Achievement(
        id: 'test_token',
        name: 'Test Token',
        description: 'd',
        criteria: FirstBurstCriteria(),
        reward: GuaranteedRevealReward(tier: Rarity.epic, count: 2),
      );
      final result = await repo.grantAchievement(ach);
      expect(result, isA<GuaranteedRevealReward>());
      expect(repo.guaranteedRevealsOf(Rarity.epic), 2);
    });

    test('claims the achievement and registers a card unlock', () async {
      final repo = await _open();
      const ach = Achievement(
        id: 'test_card',
        name: 'Test Card',
        description: 'd',
        criteria: FirstBurstCriteria(),
        reward: CardUnlockReward('048/048'),
      );
      final result = await repo.grantAchievement(ach);
      expect(result, isA<CardUnlockReward>());
      // Card unlock derives from claimed achievement set.
      final unlocked = unlockedCardNumbersFromAchievements(
        achievements: [ach],
        claimedIds: repo.profile.claimedAchievements,
      );
      expect(unlocked, contains('048/048'));
    });

    test('is idempotent — second grant returns null, no double reward',
        () async {
      final repo = await _open();
      const ach = Achievement(
        id: 'test_idem',
        name: 'Test',
        description: 'd',
        criteria: FirstBurstCriteria(),
        reward: CoinReward(75),
      );
      expect(await repo.grantAchievement(ach), isA<CoinReward>());
      expect(repo.profile.coins, 75);
      // Second call: already claimed → no-op, no extra coins.
      expect(await repo.grantAchievement(ach), isNull);
      expect(repo.profile.coins, 75);
    });
  });

  group('unlockedCardNumbersFromAchievements derivation', () {
    test('returns empty when no achievements have been claimed', () {
      final unlocked = unlockedCardNumbersFromAchievements(
        achievements: starterAchievements,
        claimedIds: const <String>{},
      );
      expect(unlocked, isEmpty);
    });

    test('returns only card_numbers from CardUnlockReward achievements',
        () {
      final unlocked = unlockedCardNumbersFromAchievements(
        achievements: starterAchievements,
        // Claim the streak_5 (token reward) and first_mythic_ever
        // (card reward).
        claimedIds: const {'streak_5', 'first_mythic_ever'},
      );
      // streak_5 contributes nothing (not a CardUnlockReward).
      // first_mythic_ever contributes 048/048.
      expect(unlocked, {'048/048'});
    });

    test('ignores claimed achievements that have non-card rewards', () {
      // All 7 non-card-reward achievements claimed: should yield empty.
      final claimed = starterAchievements
          .where((a) => a.reward is! CardUnlockReward)
          .map((a) => a.id)
          .toSet();
      final unlocked = unlockedCardNumbersFromAchievements(
        achievements: starterAchievements,
        claimedIds: claimed,
      );
      expect(unlocked, isEmpty);
    });
  });
}
