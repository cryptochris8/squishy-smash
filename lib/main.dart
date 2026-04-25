import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/diagnostics.dart';
import 'core/sentry_sink.dart';
import 'core/service_locator.dart';

/// Sentry DSN, supplied at build time via
/// `--dart-define=SENTRY_DSN=https://...@sentry.io/...`.
/// Empty in dev / test builds — the SDK is skipped entirely so there's
/// no network noise and nothing is sent until a real release.
const String _kSentryDsn =
    String.fromEnvironment('SENTRY_DSN', defaultValue: '');

/// Bootstrap entry. Wraps the whole app in `runZonedGuarded` so any
/// uncaught error — including async errors during `bootstrap()`,
/// platform-channel failures, and zone-level unhandled futures —
/// reaches the [DiagnosticsService] buffer (and any registered sink
/// such as Sentry).
///
/// On iOS (where the developer has no Mac/Xcode access), the buffer
/// is the primary debugging channel: errors stay accessible via the
/// in-app Diagnostics screen even if the app's main UI fails to load.
void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Framework-thrown errors (e.g., RenderFlex overflow, build errors).
    FlutterError.onError = (details) {
      ServiceLocator.diagnostics.record(
        source: 'flutter',
        error: details.exception,
        stack: details.stack,
      );
      // Preserve normal logging behavior in debug so the dev console
      // still gets a red error block. In release we silence it (we've
      // already captured the structured form into diagnostics).
      if (kDebugMode) FlutterError.presentError(details);
    };

    // Async / isolate errors that escape the framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      ServiceLocator.diagnostics.record(
        source: 'platform',
        error: error,
        stack: stack,
      );
      return true; // handled — don't terminate the isolate.
    };

    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);

    // Initialize Sentry only when a DSN is provided (i.e., real
    // release builds). Local dev / CI tests have an empty DSN and
    // skip the SDK entirely so we don't ping production Sentry from
    // hot-reloads or unit tests.
    if (_kSentryDsn.isNotEmpty) {
      try {
        await SentryFlutter.init((options) {
          options.dsn = _kSentryDsn;
          // Send errors only — no performance traces until we
          // explicitly opt in. Keeps quota use predictable.
          options.tracesSampleRate = 0.0;
        });
        ServiceLocator.diagnostics.addSink(SentrySink());
      } catch (e, st) {
        ServiceLocator.diagnostics.record(
          source: 'sentry',
          error: e,
          stack: st,
        );
      }
    }

    try {
      await ServiceLocator.bootstrap();
    } catch (e, st) {
      // Bootstrap failures (bad pack JSON, persistence open failure,
      // etc.) need to be captured before the UI even tries to render.
      // Re-throw so the zone handler sees it too — the app will crash
      // visibly rather than silently render an empty shell.
      ServiceLocator.diagnostics.record(
        source: 'bootstrap',
        error: e,
        stack: st,
      );
      rethrow;
    }

    runApp(const SquishySmashApp());
  }, (error, stack) {
    ServiceLocator.diagnostics.record(
      source: 'zone',
      error: error,
      stack: stack,
    );
  });
}
