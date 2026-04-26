/// Build-time feature flags. Each is read from a `--dart-define`
/// passed to `flutter build`, defaulting to a safe v0.1.x value
/// (typically "feature off") so we never accidentally ship work-in-
/// progress UI to App Review.
///
/// To enable a flag for a specific build, pass it on the build
/// command. Example for a real release with IAPs ready:
///
///     flutter build ipa --release \
///       --dart-define=IAPS_ENABLED=true \
///       --dart-define=SENTRY_DSN=$SENTRY_DSN
///
/// Codemagic carries flags through the same way — add a value to
/// the `smash` variable group, then forward it via `--dart-define`
/// in the build step.
abstract final class FeatureFlags {
  const FeatureFlags._();

  /// Master toggle for every IAP UI surface (the shop's Offers
  /// section + the Starter Bundle popup that fires on first rare
  /// reveal) AND for the underlying StoreKit/Play Billing service
  /// initialization. Off by default for v0.1.1 because no IAPs are
  /// configured in App Store Connect — Apple guideline 2.3.1
  /// requires every visible purchase button to actually work, and
  /// even an *invisible* `loadProducts()` call at boot makes a
  /// network round-trip that would invalidate our "Crash Data only"
  /// privacy nutrition label.
  ///
  /// When IAPs are configured + sandbox-tested + reviewed, ship
  /// a build with `--dart-define=IAPS_ENABLED=true` and the UI
  /// + StoreKit init both light up.
  static const bool iapsEnabled =
      bool.fromEnvironment('IAPS_ENABLED', defaultValue: false);

  /// Master toggle for the rewarded-ads stack (AdMob SDK,
  /// ConsentController / Google UMP, App Tracking Transparency
  /// prompt, all rewarded-ad UI surfaces). Off by default for
  /// v0.1.1 because the privacy policy at squishysmash.com/privacy
  /// claims "no in-game ads, no third-party advertising SDKs, ATT
  /// prompt does not appear" — and Apple's nutrition-label form
  /// will catch any binary that contradicts that claim.
  ///
  /// Until ads are intentionally re-introduced, `google_mobile_ads`
  /// and `app_tracking_transparency` are NOT in pubspec.yaml; the
  /// AdMob/Consent implementation files live under `_pending_v02/`
  /// so they're preserved without being compiled into the IPA.
  ///
  /// When ads ship, restore the packages, move the implementation
  /// files back into `lib/monetization/`, ship a build with
  /// `--dart-define=ADS_ENABLED=true`, and update the privacy
  /// nutrition label.
  static const bool adsEnabled =
      bool.fromEnvironment('ADS_ENABLED', defaultValue: false);
}
