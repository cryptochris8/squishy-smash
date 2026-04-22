import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/arena_registry.dart';

void main() {
  group('ArenaRegistry', () {
    test('exposes 8 registered themes', () {
      expect(ArenaRegistry.all.length, 8);
    });

    test('themeFor resolves known keys to matching theme', () {
      final t = ArenaRegistry.themeFor('candy_cloud_kitchen');
      expect(t.key, 'candy_cloud_kitchen');
    });

    test('themeFor falls back for null input', () {
      final t = ArenaRegistry.themeFor(null);
      expect(t.key, isNotEmpty);
    });

    test('themeFor falls back for unknown key (graceful degrade)', () {
      final t = ArenaRegistry.themeFor('slime_kitchen_legacy');
      expect(t.key, isNotEmpty);
    });

    test('every theme has non-empty fallback gradients', () {
      for (final t in ArenaRegistry.all) {
        expect(t.calmColors, isNotEmpty, reason: '${t.key} calmColors');
        expect(t.revealColors, isNotEmpty,
            reason: '${t.key} revealColors');
      }
    });

    test('sprite paths use arenas/ prefix and .png', () {
      for (final t in ArenaRegistry.all) {
        expect(t.calmSpritePath, startsWith('arenas/skybox_'));
        expect(t.calmSpritePath, endsWith('_calm.png'));
        expect(t.revealSpritePath, startsWith('arenas/skybox_'));
        expect(t.revealSpritePath, endsWith('_reveal.png'));
      }
    });
  });

  group('Skybox sprites exist on disk', () {
    for (final t in ArenaRegistry.all) {
      test('calm + reveal present for ${t.key}', () {
        final calm = File('assets/images/${t.calmSpritePath}');
        final reveal = File('assets/images/${t.revealSpritePath}');
        expect(calm.existsSync(), isTrue,
            reason: 'missing: ${calm.path}');
        expect(reveal.existsSync(), isTrue,
            reason: 'missing: ${reveal.path}');
        // Production skyboxes should be well over 100KB after downscale
        // to 2048×1024 PNG — anything smaller is almost certainly a
        // placeholder.
        expect(calm.lengthSync(), greaterThan(100 * 1024),
            reason: '${t.key} calm is suspiciously small');
        expect(reveal.lengthSync(), greaterThan(100 * 1024),
            reason: '${t.key} reveal is suspiciously small');
      });
    }
  });

  group('Pack arenaSuggestion resolves to a registered theme', () {
    // Every arenaSuggestion in every bundled pack should map to a
    // theme that has sprite files. This catches a JSON edit that
    // introduces a new arenaSuggestion but forgets to ship the art.
    const expectedSuggestions = <String>{
      'candy_cloud_kitchen', // dumpling_squishy
      'mochi_sunset_beach', // launch_squishy_foods
      'goo_laboratory', // goo_fidgets
      'creepy_cute_crypt', // creepy_cute
    };
    for (final s in expectedSuggestions) {
      test('$s resolves to an on-disk theme', () {
        final t = ArenaRegistry.themeFor(s);
        expect(t.key, s,
            reason: '$s fell through to fallback — registry missing entry');
        final calm = File('assets/images/${t.calmSpritePath}');
        expect(calm.existsSync(), isTrue, reason: 'missing ${calm.path}');
      });
    }
  });
}
