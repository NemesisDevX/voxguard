import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() {
  runApp(const VoxGuardApp());
}

/// Root application widget — VoxGuard, consumer-first AI scam
/// interceptor and voice defense system.
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
