import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/audio/pcm_codec.dart';
import '../../../forensics/domain/models/incident_report.dart';
import '../../../forensics/domain/services/incident_repository.dart';
import '../../../protection/domain/models/audio_forensic_metrics.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/domain/models/semantic_threat_signals.dart';
import '../../../protection/domain/models/transcript_snippet.dart';
import '../../../protection/domain/services/acoustic_forensics_service.dart';
import '../../../protection/domain/services/semantic_threat_service.dart';
import '../../../protection/domain/services/threat_fusion_engine.dart';
import '../models/recording_models.dart';
import 'recorded_transcription_service.dart';
import 'recording_audio_decoder.dart';

/// Orchestrates Analyze Recording: normalize → acoustic pass →
/// optional transcription → semantic pass → fuse → persist.
///
/// This deliberately REUSES the same engines as SafeCall —
/// `AcousticForensicsService`, `SemanticThreatService`,
/// `ThreatFusionEngine` — so a future fusion change affects both
/// paths identically. No parallel thresholds or weights live here.
///
/// Acoustic aggregation mirrors SafeCall: each fixed-size PCM chunk is
/// scored by the same `analyze()` call and folded into an EMA with
/// the same smoothing factor (0.35). The representative snapshot is
/// the smoothed metrics at the recording's PEAK synthetic-voice
/// score — the recording analogue of SafeCall's "snapshot at peak
/// risk", not a raw max of single-chunk scores and not just the first
/// seconds of audio.
final class RecordingAnalyzer {
  RecordingAnalyzer({
    IRecordingAudioDecoder? decoder,
    SemanticThreatService? semanticService,
    IAcousticAnalyzer? acousticService,
    ThreatFusionEngine? fusionEngine,
    IRecordedTranscriptionService? transcriptionService,
    IIncidentRepository? incidentRepository,
    @visibleForTesting Duration pollInterval = _defaultPollInterval,
  })  : _pollInterval = pollInterval,
        _decoder = decoder ?? const PluginRecordingAudioDecoder(),
        _semantic = semanticService ?? SemanticThreatService(),
        _acoustic = acousticService ?? AcousticForensicsService(),
        _fusion = fusionEngine ?? ThreatFusionEngine(),
        _transcription =
            transcriptionService ?? RecordedTranscriptionLocator.instance,
        _incidents = incidentRepository ?? IncidentRepositoryLocator.instance;

  /// Hackathon-safe bounds — everything is decoded in memory.
  static const maxSourceBytes = 25 * 1024 * 1024; // 25 MB
  static const maxDuration = Duration(minutes: 15);

  /// Stable chunk size matched to the acoustic FFT pipeline (which
  /// windows at ≤2048 bins).
  static const chunkSamples = 2048;

  /// Same EMA smoothing SafeCallBloc applies to per-chunk acoustic
  /// metrics.
  static const _acousticSmoothing = 0.35;

  /// Polling cadence / ceiling for prerecorded transcription.
  static const _defaultPollInterval = Duration(seconds: 2);
  static const _pollBudget = Duration(minutes: 3);

  /// Long provider transcripts are trimmed for incident persistence.
  static const _maxStoredTranscriptChars = 6000;

  final IRecordingAudioDecoder _decoder;
  final SemanticThreatService _semantic;
  final IAcousticAnalyzer _acoustic;
  final ThreatFusionEngine _fusion;
  final IRecordedTranscriptionService _transcription;
  final IIncidentRepository _incidents;
  final Duration _pollInterval;
  final Random _rng = Random();

  /// The decoder bound to this analyzer — the UI uses it for the
  /// selected-file metadata probe so summary + analysis always agree.
  IRecordingAudioDecoder get decoder => _decoder;

  /// Whether the enhanced transcription path is configured — gates
  /// the privacy-mode choice in the UI.
  bool get transcriptionConfigured => _transcription.isConfigured;

