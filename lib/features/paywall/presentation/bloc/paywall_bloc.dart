import 'package:flutter_bloc/flutter_bloc.dart';


import '../../domain/models/billing_cycle.dart';
import '../../domain/models/entitlement_state.dart';
import '../../domain/models/subscription_tier.dart';
import '../../domain/services/i_purchase_service.dart';
import '../../domain/services/purchase_service_locator.dart';
import 'paywall_event.dart';
import 'paywall_state.dart';
import '../../../../core/l10n/l10n.dart';

/// Drives the paywall: initialize the backend, map the *current*
/// offering to purchasable options, run checkout and restores
/// against the active [IPurchaseService].
///
/// Truth rules enforced here:
/// - a paid tier is only purchasable when the store returned a real
///   package for it;
/// - user cancellation is silent, not an error;
/// - "nothing restored" / "not yet activated" are inline notices,
///   never unrecoverable error screens;
/// - the free tier never produces a purchase success.
final class PaywallBloc extends Bloc<PaywallEvent, PaywallState> {
  PaywallBloc({IPurchaseService? purchaseService})
      : _service = purchaseService ?? PurchaseServiceLocator.instance,
        super(const PaywallLoading()) {
    on<LoadOfferingsEvent>(_onLoad);
    on<SelectBillingCycleEvent>(_onSelectCycle);
    on<SelectTierEvent>(_onSelectTier);
    on<PurchaseSelectedEvent>(_onPurchase);
    on<RestorePurchasesEvent>(_onRestore);
  }

  final IPurchaseService _service;

  Future<void> _onLoad(
    LoadOfferingsEvent event,
    Emitter<PaywallState> emit,
  ) async {
    emit(const PaywallLoading());
    final backend = _service.backendMode;

    try {
      await _service.initialize();
    } on PurchaseServiceException catch (e) {
      emit(PaywallError(e.message));
      return;
    } on Exception {
      emit(PaywallError(l10n.plansLoadError));
      return;
    }

    // No store backend configured — free plan only, no checkout.
    if (backend == PurchaseBackendMode.unavailable) {
      emit(
        PaywallLoaded(
          backend: PurchaseBackendMode.unavailable,
          tiers: [SubscriptionTiers.free],
          packages: {},
          selectedTier: SubscriptionTiers.free,
          cycle: BillingCycle.monthly,
          notice: l10n.storeUnavailableNotice,
        ),
      );
      return;
    }

    final List<StorePackage> packages;
    try {
      packages = await _service.getPackages();
    } on PurchaseServiceException catch (e) {
      emit(PaywallError(e.message));
      return;
    } on Exception {
      emit(PaywallError(l10n.plansLoadError));
      return;
    }

    final byTier = <TierId, Map<BillingCycle, StorePackage>>{};
    for (final pkg in packages) {
      byTier.putIfAbsent(pkg.tierId, () => {})[pkg.cycle] = pkg;
    }

    // Render tiers that exist in the catalog AND (for paid tiers) in
    // the current offering. The free plan always renders.
    final tiers = SubscriptionTiers.catalog
        .where((t) => t.isFree || (byTier[t.tierId]?.isNotEmpty ?? false))
        .toList();

    final selected = tiers.firstWhere(
      (t) => t.tierId == event.preselect,
      orElse: () => tiers.firstWhere(
        (t) => t.isPopular,
        orElse: () => tiers.first,
      ),
    );

    // Prefer annual when the selected tier offers it.
    final cycles = byTier[selected.tierId] ?? const {};
    final cycle = cycles.containsKey(BillingCycle.annual)
        ? BillingCycle.annual
        : BillingCycle.monthly;

    emit(
      PaywallLoaded(
        backend: backend,
        tiers: tiers,
        packages: byTier,
        selectedTier: selected,
        cycle: cycle,
        notice: tiers.length == 1
            ? l10n.msgNoPaidPlans
            : null,
      ),
    );
  }

  void _onSelectCycle(
    SelectBillingCycleEvent event,
    Emitter<PaywallState> emit,
  ) {
    final s = state;
    // Only select a cycle the selected tier actually offers.
    if (s is PaywallLoaded && s.availableCycles.contains(event.cycle)) {
      emit(s.copyWith(cycle: event.cycle, clearNotice: true));
    }
  }

  void _onSelectTier(
    SelectTierEvent event,
    Emitter<PaywallState> emit,
  ) {
    final s = state;
    if (s is! PaywallLoaded) return;
    // Clamp the cycle if the newly selected tier doesn't offer it.
    final offers = s.packages[event.tier.tierId] ?? const {};
    final cycle = offers.containsKey(s.cycle)
        ? s.cycle
        : offers.containsKey(BillingCycle.annual)
            ? BillingCycle.annual
            : BillingCycle.monthly;
    emit(s.copyWith(selectedTier: event.tier, cycle: cycle, clearNotice: true));
  }

  Future<void> _onPurchase(
    PurchaseSelectedEvent event,
    Emitter<PaywallState> emit,
  ) async {
    final s = state;
    if (s is! PaywallLoaded || s.isPurchasing) return;

    // Free is never a store transaction.
    if (s.selectedTier.isFree) return;

    final package = s.selectedPackage;
    if (package == null) {
      emit(s.copyWith(notice: l10n.planNotAvailable));
      return;
    }

    emit(s.copyWith(isPurchasing: true, clearNotice: true));
    try {
      final outcome = await _service.purchasePackage(package);
      if (emit.isDone) return;
      final activated = outcome.tier;
      if (outcome.wasCancelled) {
        // User dismissed the sheet — back to the interactive paywall.
        emit(s.copyWith(isPurchasing: false));
      } else if (activated != null && activated != TierId.free) {
        emit(
          PaywallPurchaseSuccess(
            activated,
            demo: s.backend == PurchaseBackendMode.demoStore,
          ),
        );
      } else {
        emit(
          s.copyWith(
            isPurchasing: false,
            notice: l10n.msgPurchasePendingActivation,
          ),
        );
      }
    } on PurchaseServiceException catch (e) {
      emit(s.copyWith(isPurchasing: false, notice: e.message));
    } on Exception {
      emit(
        s.copyWith(
          isPurchasing: false,
          notice: l10n.msgPurchaseFailed,
        ),
      );
    }
  }

  Future<void> _onRestore(
    RestorePurchasesEvent event,
    Emitter<PaywallState> emit,
  ) async {
    final s = state;
    if (s is! PaywallLoaded || s.isPurchasing) return;

    emit(s.copyWith(isPurchasing: true, clearNotice: true));
    try {
      final restored = await _service.restorePurchases();
      if (emit.isDone) return;
      if (restored != null && restored != TierId.free) {
        emit(
          PaywallPurchaseSuccess(
            restored,
            demo: s.backend == PurchaseBackendMode.demoStore,
          ),
        );
      } else {
        emit(
          s.copyWith(
            isPurchasing: false,
            notice: l10n.noPurchasesRestored,
          ),
        );
      }
    } on PurchaseServiceException catch (e) {
      emit(s.copyWith(isPurchasing: false, notice: e.message));
    } on Exception {
      emit(
        s.copyWith(
          isPurchasing: false,
          notice: l10n.msgRestoreFailed,
        ),
      );
    }
  }
}
