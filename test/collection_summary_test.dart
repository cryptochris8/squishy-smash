import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/ui/collection_summary.dart';

ContentPack _pack(String id, List<(String, Rarity)> objects) {
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
    'objects': [
      for (final (oid, rarity) in objects)
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
          'rarity': rarity.token,
        },
    ],
  });
}

void main() {
  final launchPack = _pack('launch', [
    ('dumplio', Rarity.common),
    ('jellyzap', Rarity.common),
    ('gold_dumplio', Rarity.mythic),
  ]);
  final gooPack = _pack('goo', [
    ('slimeorb', Rarity.common),
    ('popzee', Rarity.rare),
  ]);
  final creepyPack = _pack('creepy', [
    ('gloomp', Rarity.epic),
  ]);

  group('CollectionSummary.build', () {
    test('hides packs the player has not unlocked', () {
      final summary = CollectionSummary.build(
        allPacks: [launchPack, gooPack, creepyPack],
        unlockedPackIds: {'launch'},
        discoveredSmashableIds: const {},
      );
      expect(summary.sections, hasLength(1));
      expect(summary.sections.first.pack.packId, 'launch');
      expect(summary.totalCount, 3);
      expect(summary.discoveredCount, 0);
    });

    test('counts discovered entries only within unlocked packs', () {
      final summary = CollectionSummary.build(
        allPacks: [launchPack, gooPack, creepyPack],
        unlockedPackIds: {'launch', 'goo'},
        discoveredSmashableIds: {'dumplio', 'gold_dumplio', 'slimeorb'},
      );
      expect(summary.totalCount, 5);
      expect(summary.discoveredCount, 3);
      expect(summary.undiscoveredCount, 2);
      expect(summary.progress, closeTo(0.6, 1e-9));
    });

    test('discovered IDs belonging to locked packs do not inflate count', () {
      // Player has ever discovered `gloomp` (in the creepy pack), but
      // has since re-locked? In practice we don't re-lock, but the math
      // must still come out right.
      final summary = CollectionSummary.build(
        allPacks: [launchPack, gooPack, creepyPack],
        unlockedPackIds: {'launch'},
        discoveredSmashableIds: {'gloomp'},
      );
      expect(summary.totalCount, 3);
      expect(summary.discoveredCount, 0);
    });

    test('per-section counts match filtered entries', () {
      final summary = CollectionSummary.build(
        allPacks: [launchPack, gooPack],
        unlockedPackIds: {'launch', 'goo'},
        discoveredSmashableIds: {'dumplio', 'popzee'},
      );
      expect(summary.sections, hasLength(2));
      final launchSection =
          summary.sections.firstWhere((s) => s.pack.packId == 'launch');
      expect(launchSection.discoveredCount, 1);
      expect(launchSection.totalCount, 3);
      final gooSection =
          summary.sections.firstWhere((s) => s.pack.packId == 'goo');
      expect(gooSection.discoveredCount, 1);
      expect(gooSection.totalCount, 2);
    });

    test('progress is 0 for empty pools (no div-by-zero)', () {
      final summary = CollectionSummary.build(
        allPacks: const <ContentPack>[],
        unlockedPackIds: const <String>{},
        discoveredSmashableIds: const <String>{},
      );
      expect(summary.totalCount, 0);
      expect(summary.progress, 0);
    });

    test('preserves pack order from input list', () {
      final summary = CollectionSummary.build(
        allPacks: [creepyPack, launchPack, gooPack],
        unlockedPackIds: {'launch', 'goo', 'creepy'},
        discoveredSmashableIds: const {},
      );
      expect(
        summary.sections.map((s) => s.pack.packId).toList(),
        ['creepy', 'launch', 'goo'],
      );
    });
  });
}
