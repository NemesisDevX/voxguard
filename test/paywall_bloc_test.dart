import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/features/paywall/domain/models/billing_cycle.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'package:voxguard/features/paywall/domain/services/mock_sandbox_purchase_service.dart';
import 'package:voxguard/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:voxguard/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:voxguard/features/paywall/presentation/bloc/paywall_state.dart';

void main() {
  late MockSandboxPurchaseService service;
  late PaywallBloc bloc;

  setUp(() {
    service = MockSandboxPurchaseService(
      networkDelay: Duration.zero,
      checkoutDelay: Duration.zero,
    );
    bloc = PaywallBloc(purchaseService: service);
  });

  tearDown(() => bloc.close());

  Future<PaywallLoaded> load() async {
    bloc.add(const LoadOfferingsEvent());
    final s = await bloc.stream.firstWhere((s) => s is PaywallLoaded);
    return s as PaywallLoaded;
  }

  group('PaywallBloc', () {
    test('loads catalog and preselects the popular tier on annual', () async {
      final loaded = await load();

      expect(loaded.tiers, hasLength(3));
      expect(loaded.selectedTier.tierId, TierId.sentinel);
      expect(loaded.cycle, BillingCycle.annual);
      expect(loaded.isPurchasing, isFalse);
    });

    test('switches billing cycle', () async {
      await load();
      bloc.add(const SelectBillingCycleEvent(BillingCycle.monthly));

      final s = await bloc.stream.firstWhere(
        (s) => s is PaywallLoaded && s.cycle == BillingCycle.monthly,
      );
      expect((s as PaywallLoaded).cycle, BillingCycle.monthly);
    });

    test('selects a different tier', () async {
      await load();
      bloc.add(const SelectTierEvent(SubscriptionTiers.familyVault));

      final s = await bloc.stream.firstWhere(
        (s) =>
            s is PaywallLoaded &&
            s.selectedTier.tierId == TierId.familyVault,
      );
      expect((s as PaywallLoaded).selectedTier.name, 'Family Vault');
    });

    test('completes a purchase and activates the entitlement', () async {
      await load();
      bloc.add(
        const PurchaseTierEvent(
          SubscriptionTiers.sentinel,
          BillingCycle.annual,
        ),
      );

      final s = await bloc.stream
          .firstWhere((s) => s is PaywallPurchaseSuccess);
      expect(
        (s as PaywallPurchaseSuccess).purchasedTier.tierId,
        TierId.sentinel,
      );
      expect(service.activeTierId, 'sentinel');
    });

    test('free tier activates instantly without checkout', () async {
      await load();
      bloc.add(
        const PurchaseTierEvent(
          SubscriptionTiers.free,
          BillingCycle.monthly,
        ),
      );

      final s = await bloc.stream
          .firstWhere((s) => s is PaywallPurchaseSuccess);
      expect(
        (s as PaywallPurchaseSuccess).purchasedTier.tierId,
        TierId.free,
      );
    });

    test('restore returns the previously purchased tier', () async {
      await service.initialize();
      await service.purchaseTier(
        SubscriptionTiers.familyVault,
        BillingCycle.monthly,
      );

      await load();
      bloc.add(const RestorePurchasesEvent());

      final s = await bloc.stream
          .firstWhere((s) => s is PaywallPurchaseSuccess);
      expect(
        (s as PaywallPurchaseSuccess).purchasedTier.tierId,
        TierId.familyVault,
      );
    });

    test('restore with no purchases emits an error', () async {
      await load();
      bloc.add(const RestorePurchasesEvent());

      final s =
          await bloc.stream.firstWhere((s) => s is PaywallError);
      expect(
        (s as PaywallError).errorMessage,
        contains('No previous purchases'),
      );
    });

    test('purchase failure surfaces PaywallError', () async {
      final failing = MockSandboxPurchaseService(
        networkDelay: Duration.zero,
        checkoutDelay: Duration.zero,
        shouldFailPurchases: true,
      );
      final failingBloc = PaywallBloc(purchaseService: failing);
      addTearDown(failingBloc.close);

      failingBloc.add(const LoadOfferingsEvent());
      await failingBloc.stream.firstWhere((s) => s is PaywallLoaded);
      failingBloc.add(
        const PurchaseTierEvent(
          SubscriptionTiers.sentinel,
          BillingCycle.monthly,
        ),
      );

      final s = await failingBloc.stream
          .firstWhere((s) => s is PaywallError);
      expect((s as PaywallError).errorMessage, isNotEmpty);
    });
  });
}
