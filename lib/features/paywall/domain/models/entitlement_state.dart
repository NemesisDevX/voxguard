import 'package:equatable/equatable.dart';

import 'billing_cycle.dart';
import 'subscription_tier.dart';

/// Where subscription state actually comes from. The UI must never
/// make a simulated store look real — this flag is the truth source
/// for that labelling.
enum PurchaseBackendMode {
  /// Google Play / App Store via RevenueCat. Real money.
  realStore,

  /// RevenueCat-hosted Test Store through the real RevenueCat SDK —
  /// development/judging builds only. Transactions are processed and
  /// verified by RevenueCat's official Test Store but never charge
  /// real money. Labelled "REVENUECAT TEST STORE" and never
  /// selectable in a release build.
  testStore,

  /// In-app simulated store for web/desktop/debug builds. Always
  /// labelled "DEMO STORE" — no real charge ever occurs.
  demoStore,

  /// No store backend configured (e.g. release build without a
  /// RevenueCat key). Free features stay usable; there is NO
  /// simulated checkout in this mode.
  unavailable,
}

/// Lifecycle of the purchase backend.
enum EntitlementStatus {
  /// Service created but `initialize()` has not completed yet.
  loading,

  /// Initialized — [EntitlementState.tier] reflects the store truth.
  ready,

  /// Backend reachable-but-failed (e.g. store unreachable). Falls
  /// back to free capabilities; `errorMessage` is consumer-safe.
  error,
}

/// The single source of truth for what this device's plan unlocks.
/// `tier` always resolves to a concrete [TierId] — never nullable —
/// so the rest of the app never reasons about raw entitlement ids.
final class EntitlementState extends Equatable {
  const EntitlementState({
    this.tier = TierId.free,
    this.backend = PurchaseBackendMode.unavailable,
    this.status = EntitlementStatus.loading,
    this.managementUrl,
    this.errorMessage,
  });

  /// Active plan — `free` when no paid entitlement is verified.
  final TierId tier;

  /// Which backend produced this state.
  final PurchaseBackendMode backend;

  final EntitlementStatus status;

  /// RevenueCat `CustomerInfo.managementURL` when available — used by
  /// Settings for "Manage subscription". Null hides that action.
  final Uri? managementUrl;

  /// Consumer-safe failure detail — never raw platform/store text.
  final String? errorMessage;

  bool get isLoading => status == EntitlementStatus.loading;
  bool get isReady => status == EntitlementStatus.ready;
  bool get isDemo => backend == PurchaseBackendMode.demoStore;

  EntitlementState copyWith({
    TierId? tier,
    PurchaseBackendMode? backend,
    EntitlementStatus? status,
    Uri? managementUrl,
    String? errorMessage,
    bool clearManagementUrl = false,
    bool clearError = false,
  }) {
    return EntitlementState(
      tier: tier ?? this.tier,
      backend: backend ?? this.backend,
      status: status ?? this.status,
      managementUrl:
          clearManagementUrl ? null : managementUrl ?? this.managementUrl,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [tier, backend, status, managementUrl, errorMessage];
}

/// One purchasable option mapped from the store's *current* offering.
///
/// [priceString] is the store-localized display price (e.g.
/// `EGP 499.99`, `$9.99`) — never a hand-typed marketing number for
/// the real backend. [nativeRef] carries the service-private store
/// object (RevenueCat `Package`) so the domain model itself stays
/// free of SDK types; UI code must not inspect it.
final class StorePackage extends Equatable {
  const StorePackage({
    required this.identifier,
    required this.tierId,
    required this.cycle,
    required this.priceString,
    required this.title,
    this.nativeRef,
  });

  /// RevenueCat custom package identifier, e.g. `sentinel_monthly`.
  final String identifier;

  /// Which plan this package activates.
  final TierId tierId;

  /// Billing period this package bills on.
  final BillingCycle cycle;

  /// Store-localized price string from the underlying product.
  final String priceString;

  /// Store product title (may be empty on some stores).
  final String title;

  /// Opaque handle for the service that produced this package.
  final Object? nativeRef;

  @override
  List<Object?> get props => [identifier];
}
