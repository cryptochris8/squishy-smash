import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/game/share_capture.dart';

void main() {
  group('ShareCaptions', () {
    test('every tier list is non-empty', () {
      expect(ShareCaptions.mythic, isNotEmpty);
      expect(ShareCaptions.epic, isNotEmpty);
      expect(ShareCaptions.generic, isNotEmpty);
    });

    test('mythic captions include at least one comment-bait prompt', () {
      final hasPrompt = ShareCaptions.mythic.any(
        (c) => c.contains('?') || c.toLowerCase().contains('which'),
      );
      expect(hasPrompt, isTrue,
          reason: 'STRATEGY §9.6: mythic captions need a comment-prompt');
    });

    test('every caption carries the #squishysmash hashtag', () {
      for (final c in [
        ...ShareCaptions.mythic,
        ...ShareCaptions.epic,
        ...ShareCaptions.generic,
      ]) {
        expect(c.toLowerCase(), contains('#squishysmash'));
      }
    });

    test('forMythic is deterministic for a given seed', () {
      expect(ShareCaptions.forMythic(42), ShareCaptions.forMythic(42));
      expect(ShareCaptions.forMythic(0), ShareCaptions.mythic[0]);
    });

    test('forMythic wraps on large seeds', () {
      final seed = 10_000_000;
      final pick = ShareCaptions.forMythic(seed);
      expect(ShareCaptions.mythic, contains(pick));
    });

    test('forMythic handles negative seeds via abs', () {
      expect(
        ShareCaptions.forMythic(-5),
        ShareCaptions.mythic[5 % ShareCaptions.mythic.length],
      );
    });

    test('forEpic + forGeneric follow the same deterministic scheme', () {
      expect(
        ShareCaptions.forEpic(42),
        ShareCaptions.epic[42 % ShareCaptions.epic.length],
      );
      expect(
        ShareCaptions.forGeneric(42),
        ShareCaptions.generic[42 % ShareCaptions.generic.length],
      );
    });
  });

  group('ShareCaptureService', () {
    testWidgets('capturePngBytes returns null when boundary not mounted',
        (tester) async {
      final key = GlobalKey();
      final svc = ShareCaptureService(key);
      // Key hasn't been attached to a render tree yet.
      final bytes = await svc.capturePngBytes();
      expect(bytes, isNull);
    });

    // Skipped: RenderRepaintBoundary.toImage() requires a real GPU frame
    // pipeline that flutter_test's fake binding doesn't provide — the call
    // hangs indefinitely in CI (timed out at 10min on Codemagic, same on
    // local Windows). The happy path is exercised at runtime via the
    // mythic-burst share flow; the negative paths above (no boundary, wrong
    // render type) cover the early-return branches.
    //
    // To re-enable: try wrapping the toImage call in `tester.runAsync(...)`
    // per https://api.flutter.dev/flutter/flutter_test/WidgetTester/runAsync.html
    // — but verify on a real CI run before un-skipping.
    testWidgets(
        'capturePngBytes returns PNG bytes once boundary is rendered',
        skip: true,  // toImage hangs in headless test env (no GPU pipeline)
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: ColoredBox(color: Color(0xFFFF8FB8)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svc = ShareCaptureService(key);
      final bytes = await svc.capturePngBytes(pixelRatio: 1.0);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(20));
      // PNG magic: 89 50 4E 47 0D 0A 1A 0A
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });

    testWidgets('capturePngBytes returns null when key is not a boundary',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: key, width: 10, height: 10),
        ),
      );
      await tester.pumpAndSettle();

      final svc = ShareCaptureService(key);
      final bytes = await svc.capturePngBytes();
      expect(bytes, isNull);
    });
  });
}
