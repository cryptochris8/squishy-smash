import 'package:flutter/material.dart';

import '../../monetization/product_catalog.dart';
import '../../core/constants.dart';

/// Premium IAP card used in the Shop's "Offers" section. Matches the
/// pastel-gradient language of PackCard so the shop reads consistently.
/// Callers pass in the currently-known live store price (falls back
/// to the product's [ProductDef.fallbackPrice] if unset).
class IapProductCard extends StatelessWidget {
  const IapProductCard({
    super.key,
    required this.product,
    required this.livePrice,
    required this.owned,
    required this.onPurchase,
    this.purchasing = false,
  });

  final ProductDef product;
  final String? livePrice;
  final bool owned;
  final bool purchasing;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final price = livePrice ?? product.fallbackPrice;
    final gradient = LinearGradient(
      colors: [
        Palette.pink.withValues(alpha: 0.35),
        Palette.cream.withValues(alpha: 0.28),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.pink, width: 1.4),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (product.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Palette.cream,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product.badge!.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1E0E2A),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.tagline,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          _RewardList(product: product),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: owned
                    ? _OwnedBadge()
                    : _PriceAndCta(
                        price: price,
                        purchasing: purchasing,
                        onTap: onPurchase,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Palette.toxicLime),
        const SizedBox(width: 8),
        Text(
          'Owned',
          style: TextStyle(
            color: Palette.toxicLime,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PriceAndCta extends StatelessWidget {
  const _PriceAndCta({
    required this.price,
    required this.purchasing,
    required this.onTap,
  });

  final String price;
  final bool purchasing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          price,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Palette.cream,
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: purchasing ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.pink,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(120, 44),
          ),
          child: purchasing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'BUY',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ],
    );
  }
}

class _RewardList extends StatelessWidget {
  const _RewardList({required this.product});

  final ProductDef product;

  @override
  Widget build(BuildContext context) {
    final lines = _describeRewards(product);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('  •  ',
                    style: TextStyle(
                      color: Palette.cream,
                      fontWeight: FontWeight.w900,
                    )),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static List<String> _describeRewards(ProductDef product) {
    final out = <String>[];
    for (final r in product.rewards) {
      switch (r.kind) {
        case RewardKind.removeAds:
          out.add('No more forced ads');
          break;
        case RewardKind.coins:
          out.add('${r.amount} coins');
          break;
        case RewardKind.boostToken:
          out.add('${r.amount} reveal boost token'
              '${r.amount == 1 ? '' : 's'}');
          break;
        case RewardKind.guaranteedReveal:
          final tierName = _rarityDisplay(r.forcedRarity);
          out.add('Guaranteed $tierName reveal on your next round');
          break;
        case RewardKind.cosmeticArena:
          out.add('Unlocks a premium arena');
          break;
      }
    }
    return out;
  }

  static String _rarityDisplay(dynamic rarity) {
    // Avoid importing Rarity just for a display name — the enum's
    // displayLabel is reachable via toString fallback in the worst
    // case. Safer to match by suffix.
    final s = rarity?.toString() ?? '';
    if (s.endsWith('.rare')) return 'rare';
    if (s.endsWith('.epic')) return 'epic';
    if (s.endsWith('.mythic')) return 'legendary';
    return 'rare';
  }
}
