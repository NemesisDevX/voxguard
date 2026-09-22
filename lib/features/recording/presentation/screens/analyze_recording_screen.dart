import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/threat_phrase_highlighter.dart';
import '../../../forensics/presentation/screens/incident_detail_screen.dart';
import '../../../paywall/domain/models/entitlement_state.dart';
import '../../../paywall/domain/models/subscription_tier.dart';
import '../../../paywall/domain/services/product_access.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../../protection/domain/models/audio_forensic_metrics.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../domain/models/recording_models.dart';
import '../../domain/services/recording_analyzer.dart';
import '../../domain/services/recording_file_picker.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';
import '../../../../core/theme/app_palette.dart';

/// Analyze Recording — pick a local audio file, choose a privacy
/// mode, and run the same VoxGuard threat engines SafeCall uses.
///
/// Honest contract:
///  - on-device mode uploads nothing — acoustic analysis only (plus
///    optional user-supplied transcript text for the semantic engine);
///  - enhanced mode sends the recording through VoxGuard's
///    transcription relay only after an explicit user choice;
///  - acoustic-only output is labelled "Partial Analysis" — never a
///    normal SAFE verdict or composite Threat Score;
///  - no microphone or notification permission is touched here.
class AnalyzeRecordingScreen extends StatefulWidget {
  const AnalyzeRecordingScreen({
    super.key,
    this.picker,
    this.analyzer,
    this.productAccess,
  });

  /// Injectable seams — tests supply fakes so no platform channel or
  /// network is touched.
  final IRecordingFilePicker? picker;
  final RecordingAnalyzer? analyzer;
  final IProductAccess? productAccess;

  @override
  State<AnalyzeRecordingScreen> createState() =>
      _AnalyzeRecordingScreenState();
}

class _AnalyzeRecordingScreenState extends State<AnalyzeRecordingScreen> {
  late final IRecordingFilePicker _picker =
      widget.picker ?? const FilePickerRecordingPicker();
  late final RecordingAnalyzer _analyzer =
      widget.analyzer ??
          RecordingAnalyzer(productAccess: widget.productAccess);
  late final IProductAccess _productAccess =
      widget.productAccess ?? ProductAccessLocator.instance;

  PickedRecording? _picked;
  RecordingAudioInfo? _info;
  RecordingPrivacyMode _mode = RecordingPrivacyMode.onDevice;
  final _manualTranscript = TextEditingController();
  bool _showManualTranscript = false;

  bool _busy = false;
  bool _cancelRequested = false;
  RecordingStage? _stage;

  /// Stages the analyzer has actually reached this run, in order.
  /// The progress card renders ONLY these — a stage the pipeline
  /// skipped (e.g. conversation analysis with no transcript) can
  /// never appear, let alone look completed.
  final List<RecordingStage> _stagesRun = [];
  RecordingAnalysisResult? _result;
  String? _error;

