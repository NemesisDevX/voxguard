import 'i_purchase_service.dart';
import 'mock_sandbox_purchase_service.dart';
import 'revenuecat_purchase_service.dart';

/// IO platforms (Android/iOS/macOS/Windows/Linux).
///
/// RevenueCat is used only when the platform has a store runtime and a
/// configured API key; everything else — Windows/Linux desktop and
/// keyless debug sessions — runs on the sandbox service so the full
/// lifecycle remains testable.
IPurchaseService createPurchaseService() {
  if (RevenueCatPurchaseService.isSupported) {
    return RevenueCatPurchaseService();
  }
  return MockSandboxPurchaseService();
}
