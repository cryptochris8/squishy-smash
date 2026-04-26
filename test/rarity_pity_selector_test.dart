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

  group('RarityPitySelector forced-rarity token', () {
    const selector = RarityPitySelector();

    test('forcing rare always returns a rare-or-better pick', () {
      for (var seed = 0; seed < 50; seed++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          forcedRarity: Rarity.rare,
          rng: Random(seed),
        );
        expect(pick.rarity.index, greaterThanOrEqualTo(Rarity.rare.index),
            reason: 'guaranteed-rare should never return a common (seed $seed)');
      }
    });

    test('forcing epic always returns an epic-or-better pick', () {
      for (var seed = 0; seed < 50; seed++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          forcedRarity: Rarity.epic,
          rng: Random(seed),
        );
        expect(pick.rarity.index, greaterThanOrEqualTo(Rarity.epic.index));
      }
    });

    test('forcing legendary always returns a legendary', () {
      for (var seed = 0; seed < 50; seed++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          forcedRarity: Rarity.mythic,
          rng: Random(seed),
        );
        expect(pick.rarity, Rarity.mythic);
      }
    });

    test('unsatisfiable force falls through to weighted selection', () {
      // A pool with no legendary — forcing legendary should not crash
      // or loop forever; it should quietly fall back to normal pick.
      final noLegendary = _poolFor(_pack('p2', c: 4, r: 2, e: 1, m: 0));
      final pick = selector.pick(
        pool: noLegendary,
        rareDryByPack: const {},
        epicDryByPack: const {},
        legendaryDryByPack: const {},
        forcedRarity: Rarity.mythic,
        rng: Random(42),
      );
      // Any tier other than mythic is acceptable here — the token
      // is effectively refunded (caller is responsible for not
      // consuming it if the pool was inadequate).
      expect(pick.rarity, isNot(Rarity.mythic));
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

  group('RarityPitySelector dropWeight as relative multiplier', () {
    /// Build a pack with two same-tier objects. `heavyMultiplier` is
    /// applied to the second one via `dropWeight`; the first is left
    /// unweighted so the per-object share is the natural 50/50.
    ContentPack twoCommonPack({required int heavyMultiplier}) {
      final light = _smashableJson('light_c', Rarity.common);
      final heavy = _smashableJson('heavy_c', Rarity.common)
        ..['dropWeight'] = heavyMultiplier;
      return ContentPack.fromJson({
        'packId': 'dropweight_test',
        'displayName': 'dropweight_test',
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
        'objects': [light, heavy],
      });
    }

    test('dropWeight=1 behaves like no override (~50/50 split)', () {
      final pool = _poolFor(twoCommonPack(heavyMultiplier: 1));
      const selector = RarityPitySelector();
      final rng = Random(7);
      var heavy = 0;
      const trials = 20000;
      for (var i = 0; i < trials; i++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          rng: rng,
        );
        if (pick.id == 'heavy_c') heavy++;
      }
      expect(heavy / trials, closeTo(0.5, 0.03),
          reason: 'dropWeight=1 should match an unweighted sibling');
    });

    test('dropWeight=3 makes the heavy object ~3x more likely', () {
      final pool = _poolFor(twoCommonPack(heavyMultiplier: 3));
      const selector = RarityPitySelector();
      final rng = Random(11);
      var heavy = 0;
      var light = 0;
      const trials = 20000;
      for (var i = 0; i < trials; i++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          rng: rng,
        );
        if (pick.id == 'heavy_c') {
          heavy++;
        } else {
          light++;
        }
      }
      // Heavy should be ~3x light: 75% / 25% split. Wide band so
      // RNG noise doesn't flake.
      expect(heavy / trials, closeTo(0.75, 0.03));
      expect(light / trials, closeTo(0.25, 0.03));
      expect(heavy / light, closeTo(3.0, 0.4),
          reason: 'dropWeight is a relative multiplier on tier share');
    });

    test('dropWeight=0 effectively disables the object', () {
      final pool = _poolFor(twoCommonPack(heavyMultiplier: 0));
      const selector = RarityPitySelector();
      final rng = Random(13);
      var heavy = 0;
      for (var i = 0; i < 5000; i++) {
        final pick = selector.pick(
          pool: pool,
          rareDryByPack: const {},
          epicDryByPack: const {},
          legendaryDryByPack: const {},
          rng: rng,
        );
        if (pick.id == 'heavy_c') heavy++;
      }
      expect(heavy, 0,
          reason: 'dropWeight=0 should never spawn (weight 0)');
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

  // P1.9 — gameplay-feel guard. The compounding boosts (soft pity +
  // combo + boost token) can multiply the legendary base rate of
  // 0.02 (1/50) several-fold; the audit measured up to ~3.9x at
  // combo 8 with token, hitting roughly 1/13. The intent is "magical
  // / rare" — i.e. ~1/200 sensation. These tests don't ASSERT a
  // specific cap (tuning is config-driven, see assets/data/economy.json),
  // but they pin the actual rate produced by current code so any
  // future tuning change has to deliberately move the test.
  //
  // Methodology: 10 000 picks per scenario, advancing dry counters
  // realistically between picks (so soft + hard pity participate as
  // they would in real play). The seeded Random per call gives
  // bit-identical output across CI runs.
  group('RarityPitySelector legendary distribution (P1.9)', () {
    /// Drives `iterations` picks and returns counts per tier. Pity
    /// counters advance between picks via the resetting rules so soft
    /// and hard pity work the way they do in production.
    Map<Rarity, int> _runDistribution({
      required int iterations,
      required int comboMultiplier,
      required int seedBase,
    }) {
      const selector = RarityPitySelector();
      final tally = <Rarity, int>{
        Rarity.common: 0,
        Rarity.rare: 0,
        Rarity.epic: 0,
        Rarity.mythic: 0,
      };
      var rareDry = 0;
      var epicDry = 0;
      var legendaryDry = 0;
      for (var i = 0; i < iterations; i++) {
        final picked = _pick(
          selector,
          pool,
          seed: seedBase + i,
          rareDry: rareDry,
          epicDry: epicDry,
          legendaryDry: legendaryDry,
          combo: comboMultiplier,
          packId: 'test',
        );
        tally[picked.rarity] = (tally[picked.rarity] ?? 0) + 1;
        final (r, e, m) = selector.advanceCountersForPack(
          pickedRarity: picked.rarity,
          rareDry: rareDry,
          epicDry: epicDry,
          legendaryDry: legendaryDry,
        );
        rareDry = r;
        epicDry = e;
        legendaryDry = m;
      }
      return tally;
    }

    test('neutral combo: legendary stays "rare" (≤ 1 in 30)', () {
      // At combo 1 (no boost), the only force pulling legendary
      // above its 0.02 base rate is hard-pity at 50 dry picks.
      // Across 10k picks we expect plenty of hard-pity hits, but
      // the rate should still feel rare — not "every couple
      // sessions you see one." Cap at 1/30 = ~333 in 10k.
      final tally = _runDistribution(
        iterations: 10000,
        comboMultiplier: 1,
        seedBase: 1,
      );
      expect(tally[Rarity.mythic]!, lessThanOrEqualTo(333),
          reason: 'Legendary at neutral combo should land in '
              '"magical / rare" territory, not common-pop');
      expect(tally[Rarity.mythic]!, greaterThan(50),
          reason: 'But hard-pity at 50 must still produce some '
              'mythics across 10k picks — otherwise the safety net '
              'is broken');
    });

    test('high combo: legendary climbs but caps under 1 in 8', () {
      // At combo 8 (game cap) the comboBoost adds (8-1)*0.2 = +1.4
      // to the legendary weight. Combined with soft + hard pity
      // this is the worst case in production. Pin a sanity ceiling.
      final tally = _runDistribution(
        iterations: 10000,
        comboMultiplier: 8,
        seedBase: 7,
      );
      expect(tally[Rarity.mythic]!, lessThan(1250),
          reason: 'Even at max combo (8x), legendary pop rate '
              'should stay under 1 in 8 — anything looser undermines '
              'the "magical reveal" sensation');
    });

    test('common dominates the distribution (≥ 50%)', () {
      // Sanity guard: the bulk of session picks should always be
      // commons regardless of pity / combo. If this ever fails,
      // someone over-tuned a boost.
      final tally = _runDistribution(
        iterations: 10000,
        comboMultiplier: 1,
        seedBase: 13,
      );
      expect(tally[Rarity.common]!, greaterThan(5000),
          reason: 'Commons should be the majority of picks — '
              'otherwise the rarity ladder collapses');
    });
  });
}