  @override
  void dispose() {
    _manualTranscript.dispose();
    _picked = null; // release selected bytes with the screen
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> _chooseAudio() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final file = await _picker.pickRecording();
      if (!mounted || file == null) return; // cancel is normal
      // Probe metadata up front so the summary shows duration —
      // an unreadable container fails here, not mid-analysis.
      final info = await _analyzer.decoder.inspect(file);
      if (!mounted) return;
      setState(() {
        _picked = file;
        _info = info;
        _error = null;
      });
    } on RecordingAnalysisException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runAnalysis() async {
    final file = _picked;
    if (file == null || _busy) return;
    setState(() {
      _busy = true;
      _cancelRequested = false;
      _stage = RecordingStage.preparing;
      _stagesRun.clear();
      _error = null;
      _result = null;
    });
    try {
      final result = await _analyzer.analyze(
        file,
        mode: _mode,
        manualTranscript: _manualTranscript.text,
        onStage: (s) {
          if (mounted) {
            setState(() {
              _stage = s;
              if (_stagesRun.isEmpty || _stagesRun.last != s) {
                _stagesRun.add(s);
              }
            });
          }
        },
        isCancelled: () => _cancelRequested || !mounted,
      );
      if (!mounted) return;
      setState(() {
        if (result == null) {
          _stage = null; // cancelled — back to the summary
        } else {
          _result = result;
          _picked = null; // release source bytes — analysis is done
          _info = null;
        }
      });
    } on RecordingAnalysisException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _stage = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancelAnalysis() {
    if (!_busy || _result != null) return;
    setState(() => _cancelRequested = true);
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
  final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyzeRecordingTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            if (_result != null) ..._buildResult(_result!)
            else if (_picked == null) ..._buildEmpty(p)
            else ..._buildSelected(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: _error!),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmpty(AppPalette p) => [
        const SizedBox(height: 8),
        _StepLabel(l10n.stepPickRecording),
        const SizedBox(height: 16),
        Icon(Icons.audio_file_outlined,
            size: 56, color: p.accent),
        const SizedBox(height: 16),
        Text(
          l10n.recordingStepTitle,
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.recordingAnalyzerIntro,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.recordingFormatsHint,
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _chooseAudio,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(l10n.recordingChooseAudio),
        ),
      ];

  List<Widget> _buildSelected() {
    final file = _picked!;
    final info = _info;
    final transcriptionReady = _analyzer.transcriptionConfigured;
    final analyzing = _busy && _stage != null;
    return [
      _StepLabel(l10n.stepPrivacyDepth),
      const SizedBox(height: 10),
      _FileSummaryCard(file: file, info: info),
      const SizedBox(height: 20),
      Text(l10n.recordingPrivacyLabel, style: AppTypography.labelSmall),
      const SizedBox(height: 8),
      _PrivacyModeCard(
        selected: _mode == RecordingPrivacyMode.onDevice,
        enabled: !analyzing,
        title: l10n.recordingKeepLocal,
        subtitle: l10n.recordingKeepLocalDesc,
        onTap: () =>
            setState(() => _mode = RecordingPrivacyMode.onDevice),
      ),
      const SizedBox(height: 8),
      // Reactive: a Sentinel purchase unlocks this card without
      // leaving the screen.
      ValueListenableBuilder<EntitlementState>(
        valueListenable: _productAccess.entitlement,
        builder: (context, entitlement, _) {
          final entitled =
              _productAccess.capabilities.enhancedRecording;
          final unlocked = entitled && transcriptionReady;
          return _PrivacyModeCard(
            selected:
                _mode == RecordingPrivacyMode.enhancedTranscription,
            enabled: unlocked && !analyzing,
            locked: !entitled,
            title: l10n.recordingIncludeConversation,
            subtitle: !entitled
                ? l10n.enhancedModeLockedDesc
                : transcriptionReady
                    ? l10n.enhancedModeReadyDesc
                    : l10n.recordingCloudNotConfigured,
            onTap: () => setState(
                () => _mode = RecordingPrivacyMode.enhancedTranscription),
            onLockedTap: () =>
                PaywallScreen.show(context, preselect: TierId.sentinel),
          );
        },
      ),
      const SizedBox(height: 12),
      // Manual transcript is the on-device alternative — hidden while
      // the enhanced (upload) mode is selected so the two paths never
      // compete.
      if (_mode == RecordingPrivacyMode.onDevice)
        _ManualTranscriptSection(
          expanded: _showManualTranscript,
          controller: _manualTranscript,
          onToggle: () => setState(
              () => _showManualTranscript = !_showManualTranscript),
        ),
      const SizedBox(height: 20),
      if (analyzing) ...[
        _StageProgress(stagesRun: _stagesRun, stage: _stage!),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _cancelAnalysis,
          icon: const Icon(Icons.close),
          label: Text(l10n.recordingCancelAnalysis),
        ),
      ] else ...[
        FilledButton.icon(
          onPressed: _busy ? null : _runAnalysis,
          icon: const Icon(Icons.shield_outlined),
          label: Text(l10n.recordingAnalyzeAction),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _picked = null;
                    _info = null;
                    _error = null;
                  }),
          child: Text(l10n.recordingChooseDifferent),
        ),
      ],
    ];
  }

  List<Widget> _buildResult(RecordingAnalysisResult r) {
    final report = r.report;
    return [
      _StepLabel(l10n.stepResult),
      const SizedBox(height: 10),
      if (report != null) ...[
        _FullResultHeader(report: report),
        const SizedBox(height: 16),
        _ReasonsCard(reasons: report.primaryThreatReasons),
      ] else ...[
        const _PartialResultHeader(),
      ],
      const SizedBox(height: 16),
      _AcousticCard(metrics: r.acousticMetrics, partial: r.isPartial),
      if (r.transcriptText != null &&
          r.transcriptText!.trim().isNotEmpty) ...[
        const SizedBox(height: 16),
        _TranscriptCard(
          label: localizeSourceLabel(l10n, r.transcriptSourceLabel),
          text: r.transcriptText!,
        ),
      ],
      const SizedBox(height: 16),
      _VerificationCard(partial: r.isPartial),
      if (r.incident != null) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  IncidentDetailScreen(incident: r.incident!),
            ),
          ),
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(l10n.recordingViewIncident),
        ),
      ],
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () => setState(() {
          _result = null;
          _error = null;
        }),
        icon: const Icon(Icons.refresh),
        label: Text(l10n.recordingAnalyzeAnother),
      ),
    ];
  }
}

