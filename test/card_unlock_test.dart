import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/card_unlock.dart';
import 'package:squishy_smash/data/models/card_entry.dart';
import 'package:squishy_smash/data/models/economy_config.dart';
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

  group('Grandfathering (v3 → v4 migration)', () {
    test('once-grandfathered, a card stays unlocked even under tighter '
        'thresholds', () {
      // Player had 1 burst on a Common (unlocked under baseline).
      // Threshold tightens to 5 — the card would normally re-lock,
      // but grandfathering keeps it earned.
      const tighter = EconomyConfig(
        burstThresholds: RarityTunable<int>(
          common: 5, rare: 8, epic: 20, legendary: 40,
        ),
      );
      final card = _card(rarity: Rarity.common);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 1},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
          grandfatheredCards: const {'001/048'},
          config: tighter,
        ),
        CardUnlockSource.burstThreshold,
        reason: 'grandfathered cards must surface as burst-earned '
            'regardless of current threshold',
      );
    });

    test('grandfathering does NOT unlock cards the player never touched',
        () {
      // The migration should snapshot ONLY cards that met baseline
      // thresholds. A card with 0 bursts must remain locked.
      final card = _card(rarity: Rarity.rare);
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
          grandfatheredCards: const {},
          config: const EconomyConfig(),
        ),
        CardUnlockSource.locked,
      );
    });

    test('grandfatherUnlocksFromBaseline snapshots only baseline-met cards',
        () {
      // Build a small synthetic catalog with one of each rarity.
      const cards = [
        CardEntry(
          index: 1,
          cardNumber: '001/048',
          name: 'C',
          pack: CardPack.squishyFoods,
          rarity: Rarity.common,
          assetPath: 'a.webp',
        ),
        CardEntry(
          index: 9,
          cardNumber: '009/048',
          name: 'R',
          pack: CardPack.squishyFoods,
          rarity: Rarity.rare,
          assetPath: 'b.webp',
        ),
        CardEntry(
          index: 16,
          cardNumber: '016/048',
          name: 'M',
          pack: CardPack.squishyFoods,
          rarity: Rarity.mythic,
          assetPath: 'c.webp',
        ),
      ];
      // Baseline thresholds: common 1, rare 3, mythic 15.
      // Player has burst counts: common=1 (meets), rare=2 (below),
      // mythic=20 (meets).
      const burstCounts = {
        '001/048': 1,
        '009/048': 2,
        '016/048': 20,
      };
      final out = <String>{};
      grandfatherUnlocksFromBaseline(
        cards: cards,
        cardBurstCounts: burstCounts,
        grandfatheredOut: out,
      );
      expect(out, {'001/048', '016/048'},
          reason: 'rare with 2 bursts (below baseline=3) must NOT '
              'be grandfathered');
    });

    test('grandfatherUnlocksFromBaseline is purely additive — does not '
        'remove existing entries', () {
      const cards = [
        CardEntry(
          index: 1,
          cardNumber: '001/048',
          name: 'C',
          pack: CardPack.squishyFoods,
          rarity: Rarity.common,
          assetPath: 'a.webp',
        ),
      ];
      final out = <String>{'preexisting'};
      grandfatherUnlocksFromBaseline(
        cards: cards,
        cardBurstCounts: const {'001/048': 1},
        grandfatheredOut: out,
      );
      // Pre-existing entries survive; new ones are added.
      expect(out, {'preexisting', '001/048'});
    });
  });

  group('Config-driven thresholds (Option B JSON wiring)', () {
    test('CardUnlockThresholds defaults to v0.1.0 baseline when no '
        'config passed', () {
      // Backward-compat: omitting `config` must yield the same numbers
      // tests have always asserted (1/3/7/15).
      expect(CardUnlockThresholds.requiredBursts(Rarity.common), 1);
      expect(CardUnlockThresholds.requiredBursts(Rarity.mythic), 15);
    });

    test('CardUnlockThresholds reads from passed config', () {
      const tighter = EconomyConfig(
        burstThresholds: RarityTunable<int>(
          common: 3, rare: 8, epic: 20, legendary: 40,
        ),
      );
      expect(
        CardUnlockThresholds.requiredBursts(Rarity.common, config: tighter),
        3,
      );
      expect(
        CardUnlockThresholds.requiredBursts(Rarity.mythic, config: tighter),
        40,
      );
    });

    test('CardCoinPrice reads from passed config', () {
      const cheap = EconomyConfig(
        coinPrices: RarityTunable<int>(
          common: 10, rare: 40, epic: 150, legendary: 500,
        ),
      );
      expect(CardCoinPrice.coinsFor(Rarity.common, config: cheap), 10);
      expect(CardCoinPrice.coinsFor(Rarity.mythic, config: cheap), 500);
    });

    test('resolveCardUnlock uses config-driven threshold for burst path',
        () {
      // Common normally unlocks at 1 burst. Under a tightened config
      // requiring 3 bursts, the same player state should now lock.
      const tighter = EconomyConfig(
        burstThresholds: RarityTunable<int>(
          common: 3, rare: 8, epic: 20, legendary: 40,
        ),
      );
      final card = _card(rarity: Rarity.common);
      // 1 burst → locked under tightened config
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 1},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
          config: tighter,
        ),
        CardUnlockSource.locked,
      );
      // 3 bursts → unlocks at the tightened threshold.
      expect(
        resolveCardUnlock(
          card: card,
          cardBurstCounts: const {'001/048': 3},
          cardsPurchased: const {},
          unlockedFromAchievements: const {},
          config: tighter,
        ),
        CardUnlockSource.burstThreshold,
      );
    });
  });
}
