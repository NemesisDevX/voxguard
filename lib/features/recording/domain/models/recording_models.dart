import 'dart:typed_data';

import '../../../forensics/domain/models/incident_report.dart';
import '../../../protection/domain/models/audio_forensic_metrics.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/domain/models/semantic_threat_signals.dart';

/// Hard cap on source-file size — enforced by the picker BEFORE
/// bytes are loaded when the platform reports a size up front, and
/// again by the analyzer on the picked model.
const int kMaxRecordingSourceBytes = 25 * 1024 * 1024; // 25 MB

/// A user-selected audio file. Bytes are held in memory only for the
/// duration of the analysis — never written to PauseSignal storage.
final class PickedRecording {
  const PickedRecording({
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.bytes,
  });

  /// Local display name — UI only, never sent anywhere.
  final String name;

  /// Lowercase extension without the dot (e.g. `mp3`, `m4a`).
  final String extension;

  /// Source file size in bytes.
  final int sizeBytes;

  /// Raw source bytes — released as soon as analysis completes.
  final Uint8List bytes;
}

/// Decoder-reported metadata for a selected recording.
final class RecordingAudioInfo {
  const RecordingAudioInfo({
    required this.duration,
    required this.sampleRate,
    required this.channels,
    required this.format,
  });

  final Duration duration;
  final int sampleRate;
  final int channels;

  /// Decoder-reported format id (e.g. `mp3`, `wav`).
  final String format;
}

/// Truthful, stage-based progress — no fake percentages.
enum RecordingStage {
  /// Validating + decoding to normalized PCM16.
  preparing,

  /// Chunked acoustic-forensics pass over the whole recording.
  analyzingAcoustic,

  /// Enhanced mode only — submitting the recording to the
  /// transcription relay. Never shown for on-device analysis.
  uploading,

  /// Enhanced mode only — provider is transcribing.
  transcribing,

  /// Semantic engine pass over obtained/provided transcript text.
  evaluatingConversation,

  /// Assembling the result/incident record.
  buildingResult,
}

/// User's explicit privacy choice for a selected recording.
enum RecordingPrivacyMode {
  /// Audio never leaves the device — acoustic analysis only, plus an
  /// optional user-supplied transcript for semantic analysis.
  onDevice,

  /// Recording is sent through PauseSignal's transcription relay to the
  /// configured speech-to-text provider for conversation analysis.
  enhancedTranscription,
}

/// Terminal result of [RecordingAnalyzer.analyze].
final class RecordingAnalysisResult {
  const RecordingAnalysisResult({
    required this.fileName,
    required this.format,
    required this.sizeBytes,
    required this.duration,
    required this.acousticMetrics,
    required this.audioDigestSha256,
    required this.transcriptText,
    required this.transcriptSourceLabel,
    required this.semanticSignals,
    required this.report,
    required this.incident,
  });

  final String fileName;
  final String format;
  final int sizeBytes;
  final Duration duration;

  /// Acoustic evidence — the EMA-smoothed metrics at the recording's
  /// peak synthetic-voice score (same smoothing as SafeCall).
  final AudioForensicMetrics acousticMetrics;

  /// SHA-256 over the exact normalized PCM16 bytes analyzed.
  final String audioDigestSha256;

  /// Provider or user-supplied transcript — null when unavailable.
  final String? transcriptText;

  /// `AssemblyAI Pre-recorded` / `User-provided transcript` /
  /// `None — acoustic analysis only`.
  final String transcriptSourceLabel;

  /// Engine B output — null when no transcript existed.
  final SemanticThreatSignals? semanticSignals;

  /// Fused verdict — null for acoustic-only partial analysis.
  final CompositeThreatReport? report;

  /// Persisted incident — present only when the analysis was stored.
  final IncidentReport? incident;

  /// True when no conversation-risk signals were produced — the UI
  /// must render this as a partial analysis, never a normal verdict.
  bool get isPartial => report == null;
}

/// Thrown for every user-correctable recording failure — picker,
/// decoder, limits, transcription. Carries consumer-readable copy.
final class RecordingAnalysisException implements Exception {
  const RecordingAnalysisException(this.message, {this.code});

  final String message;

  /// Machine tag for tests (`empty`, `tooLarge`, `tooLong`,
  /// `unsupported`, `decodeFailed`, `transcriptionUnavailable`,
  /// `transcriptionFailed`, `cancelled`).
  final String? code;

  @override
  String toString() => message;
}
