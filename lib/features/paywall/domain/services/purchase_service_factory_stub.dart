import 'i_purchase_service.dart';
import 'mock_sandbox_purchase_service.dart';

/// Non-IO platforms (Web) — RevenueCat is unavailable, so the sandbox
/// service takes over transparently.
IPurchaseService createPurchaseService() => MockSandboxPurchaseService();
