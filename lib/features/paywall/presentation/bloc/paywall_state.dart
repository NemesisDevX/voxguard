import 'package:equatable/equatable.dart';

import '../../domain/models/billing_cycle.dart';
import '../../domain/models/entitlement_state.dart';
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

/// Offerings loaded — the interactive paywall.
///
/// [packages] maps tier → cycle → the actual store package; a paid
/// tier only renders purchasable when a package exists, and a cycle
/// pill only renders when the selected tier offers it. No package —
/// no fake price, no fake checkout.
final class PaywallLoaded extends PaywallState {
  const PaywallLoaded({
    required this.backend,
    required this.tiers,
    required this.packages,
    required this.selectedTier,
    required this.cycle,
    this.isPurchasing = false,
    this.notice,
  });

  /// realStore / demoStore / unavailable — drives truthful labelling.
  final PurchaseBackendMode backend;

  /// Tier display metadata actually renderable this session.
  final List<SubscriptionTier> tiers;

  /// Store packages keyed by tier, then cycle. Absent = not offered.
  final Map<TierId, Map<BillingCycle, StorePackage>> packages;

  final SubscriptionTier selectedTier;
  final BillingCycle cycle;

  /// True while a checkout/restore is in-flight — drives the CTA
  /// loading spinner and disables further taps.
  final bool isPurchasing;

  /// Transient consumer-safe inline message (e.g. "No active
  /// purchases found.", "Purchase did not activate a plan yet.").
  /// Never an unrecoverable error screen.
  final String? notice;

  /// Cycles the selected tier actually offers — drives the toggle.
  List<BillingCycle> get availableCycles =>
      BillingCycle.values
          .where((c) => packages[selectedTier.tierId]?[c] != null)
          .toList();

  /// The package the CTA would purchase for the selected tier —
  /// prefers the selected cycle, falls back to the tier's only
  /// offered cycle.
  StorePackage? get selectedPackage {
    final tierPackages = packages[selectedTier.tierId];
    if (tierPackages == null) return null;
    return tierPackages[cycle] ?? tierPackages.values.first;
  }

  PaywallLoaded copyWith({
    List<SubscriptionTier>? tiers,
    Map<TierId, Map<BillingCycle, StorePackage>>? packages,
    SubscriptionTier? selectedTier,
    BillingCycle? cycle,
    bool? isPurchasing,
    String? notice,
    bool clearNotice = false,
  }) {
    return PaywallLoaded(
      backend: backend,
      tiers: tiers ?? this.tiers,
      packages: packages ?? this.packages,
      selectedTier: selectedTier ?? this.selectedTier,
      cycle: cycle ?? this.cycle,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props =>
      [backend, tiers, packages, selectedTier, cycle, isPurchasing, notice];
}

/// A purchase/restore verified a paid entitlement — UI celebrates
/// and dismisses. [demo] distinguishes "Demo plan activated" from a
/// real subscription so the copy never lies.
final class PaywallPurchaseSuccess extends PaywallState {
  const PaywallPurchaseSuccess(this.tier, {this.demo = false});

  final TierId tier;
  final bool demo;

  @override
  List<Object?> get props => [tier, demo];
}

/// Unrecoverable load error — only for offerings/init failure, never
/// for purchase cancellation or "nothing to restore".
final class PaywallError extends PaywallState {
  const PaywallError(this.errorMessage);

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
