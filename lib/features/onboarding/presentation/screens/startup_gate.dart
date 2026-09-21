import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/onboarding/onboarding_state_store.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../protection/presentation/safecall_launcher.dart';
import 'onboarding_screen.dart';

/// Startup gate inside the app's single Navigator — first run shows
/// onboarding, completed users land on Home. A Family Shield
/// notification tap still routes through the shared navigator key, so
/// a cold-start alert can push its screen above onboarding.
///
/// This widget is `home:` — it stays mounted for the app's lifetime
/// even while its build output swaps between onboarding and Home.
/// That makes its [State.context] a durable navigation owner for the
/// onboarding→SafeCall handoff: launching from the gate's context
/// guarantees the post-call safety sheet still has a mounted context
/// after onboarding completes and the onboarding widget unmounts.
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

  /// In-flight completion write — guards against double taps racing
  /// `markCompleted()` (Skip/Explore/Start SafeCall all funnel here).
  bool _completing = false;

  /// In-flight SafeCall launch — a second Start SafeCall tap while the
  /// completion write + route push are pending must not double-push.
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await _store.isCompleted();
    if (mounted) setState(() => _completed = done);
  }

  /// Awaits the durable completion write before entering Home. If the
  /// write fails the user still gets in (the app stays usable) — but
  /// the failure is surfaced honestly and nothing claims the
  /// completion was persisted; onboarding will show again next launch.
  Future<void> _complete() async {
    if (_completing) return;
    _completing = true;
    var persisted = true;
    try {
      await _store.markCompleted();
    } catch (_) {
      persisted = false;
    } finally {
      _completing = false;
    }
    if (!mounted) return;
    if (!persisted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t save your progress — onboarding '
              'will show again next launch.'),
        ),
      );
    }
    setState(() => _completed = true);
  }

  /// Onboarding "Start SafeCall" CTA. The gate — not the onboarding
  /// widget — owns the launch context, so the post-call safety sheet
  /// survives the onboarding→Home widget swap.
  Future<void> _startSafeCall() async {
    if (_launching) return;
    _launching = true;
    try {
      await _complete();
      if (!mounted) return;
      await launchSafeCall(context);
    } finally {
      _launching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_completed) {
      null => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      true => const HomeScreen(),
      false => OnboardingScreen(
          onCompleted: _complete,
          onStartSafeCall: _startSafeCall,
        ),
    };
  }
}