  /// Runs the full pipeline. Returns `null` when [isCancelled] fires —
  /// a cancelled run is a normal outcome, not an error.
  ///
  /// [mode] selects the privacy path; [manualTranscript] is optional
  /// user-supplied text used for semantic analysis in on-device mode.
  Future<RecordingAnalysisResult?> analyze(
    PickedRecording file, {
    required RecordingPrivacyMode mode,
    String? manualTranscript,
    void Function(RecordingStage stage)? onStage,
    bool Function()? isCancelled,
  }) async {
    bool cancelled() => isCancelled?.call() ?? false;
    void stage(RecordingStage s) => onStage?.call(s);

    // ── Stage 1 · Prepare: bounds → metadata → normalize ──────────
    stage(RecordingStage.preparing);
    if (file.bytes.isEmpty || file.sizeBytes == 0) {
      throw const RecordingAnalysisException(
        'That file appears to be empty.',
        code: 'empty',
      );
    }
    if (file.sizeBytes > maxSourceBytes ||
        file.bytes.length > maxSourceBytes) {
      throw const RecordingAnalysisException(
        'That file is too large — recordings up to 25 MB are '
        'supported.',
        code: 'tooLarge',
      );
    }
    final info = await _decoder.inspect(file);
    if (info.duration > maxDuration) {
      throw const RecordingAnalysisException(
        'That recording is too long — up to 15 minutes are '
        'supported.',
        code: 'tooLong',
      );
    }
    final pcm = await _decoder.decodeToPcm16(file);
    if (pcm.length < 4) {
      throw const RecordingAnalysisException(
        'The recording decoded to no audio — nothing to analyze.',
        code: 'empty',
      );
    }
    if (cancelled()) return null;

    // SHA-256 over the exact normalized PCM16 bytes fed into the
    // acoustic engine — never the compressed container or filename.
    final digest = sha256.convert(pcm).toString();

    // ── Stage 2 · Acoustic pass over the WHOLE recording ──────────
    stage(RecordingStage.analyzingAcoustic);
    _acoustic.reset();
    var smoothed = const AudioForensicMetrics.zero();
    var peak = smoothed;
    final samples = PcmCodec.pcm16ToSamples(pcm);
    for (var i = 0; i < samples.length; i += chunkSamples) {
      final end = min(i + chunkSamples, samples.length);
      final raw = _acoustic.analyze(samples.sublist(i, end));
      smoothed = smoothed.lerpTo(raw, _acousticSmoothing);
      if (smoothed.syntheticVoiceScore > peak.syntheticVoiceScore) {
        peak = smoothed;
      }
      if (cancelled()) return null;
    }
    final acoustic = peak;

    // ── Stage 3 · Transcript (explicit opt-in paths only) ─────────
    String? transcriptText;
    var transcriptLabel = 'None — acoustic analysis only';
    final manual = manualTranscript?.trim();
    if (mode == RecordingPrivacyMode.enhancedTranscription) {
      if (!_transcription.isConfigured) {
        throw const RecordingAnalysisException(
          'Cloud transcription isn\'t configured in this build. '
          'Acoustic analysis is still available on-device.',
          code: 'transcriptionUnavailable',
        );
      }
      try {
        stage(RecordingStage.uploading);
        final jobId = await _transcription.submitJob(
          file.bytes,
          formatHint: file.extension,
        );
        stage(RecordingStage.transcribing);
        transcriptText = await _poll(jobId, cancelled);
        transcriptLabel = 'AssemblyAI Pre-recorded';
      } on RecordingTranscriptionStopped {
        // Cancelled mid-flight — fall through to a truthful partial
        // result rather than discarding completed acoustic work.
      } on RecordedTranscriptionException {
        // Provider/relay failure degrades to partial — never fake
        // transcript text.
      }
      if (cancelled()) return null;
    } else if (manual != null && manual.isNotEmpty) {
      // On-device mode only — the privacy-conscious path: audio stays
      // local, the user's own text feeds the semantic engine.
      transcriptText = manual;
      transcriptLabel = 'User-provided transcript';
    }

    // ── Stage 4 · Semantic pass (only with real transcript) ───────
    SemanticThreatSignals? semantic;
    CompositeThreatReport? report;
    if (transcriptText != null && transcriptText.trim().isNotEmpty) {
      stage(RecordingStage.evaluatingConversation);
      semantic = await _semantic.analyze(transcriptText);
      report = _fusion.fuse(acoustic, semantic);
    }
    if (cancelled()) return null;

    // ── Stage 5 · Build + persist flagged results ─────────────────
    stage(RecordingStage.buildingResult);
    final incident = await _maybePersist(
      file: file,
      info: info,
      acoustic: acoustic,
      semantic: semantic,
      report: report,
      digest: digest,
      transcriptText: transcriptText,
      transcriptLabel: transcriptLabel,
    );

    return RecordingAnalysisResult(
      fileName: file.name,
      format: info.format.isNotEmpty ? info.format : file.extension,
      sizeBytes: file.sizeBytes,
      duration: info.duration,
      acousticMetrics: acoustic,
      audioDigestSha256: digest,
      transcriptText: transcriptText,
      transcriptSourceLabel: transcriptLabel,
      semanticSignals: semantic,
      report: report,
      incident: incident,
    );
  }