// ── Building blocks ──────────────────────────────────────────────

class _FileSummaryCard extends StatelessWidget {
  const _FileSummaryCard({required this.file, required this.info});

  final PickedRecording file;
  final RecordingAudioInfo? info;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    String size() {
      final mb = file.sizeBytes / (1024 * 1024);
      return mb >= 1
          ? '${mb.toStringAsFixed(1)} MB'
          : '${(file.sizeBytes / 1024).toStringAsFixed(0)} KB';
    }

    String duration() {
      final d = info?.duration;
      if (d == null) return '—';
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return m > 0 ? '$m min ${s}s' : '${d.inSeconds}s';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.audio_file,
                  color: p.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: AppTypography.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Meta('Format', file.extension.toUpperCase()),
              _Meta('Size', size()),
              _Meta('Duration', duration()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(fontSize: 9)),
          Text(value, style: AppTypography.bodyMedium),
        ],
      );
}

class _PrivacyModeCard extends StatelessWidget {
  const _PrivacyModeCard({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
    this.onLockedTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Plan-gated card: tapping opens the upgrade path instead of
  /// selecting the mode.
  final bool locked;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Opacity(
      opacity: enabled || locked ? 1 : 0.55,
      child: Material(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: locked ? onLockedTap : (enabled ? onTap : null),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? p.accent
                    : p.borderSubtle,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  locked
                      ? Icons.lock_outline
                      : selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                  color: selected && !locked
                      ? p.accent
                      : p.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(title,
                                style: AppTypography.titleMedium),
                          ),
                          if (locked) ...[
                            const SizedBox(width: 8),
                            const _SentinelChip(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.bodyMedium
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small "SENTINEL" tag shown on plan-gated cards.
class _SentinelChip extends StatelessWidget {
  const _SentinelChip();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: p.accent.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        context.l10n.recordingSentinelBadge,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: p.accent,
        ),
      ),
    );
  }
}

class _ManualTranscriptSection extends StatelessWidget {
  const _ManualTranscriptSection({
    required this.expanded,
    required this.controller,
    required this.onToggle,
  });

  final bool expanded;
  final TextEditingController controller;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
          ),
          label: Text(l10n.recordingManualTranscript),
        ),
        if (expanded) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recordingManualTranscriptLabel,
                  style: AppTypography.labelSmall,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 3,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: l10n.recordingManualTranscriptHint,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StageProgress extends StatelessWidget {
  const _StageProgress({required this.stagesRun, required this.stage});

  /// Stages the analyzer actually emitted, in order — the rendered
  /// list IS the work performed, never a planned superset.
  final List<RecordingStage> stagesRun;
  final RecordingStage stage;

  static Map<RecordingStage, String> _labels(AppLocalizations l10n) => {
        RecordingStage.preparing: l10n.recordingStagePreparing,
        RecordingStage.analyzingAcoustic: l10n.recordingStageAcoustic,
        RecordingStage.uploading: l10n.recordingStageUploading,
        RecordingStage.transcribing: l10n.recordingStageTranscribing,
        RecordingStage.evaluatingConversation:
            l10n.recordingStageEvaluating,
        RecordingStage.buildingResult: l10n.recordingStageBuilding,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stages =
        stagesRun.isEmpty ? const [RecordingStage.preparing] : stagesRun;
    final current = stages.indexOf(stage);
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (i < current)
                  Icon(Icons.check_circle,
                      size: 16, color: p.statusSafe)
                else if (i == current)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.circle_outlined,
                      size: 16, color: p.textMuted),
                const SizedBox(width: 10),
                Text(
                  _labels(l10n)[stages[i]]!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: i <= current
                        ? p.textPrimary
                        : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FullResultHeader extends StatelessWidget {
  const _FullResultHeader({required this.report});
  final CompositeThreatReport report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final score = (report.compositeRiskScore * 100).round();
    final color = p.forThreat(report.compositeRiskScore);
    final label = switch (report.riskLevel) {
      ThreatRiskLevel.highRisk => l10n.bandHigh,
      ThreatRiskLevel.suspicious => l10n.bandSuspicious,
      ThreatRiskLevel.safe => l10n.bandSafe,
    };
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(l10n.recordingThreatScore,
            style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        Text(
          '$score/100',
          style: AppTypography.titleLarge.copyWith(
            fontSize: 40,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.threatReason(report.recommendedAction),
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

class _PartialResultHeader extends StatelessWidget {
  const _PartialResultHeader();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Deliberately incomplete visual treatment — a dashed outline
    // signals "one signal missing", never a safe-looking verdict.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.statusWarning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      foregroundDecoration: ShapeDecoration(
        shape: _DashedBorder(
          color: p.statusWarning.withValues(alpha: 0.6),
          borderRadius: 16,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.blur_off,
              size: 36, color: p.statusWarning),
          const SizedBox(height: 8),
          Text(
            l10n.bandPartial,
            style: AppTypography.labelSmall
                .copyWith(color: p.statusWarning),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.partialRecordingNote,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AbsentLayerLegend(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Legend row matching the Signal Lens "missing layer" idiom —
/// three broken dashes, not a colored bar.
class _AbsentLayerLegend extends StatelessWidget {
  const _AbsentLayerLegend();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 3.4,
            height: 3,
            margin: const EdgeInsets.only(right: 1.6),
            decoration: BoxDecoration(
              color: p.signalAbsent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        const SizedBox(width: 7),
        Text(
          l10n.recordingConversationAbsent,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: p.signalAbsent,
          ),
        ),
      ],
    );
  }
}

/// Dashed rounded-rect border used only for partial/incomplete
/// states — "in progress" outline, never an alert frame.
class _DashedBorder extends ShapeBorder {
  const _DashedBorder({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()
        ..addRRect(RRect.fromRectAndRadius(
            rect, Radius.circular(borderRadius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  ShapeBorder scale(double t) =>
      _DashedBorder(color: color, borderRadius: borderRadius * t);
}

/// Small numbered-context label introducing each phase of the flow.
class _StepLabel extends StatelessWidget {
  const _StepLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(
          width: 22,
          height: 3,
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: AppTypography.labelSmall),
        ),
      ],
    );
  }
}

class _ReasonsCard extends StatelessWidget {
  const _ReasonsCard({required this.reasons});
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _Card(
      title: l10n.whyFlaggedItTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag_outlined,
                      size: 14, color: p.statusWarning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.threatReason(r),
                        style: AppTypography.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AcousticCard extends StatelessWidget {
  const _AcousticCard({required this.metrics, required this.partial});
  final AudioForensicMetrics metrics;
  final bool partial;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = (metrics.syntheticVoiceScore * 100).round();
    return _Card(
      title: l10n.recordingAcousticSignals,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                partial
                    ? l10n.recordingAcousticScoreLabel
                    : l10n.signalSynthetic,
                style: AppTypography.bodyMedium,
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: AppTypography.titleMedium.copyWith(
                  color: p.forThreat(
                      metrics.syntheticVoiceScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(l10n.metricSpectralFlux, metrics.spectralFlux),
          _Bar(l10n.metricSpectralRolloff, metrics.spectralRolloffRatio),
          _Bar(l10n.metricZeroCrossing, metrics.zeroCrossingRate),
          if (metrics.isSyntheticElevated)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                l10n.acousticAnomalyElevatedNote,
                style: AppTypography.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.labelSmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: p.borderSubtle,
                valueColor: AlwaysStoppedAnimation(
                    p.forThreat(value)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _Card(
      title: l10n.recordingTranscriptLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              textDirection: isRtlText(text)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              textAlign: isRtlText(text) ? TextAlign.right : null,
              style: AppTypography.bodyMedium.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.partial});
  final bool partial;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: l10n.recordingVerifyTitle,
      child: Text(
        partial
            ? l10n.recordingVerifyBody
            : l10n.recordingVerifyNormalBody,
        style: AppTypography.bodyMedium,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.statusDanger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: p.statusDanger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: p.statusDanger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(context.serviceMessage(message),
                style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
