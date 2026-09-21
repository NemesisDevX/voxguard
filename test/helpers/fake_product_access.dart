import 'package:flutter/foundation.dart';
import 'package:voxguard/features/paywall/domain/models/entitlement_state.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'package:voxguard/features/paywall/domain/services/product_access.dart';

/// Test double for [IProductAccess] — pins the plan without any store.
/// Mutate via [setTier] to exercise reactive unlock paths.
final class FakeProductAccess implements IProductAccess {
  FakeProductAccess([TierId tier = TierId.free])
      : _entitlement = ValueNotifier(
          EntitlementState(tier: tier, status: EntitlementStatus.ready),
        );

  final ValueNotifier<EntitlementState> _entitlement;

  @override
  ValueListenable<EntitlementState> get entitlement => _entitlement;

  @override
  ProductCapabilities get capabilities =>
      ProductCapabilities(_entitlement.value.tier);

  void setTier(TierId tier) =>
      _entitlement.value = _entitlement.value.copyWith(tier: tier);
}
