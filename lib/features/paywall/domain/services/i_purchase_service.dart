import 'package:flutter/foundation.dart';

import '../models/billing_cycle.dart';
import '../models/subscription_tier.dart';

/// Failure thrown by a purchase service.
class PurchaseServiceException implements Exception {
  const PurchaseServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Platform-neutral contract for the subscription backend.
///
/// Two implementations exist:
///  - `RevenueCatPurchaseService` — real `purchases_flutter` integration
///    (Android/iOS/macOS with configured API keys).
///  - `MockSandboxPurchaseService` — full lifecycle simulation used on
///    Web/Desktop and whenever sandbox keys are absent.
///
/// Selection happens in `purchase_service_factory.dart` via conditional
/// import so unsupported platforms never compile RevenueCat code.
abstract interface class IPurchaseService {
  /// One-time SDK/session setup. Idempotent.
  Future<void> initialize();

  /// Available plans (store offerings or local catalog fallback).
  Future<List<SubscriptionTier>> getOfferings();

  /// Purchases [tier] on [cycle]. Returns the activated tier, or null
  /// when the user cancelled.
  Future<SubscriptionTier?> purchaseTier(
    SubscriptionTier tier,
    BillingCycle cycle,
  );

  /// Restores prior purchases. Returns the restored tier, or null when
  /// the store account holds none.
  Future<SubscriptionTier?> restorePurchases();

  /// Currently active entitlement id (`free`/`sentinel`/`family_vault`),
  /// or null when only the free plan is in effect.
  String? get activeTierId;

  /// Reactive view of [activeTierId] so UI badges update instantly.
  ValueListenable<String?> get activeTier;
}
