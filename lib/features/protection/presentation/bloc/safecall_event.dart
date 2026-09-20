import 'package:equatable/equatable.dart';

/// Events driving the SafeCall threat-monitoring session.
sealed class SafeCallEvent extends Equatable {
  const SafeCallEvent();

  @override
  List<Object?> get props => [];
}

/// Begin a protected call — starts the incoming audio feed.
final class StartCallEvent extends SafeCallEvent {
  const StartCallEvent();
}

/// A raw audio chunk arrived from the stream (mono PCM, -1.0 – 1.0).
final class IncomingAudioChunkEvent extends SafeCallEvent {
  const IncomingAudioChunkEvent(this.samples);

  final List<double> samples;

  @override
  List<Object?> get props => [samples];
}

/// A transcribed speech segment arrived.
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

/// Demo/debug toggle — progressively injects the scripted scam
/// dialogue so the HUD escalates from safe to high risk.
final class SimulateDemoAttackEvent extends SafeCallEvent {
  const SimulateDemoAttackEvent();
}

/// Caller hung up / user ended the call.
final class EndCallEvent extends SafeCallEvent {
  const EndCallEvent();
}

/// Tear the session back down to the pre-call state.
final class ResetCallEvent extends SafeCallEvent {
  const ResetCallEvent();
}
