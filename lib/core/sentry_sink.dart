import 'package:sentry_flutter/sentry_flutter.dart';

import 'diagnostics.dart';

/// Function signature for "send this error to Sentry." Extracted as a
/// parameter so tests can inject a fake sender; production code uses
/// `Sentry.captureException`.
typedef SentryCaptureFunction = void Function(
  Object error,
  StackTrace? stack,
  String source,
);

/// Default sender — forwards to the live Sentry SDK. Wraps
/// `Sentry.captureException` so we can attach the diagnostics
/// `source` tag (flutter / platform / zone / bootstrap) for filtering
/// inside the Sentry dashboard.
void defaultSentrySender(Object error, StackTrace? stack, String source) {
  Sentry.captureException(
    error,
    stackTrace: stack,
    withScope: (scope) {
      scope.setTag('diagnostics.source', source);
    },
  );
}

/// Forwards every diagnostic entry to Sentry. Add via
/// `DiagnosticsService.addSink(SentrySink(...))` after Sentry has
/// finished initializing — earlier errors stay buffered locally and
/// won't be lost.
class SentrySink implements DiagnosticsSink {
  SentrySink({SentryCaptureFunction? sender})
      : _sender = sender ?? defaultSentrySender;

  final SentryCaptureFunction _sender;

  @override
  void capture(DiagnosticEntry entry) {
    try {
      _sender(entry.error, entry.stack, entry.source);
    } catch (_) {
      // Swallow Sentry's own failures so a network blip can't cascade
      // through the diagnostics fan-out and back into the buffer.
      // Sentry's transport layer also retries internally, so a
      // dropped event isn't silently lost forever.
    }
  }
}
