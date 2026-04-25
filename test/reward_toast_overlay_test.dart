import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/systems/reward_event.dart';
import 'package:squishy_smash/ui/widgets/reward_toast.dart';
import 'package:squishy_smash/ui/widgets/reward_toast_overlay.dart';

Widget _wrap(Widget overlay) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('background')),
            overlay,
          ],
        ),
      ),
    );

void main() {
  group('RewardToastOverlay — empty state', () {
    testWidgets('renders nothing while no events have arrived',
        (tester) async {
      final controller = StreamController<RewardEvent>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(_wrap(
        RewardToastOverlay(events: controller.stream),
      ));
      expect(find.byType(RewardToast), findsNothing);
    });
  });

  group('RewardToastOverlay — event handling', () {
    testWidgets('a new event spawns a toast', (tester) async {
      final controller = StreamController<RewardEvent>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(_wrap(
        RewardToastOverlay(events: controller.stream),
      ));
      controller.add(const RewardEvent.duplicate(id: 1, coinAmount: 25));
      await tester.pump();
      expect(find.byType(RewardToast), findsOneWidget);
      expect(find.text('+25'), findsOneWidget);
      expect(find.text('Duplicate!'), findsOneWidget);
    });

    testWidgets('multiple events stack as separate toasts',
        (tester) async {
      final controller = StreamController<RewardEvent>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(_wrap(
        RewardToastOverlay(events: controller.stream),
      ));
      controller.add(const RewardEvent.duplicate(id: 1, coinAmount: 25));
      controller.add(const RewardEvent.milestone(
        id: 2, coinAmount: 100, percent: 50,
      ));
      await tester.pump();
      expect(find.byType(RewardToast), findsNWidgets(2));
      expect(find.text('Duplicate!'), findsOneWidget);
      expect(find.text('Pack 50%!'), findsOneWidget);
    });

    testWidgets('a toast removes itself after its lifetime',
        (tester) async {
      // RewardToast's default lifetime is 1500ms; once it ends, the
      // overlay gets the onComplete callback and should drop the
      // event from its active list.
      final controller = StreamController<RewardEvent>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(_wrap(
        RewardToastOverlay(events: controller.stream),
      ));
      controller.add(const RewardEvent.duplicate(id: 1, coinAmount: 25));
      await tester.pump();
      expect(find.byType(RewardToast), findsOneWidget);
      // Advance past the lifetime.
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(RewardToast), findsNothing,
          reason: 'expired toast must be removed from the active list');
    });

    testWidgets('toast removal is per-event — others stay alive',
        (tester) async {
      final controller = StreamController<RewardEvent>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(_wrap(
        RewardToastOverlay(events: controller.stream),
      ));
      // First event fires.
      controller.add(const RewardEvent.duplicate(id: 1, coinAmount: 25));
      await tester.pump();
      // 800ms later, second event fires.
      await tester.pump(const Duration(milliseconds: 800));
      controller.add(const RewardEvent.milestone(
        id: 2, coinAmount: 100, percent: 50,
      ));
      await tester.pump();
      expect(find.byType(RewardToast), findsNWidgets(2));
      // Now advance past the FIRST toast's lifetime (it was started
      // at t=0, so 1500ms total = 700ms more from here).
      await tester.pump(const Duration(milliseconds: 750));
      // First toast should be gone, second still alive.
      expect(find.byType(RewardToast), findsOneWidget);
      expect(find.text('Pack 50%!'), findsOneWidget);
      expect(find.text('Duplicate!'), findsNothing);
      // Pump out the rest so no animations leak past the test.
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });

  group('RewardToastOverlay — disposal', () {
    testWidgets('cancels its subscription when removed from the tree',
        (tester) async {
      final controller = StreamController<RewardEvent>.broadcast();
      // Open the overlay, then remove it. The stream should have no
      // active listeners after the widget unmounts. (If the
      // subscription leaked, controller.hasListener stays true.)
      await tester.pumpWidget(_wrap(
        RewardToastOverlay(events: controller.stream),
      ));
      expect(controller.hasListener, isTrue);
      // Replace with an empty page to unmount the overlay.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      expect(controller.hasListener, isFalse,
          reason: 'overlay must cancel its subscription on dispose');
      await controller.close();
    });
  });
}