  /// Polls until completed/failed, the budget expires, or the caller
  /// cancels. Budget expiry is a failure — not fabricated text.
  Future<String> _poll(String jobId, bool Function() cancelled) async {
    final deadline = DateTime.now().add(_pollBudget);
    while (DateTime.now().isBefore(deadline)) {
      if (cancelled()) throw const RecordingTranscriptionStopped();
      await Future<void>.delayed(_pollInterval);
      if (cancelled()) throw const RecordingTranscriptionStopped();
      final job = await _transcription.pollJob(jobId);
      switch (job.status) {
        case RecordedTranscriptionStatus.completed:
          final text = job.text?.trim() ?? '';
          if (text.isEmpty) {
            throw const RecordedTranscriptionException(
                'Provider returned an empty transcript.');
          }
          return text;
        case RecordedTranscriptionStatus.failed:
          throw const RecordedTranscriptionException(
              'The transcription provider could not process the '
              'recording.');
        case RecordedTranscriptionStatus.queued:
        case RecordedTranscriptionStatus.processing:
          continue;
      }
    }
    throw const RecordedTranscriptionException(
        'Transcription timed out — the acoustic result is still '
        'shown.');
  }

  /// Persistence rules:
  ///  - full analysis at suspicious/highRisk → normal incident;
  ///  - full analysis at safe → NOT persisted (no clutter);
  ///  - acoustic-only partial → persisted ONLY when the synthetic-voice
  ///    score is substantially elevated, and is explicitly labelled a
  ///    partial analysis — never a normal verdict.
  Future<IncidentReport?> _maybePersist({
    required PickedRecording file,
    required RecordingAudioInfo info,
    required AudioForensicMetrics acoustic,
    required SemanticThreatSignals? semantic,
    required CompositeThreatReport? report,
    required String digest,
    required String? transcriptText,
    required String transcriptLabel,
  }) async {
    if (report != null) {
      if (report.riskLevel == ThreatRiskLevel.safe) return null;
      final incident = _buildIncident(
        info: info,
        acoustic: acoustic,
        semantic: semantic!,
        report: report,
        digest: digest,
        transcriptText: transcriptText!,
        transcriptLabel: transcriptLabel,
        riskLevel: report.riskLevel,
        reasons: report.primaryThreatReasons,
        isPartial: false,
      );
      await _incidents.saveIncident(incident);
      return incident;
    }
    // Partial path — acoustic only.
    if (!acoustic.isSyntheticElevated) return null;
    final incident = _buildIncident(
      info: info,
      acoustic: acoustic,
      semantic: const SemanticThreatSignals.empty(),
      report: null,
      digest: digest,
      transcriptText: null,
      transcriptLabel: transcriptLabel,
      riskLevel: ThreatRiskLevel.suspicious,
      reasons: const [
        'Elevated acoustic anomalies — conversation-risk signals '
            'were not analyzed',
      ],
      isPartial: true,
    );
    await _incidents.saveIncident(incident);
    return incident;
  }

  IncidentReport _buildIncident({
    required RecordingAudioInfo info,
    required AudioForensicMetrics acoustic,
    required SemanticThreatSignals semantic,
    required CompositeThreatReport? report,
    required String digest,
    required String? transcriptText,
    required String transcriptLabel,
    required ThreatRiskLevel riskLevel,
    required List<String> reasons,
    required bool isPartial,
  }) {
    final text = transcriptText;
    return IncidentReport(
      id: 'INC-${DateTime.now().year}-${1000 + _rng.nextInt(9000)}',
      timestamp: DateTime.now(),
      // Honest provenance — an uploaded recording is never a caller
      // and never "Live Microphone".
      callerLabel: 'Uploaded Recording',
      callDurationSeconds: info.duration.inSeconds,
      audioDigestSha256: digest,
      audioSourceLabel: 'Uploaded Recording',
      transcriptionSourceLabel: transcriptLabel,
      peakRiskScore:
          report?.compositeRiskScore ?? acoustic.syntheticVoiceScore,
      riskLevel: riskLevel,
      threatReasons: reasons,
      acousticMetrics: acoustic,
      semanticSignals: semantic,
      transcriptSnippets: [
        if (text != null && text.isNotEmpty)
          TranscriptSnippet(
            speaker: 'Recording',
            text: text.length > _maxStoredTranscriptChars
                ? '${text.substring(0, _maxStoredTranscriptChars)}…'
                : text,
            timestamp: DateTime.now(),
          ),
      ],
      recommendedActions: const [
        'Do not send money or share OTPs/PINs based on this recording',
        'Verify the speaker through a number you already trust',
        'Contact the relevant bank/carrier/authority if needed',
      ],
      analysisIsPartial: isPartial,
    );
  }
}

/// Internal control-flow marker — local cancel while a provider job
/// may still be processing remotely.
final class RecordingTranscriptionStopped implements Exception {
  const RecordingTranscriptionStopped();
}
