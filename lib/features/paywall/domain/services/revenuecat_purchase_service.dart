import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/billing_cycle.dart';
import '../models/entitlement_state.dart';
import '../models/subscription_tier.dart';
import 'i_purchase_service.dart';

/// RevenueCat entitlement identifiers — configured in the RevenueCat
/// Dashboard and attached to the platform products. See
/// docs/REVENUECAT_SETUP.md.
abstract final class RevenueCatEntitlements {
  RevenueCatEntitlements._();

  static const String sentinel = 'sentinel';
  static const String familyVault = 'family_vault';
}

/// Expected custom package identifiers in the CURRENT RevenueCat
/// Offering. Product ids underneath may differ per store — Flutter
/// code never sees them.
abstract final class RevenueCatPackageIds {
  RevenueCatPackageIds._();

  static const String sentinelMonthly = 'sentinel_monthly';
  static const String sentinelAnnual = 'sentinel_annual';
  static const String familyVaultMonthly = 'family_vault_monthly';
  static const String familyVaultAnnual = 'family_vault_annual';
}

/// Seam over the static `Purchases` SDK so the service can be unit
/// tested without platform channels. Production code uses
/// [PurchasesSdkAdapter]; tests inject a fake.
abstract interface class IPurchasesAdapter {
  Future<bool> isConfigured();
  Future<void> configure(String apiKey);
  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener);
  Future<Offerings> getOfferings();
  Future<CustomerInfo> getCustomerInfo();
  Future<CustomerInfo> purchasePackage(Package package);
  Future<CustomerInfo> restorePurchases();
}

/// Real adapter — one-line delegations over the RevenueCat SDK.
/// Platform-channel only; no logic lives here.
final class PurchasesSdkAdapter implements IPurchasesAdapter {
  const PurchasesSdkAdapter();

  @override
  Future<bool> isConfigured() => Purchases.isConfigured;

  @override
  Future<void> configure(String apiKey) =>
      Purchases.configure(PurchasesConfiguration(apiKey));

  @override
  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) =>
      Purchases.addCustomerInfoUpdateListener(listener);

  @override
  Future<Offerings> getOfferings() => Purchases.getOfferings();

  @override
  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  @override
  Future<CustomerInfo> purchasePackage(Package package) async =>
      (await Purchases.purchase(PurchaseParams.package(package)))
          .customerInfo;

  @override
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();
}

/// Real-store purchase backend. Wraps RevenueCat's Flutter SDK and
/// exposes plan truth exclusively through [entitlement] — SDK types
/// never escape this boundary.
///
/// Two genuine RevenueCat backends share this implementation:
/// [RevenueCatPurchaseService.new] — the platform store key
/// (Google Play / App Store), and [RevenueCatPurchaseService.testStore]
/// — RevenueCat's hosted Test Store for judging/development builds.
/// Both go through the real SDK and both derive plan truth ONLY from
/// `CustomerInfo`; [backendMode] distinguishes them for labelling.
///
/// The caller is responsible for only constructing this service on
/// Android/iOS with a configured SDK key (see
/// `purchase_service_factory_io.dart`); [initialize] still fails
/// truthfully rather than fabricating access if the key is absent.
final class RevenueCatPurchaseService implements IPurchaseService {
  RevenueCatPurchaseService({
    String? apiKey,
    IPurchasesAdapter? adapter,
    PurchaseBackendMode backendMode = PurchaseBackendMode.realStore,
  })  : _apiKey = apiKey ?? _resolvePlatformKey(),
        _adapter = adapter ?? const PurchasesSdkAdapter(),
        _mode = backendMode,
        _state = ValueNotifier(EntitlementState(backend: backendMode));

