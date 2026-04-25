import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/core/diagnostics.dart';
import 'package:squishy_smash/core/service_locator.dart';

void main() {
  group('ServiceLocator.diagnostics global wiring', () {
    test('diagnostics service is non-null without calling bootstrap', () {
      // Critical: the buffer must be available BEFORE bootstrap so
      // bootstrap-time crashes (bad JSON, persistence failure) can
      // still be recorded. Bootstrap itself is not called here.
      expect(ServiceLocator.diagnostics, isNotNull);
    });

    test('records flow into the singleton buffer', () {
      ServiceLocator.diagnostics.clear();
      ServiceLocator.diagnostics.record(
        source: 'test',
        error: 'simulated bootstrap failure',
      );
      expect(ServiceLocator.diagnostics.entries, hasLength(1));
      expect(ServiceLocator.diagnostics.entries.first.source, 'test');
    });
  });

  group('Mirroring FlutterError.onError into diagnostics', () {
    // Mirrors the wiring main.dart sets up so we can verify the
    // pattern works without actually calling main() (which is
    // unsupported in tests).
    test('reports a thrown FlutterError into the buffer', () {
      final svc = DiagnosticsService();
      // Match the production handler's behavior.
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        svc.record(
          source: 'flutter',
          error: details.exception,
          stack: details.stack,
        );
      };
      addTearDown(() => FlutterError.onError = prevHandler);

      FlutterError.reportError(FlutterErrorDetails(
        exception: StateError('rendered something impossible'),
        stack: StackTrace.current,
        library: 'unit test',
      ));

      expect(svc.entries, hasLength(1));
      expect(svc.entries.single.source, 'flutter');
      expect(svc.entries.single.message, contains('impossible'));
      expect(svc.entries.single.stack, isNotNull);
    });
  });
}
