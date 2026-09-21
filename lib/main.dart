import 'dart:async';

import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/services/push/onesignal_push_identity_service.dart';
import 'core/theme/app_theme.dart';
import 'features/family_shield/family_alert_coordinator.dart';
import 'features/onboarding/presentation/screens/startup_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Subscribe BEFORE push init so a cold-start notification tap is
  // never lost; the coordinator holds a pending event until the
  // Navigator is mounted.
  final coordinator = FamilyAlertCoordinator(
    messengerKey: FamilyAlertNavigator.messengerKey,
  )..start();
  // Push identity init is permission-free: reads subscription state and
  // attaches observers. The native permission prompt only ever fires
  // from the Family Shield card's explicit enable button. No App ID →
  // resolves to `notConfigured`; app never blocks on it.
  unawaited(PushIdentityLocator.instance.initialize());
  runApp(VoxGuardApp(coordinator: coordinator));
}

/// Root application widget — VoxGuard, consumer-first AI voice-threat
/// monitor and scam-risk defense system.
class VoxGuardApp extends StatelessWidget {
  const VoxGuardApp({super.key, this.coordinator});

  /// Notification routing — created in `main` so it subscribes before
  /// the first frame. Optional for widget tests.
  final FamilyAlertCoordinator? coordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorKey: FamilyAlertNavigator.key,
      scaffoldMessengerKey: FamilyAlertNavigator.messengerKey,
      home: const StartupGate(),
    );
  }
}
