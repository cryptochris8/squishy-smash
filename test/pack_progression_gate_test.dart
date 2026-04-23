import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/models/smashable_def.dart';
import 'package:squishy_smash/game/systems/pack_progression_gate.dart';

ContentPack _pack(
  String id, {
  List<(String id, Rarity tier)> objects = const [],
  int epicThreshold = 0,
  int legendaryThreshold = 0,
}) {
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
    if (epicThreshold > 0 || legendaryThreshold > 0)
      'packProgression': {
        'epicUnlockRareBursts': epicThreshold,
        'legendaryUnlockEpicBursts': legendaryThreshold,
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

SmashableDef _defFor(ContentPack p, String id) =>
    p.objects.firstWhere((o) => o.id == id);

void main() {
  group('PackProgression.fromJson', () {
    test('absent config yields ungated default', () {
      final progression = PackProgression.fromJson(null);
      expect(progression.isGated, isFalse);
      expect(progression.epicUnlockRareBursts, 0);
      expect(progression.legendaryUnlockEpicBursts, 0);
    });

    test('partial config is accepted', () {
      final progression = PackProgression.fromJson({
        'epicUnlockRareBursts': 5,
      });
      expect(progression.isGated, isTrue);
      expect(progression.epicUnlockRareBursts, 5);
      expect(progression.legendaryUnlockEpicBursts, 0);
    });
  });

  group('ContentPack.fromJson progression wiring', () {
    test('ungated by default for packs without a progression block', () {
      final pack = _pack('ungated');
      expect(pack.progression.isGated, isFalse);
    });

    test('parses packProgression thresholds from JSON', () {
      final pack = _pack('gated',
          epicThreshold: 3, legendaryThreshold: 2);
      expect(pack.progression.isGated, isTrue);
      expect(pack.progression.epicUnlockRareBursts, 3);
      expect(pack.progression.legendaryUnlockEpicBursts, 2);
    });
  });

  group('PackProgressionGate.isTierUnlocked', () {
    const gate = PackProgressionGate();

    test('ungated packs always return true, regardless of counters', () {
      final pack = _pack('ungated');
      for (final tier in Rarity.values) {
        expect(
          gate.isTierUnlocked(
            pack: pack,
            tier: tier,
            rareBurstsInPack: 0,
            epicBurstsInPack: 0,
          ),
          isTrue,
        );
      }
    });

    test('gated pack: common + rare always unlocked', () {
      final pack = _pack('gated', epicThreshold: 3, legendaryThreshold: 2);
      for (final tier in [Rarity.common, Rarity.rare]) {
        expect(
          gate.isTierUnlocked(
            pack: pack,
            tier: tier,
            rareBurstsInPack: 0,
            epicBurstsInPack: 0,
          ),
          isTrue,
          reason: '${tier.token} should be unlocked from the start',
        );
      }
    });

    test('gated pack: epic locked until rare burst threshold met', () {
      final pack = _pack('gated', epicThreshold: 3, legendaryThreshold: 2);
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.epic,
          rareBurstsInPack: 2,
          epicBurstsInPack: 0,
        ),
        isFalse,
      );
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.epic,
          rareBurstsInPack: 3,
          epicBurstsInPack: 0,
        ),
        isTrue,
      );
    });

    test('gated pack: legendary locked until epic burst threshold met', () {
      final pack = _pack('gated', epicThreshold: 3, legendaryThreshold: 2);
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.mythic,
          rareBurstsInPack: 99,
          epicBurstsInPack: 1,
        ),
        isFalse,
      );
      expect(
        gate.isTierUnlocked(
          pack: pack,
          tier: Rarity.mythic,
          rareBurstsInPack: 99,
          epicBurstsInPack: 2,
        ),
        isTrue,
      );
    });
  });

  group('PackProgressionGate.filterPool', () {
    const gate = PackProgressionGate();

    test('ungated pool passes through unchanged', () {
      final launch = _pack('launch', objects: [
        ('c1', Rarity.common),
        ('r1', Rarity.rare),
        ('e1', Rarity.epic),
        ('m1', Rarity.mythic),
      ]);
      final pool = launch.objects
          .map((o) => GatedObject(def: o, pack: launch))
          .toList();
      final filtered = gate.filterPool(
        objectsByPack: pool,
        rareBurstsByPack: const {},
        epicBurstsByPack: const {},
      );
      expect(filtered, hasLength(4));
    });

    test('gated pool hides epic + legendary until thresholds met', () {
      final gated = _pack(
        'foods',
        epicThreshold: 3,
        legendaryThreshold: 2,
        objects: [
          ('c1', Rarity.common),
          ('r1', Rarity.rare),
          ('e1', Rarity.epic),
          ('m1', Rarity.mythic),
        ],
      );
      final pool = gated.objects
          .map((o) => GatedObject(def: o, pack: gated))
          .toList();
      final earlyFiltered = gate.filterPool(
        objectsByPack: pool,
        rareBurstsByPack: const {'foods': 0},
        epicBurstsByPack: const {'foods': 0},
      );
      expect(
        earlyFiltered.map((e) => e.def.id).toSet(),
        {'c1', 'r1'},
        reason: 'epic + legendary should be gated out',
      );

      final epicOpenFiltered = gate.filterPool(
        objectsByPack: pool,
        rareBurstsByPack: const {'foods': 3},
        epicBurstsByPack: const {'foods': 0},
      );
      expect(
        epicOpenFiltered.map((e) => e.def.id).toSet(),
        {'c1', 'r1', 'e1'},
        reason: 'legendary should still be gated',
      );

      final allOpenFiltered = gate.filterPool(
        objectsByPack: pool,
        rareBurstsByPack: const {'foods': 99},
        epicBurstsByPack: const {'foods': 2},
      );
      expect(allOpenFiltered.map((e) => e.def.id).toSet(),
          {'c1', 'r1', 'e1', 'm1'});
    });

    test('mixed pool: ungated pack untouched, gated pack filtered', () {
      final launch = _pack('launch', objects: [
        ('l_c', Rarity.common),
        ('l_r', Rarity.rare),
        ('l_m', Rarity.mythic),
      ]);
      final gated = _pack(
        'foods',
        epicThreshold: 3,
        legendaryThreshold: 2,
        objects: [
          ('f_c', Rarity.common),
          ('f_r', Rarity.rare),
          ('f_m', Rarity.mythic),
        ],
      );
      final pool = <GatedObject>[
        for (final o in launch.objects) GatedObject(def: o, pack: launch),
        for (final o in gated.objects) GatedObject(def: o, pack: gated),
      ];
      final filtered = gate.filterPool(
        objectsByPack: pool,
        rareBurstsByPack: const {},
        epicBurstsByPack: const {},
      );
      final ids = filtered.map((e) => e.def.id).toSet();
      expect(ids, contains('l_m'),
          reason: 'ungated legendary should stay');
      expect(ids, isNot(contains('f_m')),
          reason: 'gated legendary should be filtered');
    });
  });

  group('GatedObject', () {
    test('exposes packId from pack', () {
      final pack = _pack('launch', objects: [('x', Rarity.common)]);
      final entry = GatedObject(def: _defFor(pack, 'x'), pack: pack);
      expect(entry.packId, 'launch');
    });
  });
}
