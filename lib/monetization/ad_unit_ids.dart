import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob ad unit IDs. Uses Google's published test IDs by default so
/// development + TestFlight never accidentally drives real ad revenue
/// (and never risks policy violations for clicking your own ads).
///
/// **Before shipping to production:** replace each constant in the
/// `_prod*` block with your real ad unit ID from the AdMob console,
/// and set `_useProductionIds = true`.
///
/// How to swap per-env:
///   1. Create the ad unit in AdMob (Rewarded format).
///   2. Copy the ID (looks like `ca-app-pub-xxx/yyy`).
///   3. Paste it into `_prodRewardedIosId` / `_prodRewardedAndroidId`.
///   4. Flip `_useProductionIds` to true in a release build.
///
/// Test IDs are safe — they serve Google's always-filled test ads and
/// can't be monetized, so leaving them on in debug is correct behavior.
abstract final class AdUnitIds {
  // Set to true in a production build. Guarded with `!kDebugMode` so
  // debug + TestFlight builds continue to use test IDs automatically
  // even if a dev forgets to flip it back.
  static const bool _useProductionIds = false;

  // Google's public test IDs — free to use during dev, never charge.
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';

  // Replace before shipping to production. Leaving as `null` on
  // purpose so a missing ID never silently defaults to test revenue.
  static const String? _prodRewardedIos = null;
  static const String? _prodRewardedAndroid = null;

  /// Rewarded ad unit ID for the current platform + env. Returns null
  /// on non-mobile platforms so the ad layer can early-out cleanly.
  static String? get rewarded {
    final useProd = _useProductionIds && !kDebugMode;
    try {
      if (Platform.isIOS) {
        return useProd ? _prodRewardedIos : _testRewardedIos;
      }
      if (Platform.isAndroid) {
        return useProd ? _prodRewardedAndroid : _testRewardedAndroid;
      }
    } catch (_) {
      // web / unsupported
    }
    return null;
  }
}
