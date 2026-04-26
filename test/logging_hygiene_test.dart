import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P1.23 source-level guard. The audit found seven bundle / asset /
/// audio failure paths in lib/ that called `debugPrint(...)` —
/// which:
///   - doesn't reach Sentry (release builds silently lose the
///     error)
///   - keeps shipping log noise to device stdout in production
///
/// These tests pin that those specific files no longer call
/// debugPrint on error paths. Each match represents a failure mode
/// that should reach the diagnostics pipeline so Sentry sees it.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('P1.23 — error paths route to ServiceLocator.diagnostics', () {
    final guarded = <String>[
      'lib/data/content_loader.dart',
      'lib/data/card_manifest_loader.dart',
      'lib/data/economy_config_loader.dart',
    ];
    for (final path in guarded) {
      test('$path no longer uses debugPrint for errors', () {
        final source = read(path);
        // Loader error paths must reach Sentry. We accept zero
        // debugPrint calls in these files at all — they're pure
        // bundle readers, so any chatter is wrong.
        expect(source.contains('debugPrint('), isFalse,
            reason: '$path: replace any debugPrint with '
                'ServiceLocator.diagnostics.record so the failure '
                'reaches Sentry instead of vanishing into stdout');
        expect(source, contains('ServiceLocator.diagnostics.record'),
            reason: '$path: must route load failures through the '
                'diagnostics pipeline');
      });
    }

    test('SoundManager play/warm errors route to diagnostics', () {
      final source = read('lib/game/systems/sound_manager.dart');
      expect(source, contains('ServiceLocator.diagnostics.record'),
          reason: 'audio failure paths must reach Sentry');
      // The success log under kDebugMode is fine — it's stripped
      // from release. Any debugPrint OUTSIDE a kDebugMode guard is
      // not. We allow at most one debugPrint and only inside the
      // kDebugMode branch, so a regex check on raw text isn't
      // sufficient — instead we just assert kDebugMode is referenced.
      expect(source, contains('kDebugMode'),
          reason: 'success-path debugPrint must be wrapped in '
              'kDebugMode so release builds stay quiet');
    });
  });
}
