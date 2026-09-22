import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/onboarding/onboarding_state_store.dart';
import '../../../../core/services/preferences/app_preferences.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../protection/presentation/safecall_launcher.dart';
import '../widgets/launch_splash.dart';
import 'onboarding_screen.dart';
import 'welcome_setup_screen.dart';

/// Startup gate inside the app's single Navigator — the bootstrap
/// chain is LaunchSplash → Welcome Setup (first run only) →
/// safety/privacy onboarding → Home. A Family Shield notification tap
/// still routes through the shared navigator key, so a cold-start
/// alert can push its screen above whatever the gate is showing.
///
/// This widget is `home:` — it stays mounted for the app's lifetime
/// even while its build output swaps between stages. That makes its
/// [State.context] a durable navigation owner for the
/// onboarding→SafeCall handoff: launching from the gate's context
/// guarantees the post-call safety sheet still has a mounted context
/// after onboarding completes and the onboarding widget unmounts.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, this.onboardingStore, this.preferences});

  /// Injectable for tests; defaults to the persisted store.
  final IOnboardingStateStore? onboardingStore;

  /// Injectable for tests; defaults to the process-wide preferences.
  final AppPreferences? preferences;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final IOnboardingStateStore _store =
      widget.onboardingStore ?? OnboardingStateLocator.instance;
  late final AppPreferences _prefs =
      widget.preferences ?? AppPreferencesLocator.instance;
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
    _prefs.addListener(_onPrefs);
    _load();
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefs);
    super.dispose();
  }

  /// Welcome Setup completing flips `setupCompleted`; the gate simply
  /// rebuilds — the welcome screen unmounts and onboarding appears.
  void _onPrefs() => setState(() {});

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
        SnackBar(content: Text(context.l10n.startupStoreError)),
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
    final completed = _completed;
    if (completed == null) {
      return const LaunchSplash();
    }
    if (!_prefs.setupCompleted) {
      // Welcome Setup is a display-only stage — it just flips the
      // persisted flag the gate is already listening to.
      return const WelcomeSetupScreen(onDone: _noop);
    }
    if (!completed) {
      return OnboardingScreen(
        onCompleted: _complete,
        onStartSafeCall: _startSafeCall,
      );
    }
    return const HomeScreen();
  }

  static void _noop() {}
}
