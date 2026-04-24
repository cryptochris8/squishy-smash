import 'iap_service.dart';
import 'product_catalog.dart';

/// In-memory IAP gateway for tests + platforms without a real store
/// (web, desktop, Windows dev). Always returns "completed" for
/// [purchase] so the flow can be exercised end-to-end without a
/// sandbox account.
///
/// Hooks are exposed so tests can inject specific outcomes:
///   * [nextPurchaseStatus] — override the result of the next purchase
///   * [latencyMs] — simulate platform round-trip
///   * [storePrices] — what [loadProducts] returns
///   * [ownedSkus] — seed non-consumables that [restore] redelivers
class StubIapService implements IapService {
  StubIapService({
    Map<String, StorePrice>? storePrices,
    Set<String>? ownedSkus,
    this.latencyMs = 0,
  })  : storePrices = storePrices ?? _defaultPrices(),
        ownedSkus = ownedSkus ?? <String>{};

  /// Default price set matches ProductCatalog fallback prices so tests
  /// that don't override still see reasonable values.
  static Map<String, StorePrice> _defaultPrices() => {
        ProductIds.removeAds: const StorePrice(
          sku: ProductIds.removeAds,
          formattedPrice: '\$2.99',
          currencyCode: 'USD',
        ),
        ProductIds.starterBundle: const StorePrice(
          sku: ProductIds.starterBundle,
          formattedPrice: '\$1.99',
          currencyCode: 'USD',
        ),
      };

  final Map<String, StorePrice> storePrices;
  final Set<String> ownedSkus;
  final int latencyMs;

  /// Override for the very next purchase call. Reset to null after use.
  PurchaseStatus? nextPurchaseStatus;

  /// All purchase calls this service has handled. Useful for assertions.
  final List<String> purchaseLog = <String>[];

  @override
  Future<List<StorePrice>> loadProducts(List<String> skus) async {
    await _delay();
    return skus
        .map((sku) => storePrices[sku])
        .whereType<StorePrice>()
        .toList(growable: false);
  }

  @override
  Future<PurchaseResult> purchase(String sku) async {
    purchaseLog.add(sku);
    await _delay();
    final status = nextPurchaseStatus ?? PurchaseStatus.completed;
    nextPurchaseStatus = null;
    if (status == PurchaseStatus.completed) {
      ownedSkus.add(sku);
    }
    return PurchaseResult(
      status: status,
      sku: sku,
      errorMessage: status == PurchaseStatus.error ? 'stub error' : null,
    );
  }

  @override
  Future<Set<String>> restore() async {
    await _delay();
    return Set<String>.from(ownedSkus);
  }

  @override
  Future<void> acknowledge(String sku) async {
    await _delay();
    // No-op in the stub.
  }

  Future<void> _delay() async {
    if (latencyMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: latencyMs));
    }
  }
}
