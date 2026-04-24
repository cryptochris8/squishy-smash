import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import 'iap_service.dart';

/// Production IAP gateway backed by the in_app_purchase plugin. Wraps
/// StoreKit on iOS + BillingClient on Android behind the same
/// interface as [StubIapService], so the shop UI and
/// PurchaseGrantController don't need to branch per platform.
///
/// Usage: at app startup, register a single instance as a singleton
/// and keep it alive for the process lifetime — the purchase stream
/// is subscribed once on construction, and teardown is only safe at
/// app exit.
class RealIapService implements IapService {
  RealIapService({iap.InAppPurchase? plugin})
      : _iap = plugin ?? iap.InAppPurchase.instance {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object err) {
        debugPrint('RealIapService: purchase stream error: $err');
      },
    );
  }

  final iap.InAppPurchase _iap;
  late final StreamSubscription<List<iap.PurchaseDetails>> _subscription;

  /// Pending completers keyed by SKU. When a purchase enters
  /// PurchaseStatus.purchased (success) / error / canceled we look up
  /// the matching completer and resolve the public future.
  final Map<String, Completer<PurchaseResult>> _pending = {};

  /// Most recent restore attempt, resolved by the purchase stream when
  /// historical receipts flow through.
  Completer<Set<String>>? _restoreCompleter;
  final Set<String> _restoreBuffer = <String>{};

  void dispose() {
    _subscription.cancel();
  }

  @override
  Future<List<StorePrice>> loadProducts(List<String> skus) async {
    if (!await _iap.isAvailable()) return const [];
    final response = await _iap.queryProductDetails(skus.toSet());
    if (response.error != null) {
      debugPrint('RealIapService: query error: ${response.error}');
    }
    return response.productDetails
        .map((p) => StorePrice(
              sku: p.id,
              formattedPrice: p.price,
              currencyCode: p.currencyCode,
            ))
        .toList(growable: false);
  }

  @override
  Future<PurchaseResult> purchase(String sku) async {
    if (!await _iap.isAvailable()) {
      return PurchaseResult(
        status: PurchaseStatus.error,
        sku: sku,
        errorMessage: 'Store not available on this device',
      );
    }
    final query = await _iap.queryProductDetails({sku});
    if (query.productDetails.isEmpty) {
      return PurchaseResult(
        status: PurchaseStatus.error,
        sku: sku,
        errorMessage: 'Product not found in store',
      );
    }

    // A completer already in flight means a duplicate tap — share the
    // existing future so the shop UI doesn't spam the store.
    final existing = _pending[sku];
    if (existing != null && !existing.isCompleted) {
      return existing.future;
    }
    final completer = Completer<PurchaseResult>();
    _pending[sku] = completer;

    final purchaseParam = iap.PurchaseParam(
      productDetails: query.productDetails.first,
    );
    // Non-consumable vs consumable is a plugin-level branch. For now
    // every SKU in the launch catalog is non-consumable; consumables
    // will move to `buyConsumable` once we add the coin ladder.
    final launched =
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!launched) {
      _pending.remove(sku);
      return PurchaseResult(
        status: PurchaseStatus.error,
        sku: sku,
        errorMessage: 'Store declined to show purchase UI',
      );
    }
    return completer.future;
  }

  @override
  Future<Set<String>> restore() async {
    if (!await _iap.isAvailable()) return const <String>{};
    _restoreBuffer.clear();
    _restoreCompleter = Completer<Set<String>>();
    await _iap.restorePurchases();
    // The plugin streams restored purchases through the same
    // purchaseStream handler — that's where we populate the buffer
    // and eventually resolve the completer. Give it a ceiling so a
    // store hang doesn't lock the UI forever.
    return _restoreCompleter!.future
        .timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('RealIapService: restore timed out');
      return Set<String>.from(_restoreBuffer);
    });
  }

  @override
  Future<void> acknowledge(String sku) async {
    // The plugin auto-completes pending purchases when we call
    // completePurchase on the corresponding PurchaseDetails. The
    // stream handler already does this on successful purchases, so
    // this public method is a no-op unless future flows need to
    // explicitly re-ack (e.g. after server-side validation).
  }

  void _onPurchaseUpdates(List<iap.PurchaseDetails> updates) {
    for (final update in updates) {
      final sku = update.productID;
      switch (update.status) {
        case iap.PurchaseStatus.pending:
          // No-op — the completer stays unresolved until terminal.
          break;
        case iap.PurchaseStatus.purchased:
        case iap.PurchaseStatus.restored:
          if (update.status == iap.PurchaseStatus.restored) {
            _restoreBuffer.add(sku);
          }
          _resolvePending(sku, _pkgToResult(update));
          if (update.pendingCompletePurchase) {
            _iap.completePurchase(update);
          }
          break;
        case iap.PurchaseStatus.canceled:
          _resolvePending(sku, _pkgToResult(update));
          break;
        case iap.PurchaseStatus.error:
          _resolvePending(sku, _pkgToResult(update));
          if (update.pendingCompletePurchase) {
            _iap.completePurchase(update);
          }
          break;
      }
    }
    // If we're mid-restore and the batch landed, resolve after the
    // updates drain — the plugin signals end of restore by sending all
    // historical purchases in a single burst.
    final restore = _restoreCompleter;
    if (restore != null && !restore.isCompleted) {
      // There's no explicit end-of-restore signal in the plugin's
      // public API, so we settle after a short tail window.
      Timer(const Duration(milliseconds: 300), () {
        if (!restore.isCompleted) {
          restore.complete(Set<String>.from(_restoreBuffer));
        }
      });
    }
  }

  PurchaseResult _pkgToResult(iap.PurchaseDetails d) {
    switch (d.status) {
      case iap.PurchaseStatus.purchased:
      case iap.PurchaseStatus.restored:
        return PurchaseResult(
          status: PurchaseStatus.completed,
          sku: d.productID,
        );
      case iap.PurchaseStatus.canceled:
        return PurchaseResult(
          status: PurchaseStatus.canceled,
          sku: d.productID,
        );
      case iap.PurchaseStatus.error:
        return PurchaseResult(
          status: PurchaseStatus.error,
          sku: d.productID,
          errorMessage: d.error?.message,
        );
      case iap.PurchaseStatus.pending:
        return PurchaseResult(
          status: PurchaseStatus.pending,
          sku: d.productID,
        );
    }
  }

  void _resolvePending(String sku, PurchaseResult result) {
    final completer = _pending.remove(sku);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }
}
