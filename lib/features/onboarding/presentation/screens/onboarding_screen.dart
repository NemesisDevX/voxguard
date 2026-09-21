import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/push/onesignal_push_identity_service.dart';
import '../../../../core/services/push/push_identity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../protection/presentation/safecall_launcher.dart';

/// First-run onboarding — five concise pages covering what VoxGuard
/// does, what leaves the phone, and when permissions are asked.
///
/// [reviewMode] (Settings → "How VoxGuard Works") shows the same
/// content read-only: no Skip, no completion writes, a Done/back
/// exit. Onboarding NEVER requests microphone or notification
/// permission on open — the only permission action is the explicit
/// "Enable Family Alerts" button on page 3.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onCompleted,
    this.onStartSafeCall,
    this.reviewMode = false,
    this.pushService,
  });

  /// Called when the user finishes/skips onboarding (first-run mode).
  final VoidCallback? onCompleted;

  /// "Start SafeCall" owner. When provided (StartupGate wiring), the
  /// caller owns completion + launch so the post-call sheet keeps a
  /// mounted context after this screen unmounts. When null (directly
  /// pushed instances), the screen completes then launches itself.
  final Future<void> Function()? onStartSafeCall;
  final bool reviewMode;

  /// Injectable for tests; defaults to the process-wide push service.
  final IPushIdentityService? pushService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  IPushIdentityService get _push =>
      widget.pushService ?? PushIdentityLocator.instance;

  static const _pageCount = 5;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool _finishing = false;

  void _finish() {
    if (_finishing) return;
    _finishing = true;
    widget.onCompleted?.call();
  }

  void _startSafeCall() {
    if (_finishing) return;
    _finishing = true;
    final launch = widget.onStartSafeCall;
    if (launch != null) {
      // The caller (StartupGate) owns completion and launches from a
      // context that survives this screen's unmount — the post-call
      // safety sheet can then always present.
      launch().whenComplete(() => _finishing = false);
      return;
    }
    _finish();
    if (mounted) {
      unawaited(launchSafeCall(context)
          .whenComplete(() => _finishing = false));
    }
  }

  Future<void> _enableAlerts() async {
    await _push.enableAlerts();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — Back / progress / Skip (or Close in review).
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _page > 0
                        ? _back
                        : (widget.reviewMode
                            ? () => Navigator.of(context).maybePop()
                            : null),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _pageCount; i++)
                            _Dot(active: i == _page),
                        ],
                      ),
                    ),
                  ),
                  widget.reviewMode
                      ? IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              Navigator.of(context).maybePop(),
                        )
                      : TextButton(
                          onPressed: _finish,
                          child: const Text('Skip for now'),
                        ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _VoicePage(),
                  const _SignalsPage(),
                  const _VerifyPage(),
                  _FamilyShieldPage(
                    push: _push,
                    onEnableAlerts: _enableAlerts,
                  ),
                  _ReadyPage(
                    reviewMode: widget.reviewMode,
                    onStartSafeCall: _startSafeCall,
                    onExplore: _finish,
                  ),
                ],
              ),
            ),
            if (_page < _pageCount - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    child: const Text('Continue'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.borderSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Shared page scaffold — scrollable, safe on small screens and
/// large text scaling.
class _Page extends StatelessWidget {
  const _Page({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Icon(icon, size: 44, color: iconColor),
          const SizedBox(height: 18),
          Text(title, style: AppTypography.titleLarge),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

// ── Page 1 · Familiar voice ──────────────────────────────────────────

/// The emotional opener — the threat model in one sentence.
class _VoicePage extends StatelessWidget {
  const _VoicePage();

  @override
  Widget build(BuildContext context) {
    return const _Page(
      icon: Icons.record_voice_over_outlined,
      iconColor: AppColors.statusWarning,
      title: 'A familiar voice can still be misleading.',
      children: [
        Text(
          'Scammers clone voices, spoof numbers, and pressure the '
          'people you love. Hearing a familiar voice is not proof '
          'of who is speaking.',
          style: AppTypography.bodyMedium,
        ),
        SizedBox(height: 14),
        _Bullet('Urgency, secrecy, and payment pressure are the '
            'real tells — not the voice itself.'),
        _Bullet('Caller ID and sound alone can never prove identity.'),
      ],
    );
  }
}

// ── Page 2 · Two signals ─────────────────────────────────────────────

/// What the app actually watches — two evidence streams, one human
/// decision. The Signal Lens metaphor introduced in words.
class _SignalsPage extends StatelessWidget {
  const _SignalsPage();

  @override
  Widget build(BuildContext context) {
    return const _Page(
      icon: Icons.blur_on,
      iconColor: AppColors.accent,
      title: 'Two signals. One human decision.',
      children: [
        Text(
          'During a SafeCall session you start yourself, VoxGuard '
          'listens for risk signals — never identity certainty — and '
          'explains what it heard in plain language.',
          style: AppTypography.bodyMedium,
        ),
        SizedBox(height: 14),
        _Bullet('Conversation signal — urgency, payment demands, '
            'secrecy pressure in what is being said.'),
        _Bullet('Voice-acoustic signal — anomaly indicators; an '
            'assistive heuristic, not a forensic verdict.'),
        _Bullet('The Risk Signal score is a signal, not the '
            'probability that a call is fake.'),
        _Bullet('VoxGuard does not intercept your phone\'s cellular '
            'calls — a protection session is always your choice.'),
      ],
    );
  }
}

// ── Page 3 · Verify independently ────────────────────────────────────

/// The product's core behavior: pause, then verify through a channel
/// you already trust.
class _VerifyPage extends StatelessWidget {
  const _VerifyPage();

  @override
  Widget build(BuildContext context) {
    return const _Page(
      icon: Icons.verified_user_outlined,
      iconColor: AppColors.accent,
      title: 'When something feels wrong, verify independently.',
      children: [
        Text(
          'A risk signal is a reason to pause — not a verdict. The '
          'strongest move is always yours:',
          style: AppTypography.bodyMedium,
        ),
        SizedBox(height: 14),
        _Bullet('Pause — never send money, codes, or details under '
            'pressure.'),
        _Bullet('Call the person back on a number you already '
            'trust — never one the caller gave you.'),
        _Bullet('Agree on a family safe phrase offline — ask for it '
            'when a call feels wrong.'),
      ],
    );
  }
}

// ── Page 4 · Family Shield ───────────────────────────────────────────

/// The human loop: alerts, Trusted Circle, and the (explicit,
/// opt-in) notification permission action.
class _FamilyShieldPage extends StatelessWidget {
  const _FamilyShieldPage({
    required this.push,
    required this.onEnableAlerts,
  });

  final IPushIdentityService push;
  final Future<void> Function() onEnableAlerts;

  String _shortId(String id) =>
      id.length > 14 ? '${id.substring(0, 8)}…${id.substring(id.length - 6)}' : id;

  @override
  Widget build(BuildContext context) {
    return _Page(
      icon: Icons.group_outlined,
      iconColor: AppColors.statusSafe,
      title: 'Family Shield: a second set of eyes.',
      children: [
        const Text(
          'When a call feels wrong, people you trust can help you '
          'decide. Each VoxGuard installation receives an opaque '
          'Family Shield ID — trusted people save it in their own '
          'Trusted Circle to receive your private safety alerts '
          'and respond.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 14),
        const _Bullet('Names and trusted phone numbers stay on the '
            'device that saved them.'),
        const _Bullet('Setting up your Trusted Circle is optional — '
            'you can do it later in Settings.'),
        const SizedBox(height: 14),
        FutureBuilder<String>(
          future: PushIdentityLocator.instance.voxGuardIdentity(),
          builder: (context, snap) {
            final id = snap.data;
            if (id == null) {
              return const Text(
                'Your Family Shield ID appears here once the app '
                'finishes setting up.',
                style: AppTypography.bodyMedium,
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Your ID: ${_shortId(id)}',
                    style: AppTypography.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Family Shield ID copied.')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy ID'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<FamilyPushRegistration>(
          valueListenable: push.registration,
          builder: (context, reg, _) {
            // The permission prompt can only be requested when the OS
            // can actually show one. Denied/unconfigured/unsupported
            // states disable the action instead of firing a no-op —
            // denied users are directed to system Settings.
            final canRequest = switch (reg.status) {
              PushRegistrationStatus.permissionRequired ||
              PushRegistrationStatus.error => true,
              _ => false,
            };
            final label = switch (reg.status) {
              PushRegistrationStatus.registered =>
                'Family Alerts enabled',
              PushRegistrationStatus.permissionDenied =>
                'Notifications are off — you can enable them later '
                    'from your device\'s Settings app',
              PushRegistrationStatus.unsupported =>
                'Push alerts aren\'t supported on this platform',
              PushRegistrationStatus.notConfigured =>
                'Push alerts aren\'t configured in this build',
              PushRegistrationStatus.registering =>
                'Enabling notifications…',
              _ => null,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: canRequest ? onEnableAlerts : null,
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Enable Family Alerts'),
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(height: 8),
                  Text(label, style: AppTypography.bodyMedium),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Page 5 · Privacy + ready ─────────────────────────────────────────

/// Privacy controls stay explicit — then the ready state.
class _ReadyPage extends StatelessWidget {
  const _ReadyPage({
    required this.reviewMode,
    required this.onStartSafeCall,
    required this.onExplore,
  });

  final bool reviewMode;
  final VoidCallback onStartSafeCall;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return _Page(
      icon: Icons.lock_outline,
      iconColor: AppColors.statusSafe,
      title: 'Your voice stays in your control.',
      children: [
        const _Bullet('Microphone audio is processed in memory while '
            'a session runs — VoxGuard never stores an audio '
            'recording. Live Mic asks for microphone access only '
            'when you choose it; Demo Mode works without it.'),
        const _Bullet('When cloud transcription is configured, live '
            'audio streams to the configured transcription provider '
            'to produce transcript text for analysis.'),
        const _Bullet('Family Shield alerts carry only an opaque '
            'VoxGuard ID, an incident reference, and a risk band — '
            'never audio, transcripts, names, or phone numbers.'),
        const SizedBox(height: 6),
        const Text(
          'Evidence → Pause → Verify → People you trust',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: 10),
        const Text(
          'Start a SafeCall session when you want protection — you '
          'always choose Live Mic or Demo Mode yourself.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 22),
        if (reviewMode)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Done'),
            ),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartSafeCall,
              icon: const Icon(Icons.phone_in_talk_outlined),
              label: const Text('Start SafeCall'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onExplore,
              child: const Text('Explore VoxGuard'),
            ),
          ),
        ],
      ],
    );
  }
}