  /// RevenueCat Test Store backend — the real RevenueCat SDK pointed
  /// at a Test Store API key. Judging/development path only: the
  /// factory never selects this in a release build. [apiKey] exists
  /// only so tests can inject a fake key — production reads the
  /// `REVENUECAT_TEST_STORE_KEY` dart-define.
  RevenueCatPurchaseService.testStore({
    String? apiKey,
    IPurchasesAdapter? adapter,
  }) : this(
          apiKey: apiKey ?? testStoreKey,
          adapter: adapter,
          backendMode: PurchaseBackendMode.testStore,
        );

  final String _apiKey;
  final IPurchasesAdapter _adapter;
  final PurchaseBackendMode _mode;

  /// Public SDK keys (safe to embed — NOT secret REST keys) supplied
  /// at build time:
  ///   --dart-define=REVENUECAT_ANDROID_KEY=...
  ///   --dart-define=REVENUECAT_IOS_KEY=...
  static const _androidKey =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// RevenueCat Test Store API key — development/judging builds only.
  /// A Test Store key must NEVER act as the production configuration:
  /// the factory only honours it on Android/iOS in non-release builds.
  ///   --dart-define=REVENUECAT_TEST_STORE_KEY=...
  static const _testStoreKey =
      String.fromEnvironment('REVENUECAT_TEST_STORE_KEY');

  final ValueNotifier<EntitlementState> _state;

  Future<void>? _initFuture;
  bool _listenerAttached = false;

