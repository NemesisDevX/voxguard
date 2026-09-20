import 'dart:async';

import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/services/push/onesignal_push_identity_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Push identity init is permission-free: reads subscription state and
  // attaches observers. The native permission prompt only ever fires
  // from the Family Shield card's explicit enable button. No App ID →
  // resolves to `notConfigured`; app never blocks on it.
  unawaited(PushIdentityLocator.instance.initialize());
  runApp(const VoxGuardApp());
}

/// Root application widget — VoxGuard, consumer-first AI voice-threat
/// monitor and scam-risk defense system.
class VoxGuardApp extends StatelessWidget {
  const VoxGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
