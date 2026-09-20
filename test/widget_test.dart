// Smoke test for the VoxGuard app shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:voxguard/main.dart';

void main() {
  testWidgets('VoxGuard home renders shield dashboard', (tester) async {
    await tester.pumpWidget(const VoxGuardApp());
    await tester.pump();

    expect(find.text('VoxGuard'), findsOneWidget);
    expect(find.text('VoxGuard Ready'), findsOneWidget);
    expect(find.text('Start SafeCall'), findsOneWidget);
    expect(find.text('Live Shield'), findsOneWidget);
    expect(find.text('Analyze Recording'), findsOneWidget);
  });
}
