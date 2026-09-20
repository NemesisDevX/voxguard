import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/billing_cycle.dart';
import '../../domain/services/i_purchase_service.dart';
import '../../domain/services/purchase_service_locator.dart';
import 'paywall_event.dart';
import 'paywall_state.dart';

/// Drives the paywall: offerings load, tier/cycle selection, checkout
/// and restores against the active [IPurchaseService].
final class PaywallBloc extends Bloc<PaywallEvent, PaywallState> {
  PaywallBloc({IPurchaseService? purchaseService})
      : _service = purchaseService ?? PurchaseServiceLocator.instance,
        super(const PaywallLoading()) {
    on<LoadOfferingsEvent>(_onLoad);
    on<SelectBillingCycleEvent>(_onSelectCycle);
    on<SelectTierEvent>(_onSelectTier);
    on<PurchaseTierEvent>(_onPurchase);
    on<RestorePurchasesEvent>(_onRestore);
  }

  final IPurchaseService _service;

  Future<void> _onLoad(
    LoadOfferingsEvent event,
    Emitter<PaywallState> emit,
  ) async {
    emit(const PaywallLoading());
    try {
      await _service.initialize();
      final tiers = await _service.getOfferings();
      final selected = tiers.firstWhere(
        (t) => t.isPopular,
        orElse: () => tiers.first,
      );
      emit(
        PaywallLoaded(
          tiers: tiers,
          selectedTier: selected,
          cycle: BillingCycle.annual,
        ),
      );
    } on Exception catch (e) {
      emit(PaywallError('Could not load plans. ${e.toString()}'));
    }
  }

  void _onSelectCycle(
    SelectBillingCycleEvent event,
    Emitter<PaywallState> emit,
  ) {
    final s = state;
    if (s is PaywallLoaded) emit(s.copyWith(cycle: event.cycle));
  }

  void _onSelectTier(
    SelectTierEvent event,
    Emitter<PaywallState> emit,
  ) {
    final s = state;
    if (s is PaywallLoaded) emit(s.copyWith(selectedTier: event.tier));
  }

  Future<void> _onPurchase(
    PurchaseTierEvent event,
    Emitter<PaywallState> emit,
  ) async {
    final s = state;
    if (s is! PaywallLoaded || s.isPurchasing) return;

    // The free tier has no store checkout — activate instantly.
    if (event.tier.isFree) {
      emit(PaywallPurchaseSuccess(event.tier));
      return;
    }

    emit(s.copyWith(isPurchasing: true));
    try {
      final purchased =
          await _service.purchaseTier(event.tier, event.cycle);
      if (emit.isDone) return;
      if (purchased != null) {
        emit(PaywallPurchaseSuccess(purchased));
      } else {
        // User cancelled checkout — return to the interactive paywall.
        emit(s.copyWith(isPurchasing: false));
      }
    } on PurchaseServiceException catch (e) {
      emit(PaywallError(e.message));
    } on Exception catch (e) {
      emit(PaywallError('Purchase failed. ${e.toString()}'));
    }
  }

  Future<void> _onRestore(
    RestorePurchasesEvent event,
    Emitter<PaywallState> emit,
  ) async {
    final s = state;
    if (s is! PaywallLoaded || s.isPurchasing) return;

    emit(s.copyWith(isPurchasing: true));
    try {
      final restored = await _service.restorePurchases();
      if (emit.isDone) return;
      if (restored != null) {
        emit(PaywallPurchaseSuccess(restored));
      } else {
        emit(const PaywallError('No previous purchases found.'));
      }
    } on Exception catch (e) {
      emit(PaywallError('Restore failed. ${e.toString()}'));
    }
  }
}
