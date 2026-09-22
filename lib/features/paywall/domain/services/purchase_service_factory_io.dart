import 'package:flutter/foundation.dart';

import 'i_purchase_service.dart';
import 'mock_sandbox_purchase_service.dart';
import 'revenuecat_purchase_service.dart';
import 'unavailable_purchase_service.dart';

/// IO platforms (Android/iOS/macOS/Windows/Linux).
///
/// Real-store purchasing for this release is scoped to Android and
/// iOS ONLY — the only platforms with configured RevenueCat apps and
/// validated store flows.
///
/// Resolution order on Android/iOS:
/// - Platform store key present → real store backend. Authoritative
///   whenever configured, in every build mode.
/// - RELEASE build without a platform key → *unavailable* backend.
///   A `REVENUECAT_TEST_STORE_KEY` alone must NEVER enable the Test
///   Store in release, and a production-style build must not let a
///   user "activate" a fake paid plan.
/// - NON-release build + `REVENUECAT_TEST_STORE_KEY` → RevenueCat
///   Test Store backend: the real SDK, RevenueCat-hosted test
///   transactions, CustomerInfo-derived entitlements — the judging
///   path for Shipaton Next Gen.
/// - Everything else (macOS/Windows/Linux, store-platform debug
///   builds without any key) → clearly labelled Demo Store.
IPurchaseService createPurchaseService() => createPurchaseServiceFor(
      platform: defaultTargetPlatform,
      hasRevenueCatKey: RevenueCatPurchaseService.isSupported,
      hasRevenueCatTestStoreKey:
          RevenueCatPurchaseService.isTestStoreSupported,
      isReleaseBuild: kReleaseMode,
    );

/// Pure decision function — kept separate so tests can pin every
/// platform/build combination without platform channels.
@visibleForTesting
IPurchaseService createPurchaseServiceFor({
  required TargetPlatform platform,
  required bool hasRevenueCatKey,
  required bool isReleaseBuild,
  bool hasRevenueCatTestStoreKey = false,
}) {
  // Real billing ships on Android + iOS only. macOS intentionally
  // falls through to the Demo Store this release — its store path is
  // unconfigured and unvalidated.
  final isStorePlatform = platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;
  if (isStorePlatform && hasRevenueCatKey) {
    return RevenueCatPurchaseService();
  }
  if (isStorePlatform && isReleaseBuild) {
    return UnavailablePurchaseService();
  }
  if (isStorePlatform && hasRevenueCatTestStoreKey) {
    return RevenueCatPurchaseService.testStore();
  }
  return MockSandboxPurchaseService();
}
