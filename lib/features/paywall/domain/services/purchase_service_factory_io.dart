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
/// Resolution order:
/// - Android/iOS + RevenueCat public key → real store backend.
/// - Android/iOS release build WITHOUT a key → *unavailable*
///   backend. Never the demo store — a production-style build must
///   not let a user "activate" a fake paid plan.
/// - Everything else (macOS/Windows/Linux, store-platform debug
///   builds without a key) → clearly labelled Demo Store.
IPurchaseService createPurchaseService() => createPurchaseServiceFor(
      platform: defaultTargetPlatform,
      hasRevenueCatKey: RevenueCatPurchaseService.isSupported,
      isReleaseBuild: kReleaseMode,
    );

/// Pure decision function — kept separate so tests can pin every
/// platform/build combination without platform channels.
@visibleForTesting
IPurchaseService createPurchaseServiceFor({
  required TargetPlatform platform,
  required bool hasRevenueCatKey,
  required bool isReleaseBuild,
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
  return MockSandboxPurchaseService();
}
