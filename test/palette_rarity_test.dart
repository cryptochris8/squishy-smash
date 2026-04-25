import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/core/constants.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/ui/widgets/card_album_widgets.dart';

void main() {
  group('Palette.rarityColor — single source of truth', () {
    test('returns a distinct color for each rarity tier', () {
      final colors =
          Rarity.values.map(Palette.rarityColor).toSet();
      expect(colors.length, Rarity.values.length,
          reason: 'each rarity must have its own visually distinct '
              'color so the album, HUD, and shop all read at a glance');
    });

    test('Common is the muted gray (deliberately low-contrast)', () {
      expect(Palette.rarityColor(Rarity.common),
          const Color(0xFFB0B6C3));
    });

    test('Mythic uses the warm cream — the highest-tier signal', () {
      expect(Palette.rarityColor(Rarity.mythic), Palette.cream);
    });

    test('Rare and Epic borrow existing brand colors (no drift)', () {
      // Rare uses Palette.jellyBlue and Epic uses Palette.lavender
      // so a brand-color shift propagates everywhere automatically.
      expect(Palette.rarityColor(Rarity.rare), Palette.jellyBlue);
      expect(Palette.rarityColor(Rarity.epic), Palette.lavender);
    });
  });

  group('cardRarityColor delegates to Palette.rarityColor', () {
    // Album-local alias must resolve to the same canonical palette
    // entry so the album doesn't drift from the rest of the UI.
    test('matches Palette.rarityColor for every rarity', () {
      for (final r in Rarity.values) {
        expect(cardRarityColor(r), Palette.rarityColor(r),
            reason: 'cardRarityColor and Palette.rarityColor must '
                'return the same Color for $r');
      }
    });
  });
}
