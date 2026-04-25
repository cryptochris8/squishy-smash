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

  group('IAP UI surfaces are gated behind FeatureFlags.iapsEnabled', () {
    // Source-level guard: walks the relevant files and asserts that
    // each known IAP surface still references the feature flag.
    // Catches accidental removal of the gate during a future
    // refactor — without these gates, App Review fails 2.3.1.

    String _read(String path) => File(path).readAsStringSync();

    test('Shop screen Offers section gates on FeatureFlags.iapsEnabled',
        () {
      final source = _read('lib/ui/shop_screen.dart');
      expect(source, contains('FeatureFlags.iapsEnabled'),
          reason: 'shop_screen.dart must reference FeatureFlags.iapsEnabled '
              'to gate the Offers / IapProductCard section');
      expect(source, contains('IapProductCard'),
          reason: 'IapProductCard reference must still exist (just gated)');
    });

    test('Starter Bundle popup early-returns when IAPs are disabled', () {
      final source = _read('lib/ui/gameplay_screen.dart');
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
  });
}
