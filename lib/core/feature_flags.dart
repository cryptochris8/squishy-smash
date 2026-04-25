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
  /// reveal). Off by default for v0.1.1 because no IAPs are
  /// configured in App Store Connect — Apple guideline 2.3.1
  /// requires every visible purchase button to actually work.
  ///
  /// When IAPs are configured + sandbox-tested + reviewed, ship
  /// a build with `--dart-define=IAPS_ENABLED=true` and the UI
  /// lights up. No code rewrite needed.
  static const bool iapsEnabled =
      bool.fromEnvironment('IAPS_ENABLED', defaultValue: false);
}
