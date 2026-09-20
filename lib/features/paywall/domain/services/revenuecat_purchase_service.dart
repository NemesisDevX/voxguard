import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/billing_cycle.dart';
import '../models/subscription_tier.dart';
import 'i_purchase_service.dart';

/// Production purchase backend powered by RevenueCat
/// (`purchases_flutter`). Only constructed on store-supported mobile
/// platforms with a configured sandbox/production API key.
///
/// Keys are injected at build time:
/// `--dart-define=REVENUECAT_ANDROID_KEY=goog_...`
/// `--dart-define=REVENUECAT_IOS_KEY=appl_...`
final class RevenueCatPurchaseService implements IPurchaseService {
  RevenueCatPurchaseService();

  static const String _androidKey =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY', defaultValue: '');
  static const String _iosKey =
      String.fromEnvironment('REVENUECAT_IOS_KEY', defaultValue: '');

  final ValueNotifier<String?> _activeTier = ValueNotifier<String?>(null);
  bool _configured = false;

  /// Whether RevenueCat can run on this platform with a key present.
  /// When false, the factory falls back to the sandbox service.
  static bool get isSupported {
    if (Platform.isAndroid) return _androidKey.isNotEmpty;
    if (Platform.isIOS || Platform.isMacOS) return _iosKey.isNotEmpty;
    return false;
  }

  /// Store package identifier convention: `<tierId>_<cycle>`,
  /// e.g. `sentinel_annual`.
  static String packageId(SubscriptionTier tier, BillingCycle cycle) =>
      '${tier.tierId.id}_${cycle.name}';

  @override
  Future<void> initialize() async {
    if (_configured) return;
    final apiKey = Platform.isAndroid ? _androidKey : _iosKey;
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
    await _syncEntitlement();
  }

  @override
  Future<List<SubscriptionTier>> getOfferings() async {
    // The static catalog drives the paywall UI; RevenueCat packages are
    // resolved at purchase time by identifier.
    await Purchases.getOfferings();
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

    final offerings = await Purchases.getOfferings();
    final expectedId = packageId(tier, cycle);

    Package? target;
    for (final offering in offerings.all.values) {
      for (final package in offering.availablePackages) {
        if (package.identifier == expectedId ||
            package.storeProduct.identifier == expectedId) {
          target = package;
          break;
        }
      }
    }
    if (target == null) {
      throw PurchaseServiceException(
        'Store package "$expectedId" is not configured.',
      );
    }

    try {
      final info = await Purchases.purchasePackage(target);
      await _syncEntitlement(info);
      return _activeTier.value == tier.tierId.id ? tier : null;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return null; // user cancelled — not an error
      }
      throw PurchaseServiceException(
        e.message ?? 'Purchase failed. Please try again.',
      );
    }
  }

  @override
  Future<SubscriptionTier?> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    await _syncEntitlement(info);
    return SubscriptionTiers.byId(_activeTier.value);
  }

  Future<void> _syncEntitlement([CustomerInfo? info]) async {
    final customerInfo = info ?? await Purchases.getCustomerInfo();
    final active = customerInfo.entitlements.active.keys;
    // Family Vault supersedes Sentinel when both are active.
    _activeTier.value = active.contains(TierId.familyVault.id)
        ? TierId.familyVault.id
        : active.contains(TierId.sentinel.id)
            ? TierId.sentinel.id
            : null;
  }

  @override
  String? get activeTierId => _activeTier.value;

  @override
  ValueListenable<String?> get activeTier => _activeTier;
}
