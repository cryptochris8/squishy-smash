import '../data/models/content_pack.dart';
import '../data/models/rarity.dart';
import '../data/models/smashable_def.dart';

/// Pure data for the Collection screen. Built from the player's
/// unlocked packs + their discovered-ID set so the widget layer stays
/// trivial and the logic is easy to test.
class CollectionSummary {
  const CollectionSummary({
    required this.sections,
    required this.totalCount,
    required this.discoveredCount,
  });

  final List<CollectionSection> sections;
  final int totalCount;
  final int discoveredCount;

  int get undiscoveredCount => totalCount - discoveredCount;

  /// Percent of the collection found, 0..1. Returns 0 for empty pools
  /// so the progress bar doesn't divide by zero.
  double get progress => totalCount == 0 ? 0 : discoveredCount / totalCount;

  /// Build a summary for the given unlocked packs. Packs the player
  /// doesn't own are hidden entirely — the shelf shows only what you
  /// *could* find, to avoid spoiling content you haven't paid for.
  factory CollectionSummary.build({
    required List<ContentPack> allPacks,
    required Set<String> unlockedPackIds,
    required Set<String> discoveredSmashableIds,
  }) {
    final sections = <CollectionSection>[];
    var total = 0;
    var discovered = 0;
    for (final pack in allPacks) {
      if (!unlockedPackIds.contains(pack.packId)) continue;
      final entries = <CollectionEntry>[];
      for (final obj in pack.objects) {
        final isDiscovered = discoveredSmashableIds.contains(obj.id);
        entries.add(CollectionEntry(def: obj, discovered: isDiscovered));
        total += 1;
        if (isDiscovered) discovered += 1;
      }
      if (entries.isNotEmpty) {
        sections.add(CollectionSection(pack: pack, entries: entries));
      }
    }
    return CollectionSummary(
      sections: sections,
      totalCount: total,
      discoveredCount: discovered,
    );
  }
}

class CollectionSection {
  const CollectionSection({required this.pack, required this.entries});

  final ContentPack pack;
  final List<CollectionEntry> entries;

  int get discoveredCount => entries.where((e) => e.discovered).length;
  int get totalCount => entries.length;
}

class CollectionEntry {
  const CollectionEntry({required this.def, required this.discovered});

  final SmashableDef def;
  final bool discovered;

  Rarity get rarity => def.rarity;
}
