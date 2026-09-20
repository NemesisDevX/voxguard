import 'package:equatable/equatable.dart';

import '../../../protection/domain/models/audio_forensic_metrics.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/domain/models/semantic_threat_signals.dart';
import '../../../protection/domain/models/transcript_snippet.dart';

/// Immutable record of a single flagged protection session.
///
/// Persisted to [IIncidentRepository] and rendered by the incident
/// detail screen. Telemetry is an assistive signal — see [disclaimer].
final class IncidentReport extends Equatable {
  const IncidentReport({
    required this.id,
    required this.timestamp,
    required this.callerLabel,
    required this.callDurationSeconds,
    required this.audioDigestSha256,
    required this.audioSourceLabel,
    required this.transcriptionSourceLabel,
    required this.peakRiskScore,
    required this.riskLevel,
    required this.threatReasons,
    required this.acousticMetrics,
    required this.semanticSignals,
    required this.transcriptSnippets,
    required this.recommendedActions,
    this.disclaimer = legalDisclaimer,
  });

  /// Standard legal disclaimer rendered on every report.
  static const String legalDisclaimer =
      'AI-generated forensic telemetry. Not a legal or judicial '
      'determination.';

  /// Human reference id, e.g. `INC-2026-4821`.
  final String id;

  /// When the incident was recorded.
  final DateTime timestamp;

  /// Display label for the caller, e.g. `Unknown Caller (+20 10 ••• ••42)`.
  final String callerLabel;

  /// Session length in seconds.
  final int callDurationSeconds;

  /// Genuine SHA-256 digest (64 hex chars) of every normalized PCM16
  /// byte analyzed during the session.
  final String audioDigestSha256;

  /// Provenance of the analyzed audio — `Live Microphone` or
  /// `Generated Demo Audio`. Never ambiguous.
  final String audioSourceLabel;

  /// Provenance of the transcript — e.g. `AssemblyAI Streaming`,
  /// `Local Demo Transcript`, or `None — acoustic analysis only`.
  final String transcriptionSourceLabel;

  /// Worst fused risk score observed during the session (0.0 – 1.0).
  final double peakRiskScore;

  /// Discrete band derived from [peakRiskScore].
  final ThreatRiskLevel riskLevel;

  /// Human-readable threat drivers from the fusion engine.
  final List<String> threatReasons;

  /// Engine A snapshot at peak risk.
  final AudioForensicMetrics acousticMetrics;

  /// Engine B snapshot at peak risk.
  final SemanticThreatSignals semanticSignals;

  /// Transcript captured during the session.
  final List<TranscriptSnippet> transcriptSnippets;

  /// Recommended next steps for the user.
  final List<String> recommendedActions;

  /// Legal disclaimer rendered on the report footer.
  final String disclaimer;

  /// `MM:SS` duration label.
  String get durationLabel {
    final m = (callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// `dd/MM/yyyy HH:mm` timestamp label.
  String get timestampLabel {
    final d = timestamp;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  /// All phrases that should be threat-highlighted in the transcript.
  List<String> get flaggedPhrases => [
        ...semanticSignals.detectedKeywords,
        ...semanticSignals.impersonationClaims,
      ];

  /// Plain-text summary for the share/copy action.
  String toShareText() {
    final reasons = threatReasons.join('; ');
    return 'VoxGuard Incident Report\n'
        'ID: $id\n'
        'Time: $timestampLabel\n'
        'Caller: $callerLabel\n'
        'Duration: $durationLabel\n'
        'Risk: ${riskLevel.name} — Threat Score: ${(peakRiskScore * 100).round()}/100\n'
        'Threats: $reasons\n'
        'Audio source: $audioSourceLabel\n'
        'Transcription: $transcriptionSourceLabel\n'
        'Audio SHA-256: $audioDigestSha256\n'
        '\n$disclaimer';
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        callerLabel,
        callDurationSeconds,
        audioDigestSha256,
        audioSourceLabel,
        transcriptionSourceLabel,
        peakRiskScore,
        riskLevel,
        threatReasons,
        acousticMetrics,
        semanticSignals,
        transcriptSnippets,
        recommendedActions,
      ];
}
