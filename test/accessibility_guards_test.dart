import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/ui/widgets/coin_badge.dart';

/// Source-level + widget-level guards for the Pass-2 P1
/// accessibility fixes. Each test pins the specific change so a
/// future refactor can't silently regress it.
///
/// Pin references:
/// - P1.10 — floating mascot honors MediaQuery.disableAnimations
/// - P1.12 — HUD score wraps in Semantics(liveRegion: true)
/// - P1.13 — CoinBadge: white text + Semantics label "$N coins"
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('P1.10 — reduce-motion in floating mascot', () {
    test('reads MediaQuery.disableAnimations and stops controller', () {
      final source = read('lib/ui/widgets/floating_mascot.dart');
      expect(source, contains('disableAnimations'),
          reason: 'mascot must respect system "Reduce Motion" so a '
              '4+ rated app passes Apple accessibility expectations');
      expect(source, contains('_controller.stop()'),
          reason: 'reduce-motion path should stop the animation, '
              'not just slow it');
    });
  });

  group('P1.12 — HUD score has a live-region semantic', () {
    test('hud_overlay wraps score in Semantics(liveRegion: true)', () {
      final source = read('lib/game/components/hud_overlay.dart');
      expect(source, contains('liveRegion: true'),
          reason: 'VoiceOver should re-announce the score on each '
              'change, not require manual focus refresh');
      expect(source, contains("'Score: \${data.score}'"),
          reason: 'semantic label must include the unit "Score: " — '
              'a bare number is unhelpful to assistive tech');
    });
  });

  group('P1.13 — CoinBadge contrast + label', () {
    testWidgets('renders white digits (was cream-on-cream — contrast fail)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CoinBadge(coins: 1234)),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('1234'));
      expect(textWidget.style?.color, Colors.white,
          reason: 'cream-on-cream-tint measured ~2.4:1 contrast '
              '(WCAG AA needs 4.5:1 for normal text)');
    });

    testWidgets('exposes the "<N> coins" semantic label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CoinBadge(coins: 42)),
        ),
      );
      expect(
        find.bySemanticsLabel('42 coins'),
        findsOneWidget,
        reason: 'VoiceOver must announce the unit so a player who '
            'cannot see the icon understands what the number means',
      );
      handle.dispose();
    });
  });
}
