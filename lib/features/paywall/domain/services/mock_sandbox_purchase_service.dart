import 'package:flutter/foundation.dart';

import '../models/billing_cycle.dart';
import '../models/subscription_tier.dart';
import 'i_purchase_service.dart';

/// Sandbox purchase backend for platforms where RevenueCat is
/// unavailable (Web/Desktop) or no API key is configured.
///
/// Executes the full subscription lifecycle in memory — offerings,
/// checkout latency, entitlement activation and restores — so the
/// complete paywall flow is demoable on every target.
final class MockSandboxPurchaseService implements IPurchaseService {
  MockSandboxPurchaseService({
    this.networkDelay = const Duration(milliseconds: 500),
    this.checkoutDelay = const Duration(milliseconds: 1400),
    this.shouldFailPurchases = false,
  });

  /// Simulated round-trip latency for fetches.
  final Duration networkDelay;

  /// Simulated store-checkout latency for purchases.
  final Duration checkoutDelay;

  /// When true, purchases throw — useful for error-path testing.
  final bool shouldFailPurchases;

  final ValueNotifier<String?> _activeTier = ValueNotifier<String?>(null);

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await Future<void>.delayed(networkDelay);
    _initialized = true;
  }

  @override
  Future<List<SubscriptionTier>> getOfferings() async {
    await Future<void>.delayed(networkDelay);
    return SubscriptionTiers.catalog;
  }

  @override
  Future<SubscriptionTier?> purchaseTier(
    SubscriptionTier tier,
    BillingCycle cycle,
  ) async {
    if (tier.isFree) {
      _activeTier.value = tier.tierId.id;
      return tier;
    }
    await Future<void>.delayed(checkoutDelay);
    if (shouldFailPurchases) {
      throw const PurchaseServiceException(
        'Sandbox checkout failed — please try again.',
      );
    }
    _activeTier.value = tier.tierId.id;
    return tier;
  }

  @override
  Future<SubscriptionTier?> restorePurchases() async {
    await Future<void>.delayed(networkDelay);
    return SubscriptionTiers.byId(_activeTier.value);
  }

  @override
  String? get activeTierId => _activeTier.value;

  @override
  ValueListenable<String?> get activeTier => _activeTier;
}
