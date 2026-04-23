import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/rarity.dart';

void main() {
  group('rarityFromToken', () {
    test('parses known tokens', () {
      expect(rarityFromToken('common'), Rarity.common);
      expect(rarityFromToken('rare'), Rarity.rare);
      expect(rarityFromToken('epic'), Rarity.epic);
      expect(rarityFromToken('mythic'), Rarity.mythic);
    });

    test('defaults unknown and null to common', () {
      expect(rarityFromToken(null), Rarity.common);
      expect(rarityFromToken(''), Rarity.common);
      expect(rarityFromToken('nonsense'), Rarity.common);
    });

    test('is case-sensitive (tokens must be lowercase)', () {
      expect(rarityFromToken('Rare'), Rarity.common);
      expect(rarityFromToken('MYTHIC'), Rarity.common);
    });
  });

  group('RarityX', () {
    test('token round-trips through rarityFromToken', () {
      for (final r in Rarity.values) {
        expect(rarityFromToken(r.token), r);
      }
    });

    test('default weights descend by tier', () {
      expect(Rarity.common.defaultWeight,
          greaterThan(Rarity.rare.defaultWeight));
      expect(Rarity.rare.defaultWeight,
          greaterThan(Rarity.epic.defaultWeight));
      expect(Rarity.epic.defaultWeight,
          greaterThan(Rarity.mythic.defaultWeight));
    });

    test('mythic probability is below 1% of total weight', () {
      final totalWeight = Rarity.values
          .map((r) => r.defaultWeight)
          .fold<int>(0, (a, b) => a + b);
      final mythicPct = Rarity.mythic.defaultWeight / totalWeight;
      expect(mythicPct, lessThan(0.01));
    });

    test('triggersReveal starts at rare tier', () {
      expect(Rarity.common.triggersReveal, isFalse);
      expect(Rarity.rare.triggersReveal, isTrue);
      expect(Rarity.epic.triggersReveal, isTrue);
      expect(Rarity.mythic.triggersReveal, isTrue);
    });

    test('triggersColorGrade starts at epic tier', () {
      expect(Rarity.common.triggersColorGrade, isFalse);
      expect(Rarity.rare.triggersColorGrade, isFalse);
      expect(Rarity.epic.triggersColorGrade, isTrue);
      expect(Rarity.mythic.triggersColorGrade, isTrue);
    });

    test('promptsShareCapture is mythic-only', () {
      expect(Rarity.common.promptsShareCapture, isFalse);
      expect(Rarity.rare.promptsShareCapture, isFalse);
      expect(Rarity.epic.promptsShareCapture, isFalse);
      expect(Rarity.mythic.promptsShareCapture, isTrue);
    });

    test('displayLabel surfaces top tier as "Legendary" (not mythic)', () {
      expect(Rarity.common.displayLabel, 'Common');
      expect(Rarity.rare.displayLabel, 'Rare');
      expect(Rarity.epic.displayLabel, 'Epic');
      expect(Rarity.mythic.displayLabel, 'Legendary');
    });
  });

  group('weightedPick', () {
    test('throws on empty list', () {
      expect(
        () => weightedPick<int>(items: <int>[], weightOf: (_) => 1),
        throwsArgumentError,
      );
    });

    test('throws on negative weight', () {
      expect(
        () => weightedPick<int>(items: [1, 2], weightOf: (i) => -i),
        throwsArgumentError,
      );
    });

    test('all-zero weights degrades to uniform', () {
      final rng = Random(42);
      final counts = <int, int>{0: 0, 1: 0, 2: 0};
      for (var i = 0; i < 3000; i++) {
        final pick = weightedPick<int>(
          items: const [0, 1, 2],
          weightOf: (_) => 0,
          rng: rng,
        );
        counts[pick] = counts[pick]! + 1;
      }
      // each bucket should be roughly 1/3 with RNG of 3000 trials;
      // allow a generous band to avoid flaky tests.
      for (final c in counts.values) {
        expect(c, greaterThan(850));
        expect(c, lessThan(1150));
      }
    });

    test('higher-weight items are picked more often', () {
      final rng = Random(7);
      const items = ['common', 'rare', 'mythic'];
      int weightOf(String s) {
        switch (s) {
          case 'common':
            return 900;
          case 'rare':
            return 95;
          case 'mythic':
            return 5;
        }
        return 1;
      }

      final counts = <String, int>{for (final s in items) s: 0};
      const trials = 20000;
      for (var i = 0; i < trials; i++) {
        final pick =
            weightedPick<String>(items: items, weightOf: weightOf, rng: rng);
        counts[pick] = counts[pick]! + 1;
      }
      expect(counts['common']!, greaterThan(counts['rare']!));
      expect(counts['rare']!, greaterThan(counts['mythic']!));
      // Mythic at 0.5% should land in roughly [0.3%, 0.8%] window across
      // 20k trials.
      final mythicRate = counts['mythic']! / trials;
      expect(mythicRate, greaterThan(0.002));
      expect(mythicRate, lessThan(0.012));
    });

    test('deterministic with a seeded RNG', () {
      List<int> run(int seed) {
        final rng = Random(seed);
        return List.generate(
          50,
          (_) => weightedPick<int>(
            items: const [0, 1, 2, 3],
            weightOf: (i) => (i + 1) * 10,
            rng: rng,
          ),
        );
      }

      expect(run(99), run(99));
      expect(run(99), isNot(equals(run(100))));
    });
  });
}
