import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:squishy_smash/ui/about_screen.dart';

/// GAME_POLISH_AUDIT.md UI-4 — verifies the About screen reads its
/// version from `String.fromEnvironment('APP_VERSION', ...)` instead
/// of a hardcoded literal. The default value tracks the in-flight
/// pubspec version (0.1.3 as of this commit); release builds override
/// via `--dart-define=APP_VERSION=$VERSION`.
///
/// This test pins:
///   (a) the default lines up with what the screen renders for local
///       dev (no --dart-define), and
///   (b) the surface element ('App version' label + value row) is
///       actually present on the About screen — catches the case
///       where someone refactors the screen but forgets to render
///       the value.
void main() {
  testWidgets('About screen renders an App version row with the default '
      'fallback when APP_VERSION is not passed via --dart-define',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );
    // Settle the initial layout.
    await tester.pump();
    expect(find.text('App version'), findsOneWidget,
        reason: 'label row must render so users can self-report version');
    // The default in about_screen.dart should match the in-flight
    // pubspec version. If you bump pubspec, bump this expected value
    // (and the default in AboutScreen).
    expect(find.text('0.1.3'), findsOneWidget,
        reason: 'default APP_VERSION value must match the pubspec target');
  });
}
