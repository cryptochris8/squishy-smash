import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/monetization/product_catalog.dart';

void main() {
  group('ProductIds', () {
    test('launch-loaded SKUs contain only the P0 products', () {
      expect(ProductIds.launchLoaded,
          containsAll([ProductIds.removeAds, ProductIds.starterBundle]));
      expect(ProductIds.launchLoaded.length, 2,
          reason: 'P1/P2 SKUs should not be fetched at launch');
    });

    test('SKUs match the monetization spec strings exactly', () {
      // These strings land in App Store Connect / Play Console so drift
      // would silently break IAP resolution. Pinned intentionally.
      expect(ProductIds.removeAds, 'remove_ads');
      expect(ProductIds.starterBundle, 'starter_bundle_v1');
      expect(ProductIds.coinsSmall, 'coins_small');
      expect(ProductIds.coinsMedium, 'coins_medium');
      expect(ProductIds.coinsLarge, 'coins_large');
      expect(ProductIds.boostedRevealTokens, 'boosted_reveal_token_pack');
      expect(ProductIds.epicShards, 'epic_shard_pack');
      expect(ProductIds.voicePackCozy, 'premium_voice_pack_cozy');
      expect(ProductIds.voicePackSpooky, 'premium_voice_pack_spooky');
      expect(ProductIds.skyboxBundleGalaxy, 'skybox_bundle_galaxy');
      expect(ProductIds.themeBundleHoliday, 'theme_bundle_holiday');
    });
  });

  group('ProductCatalog', () {
    test('Starter Bundle rewards match the monetization spec', () {
      final bundle = ProductCatalog.starterBundle;
      expect(bundle.sku, 'starter_bundle_v1');
      // Doc: "Coins, one guaranteed rare collectible, one premium
      // skybox or cosmetic, one reveal boost token"
      final coinGrant = bundle.rewards
          .firstWhere((r) => r.kind == RewardKind.coins);
      expect(coinGrant.amount, 500);

      final guaranteed = bundle.rewards
          .firstWhere((r) => r.kind == RewardKind.guaranteedReveal);
      expect(guaranteed.forcedRarity, Rarity.rare);

      final boost = bundle.rewards
          .firstWhere((r) => r.kind == RewardKind.boostToken);
      expect(boost.amount, 1);

      final arena = bundle.rewards
          .firstWhere((r) => r.kind == RewardKind.cosmeticArena);
      expect(arena.arenaKey, isNotEmpty);
    });

    test('Remove Ads is a single-reward entitlement flip', () {
      final product = ProductCatalog.removeAds;
      expect(product.sku, 'remove_ads');
      expect(product.rewards, hasLength(1));
      expect(product.rewards.single.kind, RewardKind.removeAds);
      expect(product.isConsumable, isFalse);
    });

    test('bySku resolves known SKUs, returns null for unknown', () {
      expect(ProductCatalog.bySku('remove_ads'),
          ProductCatalog.removeAds);
      expect(ProductCatalog.bySku('starter_bundle_v1'),
          ProductCatalog.starterBundle);
      expect(ProductCatalog.bySku('nonsense_sku'), isNull);
    });

    test('fallback prices are populated (used before store loads)', () {
      for (final p in ProductCatalog.launch) {
        expect(p.fallbackPrice, isNotEmpty,
            reason: 'every product needs an offline fallback price');
      }
    });
  });

  group('ProductReward constructors', () {
    test('removeAds reward sets RewardKind.removeAds', () {
      const r = ProductReward.removeAds();
      expect(r.kind, RewardKind.removeAds);
    });

    test('coins reward carries amount', () {
      const r = ProductReward.coins(250);
      expect(r.kind, RewardKind.coins);
      expect(r.amount, 250);
    });

    test('guaranteedReveal reward carries rarity + count', () {
      const r = ProductReward.guaranteedReveal(Rarity.epic, count: 3);
      expect(r.kind, RewardKind.guaranteedReveal);
      expect(r.forcedRarity, Rarity.epic);
      expect(r.amount, 3);
    });

    test('cosmeticArena reward carries arena key', () {
      const r = ProductReward.cosmeticArena('neon_fidget_arcade');
      expect(r.kind, RewardKind.cosmeticArena);
      expect(r.arenaKey, 'neon_fidget_arcade');
    });
  });
}
