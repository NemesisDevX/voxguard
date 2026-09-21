import 'dart:io';

import 'package:flutter/foundation.dart';

import 'i_purchase_service.dart';
import 'mock_sandbox_purchase_service.dart';
import 'revenuecat_purchase_service.dart';
import 'unavailable_purchase_service.dart';

/// IO platforms (Android/iOS/macOS/Windows/Linux).
///
/// Resolution order:
/// - Android/iOS/macOS + RevenueCat public key → real store backend.
/// - Android/iOS/macOS release build WITHOUT a key → *unavailable*
///   backend. Never the demo store — a production-style build must
///   not let a user "activate" a fake paid plan.
/// - Everything else (Windows/Linux, store-platform debug builds
///   without a key) → clearly labelled Demo Store.
IPurchaseService createPurchaseService() => createPurchaseServiceFor(
      isMobileStorePlatform:
          Platform.isAndroid || Platform.isIOS || Platform.isMacOS,
      hasRevenueCatKey: RevenueCatPurchaseService.isSupported,
      isReleaseBuild: kReleaseMode,
    );

/// Pure decision function — kept separate so tests can pin every
/// combination without platform channels.
@visibleForTesting
IPurchaseService createPurchaseServiceFor({
  required bool isMobileStorePlatform,
  required bool hasRevenueCatKey,
  required bool isReleaseBuild,
}) {
  if (isMobileStorePlatform && hasRevenueCatKey) {
    return RevenueCatPurchaseService();
  }
  if (isMobileStorePlatform && isReleaseBuild) {
    return UnavailablePurchaseService();
  }
  return MockSandboxPurchaseService();
}
