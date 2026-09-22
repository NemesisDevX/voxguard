import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:voxguard/features/paywall/domain/models/billing_cycle.dart';
import 'package:voxguard/features/paywall/domain/models/entitlement_state.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'package:voxguard/features/paywall/domain/services/i_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/revenuecat_purchase_service.dart';

/// Fake SDK adapter — no platform channel involved. Records calls so
/// lifecycle guarantees (single configure, single listener) are
/// testable.
final class _FakeAdapter implements IPurchasesAdapter {
  _FakeAdapter({CustomerInfo? initialInfo})
      : _info = initialInfo ?? _infoWith();

  bool configured = false;
  int configureCalls = 0;
  int listenerAdds = 0;
  CustomerInfoUpdateListener? listener;
  Offerings offerings = const Offerings({});
  Object? configureError;
  Object? offeringsError;
  Object? purchaseError;
  Object? restoreError;
  CustomerInfo? purchaseResultInfo;
  CustomerInfo? restoreResultInfo;
  Package? lastPurchasedPackage;

  final CustomerInfo _info;

  @override
  Future<bool> isConfigured() async => configured;

  @override
  Future<void> configure(String apiKey) async {
    configureCalls++;
    final e = configureError;
    if (e != null) throw e;
    configured = true;
  }

  @override
  void addCustomerInfoUpdateListener(
      CustomerInfoUpdateListener listener) {
    listenerAdds++;
    this.listener = listener;
  }

  @override
  Future<Offerings> getOfferings() async {
    final e = offeringsError;
    if (e != null) throw e;
    return offerings;
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async => _info;

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    lastPurchasedPackage = package;
    final e = purchaseError;
    if (e != null) throw e;
    return purchaseResultInfo ?? _info;
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    final e = restoreError;
    if (e != null) throw e;
    return restoreResultInfo ?? _info;
  }

  /// Simulates a CustomerInfo push from the SDK (renewal, expiration,
  /// cross-device sync).
  void pushCustomerInfo(CustomerInfo info) => listener?.call(info);
}

EntitlementInfo _entitlement(String id, {required bool active}) =>
    EntitlementInfo(
      id,
      active,
      true,
      '2026-09-01T00:00:00Z',
      '2026-09-01T00:00:00Z',
      'prod_$id',
      true,
    );

CustomerInfo _infoWith({
  Set<String> active = const {},
  String? managementUrl,
}) {
  final all = <String, EntitlementInfo>{
    'sentinel': _entitlement('sentinel', active: active.contains('sentinel')),
    'family_vault':
        _entitlement('family_vault', active: active.contains('family_vault')),
  };
  return CustomerInfo(
    EntitlementInfos(
      all,
      {for (final e in all.entries) if (e.value.isActive) e.key: e.value},
    ),
    const {},
    const [],
    const [],
    const [],
    '2026-09-01T00:00:00Z',
    'app_user',
    const {},
    '2026-09-21T00:00:00Z',
    managementURL: managementUrl,
  );
}

Package _rcPackage(String id, {String price = r'$9.99'}) => Package(
      id,
      PackageType.custom,
      StoreProduct(
        'store_$id',
        'desc',
        'Title $id',
        9.99,
        price,
        'USD',
      ),
      const PresentedOfferingContext('default', null, null),
    );

Offerings _offerings(List<Package> packages, {bool current = true}) =>
    Offerings(
      {
        'default': Offering(
          'default',
          'desc',
          const {},
          packages,
        ),
      },
      current: current
          ? Offering('default', 'desc', const {}, packages)
          : null,
    );

StorePackage _domainPackage(String id, TierId tier, BillingCycle cycle,
        {String price = r'$9.99'}) =>
    StorePackage(
      identifier: id,
      tierId: tier,
      cycle: cycle,
      priceString: price,
      title: id,
      nativeRef: _rcPackage(id, price: price),
    );

RevenueCatPurchaseService _svc(_FakeAdapter adapter,
        {String apiKey = 'test_key'}) =>
    RevenueCatPurchaseService(apiKey: apiKey, adapter: adapter);

