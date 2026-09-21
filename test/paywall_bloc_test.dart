import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/features/paywall/domain/models/billing_cycle.dart';
import 'package:voxguard/features/paywall/domain/models/entitlement_state.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'package:voxguard/features/paywall/domain/services/i_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/mock_sandbox_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/unavailable_purchase_service.dart';
import 'package:voxguard/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:voxguard/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:voxguard/features/paywall/presentation/bloc/paywall_state.dart';

/// Generic fake backend — lets tests pin backend mode, package list,
/// and purchase outcome without a real store or the demo delays.
final class _FakePurchaseService implements IPurchaseService {
  _FakePurchaseService({
    this.backend = PurchaseBackendMode.demoStore,
    this.packages = const [],
    this.outcome,
    this.restoreTier,
    this.throwsOnInit = false,
    this.throwsOnPackages = false,
  });

  final PurchaseBackendMode backend;
  final List<StorePackage> packages;
  final PurchaseOutcome? outcome;
  final TierId? restoreTier;
  final bool throwsOnInit;
  final bool throwsOnPackages;

  final _entitlement = ValueNotifier<EntitlementState>(
    const EntitlementState(status: EntitlementStatus.ready),
  );
  int purchaseCalls = 0;

  @override
  ValueListenable<EntitlementState> get entitlement => _entitlement;

  @override
  PurchaseBackendMode get backendMode => backend;

  @override
  Future<void> initialize() async {
    if (throwsOnInit) {
      throw const PurchaseServiceException(
          'Subscriptions could not be initialized.');
    }
    _entitlement.value = _entitlement.value.copyWith(backend: backend);
  }

  @override
  Future<List<StorePackage>> getPackages() async {
    if (throwsOnPackages) {
      throw const PurchaseServiceException(
          'Plans could not be loaded from the store.');
    }
    return packages;
  }

  @override
  Future<PurchaseOutcome> purchasePackage(StorePackage package) async {
    purchaseCalls++;
    final o = outcome;
    if (o == null) {
      _entitlement.value = _entitlement.value.copyWith(
          tier: package.tierId, status: EntitlementStatus.ready);
      return PurchaseOutcome.activated(package.tierId);
    }
    return o;
  }

  @override
  Future<TierId?> restorePurchases() async {
    final t = restoreTier;
    if (t != null) {
      _entitlement.value =
          _entitlement.value.copyWith(tier: t);
    }
    return t;
  }
}

