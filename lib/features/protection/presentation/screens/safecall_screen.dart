import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/transcript_snippet.dart';
import '../bloc/safecall_bloc.dart';
import '../bloc/safecall_event.dart';
import '../bloc/safecall_state.dart';
import '../widgets/threat_meter_card.dart';

/// SafeCall active-call HUD.
///
/// Hosts the [SafeCallBloc] session and binds the live threat radar,
/// transcript feed and composite banner to its state.
class SafeCallScreen extends StatelessWidget {
  const SafeCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SafeCallBloc()..add(const StartCallEvent()),
      child: const _SafeCallView(),
    );
  }
}

class _SafeCallView extends StatefulWidget {
  const _SafeCallView();

  @override
  State<_SafeCallView> createState() => _SafeCallViewState();
}

class _SafeCallViewState extends State<_SafeCallView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  Timer? _clockTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  String get _durationLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SafeCallBloc, SafeCallState>(
      listenWhen: (_, current) => current is SafeCallEnded,
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final monitoring =
            state is SafeCallMonitoring ? state : null;
        final acoustic = monitoring?.acoustic;
        final semantic = monitoring?.semantic;
        final report =
            monitoring?.report ?? const CompositeThreatReport.initial();
        final transcript = monitoring?.transcript ?? const <TranscriptSnippet>[];
        final demoActive = monitoring?.demoActive ?? false;
        final score = report.compositeRiskScore;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.safeCallTitle),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
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
                        onEndCall: () => context
                            .read<SafeCallBloc>()
                            .add(const EndCallEvent()),
                      ),
                      const SizedBox(height: 16),
                      _TranscriptFeed(snippets: transcript),
                      const SizedBox(height: 16),
                      _WaveformCard(
                        animation: _waveController,
                        tint: AppColors.forThreat(score),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        AppStrings.threatRadarTitle,
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(height: 12),
                      ThreatMeterCard(
                        title: AppStrings.signalSynthetic,
                        value: acoustic?.syntheticVoiceScore ?? 0,
                        icon: Icons.record_voice_over_outlined,
                        style: ThreatMeterStyle.status,
                        normalLabel: AppStrings.statusNormal,
                        elevatedLabel: AppStrings.statusElevated,
                      ),
                      const SizedBox(height: 10),
                      ThreatMeterCard(
                        title: AppStrings.signalUrgency,
                        value: semantic?.urgencyScore ?? 0,
                        icon: Icons.priority_high,
                      ),
                      const SizedBox(height: 10),
                      ThreatMeterCard(
                        title: AppStrings.signalFinancial,
                        value: semantic?.financialDemandScore ?? 0,
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 10),
                      ThreatMeterCard(
                        title: AppStrings.signalSecrecy,
                        value: semantic?.secrecyScore ?? 0,
                        icon: Icons.visibility_off_outlined,
                      ),
                    ],
                  ),
                ),
                _CompositeBanner(report: report),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context
                .read<SafeCallBloc>()
                .add(const SimulateDemoAttackEvent()),
            backgroundColor:
                demoActive ? AppColors.statusDanger : AppColors.bgElevated,
            foregroundColor: AppColors.textPrimary,
            icon: Icon(
              demoActive ? Icons.stop : Icons.science_outlined,
            ),
            label: Text(
              demoActive
                  ? AppStrings.stopSimulation
                  : AppStrings.simulateScam,
            ),
          ),
        );
      },
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

// ── Collapsible live transcript feed ─────────────────────────────────

class _TranscriptFeed extends StatefulWidget {
  const _TranscriptFeed({required this.snippets});

  final List<TranscriptSnippet> snippets;

  @override
  State<_TranscriptFeed> createState() => _TranscriptFeedState();
}

class _TranscriptFeedState extends State<_TranscriptFeed> {
  bool _expanded = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(_TranscriptFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snippets.length != oldWidget.snippets.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.subtitles_outlined,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      AppStrings.liveTranscript,
                      style: AppTypography.labelSmall,
                    ),
                  ),
                  if (widget.snippets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${widget.snippets.length}',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: SizedBox(
              height: 132,
              width: double.infinity,
              child: widget.snippets.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        AppStrings.transcriptEmpty,
                        style: AppTypography.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      itemCount: widget.snippets.length,
                      itemBuilder: (context, i) =>
                          _TranscriptLine(snippet: widget.snippets[i]),
                    ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _TranscriptLine extends StatelessWidget {
  const _TranscriptLine({required this.snippet});

  final TranscriptSnippet snippet;

  @override
  Widget build(BuildContext context) {
    final isCaller = snippet.speaker == AppStrings.speakerCaller;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              snippet.speaker,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isCaller ? AppColors.statusWarning : AppColors.statusSafe,
              ),
            ),
          ),
          Expanded(
            child: Text(
              snippet.text,
              textDirection: _isRtl(snippet.text)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              style: AppTypography.bodyLarge
                  .copyWith(fontSize: 13.5, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRtl(String text) =>
      text.isNotEmpty && text.codeUnitAt(0) > 0x0600;
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
  const _CompositeBanner({required this.report});

  final CompositeThreatReport report;

  @override
  Widget build(BuildContext context) {
    final score = report.compositeRiskScore;
    final pct = (score * 100).round();
    final color = AppColors.forThreat(score);

    final (String headline, String detail, IconData icon) =
        switch (report.riskLevel) {
      ThreatRiskLevel.highRisk => (
          '${AppStrings.bannerThreat}: $pct% High Risk',
          report.primaryThreatReasons.firstOrNull ??
              AppStrings.bannerThreatDetail,
          Icons.gpp_maybe_outlined,
        ),
      ThreatRiskLevel.suspicious => (
          '${AppStrings.bannerElevated}: $pct%',
          report.primaryThreatReasons.firstOrNull ??
              AppStrings.bannerElevatedDetail,
          Icons.warning_amber_rounded,
        ),
      ThreatRiskLevel.safe => (
          '${AppStrings.bannerProtected}: $pct%',
          AppStrings.bannerProtectedDetail,
          Icons.verified_user_outlined,
        ),
    };

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
  const _LiveBadge();

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
