import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/ui_sound_registry.dart';

void main() {
  group('UiSoundRegistry constants', () {
    test('all paths use the audio/ui/ prefix and .mp3 extension', () {
      for (final p in UiSoundRegistry.allPaths) {
        expect(p, startsWith('audio/ui/'));
        expect(p, endsWith('.mp3'));
      }
    });

    test('allPaths is the union of the individual constants', () {
      final union = <String>{
        UiSoundRegistry.buttonTap,
        UiSoundRegistry.confirm,
        UiSoundRegistry.coinDing,
        UiSoundRegistry.unlockChime,
        UiSoundRegistry.revealStinger,
        UiSoundRegistry.packSelect,
        UiSoundRegistry.settingsToggle,
        UiSoundRegistry.back,
      };
      expect(UiSoundRegistry.allPaths.toSet(), union);
      expect(UiSoundRegistry.allPaths.length, union.length);
    });
  });

  group('UI asset files exist on disk', () {
    for (final path in UiSoundRegistry.allPaths) {
      test('file exists: $path', () {
        final f = File('assets/$path');
        expect(f.existsSync(), isTrue,
            reason: 'missing UI stinger: ${f.path}');
        expect(f.lengthSync(), greaterThan(1024),
            reason: 'file is suspiciously small (<1KB): $path');
      });
    }
  });
}
