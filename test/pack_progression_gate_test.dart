import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/game/systems/pack_progression_gate.dart';

ContentPack _pack(
  String id, {
  List<(String id, Rarity tier)> objects = const [],
  int? rareGate,
  int? epicGate,
  int? legendaryGate,
}) {
  final hasOverrides =
      rareGate != null || epicGate != null || legendaryGate != null;
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
    if (hasOverrides)
      'packProgression': {
        'unlockGates': {
          if (rareGate != null) 'rare': rareGate,
          if (epicGate != null) 'epic': epicGate,
          if (legendaryGate != null) 'legendary': legendaryGate,
        },
      },
    'objects': [
      for (final (oid, tier) in objects)
        {
          'id': oid,
          'name': oid,
          'category': 'test',
          'themeTag': 'test',
          'sprite': 'assets/images/objects/$oid.png',
          'thumbnail': 'assets/images/thumbnails/${oid}_thumb.png',
          'deformability': 0.5,
          'elasticity': 0.5,
          'burstThreshold': 0.7,
          'gooLevel': 0.5,
          'impactSounds': ['audio/test/$oid.mp3'],
          'burstSound': 'audio/test/${oid}_burst.mp3',
          'particlePreset': 'test',
          'decalPreset': 'test',
          'coinReward': 1,
          'unlockTier': 0,
          'searchTags': <String>[],
          'rarity': tier.token,
        },
    ],
  });
}

