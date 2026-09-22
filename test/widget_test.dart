// Smoke test for the VoxGuard app shell.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voxguard/core/services/preferences/app_preferences.dart';
import 'package:voxguard/main.dart';

void main() {
  testWidgets('VoxGuard home renders shield dashboard', (tester) async {
    // Completed setup + onboarding → the app opens directly into Home.
    SharedPreferences.setMockInitialValues(
        const {'voxguard.onboarding_version': 1});
    AppPreferencesLocator.instance =
        AppPreferences.inMemory(setupCompleted: true);
    await tester.pumpWidget(const VoxGuardApp());
    await tester.pump();

    expect(find.text('VoxGuard'), findsOneWidget);
    expect(find.text('VoxGuard Ready'), findsOneWidget);
    expect(find.text('Start SafeCall'), findsOneWidget);
    // Live Shield is unimplemented — the release UI must not
    // advertise it; it exists only in README roadmap docs.
    expect(find.text('Live Shield'), findsNothing);
    expect(find.text('Analyze Recording'), findsOneWidget);
  });
}
