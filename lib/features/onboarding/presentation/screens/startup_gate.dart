import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/onboarding/onboarding_state_store.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'onboarding_screen.dart';

/// Startup gate inside the app's single Navigator — first run shows
/// onboarding, completed users land on Home. A Family Shield
/// notification tap still routes through the shared navigator key, so
/// a cold-start alert can push its screen above onboarding.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, this.onboardingStore});

  /// Injectable for tests; defaults to the persisted store.
  final IOnboardingStateStore? onboardingStore;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final IOnboardingStateStore _store =
      widget.onboardingStore ?? OnboardingStateLocator.instance;
  bool? _completed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await _store.isCompleted();
    if (mounted) setState(() => _completed = done);
  }

  void _complete() {
    unawaited(_store.markCompleted());
    setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_completed) {
      null => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      true => const HomeScreen(),
      false => OnboardingScreen(onCompleted: _complete),
    };
  }
}
