import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/threat_meter_card.dart';

/// SafeCall active-call HUD.
///
/// Shows caller identity, a live waveform, the multi-signal threat
/// radar and a composite threat banner. A floating simulation toggle
/// drives the meters from safe → high risk for demos.
class SafeCallScreen extends StatefulWidget {
  const SafeCallScreen({super.key});

  @override
  State<SafeCallScreen> createState() => _SafeCallScreenState();
}

class _SafeCallScreenState extends State<SafeCallScreen>
    with TickerProviderStateMixin {
  // Simulated scam-conversation targets (composite ≈ 87%).
  static const double _scamSynthetic = 0.88;
  static const double _scamUrgency = 0.93;
  static const double _scamFinancial = 0.85;
  static const double _scamSecrecy = 0.80;

  final Random _rng = Random();

  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  Timer? _clockTimer;
  Timer? _signalTimer;

  Duration _elapsed = Duration.zero;
  bool _simulating = false;

  double _synthetic = 0.08;
  double _urgency = 0.06;
  double _financial = 0.04;
  double _secrecy = 0.05;

  /// Weighted composite threat score shown in the banner.
  double get _composite =>
      (_synthetic + _urgency + _financial + _secrecy) / 4;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
    _signalTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      _tickSignals();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _signalTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  void _tickSignals() {
    setState(() {
      _synthetic = _approach(
        _synthetic,
        _simulating ? _scamSynthetic : _idleTarget(),
      );
      _urgency = _approach(
        _urgency,
        _simulating ? _scamUrgency : _idleTarget(),
      );
      _financial = _approach(
        _financial,
        _simulating ? _scamFinancial : _idleTarget(),
      );
      _secrecy = _approach(
        _secrecy,
        _simulating ? _scamSecrecy : _idleTarget(),
      );
    });
  }

  /// Low wandering baseline while the call is healthy.
  double _idleTarget() => 0.05 + _rng.nextDouble() * 0.09;

  double _approach(double current, double target) {
    final rate = _simulating ? 0.22 : 0.15;
    final noise = (_rng.nextDouble() - 0.5) * 0.02;
    return (current + (target - current) * rate + noise).clamp(0.02, 0.97);
  }

  void _toggleSimulation() {
    setState(() => _simulating = !_simulating);
  }

  String get _durationLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.safeCallTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _LiveBadge()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _CallerCard(
                    durationLabel: _durationLabel,
                    onEndCall: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 16),
                  _WaveformCard(
                    animation: _waveController,
                    tint: AppColors.forThreat(_composite),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    AppStrings.threatRadarTitle,
                    style: AppTypography.labelSmall,
                  ),
                  const SizedBox(height: 12),
                  ThreatMeterCard(
                    title: AppStrings.signalSynthetic,
                    value: _synthetic,
                    icon: Icons.record_voice_over_outlined,
                    style: ThreatMeterStyle.status,
                    normalLabel: AppStrings.statusNormal,
                    elevatedLabel: AppStrings.statusElevated,
                  ),
                  const SizedBox(height: 10),
                  ThreatMeterCard(
                    title: AppStrings.signalUrgency,
                    value: _urgency,
                    icon: Icons.priority_high,
                  ),
                  const SizedBox(height: 10),
                  ThreatMeterCard(
                    title: AppStrings.signalFinancial,
                    value: _financial,
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 10),
                  ThreatMeterCard(
                    title: AppStrings.signalSecrecy,
                    value: _secrecy,
                    icon: Icons.visibility_off_outlined,
                  ),
                ],
              ),
            ),
            _CompositeBanner(score: _composite),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleSimulation,
        backgroundColor:
            _simulating ? AppColors.statusDanger : AppColors.bgElevated,
        foregroundColor: AppColors.textPrimary,
        icon: Icon(_simulating ? Icons.stop : Icons.science_outlined),
        label: Text(
          _simulating ? AppStrings.stopSimulation : AppStrings.simulateScam,
        ),
      ),
    );
  }
}

// ── Caller identity card ─────────────────────────────────────────────

class _CallerCard extends StatelessWidget {
  const _CallerCard({required this.durationLabel, required this.onEndCall});

  final String durationLabel;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.bgElevated,
            child: Icon(
              Icons.person_outline,
              color: AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.unknownCaller,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${AppStrings.maskedNumber} · $durationLabel',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            children: [
              InkWell(
                onTap: onEndCall,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.statusDanger,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(AppStrings.endCall, style: AppTypography.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Live waveform visualizer ─────────────────────────────────────────

class _WaveformCard extends StatelessWidget {
  const _WaveformCard({required this.animation, required this.tint});

  final Animation<double> animation;
  final Color tint;

  static const int _barCount = 27;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value * 2 * pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barCount, (i) {
              final wave = sin(t * 2 + i * 0.55) * 0.5 +
                  sin(t * 3.1 + i * 1.3) * 0.5;
              final h = 12 + (wave.abs() * 44);
              return Container(
                width: 4,
                height: h.clamp(6.0, 58.0),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.35 + wave.abs() * 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ── Composite threat banner ──────────────────────────────────────────

class _CompositeBanner extends StatelessWidget {
  const _CompositeBanner({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    final color = AppColors.forThreat(score);

    final (String headline, String detail, IconData icon) = score >= 0.7
        ? (
            '${AppStrings.bannerThreat}: $pct% High Risk',
            AppStrings.bannerThreatDetail,
            Icons.gpp_maybe_outlined,
          )
        : score >= 0.4
            ? (
                '${AppStrings.bannerElevated}: $pct%',
                AppStrings.bannerElevatedDetail,
                Icons.warning_amber_rounded,
              )
            : (
                '${AppStrings.bannerProtected}: $pct%',
                AppStrings.bannerProtectedDetail,
                Icons.verified_user_outlined,
              );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.65), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: AppTypography.titleMedium.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(detail, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── LIVE badge ───────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.statusSafe.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.statusSafe.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
            child: const Icon(
              Icons.circle,
              size: 8,
              color: AppColors.statusSafe,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            AppStrings.liveBadge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.statusSafe,
            ),
          ),
        ],
      ),
    );
  }
}
