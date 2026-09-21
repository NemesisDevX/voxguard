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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pageCount; i++)
                          _Dot(active: i == _page),
                      ],
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
                  const _UnderstandPage(),
                  const _PrivacyPage(),
                  _PermissionsPage(
                    push: _push,
                    onEnableAlerts: _enableAlerts,
                  ),
                  const _FamilyShieldPage(),
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

// ── Page 1 · Understand ──────────────────────────────────────────────

class _UnderstandPage extends StatelessWidget {
  const _UnderstandPage();

  @override
  Widget build(BuildContext context) {
    return const _Page(
      icon: Icons.hearing,
      iconColor: AppColors.statusSafe,
      title: 'Hear the threat before you trust the voice.',
      children: [
        Text(
          'During a SafeCall protection session you start yourself, '
          'VoxGuard listens for suspicious patterns and explains the '
          'risk in plain language.',
          style: AppTypography.bodyMedium,
        ),
        SizedBox(height: 14),
        _Bullet('Conversation-risk signals — urgency, payment '
            'demands, secrecy pressure.'),
        _Bullet('Acoustic anomaly indicators — an assistive '
            'heuristic prototype, not a forensic verdict.'),
        _Bullet('Threat Score is a risk signal, not the statistical '
            'probability that a call is fake.'),
        _Bullet('VoxGuard does not intercept your phone\'s cellular '
            'calls — a protection session is always your choice.'),
      ],
    );
  }
}

// ── Page 2 · Privacy ─────────────────────────────────────────────────

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return const _Page(
      icon: Icons.lock_outline,
      iconColor: AppColors.accent,
      title: 'Your voice stays in your control.',
      children: [
        _Bullet('Microphone audio is processed in memory while a '
            'session runs — VoxGuard never stores an audio recording.'),
        _Bullet('When cloud transcription is configured, live audio '
            'streams to the configured transcription provider to '
            'produce transcript text for analysis.'),
        _Bullet('Family Shield alerts carry only privacy-minimal '
            'metadata: an opaque VoxGuard ID, an incident reference, '
            'and a risk band.'),
        _Bullet('Family Shield never sends audio, transcripts, '
            'names, or trusted phone numbers.'),
        _Bullet('You verify people independently — VoxGuard flags '
            'risk; it does not prove identity.'),
      ],
    );
  }
}

// ── Page 3 · Permissions ─────────────────────────────────────────────

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    required this.push,
    required this.onEnableAlerts,
  });

  final IPushIdentityService push;
  final Future<void> Function() onEnableAlerts;

  @override
  Widget build(BuildContext context) {
    return _Page(
      icon: Icons.tune,
      iconColor: AppColors.statusWarning,
      title: 'Permissions only when you choose.',
      children: [
        const Text('Microphone', style: AppTypography.titleMedium),
        const SizedBox(height: 6),
        const Text(
          'Live Mic needs microphone access while a protection '
          'session is running — it is only asked for when you choose '
          'Live Mic. Demo Mode works without it.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 18),
        const Text('Notifications', style: AppTypography.titleMedium),
        const SizedBox(height: 6),
        const Text(
          'Family Alerts let trusted people respond when you need a '
          'second pair of eyes. You can enable them now or later in '
          'Settings — SafeCall works either way.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 14),
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

// ── Page 4 · Family Shield ───────────────────────────────────────────

class _FamilyShieldPage extends StatelessWidget {
  const _FamilyShieldPage();

  String _shortId(String id) =>
      id.length > 14 ? '${id.substring(0, 8)}…${id.substring(id.length - 6)}' : id;

  @override
  Widget build(BuildContext context) {
    return _Page(
      icon: Icons.group_outlined,
      iconColor: AppColors.accent,
      title: 'A second pair of eyes.',
      children: [
        const Text(
          'Each VoxGuard installation receives an opaque Family Shield '
          'ID. Trusted people can save it in their own Trusted Circle '
          'to receive your private safety alerts — and respond.',
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
      ],
    );
  }
}

// ── Page 5 · Ready ───────────────────────────────────────────────────

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
      icon: Icons.shield_outlined,
      iconColor: AppColors.statusSafe,
      title: 'VoxGuard is ready.',
      children: [
        const Text(
          'Listen → Warn → Explain → Verify → Protect family',
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
