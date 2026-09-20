import 'package:equatable/equatable.dart';

import '../../../../core/services/audio/audio_stream_source.dart';

/// Events driving the SafeCall threat-monitoring session.
sealed class SafeCallEvent extends Equatable {
  const SafeCallEvent();

  @override
  List<Object?> get props => [];
}

/// Begin a microphone protection session — requests mic permission,
/// starts real PCM capture, and starts streaming STT when configured.
final class StartLiveMicSessionEvent extends SafeCallEvent {
  const StartLiveMicSessionEvent();
}

/// Begin a demo session — deterministic generated PCM with the
/// scripted scam scenario available via [SimulateDemoAttackEvent].
final class StartDemoSessionEvent extends SafeCallEvent {
  const StartDemoSessionEvent();
}

/// A raw audio chunk arrived from the active source (mono PCM16,
/// normalized samples + original bytes).
final class IncomingAudioChunkEvent extends SafeCallEvent {
  const IncomingAudioChunkEvent(this.chunk);

  final AudioChunk chunk;

  @override
  List<Object?> get props => [chunk];
}

/// A committed (final) transcript segment arrived — from streaming
/// STT in live mode, or the scripted demo dialogue in demo mode.
final class IncomingTranscriptSnippetEvent extends SafeCallEvent {
  const IncomingTranscriptSnippetEvent({
    required this.speaker,
    required this.text,
  });

  final String speaker;
  final String text;

  @override
  List<Object?> get props => [speaker, text];
}

/// A volatile partial hypothesis arrived from streaming STT.
/// Displayed live; semantic analysis runs on a debounced window.
final class IncomingTranscriptPartialEvent extends SafeCallEvent {
  const IncomingTranscriptPartialEvent(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Demo/debug toggle — progressively injects the scripted scam
/// dialogue so the HUD escalates from safe to high risk.
/// Only meaningful in demo sessions.
final class SimulateDemoAttackEvent extends SafeCallEvent {
  const SimulateDemoAttackEvent();
}

/// Caller hung up / user ended the session.
final class EndCallEvent extends SafeCallEvent {
  const EndCallEvent();
}

/// Tear the session back down to the pre-session state.
final class ResetCallEvent extends SafeCallEvent {
  const ResetCallEvent();
}

/// Internal: fires the debounced semantic-analysis pass after partial
/// transcript updates settle. Never dispatched by the UI.
final class AnalyzeTranscriptContextEvent extends SafeCallEvent {
  const AnalyzeTranscriptContextEvent();
}

/// Internal: the STT provider reported a session-status change (e.g.
/// mid-session disconnect → transcription degraded). Never dispatched
/// by the UI.
final class TranscriptionStatusChangedEvent extends SafeCallEvent {
  const TranscriptionStatusChangedEvent(this.live);

  /// Whether the provider session is currently usable.
  final bool live;
}
