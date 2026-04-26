import 'package:flutter/material.dart';

import '../../analytics/events.dart';
import '../../core/service_locator.dart';
import '../../monetization/iap_service.dart';
import '../../monetization/product_catalog.dart';
import '../../core/constants.dart';

/// Celebratory Starter Bundle paywall shown once, after the player's
/// very first rare (or better) burst. Treated as an offer — not a
/// wall — so the "Not now" action always dismisses without friction.
///
/// Show via: `await StarterBundlePopup.show(context)`.
class StarterBundlePopup extends StatefulWidget {
  const StarterBundlePopup._();

  /// Returns true if the purchase completed, false if the player
  /// dismissed. Fires all the analytics events the monetization spec
  /// requires for the starter-bundle funnel.
  static Future<bool> show(BuildContext context) async {
    final events = GameEvents(ServiceLocator.analytics);
    final progress = _collectionProgressPct();
    events.starterBundleViewed(
      source: 'first_rare_reveal',
      collectionProgressPercent: progress,
    );
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const StarterBundlePopup._(),
    );
    return result ?? false;
  }

  static int _collectionProgressPct() {
    final profile = ServiceLocator.progression.profile;
    final allObjects =
        ServiceLocator.packs.packs.expand((p) => p.objects).toList();
    if (allObjects.isEmpty) return 0;
    final discovered = allObjects
        .where((o) => profile.discoveredSmashableIds.contains(o.id))
        .length;
    return ((discovered / allObjects.length) * 100).round();
  }

  @override
  State<StarterBundlePopup> createState() => _StarterBundlePopupState();
}

class _StarterBundlePopupState extends State<StarterBundlePopup> {
  bool _purchasing = false;
  StorePrice? _livePrice;
  late final GameEvents _events;

  @override
  void initState() {
    super.initState();
    _events = GameEvents(ServiceLocator.analytics);
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final prices = await ServiceLocator.iap.loadProducts(
      [ProductIds.starterBundle],
    );
    if (!mounted) return;
    setState(() {
      _livePrice = prices.isNotEmpty ? prices.first : null;
    });
  }

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    final result = await ServiceLocator.iap.purchase(ProductIds.starterBundle);
    if (!mounted) return;
    if (result.isSuccess) {
      await ServiceLocator.purchaseGrants.applyGrantsFor(
        result.sku,
        isRestore: false,
      );
      if (!mounted) return;
      final price =
          _livePrice?.formattedPrice ?? ProductCatalog.starterBundle.fallbackPrice;
      final currency = _livePrice?.currencyCode ?? 'USD';
      _events.shopItemPurchased(
        sku: ProductIds.starterBundle,
        price: price,
        currency: currency,
        wasFirstPurchase:
            ServiceLocator.progression.profile.purchasedSkus.length == 1,
      );
      _events.starterBundlePurchased(price: price, currency: currency);
      _events.paywallClosed(
        sku: ProductIds.starterBundle,
        reason: 'purchased',
      );
      Navigator.of(context).pop(true);
    } else if (result.status == PurchaseStatus.canceled) {
      setState(() => _purchasing = false);
      _events.paywallClosed(
        sku: ProductIds.starterBundle,
        reason: 'dismissed',
      );
    } else {
      setState(() => _purchasing = false);
      _events.paywallClosed(
        sku: ProductIds.starterBundle,
        reason: 'error',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.errorMessage ?? 'Purchase failed. Please try again.'),
        ),
      );
    }
  }

  void _dismiss() {
    _events.paywallClosed(
      sku: ProductIds.starterBundle,
      reason: 'dismissed',
    );
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final product = ProductCatalog.starterBundle;
    final price =
        _livePrice?.formattedPrice ?? product.fallbackPrice;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.pink, Palette.lavender, Palette.jellyBlue],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF8FB8),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0F23),
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Palette.cream,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'First rare unlocked!',
                style: TextStyle(
                  color: Palette.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kickstart your collection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  children: [
                    _BundleRow('500 coins to unlock new packs'),
                    _BundleRow(
                      'Guaranteed rare reveal on your next round',
                    ),
                    _BundleRow('1 reveal boost token'),
                    _BundleRow('Candy Cloud Kitchen arena unlocked'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _purchasing ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.cream,
                    foregroundColor: const Color(0xFF1A0F23),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _purchasing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF1A0F23),
                          ),
                        )
                      : Text(
                          'Get bundle · $price',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _purchasing ? null : _dismiss,
                child: const Text(
                  'Not now',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleRow extends StatelessWidget {
  const _BundleRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              color: Palette.toxicLime, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
