import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/card_manifest_loader.dart';
import 'package:squishy_smash/data/models/card_entry.dart';
import 'package:squishy_smash/data/models/rarity.dart';

/// Read manifest JSON straight off disk (relative to the package root,
/// where `flutter test` runs). Bypasses rootBundle so the canonical
/// shipping manifests are validated directly.
List<CardEntry> _loadFromDisk() {
  final raw = File('assets/data/cards_manifest.json').readAsStringSync();
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .cast<Map<String, dynamic>>()
      .map(CardEntry.fromJson)
      .toList(growable: false);
}

List<CustomCardEntry> _loadCustomFromDisk() {
  final raw =
      File('assets/data/custom_cards_manifest.json').readAsStringSync();
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .cast<Map<String, dynamic>>()
      .map(CustomCardEntry.fromJson)
      .toList(growable: false);
}

class _FakeAssets {
  final Map<String, String> _bodies = {};
  final Map<String, Object> _errors = {};
  void put(String path, String body) => _bodies[path] = body;
  void fail(String path, Object err) => _errors[path] = err;
  Future<String> read(String path) async {
    if (_errors.containsKey(path)) throw _errors[path]!;
    if (_bodies.containsKey(path)) return _bodies[path]!;
    throw StateError('No fake asset for $path');
  }
}

