import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_unit_ids.dart';
import 'rewarded_ad_service.dart';

/// Production [RewardedAdService] backed by Google AdMob.
///
/// Lifecycle:
///   * Constructor kicks off a pre-load so the first show() can resolve
///     near-instantly if the player accepts the offer quickly.
///   * On any show() path — whether the ad played or errored — a fresh
///     pre-load fires so the next offer also has inventory ready.
///   * `dispose()` tears down the cached ad + cancels any in-flight load.
///
/// The SDK's `RewardedAd.load` is single-shot; we wrap it in a small
/// state machine so [isReady] reflects "cached and playable" rather
/// than "load is somewhere in progress."
class AdMobRewardedAdService implements RewardedAdService {
  AdMobRewardedAdService() {
    // Fire-and-forget pre-load. A failure here just leaves [isReady]
    // reporting false until a later probe triggers another attempt.
    _preload();
  }

  RewardedAd? _cached;
  bool _loading = false;

  /// When true, [show] will wait up to this long for an in-flight load
  /// to resolve before returning unavailable. Keeps the offer UX
  /// tolerant of network variance without blocking the Flame loop.
  final Duration showLoadTimeout = const Duration(seconds: 6);

  void dispose() {
    _cached?.dispose();
    _cached = null;
  }

  @override
  Future<bool> isReady(String placement) async {
    // We don't vary ad units per placement yet — a single rewarded
    // unit serves all three offer sites. If the cache is warm, say
    // ready; otherwise kick off a pre-load for next time.
    if (_cached != null) return true;
    if (!_loading) {
      unawaited(_preload());
    }
    return false;
  }

  @override
  Future<AdResult> show(String placement) async {
    final unitId = AdUnitIds.rewarded;
    if (unitId == null) {
      return const AdResult(
        outcome: AdOutcome.unavailable,
        errorMessage: 'No rewarded ad unit configured for this platform',
      );
    }

    // If the cache is cold, wait briefly for the in-flight load.
    if (_cached == null) {
      if (!_loading) {
        unawaited(_preload());
      }
      final start = DateTime.now();
      while (_cached == null &&
          DateTime.now().difference(start) < showLoadTimeout) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    final ad = _cached;
    if (ad == null) {
      return const AdResult(
        outcome: AdOutcome.unavailable,
        errorMessage: 'Rewarded ad not ready',
      );
    }
    // Consume the cache slot now so a double-tap can't re-show the
    // same ad instance (which the SDK explicitly forbids).
    _cached = null;

    final completer = Completer<AdResult>();
    var rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) {},
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        if (!completer.isCompleted) {
          completer.complete(AdResult(
            outcome:
                rewarded ? AdOutcome.completed : AdOutcome.dismissedEarly,
          ));
        }
        // Warm the cache for the next offer.
        unawaited(_preload());
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            AdResult(
              outcome: AdOutcome.unavailable,
              errorMessage: 'Failed to show: ${error.message}',
            ),
          );
        }
        unawaited(_preload());
      },
    );

    await ad.show(onUserEarnedReward: (_, __) {
      rewarded = true;
    });

    return completer.future;
  }

  Future<void> _preload() async {
    final unitId = AdUnitIds.rewarded;
    if (unitId == null) return;
    if (_loading || _cached != null) return;
    _loading = true;
    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _cached = ad;
            _loading = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              'AdMobRewardedAdService: load failed '
              '(${error.code}) ${error.message}',
            );
            _cached = null;
            _loading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('AdMobRewardedAdService: load threw $e');
      _loading = false;
    }
  }
}

/// Local `unawaited` shim mirroring the one in ServiceLocator — avoids
/// pulling in `dart:async` in every caller.
void unawaited(Future<void> _) {}
