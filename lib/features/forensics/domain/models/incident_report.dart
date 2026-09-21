import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_strings.dart';
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
    this.analysisIsPartial = false,
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

  /// True when this record was produced by an acoustic-only analysis
  /// (no conversation-risk signals) — the UI labels it partial rather
  /// than a full fused verdict.
  final bool analysisIsPartial;

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

  /// Plain-text summary for the share/copy action. A partial
  /// (acoustic-only) report must never present a fused Threat Score —
  /// conversation-risk signals were not analyzed.
  String toShareText() {
    final reasons = threatReasons.join('; ');
    final assessment = analysisIsPartial
        ? 'Analysis: Partial — acoustic signals only\n'
            'Acoustic anomaly score: '
            '${(acousticMetrics.syntheticVoiceScore * 100).round()}/100\n'
            'Conversation-risk signals were not analyzed.\n'
        : 'Risk: ${riskLevel.name} — Threat Score: '
            '${(peakRiskScore * 100).round()}/100\n';
    return '${AppStrings.incidentReportTitle}\n'
        'ID: $id\n'
        'Time: $timestampLabel\n'
        'Caller: $callerLabel\n'
        'Duration: $durationLabel\n'
        '$assessment'
        'Signals: $reasons\n'
        'Audio source: $audioSourceLabel\n'
        'Transcription: $transcriptionSourceLabel\n'
        'Audio SHA-256: $audioDigestSha256\n'
        '\n$disclaimer';
  }

  static final _idPattern = RegExp(r'^[A-Za-z0-9_\-.:@]{1,64}$');
  static final _shaPattern = RegExp(r'^[0-9a-f]{64}$');

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'caller_label': callerLabel,
        'call_duration_seconds': callDurationSeconds,
        'audio_digest_sha256': audioDigestSha256,
        'audio_source_label': audioSourceLabel,
        'transcription_source_label': transcriptionSourceLabel,
        'peak_risk_score': peakRiskScore,
        'risk_level': riskLevel.name,
        'threat_reasons': threatReasons,
        'acoustic_metrics': acousticMetrics.toJson(),
        'semantic_signals': semanticSignals.toJson(),
        'transcript_snippets':
            [for (final s in transcriptSnippets) s.toJson()],
        'recommended_actions': recommendedActions,
        'disclaimer': disclaimer,
        'analysis_is_partial': analysisIsPartial,
      };

  /// Strict decode — every field validated; a malformed row is
  /// skipped by the repository rather than crashing startup.
  static IncidentReport? fromJson(Map<String, dynamic> json) {
    String? boundedStr(Object? v, int max) =>
        v is String && v.isNotEmpty && v.length <= max ? v : null;
    List<String>? strList(Object? v, int maxItems, int maxLen) {
      if (v is! List || v.length > maxItems) return null;
      final out = <String>[];
      for (final e in v) {
        if (e is! String || e.length > maxLen) return null;
        out.add(e);
      }
      return out;
    }

    final id = json['id'];
    final ts = DateTime.tryParse('${json['timestamp'] ?? ''}');
    final caller = boundedStr(json['caller_label'], 200);
    final duration = json['call_duration_seconds'];
    final digest = json['audio_digest_sha256'];
    final audioSrc = boundedStr(json['audio_source_label'], 200);
    final sttSrc = boundedStr(json['transcription_source_label'], 200);
    final score = json['peak_risk_score'];
    final level = json['risk_level'];
    final reasons = strList(json['threat_reasons'], 32, 300);
    final actions = strList(json['recommended_actions'], 16, 300);
    final acoustic =
        json['acoustic_metrics'] is Map<String, dynamic>
            ? AudioForensicMetrics.fromJson(
                json['acoustic_metrics'] as Map<String, dynamic>)
            : null;
    final semantic =
        json['semantic_signals'] is Map<String, dynamic>
            ? SemanticThreatSignals.fromJson(
                json['semantic_signals'] as Map<String, dynamic>)
            : null;
    final snippetsJson = json['transcript_snippets'];
    List<TranscriptSnippet>? snippets;
    if (snippetsJson is List && snippetsJson.length <= 200) {
      snippets = [];
      for (final e in snippetsJson) {
        if (e is! Map<String, dynamic>) return null;
        final s = TranscriptSnippet.fromJson(e);
        if (s == null) return null;
        snippets.add(s);
      }
    }
    if (id is! String ||
        !_idPattern.hasMatch(id) ||
        ts == null ||
        caller == null ||
        duration is! int ||
        duration < 0 ||
        duration > 7 * 24 * 3600 ||
        digest is! String ||
        !_shaPattern.hasMatch(digest) ||
        audioSrc == null ||
        sttSrc == null ||
        score is! num ||
        score < 0 ||
        score > 1 ||
        level is! String ||
        !ThreatRiskLevel.values.any((l) => l.name == level) ||
        reasons == null ||
        actions == null ||
        acoustic == null ||
        semantic == null ||
        snippets == null) {
      return null;
    }
    return IncidentReport(
      id: id,
      timestamp: ts,
      callerLabel: caller,
      callDurationSeconds: duration,
      audioDigestSha256: digest,
      audioSourceLabel: audioSrc,
      transcriptionSourceLabel: sttSrc,
      peakRiskScore: score.toDouble(),
      riskLevel:
          ThreatRiskLevel.values.firstWhere((l) => l.name == level),
      threatReasons: reasons,
      acousticMetrics: acoustic,
      semanticSignals: semantic,
      transcriptSnippets: snippets,
      recommendedActions: actions,
      disclaimer: boundedStr(json['disclaimer'], 400) ??
          legalDisclaimer,
      analysisIsPartial: json['analysis_is_partial'] == true,
    );
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
        analysisIsPartial,
      ];
}
