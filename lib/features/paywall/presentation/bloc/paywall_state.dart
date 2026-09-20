import 'package:equatable/equatable.dart';

import '../../domain/models/billing_cycle.dart';
import '../../domain/models/subscription_tier.dart';

/// States for the paywall flow.
sealed class PaywallState extends Equatable {
  const PaywallState();

  @override
  List<Object?> get props => [];
}

/// Fetching offerings.
final class PaywallLoading extends PaywallState {
  const PaywallLoading();
}

/// Offerings ready — the interactive paywall.
final class PaywallLoaded extends PaywallState {
  const PaywallLoaded({
    required this.tiers,
    required this.selectedTier,
    required this.cycle,
    this.isPurchasing = false,
  });

  final List<SubscriptionTier> tiers;
  final SubscriptionTier selectedTier;
  final BillingCycle cycle;

  /// True while a checkout/restore is in-flight — drives the CTA
  /// loading spinner and disables further taps.
  final bool isPurchasing;

  PaywallLoaded copyWith({
    List<SubscriptionTier>? tiers,
    SubscriptionTier? selectedTier,
    BillingCycle? cycle,
    bool? isPurchasing,
  }) {
    return PaywallLoaded(
      tiers: tiers ?? this.tiers,
      selectedTier: selectedTier ?? this.selectedTier,
      cycle: cycle ?? this.cycle,
      isPurchasing: isPurchasing ?? this.isPurchasing,
    );
  }

  @override
  List<Object?> get props => [tiers, selectedTier, cycle, isPurchasing];
}

/// A purchase/restore completed — UI should celebrate and dismiss.
final class PaywallPurchaseSuccess extends PaywallState {
  const PaywallPurchaseSuccess(this.purchasedTier);

  final SubscriptionTier purchasedTier;

  @override
  List<Object?> get props => [purchasedTier];
}

/// Unrecoverable paywall error (offerings fetch or checkout failure).
final class PaywallError extends PaywallState {
  const PaywallError(this.errorMessage);

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
