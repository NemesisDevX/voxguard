// Conditional factory export — resolves [createPurchaseService] to the
// IO implementation (RevenueCat on store platforms, sandbox elsewhere)
// or the pure-Dart stub (Web), so `purchases_flutter` is never
// compiled into unsupported targets.
export 'purchase_service_factory_stub.dart'
    if (dart.library.io) 'purchase_service_factory_io.dart';
