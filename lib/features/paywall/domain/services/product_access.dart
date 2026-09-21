import 'package:flutter/foundation.dart';

import '../models/entitlement_state.dart';
import '../models/subscription_tier.dart';
import 'i_purchase_service.dart';
import 'purchase_service_locator.dart';

/// What the active plan actually unlocks — derived from
/// [EntitlementState.tier] in exactly one place so tier checks never
/// scatter across widgets.
///
/// These are product-access capabilities, not infrastructure truth:
/// e.g. `liveCloudTranscription` being true still requires the
/// transcription backend to be configured. Paid status can never
/// manufacture missing provider configuration.
final class ProductCapabilities {
  const ProductCapabilities(this.tier);

  final TierId tier;

  /// Live Mic automatic cloud transcription + transcript-backed
  /// conversation-risk analysis. Sentinel and above.
  bool get liveCloudTranscription => tier != TierId.free;

  /// Analyze Recording → provider transcription of the uploaded
  /// file. Sentinel and above. Local acoustic/manual-transcript
  /// analysis stays free.
  bool get enhancedRecording => tier != TierId.free;

  /// Real outbound Family Shield alerts to the local Trusted Circle.
  /// Family Vault only — Sentinel cannot send.
  bool get familyShieldOutbound => tier == TierId.familyVault;

  /// Free-forever surfaces — never gated by any tier:
  /// local acoustic analysis, manual transcript with local semantic
  /// analysis, incident history, Family Shield receiving/responding,
  /// and all demo/simulation paths.
}

/// The app's product-access read model. One reactive source of plan
/// truth ([entitlement]) plus a synchronous [capabilities] snapshot
/// for feature-operation guards.
abstract interface class IProductAccess {
  /// Reactive plan truth — widgets listen to this to unlock without
  /// restart after a purchase/restore/expiration.
  ValueListenable<EntitlementState> get entitlement;

  /// Capabilities for the currently known entitlement state.
  ProductCapabilities get capabilities;
}

/// Default implementation — derives capabilities from the active
/// [IPurchaseService]'s entitlement stream.
final class ProductAccess implements IProductAccess {
  ProductAccess(this._service);

  final IPurchaseService _service;

  @override
  ValueListenable<EntitlementState> get entitlement => _service.entitlement;

  @override
  ProductCapabilities get capabilities =>
      ProductCapabilities(_service.entitlement.value.tier);
}

/// Process-wide accessor mirroring [PurchaseServiceLocator] — the
/// rest of the app asks this, never RevenueCat directly.
final class ProductAccessLocator {
  ProductAccessLocator._();

  static IProductAccess? _instance;

  static IProductAccess get instance =>
      _instance ??= ProductAccess(PurchaseServiceLocator.instance);

  /// Test hook — inject a fake access layer (or a fake purchase
  /// service into [PurchaseServiceLocator]) before widgets resolve it.
  @visibleForTesting
  static set instance(IProductAccess? access) => _instance = access;

  /// Test hook — clear the cached instance.
  @visibleForTesting
  static void reset() => _instance = null;
}