  /// dart:io-free platform key resolution — the factory only builds
  /// this service on Android/iOS; tests always inject [apiKey].
  static String _resolvePlatformKey() {
    // defaultTargetPlatform is testable and avoids dart:io so the
    // file stays importable from widget tests on the VM.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidKey;
      case TargetPlatform.iOS:
        return _iosKey;
      // Real-store scope is Android/iOS only this release — macOS
      // has no configured/validated RevenueCat app, so no key
      // resolves and the factory routes it to the Demo Store.
      default:
        return '';
    }
  }

  /// True when a public SDK key exists for the current platform.
  /// Used by the purchase-service factory to decide real vs
  /// unavailable/demo backends.
  static bool get isSupported => _resolvePlatformKey().isNotEmpty;

  /// The Test Store API key supplied at build time (may be empty).
  static String get testStoreKey => _testStoreKey;

  /// True when a RevenueCat Test Store key exists. The factory gates
  /// this to non-release Android/iOS builds — it is never a release
  /// fallback.
  static bool get isTestStoreSupported => _testStoreKey.isNotEmpty;

  @override
  PurchaseBackendMode get backendMode => _mode;

  @override
  ValueListenable<EntitlementState> get entitlement => _state;

  @override
  Future<void> initialize() {
    // Idempotent — a second call joins the in-flight/finished future
    // instead of re-configuring or double-attaching the listener.
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      if (_apiKey.isEmpty) {
        throw const PurchaseServiceException(
          'Subscriptions are not configured in this build.',
        );
      }
      if (!await _adapter.isConfigured()) {
        await _adapter.configure(_apiKey);
      }
      if (!_listenerAttached) {
        _adapter.addCustomerInfoUpdateListener(_applyCustomerInfo);
        _listenerAttached = true;
      }
      _applyCustomerInfo(await _adapter.getCustomerInfo());
    } on PurchaseServiceException {
      _initFuture = null; // allow a later retry
      rethrow;
    } catch (e) {
      _initFuture = null;
      _state.value = _state.value.copyWith(
        status: EntitlementStatus.error,
        errorMessage: 'Subscriptions could not be initialized.',
      );
      throw PurchaseServiceException(
        'Subscriptions could not be initialized.',
        detail: e.toString(),
      );
    }
  }

  /// CustomerInfo is the ONLY authority for plan truth — we never
  /// infer entitlement from a product id or a returned call.
  void _applyCustomerInfo(CustomerInfo info) {
    final entitlements = info.entitlements.all;
    final tier = entitlements[RevenueCatEntitlements.familyVault]
                ?.isActive ==
            true
        ? TierId.familyVault
        : entitlements[RevenueCatEntitlements.sentinel]?.isActive ==
                true
            ? TierId.sentinel
            : TierId.free;
    final url = info.managementURL;
    _state.value = EntitlementState(
      tier: tier,
      backend: _mode,
      status: EntitlementStatus.ready,
      managementUrl: url == null ? null : Uri.tryParse(url),
    );
  }

  /// Maps the *current* Offering's packages only. Unknown identifiers
  /// are ignored — never fabricated into purchasable rows.
  @override
  Future<List<StorePackage>> getPackages() async {
    final Offerings offerings;
    try {
      offerings = await _adapter.getOfferings();
    } catch (e) {
      throw PurchaseServiceException(
        'Plans could not be loaded from the store.',
        detail: e.toString(),
      );
    }
    final current = offerings.current;
    if (current == null) return const [];
    final packages = <StorePackage>[];
    for (final pkg in current.availablePackages) {
      final mapped = _mapPackageIdentifier(pkg.identifier);
      if (mapped == null) continue;
      packages.add(
        StorePackage(
          identifier: pkg.identifier,
          tierId: mapped.$1,
          cycle: mapped.$2,
          priceString: pkg.storeProduct.priceString,
          title: pkg.storeProduct.title,
          nativeRef: pkg,
        ),
      );
    }
    return packages;
  }

  static (TierId, BillingCycle)? _mapPackageIdentifier(String id) {
    switch (id) {
      case RevenueCatPackageIds.sentinelMonthly:
        return (TierId.sentinel, BillingCycle.monthly);
      case RevenueCatPackageIds.sentinelAnnual:
        return (TierId.sentinel, BillingCycle.annual);
      case RevenueCatPackageIds.familyVaultMonthly:
        return (TierId.familyVault, BillingCycle.monthly);
      case RevenueCatPackageIds.familyVaultAnnual:
        return (TierId.familyVault, BillingCycle.annual);
    }
    return null;
  }

  @override
  Future<PurchaseOutcome> purchasePackage(StorePackage package) async {
    final native = package.nativeRef;
    if (native is! Package) {
      throw const PurchaseServiceException(
        'That plan is not available in this store.',
      );
    }
    final CustomerInfo info;
    try {
      info = await _adapter.purchasePackage(native);
    } catch (e) {
      if (_isCancellation(e)) return PurchaseOutcome.cancelled;
      throw PurchaseServiceException(
        _safePurchaseError(e),
        detail: e.toString(),
      );
    }
    _applyCustomerInfo(info);
    final tier = _state.value.tier;
    // Never grant access merely because the call returned — the
    // verified entitlement is the only success signal.
    return tier == TierId.free
        ? PurchaseOutcome.notActivated
        : PurchaseOutcome.activated(tier);
  }

  @override
  Future<TierId?> restorePurchases() async {
    try {
      final info = await _adapter.restorePurchases();
      _applyCustomerInfo(info);
      final tier = _state.value.tier;
      return tier == TierId.free ? null : tier;
    } catch (e) {
      throw PurchaseServiceException(
        'Purchases could not be restored right now.',
        detail: e.toString(),
      );
    }
  }

  static bool _isCancellation(Object e) =>
      e is PlatformException &&
      PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError;

  /// Maps store failures to consumer-safe copy — raw RevenueCat ids,
  /// provider bodies, and exception text must never reach the UI.
  static String _safePurchaseError(Object e) {
    if (e is! PlatformException) {
      return 'The purchase could not be completed.';
    }
    switch (PurchasesErrorHelper.getErrorCode(e)) {
      case PurchasesErrorCode.networkError:
        return 'No connection — check your network and try again.';
      case PurchasesErrorCode.storeProblemError:
        return 'The store is unavailable right now. Try again later.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device or account.';
      case PurchasesErrorCode.paymentPendingError:
        return 'The payment is pending approval.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'That plan is not available in this store.';
      default:
        return 'The purchase could not be completed.';
    }
  }
}
