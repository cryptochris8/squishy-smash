import 'dart:collection';

/// One captured error entry. Plain data — no Flutter dependencies so
/// the buffer can be exercised in pure-Dart tests.
class DiagnosticEntry {
  const DiagnosticEntry({
    required this.timestamp,
    required this.source,
    required this.message,
    required this.error,
    this.stack,
  });

  /// When the error was recorded (UTC).
  final DateTime timestamp;

  /// Which subsystem caught it. Conventional values:
  ///   * `flutter` — `FlutterError.onError` framework errors
  ///   * `platform` — `PlatformDispatcher.onError` async/isolate errors
  ///   * `zone` — uncaught error in `runZonedGuarded`
  ///   * `bootstrap` — failure inside `ServiceLocator.bootstrap`
  ///   * `sentry` — Sentry SDK reported an error of its own
  final String source;

  /// Single-line summary. The first line of the exception's `toString`.
  /// Used by the in-app diagnostics screen for compact display.
  final String message;

  /// The raw error object as passed into `record()`. Sinks that want
  /// type-aware capture (e.g., Sentry, which groups by exception
  /// class) read this instead of [message]. Local UI uses [message].
  final Object error;

  /// Full stack trace, if available.
  final StackTrace? stack;
}

/// Optional sink the [DiagnosticsService] forwards every captured error
/// to. The Sentry adapter implements this interface so the same error
/// stream lights up Sentry without the buffer needing to know about
/// any specific SDK.
abstract class DiagnosticsSink {
  void capture(DiagnosticEntry entry);
}

/// In-memory ring buffer of recent errors. Always-on (no init flag),
/// safe to read at any time. Bounded so a runaway error loop can't
/// blow the heap.
///
/// The diagnostic overlay reads `entries` to surface errors in-app —
/// critical on iOS where the dev has no Mac/Xcode and the only way to
/// see a crash is in the running app itself.
class DiagnosticsService {
  DiagnosticsService({this.maxEntries = 50, List<DiagnosticsSink>? sinks})
      : assert(maxEntries > 0),
        _sinks = List.of(sinks ?? const <DiagnosticsSink>[]);

  /// Cap on how many recent entries we keep. Older entries fall off
  /// the front of the queue when the buffer is full.
  final int maxEntries;

  final Queue<DiagnosticEntry> _buffer = Queue<DiagnosticEntry>();
  final List<DiagnosticsSink> _sinks;

  /// Most-recent-last view of the buffer. Returned as an unmodifiable
  /// list so callers can iterate without coupling to internal storage.
  List<DiagnosticEntry> get entries => List.unmodifiable(_buffer);

  int get count => _buffer.length;

  void clear() => _buffer.clear();

  /// Add a new diagnostic entry. Trims oldest if over [maxEntries] and
  /// fans out to every registered sink. Sink failures are swallowed so
  /// a misbehaving sink can't cascade into more errors.
  void record({
    required String source,
    required Object error,
    StackTrace? stack,
  }) {
    final entry = DiagnosticEntry(
      timestamp: DateTime.now().toUtc(),
      source: source,
      message: _firstLine(error.toString()),
      error: error,
      stack: stack,
    );
    _buffer.addLast(entry);
    while (_buffer.length > maxEntries) {
      _buffer.removeFirst();
    }
    for (final sink in _sinks) {
      try {
        sink.capture(entry);
      } catch (_) {
        // A sink throwing must not poison subsequent sinks or callers.
        // Intentionally swallow — surfacing this would mean recording
        // an error from inside `record`, which is a cycle.
      }
    }
  }

  /// Register an additional sink at runtime. Useful when Sentry init
  /// is async and finishes after bootstrap (e.g., consent gating on
  /// iOS) — early errors stay in the buffer; late errors fan out to
  /// Sentry once it's online.
  void addSink(DiagnosticsSink sink) {
    _sinks.add(sink);
  }

  static String _firstLine(String s) {
    final idx = s.indexOf('\n');
    return idx < 0 ? s : s.substring(0, idx);
  }
}
