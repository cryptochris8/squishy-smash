import 'package:flutter/material.dart';

import '../core/service_locator.dart';
import '../data/models/rarity.dart';
import '../data/models/smashable_def.dart';
import 'collection_summary.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progression = ServiceLocator.progression;
    final summary = CollectionSummary.build(
      allPacks: ServiceLocator.packs.packs,
      unlockedPackIds: progression.profile.unlockedPackIds,
      discoveredSmashableIds: progression.profile.discoveredSmashableIds,
    );
    final rarest = progression.profile.rarestSeen;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'COLLECTION',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CollectionHeader(summary: summary, rarestSeen: rarest),
          const SizedBox(height: 20),
          for (final section in summary.sections) ...[
            _PackSectionHeader(section: section),
            const SizedBox(height: 10),
            _EntryGrid(entries: section.entries),
            const SizedBox(height: 22),
          ],
          if (summary.sections.isEmpty) const _EmptyState(),
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.summary, required this.rarestSeen});

  final CollectionSummary summary;
  final Rarity rarestSeen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8FB8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${summary.discoveredCount} / ${summary.totalCount} found',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              _RarityBadge(rarity: rarestSeen, prefix: 'Rarest:'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFB6FF5C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackSectionHeader extends StatelessWidget {
  const _PackSectionHeader({required this.section});

  final CollectionSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            section.pack.displayName.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD36E),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Text(
          '${section.discoveredCount} / ${section.totalCount}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({required this.entries});

  final List<CollectionEntry> entries;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _EntryTile(entry: entries[i]),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final borderColor = entry.discovered
        ? _rarityColor(entry.rarity)
        : Colors.white.withValues(alpha: 0.1);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: entry.discovered
                  ? _Thumbnail(def: entry.def)
                  : const _UndiscoveredSilhouette(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.discovered ? entry.def.name : '???',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: entry.discovered
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.def});

  final SmashableDef def;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      def.thumbnail,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.bubble_chart,
        size: 36,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

class _UndiscoveredSilhouette extends StatelessWidget {
  const _UndiscoveredSilhouette();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.help_outline,
      size: 36,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity, required this.prefix});

  final Rarity rarity;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefix,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rarity.displayLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock a pack to start collecting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

Color _rarityColor(Rarity r) {
  switch (r) {
    case Rarity.common:
      return const Color(0xFFB0B6C3);
    case Rarity.rare:
      return const Color(0xFF7FE7FF);
    case Rarity.epic:
      return const Color(0xFFC98BFF);
    case Rarity.mythic:
      return const Color(0xFFFFD36E);
  }
}
