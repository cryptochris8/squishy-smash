import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/models/smashable_def.dart';
import 'package:squishy_smash/game/systems/pack_progression_gate.dart';
import 'package:squishy_smash/game/systems/rarity_pity_selector.dart';

Map<String, dynamic> _smashableJson(String id, Rarity rarity) => {
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
      'impactSounds': ['audio/test/$id.mp3'],
      'burstSound': 'audio/test/${id}_burst.mp3',
      'particlePreset': 'test',
      'decalPreset': 'test',
      'coinReward': 1,
      'unlockTier': 0,
      'searchTags': <String>[],
      'rarity': rarity.token,
    };

/// Build a ContentPack with the given tier composition. Uses code-
/// default PackProgression (base odds 68/22/8/2, pity 5-7/14-20/25-50).
ContentPack _pack(String id, {int c = 8, int r = 4, int e = 3, int m = 1}) {
  final objects = <Map<String, dynamic>>[];
  for (var i = 0; i < c; i++) {
    objects.add(_smashableJson('${id}_c$i', Rarity.common));
  }
  for (var i = 0; i < r; i++) {
    objects.add(_smashableJson('${id}_r$i', Rarity.rare));
  }
  for (var i = 0; i < e; i++) {
    objects.add(_smashableJson('${id}_e$i', Rarity.epic));
  }
  for (var i = 0; i < m; i++) {
    objects.add(_smashableJson('${id}_m$i', Rarity.mythic));
  }
  return ContentPack.fromJson({
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
    'unlockCost': 0,
    'objects': objects,
  });
}

List<GatedObject> _poolFor(ContentPack pack) => [
      for (final o in pack.objects) GatedObject(def: o, pack: pack),
    ];

SmashableDef _pick(RarityPitySelector selector, List<GatedObject> pool,
    {required int seed,
    int rareDry = 0,
    int epicDry = 0,
    int legendaryDry = 0,
    int combo = 1,
    required String packId}) {
  return selector.pick(
    pool: pool,
    rareDryByPack: {packId: rareDry},
    epicDryByPack: {packId: epicDry},
    legendaryDryByPack: {packId: legendaryDry},
    comboMultiplier: combo,
    rng: Random(seed),
  );
}

