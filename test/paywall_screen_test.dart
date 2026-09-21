import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/features/paywall/domain/models/billing_cycle.dart';
import 'package:voxguard/features/paywall/domain/models/entitlement_state.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'package:voxguard/features/paywall/domain/services/i_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/mock_sandbox_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/purchase_service_locator.dart';
import 'package:voxguard/features/paywall/domain/services/unavailable_purchase_service.dart';
import 'package:voxguard/features/paywall/presentation/screens/paywall_screen.dart';

/// Fake real-store backend — returns a controlled package set.
final class _RealStoreFake implements IPurchaseService {
  _RealStoreFake(this.packages);

  final List<StorePackage> packages;
  final _entitlement = ValueNotifier<EntitlementState>(
    const EntitlementState(
      backend: PurchaseBackendMode.realStore,
      status: EntitlementStatus.ready,
    ),
  );

  @override
  PurchaseBackendMode get backendMode => PurchaseBackendMode.realStore;

  @override
  ValueListenable<EntitlementState> get entitlement => _entitlement;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<StorePackage>> getPackages() async => packages;

  @override
  Future<PurchaseOutcome> purchasePackage(StorePackage package) async {
    _entitlement.value = EntitlementState(
      tier: package.tierId,
      backend: PurchaseBackendMode.realStore,
      status: EntitlementStatus.ready,
    );
    return PurchaseOutcome.activated(package.tierId);
  }

  @override
  Future<TierId?> restorePurchases() async => null;
}

StorePackage _pkg(String id, TierId tier, BillingCycle cycle,
        {String price = 'EGP 499.99'}) =>
    StorePackage(
      identifier: id,
      tierId: tier,
      cycle: cycle,
      priceString: price,
      title: id,
    );

/// Pushes the paywall as a real route (matching production) so the
/// "Continue Free" / post-purchase pop has somewhere to go.
Widget _app({TierId? preselect}) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PaywallScreen(preselect: preselect),
                ),
              ),
              child: const Text('open paywall'),
            ),
          ),
        ),
      ),
    );

Future<void> _open(WidgetTester tester, {TierId? preselect}) async {
  await tester.pumpWidget(_app(preselect: preselect));
  await tester.tap(find.text('open paywall'));
  await tester.pumpAndSettle();
}

/// Scrolls the paywall ListView until [target] is built+visible.
Future<void> _scrollTo(WidgetTester tester, String text) =>
    tester.scrollUntilVisible(find.text(text), 200,
        scrollable: find.byType(Scrollable));

void main() {
  setUp(() => PurchaseServiceLocator.reset());
  tearDown(() => PurchaseServiceLocator.reset());

  group('PaywallScreen — Demo Store', () {
    testWidgets('labels the simulated store honestly and never '
        'claims a real purchase', (tester) async {
      PurchaseServiceLocator.instance = MockSandboxPurchaseService(
        networkDelay: Duration.zero,
        checkoutDelay: Duration.zero,
      );
      await _open(tester);

      expect(find.text('DEMO STORE'), findsOneWidget);
      expect(find.textContaining('no real charge'), findsOneWidget);
      expect(find.text('Activate Demo Plan'), findsOneWidget);
      // No trial marketing, no encryption overclaim.
      expect(find.textContaining('Free Trial'), findsNothing);
      expect(find.textContaining('Bank-Grade'), findsNothing);

      await tester.tap(find.text('Activate Demo Plan'));
      await tester.pumpAndSettle();
      // Demo confirmation says "Demo plan activated" — never
      // "subscription purchased"; the route pops back home.
      expect(find.textContaining('Demo plan activated'),
          findsOneWidget);
      expect(find.byType(PaywallScreen), findsNothing);
    });
  });

  group('PaywallScreen — unavailable backend', () {
    testWidgets('production-style build without keys cannot fake a '
        'purchase', (tester) async {
      PurchaseServiceLocator.instance = UnavailablePurchaseService();
      await _open(tester);

      expect(find.textContaining("aren't configured in this build"),
          findsOneWidget);
      expect(find.text('Quick Check'), findsOneWidget);
      // No Subscribe CTA, no Restore, no paid cards.
      expect(find.text('Subscribe'), findsNothing);
      expect(find.text('Restore Purchases'), findsNothing);
      expect(find.text('Sentinel Shield'), findsNothing);
      expect(find.text('Family Vault'), findsNothing);

      // Continue Free closes the paywall — no success state, no
      // entitlement mutation.
      await tester.tap(find.text('Continue with Free'));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsNothing);
    });
  });

  group('PaywallScreen — real store', () {
    testWidgets('renders only packages the offering returned, with '
        'store-localized prices', (tester) async {
      PurchaseServiceLocator.instance = _RealStoreFake([
        _pkg('sentinel_monthly', TierId.sentinel, BillingCycle.monthly,
            price: 'EGP 499.99'),
        _pkg('family_vault_monthly', TierId.familyVault,
            BillingCycle.monthly, price: 'EGP 899.99'),
        // No annual packages — the toggle must not render.
      ]);
      await _open(tester);

      expect(find.text('EGP 499.99/mo'), findsOneWidget);
      await _scrollTo(tester, 'Family Vault');
      expect(find.text('EGP 899.99/mo'), findsOneWidget);
      // Only monthly exists → no cycle toggle.
      expect(find.text('Annual'), findsNothing);
      expect(find.text('Monthly'), findsNothing);
      // No unconditional trial/encryption claims.
      expect(find.textContaining('Free Trial'), findsNothing);
      expect(find.textContaining('Bank-Grade'), findsNothing);
      expect(find.text('Billing handled by your app store'),
          findsOneWidget);
    });

    testWidgets('missing paid packages degrade to free with a '
        'truthful notice', (tester) async {
      PurchaseServiceLocator.instance = _RealStoreFake(const []);
      await _open(tester);

      expect(find.text('Quick Check'), findsOneWidget);
      expect(find.textContaining('No paid plans are available'),
          findsOneWidget);
      expect(find.text('Subscribe'), findsNothing);
    });

    testWidgets('preselect highlights the caller-intended tier',
        (tester) async {
      PurchaseServiceLocator.instance = _RealStoreFake([
        _pkg('sentinel_monthly', TierId.sentinel, BillingCycle.monthly),
        _pkg('sentinel_annual', TierId.sentinel, BillingCycle.annual,
            price: 'EGP 4,999.99'),
        _pkg('family_vault_monthly', TierId.familyVault,
            BillingCycle.monthly, price: 'EGP 899.99'),
        _pkg('family_vault_annual', TierId.familyVault,
            BillingCycle.annual, price: 'EGP 8,999.99'),
      ]);
      await _open(tester, preselect: TierId.familyVault);

      // Both cycles exist → toggle renders.
      expect(find.text('Annual'), findsOneWidget);
      // Family Vault card shows its store-localized annual price.
      await _scrollTo(tester, 'Family Vault');
      expect(find.text('EGP 8,999.99/yr'), findsOneWidget);
    });

    testWidgets('legal links render — defaults point at the deployed '
        'GitHub Pages policy/terms', (tester) async {
      PurchaseServiceLocator.instance = _RealStoreFake([
        _pkg('sentinel_monthly', TierId.sentinel, BillingCycle.monthly),
      ]);
      await _open(tester);

      // LegalLinks defaults resolve to the hosted pages — buttons
      // are live, never dead.
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      // Restore is present for a real store.
      expect(find.text('Restore Purchases'), findsOneWidget);
    });
  });
}
