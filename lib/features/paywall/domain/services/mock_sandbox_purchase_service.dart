import 'package:flutter/foundation.dart';

import '../models/billing_cycle.dart';
import '../models/entitlement_state.dart';
import '../models/subscription_tier.dart';
import 'i_purchase_service.dart';

/// Simulated purchase backend for Web/Desktop, debug builds without
/// a RevenueCat key, and tests.
///
/// Executes the full subscription lifecycle in memory — offerings,
/// checkout latency, entitlement activation and restores — so the
/// complete paywall flow is demoable on every target.
///
/// IMPORTANT: `backendMode == PurchaseBackendMode.demoStore` is what
/// lets the UI truthfully label this path "DEMO STORE — no real
/// charge". This service must never be used to pretend a real
/// purchase happened on a store platform.
final class MockSandboxPurchaseService implements IPurchaseService {
  MockSandboxPurchaseService({
    this.networkDelay = const Duration(milliseconds: 400),
    this.checkoutDelay = const Duration(milliseconds: 900),
    this.shouldFailPurchases = false,
    this.simulateCancellation = false,
  });

  /// Simulated round-trip latency for fetches.
  final Duration networkDelay;

  /// Simulated store-checkout latency for purchases.
  final Duration checkoutDelay;

  /// When true, purchases throw — useful for error-path testing.
  final bool shouldFailPurchases;

  /// When true, purchases report user cancellation — the demo
  /// analogue of dismissing the store sheet.
  final bool simulateCancellation;

  final _state = ValueNotifier<EntitlementState>(
    const EntitlementState(
      backend: PurchaseBackendMode.demoStore,
      status: EntitlementStatus.loading,
    ),
  );

  bool _initialized = false;

  @override
  PurchaseBackendMode get backendMode => PurchaseBackendMode.demoStore;

  @override
  ValueListenable<EntitlementState> get entitlement => _state;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await Future<void>.delayed(networkDelay);
    _initialized = true;
    _state.value = _state.value.copyWith(status: EntitlementStatus.ready);
  }

  /// Demo packages mirror the real RevenueCat package identifiers so
  /// the paywall exercises the same code path. Prices are simulated —
  /// the DEMO STORE badge covers truthful labelling.
  static const _demoPackages = [
    StorePackage(
      identifier: 'sentinel_monthly',
      tierId: TierId.sentinel,
      cycle: BillingCycle.monthly,
      priceString: r'$9.99',
      title: 'Sentinel Shield (Monthly)',
    ),
    StorePackage(
      identifier: 'sentinel_annual',
      tierId: TierId.sentinel,
      cycle: BillingCycle.annual,
      priceString: r'$79.99',
      title: 'Sentinel Shield (Annual)',
    ),
    StorePackage(
      identifier: 'family_vault_monthly',
      tierId: TierId.familyVault,
      cycle: BillingCycle.monthly,
      priceString: r'$19.99',
      title: 'Family Vault (Monthly)',
    ),
    StorePackage(
      identifier: 'family_vault_annual',
      tierId: TierId.familyVault,
      cycle: BillingCycle.annual,
      priceString: r'$149.99',
      title: 'Family Vault (Annual)',
    ),
  ];

  @override
  Future<List<StorePackage>> getPackages() async {
    await Future<void>.delayed(networkDelay);
    return _demoPackages;
  }

  @override
  Future<PurchaseOutcome> purchasePackage(StorePackage package) async {
    if (package.tierId == TierId.free) {
      return PurchaseOutcome.activated(TierId.free);
    }
    await Future<void>.delayed(checkoutDelay);
    if (simulateCancellation) return PurchaseOutcome.cancelled;
    if (shouldFailPurchases) {
      throw const PurchaseServiceException(
        'Demo checkout failed — please try again.',
      );
    }
    _state.value = EntitlementState(
      tier: package.tierId,
      backend: PurchaseBackendMode.demoStore,
      status: EntitlementStatus.ready,
    );
    return PurchaseOutcome.activated(package.tierId);
  }

  @override
  Future<TierId?> restorePurchases() async {
    await Future<void>.delayed(networkDelay);
    final tier = _state.value.tier;
    return tier == TierId.free ? null : tier;
  }
}
