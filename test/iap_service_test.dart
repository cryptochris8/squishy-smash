import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squishy_smash/data/models/content_pack.dart';
import 'package:squishy_smash/data/models/liveops_schedule.dart';
import 'package:squishy_smash/data/models/rarity.dart';
import 'package:squishy_smash/data/persistence.dart';
import 'package:squishy_smash/data/repositories/pack_repository.dart';
import 'package:squishy_smash/data/repositories/progression_repo.dart';
import 'package:squishy_smash/monetization/iap_service.dart';
import 'package:squishy_smash/monetization/iap_service_stub.dart';
import 'package:squishy_smash/monetization/product_catalog.dart';

LiveOpsSchedule _emptySchedule() =>
    LiveOpsSchedule.fromJson(const {'featuredRotation': []});

Future<(ProgressionRepository, PurchaseGrantController, StubIapService)>
    _setup() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final persistence = await Persistence.open();
  final packs = PackRepository(<ContentPack>[], _emptySchedule());
  final repo = ProgressionRepository(persistence, packs);
  final stub = StubIapService();
  final grants = PurchaseGrantController(repo);
  return (repo, grants, stub);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StubIapService', () {
    test('loadProducts returns only the requested SKUs that exist', () async {
      final stub = StubIapService();
      final products = await stub.loadProducts(
        [ProductIds.removeAds, ProductIds.starterBundle, 'bogus_sku'],
      );
      expect(products.map((p) => p.sku), [
        ProductIds.removeAds,
        ProductIds.starterBundle,
      ]);
    });

    test('default purchase resolves as completed', () async {
      final stub = StubIapService();
      final result = await stub.purchase(ProductIds.removeAds);
      expect(result.status, PurchaseStatus.completed);
      expect(result.isSuccess, isTrue);
      expect(stub.ownedSkus, contains(ProductIds.removeAds));
    });

    test('nextPurchaseStatus override wins for a single call', () async {
      final stub = StubIapService();
      stub.nextPurchaseStatus = PurchaseStatus.canceled;
      final first = await stub.purchase(ProductIds.removeAds);
      expect(first.status, PurchaseStatus.canceled);
      expect(stub.ownedSkus, isEmpty,
          reason: 'canceled purchase should not record ownership');
      // Override resets — next call is back to completed.
      final second = await stub.purchase(ProductIds.removeAds);
      expect(second.status, PurchaseStatus.completed);
    });

    test('error override carries a message', () async {
      final stub = StubIapService();
      stub.nextPurchaseStatus = PurchaseStatus.error;
      final result = await stub.purchase(ProductIds.starterBundle);
      expect(result.status, PurchaseStatus.error);
      expect(result.errorMessage, isNotNull);
    });

    test('restore returns previously seeded ownedSkus', () async {
      final stub = StubIapService(ownedSkus: {ProductIds.removeAds});
      final restored = await stub.restore();
      expect(restored, {ProductIds.removeAds});
    });

    test('purchaseLog records every call in order', () async {
      final stub = StubIapService();
      await stub.purchase(ProductIds.starterBundle);
      await stub.purchase(ProductIds.removeAds);
      expect(stub.purchaseLog, [
        ProductIds.starterBundle,
        ProductIds.removeAds,
      ]);
    });
  });

  group('PurchaseGrantController', () {
    test('remove_ads grants the entitlement + records receipt', () async {
      final (repo, grants, _) = await _setup();
      await grants.applyGrantsFor(ProductIds.removeAds, isRestore: false);
      expect(repo.profile.hasRemoveAds, isTrue);
      expect(repo.profile.purchasedSkus, contains(ProductIds.removeAds));
    });

    test('starter_bundle applies every reward once', () async {
      final (repo, grants, _) = await _setup();
      final beforeCoins = repo.profile.coins;
      await grants.applyGrantsFor(
        ProductIds.starterBundle,
        isRestore: false,
      );
      expect(repo.profile.coins, beforeCoins + 500);
      expect(repo.profile.boostTokens, 1);
      expect(repo.profile.guaranteedRevealTokens[Rarity.rare], 1);
      expect(repo.profile.unlockedArenaKeys,
          contains('candy_cloud_kitchen'));
      expect(repo.profile.starterBundleClaimed, isTrue);
      expect(repo.profile.purchasedSkus, contains(ProductIds.starterBundle));
    });

    test('starter_bundle re-grant is a no-op (non-consumable)', () async {
      final (repo, grants, _) = await _setup();
      await grants.applyGrantsFor(
        ProductIds.starterBundle,
        isRestore: false,
      );
      final coinsAfterFirst = repo.profile.coins;
      final tokensAfterFirst = repo.profile.boostTokens;
      // Simulate a buggy double-dispatch — grant again.
      await grants.applyGrantsFor(
        ProductIds.starterBundle,
        isRestore: false,
      );
      expect(repo.profile.coins, coinsAfterFirst,
          reason: 'coins should not double-grant');
      expect(repo.profile.boostTokens, tokensAfterFirst,
          reason: 'boost tokens should not double-grant');
    });

    test('restore of remove_ads re-flips the entitlement only', () async {
      final (repo, grants, _) = await _setup();
      // Simulate a prior install that purchased remove_ads.
      await repo.markSkuPurchased(ProductIds.removeAds);
      expect(repo.profile.hasRemoveAds, isFalse,
          reason: 'fresh profile shouldnt have the entitlement yet');
      await grants.applyGrantsFor(ProductIds.removeAds, isRestore: true);
      expect(repo.profile.hasRemoveAds, isTrue,
          reason: 'restore should flip the entitlement flag on');
    });

    test('unknown SKU is silently ignored', () async {
      final (repo, grants, _) = await _setup();
      await grants.applyGrantsFor('not_a_real_sku', isRestore: false);
      expect(repo.profile.purchasedSkus, isEmpty);
    });
  });

  group('Stub + grant integration', () {
    test('successful stub purchase -> grant controller applies rewards',
        () async {
      final (repo, grants, stub) = await _setup();
      final result = await stub.purchase(ProductIds.starterBundle);
      expect(result.isSuccess, isTrue);
      await grants.applyGrantsFor(result.sku, isRestore: false);
      expect(repo.profile.starterBundleClaimed, isTrue);
      expect(repo.profile.coins, 500);
    });

    test('canceled purchase skips grant application', () async {
      final (repo, grants, stub) = await _setup();
      stub.nextPurchaseStatus = PurchaseStatus.canceled;
      final result = await stub.purchase(ProductIds.starterBundle);
      expect(result.isSuccess, isFalse);
      // Calling code is expected to gate applyGrantsFor on isSuccess.
      if (result.isSuccess) {
        await grants.applyGrantsFor(result.sku, isRestore: false);
      }
      expect(repo.profile.coins, 0);
      expect(repo.profile.starterBundleClaimed, isFalse);
    });
  });
}
