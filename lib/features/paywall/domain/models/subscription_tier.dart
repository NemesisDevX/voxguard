import 'package:equatable/equatable.dart';

import 'billing_cycle.dart';

/// Store-facing product identifier for each plan.
enum TierId {
  free('free'),
  sentinel('sentinel'),
  familyVault('family_vault');

  const TierId(this.id);

  /// Raw entitlement/product id used by the purchase service.
  final String id;

  static TierId? fromId(String id) {
    for (final t in TierId.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Immutable subscription plan definition shown on the paywall.
final class SubscriptionTier extends Equatable {
  const SubscriptionTier({
    required this.tierId,
    required this.name,
    required this.subtitle,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.discountLabel,
    required this.features,
    this.isPopular = false,
  });

  final TierId tierId;
  final String name;
  final String subtitle;
  final double monthlyPrice;
  final double annualPrice;

  /// e.g. "SAVE 35%" — empty string for the free tier.
  final String discountLabel;

  /// Marketing bullet points rendered with checkmarks.
  final List<String> features;

  /// Whether this tier gets the highlight border / "MOST POPULAR" chip.
  final bool isPopular;

  bool get isFree => tierId == TierId.free;

  /// Raw price for the selected billing cycle.
  double priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.monthly ? monthlyPrice : annualPrice;

  /// Human-readable price label, e.g. `$9.99/mo`.
  String priceLabel(BillingCycle cycle) {
    if (isFree) return r'$0';
    return '\$${priceFor(cycle).toStringAsFixed(2)}${cycle.priceSuffix}';
  }

  @override
  List<Object?> get props => [tierId];
}

/// Static plan catalog — acts as the offering fallback when the store
/// is unreachable or running on a non-store platform.
abstract final class SubscriptionTiers {
  SubscriptionTiers._();

  static const SubscriptionTier free = SubscriptionTier(
    tierId: TierId.free,
    name: 'Quick Check',
    subtitle: 'Essential protection to try VoxGuard',
    monthlyPrice: 0,
    annualPrice: 0,
    discountLabel: '',
    features: [
      '5 call analyses per month',
      'Standard acoustic voice check',
      'Basic incident log',
    ],
  );

  static const SubscriptionTier sentinel = SubscriptionTier(
    tierId: TierId.sentinel,
    name: 'Sentinel Shield',
    subtitle: 'Full dual-engine defense for you',
    monthlyPrice: 9.99,
    annualPrice: 79.99,
    discountLabel: 'SAVE 35%',
    isPopular: true,
    features: [
      'Unlimited SafeCall & Live Shield',
      'Dual-engine threat fusion',
      'Synthetic voice detection',
      'Incident reports export',
      'Priority protection updates',
    ],
  );

  static const SubscriptionTier familyVault = SubscriptionTier(
    tierId: TierId.familyVault,
    name: 'Family Vault',
    subtitle: 'Whole-household scam defense',
    monthlyPrice: 19.99,
    annualPrice: 149.99,
    discountLabel: 'SAVE 38%',
    features: [
      'Everything in Sentinel Shield',
      'Up to 5 protected devices',
      'Family Shield emergency broadcast',
      'Shared family threat log',
    ],
  );

  static const List<SubscriptionTier> catalog = [free, sentinel, familyVault];

  static SubscriptionTier? byId(String? tierId) {
    if (tierId == null) return null;
    final id = TierId.fromId(tierId);
    if (id == null) return null;
    return catalog.firstWhere((t) => t.tierId == id);
  }
}
