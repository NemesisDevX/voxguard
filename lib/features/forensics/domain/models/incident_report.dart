import 'package:equatable/equatable.dart';

import '../../../protection/domain/models/audio_forensic_metrics.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/domain/models/semantic_threat_signals.dart';
import '../../../protection/domain/models/transcript_snippet.dart';

/// Immutable record of a single flagged call session.
///
/// Persisted to [IIncidentRepository] and rendered by the incident
/// detail screen. Telemetry is an assistive signal — see [disclaimer].
final class IncidentReport extends Equatable {
  const IncidentReport({
    required this.id,
    required this.timestamp,
    required this.callerLabel,
    required this.callDurationSeconds,
    required this.audioFingerprint,
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

  /// Call length in seconds.
  final int callDurationSeconds;

  /// Deterministic fingerprint of the session audio stream (rolling
  /// hash, 64 hex chars). Identifies the session's audio evidence.
  final String audioFingerprint;

  /// Worst fused risk score observed during the call (0.0 – 1.0).
  final double peakRiskScore;

  /// Discrete band derived from [peakRiskScore].
  final ThreatRiskLevel riskLevel;

  /// Human-readable threat drivers from the fusion engine.
  final List<String> threatReasons;

  /// Engine A snapshot at peak risk.
  final AudioForensicMetrics acousticMetrics;

  /// Engine B snapshot at peak risk.
  final SemanticThreatSignals semanticSignals;

  /// Live transcript captured during the call.
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
        'Risk: ${riskLevel.name} (${(peakRiskScore * 100).round()}%)\n'
        'Threats: $reasons\n'
        'Audio fingerprint: $audioFingerprint\n'
        '\n$disclaimer';
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        callerLabel,
        callDurationSeconds,
        audioFingerprint,
        peakRiskScore,
        riskLevel,
        threatReasons,
        acousticMetrics,
        semanticSignals,
        transcriptSnippets,
        recommendedActions,
      ];
}
