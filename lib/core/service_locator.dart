import 'dart:io' show Platform;

import '../data/content_loader.dart';
import '../data/persistence.dart';
import '../data/repositories/pack_repository.dart';
import '../data/repositories/progression_repo.dart';
import '../game/systems/sound_manager.dart';
import '../game/systems/ui_sound_registry.dart';
import '../game/systems/voice_line_registry.dart';
import '../monetization/iap_service.dart';
import '../monetization/iap_service_real.dart';
import '../monetization/iap_service_stub.dart';
import '../monetization/product_catalog.dart';
import 'analytics_stub.dart';

class ServiceLocator {
  ServiceLocator._();

  static late final Persistence persistence;
  static late final PackRepository packs;
  static late final ProgressionRepository progression;
  static late final SoundManager sounds;
  static late final UiSounds ui;
  static late final Analytics analytics;
  static late final IapService iap;
  static late final PurchaseGrantController purchaseGrants;

  static Future<void> bootstrap() async {
    persistence = await Persistence.open();
    final loader = ContentLoader();
    final loaded = await loader.loadAll();
    packs = PackRepository(loaded.packs, loaded.schedule);
    progression = ProgressionRepository(persistence, packs);
    sounds = SoundManager();
    await sounds.warm(<String>[
      ...packs.allObjectSoundPaths(),
      ...VoiceLineRegistry.allPaths,
      ...UiSoundRegistry.allPaths,
    ]);
    ui = UiSounds(sounds);
    analytics = const NoOpAnalytics();

    // StoreKit + Play Billing are only available on iOS and Android.
    // Everywhere else (web, macOS tests, Windows dev) we fall back to
    // a stub that auto-completes purchases so UI flows can be
    // exercised without a sandbox account.
    iap = _isMobile ? RealIapService() : StubIapService();
    purchaseGrants = PurchaseGrantController(progression);
    // Fire-and-forget product load so the Shop screen has prices the
    // first time it's opened. Offline or store-unavailable just
    // returns an empty list; UI falls back to ProductCatalog prices.
    unawaited(iap.loadProducts(ProductIds.launchLoaded));
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
