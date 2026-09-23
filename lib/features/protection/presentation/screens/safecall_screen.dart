import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/threat_phrase_highlighter.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/semantic_threat_signals.dart';
import '../../domain/models/transcript_snippet.dart';
import '../bloc/safecall_bloc.dart';
import '../bloc/safecall_event.dart';
import '../bloc/safecall_state.dart';
import '../widgets/signal_lens.dart';
import '../widgets/threat_meter_card.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/services/haptics/app_haptics.dart';
import '../../../../core/services/preferences/app_preferences.dart';
import '../../../../core/widgets/chrome.dart';
import '../../../../core/widgets/surfaces.dart';

/// SafeCall active-session screen.
///
/// Hierarchy: Signal Lens (state) → human interpretation → evidence →
/// transcript → collapsed technical metrics. Raw DSP never leads.
class SafeCallScreen extends StatelessWidget {
  const SafeCallScreen({super.key, @visibleForTesting this.bloc});

  /// Presentation-test seam — a preloaded bloc (e.g.
  /// `SafeCallBloc.seeded`) for design-state tests. Production always
  /// builds its own.
  final SafeCallBloc? bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => bloc ?? SafeCallBloc(),
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

  /// Escalation haptic — one restrained pulse when the risk band moves
  /// upward. Never continuous vibration during monitoring.
  bool _bandEscalated(SafeCallState prev, SafeCallState curr) =>
      prev is SafeCallMonitoring &&
      curr is SafeCallMonitoring &&
      curr.report.riskLevel.index > prev.report.riskLevel.index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocConsumer<SafeCallBloc, SafeCallState>(
      listenWhen: (prev, current) =>
          current is SafeCallEnded || _bandEscalated(prev, current),
      listener: (context, state) {
        if (state is SafeCallEnded) {
          Navigator.of(context).pop(state);
        } else {
          AppHaptics.confirm();
        }
      },
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

        // The conversation layer exists only after the semantic
        // engine has COMPLETED an analysis — caller text, a visible
        // partial and STT liveness all arrive before that, and an
        // acoustic-only composite must never render as a fused
        // verdict (semantic×0.65 caps it at 0.35 → a false SAFE even
        // when acoustic anomalies are elevated).
        final conversationAnalyzed =
            monitoring?.semanticAnalysisHasRun ?? false;
        final semanticScore =
            conversationAnalyzed ? semantic.combinedScore : null;
        final acousticElevated = acoustic?.isSyntheticElevated ?? false;
        // Supporting copy for the incomplete state — honest about
        // WHY there is no conversation signal (plan gate vs pending).
        final partialSupport = (!isDemo && !sttEntitled)
            ? l10n.acousticOnlyMonitoring
            : l10n.conversationNotAnalyzed;

        return Scaffold(
          // Frosted chrome over the session content; the ambient
          // field drifts toward danger at HIGH RISK — atmospheric,
          // not alarming.
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: Text(l10n.safeCallTitle),
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
          body: Stack(
            children: [
              AmbientBackground(
                tint: p.statusDanger,
                tintAlpha:
                    report.riskLevel == ThreatRiskLevel.highRisk
                        ? 0.55
                        : 0.0,
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) =>
                            SingleChildScrollView(
                          // SafeArea carries the app-bar inset — only
                          // breathing room is added here. Spacers lift
                          // the session cluster so the lens reads as
                          // suspended rather than top-anchored.
                          padding: const EdgeInsets.fromLTRB(
                              20, 4, 20, 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: c.maxHeight - 28),
                            child: IntrinsicHeight(
                              child: Column(
                                children: [
                      const Spacer(),
                      _CallerCard(
                        durationLabel: _durationLabel,
                        onEndCall: () => context
                            .read<SafeCallBloc>()
                            .add(const EndCallEvent()),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: SignalLens(
                          score: score,
                          semanticScore: semanticScore,
                          acousticScore:
                              acoustic?.syntheticVoiceScore ?? 0,
                          conversationAnalyzed: conversationAnalyzed,
                          amplitude: amplitude,
                          isDemoAudio: isDemo,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Human interpretation — the message first,
                      // the number second. In acoustic-only scope this
                      // slot explains the missing signal instead of
                      // printing a fused-band interpretation.
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            conversationAnalyzed
                                ? SignalLens.interpretation(
                                    score, context.l10n)
                                : partialSupport,
                            key: ValueKey(conversationAnalyzed
                                ? SignalLens.stateLabel(
                                    score, context.l10n)
                                : 'acoustic-only'),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: conversationAnalyzed
                                  ? p.forThreat(score)
                                  : (acousticElevated
                                      ? p.statusWarning
                                      : p.textMuted),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (report.primaryThreatReasons.isNotEmpty &&
                          report.riskLevel != ThreatRiskLevel.safe) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            context.threatReason(
                                report.primaryThreatReasons.first),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Demo control lives in-flow beside the demo
                      // provenance — a floating action button here
                      // would cover the safety CTA on real phones.
                      if (isDemo)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: FilledButton.icon(
                              onPressed: () {
                                AppHaptics.tap();
                                context.read<SafeCallBloc>().add(
                                    const SimulateDemoAttackEvent());
                              },
                              icon: Icon(
                                demoActive
                                    ? Icons.stop
                                    : Icons.science_outlined,
                                size: 16,
                              ),
                              label: Text(
                                demoActive
                                    ? l10n.stopSimulation
                                    : l10n.simulateScam,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: demoActive
                                    ? p.statusDanger
                                    : p.bgElevated,
                                foregroundColor: demoActive
                                    ? Colors.white
                                    : p.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8),
                              ),
                            ),
                          ),
                        ),
                      if (semantic.evidenceCategories.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final e in semantic.evidenceCategories)
                                _EvidenceChip(category: e),
                            ],
                          ),
                        ),
                      _TranscriptFeed(
                        snippets: transcript,
                        flaggedPhrases: semantic.flaggedPhrases,
                        demoActive: demoActive,
                        partial: partial,
                        transcriptionLive: sttLive,
                        transcriptionEntitled: sttEntitled,
                        isDemoSession: isDemo,
                      ),
                      const SizedBox(height: 16),
                      _TechnicalDetails(
                        waveAnimation: _waveController,
                        tint: p.forThreat(score),
                        amplitude: amplitude,
                        syntheticScore:
                            acoustic?.syntheticVoiceScore ?? 0,
                        semantic: semantic,
                      ),
                      const Spacer(flex: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                _SessionActionBar(
                  report: report,
                  conversationAnalyzed: conversationAnalyzed,
                  acousticElevated: acousticElevated,
                  onEndCall: () => context
                      .read<SafeCallBloc>()
                      .add(const EndCallEvent()),
                ),
                  ],
                ),
              ),
            ],
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
    final p = context.palette;
    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.hearing,
            color: p.textMuted,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.safeCallActive,
                  style: AppTypography.labelSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${l10n.unknownCaller} · $durationLabel',
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
                  width: context.isGuided ? 60 : 48,
                  height: context.isGuided ? 60 : 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.statusDanger,
                  ),
                  child: Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: context.isGuided ? 26 : 22,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(l10n.endCall, style: AppTypography.labelSmall),
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
    required this.demoActive,
    required this.partial,
    required this.transcriptionLive,
    required this.transcriptionEntitled,
    required this.isDemoSession,
  });

  final List<TranscriptSnippet> snippets;
  final List<String> flaggedPhrases;
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
      return l10n.transcriptDemoPending;
    }
    if (widget.transcriptionLive) return l10n.transcriptListening;
    return widget.transcriptionEntitled
        ? l10n.transcriptNoLive
        : l10n.acousticProtectionActive;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      radius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.subtitles_outlined,
                    size: 18,
                    color: p.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.liveTranscript,
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
                            .copyWith(color: p.accent),
                      ),
                    ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: p.textMuted,
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
    final p = context.palette;
    final isCaller = snippet.speaker == l10n.speakerCaller;
    final style = AppTypography.bodyLarge
        .copyWith(fontSize: 13.5, color: p.textPrimary);
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
                    isCaller ? p.statusWarning : p.statusSafe,
              ),
            ),
          ),
          Expanded(
            // Text.rich inherits DefaultTextStyle so transcript spans
            // pick up the ambient font family + fallback list.
            child: Text.rich(
              textDirection: isRtlText(snippet.text)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              TextSpan(
                style: style,
                children: buildThreatSpans(
                  snippet.text,
                  flaggedPhrases,
                  baseStyle: style,
                  palette: context.palette,
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
    final p = context.palette;
    final (color, icon) = switch (category) {
      EvidenceCategory.impersonation => (
          p.statusDanger,
          Icons.person_search_outlined
        ),
      EvidenceCategory.moneyRequest => (
          p.statusDanger,
          Icons.payments_outlined
        ),
      EvidenceCategory.urgency => (
          p.statusWarning,
          Icons.priority_high
        ),
      EvidenceCategory.secrecy => (
          p.statusWarning,
          Icons.visibility_off_outlined
        ),
    };
    return StatusPill(
      color: color,
      label: context.evidenceLabel(category.label),
      icon: icon,
    );
  }
}

// ── Technical details (collapsed by default) ─────────────────────────

/// Deeper metrics — real signal data, but visually secondary. The
/// waveform lives here too: it is real amplitude data, not ornament,
/// so it belongs with the technical layer rather than the headline.
class _TechnicalDetails extends StatefulWidget {
  const _TechnicalDetails({
    required this.waveAnimation,
    required this.tint,
    required this.amplitude,
    required this.syntheticScore,
    required this.semantic,
  });

  final Animation<double> waveAnimation;
  final Color tint;
  final double amplitude;
  final double syntheticScore;
  final SemanticThreatSignals semantic;

  @override
  State<_TechnicalDetails> createState() => _TechnicalDetailsState();
}

class _TechnicalDetailsState extends State<_TechnicalDetails> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      radius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    Icons.biotech_outlined,
                    size: 18,
                    color: p.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.technicalDetails,
                      style: AppTypography.labelSmall,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: p.textMuted,
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
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                children: [
                  _WaveformCard(
                    animation: widget.waveAnimation,
                    tint: widget.tint,
                    amplitude: widget.amplitude,
                  ),
                  const SizedBox(height: 12),
                  ThreatMeterCard(
                    title: l10n.signalSynthetic,
                    value: widget.syntheticScore,
                    icon: Icons.record_voice_over_outlined,
                    style: ThreatMeterStyle.status,
                    normalLabel: l10n.statusNormal,
                    elevatedLabel: l10n.statusElevated,
                  ),
                  const SizedBox(height: 10),
                  ThreatMeterCard(
                    title: l10n.signalUrgency,
                    value: widget.semantic.urgencyScore,
                    icon: Icons.priority_high,
                    normalLabel: l10n.statusNormal,
                    elevatedLabel: l10n.statusElevated,
                  ),
                  const SizedBox(height: 10),
                  ThreatMeterCard(
                    title: l10n.signalFinancial,
                    value: widget.semantic.financialDemandScore,
                    icon: Icons.payments_outlined,
                    normalLabel: l10n.statusNormal,
                    elevatedLabel: l10n.statusElevated,
                  ),
                  const SizedBox(height: 10),
                  ThreatMeterCard(
                    title: l10n.signalSecrecy,
                    value: widget.semantic.secrecyScore,
                    icon: Icons.visibility_off_outlined,
                    normalLabel: l10n.statusNormal,
                    elevatedLabel: l10n.statusElevated,
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
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

  /// Real RMS amplitude from the audio pipeline. Bars scale with it —
  /// motion reflects actual stream data, not a decorative loop.
  final double amplitude;

  static const int _barCount = 27;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final amp = amplitude.clamp(0.0, 1.0);
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.bgBase.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.borderSubtle.withValues(alpha: 0.7)),
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

// ── Session action bar ───────────────────────────────────────────────

/// Bottom action surface — calm by default; at high risk it becomes
/// the PAUSE → VERIFY moment: a human decision, not an alarm.
class _SessionActionBar extends StatelessWidget {
  const _SessionActionBar({
    required this.report,
    required this.conversationAnalyzed,
    required this.acousticElevated,
    required this.onEndCall,
  });

  final CompositeThreatReport report;

  /// Whether conversation/semantic evidence exists this session —
  /// the calm strip must not claim "all signals nominal" while a
  /// whole signal layer is missing.
  final bool conversationAnalyzed;

  /// Whether the acoustic layer alone reads elevated.
  final bool acousticElevated;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final score = report.compositeRiskScore;
    final color = p.forThreat(score);
    final highRisk = report.riskLevel == ThreatRiskLevel.highRisk;

    if (!highRisk) {
      // Calm strip — a quiet status line, not a competing banner.
      final stripColor = !conversationAnalyzed
          ? (acousticElevated
              ? p.statusWarning
              : p.textMuted)
          : color;
      final stripText = !conversationAnalyzed
          ? (acousticElevated
              ? l10n.bannerAcousticElevated
              : l10n.bannerAcousticOnly)
          : report.riskLevel == ThreatRiskLevel.suspicious
              ? (report.primaryThreatReasons.firstOrNull == null
                  ? l10n.bannerElevatedDetail
                  : context.threatReason(
                      report.primaryThreatReasons.first))
              : l10n.bannerProtectedDetail;
      return SurfaceCard(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        radius: 16,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              !conversationAnalyzed
                  ? Icons.graphic_eq
                  : report.riskLevel == ThreatRiskLevel.suspicious
                      ? Icons.visibility_outlined
                      : Icons.check_circle_outline,
              color: stripColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                stripText,
                style: AppTypography.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    // HIGH RISK — clarity, not panic. The primary next step is a
    // human verification, ending the session first. A lifted,
    // danger-tinted glass panel — serious without flooding the
    // screen in red.
    return SurfaceCard(
      elevated: true,
      radius: 20,
      tint: p.statusDanger,
      tintAlpha: 0.10,
      borderColor: p.statusDanger.withValues(alpha: 0.55),
      borderWidth: 1.3,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.verifyBeforeYouAct,
            style: AppTypography.titleLarge.copyWith(
              color: p.statusDanger,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.callSavedNumberHint,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () {
                AppHaptics.tap();
                onEndCall();
              },
              icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: Text(
                l10n.endCallAndVerify,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: p.statusDanger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '…',
              style: TextStyle(color: p.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              text,
              textDirection:
                  isRtlText(text) ? TextDirection.rtl : TextDirection.ltr,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 13.5,
                color: p.textMuted,
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
    final p = context.palette;
    final error = state is SafeCallError ? state as SafeCallError : null;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l10n.safeCallTitle)),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
            Center(
              child: SurfaceCard(
                radius: 42,
                elevated: true,
                tint: p.accent,
                tintAlpha: 0.10,
                padding: const EdgeInsets.all(20),
                child: Icon(Icons.graphic_eq,
                    size: 44, color: p.accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.safeCallPickerTitle,
              style: AppTypography.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.safecallIntro,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _ModeCard(
              icon: Icons.mic,
              title: l10n.modeLiveMic,
              description: l10n.modeLiveMicDesc,
              accent: p.statusSafe,
              badge: l10n.modeLiveMicBadge,
              primary: true,
              onTap: () {
                AppHaptics.tap();
                context
                    .read<SafeCallBloc>()
                    .add(const StartLiveMicSessionEvent());
              },
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.science_outlined,
              title: l10n.modeDemo,
              description: l10n.modeDemoDesc,
              accent: p.accent,
              badge: l10n.modeDemoBadge,
              primary: false,
              onTap: () {
                AppHaptics.tap();
                context
                    .read<SafeCallBloc>()
                    .add(const StartDemoSessionEvent());
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 20),
              SurfaceCard(
                radius: 14,
                padding: const EdgeInsets.all(14),
                tint: p.statusWarning,
                tintAlpha: 0.08,
                borderColor: p.statusWarning.withValues(alpha: 0.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: p.statusWarning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(context.serviceMessage(error.message),
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
                    label: Text(l10n.actionOpenSystemSettings),
                  ),
                ),
            ],
              ],
            ),
          ),
        ],
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
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final String badge;

  /// The real-session card is visually dominant; the demo card stays
  /// deliberately secondary so a demonstration can never look like
  /// captured real evidence.
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      child: SurfaceCard(
        radius: 20,
        elevated: primary,
        tint: accent,
        tintAlpha: primary ? 0.08 : 0.04,
        borderColor: accent.withValues(alpha: primary ? 0.5 : 0.3),
        borderWidth: primary ? 1.3 : 1,
        onTap: onTap,
        padding: EdgeInsets.all(context.isGuided ? 22 : 18),
        child: Row(
          children: [
            // Icon tile — a soft accent halo, not a filled box.
            Container(
              width: context.isGuided ? 60 : 50,
              height: context.isGuided ? 60 : 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.18),
                    accent.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                    color: accent.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, color: accent,
                  size: context.isGuided ? 28 : 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                                fontSize: context.isGuided
                                    ? 17.5
                                    : null)),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        color: accent,
                        label: badge,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: AppTypography.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: p.textMuted),
          ],
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
    return StatusPill(
      color: context.palette.statusDanger,
      label: l10n.modeLiveBadgeShort,
      icon: Icons.mic,
    );
  }
}

// ── DEMO badge — discoverable but unobtrusive ────────────────────────

class _DemoBadge extends StatelessWidget {
  const _DemoBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      color: context.palette.accent,
      label:
          compact ? l10n.demoBadgeCompact : l10n.modeDemoModeLabel,
      icon: Icons.science_outlined,
      compact: compact,
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
    final p = context.palette;
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.statusSafe.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: p.statusSafe.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          reduceMotion
              ? Icon(
                  Icons.circle,
                  size: 8,
                  color: p.statusSafe,
                )
              : FadeTransition(
                  opacity:
                      Tween(begin: 0.35, end: 1.0).animate(_controller),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: p.statusSafe,
                  ),
                ),
          const SizedBox(width: 6),
          Text(
            l10n.liveBadge,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              color: p.statusSafe,
            ),
          ),
        ],
      ),
    );
  }
}
