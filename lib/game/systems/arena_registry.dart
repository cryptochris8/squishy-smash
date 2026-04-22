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
    required this.calmColors,
    required this.revealColors,
  });

  final String key;
  final List<Color> calmColors;
  final List<Color> revealColors;

  String get calmSpritePath => 'arenas/skybox_${key}_calm.png';
  String get revealSpritePath => 'arenas/skybox_${key}_reveal.png';
}

class ArenaRegistry {
  ArenaRegistry._();

  static const Map<String, ArenaTheme> _byKey = <String, ArenaTheme>{
    'candy_cloud_kitchen': ArenaTheme(
      key: 'candy_cloud_kitchen',
      calmColors: <Color>[Color(0xFFFFD1DC), Color(0xFFF4A58E)],
      revealColors: <Color>[Color(0xFFFFE7A0), Color(0xFFFFB5A7)],
    ),
    'gelatin_reef': ArenaTheme(
      key: 'gelatin_reef',
      calmColors: <Color>[Color(0xFF6EDCD9), Color(0xFF87CCC7)],
      revealColors: <Color>[Color(0xFFE4FBF9), Color(0xFF6EDCD9)],
    ),
    'creepy_cute_crypt': ArenaTheme(
      key: 'creepy_cute_crypt',
      calmColors: <Color>[Color(0xFF3B2F4F), Color(0xFF2A1B36)],
      revealColors: <Color>[Color(0xFFB084CC), Color(0xFF6E4B8B)],
    ),
    'goo_laboratory': ArenaTheme(
      key: 'goo_laboratory',
      calmColors: <Color>[Color(0xFFDAFFE4), Color(0xFFA8F4C8)],
      revealColors: <Color>[Color(0xFF5EE6A6), Color(0xFF32B874)],
    ),
    'mochi_sunset_beach': ArenaTheme(
      key: 'mochi_sunset_beach',
      calmColors: <Color>[Color(0xFFFFD9A3), Color(0xFFC97A6F)],
      revealColors: <Color>[Color(0xFFFFE7A0), Color(0xFFE9AAA0)],
    ),
    'neon_fidget_arcade': ArenaTheme(
      key: 'neon_fidget_arcade',
      calmColors: <Color>[Color(0xFF0E0820), Color(0xFF3BE8FF)],
      revealColors: <Color>[Color(0xFFFF3BAC), Color(0xFFB8FF3B)],
    ),
    'forest_dew_garden': ArenaTheme(
      key: 'forest_dew_garden',
      calmColors: <Color>[Color(0xFF8ED6A2), Color(0xFF4E8F68)],
      revealColors: <Color>[Color(0xFFE7F6EA), Color(0xFF7FB893)],
    ),
    'birthday_party_arena': ArenaTheme(
      key: 'birthday_party_arena',
      calmColors: <Color>[Color(0xFFFFD1DC), Color(0xFFFFE7A0)],
      revealColors: <Color>[Color(0xFFB8E0FF), Color(0xFFC9F0CE)],
    ),
  };

  /// Default theme when a pack's [arenaSuggestion] doesn't match any
  /// registered theme — keeps the game running with the launch pack's
  /// palette instead of crashing.
  static const ArenaTheme _fallback = ArenaTheme(
    key: 'candy_cloud_kitchen',
    calmColors: <Color>[Color(0xFF24172C), Color(0xFF120B17)],
    revealColors: <Color>[Color(0xFFFFD36E), Color(0xFFFF8FB8)],
  );

  static ArenaTheme themeFor(String? arenaSuggestion) {
    if (arenaSuggestion == null) return _fallback;
    return _byKey[arenaSuggestion] ?? _fallback;
  }

  static Iterable<ArenaTheme> get all => _byKey.values;
}
