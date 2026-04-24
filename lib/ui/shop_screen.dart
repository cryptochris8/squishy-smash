import 'package:flutter/material.dart';

import '../analytics/events.dart';
import '../core/service_locator.dart';
import '../data/models/content_pack.dart';
import '../game/systems/arena_registry.dart';
import '../monetization/iap_service.dart';
import '../monetization/product_catalog.dart';
import 'widgets/coin_badge.dart';
import 'widgets/iap_product_card.dart';
import 'widgets/pack_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  Map<String, StorePrice> _livePrices = <String, StorePrice>{};
  final Set<String> _purchasingSkus = <String>{};
  bool _restoring = false;
  late final GameEvents _events;

  @override
  void initState() {
    super.initState();
    _events = GameEvents(ServiceLocator.analytics);
    _events.shopOpened(source: 'menu_cta');
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final prices = await ServiceLocator.iap.loadProducts(
      ProductIds.launchLoaded,
    );
    if (!mounted) return;
    setState(() {
      _livePrices = {for (final p in prices) p.sku: p};
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = ServiceLocator.packs.packs;
    final progression = ServiceLocator.progression;
    final standaloneArenas = ArenaRegistry.standalone.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SHOP',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: CoinBadge(coins: progression.profile.coins)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Offers'),
          const SizedBox(height: 8),
          for (final product in ProductCatalog.launch) ...[
            IapProductCard(
              product: product,
              livePrice: _livePrices[product.sku]?.formattedPrice,
              owned: _isOwned(product.sku),
              purchasing: _purchasingSkus.contains(product.sku),
              onPurchase: () => _buy(product),
            ),
            const SizedBox(height: 12),
          ],
          TextButton.icon(
            onPressed: _restoring ? null : _restore,
            icon: _restoring
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore, size: 18),
            label: Text(
              _restoring ? 'Restoring...' : 'Restore purchases',
              style: const TextStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
          const SizedBox(height: 20),
          const _SectionHeader('Object Packs'),
          const SizedBox(height: 8),
          for (final pack in packs) ...[
            PackCard(
              pack: pack,
              unlocked: progression.isUnlocked(pack.packId),
              onUnlock: progression.isUnlocked(pack.packId)
                  ? null
                  : () => _attemptUnlockPack(pack),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          const _SectionHeader('Arenas'),
          const SizedBox(height: 8),
          for (final theme in standaloneArenas) ...[
            _ArenaSkuCard(
              theme: theme,
              unlocked: progression.isArenaUnlocked(theme.key),
              onUnlock: progression.isArenaUnlocked(theme.key)
                  ? null
                  : () => _attemptUnlockArena(theme),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  bool _isOwned(String sku) {
    final profile = ServiceLocator.progression.profile;
    switch (sku) {
      case ProductIds.removeAds:
        return profile.hasRemoveAds;
      case ProductIds.starterBundle:
        return profile.starterBundleClaimed;
      default:
        return profile.purchasedSkus.contains(sku);
    }
  }

  Future<void> _buy(ProductDef product) async {
    _events.shopItemViewed(sku: product.sku);
    if (product.sku == ProductIds.removeAds) {
      _events.removeAdsViewed(source: 'shop');
    } else if (product.sku == ProductIds.starterBundle) {
      _events.starterBundleViewed(
        source: 'shop',
        collectionProgressPercent: _collectionProgressPct(),
      );
    }
    setState(() => _purchasingSkus.add(product.sku));
    final result = await ServiceLocator.iap.purchase(product.sku);
    if (!mounted) return;
    setState(() => _purchasingSkus.remove(product.sku));

    if (result.isSuccess) {
      await ServiceLocator.purchaseGrants.applyGrantsFor(
        result.sku,
        isRestore: false,
      );
      if (!mounted) return;
      final price = _livePrices[product.sku]?.formattedPrice ??
          product.fallbackPrice;
      final currency =
          _livePrices[product.sku]?.currencyCode ?? 'USD';
      _events.shopItemPurchased(
        sku: product.sku,
        price: price,
        currency: currency,
        wasFirstPurchase:
            ServiceLocator.progression.profile.purchasedSkus.length == 1,
      );
      if (product.sku == ProductIds.removeAds) {
        _events.removeAdsPurchased(price: price, currency: currency);
      } else if (product.sku == ProductIds.starterBundle) {
        _events.starterBundlePurchased(price: price, currency: currency);
      }
      _events.paywallClosed(sku: product.sku, reason: 'purchased');
      _showSnack('Thanks! ${product.displayName} unlocked.');
      setState(() {}); // refresh "Owned" badge + coin badge
    } else if (result.status == PurchaseStatus.canceled) {
      _events.paywallClosed(sku: product.sku, reason: 'dismissed');
    } else {
      _events.paywallClosed(sku: product.sku, reason: 'error');
      _showSnack(result.errorMessage ?? 'Purchase failed. Please try again.');
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final restored = await ServiceLocator.iap.restore();
    for (final sku in restored) {
      await ServiceLocator.purchaseGrants.applyGrantsFor(
        sku,
        isRestore: true,
      );
    }
    if (!mounted) return;
    setState(() => _restoring = false);
    _showSnack(restored.isEmpty
        ? 'No previous purchases found.'
        : 'Restored ${restored.length} purchase${restored.length == 1 ? '' : 's'}.');
  }

  int _collectionProgressPct() {
    final profile = ServiceLocator.progression.profile;
    final allObjects = ServiceLocator.packs.packs.expand((p) => p.objects).toList();
    if (allObjects.isEmpty) return 0;
    final discovered = allObjects
        .where((o) => profile.discoveredSmashableIds.contains(o.id))
        .length;
    return ((discovered / allObjects.length) * 100).round();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _attemptUnlockPack(ContentPack pack) async {
    final ok = await ServiceLocator.progression.tryUnlock(pack.packId);
    if (!mounted) return;
    setState(() {});
    final msg = ok
        ? 'Unlocked ${pack.displayName}!'
        : 'Need ${pack.unlockCost} coins (you have ${ServiceLocator.progression.profile.coins})';
    _showSnack(msg);
  }

  Future<void> _attemptUnlockArena(ArenaTheme theme) async {
    final ok = await ServiceLocator.progression.tryUnlockArena(theme.key);
    if (!mounted) return;
    setState(() {});
    final msg = ok
        ? 'Unlocked ${theme.displayName}! Set as active in Settings.'
        : 'Need ${theme.cost} coins (you have ${ServiceLocator.progression.profile.coins})';
    _showSnack(msg);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Color(0xFFFFD36E),
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Compact storefront card for a standalone arena SKU. Layout mirrors
/// PackCard so the shop reads consistently — gradient swatch from the
/// arena's calmColors, cost or checkmark on the right, unlock CTA when
/// locked.
class _ArenaSkuCard extends StatelessWidget {
  const _ArenaSkuCard({
    required this.theme,
    required this.unlocked,
    required this.onUnlock,
  });

  final ArenaTheme theme;
  final bool unlocked;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final swatchTop = theme.calmColors.first;
    final swatchBottom = theme.calmColors.last;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            swatchTop.withValues(alpha: 0.35),
            swatchBottom.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: swatchTop, width: 1.4),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.calmColors,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  theme.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked
                      ? 'Owned — switch in Settings'
                      : 'Standalone arena',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, color: Color(0xFFB6FF5C))
          else ...[
            Text(
              '${theme.cost}',
              style: const TextStyle(
                color: Color(0xFFFFD36E),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: swatchTop,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'UNLOCK',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
