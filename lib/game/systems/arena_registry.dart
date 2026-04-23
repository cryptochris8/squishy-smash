import 'package:flutter/painting.dart';

/// Maps a pack's `arenaSuggestion` string to the skybox PNG filenames
/// (sans directory prefix) and the fallback gradient palette used when
/// the sprites aren't on disk yet.
///
/// Skybox PNGs live under `assets/images/arenas/` as
/// `skybox_{stem}_calm.png` and `skybox_{stem}_reveal.png` — the stem
/// matches an `ArenaTheme.key`.
class ArenaTheme {
  const ArenaTheme({
    required this.key,
    required this.displayName,
    required this.calmColors,
    required this.revealColors,
    this.cost = 0,
    this.bundledWithPack,
  });

  final String key;

  /// Human-readable name shown in shop / settings UI.
  final String displayName;

  final List<Color> calmColors;
  final List<Color> revealColors;

  /// Coin cost when purchased standalone via the shop. Pack-bundled
  /// arenas keep this at 0 — they unlock for free when their pack is
  /// purchased; the field is informational for those rows.
  final int cost;

  /// If non-null, this arena is auto-granted when the player unlocks
  /// the named pack. Used by ProgressionRepository.tryUnlock to keep
  /// arena-with-pack as a single transaction.
  final String? bundledWithPack;

  String get calmSpritePath => 'arenas/skybox_${key}_calm.png';
  String get revealSpritePath => 'arenas/skybox_${key}_reveal.png';

  /// True when this arena is buyable as its own SKU (not a pack
  /// bundle). The shop's Arenas section lists these.
  bool get isStandalone => bundledWithPack == null && cost > 0;
}

class ArenaRegistry {
  ArenaRegistry._();

  static const Map<String, ArenaTheme> _byKey = <String, ArenaTheme>{
    // -- pack-bundled arenas (cost 0, unlocked when pack is bought) ----
    'candy_cloud_kitchen': ArenaTheme(
      key: 'candy_cloud_kitchen',
      displayName: 'Candy Cloud Kitchen',
      calmColors: <Color>[Color(0xFFFFD1DC), Color(0xFFF4A58E)],
      revealColors: <Color>[Color(0xFFFFE7A0), Color(0xFFFFB5A7)],
      bundledWithPack: 'dumpling_squishy_drop_01',
    ),
    'creepy_cute_crypt': ArenaTheme(
      key: 'creepy_cute_crypt',
      displayName: 'Creepy-Cute Crypt',
      calmColors: <Color>[Color(0xFF3B2F4F), Color(0xFF2A1B36)],
      revealColors: <Color>[Color(0xFFB084CC), Color(0xFF6E4B8B)],
      bundledWithPack: 'creepy_cute_pack_01',
    ),
    'goo_laboratory': ArenaTheme(
      key: 'goo_laboratory',
      displayName: 'Goo Laboratory',
      calmColors: <Color>[Color(0xFFDAFFE4), Color(0xFFA8F4C8)],
      revealColors: <Color>[Color(0xFF5EE6A6), Color(0xFF32B874)],
      bundledWithPack: 'goo_fidgets_drop_01',
    ),
    'mochi_sunset_beach': ArenaTheme(
      key: 'mochi_sunset_beach',
      displayName: 'Mochi Sunset Beach',
      calmColors: <Color>[Color(0xFFFFD9A3), Color(0xFFC97A6F)],
      revealColors: <Color>[Color(0xFFFFE7A0), Color(0xFFE9AAA0)],
      bundledWithPack: 'launch_squishy_foods',
    ),
    // -- standalone arena SKUs (purchased directly in the shop) --------
    'gelatin_reef': ArenaTheme(
      key: 'gelatin_reef',
      displayName: 'Gelatin Reef',
      calmColors: <Color>[Color(0xFF6EDCD9), Color(0xFF87CCC7)],
      revealColors: <Color>[Color(0xFFE4FBF9), Color(0xFF6EDCD9)],
      cost: 150,
    ),
    'neon_fidget_arcade': ArenaTheme(
      key: 'neon_fidget_arcade',
      displayName: 'Neon Fidget Arcade',
      calmColors: <Color>[Color(0xFF0E0820), Color(0xFF3BE8FF)],
      revealColors: <Color>[Color(0xFFFF3BAC), Color(0xFFB8FF3B)],
      cost: 150,
    ),
    'forest_dew_garden': ArenaTheme(
      key: 'forest_dew_garden',
      displayName: 'Forest Dew Garden',
      calmColors: <Color>[Color(0xFF8ED6A2), Color(0xFF4E8F68)],
      revealColors: <Color>[Color(0xFFE7F6EA), Color(0xFF7FB893)],
      cost: 100,
    ),
    'birthday_party_arena': ArenaTheme(
      key: 'birthday_party_arena',
      displayName: 'Birthday Party',
      calmColors: <Color>[Color(0xFFFFD1DC), Color(0xFFFFE7A0)],
      revealColors: <Color>[Color(0xFFB8E0FF), Color(0xFFC9F0CE)],
      cost: 100,
    ),
  };

  /// Default theme when a pack's [arenaSuggestion] doesn't match any
  /// registered theme — keeps the game running with the launch pack's
  /// palette instead of crashing.
  static const ArenaTheme _fallback = ArenaTheme(
    key: 'mochi_sunset_beach',
    displayName: 'Mochi Sunset Beach',
    calmColors: <Color>[Color(0xFF24172C), Color(0xFF120B17)],
    revealColors: <Color>[Color(0xFFFFD36E), Color(0xFFFF8FB8)],
  );

  /// The arena a brand-new player starts in (matches the launch pack).
  static const String defaultActiveKey = 'mochi_sunset_beach';

  static ArenaTheme themeFor(String? arenaSuggestion) {
    if (arenaSuggestion == null) return _fallback;
    return _byKey[arenaSuggestion] ?? _fallback;
  }

  /// Direct lookup by arena key. Returns the fallback theme for unknown
  /// keys so callers don't need null-handling boilerplate.
  static ArenaTheme byKey(String key) => _byKey[key] ?? _fallback;

  /// Whether the given key is a registered arena. Useful when
  /// validating user-selected active-arena values from persistence.
  static bool isKnown(String key) => _byKey.containsKey(key);

  static Iterable<ArenaTheme> get all => _byKey.values;

  /// Standalone-purchasable arenas (the four orphaned themes that don't
  /// ship with any object pack). Used by the shop's Arenas section.
  static Iterable<ArenaTheme> get standalone =>
      _byKey.values.where((t) => t.isStandalone);
}
