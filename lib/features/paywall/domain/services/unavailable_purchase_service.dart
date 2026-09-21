import 'package:flutter/foundation.dart';

import '../models/entitlement_state.dart';
import '../models/subscription_tier.dart';
import 'i_purchase_service.dart';

/// Purchase backend for production-style mobile builds with NO
/// RevenueCat key configured.
///
/// The critical contract: there is no simulated checkout here. A
/// release build missing its store configuration must never let a
/// user "activate" a fake paid plan — the paywall shows a truthful
/// unavailable notice and free features keep working.
final class UnavailablePurchaseService implements IPurchaseService {
  UnavailablePurchaseService();

  final _state = ValueNotifier<EntitlementState>(
    const EntitlementState(
      backend: PurchaseBackendMode.unavailable,
      status: EntitlementStatus.ready,
    ),
  );

  @override
  PurchaseBackendMode get backendMode => PurchaseBackendMode.unavailable;

  @override
  ValueListenable<EntitlementState> get entitlement => _state;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<StorePackage>> getPackages() async => const [];

  @override
  Future<PurchaseOutcome> purchasePackage(StorePackage package) async {
    throw const PurchaseServiceException(
      'Subscriptions are not configured in this build.',
    );
  }

  @override
  Future<TierId?> restorePurchases() async => null;
}
