import 'i_purchase_service.dart';
import 'mock_sandbox_purchase_service.dart';

/// Non-IO platforms (Web) — RevenueCat native billing is unavailable,
/// so the clearly-labelled Demo Store takes over transparently.
IPurchaseService createPurchaseService() => MockSandboxPurchaseService();
