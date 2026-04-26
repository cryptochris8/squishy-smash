import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Drives the pre-ad compliance flow in the order Apple + the EU AEPD
/// require:
///
///   1. Ask Google UMP (User Messaging Platform) whether a consent
///      form is required (GDPR region, TCF v2 signals, etc.).
///   2. If required, show it. Blocking on the main thread is fine
///      here — it happens once per install or until consent changes.
///   3. On iOS, request App Tracking Transparency **after** the
///      consent sheet so the two prompts don't visually stack.
///   4. Initialize the Mobile Ads SDK using whatever consent signals
///      were gathered. UMP hands its result to the SDK automatically
///      via the plugin integration.
///
/// Call [ensureConsentAndInit] once at app startup, before the first
/// ad load. Safe to call multiple times — subsequent calls short-
/// circuit on [_initialized].
class ConsentController {
  ConsentController();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> ensureConsentAndInit() async {
    if (_initialized) return;

    try {
      await _requestConsentInfo();
    } catch (e) {
      debugPrint('ConsentController: UMP error $e — continuing with '
          'non-personalized ads');
    }

    // ATT is iOS-only. Skip on other platforms. It also has to run
    // after the consent sheet per Apple's review guidelines.
    if (_isIos) {
      try {
        await _requestTrackingAuthorization();
      } catch (e) {
        debugPrint('ConsentController: ATT error $e — assume denied');
      }
    }

    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('ConsentController: MobileAds init failed $e');
    }

    _initialized = true;
  }

  Future<void> _requestConsentInfo() async {
    final params = ConsentRequestParameters();
    final info = ConsentInformation.instance;

    final updateCompleter = Completer<void>();
    info.requestConsentInfoUpdate(
      params,
      () => updateCompleter.complete(),
      (FormError error) {
        debugPrint('UMP consent info update failed: '
            '${error.errorCode} ${error.message}');
        if (!updateCompleter.isCompleted) updateCompleter.complete();
      },
    );
    await updateCompleter.future;

    final available = await info.isConsentFormAvailable();
    if (!available) return;

    final formCompleter = Completer<void>();
    ConsentForm.loadConsentForm(
      (ConsentForm form) async {
        final status = await info.getConsentStatus();
        if (status == ConsentStatus.required) {
          form.show((FormError? dismissError) {
            if (dismissError != null) {
              debugPrint(
                'UMP form dismiss error: ${dismissError.message}',
              );
            }
            if (!formCompleter.isCompleted) formCompleter.complete();
          });
        } else {
          if (!formCompleter.isCompleted) formCompleter.complete();
        }
      },
      (FormError error) {
        debugPrint('UMP form load error: '
            '${error.errorCode} ${error.message}');
        if (!formCompleter.isCompleted) formCompleter.complete();
      },
    );
    await formCompleter.future;
  }

  Future<void> _requestTrackingAuthorization() async {
    final status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      // The system sheet only shows once per install — subsequent
      // calls return the cached decision. Safe to always call.
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  bool get _isIos {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}
