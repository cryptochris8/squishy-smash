import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Coin balance badge used in the menu + shop top bar.
///
/// P1.13 fixes:
///   - Text color promoted to white (was cream-on-cream-tint —
///     contrast measured ~2.4:1, below WCAG AA 4.5 for normal
///     text). Cream is preserved as the icon + border accent so the
///     "this is currency" cue stays.
///   - Wrapped in a Semantics node so VoiceOver announces "$N coins"
///     instead of bare digits.
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$coins coins',
      excludeSemantics: true, // suppress the inner Text's bare-number announce
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.cream.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.cream, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on,
                color: Palette.cream, size: 18),
            const SizedBox(width: 6),
            Text(
              '$coins',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
