import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/card_unlock.dart';
import 'package:squishy_smash/data/models/card_entry.dart';
import 'package:squishy_smash/data/models/rarity.dart';

CardEntry _card({
  String number = '001/048',
  String name = 'Test Card',
  CardPack pack = CardPack.squishyFoods,
  Rarity rarity = Rarity.common,
}) =>
    CardEntry(
      index: int.parse(number.split('/').first),
      cardNumber: number,
      name: name,
      pack: pack,
      rarity: rarity,
      assetPath: 'assets/cards/final_48/$number.webp',
    );

void main() {
  group('CardUnlockThresholds.requiredBursts', () {
    test('Common = 1, Rare = 3, Epic = 7, Legendary (mythic) = 15', () {
      expect(CardUnlockThresholds.requiredBursts(Rarity.common), 1);
      expect(CardUnlockThresholds.requiredBursts(Rarity.rare), 3);
      expect(CardUnlockThresholds.requiredBursts(Rarity.epic), 7);
      expect(CardUnlockThresholds.requiredBursts(Rarity.mythic), 15);
    });

    test('thresholds are strictly increasing by rarity', () {
      // Defends against accidental swaps that would make epic grindier
      // than legendary or vice versa.
      final values = [
        CardUnlockThresholds.requiredBursts(Rarity.common),
        CardUnlockThresholds.requiredBursts(Rarity.rare),
        CardUnlockThresholds.requiredBursts(Rarity.epic),
        CardUnlockThresholds.requiredBursts(Rarity.mythic),
      ];
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]),
            reason: 'rarity ${Rarity.values[i]} threshold (${values[i]}) '
                'should exceed ${Rarity.values[i - 1]} '
                '(${values[i - 1]})');
      }
    });
  });

  group('CardCoinPrice.coinsFor', () {
    test('Common = 50, Rare = 200, Epic = 750, Legendary = 2500', () {
      expect(CardCoinPrice.coinsFor(Rarity.common), 50);
      expect(CardCoinPrice.coinsFor(Rarity.rare), 200);
      expect(CardCoinPrice.coinsFor(Rarity.epic), 750);
      expect(CardCoinPrice.coinsFor(Rarity.mythic), 2500);
    });

    test('prices are strictly increasing by rarity', () {
      final values = [
        CardCoinPrice.coinsFor(Rarity.common),
        CardCoinPrice.coinsFor(Rarity.rare),
        CardCoinPrice.coinsFor(Rarity.epic),
        CardCoinPrice.coinsFor(Rarity.mythic),
      ];
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]));
      }
    });
  });

  group('resolveCardUnlock — burst threshold path', () {
    test('Common card unlocks at burst count 1', () {
      final card = _card(rarity: Rarity.common);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 1},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.burstThreshold,
      );
    });

    test('Common card stays locked at burst count 0', () {
      final card = _card(rarity: Rarity.common);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.locked,
      );
    });

    test('Rare card unlocks at exactly 3 bursts, locked at 2', () {
      final card = _card(rarity: Rarity.rare);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 2},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.locked,
      );
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 3},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.burstThreshold,
      );
    });

    test('Epic card unlocks at 7 bursts', () {
      final card = _card(rarity: Rarity.epic);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 6},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.locked,
      );
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 7},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.burstThreshold,
      );
    });

    test('Legendary card unlocks at 15 bursts', () {
      final card = _card(rarity: Rarity.mythic);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 14},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.locked,
      );
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 15},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.burstThreshold,
      );
    });
  });

  group('resolveCardUnlock — purchase path', () {
    test('purchased card unlocks regardless of burst count', () {
      final card = _card(rarity: Rarity.mythic);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {}, // zero bursts
          cardsPurchased: const {'001/048'},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.purchased,
      );
    });
  });

  group('resolveCardUnlock — achievement path', () {
    test('achievement-granted card unlocks without bursts or purchase', () {
      final card = _card(rarity: Rarity.epic);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {},
          cardsPurchased: const {},
          unlockedFromAchievements: const {'001/048'},
        ),
        CardUnlockSource.achievement,
      );
    });
  });

  group('resolveCardUnlock — source priority', () {
    // When multiple paths are satisfied, the source returned must be
    // deterministic so the UI badge stays stable across sessions.
    test('purchase wins over achievement', () {
      final card = _card();
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {},
          cardsPurchased: const {'001/048'},
          unlockedFromAchievements: const {'001/048'},
        ),
        CardUnlockSource.purchased,
      );
    });

    test('purchase wins over burst threshold', () {
      final card = _card();
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 99},
          cardsPurchased: const {'001/048'},
          unlockedFromAchievements: const {},
        ),
        CardUnlockSource.purchased,
      );
    });

    test('achievement wins over burst threshold', () {
      final card = _card();
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 99},
          cardsPurchased: const {},
          unlockedFromAchievements: const {'001/048'},
        ),
        CardUnlockSource.achievement,
      );
    });
  });

  group('isCardUnlocked sugar', () {
    test('returns true for any non-locked source', () {
      final card = _card();
      expect(
        isCardUnlocked(
          card: card,
          cardBurstCounts: const {'001/048': 5},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        isTrue,
      );
    });

    test('returns false when fully locked', () {
      final card = _card();
      expect(
        isCardUnlocked(
          card: card,
          cardBurstCounts: const {'001/048': 0},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
        ),
        isFalse,
      );
    });
  });
}
