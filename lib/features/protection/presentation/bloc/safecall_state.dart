import 'package:equatable/equatable.dart';

import '../../../../core/services/audio/audio_stream_source.dart';
import '../../../forensics/domain/models/incident_report.dart';
import '../../domain/models/audio_forensic_metrics.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/semantic_threat_signals.dart';
import '../../domain/models/transcript_snippet.dart';

/// States for the SafeCall threat-monitoring session.
sealed class SafeCallState extends Equatable {
  const SafeCallState();

  @override
  List<Object?> get props => [];
}

/// Pre-session / idle — the mode picker is showing.
final class SafeCallInitial extends SafeCallState {
  const SafeCallInitial();
}

/// Session is starting (permission request, source/STT spin-up).
final class SafeCallStarting extends SafeCallState {
  const SafeCallStarting({required this.audioSourceType});

  final AudioSourceType audioSourceType;

  @override
  List<Object?> get props => [audioSourceType];
}

/// Live session in progress — carries the full latest sensor snapshot.
final class SafeCallMonitoring extends SafeCallState {
  const SafeCallMonitoring({
    required this.acoustic,
    required this.semantic,
    required this.report,
    required this.transcript,
    required this.audioSourceType,
    this.demoActive = false,
    this.audioAmplitude = 0,
    this.isTranscriptionLive = false,
    this.cloudTranscriptionEntitled = false,
    this.partialTranscript = '',
  });

  /// Latest acoustic forensics snapshot (Engine A).
  final AudioForensicMetrics acoustic;

  /// Latest semantic threat signals (Engine B).
  final SemanticThreatSignals semantic;

  /// Fused composite assessment.
  final CompositeThreatReport report;

  /// Committed transcript lines received so far.
  final List<TranscriptSnippet> transcript;

  /// Provenance of the audio feeding the pipeline — the single
  /// authoritative source of truth for demo-vs-live labelling.
  final AudioSourceType audioSourceType;

  /// Whether the scripted demo-attack injection is running.
  /// Only possible in demo sessions.
  final bool demoActive;

  /// RMS amplitude of the latest audio chunk (0–1), lightly smoothed.
  /// Drives the Signal Lens breathing motion.
  final double audioAmplitude;

  /// Whether a streaming STT provider is actively producing
  /// transcripts for this session.
  final bool isTranscriptionLive;

  /// Whether the current plan entitles automatic cloud
  /// transcription. When false the session runs acoustic-only BY
  /// PLAN, not by configuration — the UI must say so honestly
  /// instead of implying the provider is merely unavailable.
  final bool cloudTranscriptionEntitled;

  /// Latest volatile STT partial hypothesis (displayed live, never
  /// committed to the transcript until finalized).
  final String partialTranscript;

  /// Single source of truth for demo provenance.
  bool get isDemoMode => audioSourceType == AudioSourceType.demo;

  SafeCallMonitoring copyWith({
    AudioForensicMetrics? acoustic,
    SemanticThreatSignals? semantic,
    CompositeThreatReport? report,
    List<TranscriptSnippet>? transcript,
    AudioSourceType? audioSourceType,
    bool? demoActive,
    double? audioAmplitude,
    bool? isTranscriptionLive,
    bool? cloudTranscriptionEntitled,
    String? partialTranscript,
  }) {
    return SafeCallMonitoring(
      acoustic: acoustic ?? this.acoustic,
      semantic: semantic ?? this.semantic,
      report: report ?? this.report,
      transcript: transcript ?? this.transcript,
      audioSourceType: audioSourceType ?? this.audioSourceType,
      demoActive: demoActive ?? this.demoActive,
      audioAmplitude: audioAmplitude ?? this.audioAmplitude,
      isTranscriptionLive: isTranscriptionLive ?? this.isTranscriptionLive,
      cloudTranscriptionEntitled:
          cloudTranscriptionEntitled ?? this.cloudTranscriptionEntitled,
      partialTranscript: partialTranscript ?? this.partialTranscript,
    );
  }

  @override
  List<Object?> get props => [
        acoustic,
        semantic,
        report,
        transcript,
        audioSourceType,
        demoActive,
        audioAmplitude,
        isTranscriptionLive,
        cloudTranscriptionEntitled,
        partialTranscript,
      ];
}

/// The session could not start (permission denied, unsupported
/// platform, capture failure). Carries enough context for the UI to
/// offer retry or Demo Mode without crashing.
final class SafeCallError extends SafeCallState {
  const SafeCallError({
    required this.message,
    this.permanentlyDenied = false,
  });

  final String message;

  /// True when the OS will no longer show a permission prompt — the
  /// user must be directed to system settings.
  final bool permanentlyDenied;

  @override
  List<Object?> get props => [message, permanentlyDenied];
}

/// Session finished. Carries the worst risk level seen during the
/// session so the UI can trigger post-call actions.
final class SafeCallEnded extends SafeCallState {
  const SafeCallEnded({
    this.peakRiskLevel = ThreatRiskLevel.safe,
    this.incident,
  });

  final ThreatRiskLevel peakRiskLevel;

  /// Incident report persisted when the session ended at high risk.
  final IncidentReport? incident;

  @override
  List<Object?> get props => [peakRiskLevel, incident];
}
