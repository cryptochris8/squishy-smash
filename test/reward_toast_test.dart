import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/reward_event.dart';
import 'package:squishy_smash/ui/widgets/reward_toast.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('RewardEvent factory constructors', () {
    test('duplicate factory uses cream tint + "Duplicate!" label', () {
      const event = RewardEvent.duplicate(id: 1, coinAmount: 25);
      expect(event.id, 1);
      expect(event.coinAmount, 25);
      expect(event.label, 'Duplicate!');
      expect(event.tint, 0xFFFFD36E);
    });

    test('milestone factory composes "Pack N%!" label + lime tint', () {
      const event = RewardEvent.milestone(
        id: 7,
        coinAmount: 100,
        percent: 50,
      );
      expect(event.id, 7);
      expect(event.coinAmount, 100);
      expect(event.label, 'Pack 50%!');
      expect(event.tint, 0xFFB6FF5C);
    });

    test('milestone label is short enough for a phone toast', () {
      // ≤ 16 chars keeps the toast on a single line at the standard
      // text style. Pin the contract so a future verbose label
      // doesn't blow out the layout.
      for (final p in [25, 50, 75, 100]) {
        final label =
            RewardEvent.milestone(id: 0, coinAmount: 1, percent: p).label;
        expect(label.length, lessThanOrEqualTo(16));
      }
    });
  });

  group('RewardToast widget rendering', () {
    testWidgets('renders the +N coin amount and label', (tester) async {
      var completed = false;
      await tester.pumpWidget(_wrap(RewardToast(
        event: const RewardEvent.duplicate(id: 1, coinAmount: 25),
        onComplete: () => completed = true,
      )));
      expect(find.text('+25'), findsOneWidget);
      expect(find.text('Duplicate!'), findsOneWidget);
      expect(completed, isFalse, reason: 'shouldnt fire mid-animation');
    });

    testWidgets('milestone toast shows the "Pack N%!" label',
        (tester) async {
      await tester.pumpWidget(_wrap(RewardToast(
        event: const RewardEvent.milestone(
          id: 1, coinAmount: 100, percent: 50,
        ),
        onComplete: () {},
      )));
      expect(find.text('+100'), findsOneWidget);
      expect(find.text('Pack 50%!'), findsOneWidget);
    });
  });

  group('RewardToast lifecycle', () {
    testWidgets('fires onComplete after the configured lifetime',
        (tester) async {
      var completed = false;
      await tester.pumpWidget(_wrap(RewardToast(
        event: const RewardEvent.duplicate(id: 1, coinAmount: 25),
        onComplete: () => completed = true,
        lifetime: const Duration(milliseconds: 300),
      )));
      // Halfway through — not yet done.
      await tester.pump(const Duration(milliseconds: 150));
      expect(completed, isFalse);
      // After full lifetime, onComplete must have fired.
      await tester.pump(const Duration(milliseconds: 200));
      expect(completed, isTrue);
    });

    testWidgets('drifts upward over its lifetime', (tester) async {
      // Sample the y-translation at three points across the animation.
      // Should monotonically decrease (negative y = upward in
      // Flutter's coordinate space).
      await tester.pumpWidget(_wrap(RewardToast(
        event: const RewardEvent.duplicate(id: 1, coinAmount: 25),
        onComplete: () {},
        lifetime: const Duration(milliseconds: 1000),
        driftPx: 40.0,
      )));

      double sampleDy() {
        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(RewardToast),
            matching: find.byType(Transform),
          ),
        );
        return transform.transform.getTranslation().y;
      }

      await tester.pump(const Duration(milliseconds: 50));
      final atStart = sampleDy();
      await tester.pump(const Duration(milliseconds: 400));
      final atMid = sampleDy();
      expect(atMid, lessThan(atStart),
          reason: 'toast should be moving upward (more negative y)');
      // Pump to completion so the addTearDown phase doesn't see a
      // dangling animation.
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('opacity fades in then fades out across lifetime',
        (tester) async {
      await tester.pumpWidget(_wrap(RewardToast(
        event: const RewardEvent.duplicate(id: 1, coinAmount: 25),
        onComplete: () {},
        lifetime: const Duration(milliseconds: 1000),
      )));

      double sampleOpacity() {
        final opacity = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(RewardToast),
            matching: find.byType(Opacity),
          ),
        );
        return opacity.opacity;
      }

      // Very early — partway through fade-in.
      await tester.pump(const Duration(milliseconds: 50));
      final early = sampleOpacity();
      // Middle hold — fully visible.
      await tester.pump(const Duration(milliseconds: 400));
      final mid = sampleOpacity();
      // Late — partway through fade-out.
      await tester.pump(const Duration(milliseconds: 450));
      final late = sampleOpacity();

      expect(mid, closeTo(1.0, 0.01),
          reason: 'mid-life toast should be at full opacity');
      expect(early, lessThan(mid),
          reason: 'early frame should be fading in (less than mid)');
      expect(late, lessThan(mid),
          reason: 'late frame should be fading out (less than mid)');

      // Pump to completion.
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
