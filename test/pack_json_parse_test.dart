import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/content_loader.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/rarity.dart';

/// Parses a pack JSON directly from disk (relative to the package root,
/// where `flutter test` runs). Catches schema regressions before the app
/// ever tries to load via rootBundle.
ContentPack _loadPackFromDisk(String assetPath) {
  final file = File(assetPath);
  expect(file.existsSync(), isTrue,
      reason: 'missing pack file on disk: $assetPath');
  final map = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return ContentPack.fromJson(map);
}

void main() {
  group('Bundled pack JSONs parse with the current schema', () {
    for (final path in ContentLoader.bundledPackPaths) {
      test(path, () {
        final pack = _loadPackFromDisk(path);
        expect(pack.packId, isNotEmpty);
        expect(pack.displayName, isNotEmpty);
        expect(pack.objects, isNotEmpty,
            reason: '$path has zero objects');
        for (final obj in pack.objects) {
          expect(obj.id, isNotEmpty);
          expect(obj.impactSounds, isNotEmpty);
          expect(obj.burstSound, isNotEmpty);
          expect(obj.deformability, inInclusiveRange(0.0, 1.0));
          expect(obj.burstThreshold, inInclusiveRange(0.0, 1.0));
          expect(obj.gooLevel, inInclusiveRange(0.0, 1.0));
          expect(obj.coinReward, greaterThan(0));
        }
      });
    }
  });

  group('Dumpling Squishy pack shape', () {
    late final ContentPack pack;

    setUpAll(() {
      pack = _loadPackFromDisk(
        'assets/data/packs/dumpling_squishy_drop_01.json',
      );
    });

    test('has 8 objects total', () {
      expect(pack.objects, hasLength(8));
    });

    test('5 commons, 2 rares, 1 mythic', () {
      final counts = <Rarity, int>{for (final r in Rarity.values) r: 0};
      for (final obj in pack.objects) {
        counts[obj.rarity] = counts[obj.rarity]! + 1;
      }
      expect(counts[Rarity.common], 5);
      expect(counts[Rarity.rare], 2);
      expect(counts[Rarity.epic], 0);
      expect(counts[Rarity.mythic], 1);
    });

    test('Gold Dumplio is the mythic hero', () {
      final mythic = pack.objects.singleWhere(
        (o) => o.rarity == Rarity.mythic,
      );
      expect(mythic.id, 'gold_dumplio');
      expect(mythic.name, 'Gold Dumplio');
      expect(mythic.particlePreset, 'gold_mythic_burst');
      expect(mythic.decalPreset, 'gold_mythic_splat');
      expect(mythic.coinReward, greaterThanOrEqualTo(50));
    });

    test('palette matches Candy Cloud Kitchen direction', () {
      expect(pack.palette.primary, '#FFD1DC');
      expect(pack.palette.secondary, '#FFB5A7');
      expect(pack.palette.accent, '#F6C089');
    });

    test('arena suggestion and release window match the strategy doc', () {
      expect(pack.arenaSuggestion, 'candy_cloud_kitchen');
      expect(pack.releaseWindow, '2026-04-27');
    });

    test('object IDs are unique within the pack', () {
      final ids = pack.objects.map((o) => o.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every object has at least 3 impact sound variants', () {
      for (final obj in pack.objects) {
        expect(obj.impactSounds.length, greaterThanOrEqualTo(3),
            reason: 'object ${obj.id} has only '
                '${obj.impactSounds.length} impact sound variants');
      }
    });

    test('packProgression is tuned for the actual rarity composition', () {
      // Tuning rationale: 5C / 2R / 0E / 1M means the default epic
      // gates/pity (which assume epics exist) would create dead
      // progression states. The pack's own packProgression block
      // disables the epic tier and lowers the legendary unlock to
      // match the smaller object pool.
      final prog = pack.progression;

      // Base odds redistribute the unused epic share to commons + mythic.
      expect(prog.baseOdds.common, closeTo(0.70, 0.001));
      expect(prog.baseOdds.rare, closeTo(0.25, 0.001));
      expect(prog.baseOdds.epic, closeTo(0.00, 0.001),
          reason: 'no epics in pack — share must be 0');
      expect(prog.baseOdds.legendary, closeTo(0.05, 0.001));

      // Epic gate is effectively disabled (>= object count). The
      // legendary gate is lowered to match the 8-object pool size.
      expect(prog.unlockGates.rare, 3);
      expect(prog.unlockGates.epic, greaterThanOrEqualTo(pack.objects.length),
          reason: 'no epics — gate must be unreachable so it never blocks');
      expect(prog.unlockGates.legendary, 8);

      // Pity floors are tightened for the smaller pack.
      expect(prog.pity.rareSoft, 4);
      expect(prog.pity.rareHard, 6);
      expect(prog.pity.epicSoft, greaterThanOrEqualTo(prog.unlockGates.epic),
          reason: 'epic pity inert when there are no epics');
      expect(prog.pity.legendarySoft, 15);
      expect(prog.pity.legendaryHard, 25);
    });
  });

  group('Launch pack rarity composition (8 / 4 / 3 / 1 lock)', () {
    // Locks the canonical 8C/4R/3E/1L shape for every doc-aligned launch
    // pack. If anyone strips per-object `rarity` fields from a pack JSON,
    // SmashableDef.fromJson silently defaults to common — these counts
    // would then collapse to 16/0/0/0 and the test fires. Same guardrail
    // as the warning in docs/archive/claude_pack_kickoff/ARCHIVE_NOTES.md.
    const launchPackPaths = [
      'assets/data/packs/launch_squishy_foods.json',
      'assets/data/packs/goo_fidgets_drop_01.json',
      'assets/data/packs/creepy_cute_pack_01.json',
    ];

    for (final path in launchPackPaths) {
      test('$path: 8 common / 4 rare / 3 epic / 1 legendary', () {
        final raw = File(path).readAsStringSync();
        final pack = ContentPack.fromJson(
          json.decode(raw) as Map<String, dynamic>,
        );
        final counts = <Rarity, int>{for (final r in Rarity.values) r: 0};
        for (final obj in pack.objects) {
          counts[obj.rarity] = counts[obj.rarity]! + 1;
        }
        expect(pack.objects.length, 16,
            reason: '$path total object count');
        expect(counts[Rarity.common], 8, reason: '$path commons');
        expect(counts[Rarity.rare], 4, reason: '$path rares');
        expect(counts[Rarity.epic], 3, reason: '$path epics');
        expect(counts[Rarity.mythic], 1,
            reason: '$path legendaries (Rarity.mythic enum variant)');
      });

      test('$path: every object declares an explicit rarity field', () {
        // The fromJson path defaults to common when rarity is absent. We
        // want the JSON file itself to carry the field — a missing field
        // would still parse but downstream tier balancing would silently
        // collapse to 16-commons. This catches the *string presence*,
        // not just the parsed enum value.
        final raw = File(path).readAsStringSync();
        final map = json.decode(raw) as Map<String, dynamic>;
        final objects = (map['objects'] as List)
            .cast<Map<String, dynamic>>();
        for (final obj in objects) {
          expect(obj.containsKey('rarity'), isTrue,
              reason: '$path: object ${obj['id']} is missing rarity');
        }
      });
    }
  });

  group('LiveOps schedule reflects Dumpling Squishy Drop', () {
    test('featured rotation includes the Dumpling Squishy Drop week', () {
      final raw = File('assets/data/liveops_schedule.json').readAsStringSync();
      final map = json.decode(raw) as Map<String, dynamic>;
      final rotation = (map['featuredRotation'] as List)
          .cast<Map<String, dynamic>>();
      final dumplingWeek = rotation.firstWhere(
        (w) => w['featuredPack'] == 'dumpling_squishy_drop_01',
      );
      expect(dumplingWeek['weekOf'], '2026-04-27');
      expect(dumplingWeek['promoLabel'], contains('Dumpling'));
    });
  });

  group('Pack audio assets exist on disk', () {
    // Each pack's SFX paths should resolve to files that are real audio
    // (>1 KB — anything smaller is almost certainly an unpopulated stub).
    for (final path in ContentLoader.bundledPackPaths) {
      test('all SFX referenced by $path are present and non-stub', () {
        final pack = _loadPackFromDisk(path);
        for (final obj in pack.objects) {
          for (final soundPath in <String>[
            ...obj.impactSounds,
            obj.burstSound,
          ]) {
            // SoundManager strips the "audio/" prefix; on disk files live
            // under "assets/audio/...".
            final onDisk = File('assets/$soundPath');
            expect(onDisk.existsSync(), isTrue,
                reason: 'missing audio file: assets/$soundPath '
                    '(referenced by ${pack.packId} / ${obj.id})');
            expect(onDisk.lengthSync(), greaterThan(1024),
                reason: 'audio file is <1KB — possibly a stub: '
                    'assets/$soundPath');
          }
        }
      });
    }
  });

  group('Pack sprite assets exist on disk', () {
    // FLUX-generated 1024x1024 character sprites run ~200-400 KB.
    // 256x256 thumbnails compress to ~30-45 KB. We set separate
    // floors to catch stubs without false-flagging real thumbnails.
    const int kSpriteMinBytes = 100 * 1024;
    const int kThumbMinBytes = 10 * 1024;

    for (final path in ContentLoader.bundledPackPaths) {
      test('all sprites referenced by $path are present and non-stub', () {
        final pack = _loadPackFromDisk(path);
        for (final obj in pack.objects) {
          // Full sprite at 1024x1024.
          final sprite = File(obj.sprite);
          expect(sprite.existsSync(), isTrue,
              reason: 'missing sprite: ${obj.sprite} '
                  '(${pack.packId} / ${obj.id})');
          expect(sprite.lengthSync(), greaterThan(kSpriteMinBytes),
              reason: 'sprite is <${kSpriteMinBytes ~/ 1024} KB '
                  '— possibly a stub: ${obj.sprite}');

          // Thumbnail at 256x256.
          final thumb = File(obj.thumbnail);
          expect(thumb.existsSync(), isTrue,
              reason: 'missing thumbnail: ${obj.thumbnail} '
                  '(${pack.packId} / ${obj.id})');
          expect(thumb.lengthSync(), greaterThan(kThumbMinBytes),
              reason: 'thumbnail is <${kThumbMinBytes ~/ 1024} KB '
                  '— possibly a stub: ${obj.thumbnail}');
        }
      });
    }
  });
}