void main() {
  group('RevenueCatPurchaseService — initialization', () {
    test('defaults to free until CustomerInfo says otherwise',
        () async {
      final adapter = _FakeAdapter();
      final svc = _svc(adapter);
      await svc.initialize();

      expect(adapter.configureCalls, 1);
      expect(adapter.listenerAdds, 1);
      expect(svc.entitlement.value.tier, TierId.free);
      expect(svc.entitlement.value.backend,
          PurchaseBackendMode.realStore);
      expect(svc.entitlement.value.status, EntitlementStatus.ready);
    });

    test('initialize is idempotent — single configure + single '
        'listener', () async {
      final adapter = _FakeAdapter();
      final svc = _svc(adapter);
      await svc.initialize();
      await svc.initialize();
      await svc.initialize();

      expect(adapter.configureCalls, 1);
      expect(adapter.listenerAdds, 1);
    });

    test('skips configure when the SDK is already configured', () async {
      final adapter = _FakeAdapter()..configured = true;
      final svc = _svc(adapter);
      await svc.initialize();

      expect(adapter.configureCalls, 0);
      expect(adapter.listenerAdds, 1);
    });

    test('empty api key fails truthfully — never grants paid access',
        () async {
      final adapter = _FakeAdapter();
      final svc = _svc(adapter, apiKey: '');

      await expectLater(svc.initialize(),
          throwsA(isA<PurchaseServiceException>()));
      expect(svc.entitlement.value.tier, TierId.free);
      expect(adapter.configureCalls, 0);
    });

    test('sdk failure maps to consumer-safe error, keeps free tier',
        () async {
      final adapter = _FakeAdapter()
        ..configureError = Exception('raw sdk internals boom');
      final svc = _svc(adapter);

      try {
        await svc.initialize();
        fail('expected throw');
      } on PurchaseServiceException catch (e) {
        expect(e.message, isNot(contains('boom')));
        expect(e.message, 'Subscriptions could not be initialized.');
      }
      expect(svc.entitlement.value.tier, TierId.free);
      expect(svc.entitlement.value.status, EntitlementStatus.error);
    });
  });

  group('RevenueCatPurchaseService — entitlement mapping', () {
    test('sentinel entitlement activates Sentinel', () async {
      final adapter = _FakeAdapter(
          initialInfo: _infoWith(active: {'sentinel'}));
      final svc = _svc(adapter);
      await svc.initialize();

      expect(svc.entitlement.value.tier, TierId.sentinel);
    });

    test('family_vault supersedes sentinel when both are active',
        () async {
      final adapter = _FakeAdapter(
          initialInfo: _infoWith(active: {'sentinel', 'family_vault'}));
      final svc = _svc(adapter);
      await svc.initialize();

      expect(svc.entitlement.value.tier, TierId.familyVault);
    });

    test('CustomerInfo listener updates entitlement reactively',
        () async {
      final adapter = _FakeAdapter();
      final svc = _svc(adapter);
      await svc.initialize();
      expect(svc.entitlement.value.tier, TierId.free);

      adapter.pushCustomerInfo(_infoWith(active: {'sentinel'}));
      expect(svc.entitlement.value.tier, TierId.sentinel);

      // Expiration drops back to free — no restart needed.
      adapter.pushCustomerInfo(_infoWith());
      expect(svc.entitlement.value.tier, TierId.free);
    });

    test('managementURL surfaces only when present', () async {
      final withUrl = _FakeAdapter(
          initialInfo: _infoWith(
              active: {'sentinel'},
              managementUrl: 'https://play.google.com/store/account'));
      final svc = _svc(withUrl);
      await svc.initialize();
      expect(svc.entitlement.value.managementUrl.toString(),
          contains('play.google.com'));

      final without = _FakeAdapter(initialInfo: _infoWith());
      final svc2 = _svc(without);
      await svc2.initialize();
      expect(svc2.entitlement.value.managementUrl, isNull);
    });
  });

  group('RevenueCatPurchaseService — offerings', () {
    test('uses the CURRENT offering and maps known package ids',
        () async {
      final adapter = _FakeAdapter()
        ..offerings = _offerings([
          _rcPackage('sentinel_monthly', price: r'$9.99'),
          _rcPackage('sentinel_annual', price: r'$79.99'),
          _rcPackage('family_vault_monthly', price: r'$19.99'),
          _rcPackage('family_vault_annual', price: 'EGP 999.99'),
          _rcPackage('mystery_legacy_sku'), // unknown — ignored
        ]);
      final svc = _svc(adapter);
      await svc.initialize();
      final packages = await svc.getPackages();

      expect(packages, hasLength(4));
      final annual = packages.firstWhere(
          (p) => p.identifier == 'family_vault_annual');
      expect(annual.tierId, TierId.familyVault);
      expect(annual.cycle, BillingCycle.annual);
      // Store-localized price string passes through untouched.
      expect(annual.priceString, 'EGP 999.99');
    });

    test('null current offering returns empty — nothing fabricated',
        () async {
      final adapter = _FakeAdapter()
        ..offerings = _offerings([], current: false);
      final svc = _svc(adapter);
      await svc.initialize();

      expect(await svc.getPackages(), isEmpty);
    });

    test('offerings failure surfaces a safe exception', () async {
      final adapter = _FakeAdapter()
        ..offeringsError = Exception('internal rc detail');
      final svc = _svc(adapter);
      await svc.initialize();

      try {
        await svc.getPackages();
        fail('expected throw');
      } on PurchaseServiceException catch (e) {
        expect(e.message, isNot(contains('internal')));
      }
    });
  });

  group('RevenueCatPurchaseService — purchase & restore', () {
    test('purchase forwards the native package and verifies the '
        'returned entitlement', () async {
      final adapter = _FakeAdapter()
        ..purchaseResultInfo = _infoWith(active: {'sentinel'});
      final svc = _svc(adapter);
      await svc.initialize();

      final pkg = _domainPackage('sentinel_monthly', TierId.sentinel,
          BillingCycle.monthly);
      final outcome = await svc.purchasePackage(pkg);

      expect(outcome.tier, TierId.sentinel);
      expect(outcome.wasCancelled, isFalse);
      expect(adapter.lastPurchasedPackage?.identifier,
          'sentinel_monthly');
      expect(svc.entitlement.value.tier, TierId.sentinel);
    });

    test('purchase returning without entitlement does NOT activate',
        () async {
      final adapter = _FakeAdapter()
        ..purchaseResultInfo = _infoWith(); // no entitlements
      final svc = _svc(adapter);
      await svc.initialize();

      final pkg = _domainPackage('sentinel_monthly', TierId.sentinel,
          BillingCycle.monthly);
      final outcome = await svc.purchasePackage(pkg);

      expect(outcome.tier, isNull);
      expect(outcome.wasCancelled, isFalse);
      expect(svc.entitlement.value.tier, TierId.free);
    });

    test('user cancellation is a quiet outcome, not an error',
        () async {
      final adapter = _FakeAdapter()
        ..purchaseError =
            PlatformException(code: '1'); // purchaseCancelledError
      final svc = _svc(adapter);
      await svc.initialize();

      final pkg = _domainPackage('sentinel_monthly', TierId.sentinel,
          BillingCycle.monthly);
      final outcome = await svc.purchasePackage(pkg);

      expect(outcome.wasCancelled, isTrue);
      expect(outcome.tier, isNull);
      expect(svc.entitlement.value.tier, TierId.free);
    });

    test('store errors map to consumer-safe messages', () async {
      final adapter = _FakeAdapter()
        ..purchaseError = PlatformException(
            code: '10', message: 'secret upstream body dump');
      final svc = _svc(adapter);
      await svc.initialize();

      final pkg = _domainPackage('sentinel_monthly', TierId.sentinel,
          BillingCycle.monthly);
      try {
        await svc.purchasePackage(pkg);
        fail('expected throw');
      } on PurchaseServiceException catch (e) {
        expect(e.message, isNot(contains('secret')));
        expect(e.message, contains('connection'));
      }
    });

    test('purchase of a package without a native handle fails safely',
        () async {
      final adapter = _FakeAdapter();
      final svc = _svc(adapter);
      await svc.initialize();

      const pkg = StorePackage(
        identifier: 'sentinel_monthly',
        tierId: TierId.sentinel,
        cycle: BillingCycle.monthly,
        priceString: r'$9.99',
        title: 'x',
      );
      await expectLater(svc.purchasePackage(pkg),
          throwsA(isA<PurchaseServiceException>()));
      expect(adapter.lastPurchasedPackage, isNull);
    });

    test('restore returns the verified tier', () async {
      final adapter = _FakeAdapter()
        ..restoreResultInfo = _infoWith(active: {'family_vault'});
      final svc = _svc(adapter);
      await svc.initialize();

      expect(await svc.restorePurchases(), TierId.familyVault);
      expect(svc.entitlement.value.tier, TierId.familyVault);
    });

    test('restore with nothing active returns null', () async {
      final adapter = _FakeAdapter()..restoreResultInfo = _infoWith();
      final svc = _svc(adapter);
      await svc.initialize();

      expect(await svc.restorePurchases(), isNull);
      expect(svc.entitlement.value.tier, TierId.free);
    });

    test('restore failure surfaces a safe exception', () async {
      final adapter = _FakeAdapter()
        ..restoreError = Exception('raw receipt internals');
      final svc = _svc(adapter);
      await svc.initialize();

      try {
        await svc.restorePurchases();
        fail('expected throw');
      } on PurchaseServiceException catch (e) {
        expect(e.message, isNot(contains('internals')));
      }
    });
  });

  group('RevenueCatPurchaseService — Test Store judging backend', () {
    RevenueCatPurchaseService testStoreSvc(_FakeAdapter adapter) =>
        RevenueCatPurchaseService.testStore(
            apiKey: 'rc_test_store_key', adapter: adapter);

    test('is the real SDK service with a distinct test-store backend '
        'mode — never the local Demo Store', () async {
      final adapter = _FakeAdapter();
      final svc = testStoreSvc(adapter);
      await svc.initialize();

      expect(svc, isA<RevenueCatPurchaseService>());
      expect(svc.backendMode, PurchaseBackendMode.testStore);
      expect(svc.backendMode, isNot(PurchaseBackendMode.demoStore));
      expect(svc.backendMode, isNot(PurchaseBackendMode.realStore));
      expect(svc.entitlement.value.backend,
          PurchaseBackendMode.testStore);
      expect(svc.entitlement.value.isDemo, isFalse);
    });

    test('derives entitlement exclusively from Test Store '
        'CustomerInfo — same sentinel/family_vault truth', () async {
      final adapter = _FakeAdapter(
          initialInfo: _infoWith(active: {'sentinel'}));
      final svc = testStoreSvc(adapter);
      await svc.initialize();
      expect(svc.entitlement.value.tier, TierId.sentinel);
      expect(svc.entitlement.value.backend,
          PurchaseBackendMode.testStore);

      adapter.pushCustomerInfo(_infoWith(active: {'family_vault'}));
      expect(svc.entitlement.value.tier, TierId.familyVault);
      expect(svc.entitlement.value.backend,
          PurchaseBackendMode.testStore);
    });

    test('Test Store purchase activates only when CustomerInfo '
        'verifies the entitlement', () async {
      final adapter = _FakeAdapter()
        ..purchaseResultInfo = _infoWith(active: {'sentinel'});
      final svc = testStoreSvc(adapter);
      await svc.initialize();

      final pkg = _domainPackage('sentinel_monthly', TierId.sentinel,
          BillingCycle.monthly);
      final outcome = await svc.purchasePackage(pkg);
      expect(outcome.tier, TierId.sentinel);
      expect(svc.entitlement.value.backend,
          PurchaseBackendMode.testStore);
    });

    test('Test Store purchase that returns without entitlement does '
        'NOT activate', () async {
      final adapter = _FakeAdapter()
        ..purchaseResultInfo = _infoWith();
      final svc = testStoreSvc(adapter);
      await svc.initialize();

      final pkg = _domainPackage('sentinel_monthly', TierId.sentinel,
          BillingCycle.monthly);
      final outcome = await svc.purchasePackage(pkg);
      expect(outcome.tier, isNull);
      expect(svc.entitlement.value.tier, TierId.free);
    });

    test('Test Store restore flows through the real SDK path',
        () async {
      final adapter = _FakeAdapter()
        ..restoreResultInfo = _infoWith(active: {'family_vault'});
      final svc = testStoreSvc(adapter);
      await svc.initialize();

      expect(await svc.restorePurchases(), TierId.familyVault);
      expect(svc.entitlement.value.backend,
          PurchaseBackendMode.testStore);
    });

    test('empty Test Store key fails truthfully — no granted tier',
        () async {
      final adapter = _FakeAdapter();
      // Bypass the dart-define by injecting an empty key explicitly.
      final svc = RevenueCatPurchaseService(
        apiKey: '',
        adapter: adapter,
        backendMode: PurchaseBackendMode.testStore,
      );
      await expectLater(svc.initialize(),
          throwsA(isA<PurchaseServiceException>()));
      expect(svc.entitlement.value.tier, TierId.free);
      expect(adapter.configureCalls, 0);
    });
  });
}
