import 'package:flutter/foundation.dart';

import '../models/entitlement_state.dart';
import '../models/subscription_tier.dart';

/// A thrown purchase/backend failure. `message` is always a
/// consumer-safe sentence — raw PlatformException text, RevenueCat
/// internal ids, and provider bodies must never reach the UI.
final class PurchaseServiceException implements Exception {
  const PurchaseServiceException(this.message, {this.detail});

  /// Consumer-safe message.
  final String message;

  /// Optional diagnostic for debug logging — not for display.
  final String? detail;

  @override
  String toString() =>
      'PurchaseServiceException($message${detail == null ? '' : ', $detail'})';
}

/// Outcome of a store purchase attempt.
final class PurchaseOutcome {
  const PurchaseOutcome._({this.tier, this.wasCancelled = false});

  /// Store confirmed the purchase AND CustomerInfo verifies the
  /// entitlement. The only path that may unlock a paid plan.
  factory PurchaseOutcome.activated(TierId tier) =>
      PurchaseOutcome._(tier: tier);

  /// User dismissed the native purchase sheet — NOT an error; the
  /// paywall simply stays interactive.
  static const PurchaseOutcome cancelled =
      PurchaseOutcome._(wasCancelled: true);

  /// The purchase call returned but no entitlement is active yet
  /// (e.g. pending approval / propagation delay). Not a success —
  /// no tier may be granted.
  static const PurchaseOutcome notActivated = PurchaseOutcome._();

  /// Verified active tier after the call — null unless activated.
  final TierId? tier;

  /// True when the user cancelled the purchase sheet.
  final bool wasCancelled;
}

/// Boundary between PauseSignal and the subscription backend.
///
/// The rest of the app reads plan truth ONLY through [entitlement];
/// store SDK types never cross this line. Implementations:
/// [RevenueCatPurchaseService] (real store), [MockSandboxPurchaseService]
/// (demo store), [UnavailablePurchaseService] (no backend).
abstract interface class IPurchaseService {
  /// Which backend produced [entitlement]. Drives paywall labelling —
  /// demo vs real vs unavailable.
  PurchaseBackendMode get backendMode;

  /// Reactive entitlement truth. Changes on purchases, restores,
  /// renewals, expirations, and cross-device sync — UI updates
  /// without restart.
  ValueListenable<EntitlementState> get entitlement;

  /// Idempotent — repeated calls are safe, no duplicate listeners.
  Future<void> initialize();

  /// Packages in the store's *current* offering only. Missing
  /// packages are simply absent — never fabricated. Empty list on
  /// the unavailable backend.
  Future<List<StorePackage>> getPackages();

  /// Purchase [package] through the active backend.
  ///
  /// `activated` only when CustomerInfo verifies the entitlement —
  /// never granted merely because the call returned. `cancelled`
  /// when the user dismissed the sheet. Throws
  /// [PurchaseServiceException] with consumer-safe text on failure.
  Future<PurchaseOutcome> purchasePackage(StorePackage package);

  /// Sync entitlement state from the store's record of this device.
  /// Returns the verified active tier, or null when nothing was
  /// restored — the paywall keeps showing its normal layout.
  Future<TierId?> restorePurchases();
}
