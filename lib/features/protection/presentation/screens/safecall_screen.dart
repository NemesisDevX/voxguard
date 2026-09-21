import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/threat_phrase_highlighter.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/semantic_threat_signals.dart';
import '../../domain/models/transcript_snippet.dart';
import '../bloc/safecall_bloc.dart';
import '../bloc/safecall_event.dart';
import '../bloc/safecall_state.dart';
import '../widgets/threat_core.dart';
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
      create: (_) => SafeCallBloc(),
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
  // Eagerly initialized in initState — a lazy field would be created
  // during dispose() if build never touched it, and createTicker on a
  // deactivated element crashes/leaks a ticker.
  late final AnimationController _waveController;

  Timer? _clockTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
      listener: (context, state) => Navigator.of(context).pop(state),
      builder: (context, state) {
        if (state is SafeCallInitial || state is SafeCallError) {
          return _ModePickerView(state: state);
        }
        if (state is SafeCallStarting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final monitoring =
            state is SafeCallMonitoring ? state : null;
        final acoustic = monitoring?.acoustic;
        final semantic =
            monitoring?.semantic ?? const SemanticThreatSignals.empty();
        final report =
            monitoring?.report ?? const CompositeThreatReport.initial();
        final transcript = monitoring?.transcript ?? const <TranscriptSnippet>[];
        final demoActive = monitoring?.demoActive ?? false;
        final amplitude = monitoring?.audioAmplitude ?? 0.0;
        final isDemo = monitoring?.isDemoMode ?? true;
        final sttLive = monitoring?.isTranscriptionLive ?? false;
        final sttEntitled =
            monitoring?.cloudTranscriptionEntitled ?? false;
        final partial = monitoring?.partialTranscript ?? '';
        final score = report.compositeRiskScore;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.safeCallTitle),
            actions: [
              if (isDemo)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Center(child: _DemoBadge()),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Center(child: _LiveMicBadge()),
                ),
              const Padding(
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
                      const SizedBox(height: 20),
                      Center(
                        child: ThreatCore(
                          score: score,
                          amplitude: amplitude,
                          isDemoAudio: isDemo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TranscriptFeed(
                        snippets: transcript,
                        flaggedPhrases: semantic.flaggedPhrases,
                        evidence: semantic.evidenceCategories,
                        demoActive: demoActive,
                        partial: partial,
                        transcriptionLive: sttLive,
                        transcriptionEntitled: sttEntitled,
                        isDemoSession: isDemo,
                      ),
                      const SizedBox(height: 16),
                      _WaveformCard(
                        animation: _waveController,
                        tint: AppColors.forThreat(score),
                        amplitude: amplitude,
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
                        value: semantic.urgencyScore,
                        icon: Icons.priority_high,
                      ),
                      const SizedBox(height: 10),
                      ThreatMeterCard(
                        title: AppStrings.signalFinancial,
                        value: semantic.financialDemandScore,
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 10),
                      ThreatMeterCard(
                        title: AppStrings.signalSecrecy,
                        value: semantic.secrecyScore,
                        icon: Icons.visibility_off_outlined,
                      ),
                    ],
                  ),
                ),
                _CompositeBanner(report: report),
              ],
            ),
          ),
          floatingActionButton: isDemo
              ? FloatingActionButton.extended(
                  onPressed: () => context
                      .read<SafeCallBloc>()
                      .add(const SimulateDemoAttackEvent()),
                  backgroundColor: demoActive
                      ? AppColors.statusDanger
                      : AppColors.bgElevated,
                  foregroundColor: AppColors.textPrimary,
                  icon: Icon(
                    demoActive ? Icons.stop : Icons.science_outlined,
                  ),
                  label: Text(
                    demoActive
                        ? AppStrings.stopSimulation
                        : AppStrings.simulateScam,
                  ),
                )
              : null,
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
  const _TranscriptFeed({
    required this.snippets,
    required this.flaggedPhrases,
    required this.evidence,
    required this.demoActive,
    required this.partial,
    required this.transcriptionLive,
    required this.transcriptionEntitled,
    required this.isDemoSession,
  });

  final List<TranscriptSnippet> snippets;
  final List<String> flaggedPhrases;
  final List<EvidenceCategory> evidence;
  final bool demoActive;

  /// Live uncommitted STT partial — rendered dimmed at the tail.
  final String partial;

  /// Whether a streaming STT provider is active this session.
  final bool transcriptionLive;

  /// Whether the current plan entitles cloud transcription — false
  /// means acoustic-only by plan, not by provider failure.
  final bool transcriptionEntitled;

  /// Whether this is a demo session (scripted transcript).
  final bool isDemoSession;

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

  /// Honest empty-state copy per mode — never implies a live mic
  /// transcript that isn't happening, and never blames a provider
  /// outage for what is actually a plan gate.
  String get _emptyLabel {
    if (widget.isDemoSession) {
      return 'Demo transcript will appear here.';
    }
    if (widget.transcriptionLive) return 'Listening for speech…';
    return widget.transcriptionEntitled
        ? 'Voice analysis active — live transcription unavailable.'
        : AppStrings.acousticProtectionActive;
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
                  if (widget.demoActive)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: _DemoBadge(compact: true),
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
          if (widget.evidence.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in widget.evidence) _EvidenceChip(category: e),
                ],
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
              child: widget.snippets.isEmpty && widget.partial.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _emptyLabel,
                        style: AppTypography.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      itemCount: widget.snippets.length +
                          (widget.partial.isEmpty ? 0 : 1),
                      itemBuilder: (context, i) {
                        if (i == widget.snippets.length) {
                          return _PartialLine(text: widget.partial);
                        }
                        return _TranscriptLine(
                          snippet: widget.snippets[i],
                          flaggedPhrases: widget.flaggedPhrases,
                        );
                      },
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
  const _TranscriptLine({
    required this.snippet,
    required this.flaggedPhrases,
  });

  final TranscriptSnippet snippet;
  final List<String> flaggedPhrases;

  @override
  Widget build(BuildContext context) {
    final isCaller = snippet.speaker == AppStrings.speakerCaller;
    final style = AppTypography.bodyLarge
        .copyWith(fontSize: 13.5, color: AppColors.textPrimary);
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
            child: RichText(
              textDirection: isRtlText(snippet.text)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              text: TextSpan(
                style: style,
                children: buildThreatSpans(
                  snippet.text,
                  flaggedPhrases,
                  baseStyle: style,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Evidence chip derived from [SemanticThreatSignals.evidenceCategories] —
/// explains WHY the score moved without reading raw telemetry.
class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({required this.category});

  final EvidenceCategory category;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (category) {
      EvidenceCategory.impersonation => (
          AppColors.statusDanger,
          Icons.person_search_outlined
        ),
      EvidenceCategory.moneyRequest => (
          AppColors.statusDanger,
          Icons.payments_outlined
        ),
      EvidenceCategory.urgency => (
          AppColors.statusWarning,
          Icons.priority_high
        ),
      EvidenceCategory.secrecy => (
          AppColors.statusWarning,
          Icons.visibility_off_outlined
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: AppTypography.labelSmall
                .copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Live waveform visualizer ─────────────────────────────────────────

class _WaveformCard extends StatelessWidget {
  const _WaveformCard({
    required this.animation,
    required this.tint,
    required this.amplitude,
  });

  final Animation<double> animation;
  final Color tint;

  /// Real RMS amplitude from the audio pipeline (demo PCM in this
  /// build). Bars scale with it — motion reflects actual stream data,
  /// not a decorative loop.
  final double amplitude;

  static const int _barCount = 27;

  @override
  Widget build(BuildContext context) {
    final amp = amplitude.clamp(0.0, 1.0);
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
              final h = 8 + (wave.abs() * (14 + amp * 40));
              return Container(
                width: 4,
                height: h.clamp(6.0, 58.0),
                decoration: BoxDecoration(
                  color: tint.withValues(
                      alpha: 0.30 + wave.abs() * (0.25 + amp * 0.45)),
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
          AppStrings.bannerThreat,
          '${AppStrings.threatScoreLabel}: $pct/100 — '
              '${report.primaryThreatReasons.firstOrNull ??
                  AppStrings.bannerThreatDetail}',
          Icons.gpp_maybe_outlined,
        ),
      ThreatRiskLevel.suspicious => (
          '${AppStrings.bannerElevated}: $pct/100',
          report.primaryThreatReasons.firstOrNull ??
              AppStrings.bannerElevatedDetail,
          Icons.warning_amber_rounded,
        ),
      ThreatRiskLevel.safe => (
          '${AppStrings.bannerProtected}: $pct/100',
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

/// Dimmed in-flight STT partial at the tail of the transcript feed.
class _PartialLine extends StatelessWidget {
  const _PartialLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 48,
            child: Text(
              '…',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              text,
              textDirection:
                  isRtlText(text) ? TextDirection.rtl : TextDirection.ltr,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 13.5,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode picker (pre-session) ────────────────────────────────────────

/// Pre-session mode selection — the explicit user intent that starts
/// either a real microphone protection session or the demo.
class _ModePickerView extends StatelessWidget {
  const _ModePickerView({required this.state});

  final SafeCallState state;

  @override
  Widget build(BuildContext context) {
    final error = state is SafeCallError ? state as SafeCallError : null;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.safeCallTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const Icon(Icons.shield_outlined,
                size: 56, color: AppColors.statusSafe),
            const SizedBox(height: 16),
            const Text(
              'Start a Protection Session',
              style: AppTypography.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'VoxGuard listens through your microphone for '
              'suspicious voice and conversation patterns.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _ModeCard(
              icon: Icons.mic,
              title: 'Live Mic',
              description:
                  'Analyze real microphone audio — speakerphone calls '
                  'or a voice played nearby.',
              accent: AppColors.statusSafe,
              badge: 'LIVE MIC',
              onTap: () => context
                  .read<SafeCallBloc>()
                  .add(const StartLiveMicSessionEvent()),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.science_outlined,
              title: 'Demo Attack',
              description:
                  'Run the scripted judging scenario — generated '
                  'audio and demo transcript.',
              accent: AppColors.accent,
              badge: 'DEMO',
              onTap: () => context
                  .read<SafeCallBloc>()
                  .add(const StartDemoSessionEvent()),
            ),
            if (error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusWarning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.statusWarning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.statusWarning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(error.message,
                          style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
              if (error.permanentlyDenied)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text('Open System Settings'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    // ignore: unawaited_futures
    openAppSettings();
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: AppTypography.titleMedium),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(description, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── LIVE MIC badge ───────────────────────────────────────────────────

class _LiveMicBadge extends StatelessWidget {
  const _LiveMicBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.statusDanger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.statusDanger.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, size: 11, color: AppColors.statusDanger),
          SizedBox(width: 4),
          Text(
            'LIVE MIC',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.statusDanger,
            ),
          ),
        ],
      ),
    );
  }
}

// ── DEMO badge — discoverable but unobtrusive ────────────────────────

class _DemoBadge extends StatelessWidget {
  const _DemoBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science_outlined,
            size: compact ? 10 : 12,
            color: AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            compact ? 'DEMO' : 'DEMO MODE',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.accent,
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
