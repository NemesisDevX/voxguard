// Responsiveness + accessibility smoke: every major surface must lay
// out without RenderFlex overflow at 320px width and under large text
// scale. Flutter reports overflow as a test exception — a passing
// pump IS the assertion.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxguard/features/home/presentation/screens/home_screen.dart';
import 'package:voxguard/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:voxguard/features/paywall/domain/services/mock_sandbox_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/purchase_service_locator.dart';
import 'package:voxguard/features/paywall/domain/services/unavailable_purchase_service.dart';
import 'package:voxguard/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:voxguard/features/recording/presentation/screens/analyze_recording_screen.dart';

Widget _app(Widget child) => MaterialApp(home: child);

/// Pumps [child] at each hostile configuration — narrow phone,
/// narrow + large text, short landscape-ish height, keyboard inset.
Future<void> _pumpAtHostileSizes(
  WidgetTester tester,
  Widget child,
) async {
  for (final (size, scale) in [
    (const Size(320, 568), 1.0), // smallest common phone
    (const Size(360, 640), 1.0), // common budget phone
    (const Size(320, 568), 1.35), // large text on narrow screen
    (const Size(360, 640), 1.5), // large text on normal phone
    (const Size(320, 400), 1.0), // short-height screen
    (const Size(360, 480), 1.3), // keyboard-open-ish height
  ]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(_app(child));
    // Bounded pumps — the banner/core animations repeat forever, so
    // pumpAndSettle would never settle. Overflow errors still throw
    // during layout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }
}

void main() {
  setUp(() => PurchaseServiceLocator.reset());
  tearDown(() => PurchaseServiceLocator.reset());

  testWidgets('HomeScreen lays out at narrow widths and large text',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        const {'voxguard.onboarding_version': 1});
    await _pumpAtHostileSizes(tester, const HomeScreen());
  });

  testWidgets('Settings tab (subscription card) fits narrow screens',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        const {'voxguard.onboarding_version': 1});
    PurchaseServiceLocator.instance = MockSandboxPurchaseService(
        networkDelay: Duration.zero, checkoutDelay: Duration.zero);
    await _pumpAtHostileSizes(tester, const HomeScreen());
    // Jump to the settings tab. Bounded pumps — the home banner keeps
    // animating inside the IndexedStack, so pumpAndSettle never settles.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Subscription'), findsOneWidget);
  });

  testWidgets('PaywallScreen (demo store) fits narrow + large text',
      (tester) async {
    PurchaseServiceLocator.instance = MockSandboxPurchaseService(
        networkDelay: Duration.zero, checkoutDelay: Duration.zero);
    await _pumpAtHostileSizes(tester, const PaywallScreen());
  });

  testWidgets('PaywallScreen (unavailable) fits narrow + large text',
      (tester) async {
    PurchaseServiceLocator.instance = UnavailablePurchaseService();
    await _pumpAtHostileSizes(tester, const PaywallScreen());
  });

  testWidgets('AnalyzeRecordingScreen picker state fits narrow '
      'screens', (tester) async {
    await _pumpAtHostileSizes(tester, const AnalyzeRecordingScreen());
  });

  testWidgets('OnboardingScreen fits narrow + large text',
      (tester) async {
    await _pumpAtHostileSizes(tester, const OnboardingScreen());
  });
}
