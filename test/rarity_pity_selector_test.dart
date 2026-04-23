import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/models/smashable_def.dart';
import 'package:squishy_smash/game/systems/rarity_pity_selector.dart';

SmashableDef _def(String id, Rarity rarity) => SmashableDef.fromJson({
      'id': id,
      'name': id,
      'category': 'test',
      'themeTag': 'test',
      'sprite': 'assets/images/objects/$id.png',
      'thumbnail': 'assets/images/thumbnails/${id}_thumb.png',
      'deformability': 0.5,
      'elasticity': 0.5,
      'burstThreshold': 0.7,
      'gooLevel': 0.5,
      'impactSounds': <String>['audio/test/$id.mp3'],
      'burstSound': 'audio/test/${id}_burst.mp3',
      'particlePreset': 'test_burst',
      'decalPreset': 'test_splat',
      'coinReward': 1,
      'unlockTier': 0,
      'searchTags': <String>[],
      'rarity': rarity.token,
    });

void main() {
  final pool = <SmashableDef>[
    _def('c1', Rarity.common),
    _def('c2', Rarity.common),
    _def('r1', Rarity.rare),
    _def('e1', Rarity.epic),
    _def('m1', Rarity.mythic),
  ];

  group('RarityPitySelector.pick', () {
    test('throws on empty pool', () {
      expect(
        () => const RarityPitySelector().pick(
          pool: const <SmashableDef>[],
          rollsSinceRare: 0,
          rollsSinceEpic: 0,
          rollsSinceMythic: 0,
        ),
        throwsArgumentError,
      );
    });

    test('default counters + combo 1 respects base weight distribution', () {
      final selector = const RarityPitySelector();
      final rng = Random(1);
      final counts = <Rarity, int>{
        Rarity.common: 0,
        Rarity.rare: 0,
        Rarity.epic: 0,
        Rarity.mythic: 0,
      };
      for (var i = 0; i < 20000; i++) {
        final pick = selector.pick(
          pool: pool,
          rollsSinceRare: 0,
          rollsSinceEpic: 0,
          rollsSinceMythic: 0,
          rng: rng,
        );
        counts[pick.rarity] = counts[pick.rarity]! + 1;
      }
      // Common dominates (2 commons × 750), rare is clearly present,
      // mythic is the rarest. Just assert ordering, not exact rates.
      expect(counts[Rarity.common]!, greaterThan(counts[Rarity.rare]!));
      expect(counts[Rarity.rare]!, greaterThan(counts[Rarity.epic]!));
      expect(counts[Rarity.epic]!, greaterThan(counts[Rarity.mythic]!));
    });

    test('rare hard pity excludes commons once the floor is hit', () {
      final selector = const RarityPitySelector();
      final rng = Random(99);
      for (var i = 0; i < 500; i++) {
        final pick = selector.pick(
          pool: pool,
          rollsSinceRare: selector.rareHardPity, // at the hard floor
          rollsSinceEpic: 0,
          rollsSinceMythic: 0,
          rng: rng,
        );
        expect(
          pick.rarity.index,
          greaterThanOrEqualTo(Rarity.rare.index),
          reason: 'hard pity should force rare+, got ${pick.rarity}',
        );
      }
    });

    test('epic hard pity forces epic or mythic', () {
      final selector = const RarityPitySelector();
      final rng = Random(7);
      for (var i = 0; i < 500; i++) {
        final pick = selector.pick(
          pool: pool,
          rollsSinceRare: 1000,
          rollsSinceEpic: selector.epicHardPity,
          rollsSinceMythic: 0,
          rng: rng,
        );
        expect(
          pick.rarity.index,
          greaterThanOrEqualTo(Rarity.epic.index),
          reason: 'epic hard pity should force epic+, got ${pick.rarity}',
        );
      }
    });

    test('mythic hard pity forces mythic', () {
      final selector = const RarityPitySelector();
      final rng = Random(3);
      for (var i = 0; i < 200; i++) {
        final pick = selector.pick(
          pool: pool,
          rollsSinceRare: 99999,
          rollsSinceEpic: 99999,
          rollsSinceMythic: selector.mythicHardPity,
          rng: rng,
        );
        expect(pick.rarity, Rarity.mythic);
      }
    });

    test('soft pity increases rare rate between soft and hard floors', () {
      final selector = const RarityPitySelector();

      int rareHits({required int rollsSinceRare}) {
        final rng = Random(42);
        var hits = 0;
        for (var i = 0; i < 20000; i++) {
          final pick = selector.pick(
            pool: pool,
            rollsSinceRare: rollsSinceRare,
            rollsSinceEpic: 0,
            rollsSinceMythic: 0,
            rng: rng,
          );
          if (pick.rarity.index >= Rarity.rare.index) hits++;
        }
        return hits;
      }

      final baseline = rareHits(rollsSinceRare: 0);
      final midSoft = rareHits(
        rollsSinceRare:
            (selector.rareSoftPity + selector.rareHardPity) ~/ 2,
      );
      expect(midSoft, greaterThan(baseline),
          reason: 'soft pity should raise rare+ rate');
    });

    test('combo multiplier boosts rare+ rate at fixed counters', () {
      final selector = const RarityPitySelector();

      int rareHits({required int comboMultiplier}) {
        final rng = Random(11);
        var hits = 0;
        for (var i = 0; i < 20000; i++) {
          final pick = selector.pick(
            pool: pool,
            rollsSinceRare: 0,
            rollsSinceEpic: 0,
            rollsSinceMythic: 0,
            comboMultiplier: comboMultiplier,
            rng: rng,
          );
          if (pick.rarity.index >= Rarity.rare.index) hits++;
        }
        return hits;
      }

      final base = rareHits(comboMultiplier: 1);
      final boosted = rareHits(comboMultiplier: 8);
      // Combo 8 with 0.2/step = 2.4× weight on rare+, should produce
      // materially more rare+ hits than combo 1.
      expect(boosted, greaterThan((base * 1.5).round()),
          reason: 'combo 8 should at least 1.5× the baseline rare+ rate');
    });

    test('deterministic with a seeded RNG', () {
      final selector = const RarityPitySelector();
      List<String> run(int seed) {
        final rng = Random(seed);
        return List.generate(
          40,
          (_) => selector.pick(
            pool: pool,
            rollsSinceRare: 5,
            rollsSinceEpic: 10,
            rollsSinceMythic: 20,
            comboMultiplier: 3,
            rng: rng,
          ).id,
        );
      }

      expect(run(123), run(123));
      expect(run(123), isNot(equals(run(124))));
    });

    test('common-only pool under hard pity degrades to uniform pick', () {
      final selector = const RarityPitySelector();
      final commonOnly = <SmashableDef>[
        _def('c1', Rarity.common),
        _def('c2', Rarity.common),
      ];
      final rng = Random(0);
      // Hard pity wants to exclude commons, but with no rare+ in the
      // pool the weightedPick all-zero fallback should keep us alive.
      final pick = selector.pick(
        pool: commonOnly,
        rollsSinceRare: selector.rareHardPity * 10,
        rollsSinceEpic: 0,
        rollsSinceMythic: 0,
        rng: rng,
      );
      expect(pick.rarity, Rarity.common);
    });
  });

  group('RarityPitySelector.advanceCounters', () {
    const selector = RarityPitySelector();

    test('common pick increments all three counters', () {
      final (r, e, m) = selector.advanceCounters(
        pickedRarity: Rarity.common,
        rollsSinceRare: 4,
        rollsSinceEpic: 10,
        rollsSinceMythic: 50,
      );
      expect(r, 5);
      expect(e, 11);
      expect(m, 51);
    });

    test('rare pick resets rare, increments epic and mythic', () {
      final (r, e, m) = selector.advanceCounters(
        pickedRarity: Rarity.rare,
        rollsSinceRare: 12,
        rollsSinceEpic: 30,
        rollsSinceMythic: 100,
      );
      expect(r, 0);
      expect(e, 31);
      expect(m, 101);
    });

    test('epic pick resets rare and epic, increments mythic', () {
      final (r, e, m) = selector.advanceCounters(
        pickedRarity: Rarity.epic,
        rollsSinceRare: 12,
        rollsSinceEpic: 30,
        rollsSinceMythic: 100,
      );
      expect(r, 0);
      expect(e, 0);
      expect(m, 101);
    });

    test('mythic pick resets all three counters', () {
      final (r, e, m) = selector.advanceCounters(
        pickedRarity: Rarity.mythic,
        rollsSinceRare: 12,
        rollsSinceEpic: 30,
        rollsSinceMythic: 100,
      );
      expect(r, 0);
      expect(e, 0);
      expect(m, 0);
    });
  });
}
