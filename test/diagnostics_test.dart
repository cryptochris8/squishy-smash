import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/core/diagnostics.dart';

class _RecordingSink implements DiagnosticsSink {
  final List<DiagnosticEntry> received = [];
  @override
  void capture(DiagnosticEntry entry) => received.add(entry);
}

class _ThrowingSink implements DiagnosticsSink {
  @override
  void capture(DiagnosticEntry entry) =>
      throw StateError('sink intentionally broken');
}

void main() {
  group('DiagnosticsService.record', () {
    test('adds entries in insertion order', () {
      final svc = DiagnosticsService();
      svc.record(source: 'flutter', error: 'first');
      svc.record(source: 'platform', error: 'second');
      expect(svc.entries.map((e) => e.message),
          ['first', 'second']);
    });

    test('captures the first line only of multi-line error.toString', () {
      final svc = DiagnosticsService();
      svc.record(source: 'x', error: 'line one\nline two\nline three');
      expect(svc.entries.single.message, 'line one');
    });

    test('preserves the stack trace when provided', () {
      final svc = DiagnosticsService();
      final st = StackTrace.current;
      svc.record(source: 'x', error: 'boom', stack: st);
      expect(svc.entries.single.stack, st);
    });

    test('timestamp is UTC and recent', () {
      final svc = DiagnosticsService();
      final before = DateTime.now().toUtc();
      svc.record(source: 'x', error: 'boom');
      final after = DateTime.now().toUtc();
      final ts = svc.entries.single.timestamp;
      expect(ts.isUtc, isTrue);
      expect(ts.isBefore(before.subtract(const Duration(seconds: 1))),
          isFalse);
      expect(ts.isAfter(after.add(const Duration(seconds: 1))),
          isFalse);
    });
  });

  group('DiagnosticsService ring-buffer behavior', () {
    test('drops oldest entries past maxEntries', () {
      final svc = DiagnosticsService(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        svc.record(source: 'x', error: 'err$i');
      }
      expect(svc.count, 3);
      expect(svc.entries.map((e) => e.message),
          ['err2', 'err3', 'err4']);
    });

    test('clear empties the buffer', () {
      final svc = DiagnosticsService();
      svc.record(source: 'x', error: 'a');
      svc.record(source: 'x', error: 'b');
      svc.clear();
      expect(svc.count, 0);
    });

    test('entries getter returns an unmodifiable view', () {
      final svc = DiagnosticsService();
      svc.record(source: 'x', error: 'a');
      expect(
        () => (svc.entries).removeAt(0),
        throwsUnsupportedError,
      );
    });
  });

  group('DiagnosticsService sinks', () {
    test('forwards every record to every registered sink', () {
      final s1 = _RecordingSink();
      final s2 = _RecordingSink();
      final svc = DiagnosticsService(sinks: [s1, s2]);
      svc.record(source: 'x', error: 'boom');
      expect(s1.received.single.message, 'boom');
      expect(s2.received.single.message, 'boom');
    });

    test('addSink hooks up later sinks for subsequent events', () {
      final svc = DiagnosticsService();
      svc.record(source: 'x', error: 'before');
      final late = _RecordingSink();
      svc.addSink(late);
      svc.record(source: 'x', error: 'after');
      // The pre-add event isn't replayed — sink only sees forward events.
      expect(late.received.map((e) => e.message), ['after']);
    });

    test('a throwing sink does not poison other sinks or the buffer', () {
      final good = _RecordingSink();
      final svc = DiagnosticsService(sinks: [_ThrowingSink(), good]);
      svc.record(source: 'x', error: 'still works');
      // Buffer still updated.
      expect(svc.entries.single.message, 'still works');
      // Healthy sink still received it.
      expect(good.received.single.message, 'still works');
    });
  });
}
