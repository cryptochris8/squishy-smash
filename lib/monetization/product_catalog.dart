import '../data/models/rarity.dart';

/// IAP SKU identifiers. These must match the product IDs created in
/// App Store Connect and Google Play Console exactly. The exact
/// casing + underscores are pulled from the monetization spec so
/// server-side receipt validation keys off the same strings.
abstract final class ProductIds {
  // ----- P0 launch -----
  static const String removeAds = 'remove_ads';
  static const String starterBundle = 'starter_bundle_v1';

  // ----- P1 consumables -----
  static const String coinsSmall = 'coins_small';
  static const String coinsMedium = 'coins_medium';
  static const String coinsLarge = 'coins_large';
  static const String boostedRevealTokens = 'boosted_reveal_token_pack';
  static const String epicShards = 'epic_shard_pack';

  // ----- P2 cosmetics -----
  static const String voicePackCozy = 'premium_voice_pack_cozy';
  static const String voicePackSpooky = 'premium_voice_pack_spooky';
  static const String skyboxBundleGalaxy = 'skybox_bundle_galaxy';
  static const String themeBundleHoliday = 'theme_bundle_holiday';

  /// SKUs the app will load at launch (keeps store-calls minimal —
  /// P2 items opt in once their offers are actually wired up).
  static const List<String> launchLoaded = [
    removeAds,
    starterBundle,
  ];
}

/// Which of the app's internal reward systems an IAP grants. The
/// service layer resolves this into actual profile state changes on
/// successful purchase — keeps the grant logic data-driven rather
/// than hand-coded per SKU.
enum RewardKind {
  removeAds,
  coins,
  boostToken,
  guaranteedReveal,
  cosmeticArena,
}

class ProductReward {
  const ProductReward({
    required this.kind,
    this.amount = 1,
    this.forcedRarity,
    this.arenaKey,
  });

  /// Remove-ads entitlement flip.
  const ProductReward.removeAds()
      : kind = RewardKind.removeAds,
        amount = 1,
        forcedRarity = null,
        arenaKey = null;

  /// N coins awarded to profile.coins.
  const ProductReward.coins(int n)
      : kind = RewardKind.coins,
        amount = n,
        forcedRarity = null,
        arenaKey = null;

  /// N boost tokens granted (see RarityPitySelector.boostTokenMultiplier).
  const ProductReward.boostToken(int n)
      : kind = RewardKind.boostToken,
        amount = n,
        forcedRarity = null,
        arenaKey = null;

  /// A forced-tier reveal token — next spawn will bypass weighting
  /// and produce an object of [forcedRarity].
  const ProductReward.guaranteedReveal(Rarity rarity, {int count = 1})
      : kind = RewardKind.guaranteedReveal,
        amount = count,
        forcedRarity = rarity,
        arenaKey = null;

  /// Unlocks an arena from ArenaRegistry without charging coins.
  const ProductReward.cosmeticArena(String key)
      : kind = RewardKind.cosmeticArena,
        amount = 1,
        forcedRarity = null,
        arenaKey = key;

  final RewardKind kind;
  final int amount;
  final Rarity? forcedRarity;
  final String? arenaKey;
}

/// Metadata for an IAP product as displayed in the Shop. Price is
/// intentionally omitted from this model — the live price + localized
/// currency comes from the platform store at runtime.
class ProductDef {
  const ProductDef({
    required this.sku,
    required this.displayName,
    required this.tagline,
    required this.fallbackPrice,
    required this.rewards,
    this.isConsumable = false,
    this.badge,
  });

  /// Matches a ProductIds constant. This is the string passed to
  /// StoreKit / Play Billing.
  final String sku;

  /// Human-readable name shown in the shop card header.
  final String displayName;

  /// One-sentence pitch shown under the name.
  final String tagline;

  /// Shown only if the live store price isn't available yet (offline,
  /// before products have loaded). Localization uses the store price
  /// when present.
  final String fallbackPrice;

  /// Everything the player receives on purchase. A single product can
  /// grant multiple rewards (e.g. Starter Bundle grants coins + boost
  /// token + arena unlock).
  final List<ProductReward> rewards;

  /// True for consumable-style SKUs that can be purchased repeatedly
  /// (coin packs, boost token packs). False for unlock-style SKUs
  /// (remove_ads, starter_bundle, cosmetic bundles).
  final bool isConsumable;

  /// Optional corner badge for the shop UI — "Best value", "New", etc.
  final String? badge;
}

/// Static catalog driving the shop + paywall UI. Order here is the
/// display order in the shop section.
abstract final class ProductCatalog {
  static const ProductDef removeAds = ProductDef(
    sku: ProductIds.removeAds,
    displayName: 'No Ads',
    tagline: 'Turn off forced interstitials. Keep optional boost ads.',
    fallbackPrice: '\$2.99',
    rewards: [ProductReward.removeAds()],
  );

  static const ProductDef starterBundle = ProductDef(
    sku: ProductIds.starterBundle,
    displayName: 'Starter Bundle',
    tagline: 'Coins, a guaranteed rare, a premium arena, and a boost token.',
    fallbackPrice: '\$1.99',
    rewards: [
      ProductReward.coins(500),
      ProductReward.guaranteedReveal(Rarity.rare),
      ProductReward.boostToken(1),
      ProductReward.cosmeticArena('candy_cloud_kitchen'),
    ],
    badge: 'Best value',
  );

  /// Products loaded + shown at launch. Phase 1+2 products are added
  /// to this list as they come online.
  static const List<ProductDef> launch = [
    starterBundle,
    removeAds,
  ];

  static ProductDef? bySku(String sku) {
    for (final p in launch) {
      if (p.sku == sku) return p;
    }
    return null;
  }
}
