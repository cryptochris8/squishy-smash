import 'dart:math';

/// Rarity tier for a smashable. Drives reveal-moment gating,
/// particle intensity, and social-clip capture.
enum Rarity { common, rare, epic, mythic }

extension RarityX on Rarity {
  /// The string token used in JSON content packs.
  String get token {
    switch (this) {
      case Rarity.common:
        return 'common';
      case Rarity.rare:
        return 'rare';
      case Rarity.epic:
        return 'epic';
      case Rarity.mythic:
        return 'mythic';
    }
  }

  /// Player-facing label. The top tier is surfaced as "LEGENDARY"
  /// per the collectible rarity map, while the enum variant stays
  /// `mythic` internally to match the persisted token and voice-line
  /// registry keys. Callers that want a capitalized label use this.
  String get displayLabel {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.rare:
        return 'Rare';
      case Rarity.epic:
        return 'Epic';
      case Rarity.mythic:
        return 'Legendary';
    }
  }

  /// Default drop weight used when a pack does not override per-object weights.
  /// Higher = more likely. Tuned so mythic is < 1% and epic is ~4%.
  int get defaultWeight {
    switch (this) {
      case Rarity.common:
        return 750;
      case Rarity.rare:
        return 200;
      case Rarity.epic:
        return 45;
      case Rarity.mythic:
        return 5;
    }
  }

  /// Does this tier trigger a visible reveal moment (skybox swap,
  /// freeze-frame, reveal stinger)?
  bool get triggersReveal => index >= Rarity.rare.index;

  /// Does this tier trigger a saturation/contrast grade shift on reveal?
  bool get triggersColorGrade => index >= Rarity.epic.index;

  /// Is this tier rare enough to force a "Save this clip?" prompt?
  bool get promptsShareCapture => index >= Rarity.mythic.index;
}

/// Parse a rarity token to the enum. Unknown or null values fall back
/// to [Rarity.common] so older packs without the field keep working.
Rarity rarityFromToken(String? token) {
  switch (token) {
    case 'rare':
      return Rarity.rare;
    case 'epic':
      return Rarity.epic;
    case 'mythic':
      return Rarity.mythic;
    case 'common':
    case null:
    default:
      return Rarity.common;
  }
}

/// Weighted random selection across a list of items, keyed by [weightOf].
///
/// [rng] is injectable so tests can run deterministically by seeding
/// a [Random]. Throws [ArgumentError] if the list is empty.
T weightedPick<T>({
  required List<T> items,
  required int Function(T item) weightOf,
  Random? rng,
}) {
  if (items.isEmpty) {
    throw ArgumentError('weightedPick called on empty list');
  }
  final r = rng ?? Random();
  var total = 0;
  for (final it in items) {
    final w = weightOf(it);
    if (w < 0) {
      throw ArgumentError('weightedPick received negative weight $w');
    }
    total += w;
  }
  if (total == 0) {
    // All-zero weights: degenerate to uniform pick.
    return items[r.nextInt(items.length)];
  }
  var target = r.nextInt(total);
  for (final it in items) {
    target -= weightOf(it);
    if (target < 0) return it;
  }
  return items.last;
}
