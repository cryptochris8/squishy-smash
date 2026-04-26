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
    // Bootstrap services BEFORE Sentry init so the first frame can
    // render as soon as the SDK handshake completes. Pre-fix the
    // `await SentryFlutter.init(...)` call gated runApp until Sentry
    // had completed its native handshake (~200-400 ms on a cold
    // start) — visible launch latency the player would see (P1.14).
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

    if (_kSentryDsn.isNotEmpty) {
      // appRunner-style init: SentryFlutter.init handles the SDK
      // handshake, then calls our runner which calls runApp. The
      // first frame can paint immediately while the SDK finishes
      // wiring; if init fails, the catch falls back to runApp so
      // the app still launches.
      try {
        await SentryFlutter.init(
          (options) {
            options.dsn = _kSentryDsn;
            // Send errors only — no performance traces until we
            // explicitly opt in. Keeps quota use predictable.
            options.tracesSampleRate = 0.0;
            // Apple's privacy nutrition label for v0.1.1 declares
            // ONLY "Crash Data + Other Diagnostic Data → App
            // Functionality." Sentry's defaults send several event
            // shapes that don't fit that scope — explicitly disable
            // each one so the binary's network surface matches the
            // declared posture.
            //
            // - sessions: send_session_start / send_session_end on
            //   every app foreground/background. Behavioral
            //   telemetry, not a crash.
            // - app hangs: a watchdog that fires when the main thread
            //   stalls > 2 s. Produces a synthetic event that's not a
            //   real crash and is shaped like one.
            // - user interaction breadcrumbs: tap / scroll trail
            //   attached to crash reports. Useful for debugging but
            //   crosses the line into "Usage Data."
            // - default PII: device name, IP, etc. Already off by
            //   default in sentry_flutter ^8 — set explicitly so a
            //   future SDK upgrade can't accidentally flip it on.
            // - screenshot attach: for debugging UI crashes — a
            //   screenshot of the screen at crash time. Could include
            //   text the user typed; not declared. Off.
            options.enableAutoSessionTracking = false;
            options.enableAppHangTracking = false;
            options.enableUserInteractionBreadcrumbs = false;
            options.attachScreenshot = false;
            options.sendDefaultPii = false;
          },
          appRunner: () => runApp(const SquishySmashApp()),
        );
        ServiceLocator.diagnostics.addSink(SentrySink());
        return; // appRunner already called runApp
      } catch (e, st) {
        ServiceLocator.diagnostics.record(
          source: 'sentry',
          error: e,
          stack: st,
        );
        // Fall through to runApp so the app still launches even if
        // Sentry init fails.
      }
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
