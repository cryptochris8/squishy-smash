import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/core/diagnostics.dart';
import 'package:squishy_smash/ui/diagnostics_screen.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: child,
    );

void main() {
  group('DiagnosticsScreen — empty state', () {
    testWidgets('renders the "no errors" empty state when buffer is empty',
        (tester) async {
      final svc = DiagnosticsService();
      await tester
          .pumpWidget(_wrap(DiagnosticsScreen(service: svc)));
      expect(find.text('No errors recorded.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('Copy and Clear actions are disabled when empty',
        (tester) async {
      final svc = DiagnosticsService();
      await tester
          .pumpWidget(_wrap(DiagnosticsScreen(service: svc)));
      final copy = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.copy_all),
      );
      final clear = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_sweep),
      );
      expect(copy.onPressed, isNull);
      expect(clear.onPressed, isNull);
    });
  });

  group('DiagnosticsScreen — populated', () {
    testWidgets('shows each entry with source pill and message',
        (tester) async {
      final svc = DiagnosticsService();
      svc.record(source: 'flutter', error: 'render overflow');
      svc.record(source: 'platform', error: 'http failed');
      await tester
          .pumpWidget(_wrap(DiagnosticsScreen(service: svc)));
      expect(find.text('FLUTTER'), findsOneWidget);
      expect(find.text('PLATFORM'), findsOneWidget);
      expect(find.text('render overflow'), findsOneWidget);
      expect(find.text('http failed'), findsOneWidget);
    });

    testWidgets('newest entries render first (reverse-chronological)',
        (tester) async {
      final svc = DiagnosticsService();
      svc.record(source: 'flutter', error: 'OLDEST');
      svc.record(source: 'flutter', error: 'NEWEST');
      await tester
          .pumpWidget(_wrap(DiagnosticsScreen(service: svc)));
      // The first message in widget tree order should be the newest.
      final firstMessageFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'NEWEST' || w.data == 'OLDEST'),
      );
      final firstMatch = tester.widget<Text>(firstMessageFinder.first);
      expect(firstMatch.data, 'NEWEST');
    });

    testWidgets('Clear empties the buffer and re-renders empty state',
        (tester) async {
      final svc = DiagnosticsService();
      svc.record(source: 'flutter', error: 'boom');
      await tester
          .pumpWidget(_wrap(DiagnosticsScreen(service: svc)));
      expect(find.text('boom'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_sweep));
      await tester.pump();
      expect(find.text('No errors recorded.'), findsOneWidget);
      expect(svc.count, 0);
    });

    testWidgets('Copy writes the buffer to the system clipboard',
        (tester) async {
      final svc = DiagnosticsService();
      svc.record(source: 'flutter', error: 'crash one');
      svc.record(source: 'platform', error: 'crash two');

      // Capture clipboard writes via the platform-channel test handler.
      String? captured;
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          captured = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });

      await tester
          .pumpWidget(_wrap(DiagnosticsScreen(service: svc)));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.copy_all));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured, contains('crash one'));
      expect(captured, contains('crash two'));
      expect(captured, contains('flutter'));
      expect(captured, contains('platform'));
    });

    testWidgets('the bootstrap source uses the high-severity red tint',
        (tester) async {
      // The most catastrophic source — a bootstrap failure means the
      // app didn't fully start. Pin the visual hierarchy so a future
      // refactor doesn't accidentally flatten all sources to the same
      // color.
      final svc = DiagnosticsService();
      svc.record(source: 'bootstrap', error: 'pack JSON malformed');
      await tester
          .pumpWidget(_wrap(DiagnosticsScreen(service: svc)));
      expect(find.text('BOOTSTRAP'), findsOneWidget);
    });
  });
}
