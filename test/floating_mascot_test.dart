import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/ui/widgets/floating_mascot.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

/// Walk the widget tree under [WidgetTester.element] and find the
/// `dy` offset of the FloatingMascot's Transform.translate. Used to
/// verify the bob is actually animating (not just static).
double _readBobDy(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(FloatingMascot),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.getTranslation().y;
}

void main() {
  group('FloatingMascot rendering', () {
    testWidgets('renders the asset image at the requested width',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const FloatingMascot(
          assetPath: 'assets/cards/final_48/016_Celestial_Dumpling_Core.webp',
          width: 180,
        ),
      ));
      expect(find.byType(Image), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      // The asset wiring should reach Image.asset's AssetImage provider.
      expect(image.image, isA<AssetImage>());
      expect(
        (image.image as AssetImage).assetName,
        'assets/cards/final_48/016_Celestial_Dumpling_Core.webp',
      );
    });

    testWidgets('falls back to an empty box when the asset is missing',
        (tester) async {
      // Real production path: a missing TTF/WebP/etc. shouldn't take
      // the menu down. The errorBuilder swaps in a SizedBox.shrink so
      // layout still completes.
      await tester.pumpWidget(_wrap(
        const FloatingMascot(
          assetPath: 'assets/does_not_exist.webp',
          width: 100,
        ),
      ));
      // Force the image to attempt resolution + fail-back.
      await tester.pump();
      // Mascot still mounts even if the asset can't load — that's the
      // contract. We don't assert on what's rendered inside; just
      // that the widget didn't throw.
      expect(find.byType(FloatingMascot), findsOneWidget);
    });
  });

  group('FloatingMascot bob animation', () {
    testWidgets('the dy offset varies over time (animation is running)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const FloatingMascot(
          assetPath: 'assets/cards/final_48/001_Soft_Dumpling.webp',
          width: 100,
          bobAmplitude: 10.0,
          bobDuration: Duration(milliseconds: 1000),
        ),
      ));
      await tester.pump();
      final atStart = _readBobDy(tester);
      // Quarter of the period should land near the peak amplitude.
      await tester.pump(const Duration(milliseconds: 250));
      final atQuarter = _readBobDy(tester);
      expect(atQuarter, isNot(equals(atStart)),
          reason: 'bob value should change between frames');
      expect(atQuarter.abs(), greaterThan(5.0),
          reason: 'after a quarter cycle of a 10-px amplitude bob, '
              'dy should be close to the peak');
    });

    testWidgets('bob stays inside the configured amplitude',
        (tester) async {
      // Defensive: never let the bob drift further than asked. A
      // numerical bug in the sine math could push the card outside
      // its laid-out box and clip the buttons below.
      await tester.pumpWidget(_wrap(
        const FloatingMascot(
          assetPath: 'assets/cards/final_48/001_Soft_Dumpling.webp',
          width: 100,
          bobAmplitude: 8.0,
          bobDuration: Duration(milliseconds: 500),
        ),
      ));
      // Sample 20 frames across one full cycle and check bounds.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        expect(_readBobDy(tester).abs(), lessThanOrEqualTo(8.001),
            reason: 'sample $i exceeded amplitude');
      }
    });
  });

  group('FloatingMascot lifecycle pause', () {
    testWidgets('stops animating when the app is backgrounded',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const FloatingMascot(
          assetPath: 'assets/cards/final_48/001_Soft_Dumpling.webp',
          width: 100,
          bobDuration: Duration(milliseconds: 1000),
        ),
      ));
      // Advance briefly so we know the animation is running.
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate the OS sending a "paused" lifecycle event.
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      final dyAtPause = _readBobDy(tester);
      // After 500 ms in the paused state, dy should not have moved —
      // the controller stopped, frames aren't being driven.
      await tester.pump(const Duration(milliseconds: 500));
      expect(_readBobDy(tester), dyAtPause,
          reason: 'bob should freeze while the app is backgrounded');
    });

    testWidgets('resumes animating when the app returns to foreground',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const FloatingMascot(
          assetPath: 'assets/cards/final_48/001_Soft_Dumpling.webp',
          width: 100,
          bobDuration: Duration(milliseconds: 1000),
        ),
      ));
      final binding = tester.binding;
      // Pause, then resume.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final dyAtPause = _readBobDy(tester);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      // Forward enough time for the controller to advance noticeably.
      await tester.pump(const Duration(milliseconds: 250));
      expect(_readBobDy(tester), isNot(equals(dyAtPause)),
          reason: 'bob should resume moving after returning to '
              'the foreground');
    });
  });
}
