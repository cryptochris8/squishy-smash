import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/rarity.dart';

void main() {
  group('rarityFromToken — legendary/mythic alias', () {
    test('"mythic" parses to Rarity.mythic', () {
      expect(rarityFromToken('mythic'), Rarity.mythic);
    });

    test('"legendary" parses to Rarity.mythic (player-facing alias)', () {
      // The player-facing label says "Legendary" — pack JSONs and
      // manifests authored after the terminology cleanup should be
      // able to use that name without it falling back to common.
      expect(rarityFromToken('legendary'), Rarity.mythic);
    });

    test('common, rare, epic still map correctly (no regression)', () {
      expect(rarityFromToken('common'), Rarity.common);
      expect(rarityFromToken('rare'), Rarity.rare);
      expect(rarityFromToken('epic'), Rarity.epic);
    });

    test('persisted token from Rarity.mythic.token round-trips', () {
      // Regardless of which token came in, the canonical persisted
      // form is `mythic` (so v1/v2 saves keep loading without a
      // migration).
      expect(Rarity.mythic.token, 'mythic');
      expect(rarityFromToken(Rarity.mythic.token), Rarity.mythic);
    });

    test('unknown tokens fall back to common (defensive)', () {
      expect(rarityFromToken('mythical'), Rarity.common);
      expect(rarityFromToken('lengendary'), Rarity.common); // typo
      expect(rarityFromToken(null), Rarity.common);
    });
  });

  group('RarityOdds.fromJson — legendary/mythic key alias', () {
    test('legendary key wins when present', () {
      final odds = RarityOdds.fromJson({
        'common': 0.6,
        'rare': 0.25,
        'epic': 0.10,
        'legendary': 0.05,
      });
      expect(odds.shareFor(Rarity.mythic), closeTo(0.05, 1e-9));
    });

    test('mythic key parses as the alias', () {
      // Pack author uses internal-style key — must still set the top
      // tier value (no silent fallback to default 0.02).
      final odds = RarityOdds.fromJson({
        'common': 0.6,
        'rare': 0.25,
        'epic': 0.10,
        'mythic': 0.05,
      });
      expect(odds.shareFor(Rarity.mythic), closeTo(0.05, 1e-9));
    });

    test('legendary takes precedence when both keys are present', () {
      // The user-facing "legendary" name is canonical; if a pack
      // accidentally carries both, prefer the canonical value so
      // behavior is predictable.
      final odds = RarityOdds.fromJson({
        'common': 0.6,
        'rare': 0.25,
        'epic': 0.10,
        'legendary': 0.05,
        'mythic': 0.99,
      });
      expect(odds.shareFor(Rarity.mythic), closeTo(0.05, 1e-9));
    });

    test('missing top-tier key falls back to default 0.02', () {
      final odds = RarityOdds.fromJson({
        'common': 0.6,
        'rare': 0.25,
        'epic': 0.10,
      });
      expect(odds.shareFor(Rarity.mythic), closeTo(0.02, 1e-9));
    });
  });

  group('UnlockGates.fromJson — legendary/mythic key alias', () {
    test('legendary key wins when present', () {
      final g = UnlockGates.fromJson({'rare': 1, 'epic': 5, 'legendary': 8});
      expect(g.gateFor(Rarity.mythic), 8);
    });

    test('mythic key parses as the alias', () {
      final g = UnlockGates.fromJson({'rare': 1, 'epic': 5, 'mythic': 8});
      expect(g.gateFor(Rarity.mythic), 8);
    });

    test('legendary takes precedence over mythic when both present', () {
      final g = UnlockGates.fromJson({
        'rare': 1,
        'epic': 5,
        'legendary': 8,
        'mythic': 99,
      });
      expect(g.gateFor(Rarity.mythic), 8);
    });
  });

  group('PityThresholds.fromJson — legendary/mythic alias', () {
    test('legendarySoft/legendaryHard keys parse correctly', () {
      final p = PityThresholds.fromJson({
        'rareSoft': 4,
        'rareHard': 6,
        'epicSoft': 12,
        'epicHard': 18,
        'legendarySoft': 22,
        'legendaryHard': 40,
      });
      final (soft, hard) = p.forTier(Rarity.mythic);
      expect(soft, 22);
      expect(hard, 40);
    });

    test('mythicSoft/mythicHard keys parse via alias', () {
      final p = PityThresholds.fromJson({
        'mythicSoft': 22,
        'mythicHard': 40,
      });
      final (soft, hard) = p.forTier(Rarity.mythic);
      expect(soft, 22);
      expect(hard, 40);
    });

    test('legendary keys win when both forms are present', () {
      final p = PityThresholds.fromJson({
        'legendarySoft': 22,
        'legendaryHard': 40,
        'mythicSoft': 99,
        'mythicHard': 99,
      });
      final (soft, hard) = p.forTier(Rarity.mythic);
      expect(soft, 22);
      expect(hard, 40);
    });
  });

  group('Player-facing display label vs internal token', () {
    test('Rarity.mythic.displayLabel is "Legendary" (player-facing)', () {
      expect(Rarity.mythic.displayLabel, 'Legendary');
    });

    test('Rarity.mythic.token is "mythic" (legacy persistence)', () {
      expect(Rarity.mythic.token, 'mythic');
    });
  });
}
