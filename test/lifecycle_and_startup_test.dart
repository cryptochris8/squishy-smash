import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level guards for the Pass-2 P1 startup + lifecycle fixes
/// landed alongside v0.1.1. Each test asserts the relevant file
/// still contains the structural change so a future refactor
/// cannot silently regress the fix without flipping a red bar.
///
/// Pin references:
/// - P1.1  — mute setting applied at SoundManager construction
/// - P1.2  — gameplay screen observes AppLifecycleState
/// - P1.14 — Sentry init uses appRunner so first frame isn't blocked
/// - P1.15 — sounds.warm() runs unawaited so bootstrap finishes early
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('P1.1 — mute setting applied at startup', () {
    test('service_locator wires persisted mute into SoundManager', () {
      final source = read('lib/core/service_locator.dart');
      expect(source, contains('sounds.muted = persistence.muted'),
          reason: 'A player who muted in a prior session must NOT '
              'hear full-volume audio during the bootstrap-to-Settings '
              'gap. Pin the assignment so a refactor cannot drop it.');
    });
  });

  group('P1.2 — AppLifecycle observer flushes mid-round', () {
    test('gameplay screen mixes WidgetsBindingObserver', () {
      final source = read('lib/ui/gameplay_screen.dart');
      expect(source, contains('with WidgetsBindingObserver'),
          reason: 'gameplay_screen.dart must mix in '
              'WidgetsBindingObserver so didChangeAppLifecycleState '
              'fires when the player backgrounds the app');
    });

    test('gameplay screen handles paused / detached lifecycle', () {
      final source = read('lib/ui/gameplay_screen.dart');
      expect(source, contains('didChangeAppLifecycleState'),
          reason: 'lifecycle handler must exist');
      expect(source, contains('AppLifecycleState.paused'),
          reason: 'paused is the iOS background trigger');
      expect(source, contains('finalizeRoundIfActive'),
          reason: 'must finalize the round so best-score / best-combo '
              'persist on backgrounding');
      expect(source, contains('flushPending'),
          reason: 'must flush debounced writes before the OS suspends');
    });

    test('SquishyGame exposes finalizeRoundIfActive', () {
      final source = read('lib/game/squishy_game.dart');
      expect(source, contains('finalizeRoundIfActive'),
          reason: 'public hook for the screen-level observer; without '
              'it the lifecycle handler has nothing to call');
    });
  });

  group('P1.14 — Sentry init uses appRunner', () {
    test('main.dart passes runApp through Sentry appRunner', () {
      final source = read('lib/main.dart');
      expect(source, contains('appRunner:'),
          reason: 'Sentry init must use the appRunner pattern so the '
              'SDK handshake does not block the first frame');
      // Bootstrap should run BEFORE Sentry init now (so the runner
      // can pass control to runApp immediately). Match the actual
      // `await SentryFlutter.init(` call site, not the explanatory
      // comment that names it.
      final bootstrapIndex =
          source.indexOf('await ServiceLocator.bootstrap()');
      // `appRunner:` only appears at the actual call site, not in
      // any of the explanatory comments above it.
      final sentryIndex = source.indexOf('appRunner:');
      expect(bootstrapIndex, greaterThan(0));
      expect(sentryIndex, greaterThan(0));
      expect(bootstrapIndex, lessThan(sentryIndex),
          reason: 'bootstrap should be awaited before Sentry init so '
              'the appRunner can hand off to runApp without further '
              'awaiting on bootstrap');
    });
  });

  group('P1.15 — sounds.warm() does not block bootstrap', () {
    test('service_locator wraps sounds.warm in unawaited', () {
      final source = read('lib/core/service_locator.dart');
      expect(source, contains('unawaited(sounds.warm'),
          reason: 'warming ~200 mp3 files synchronously during '
              'bootstrap added 1-2 s to startup; the play() path '
              'tolerates cache misses, so warm() should fire and '
              'forget');
    });
  });
}
