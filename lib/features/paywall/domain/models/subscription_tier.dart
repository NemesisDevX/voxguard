import 'package:equatable/equatable.dart';

/// Plan identifiers — these double as the RevenueCat entitlement ids
/// for paid tiers.
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

/// Display metadata for a plan — name, subtitle, and the features
/// VoxGuard genuinely implements and enforces.
///
/// This model intentionally carries NO prices: real prices come from
/// the store's current offering ([StorePackage.priceString]), and
/// inventing static numbers for the real backend would be false
/// pricing. Feature copy must never claim unimplemented behavior
/// (no quotas, Live Shield, device management, or shared cloud logs).
final class SubscriptionTier extends Equatable {
  const SubscriptionTier({
    required this.tierId,
    required this.name,
    required this.subtitle,
    required this.features,
    this.isPopular = false,
  });

  final TierId tierId;
  final String name;
  final String subtitle;

  /// Capability bullet points rendered with checkmarks — each must
  /// describe a real, enforced product behavior.
  final List<String> features;

  /// Whether this tier gets the highlight border / "MOST POPULAR" chip.
  final bool isPopular;

  bool get isFree => tierId == TierId.free;

  @override
  List<Object?> get props => [tierId];
}

/// The plan catalog — what VoxGuard actually does at each level.
abstract final class SubscriptionTiers {
  SubscriptionTiers._();

  /// Free — meaningful safety functionality, never crippled.
  /// Receiving and responding to Family Shield alerts is free
  /// forever: nobody pays to help protect a family member.
  static const SubscriptionTier free = SubscriptionTier(
    tierId: TierId.free,
    name: 'Quick Check',
    subtitle: 'Local safety tools',
    features: [
      'Live Mic acoustic anomaly monitoring',
      'On-device recording analysis',
      'Manual transcript check — analyzed locally',
      'Local incident history',
      'Receive & respond to Family Shield alerts',
    ],
  );

  /// Sentinel — adds transcript-backed conversation-risk analysis
  /// where transcription infrastructure is configured. The paid plan
  /// cannot manufacture missing provider configuration.
  static const SubscriptionTier sentinel = SubscriptionTier(
    tierId: TierId.sentinel,
    name: 'Sentinel Shield',
    subtitle: 'Conversation-aware protection',
    isPopular: true,
    features: [
      'Everything in Quick Check',
      'Automatic Live Mic transcription & enhanced recording '
          'transcription — when infrastructure is configured',
      'Transcript-backed conversation-risk analysis',
      'Fused multi-signal threat scoring',
    ],
  );

  /// Family Vault — Sentinel plus real outbound Family Shield alerts
  /// to the locally saved Trusted Circle. "5 people" are local
  /// contacts, not managed devices — VoxGuard has no household
  /// account system.
  static const SubscriptionTier familyVault = SubscriptionTier(
    tierId: TierId.familyVault,
    name: 'Family Vault',
    subtitle: 'The human verification loop',
    features: [
      'Everything in Sentinel Shield',
      'Send Family Shield alerts to your Trusted Circle',
      'Up to 5 locally-saved Trusted Circle contacts',
      'Safety responses loop back privately',
    ],
  );

  static const List<SubscriptionTier> catalog = [free, sentinel, familyVault];

  static SubscriptionTier? byId(TierId? id) {
    if (id == null) return null;
    for (final t in catalog) {
      if (t.tierId == id) return t;
    }
    return null;
  }
}
