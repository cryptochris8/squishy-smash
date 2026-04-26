import 'dart:io' show Platform;

import '../data/card_manifest_loader.dart';
import '../data/card_unlock.dart';
import '../data/content_loader.dart';
import '../data/economy_config_loader.dart';
import '../data/models/economy_config.dart';
import '../data/persistence.dart';
import '../data/repositories/pack_repository.dart';
import '../data/repositories/progression_repo.dart';
import 'diagnostics.dart';
import 'feature_flags.dart';
import '../game/systems/sound_manager.dart';
import '../game/systems/ui_sound_registry.dart';
import '../game/systems/voice_line_registry.dart';
import '../monetization/ad_offer_controller.dart';
import '../monetization/iap_service.dart';
import '../monetization/iap_service_real.dart';
import '../monetization/iap_service_stub.dart';
import '../monetization/product_catalog.dart';
import '../monetization/rewarded_ad_service.dart';
import '../analytics/events.dart';
import 'analytics_stub.dart';

class ServiceLocator {
  ServiceLocator._();

  /// Always-available — initialized synchronously at the very top of
  /// `main()` so global error handlers can record into it before
  /// bootstrap runs (and even if bootstrap throws). Not `late` because
  /// it must exist before async init can fail.
  static final DiagnosticsService diagnostics = DiagnosticsService();

  static late final Persistence persistence;
  static late final PackRepository packs;
  static late final ProgressionRepository progression;
  static late final LoadedCardManifest cards;
  /// Tunable economy values (burst thresholds, coin prices, dupe
  /// bonuses, anti-spam, milestones). Loaded from assets/data/
  /// economy.json — edit that file to rebalance without recompiling
  /// any Dart code. See `EconomyConfig` for the field set.
  static late final EconomyConfig economy;
  static late final SoundManager sounds;
  static late final UiSounds ui;
  static late final Analytics analytics;
  static late final IapService iap;
  static late final PurchaseGrantController purchaseGrants;
  static late final RewardedAdService rewardedAds;
  static late final AdOfferController adOffers;

  static Future<void> bootstrap() async {
    persistence = await Persistence.open();
    // Wire the persistence layer's corruption-diagnostics emitter to
    // the shared service so Sentry sees blob corruption events. See
    // Persistence._readBlobOrBackup for what triggers events.
    persistence.diagnostics = diagnostics;
    final loader = ContentLoader();
    final loaded = await loader.loadAll();
    packs = PackRepository(loaded.packs, loaded.schedule);
    // Economy config loads BEFORE the progression repo so the repo's
    // pricing/threshold accessors can use the JSON-driven values
    // throughout its lifetime. Defensive fallback to const default
    // means a missing/malformed JSON is non-fatal.
    economy = await EconomyConfigLoader().load();
    progression = ProgressionRepository(persistence, packs, economy: economy);
    // Card manifests load defensively — a missing manifest yields an
    // empty cards list, so the album just shows nothing rather than
    // crashing bootstrap.
    cards = await CardManifestLoader().loadAll();
    // One-shot v3 → v4 grandfather migration. Players coming from
    // v0.1.0 (where Common unlocked at 1 burst, etc.) get their
    // already-unlocked cards snapshotted into `grandfatheredCards`
    // before any tightened threshold takes effect — protects them
    // from "I had 80% of the album, now I see them locked again."
    if (persistence.profileVersion < 4 && cards.cards.isNotEmpty) {
      grandfatherUnlocksFromBaseline(
        cards: cards.cards,
        cardBurstCounts: progression.profile.cardBurstCounts,
        grandfatheredOut: progression.profile.grandfatheredCards,
      );
      // Persist the migration immediately so the snapshot is durable
      // — if the app crashes after this point, the next launch sees
      // a v4 blob and skips re-migration.
      await persistence.saveProfile(progression.profile);
    }
    sounds = SoundManager();
    await sounds.warm(<String>[
      ...packs.allObjectSoundPaths(),
      ...VoiceLineRegistry.allPaths,
      ...UiSoundRegistry.allPaths,
    ]);
    ui = UiSounds(sounds);
    analytics = const NoOpAnalytics();

    // IAP service: gated behind FeatureFlags.iapsEnabled. With the
    // flag off, the stub is selected on every platform so the
    // RealIapService never constructs and never calls StoreKit's
    // SKProductsRequest at boot. With the flag on (a future build
    // that has products configured + sandbox-tested + reviewed), the
    // mobile platforms get the real service; web/desktop still get
    // the stub so dev flows work without a sandbox account.
    iap = (FeatureFlags.iapsEnabled && _isMobile)
        ? RealIapService()
        : StubIapService();
    purchaseGrants = PurchaseGrantController(progression);
    if (FeatureFlags.iapsEnabled) {
      // Fire-and-forget product load so the Shop screen has prices
      // the first time it's opened. Offline or store-unavailable
      // just returns an empty list; UI falls back to ProductCatalog
      // prices. Skipped entirely when iapsEnabled is false so we
      // make zero StoreKit network calls in v0.1.1.
      unawaited(iap.loadProducts(ProductIds.launchLoaded));
    }

    // Rewarded ads: gated behind FeatureFlags.adsEnabled. With the
    // flag off (v0.1.1 ship config) the stub is wired with
    // alwaysReady=false so any UI surface that probes "is an ad
    // available?" cleanly hides itself. The ads stack (AdMob SDK,
    // UMP consent flow, ATT prompt) is NOT linked into the IPA — see
    // _pending_v02/monetization/ for the implementation files that
    // get re-enabled when ads ship.
    rewardedAds = StubRewardedAdService(alwaysReady: false);
    adOffers = AdOfferController(
      ads: rewardedAds,
      progression: progression,
      events: GameEvents(analytics),
    );
  }

  static bool get _isMobile {
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      return false; // web
    }
  }
}

/// Local `unawaited` shim so we don't pull in `dart:async` just for
/// the type hint on a fire-and-forget.
void unawaited(Future<void> _) {}
