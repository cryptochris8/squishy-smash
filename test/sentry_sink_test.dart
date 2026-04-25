import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/core/diagnostics.dart';
import 'package:squishy_smash/core/sentry_sink.dart';

class _SentryCall {
  _SentryCall(this.error, this.stack, this.source);
  final Object error;
  final StackTrace? stack;
  final String source;
}

void main() {
  group('SentrySink', () {
    test('forwards each captured entry to the sender once', () {
      final calls = <_SentryCall>[];
      final sink = SentrySink(
        sender: (e, s, src) => calls.add(_SentryCall(e, s, src)),
      );
      final svc = DiagnosticsService(sinks: [sink]);
      svc.record(source: 'flutter', error: StateError('boom'));
      svc.record(source: 'platform', error: 'string error');
      expect(calls, hasLength(2));
      expect(calls[0].error, isA<StateError>());
      expect(calls[0].source, 'flutter');
      expect(calls[1].error, 'string error');
      expect(calls[1].source, 'platform');
    });

    test('passes the original error object through (not just the message)',
        () {
      // Sentry groups by exception type, so flattening to a String
      // would bucket every error together. Pin the type-preservation
      // contract explicitly.
      Object? receivedError;
      final sink = SentrySink(
        sender: (e, s, src) => receivedError = e,
      );
      final original = ArgumentError('bad input');
      sink.capture(DiagnosticEntry(
        timestamp: DateTime.now().toUtc(),
        source: 'test',
        message: 'bad input',
        error: original,
      ));
      expect(receivedError, same(original),
          reason: 'sink must preserve identity of the error object so '
              'Sentry sees the original exception class');
    });

    test('preserves the stack trace verbatim', () {
      StackTrace? received;
      final sink = SentrySink(
        sender: (e, s, src) => received = s,
      );
      final st = StackTrace.current;
      sink.capture(DiagnosticEntry(
        timestamp: DateTime.now().toUtc(),
        source: 'flutter',
        message: 'm',
        error: 'm',
        stack: st,
      ));
      expect(received, same(st));
    });

    test('forwards the diagnostics source as a tag for Sentry filtering',
        () {
      // The `source` value lets the Sentry dashboard filter by
      // "show me only bootstrap-time crashes" or "show me only zone
      // failures" — drop the source and that filtering breaks.
      final sources = <String>[];
      final sink = SentrySink(
        sender: (e, s, src) => sources.add(src),
      );
      sink.capture(DiagnosticEntry(
        timestamp: DateTime.now().toUtc(),
        source: 'bootstrap',
        message: 'pack JSON malformed',
        error: const FormatException('malformed'),
      ));
      expect(sources, ['bootstrap']);
    });

    test('sender failures do not propagate (resilient fan-out)', () {
      // A flaky network or misconfigured DSN should not back-pressure
      // the buffer / the calling thread. The sink swallows internally.
      final sink = SentrySink(
        sender: (_, __, ___) => throw StateError('Sentry transport down'),
      );
      // Nothing here should throw.
      expect(
        () => sink.capture(DiagnosticEntry(
          timestamp: DateTime.now().toUtc(),
          source: 'flutter',
          message: 'm',
          error: 'm',
        )),
        returnsNormally,
      );
    });

    test('integrates cleanly with DiagnosticsService.addSink (late attach)',
        () {
      // Sentry init can finish AFTER bootstrap (e.g., behind a consent
      // gate). Buffer captures pre-init events; the late-attached
      // sink only sees forward events. That contract is asserted in
      // diagnostics_test.dart but pinned here from the Sentry side
      // too so the launch order is enshrined.
      final sent = <Object>[];
      final svc = DiagnosticsService();
      svc.record(source: 'bootstrap', error: 'pre-sentry-init');

      final sink = SentrySink(
        sender: (e, s, src) => sent.add(e),
      );
      svc.addSink(sink);
      svc.record(source: 'flutter', error: 'post-sentry-init');

      expect(sent.map((e) => e.toString()), ['post-sentry-init']);
    });
  });
}
