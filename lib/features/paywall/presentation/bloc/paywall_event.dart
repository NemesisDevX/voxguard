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
/// [preselect] opens the paywall with a specific plan highlighted —
/// e.g. Sentinel from the Live Mic upsell, Family Vault from the
/// Family Shield gate.
final class LoadOfferingsEvent extends PaywallEvent {
  const LoadOfferingsEvent({this.preselect});

  final TierId? preselect;

  @override
  List<Object?> get props => [preselect];
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

/// Execute checkout for the currently selected tier/cycle. The bloc
/// resolves the actual [StorePackage] from the loaded offering — the
/// UI never picks raw packages.
final class PurchaseSelectedEvent extends PaywallEvent {
  const PurchaseSelectedEvent();
}

/// Restore previously purchased entitlements.
final class RestorePurchasesEvent extends PaywallEvent {
  const RestorePurchasesEvent();
}