void main() {
  group('Card manifest shape', () {
    late final List<CardEntry> cards;
    setUpAll(() {
      cards = _loadFromDisk();
    });

    test('contains exactly 48 entries', () {
      expect(cards, hasLength(48));
    });

    test('cards 1-48 are present and contiguous', () {
      final indexes = cards.map((c) => c.index).toList()..sort();
      expect(indexes, List.generate(48, (i) => i + 1));
    });

    test('card numbers follow the "NNN/048" format', () {
      for (final card in cards) {
        expect(
          card.cardNumber,
          matches(RegExp(r'^\d{3}/048$')),
          reason: 'card ${card.index} has malformed cardNumber '
              '"${card.cardNumber}"',
        );
      }
    });

    test('every name is non-empty', () {
      for (final card in cards) {
        expect(card.name, isNotEmpty, reason: 'card ${card.index}');
      }
    });

    test('per-pack distribution is exactly 16/16/16', () {
      final byPack = <CardPack, int>{for (final p in CardPack.values) p: 0};
      for (final card in cards) {
        byPack[card.pack] = byPack[card.pack]! + 1;
      }
      expect(byPack[CardPack.squishyFoods], 16);
      expect(byPack[CardPack.gooAndFidgets], 16);
      expect(byPack[CardPack.creepyCuteCreatures], 16);
    });

    test('each pack has the canonical 8C/4R/3E/1L rarity composition', () {
      for (final pack in CardPack.values) {
        final inPack = cards.where((c) => c.pack == pack);
        final counts = <Rarity, int>{for (final r in Rarity.values) r: 0};
        for (final c in inPack) {
          counts[c.rarity] = counts[c.rarity]! + 1;
        }
        expect(counts[Rarity.common], 8,
            reason: '${pack.displayLabel} commons');
        expect(counts[Rarity.rare], 4,
            reason: '${pack.displayLabel} rares');
        expect(counts[Rarity.epic], 3,
            reason: '${pack.displayLabel} epics');
        expect(counts[Rarity.mythic], 1,
            reason: '${pack.displayLabel} legendaries (mythic)');
      }
    });

    test('packs partition the index range cleanly', () {
      // 1-16 = Squishy Foods, 17-32 = Goo & Fidgets, 33-48 = Creepy-Cute.
      // The numbering scheme is part of the manifest contract — anyone
      // reorganizing has to update both the JSON and the manifest doc.
      for (final card in cards) {
        if (card.index <= 16) {
          expect(card.pack, CardPack.squishyFoods,
              reason: 'card ${card.index} pack mismatch');
        } else if (card.index <= 32) {
          expect(card.pack, CardPack.gooAndFidgets);
        } else {
          expect(card.pack, CardPack.creepyCuteCreatures);
        }
      }
    });

    test('asset paths point at WebP under assets/cards/final_48/', () {
      for (final card in cards) {
        expect(card.assetPath,
            startsWith('assets/cards/final_48/'),
            reason: 'card ${card.index} bad path: ${card.assetPath}');
        expect(card.assetPath, endsWith('.webp'),
            reason: 'card ${card.index} should be .webp (got '
                '${card.assetPath})');
      }
    });

    test('every card asset file exists on disk', () {
      for (final card in cards) {
        final f = File(card.assetPath);
        expect(f.existsSync(), isTrue,
            reason: 'missing asset for card ${card.index} '
                '(${card.name}): ${card.assetPath}');
      }
    });

    test('asset filenames are >5KB (catches stub placeholders)', () {
      for (final card in cards) {
        final size = File(card.assetPath).lengthSync();
        expect(size, greaterThan(5 * 1024),
            reason: 'card ${card.index} asset is suspiciously small: '
                '$size bytes at ${card.assetPath}');
      }
    });
  });

  group('Custom family card manifest', () {
    late final List<CustomCardEntry> custom;
    setUpAll(() {
      custom = _loadCustomFromDisk();
    });

    test('contains the three documented family cards', () {
      expect(custom, hasLength(3));
      expect(
        custom.map((c) => c.name).toSet(),
        {'Eggy Ellie', 'Apple Addy', 'Hot Dog Heidi'},
      );
    });

    test('asset paths point at WebP under assets/cards/custom_family/', () {
      for (final card in custom) {
        expect(card.assetPath,
            startsWith('assets/cards/custom_family/'));
        expect(card.assetPath, endsWith('.webp'));
      }
    });

    test('every custom asset file exists on disk', () {
      for (final card in custom) {
        expect(File(card.assetPath).existsSync(), isTrue,
            reason: 'missing custom asset: ${card.assetPath}');
      }
    });
  });

  group('CardManifestLoader resilience', () {
    test('loads both manifests when both are present and valid', () async {
      final fake = _FakeAssets();
      fake.put(kCardManifestPath, jsonEncode([
        {
          'card_number': '001/048',
          'name': 'Test Card',
          'pack': 'Squishy Foods',
          'rarity': 'Common',
          'packaged_filename': 'assets/cards/final_48/001_Test.webp',
        },
      ]));
      fake.put(kCustomCardManifestPath, jsonEncode([
        {
          'card_number': '#042',
          'name': 'Test Custom',
          'packaged_filename': 'assets/cards/custom_family/Test.webp',
        },
      ]));
      final loaded =
          await CardManifestLoader().loadAll(readAsset: fake.read);
      expect(loaded.cards, hasLength(1));
      expect(loaded.cards.first.name, 'Test Card');
      expect(loaded.cards.first.pack, CardPack.squishyFoods);
      expect(loaded.cards.first.rarity, Rarity.common);
      expect(loaded.custom, hasLength(1));
      expect(loaded.custom.first.name, 'Test Custom');
    });

    test('returns empty cards list on malformed main manifest', () async {
      final fake = _FakeAssets();
      fake.put(kCardManifestPath, '{ not json');
      fake.put(kCustomCardManifestPath, jsonEncode(<dynamic>[]));
      final loaded =
          await CardManifestLoader().loadAll(readAsset: fake.read);
      expect(loaded.cards, isEmpty);
      expect(loaded.custom, isEmpty);
    });

    test('returns empty custom list when only the custom manifest is missing',
        () async {
      final fake = _FakeAssets();
      fake.put(kCardManifestPath, jsonEncode(<dynamic>[]));
      fake.fail(kCustomCardManifestPath, StateError('missing'));
      final loaded =
          await CardManifestLoader().loadAll(readAsset: fake.read);
      // Main manifest still loads fine; custom degrades gracefully.
      expect(loaded.cards, isEmpty);
      expect(loaded.custom, isEmpty);
    });

    test('main manifest failure does not block the custom manifest',
        () async {
      // Inverse of the above — confirms each manifest loads independently.
      final fake = _FakeAssets();
      fake.fail(kCardManifestPath, StateError('boom'));
      fake.put(kCustomCardManifestPath, jsonEncode([
        {
          'card_number': '#042',
          'name': 'Eggy Ellie',
          'packaged_filename': 'assets/cards/custom_family/Eggy_Ellie.webp',
        },
      ]));
      final loaded =
          await CardManifestLoader().loadAll(readAsset: fake.read);
      expect(loaded.cards, isEmpty);
      expect(loaded.custom, hasLength(1));
      expect(loaded.custom.first.name, 'Eggy Ellie');
    });
  });

  group('CardEntry / CustomCardEntry parsing', () {
    test('rarity label "Legendary" maps to Rarity.mythic', () {
      // Manifest uses player-facing "Legendary"; internal enum is `mythic`.
      // This split is documented in rarity.dart — the test pins it down.
      final entry = CardEntry.fromJson({
        'card_number': '048/048',
        'name': 'Test Mythic',
        'pack': 'Creepy-Cute Creatures',
        'rarity': 'Legendary',
        'packaged_filename': 'assets/cards/final_48/048.webp',
      });
      expect(entry.rarity, Rarity.mythic);
    });

    test('unknown pack label throws ArgumentError', () {
      expect(
        () => CardEntry.fromJson({
          'card_number': '001/048',
          'name': 'X',
          'pack': 'Made Up Pack',
          'rarity': 'Common',
          'packaged_filename': 'assets/cards/final_48/001.webp',
        }),
        throwsArgumentError,
      );
    });

    test('unknown rarity label throws ArgumentError', () {
      expect(
        () => CardEntry.fromJson({
          'card_number': '001/048',
          'name': 'X',
          'pack': 'Squishy Foods',
          'rarity': 'Ultra-Mythic',
          'packaged_filename': 'assets/cards/final_48/001.webp',
        }),
        throwsArgumentError,
      );
    });

    test('CardEntry.index extracts integer from "NNN/048" string', () {
      final entry = CardEntry.fromJson({
        'card_number': '012/048',
        'name': 'X',
        'pack': 'Squishy Foods',
        'rarity': 'Rare',
        'packaged_filename': 'assets/cards/final_48/012.webp',
      });
      expect(entry.index, 12);
    });
  });
}
