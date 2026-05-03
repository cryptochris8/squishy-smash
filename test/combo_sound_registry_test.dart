import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/combo_controller.dart';
import 'package:squishy_smash/game/systems/combo_sound_registry.dart';

String _resolve(String audioPath) {
  // Registry uses "audio/..." paths; on disk these live under "assets/".
  return 'assets/$audioPath';
}

void main() {
  group('ComboSoundRegistry structure', () {
    test('every tier list is non-empty', () {
      expect(ComboSoundRegistry.tierStarter, isNotEmpty);
      expect(ComboSoundRegistry.tierStronger, isNotEmpty);
      expect(ComboSoundRegistry.tierRevealReady, isNotEmpty);
      expect(ComboSoundRegistry.tierMega, isNotEmpty);
    });

    test('every tier has ≥2 variants for anti-repetition', () {
      // 2 is the strict minimum so SoundVariantPicker has *something* to
      // alternate with. Combo milestones fire less frequently than reveals
      // (a player crosses a tier once per session per tier, not on every
      // hit), so the headroom requirement is lower than VO reveals.
      expect(ComboSoundRegistry.tierStarter.length, greaterThanOrEqualTo(2));
      expect(ComboSoundRegistry.tierStronger.length, greaterThanOrEqualTo(2));
      expect(ComboSoundRegistry.tierRevealReady.length, greaterThanOrEqualTo(2));
      expect(ComboSoundRegistry.tierMega.length, greaterThanOrEqualTo(2));
    });

    test('allPaths is the union of every tier', () {
      final union = <String>{
        ...ComboSoundRegistry.tierStarter,
        ...ComboSoundRegistry.tierStronger,
        ...ComboSoundRegistry.tierRevealReady,
        ...ComboSoundRegistry.tierMega,
      };
      expect(ComboSoundRegistry.allPaths.toSet(), union);
    });

    test('paths are unique across tiers', () {
      final all = ComboSoundRegistry.allPaths;
      expect(all.toSet().length, all.length);
    });

    test('every path uses the audio/sfx/combo/ prefix', () {
      for (final p in ComboSoundRegistry.allPaths) {
        expect(p, startsWith('audio/sfx/combo/'));
        expect(p, endsWith('.mp3'));
      }
    });

    test('dispatcherMap has all four firing ComboTier values', () {
      final map = ComboSoundRegistry.dispatcherMap;
      expect(map.keys.toSet(), {
        ComboTier.starter,
        ComboTier.stronger,
        ComboTier.revealReady,
        ComboTier.mega,
      });
    });

    test('dispatcherMap intentionally excludes ComboTier.none', () {
      // The call site filters out `none` before dispatching, so the
      // registry should not be queried with it. If a key for `none`
      // ever appears, it's a sign someone is dispatching incorrectly.
      expect(ComboSoundRegistry.dispatcherMap.containsKey(ComboTier.none),
          isFalse);
    });
  });

  group('ComboSoundRegistry disk presence', () {
    for (final path in ComboSoundRegistry.allPaths) {
      test('file exists on disk: $path', () {
        final f = File(_resolve(path));
        expect(f.existsSync(), isTrue,
            reason: 'missing asset at ${f.path}');
        expect(f.lengthSync(), greaterThan(1024),
            reason: 'file is suspiciously small (<1KB) — '
                'possibly an unpopulated stub: $path');
      });
    }
  });
}
