import 'package:equatable/equatable.dart';

import '../../domain/models/billing_cycle.dart';
import '../../domain/models/subscription_tier.dart';

/// Events for the paywall flow.
sealed class PaywallEvent extends Equatable {
  const PaywallEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch offerings and build the initial view-model.
final class LoadOfferingsEvent extends PaywallEvent {
  const LoadOfferingsEvent();
}

/// Toggle Monthly ↔ Annual.
final class SelectBillingCycleEvent extends PaywallEvent {
  const SelectBillingCycleEvent(this.cycle);

  final BillingCycle cycle;

  @override
  List<Object?> get props => [cycle];
}

/// Highlight a tier card.
final class SelectTierEvent extends PaywallEvent {
  const SelectTierEvent(this.tier);

  final SubscriptionTier tier;

  @override
  List<Object?> get props => [tier];
}

/// Execute checkout for the given tier/cycle combination.
final class PurchaseTierEvent extends PaywallEvent {
  const PurchaseTierEvent(this.tier, this.cycle);

  final SubscriptionTier tier;
  final BillingCycle cycle;

  @override
  List<Object?> get props => [tier, cycle];
}

/// Restore previously purchased entitlements.
final class RestorePurchasesEvent extends PaywallEvent {
  const RestorePurchasesEvent();
}
