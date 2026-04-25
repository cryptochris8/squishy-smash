import 'rarity.dart';

/// Which named pack a [CardEntry] belongs to. The card manifest uses
/// human-friendly labels ("Squishy Foods", "Goo & Fidgets", "Creepy-
/// Cute Creatures") rather than the bundled-pack JSON IDs; this enum
/// preserves the same partition without coupling card display to the
/// gameplay pack registry.
enum CardPack { squishyFoods, gooAndFidgets, creepyCuteCreatures }

extension CardPackX on CardPack {
  /// Manifest-side display label. Stable — used as the JSON `pack`
  /// field, so renaming requires a manifest migration.
  String get displayLabel {
    switch (this) {
      case CardPack.squishyFoods:
        return 'Squishy Foods';
      case CardPack.gooAndFidgets:
        return 'Goo & Fidgets';
      case CardPack.creepyCuteCreatures:
        return 'Creepy-Cute Creatures';
    }
  }
}

CardPack cardPackFromLabel(String label) {
  switch (label) {
    case 'Squishy Foods':
      return CardPack.squishyFoods;
    case 'Goo & Fidgets':
      return CardPack.gooAndFidgets;
    case 'Creepy-Cute Creatures':
      return CardPack.creepyCuteCreatures;
  }
  throw ArgumentError('Unknown card pack label: "$label"');
}

/// One card in the 48-card collection binder. Loaded from
/// `assets/data/cards_manifest.json` — see `CardManifestLoader`.
///
/// `cardNumber` is the display string ("001/048"); the integer
/// position is in `index` (1-48). `assetPath` is the WebP location
/// in the bundle.
class CardEntry {
  const CardEntry({
    required this.index,
    required this.cardNumber,
    required this.name,
    required this.pack,
    required this.rarity,
    required this.assetPath,
  });

  final int index;
  final String cardNumber;
  final String name;
  final CardPack pack;
  final Rarity rarity;
  final String assetPath;

  factory CardEntry.fromJson(Map<String, dynamic> json) {
    final cardNumber = json['card_number'] as String;
    // "012/048" -> 12. Tolerate both "012/048" and bare integer-string.
    final indexStr = cardNumber.split('/').first;
    final index = int.parse(indexStr);
    return CardEntry(
      index: index,
      cardNumber: cardNumber,
      name: json['name'] as String,
      pack: cardPackFromLabel(json['pack'] as String),
      rarity: _rarityFromManifest(json['rarity'] as String),
      assetPath: json['packaged_filename'] as String,
    );
  }
}

/// One personal/family-only keepsake card. The manifest doesn't carry
/// a pack or rarity, so this stays a separate type to prevent the
/// custom set from leaking into the main 48-card progression.
class CustomCardEntry {
  const CustomCardEntry({
    required this.cardNumber,
    required this.name,
    required this.assetPath,
  });

  final String cardNumber;
  final String name;
  final String assetPath;

  factory CustomCardEntry.fromJson(Map<String, dynamic> json) {
    return CustomCardEntry(
      cardNumber: json['card_number'] as String,
      name: json['name'] as String,
      assetPath: json['packaged_filename'] as String,
    );
  }
}

/// The manifest stores rarity as a capitalized word ("Common", "Rare",
/// "Epic", "Legendary"). The internal Rarity enum uses lowercase tokens
/// with `mythic` for the top tier — bridge here so callers downstream
/// can keep using Rarity directly.
Rarity _rarityFromManifest(String label) {
  switch (label) {
    case 'Common':
      return Rarity.common;
    case 'Rare':
      return Rarity.rare;
    case 'Epic':
      return Rarity.epic;
    case 'Legendary':
      return Rarity.mythic;
  }
  throw ArgumentError('Unknown rarity label in manifest: "$label"');
}
