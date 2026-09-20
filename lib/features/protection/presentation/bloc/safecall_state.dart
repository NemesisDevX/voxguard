import 'package:equatable/equatable.dart';

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

/// Pre-call / idle.
final class SafeCallInitial extends SafeCallState {
  const SafeCallInitial();
}

/// Live call in progress — carries the full latest sensor snapshot.
final class SafeCallMonitoring extends SafeCallState {
  const SafeCallMonitoring({
    required this.acoustic,
    required this.semantic,
    required this.report,
    required this.transcript,
    this.demoActive = false,
  });

  /// Latest acoustic forensics snapshot (Engine A).
  final AudioForensicMetrics acoustic;

  /// Latest semantic threat signals (Engine B).
  final SemanticThreatSignals semantic;

  /// Fused composite assessment.
  final CompositeThreatReport report;

  /// Live transcript lines received so far.
  final List<TranscriptSnippet> transcript;

  /// Whether the scripted demo-attack injection is running.
  final bool demoActive;

  SafeCallMonitoring copyWith({
    AudioForensicMetrics? acoustic,
    SemanticThreatSignals? semantic,
    CompositeThreatReport? report,
    List<TranscriptSnippet>? transcript,
    bool? demoActive,
  }) {
    return SafeCallMonitoring(
      acoustic: acoustic ?? this.acoustic,
      semantic: semantic ?? this.semantic,
      report: report ?? this.report,
      transcript: transcript ?? this.transcript,
      demoActive: demoActive ?? this.demoActive,
    );
  }

  @override
  List<Object?> get props =>
      [acoustic, semantic, report, transcript, demoActive];
}

/// Call finished. Carries the worst risk level seen during the session
/// so the UI can trigger post-call actions (e.g. the Family Shield
/// upsell after a high-risk interception).
final class SafeCallEnded extends SafeCallState {
  const SafeCallEnded({this.peakRiskLevel = ThreatRiskLevel.safe});

  final ThreatRiskLevel peakRiskLevel;

  @override
  List<Object?> get props => [peakRiskLevel];
}
