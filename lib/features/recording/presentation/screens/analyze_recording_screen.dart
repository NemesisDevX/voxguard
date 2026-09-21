import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../forensics/presentation/screens/incident_detail_screen.dart';
import '../../../protection/domain/models/audio_forensic_metrics.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../domain/models/recording_models.dart';
import '../../domain/services/recording_analyzer.dart';
import '../../domain/services/recording_file_picker.dart';

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
  });

  /// Injectable seams — tests supply fakes so no platform channel or
  /// network is touched.
  final IRecordingFilePicker? picker;
  final RecordingAnalyzer? analyzer;

  @override
  State<AnalyzeRecordingScreen> createState() =>
      _AnalyzeRecordingScreenState();
}

class _AnalyzeRecordingScreenState extends State<AnalyzeRecordingScreen> {
  late final IRecordingFilePicker _picker =
      widget.picker ?? const FilePickerRecordingPicker();
  late final RecordingAnalyzer _analyzer =
      widget.analyzer ?? RecordingAnalyzer();

  PickedRecording? _picked;
  RecordingAudioInfo? _info;
  RecordingPrivacyMode _mode = RecordingPrivacyMode.onDevice;
  final _manualTranscript = TextEditingController();
  bool _showManualTranscript = false;

  bool _busy = false;
  bool _cancelRequested = false;
  RecordingStage? _stage;
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
      _error = null;
      _result = null;
    });
    try {
      final result = await _analyzer.analyze(
        file,
        mode: _mode,
        manualTranscript: _manualTranscript.text,
        onStage: (s) {
          if (mounted) setState(() => _stage = s);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Analyze Recording')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            if (_result != null) ..._buildResult(_result!)
            else if (_picked == null) ..._buildEmpty()
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

  List<Widget> _buildEmpty() => [
        const SizedBox(height: 24),
        const Icon(Icons.audio_file_outlined,
            size: 56, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text(
          'Analyze a call recording or voice note',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'VoxGuard examines acoustic anomalies and, when you choose '
          'transcription, conversation-risk signals.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — up to 25 MB or '
          '15 minutes.',
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _chooseAudio,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Choose audio'),
        ),
      ];

  List<Widget> _buildSelected() {
    final file = _picked!;
    final info = _info;
    final transcriptionReady = _analyzer.transcriptionConfigured;
    final analyzing = _busy && _stage != null;
    return [
      _FileSummaryCard(file: file, info: info),
      const SizedBox(height: 20),
      const Text('PRIVACY', style: AppTypography.labelSmall),
      const SizedBox(height: 8),
      _PrivacyModeCard(
        selected: _mode == RecordingPrivacyMode.onDevice,
        enabled: !analyzing,
        title: 'Keep audio on this device',
        subtitle:
            'Acoustic analysis runs locally. Nothing is uploaded.',
        onTap: () =>
            setState(() => _mode = RecordingPrivacyMode.onDevice),
      ),
      const SizedBox(height: 8),
      _PrivacyModeCard(
        selected: _mode == RecordingPrivacyMode.enhancedTranscription,
        enabled: transcriptionReady && !analyzing,
        title: 'Include conversation analysis',
        subtitle: transcriptionReady
            ? 'To create a transcript, this recording will be sent '
                'through VoxGuard\u2019s transcription relay to the '
                'configured speech-to-text provider. VoxGuard does '
                'not permanently store the recording.'
            : 'Cloud transcription isn\u2019t configured in this '
                'build. Acoustic analysis is still available '
                'on-device.',
        onTap: () => setState(
            () => _mode = RecordingPrivacyMode.enhancedTranscription),
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
        _StageProgress(stage: _stage!, mode: _mode),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _cancelAnalysis,
          icon: const Icon(Icons.close),
          label: const Text('Cancel analysis'),
        ),
      ] else ...[
        FilledButton.icon(
          onPressed: _busy ? null : _runAnalysis,
          icon: const Icon(Icons.shield_outlined),
          label: const Text('Analyze recording'),
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
          child: const Text('Choose a different file'),
        ),
      ],
    ];
  }

  List<Widget> _buildResult(RecordingAnalysisResult r) {
    final report = r.report;
    return [
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
          label: r.transcriptSourceLabel,
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
          label: const Text('View Incident Report'),
        ),
      ],
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () => setState(() {
          _result = null;
          _error = null;
        }),
        icon: const Icon(Icons.refresh),
        label: const Text('Analyze another recording'),
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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.audio_file,
                  color: AppColors.accent, size: 20),
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
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? AppColors.accent
                      : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleMedium),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
          ),
          label: const Text('Add transcript text instead'),
        ),
        if (expanded) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'USER-PROVIDED TRANSCRIPT',
                  style: AppTypography.labelSmall,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 3,
                  style: AppTypography.bodyMedium,
                  decoration: const InputDecoration(
                    hintText:
                        'Paste transcript text you already have — '
                        'it stays on this device.',
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
  const _StageProgress({required this.stage, required this.mode});

  final RecordingStage stage;
  final RecordingPrivacyMode mode;

  /// Only the stages this mode actually reaches — local-only mode
  /// never shows an upload/transcribe stage.
  List<RecordingStage> get _stages => [
        RecordingStage.preparing,
        RecordingStage.analyzingAcoustic,
        if (mode == RecordingPrivacyMode.enhancedTranscription) ...[
          RecordingStage.uploading,
          RecordingStage.transcribing,
        ],
        RecordingStage.evaluatingConversation,
        RecordingStage.buildingResult,
      ];

  static const _labels = {
    RecordingStage.preparing: 'Preparing audio',
    RecordingStage.analyzingAcoustic: 'Analyzing acoustic signals',
    RecordingStage.uploading: 'Uploading for transcription',
    RecordingStage.transcribing: 'Transcribing conversation',
    RecordingStage.evaluatingConversation:
        'Evaluating conversation risk',
    RecordingStage.buildingResult: 'Building result',
  };

  @override
  Widget build(BuildContext context) {
    final stages = _stages;
    final current = stages.indexOf(stage);
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (i < current)
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.statusSafe)
                else if (i == current)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.circle_outlined,
                      size: 16, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(
                  _labels[stages[i]]!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: i <= current
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
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
    final score = (report.compositeRiskScore * 100).round();
    final color = AppColors.forThreat(report.compositeRiskScore);
    final label = switch (report.riskLevel) {
      ThreatRiskLevel.highRisk => 'HIGH RISK',
      ThreatRiskLevel.suspicious => 'SUSPICIOUS',
      ThreatRiskLevel.safe => 'SAFE',
    };
    return Column(
      children: [
        const SizedBox(height: 8),
        Text('Threat Score',
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
          report.recommendedAction,
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
    return Column(
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.analytics_outlined,
            size: 40, color: AppColors.statusWarning),
        const SizedBox(height: 8),
        Text(
          'PARTIAL ANALYSIS',
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.statusWarning),
        ),
        const SizedBox(height: 8),
        const Text(
          'Conversation-risk signals were not analyzed, so VoxGuard '
          'cannot produce a complete Threat Score.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
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
    return _Card(
      title: 'WHY VOXGUARD FLAGGED IT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_outlined,
                      size: 14, color: AppColors.statusWarning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r, style: AppTypography.bodyMedium),
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
    final pct = (metrics.syntheticVoiceScore * 100).round();
    return _Card(
      title: 'ACOUSTIC ANOMALY SIGNALS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                partial ? 'Acoustic anomaly score' : 'Synthetic voice',
                style: AppTypography.bodyMedium,
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.forThreat(
                      metrics.syntheticVoiceScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Bar('Spectral flux', metrics.spectralFlux),
          _Bar('Spectral rolloff', metrics.spectralRolloffRatio),
          _Bar('Zero-crossing rate', metrics.zeroCrossingRate),
          if (metrics.isSyntheticElevated)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Elevated synthetic-voice indicators detected.',
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
                backgroundColor: AppColors.borderSubtle,
                valueColor: AlwaysStoppedAnimation(
                    AppColors.forThreat(value)),
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
    return _Card(
      title: 'RECORDING TRANSCRIPT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
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
      title: 'VERIFY BEFORE YOU ACT',
      child: Text(
        partial
            ? 'This is an acoustic-only check — the conversation '
                'itself was not analyzed. Never rely on a partial '
                'result to decide a recording is safe: verify the '
                'speaker through a number or channel you already '
                'trust before acting on anything it asks for.'
            : 'A score is a risk signal, not proof. Verify the '
                'speaker through a number you already trust — never '
                'one provided in the recording — before acting on '
                'any request.',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusDanger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.statusDanger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.statusDanger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTypography.bodyMedium),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
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
