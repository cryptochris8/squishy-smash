import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/core/feature_flags.dart';

void main() {
  group('FeatureFlags.iapsEnabled', () {
    test('defaults to false in dev/test builds (no --dart-define)', () {
      // The whole point of the flag: without an explicit
      // --dart-define=IAPS_ENABLED=true at build time, the IAP UI
      // surfaces stay hidden. v0.1.1 ships in this state because no
      // products are configured in App Store Connect.
      //
      // If this test starts failing, someone changed the default to
      // `true` — that's an App Review hazard. Don't.
      expect(FeatureFlags.iapsEnabled, isFalse,
          reason: 'IAPs must be off by default — Apple 2.3.1 requires '
              'every visible purchase button to actually work, and no '
              'products are configured for v0.1.1');
    });
  });

  group('FeatureFlags.adsEnabled', () {
    test('defaults to false in dev/test builds (no --dart-define)', () {
      // v0.1.1 privacy posture at squishysmash.com/privacy declares
      // "no in-game ads, no third-party SDKs, ATT prompt does not
      // appear." The shipped binary must match that claim — the gate
      // is what ensures it.
      //
      // If this test starts failing, someone flipped the default to
      // `true` AND the privacy nutrition label needs updating before
      // resubmitting. Don't ship without both.
      expect(FeatureFlags.adsEnabled, isFalse,
          reason: 'Ads must be off by default — privacy nutrition label '
              'declares Crash Data only, and the live policy at '
              'squishysmash.com/privacy claims no ads or third-party SDKs');
    });
  });

  group('IAP UI surfaces are gated behind FeatureFlags.iapsEnabled', () {
    // Source-level guard: walks the relevant files and asserts that
    // each known IAP surface still references the feature flag.
    // Catches accidental removal of the gate during a future
    // refactor — without these gates, App Review fails 2.3.1.

    String read(String path) => File(path).readAsStringSync();

    test('Shop screen Offers section gates on FeatureFlags.iapsEnabled',
        () {
      final source = read('lib/ui/shop_screen.dart');
      expect(source, contains('FeatureFlags.iapsEnabled'),
          reason: 'shop_screen.dart must reference FeatureFlags.iapsEnabled '
              'to gate the Offers / IapProductCard section');
      expect(source, contains('IapProductCard'),
          reason: 'IapProductCard reference must still exist (just gated)');
    });

    test('Starter Bundle popup early-returns when IAPs are disabled', () {
      final source = read('lib/ui/gameplay_screen.dart');
      expect(source, contains('FeatureFlags.iapsEnabled'),
          reason: 'gameplay_screen.dart must reference '
              'FeatureFlags.iapsEnabled to gate the StarterBundlePopup');
      // The early-return should fire BEFORE we schedule the post-
      // frame callback that shows the popup — pin that ordering.
      final flagIndex = source.indexOf('FeatureFlags.iapsEnabled');
      final popupIndex = source.indexOf('StarterBundlePopup.show');
      expect(flagIndex, greaterThan(0));
      expect(popupIndex, greaterThan(0));
      expect(flagIndex, lessThan(popupIndex),
          reason: 'the iapsEnabled check must appear before '
              'StarterBundlePopup.show — otherwise the popup fires '
              'before we get to skip it');
    });

    test('ServiceLocator gates RealIapService construction', () {
      final source = read('lib/core/service_locator.dart');
      // Without this gate the underlying StoreKit SKProductsRequest
      // fires at every cold start regardless of UI flag — making a
      // network round-trip that would invalidate the privacy
      // nutrition label "Crash Data only" claim.
      expect(source, contains('FeatureFlags.iapsEnabled'),
          reason: 'service_locator.dart must gate IAP service init '
              'behind FeatureFlags.iapsEnabled — UI flag alone is not '
              'sufficient because RealIapService.loadProducts() makes '
              'a network call at construction');
      // RealIapService should only be constructed when iapsEnabled
      // is true AND we're on a mobile platform.
      expect(source, contains('FeatureFlags.iapsEnabled && _isMobile'),
          reason: 'IAP service selector must be gated by both the '
              'feature flag AND the mobile platform check');
    });
  });

  group('Ads stack is fully gated behind FeatureFlags.adsEnabled', () {
    String read(String path) => File(path).readAsStringSync();

    test('AdMob package is NOT in pubspec.yaml', () {
      // The single most important test in this suite: even an
      // *unused* google_mobile_ads import in a Dart file pulls the
      // SDK into the IPA and Apple's privacy-form scanner will see
      // it. The package must be physically absent from pubspec for
      // the privacy claim to be accurate.
      final source = read('pubspec.yaml');
      expect(source, isNot(contains(RegExp(r'^\s*google_mobile_ads:',
          multiLine: true))),
          reason: 'google_mobile_ads must NOT be a pubspec dependency '
              'in v0.1.1 — privacy nutrition label and live policy '
              'both claim no third-party advertising SDKs');
      expect(source, isNot(contains(RegExp(r'^\s*app_tracking_transparency:',
          multiLine: true))),
          reason: 'app_tracking_transparency must NOT be a pubspec '
              'dependency — privacy policy claims ATT prompt never appears');
    });

    test('Info.plist has no AdMob/ATT/SKAdNetwork keys', () {
      final source = read('ios/Runner/Info.plist');
      expect(source, isNot(contains('GADApplicationIdentifier')),
          reason: 'Info.plist must not declare GADApplicationIdentifier '
              'in v0.1.1 — even an unused declaration triggers Apple\'s '
              'static SDK scanner');
      expect(source, isNot(contains('NSUserTrackingUsageDescription')),
          reason: 'Info.plist must not declare NSUserTrackingUsageDescription '
              'in v0.1.1 — privacy policy claims ATT prompt never appears');
      expect(source, isNot(contains('SKAdNetworkItems')),
          reason: 'Info.plist must not declare SKAdNetworkItems in '
              'v0.1.1 — the array implies ad-attribution support');
    });

    test('AndroidManifest has no AdMob APPLICATION_ID', () {
      final source = read('android/app/src/main/AndroidManifest.xml');
      expect(source, isNot(contains('com.google.android.gms.ads.APPLICATION_ID')),
          reason: 'AndroidManifest must not declare the AdMob '
              'APPLICATION_ID meta-data in v0.1.1');
    });

    test('Service locator wires StubRewardedAdService with alwaysReady false',
        () {
      final source = read('lib/core/service_locator.dart');
      expect(source, contains('StubRewardedAdService(alwaysReady: false)'),
          reason: 'rewardedAds must be the stub with alwaysReady=false '
              'so any UI surface that probes "is an ad ready?" '
              'cleanly hides itself');
      expect(source, isNot(contains('AdMobRewardedAdService')),
          reason: 'AdMobRewardedAdService must not be referenced in '
              'service_locator — the implementation lives under '
              '_pending_v02/ until v0.2');
      expect(source, isNot(contains('ConsentController')),
          reason: 'ConsentController must not be referenced in '
              'service_locator — the AdMob/UMP/ATT flow is dormant '
              'in v0.1.1');
    });
  });

  group('Sentry init matches the declared privacy posture', () {
    String read(String path) => File(path).readAsStringSync();

    test('Sentry options disable session/hang/PII telemetry', () {
      // The privacy nutrition label declares Crash Data + Other
      // Diagnostic Data → App Functionality. Sentry's defaults
      // include session and app-hang envelopes that don't fit that
      // scope. Pin the explicit opt-outs so no future SDK upgrade
      // can quietly send more.
      final source = read('lib/main.dart');
      expect(source, contains('enableAutoSessionTracking = false'),
          reason: 'auto session tracking sends behavioral telemetry '
              'beyond crash data');
      expect(source, contains('enableAppHangTracking = false'),
          reason: 'app-hang tracking sends synthetic events that '
              'aren\'t real crashes');
      expect(source, contains('enableUserInteractionBreadcrumbs = false'),
          reason: 'interaction breadcrumbs cross into Usage Data');
      expect(source, contains('attachScreenshot = false'),
          reason: 'crash-time screenshots could capture user input');
      expect(source, contains('sendDefaultPii = false'),
          reason: 'PII transmission is not declared in the nutrition label');
    });
  });
}
