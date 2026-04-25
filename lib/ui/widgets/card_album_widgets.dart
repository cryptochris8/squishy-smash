import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/rarity.dart';

/// Album-local alias for [Palette.rarityColor]. Kept around so existing
/// album call sites don't need to be rewritten — but new code should
/// prefer `Palette.rarityColor(...)` directly.
Color cardRarityColor(Rarity r) => Palette.rarityColor(r);

/// Pill-shaped filter button used by both the pack filter row and the
/// rarity filter row in the card album. Selected state highlights the
/// pill with [tint] (or the default warm yellow) and saturates the
/// background slightly.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? const Color(0xFFFFD36E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.15),
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: selected ? color : Colors.white.withValues(alpha: 0.7),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Compact rarity badge — a tinted pill carrying the rarity's display
/// label. Used in card detail modals.
class RarityPill extends StatelessWidget {
  const RarityPill({super.key, required this.rarity});

  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = cardRarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        rarity.displayLabel.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// "Bursts X / Y" progress bar shown in the locked-card detail sheet
/// to communicate how close the player is to the burst-threshold path.
class BurstProgressBar extends StatelessWidget {
  const BurstProgressBar({
    super.key,
    required this.bursts,
    required this.required,
  });

  final int bursts;
  final int required;

  @override
  Widget build(BuildContext context) {
    final progress = required == 0
        ? 1.0
        : (bursts / required).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BURSTS  $bursts / $required',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFD36E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFFFD36E),
            ),
          ),
        ),
      ],
    );
  }
}
