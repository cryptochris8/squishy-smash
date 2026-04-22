import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/voice_line_registry.dart';

String _resolve(String audioPath) {
  // Registry uses "audio/..." paths; on disk these live under "assets/".
  return 'assets/$audioPath';
}

void main() {
  group('VoiceLineRegistry structure', () {
    test('every tier list is non-empty', () {
      expect(VoiceLineRegistry.revealRare, isNotEmpty);
      expect(VoiceLineRegistry.revealEpic, isNotEmpty);
      expect(VoiceLineRegistry.revealMythic, isNotEmpty);
      expect(VoiceLineRegistry.mega, isNotEmpty);
      expect(VoiceLineRegistry.asmrIdle, isNotEmpty);
    });

    test('mega has at least 3 variants for anti-repetition headroom', () {
      expect(VoiceLineRegistry.mega.length, greaterThanOrEqualTo(3));
    });

    test('rare/epic/mythic each have at least 2 variants', () {
      expect(VoiceLineRegistry.revealRare.length, greaterThanOrEqualTo(2));
      expect(VoiceLineRegistry.revealEpic.length, greaterThanOrEqualTo(2));
      expect(VoiceLineRegistry.revealMythic.length, greaterThanOrEqualTo(2));
    });

    test('allPaths is the union of every tier', () {
      final union = <String>{
        ...VoiceLineRegistry.revealRare,
        ...VoiceLineRegistry.revealEpic,
        ...VoiceLineRegistry.revealMythic,
        ...VoiceLineRegistry.mega,
        ...VoiceLineRegistry.asmrIdle,
      };
      expect(VoiceLineRegistry.allPaths.toSet(), union);
    });

    test('paths are unique across tiers', () {
      final all = VoiceLineRegistry.allPaths;
      expect(all.toSet().length, all.length);
    });

    test('dispatcherMap keys match FeedbackDispatcher conventions', () {
      final map = VoiceLineRegistry.dispatcherMap;
      expect(map.keys.toSet(), {
        'reveal_rare',
        'reveal_epic',
        'reveal_mythic',
        'mega',
      });
    });

    test('every path uses the audio/ prefix', () {
      for (final p in VoiceLineRegistry.allPaths) {
        expect(p, startsWith('audio/'));
        expect(p, endsWith('.mp3'));
      }
    });
  });

  group('VoiceLineRegistry disk presence', () {
    for (final path in VoiceLineRegistry.allPaths) {
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
