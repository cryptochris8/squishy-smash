import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/service_locator.dart';
import 'content_loader.dart' show AssetReader;
import 'models/card_entry.dart';

/// Bundle paths for the two card manifests. Kept as constants here so
/// tests can reference the same canonical paths the production loader
/// uses (no string drift between test fixtures and runtime).
const String kCardManifestPath = 'assets/data/cards_manifest.json';
const String kCustomCardManifestPath =
    'assets/data/custom_cards_manifest.json';

/// Combined result of [CardManifestLoader.loadAll]. Either list may be
/// empty if the corresponding asset failed to load — failures are
/// logged via debugPrint but never crash bootstrap.
class LoadedCardManifest {
  const LoadedCardManifest({required this.cards, required this.custom});
  final List<CardEntry> cards;
  final List<CustomCardEntry> custom;
}

class CardManifestLoader {
  /// Read both manifests off the bundle. [readAsset] defaults to
  /// [rootBundle.loadString]; tests inject a fake reader to simulate
  /// missing or malformed JSON.
  Future<LoadedCardManifest> loadAll({AssetReader? readAsset}) async {
    final read = readAsset ?? rootBundle.loadString;
    final cards = await _loadCards(read);
    final custom = await _loadCustom(read);
    return LoadedCardManifest(cards: cards, custom: custom);
  }

  Future<List<CardEntry>> _loadCards(AssetReader read) async {
    try {
      final raw = await read(kCardManifestPath);
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(CardEntry.fromJson)
          .toList(growable: false);
    } catch (e, st) {
      // P1.23: route to diagnostics so Sentry sees a broken bundle.
      ServiceLocator.diagnostics.record(
        source: 'card_manifest',
        error: 'main manifest load failed: $e',
        stack: st,
      );
      return const <CardEntry>[];
    }
  }

  Future<List<CustomCardEntry>> _loadCustom(AssetReader read) async {
    try {
      final raw = await read(kCustomCardManifestPath);
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(CustomCardEntry.fromJson)
          .toList(growable: false);
    } catch (e, st) {
      ServiceLocator.diagnostics.record(
        source: 'card_manifest',
        error: 'custom manifest load failed: $e',
        stack: st,
      );
      return const <CustomCardEntry>[];
    }
  }
}