StorePackage _pkg(
  String id,
  TierId tier,
  BillingCycle cycle, {
  String price = r'$9.99',
}) =>
    StorePackage(
      identifier: id,
      tierId: tier,
      cycle: cycle,
      priceString: price,
      title: id,
    );



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

  Future<PaywallLoaded> load([PaywallBloc? b]) async {
    final target = b ?? bloc;
    target.add(const LoadOfferingsEvent());
    final s =
        await target.stream.firstWhere((s) => s is PaywallLoaded);
    return s as PaywallLoaded;
  }

  group('PaywallBloc — demo backend', () {
    test('loads catalog, preselects popular tier on annual, '
        'marks backend demoStore', () async {
      final loaded = await load();

      expect(loaded.backend, PurchaseBackendMode.demoStore);
      expect(loaded.tiers, hasLength(3));
      expect(loaded.selectedTier.tierId, TierId.sentinel);
      expect(loaded.cycle, BillingCycle.annual);
      expect(loaded.isPurchasing, isFalse);
      // Every paid tier has both cycles in the demo offering.
      expect(loaded.packages[TierId.sentinel], hasLength(2));
      expect(loaded.packages[TierId.familyVault], hasLength(2));
      expect(loaded.selectedPackage?.priceString, r'$79.99');
    });

    test('preselects a caller-provided tier', () async {
      bloc.add(const LoadOfferingsEvent(preselect: TierId.familyVault));
      final s = await bloc.stream.firstWhere((s) => s is PaywallLoaded);
      expect((s as PaywallLoaded).selectedTier.tierId,
          TierId.familyVault);
    });

    test('switches billing cycle', () async {
      await load();
      bloc.add(const SelectBillingCycleEvent(BillingCycle.monthly));

      final s = await bloc.stream.firstWhere(
        (s) => s is PaywallLoaded && s.cycle == BillingCycle.monthly,
      );
      expect((s as PaywallLoaded).cycle, BillingCycle.monthly);
    });

    test('purchase activates entitlement and marks the result demo',
        () async {
      await load();
      bloc.add(const PurchaseSelectedEvent());

      final s = await bloc.stream
          .firstWhere((s) => s is PaywallPurchaseSuccess);
      expect((s as PaywallPurchaseSuccess).tier, TierId.sentinel);
      expect(s.demo, isTrue);
      expect(service.entitlement.value.tier, TierId.sentinel);
    });

    test('cancelled purchase returns to the interactive paywall — '
        'not an error', () async {
      final cancelling = MockSandboxPurchaseService(
        networkDelay: Duration.zero,
        checkoutDelay: Duration.zero,
        simulateCancellation: true,
      );
      final b = PaywallBloc(purchaseService: cancelling);
      addTearDown(b.close);
      await load(b);

      b.add(const PurchaseSelectedEvent());
      final s = await b.stream.firstWhere(
        (s) => s is PaywallLoaded && !s.isPurchasing,
      );
      expect((s as PaywallLoaded).isPurchasing, isFalse);
      expect(s.notice, isNull);
      expect(cancelling.entitlement.value.tier, TierId.free);
    });

    test('free selection performs no purchase and emits no success',
        () async {
      await load();
      bloc.add(const SelectTierEvent(SubscriptionTiers.free));
      await bloc.stream.firstWhere(
        (s) =>
            s is PaywallLoaded &&
            s.selectedTier.tierId == TierId.free,
      );
      bloc.add(const PurchaseSelectedEvent());
      // Give the bloc a beat — free is not a transaction.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.entitlement.value.tier, TierId.free);
    });

    test('restore returns the previously purchased tier', () async {
      await service.initialize();
      final pkg = (await service.getPackages())
          .firstWhere((p) => p.identifier == 'family_vault_monthly');
      await service.purchasePackage(pkg);

      await load();
      bloc.add(const RestorePurchasesEvent());

      final s = await bloc.stream
          .firstWhere((s) => s is PaywallPurchaseSuccess);
      expect((s as PaywallPurchaseSuccess).tier, TierId.familyVault);
    });

    test('restore with no purchases shows an inline notice, not an '
        'error screen', () async {
      await load();
      bloc.add(const RestorePurchasesEvent());

      final s = await bloc.stream.firstWhere(
        (s) => s is PaywallLoaded && s.notice != null,
      );
      expect((s as PaywallLoaded).notice, 'No active purchases found.');
    });

    test('purchase failure surfaces an inline notice — paywall stays '
        'usable', () async {
      final failing = MockSandboxPurchaseService(
        networkDelay: Duration.zero,
        checkoutDelay: Duration.zero,
        shouldFailPurchases: true,
      );
      final b = PaywallBloc(purchaseService: failing);
      addTearDown(b.close);
      await load(b);

      b.add(const PurchaseSelectedEvent());
      final s = await b.stream.firstWhere(
        (s) => s is PaywallLoaded && s.notice != null,
      );
      expect((s as PaywallLoaded).notice, isNotEmpty);
      expect(s.isPurchasing, isFalse);
    });
  });

  group('PaywallBloc — store truth', () {
    test('unavailable backend renders free only with the '
        'not-configured notice', () async {
      final b = PaywallBloc(
          purchaseService: UnavailablePurchaseService());
      addTearDown(b.close);
      final s = await load(b);

      expect(s.backend, PurchaseBackendMode.unavailable);
      expect(s.tiers, hasLength(1));
      expect(s.tiers.single.isFree, isTrue);
      expect(s.notice, "Subscriptions aren't configured in this build.");
      expect(s.availableCycles, isEmpty);
    });

    test('missing packages are never fabricated — absent tiers/cycles '
        'do not render', () async {
      final fake = _FakePurchaseService(
        backend: PurchaseBackendMode.realStore,
        packages: [
          _pkg('sentinel_monthly', TierId.sentinel,
              BillingCycle.monthly),
        ],
      );
      final b = PaywallBloc(purchaseService: fake);
      addTearDown(b.close);
      final s = await load(b);

      // Family Vault has no package — it must not render.
      expect(s.tiers.map((t) => t.tierId),
          [TierId.free, TierId.sentinel]);
      // Sentinel only offers monthly — annual must not appear.
      expect(s.availableCycles, [BillingCycle.monthly]);
      expect(s.cycle, BillingCycle.monthly);
      expect(s.selectedPackage?.priceString, r'$9.99');
    });

    test('empty current offering keeps free plan usable with a '
        'truthful notice', () async {
      final fake = _FakePurchaseService(
        backend: PurchaseBackendMode.realStore,
        packages: const [],
      );
      final b = PaywallBloc(purchaseService: fake);
      addTearDown(b.close);
      final s = await load(b);

      expect(s.tiers, hasLength(1));
      expect(s.tiers.single.isFree, isTrue);
      expect(s.notice, isNotNull);
    });

    test('purchase that returns without entitlement does not '
        'activate a plan', () async {
      final fake = _FakePurchaseService(
        backend: PurchaseBackendMode.realStore,
        packages: [
          _pkg('sentinel_monthly', TierId.sentinel,
              BillingCycle.monthly),
        ],
        outcome: PurchaseOutcome.notActivated,
      );
      final b = PaywallBloc(purchaseService: fake);
      addTearDown(b.close);
      await load(b);

      // Select Sentinel (default is popular sentinel anyway).
      b.add(const PurchaseSelectedEvent());
      final s = await b.stream.firstWhere(
        (s) => s is PaywallLoaded && s.notice != null,
      );
      expect((s as PaywallLoaded).notice,
          contains('did not activate'));
      expect(fake.entitlement.value.tier, TierId.free);
    });

    test('init failure is the only unrecoverable error', () async {
      final fake = _FakePurchaseService(throwsOnInit: true);
      final b = PaywallBloc(purchaseService: fake);
      addTearDown(b.close);
      b.add(const LoadOfferingsEvent());
      final s = await b.stream.firstWhere((s) => s is PaywallError);
      expect((s as PaywallError).errorMessage,
          'Subscriptions could not be initialized.');
    });

    test('offerings fetch failure is an unrecoverable error', () async {
      final fake = _FakePurchaseService(
        backend: PurchaseBackendMode.realStore,
        throwsOnPackages: true,
      );
      final b = PaywallBloc(purchaseService: fake);
      addTearDown(b.close);
      b.add(const LoadOfferingsEvent());
      final s = await b.stream.firstWhere((s) => s is PaywallError);
      expect((s as PaywallError).errorMessage,
          'Plans could not be loaded from the store.');
    });

    test('restore of a paid entitlement emits success and updates '
        'entitlement state', () async {
      final fake = _FakePurchaseService(
        backend: PurchaseBackendMode.realStore,
        packages: [
          _pkg('sentinel_monthly', TierId.sentinel,
              BillingCycle.monthly),
        ],
        restoreTier: TierId.sentinel,
      );
      final b = PaywallBloc(purchaseService: fake);
      addTearDown(b.close);
      await load(b);

      b.add(const RestorePurchasesEvent());
      final s = await b.stream
          .firstWhere((s) => s is PaywallPurchaseSuccess);
      expect((s as PaywallPurchaseSuccess).tier, TierId.sentinel);
      expect(fake.entitlement.value.tier, TierId.sentinel);
    });
  });
}