void main() {
  group('PackProgression defaults', () {
    test('absent JSON yields code defaults (3/10/20 unlock gates)', () {
      final pack = _pack('default');
      expect(pack.progression.unlockGates.rare, 3);
      expect(pack.progression.unlockGates.epic, 10);
      expect(pack.progression.unlockGates.legendary, 20);
    });

    test('absent JSON yields doc-default base odds (68/22/8/2)', () {
      final pack = _pack('default');
      expect(pack.progression.baseOdds.common, 0.68);
      expect(pack.progression.baseOdds.rare, 0.22);
      expect(pack.progression.baseOdds.epic, 0.08);
      expect(pack.progression.baseOdds.legendary, 0.02);
    });

    test('absent JSON yields doc-default pity thresholds', () {
      final pack = _pack('default');
      expect(pack.progression.pity.rareSoft, 5);
      expect(pack.progression.pity.rareHard, 7);
      expect(pack.progression.pity.epicSoft, 14);
      expect(pack.progression.pity.epicHard, 20);
      expect(pack.progression.pity.legendarySoft, 25);
      expect(pack.progression.pity.legendaryHard, 50);
    });
  });

  group('PackProgression.fromJson partial overrides', () {
    test('overrides merge with defaults for missing fields', () {
      final pack = _pack('gated',
          rareGate: 5); // leaves epic + legendary at defaults
      expect(pack.progression.unlockGates.rare, 5);
      expect(pack.progression.unlockGates.epic, 10);
      expect(pack.progression.unlockGates.legendary, 20);
    });
  });

  group('PackProgressionGate.isTierUnlocked', () {
    const gate = PackProgressionGate();

    test('common always unlocked regardless of burst count', () {
      final pack = _pack('p');
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.common,
          totalBurstsInPack: 0,
        ),
        isTrue,
      );
    });

    test('rare locked before 3 total bursts, unlocked after', () {
      final pack = _pack('p');
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.rare,
          totalBurstsInPack: 2,
        ),
        isFalse,
      );
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.rare,
          totalBurstsInPack: 3,
        ),
        isTrue,
      );
    });

    test('epic locked before 10, unlocked after', () {
      final pack = _pack('p');
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.epic,
          totalBurstsInPack: 9,
        ),
        isFalse,
      );
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.epic,
          totalBurstsInPack: 10,
        ),
        isTrue,
      );
    });

    test('legendary locked before 20, unlocked after', () {
      final pack = _pack('p');
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.mythic,
          totalBurstsInPack: 19,
        ),
        isFalse,
      );
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.mythic,
          totalBurstsInPack: 20,
        ),
        isTrue,
      );
    });

    test('custom gates from JSON override defaults', () {
      final pack = _pack('custom',
          rareGate: 1, epicGate: 2, legendaryGate: 5);
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.rare,
          totalBurstsInPack: 1,
        ),
        isTrue,
      );
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.mythic,
          totalBurstsInPack: 4,
        ),
        isFalse,
      );
    });
  });

  group('PackProgressionGate.filterPool', () {
    const gate = PackProgressionGate();

    test('fresh profile (0 bursts): only commons pass through', () {
      final pack = _pack('p', objects: [
        ('c1', Rarity.common),
        ('r1', Rarity.rare),
        ('e1', Rarity.epic),
        ('m1', Rarity.mythic),
      ]);
      final pool = [
        for (final o in pack.objects) GatedObject(def: o, pack: pack),
      ];
      final filtered = gate.filterPool(
        objectsByPack: pool,
        totalBurstsByPack: const {},
      );
      expect(filtered.map((e) => e.def.id).toSet(), {'c1'});
    });

    test('at 3 bursts: commons + rares pass', () {
      final pack = _pack('p', objects: [
        ('c1', Rarity.common),
        ('r1', Rarity.rare),
        ('e1', Rarity.epic),
        ('m1', Rarity.mythic),
      ]);
      final pool = [
        for (final o in pack.objects) GatedObject(def: o, pack: pack),
      ];
      final filtered = gate.filterPool(
        objectsByPack: pool,
        totalBurstsByPack: const {'p': 3},
      );
      expect(filtered.map((e) => e.def.id).toSet(), {'c1', 'r1'});
    });

    test('at 10 bursts: commons + rares + epics pass', () {
      final pack = _pack('p', objects: [
        ('c1', Rarity.common),
        ('r1', Rarity.rare),
        ('e1', Rarity.epic),
        ('m1', Rarity.mythic),
      ]);
      final pool = [
        for (final o in pack.objects) GatedObject(def: o, pack: pack),
      ];
      final filtered = gate.filterPool(
        objectsByPack: pool,
        totalBurstsByPack: const {'p': 10},
      );
      expect(filtered.map((e) => e.def.id).toSet(), {'c1', 'r1', 'e1'});
    });

    test('at 20 bursts: every tier passes', () {
      final pack = _pack('p', objects: [
        ('c1', Rarity.common),
        ('r1', Rarity.rare),
        ('e1', Rarity.epic),
        ('m1', Rarity.mythic),
      ]);
      final pool = [
        for (final o in pack.objects) GatedObject(def: o, pack: pack),
      ];
      final filtered = gate.filterPool(
        objectsByPack: pool,
        totalBurstsByPack: const {'p': 20},
      );
      expect(filtered.map((e) => e.def.id).toSet(),
          {'c1', 'r1', 'e1', 'm1'});
    });

    test('mixed pool — each pack gates independently', () {
      final packA = _pack('A',
          objects: [('a_c', Rarity.common), ('a_m', Rarity.mythic)]);
      final packB = _pack('B',
          objects: [('b_c', Rarity.common), ('b_m', Rarity.mythic)]);
      final pool = <GatedObject>[
        for (final o in packA.objects) GatedObject(def: o, pack: packA),
        for (final o in packB.objects) GatedObject(def: o, pack: packB),
      ];
      final filtered = gate.filterPool(
        objectsByPack: pool,
        totalBurstsByPack: const {'A': 25, 'B': 5},
      );
      final ids = filtered.map((e) => e.def.id).toSet();
      expect(ids, contains('a_m'),
          reason: 'packA has enough bursts for legendary');
      expect(ids, isNot(contains('b_m')),
          reason: 'packB has only 5 bursts — legendary still locked');
    });
  });
}