void main() {
  final pack = _pack('test');
  final pool = _poolFor(pack);

  group('RarityPitySelector.pick basic behavior', () {
    test('throws on empty pool', () {
      expect(
        () => const RarityPitySelector().pick(
          pool: const <GatedObject>[],
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
        ),
        throwsArgumentError,
      );
    });

    test('default counters + combo 1 approximates 68/22/8/2 tier odds', () {
      const selector = RarityPitySelector();
      final rng = Random(1);
      final counts = <Rarity, int>{
        for (final r in Rarity.values) r: 0,
      };
      const trials = 20000;
      for (var i = 0; i < trials; i++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          rng: rng,
        );
        counts[pick.rarity] = counts[pick.rarity]! + 1;
      }
      // Expect roughly 68/22/8/2 ± noise. Wide bands to avoid flakes.
      expect(counts[Rarity.common]! / trials, closeTo(0.68, 0.03));
      expect(counts[Rarity.rare]! / trials, closeTo(0.22, 0.03));
      expect(counts[Rarity.epic]! / trials, closeTo(0.08, 0.02));
      expect(counts[Rarity.mythic]! / trials, closeTo(0.02, 0.01));
    });

    test('deterministic with a seeded RNG', () {
      const selector = RarityPitySelector();
      List<String> run(int seed) {
        final rng = Random(seed);
        return List.generate(
          40,
          (_) => selector.pick(
            pool: pool,
            rareDryByPack: const {'test': 3},
            epicDryByPack: const {'test': 5},
            legendaryDryByPack: const {'test': 10},
            comboMultiplier: 3,
            rng: rng,
          ).id,
        );
      }

      expect(run(123), run(123));
      expect(run(123), isNot(equals(run(124))));
    });
  });

  group('RarityPitySelector.pick hard-pity exclusion', () {
    const selector = RarityPitySelector();

    test('rare hard pity excludes commons — always returns rare+', () {
      // rareHard defaults to 7; set rareDry above that.
      for (var seed = 0; seed < 50; seed++) {
        final pick = _pick(selector, pool,
            seed: seed, rareDry: 7, packId: 'test');
        expect(pick.rarity.index, greaterThanOrEqualTo(Rarity.rare.index),
            reason: 'hard-pity should force rare+ (seed $seed)');
      }
    });

    test('epic hard pity forces epic or legendary', () {
      for (var seed = 0; seed < 50; seed++) {
        final pick = _pick(selector, pool,
            seed: seed,
            rareDry: 1000,
            epicDry: 20,
            packId: 'test');
        expect(pick.rarity.index, greaterThanOrEqualTo(Rarity.epic.index));
      }
    });

    test('legendary hard pity forces mythic', () {
      for (var seed = 0; seed < 50; seed++) {
        final pick = _pick(selector, pool,
            seed: seed,
            rareDry: 9999,
            epicDry: 9999,
            legendaryDry: 50,
            packId: 'test');
        expect(pick.rarity, Rarity.mythic);
      }
    });
  });

  group('RarityPitySelector.pick soft pity + combo boost', () {
    const selector = RarityPitySelector();

    int rareHitsAcross(
      int trials, {
      required int rareDry,
      int combo = 1,
    }) {
      final rng = Random(42);
      var hits = 0;
      for (var i = 0; i < trials; i++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: {'test': rareDry},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          comboMultiplier: combo,
          rng: rng,
        );
        if (pick.rarity.index >= Rarity.rare.index) hits++;
      }
      return hits;
    }

    test('soft pity ramps rare rate between soft and hard floors', () {
      final baseline = rareHitsAcross(20000, rareDry: 0);
      final midRamp = rareHitsAcross(20000, rareDry: 6); // between 5 and 7
      expect(midRamp, greaterThan(baseline),
          reason: 'soft pity should lift rare rate after the soft floor');
    });

    test('combo multiplier boosts rare rate at fixed dry counters', () {
      final base = rareHitsAcross(20000, rareDry: 0, combo: 1);
      final boosted = rareHitsAcross(20000, rareDry: 0, combo: 8);
      expect(boosted, greaterThan((base * 1.2).round()),
          reason: 'combo 8 should materially outpace combo 1');
    });
  });

  group('RarityPitySelector boost token', () {
    const selector = RarityPitySelector();

    int rareHits({required bool boost}) {
      final rng = Random(77);
      var hits = 0;
      for (var i = 0; i < 20000; i++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          boostActive: boost,
          rng: rng,
        );
        if (pick.rarity.index >= Rarity.rare.index) hits++;
      }
      return hits;
    }

    test('boost token boosts rare+ rate versus no boost', () {
      final without = rareHits(boost: false);
      final with_ = rareHits(boost: true);
      expect(with_, greaterThan(without),
          reason: 'boost token should materially lift rare+ rate');
      // +50% on rare+ weights should push the ratio up meaningfully.
      expect(with_ / without, greaterThan(1.1));
    });

    test('boost token does not affect common weight', () {
      // Commons should be a smaller share of picks when boosted.
      final rngBase = Random(101);
      var baseCommons = 0;
      for (var i = 0; i < 10000; i++) {
        final p = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          boostActive: false,
          rng: rngBase,
        );
        if (p.rarity == Rarity.common) baseCommons++;
      }
      final rngBoost = Random(101);
      var boostCommons = 0;
      for (var i = 0; i < 10000; i++) {
        final p = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          boostActive: true,
          rng: rngBoost,
        );
        if (p.rarity == Rarity.common) boostCommons++;
      }
      expect(boostCommons, lessThan(baseCommons));
    });
  });

  group('RarityPitySelector fallback behavior', () {
    test('empty pool after all-zero weights falls back to uniform pick', () {
      // Craft a pack where the only tier present is common, then force
      // rare hard pity — commons get zeroed, so no non-zero weights.
      final commonOnly = _pack('commons_only', c: 3, r: 0, e: 0, m: 0);
      final commonPool = _poolFor(commonOnly);
      const selector = RarityPitySelector();
      // Sanity: should still produce a pick rather than crash.
      final pick = selector.pick(
        pool: commonPool,
        rareDryByPack: const {'commons_only': 100},
        epicDryByPack: const {},
        legendaryDryByPack: const {},
        rng: Random(0),
      );
      expect(pick.rarity, Rarity.common);
    });
  });

  group('RarityPitySelector.advanceCountersForPack', () {
    const selector = RarityPitySelector();

    test('common pick increments all three counters', () {
      final (r, e, m) = selector.advanceCountersForPack(
        pickedRarity: Rarity.common,
        rareDry: 4,
        epicDry: 10,
        legendaryDry: 25,
      );
      expect(r, 5);
      expect(e, 11);
      expect(m, 26);
    });

    test('rare pick resets rare, increments epic + legendary', () {
      final (r, e, m) = selector.advanceCountersForPack(
        pickedRarity: Rarity.rare,
        rareDry: 6,
        epicDry: 18,
        legendaryDry: 40,
      );
      expect(r, 0);
      expect(e, 19);
      expect(m, 41);
    });

    test('epic pick resets rare + epic, increments legendary', () {
      final (r, e, m) = selector.advanceCountersForPack(
        pickedRarity: Rarity.epic,
        rareDry: 6,
        epicDry: 18,
        legendaryDry: 40,
      );
      expect(r, 0);
      expect(e, 0);
      expect(m, 41);
    });

    test('mythic (legendary) resets all three', () {
      final (r, e, m) = selector.advanceCountersForPack(
        pickedRarity: Rarity.mythic,
        rareDry: 6,
        epicDry: 18,
        legendaryDry: 40,
      );
      expect(r, 0);
      expect(e, 0);
      expect(m, 0);
    });
  });
}
