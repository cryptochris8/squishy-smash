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
