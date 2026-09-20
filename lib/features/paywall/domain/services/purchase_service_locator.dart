import 'package:flutter/foundation.dart';

import 'i_purchase_service.dart';
import 'purchase_service_factory.dart';

/// App-level accessor for the active [IPurchaseService].
///
/// Lazily resolves the platform implementation via the conditional
/// factory and keeps it as a process-wide singleton so entitlement
/// state (e.g. the plan badge on Home) stays consistent.
final class PurchaseServiceLocator {
  PurchaseServiceLocator._();

  static IPurchaseService? _instance;

  static IPurchaseService get instance =>
      _instance ??= createPurchaseService();

  /// Test hook — inject a fake service before the bloc/UI resolves it.
  @visibleForTesting
  static set instance(IPurchaseService service) => _instance = service;
}
