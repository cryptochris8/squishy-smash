import '../data/models/rarity.dart';
import '../data/repositories/progression_repo.dart';
import '../game/systems/arena_registry.dart';
import 'product_catalog.dart';

/// Live price info from the platform store. Tests use literals; the
/// real IAP service populates these from StoreKit / Play Billing.
class StorePrice {
  const StorePrice({
    required this.sku,
    required this.formattedPrice,
    required this.currencyCode,
  });

  final String sku;
  final String formattedPrice; // e.g. "$2.99", "€2,99"
  final String currencyCode; // e.g. "USD", "EUR"
}

/// Outcome of an attempted purchase.
enum PurchaseStatus {
  /// Purchase was successful and the store has verified the receipt.
  completed,

  /// User dismissed the purchase sheet without buying.
  canceled,

  /// Store-side error (network, declined card, invalid product, etc.).
  error,

  /// Purchase is still in flight — the platform may deliver the
  /// verified receipt asynchronously. Shop UI should show a pending
  /// state until the service calls back with a terminal status.
  pending,
}

class PurchaseResult {
  const PurchaseResult({
    required this.status,
    required this.sku,
    this.errorMessage,
  });

  final PurchaseStatus status;
  final String sku;
  final String? errorMessage;

  bool get isSuccess => status == PurchaseStatus.completed;
}

/// IAP gateway interface. Production uses [RealIapService] backed by
/// the in_app_purchase plugin; tests and web/desktop use
/// [StubIapService]. Pick one in ServiceLocator based on platform.
abstract class IapService {
  /// Pull product metadata from the platform store. Call once at
  /// startup; the returned list may be empty if the store hasn't
  /// provisioned SKUs yet or the device is offline.
  Future<List<StorePrice>> loadProducts(List<String> skus);

  /// Kick off a purchase flow for [sku]. The returned future resolves
  /// once the platform returns a terminal status.
  Future<PurchaseResult> purchase(String sku);

  /// Ask the store to redeliver any non-consumable purchases the user
  /// owns (e.g., Remove Ads). Useful on fresh installs or device
  /// migrations. Returns the set of SKUs restored.
  Future<Set<String>> restore();

  /// Mark a pending purchase as consumed so the store stops offering
  /// it. For non-consumables this is a no-op on most platforms but
  /// consumables require explicit acknowledgment to allow re-purchase.
  Future<void> acknowledge(String sku);
}

/// Applies the declarative ProductReward list to the game state. Lives
/// separate from the service so both stub + real share grant logic.
class PurchaseGrantController {
  const PurchaseGrantController(this._progression);

  final ProgressionRepository _progression;

  /// Apply every reward declared on [sku]. Idempotent — re-granting
  /// a non-consumable that's already marked purchased is a no-op.
  Future<void> applyGrantsFor(String sku, {required bool isRestore}) async {
    final product = ProductCatalog.bySku(sku);
    if (product == null) return;

    final alreadyOwned = _progression.profile.purchasedSkus.contains(sku);
    if (alreadyOwned && !product.isConsumable) {
      // Non-consumables only grant once. A restore just re-confirms
      // the entitlement without re-awarding coins/boosts.
      if (isRestore) {
        await _reapplyEntitlementsOnly(product);
      }
      return;
    }

    for (final reward in product.rewards) {
      switch (reward.kind) {
        case RewardKind.removeAds:
          await _progression.setRemoveAds(true);
          break;
        case RewardKind.coins:
          await _progression.awardCoins(reward.amount);
          break;
        case RewardKind.boostToken:
          await _progression.grantBoostToken(count: reward.amount);
          break;
        case RewardKind.guaranteedReveal:
          final r = reward.forcedRarity;
          if (r != null) {
            await _progression.grantGuaranteedReveal(r, count: reward.amount);
          }
          break;
        case RewardKind.cosmeticArena:
          final key = reward.arenaKey;
          if (key != null && ArenaRegistry.isKnown(key)) {
            _progression.profile.unlockedArenaKeys.add(key);
          }
          break;
      }
    }

    await _progression.markSkuPurchased(sku);
    if (sku == ProductIds.starterBundle) {
      await _progression.markStarterBundleClaimed();
    }
  }

  /// Restore path: a non-consumable we'd already marked as purchased.
  /// Only re-confirm the entitlement flip (e.g. remove_ads); don't
  /// re-grant any coin / token rewards.
  Future<void> _reapplyEntitlementsOnly(ProductDef product) async {
    for (final reward in product.rewards) {
      if (reward.kind == RewardKind.removeAds) {
        await _progression.setRemoveAds(true);
      }
    }
  }
}
