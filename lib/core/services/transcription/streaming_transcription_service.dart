import 'dart:typed_data';

/// One piece of speech-to-text output from a streaming provider.
final class TranscriptEvent {
  const TranscriptEvent({required this.text, required this.isFinal});

  /// Transcript text — a partial hypothesis when [isFinal] is false,
  /// a committed segment when true.
  final String text;
  final bool isFinal;
}

/// Lifecycle of a streaming transcription session.
///
/// `live` is emitted only once the provider session is confirmed
/// usable (socket connected + session begun) — never merely because
/// credentials exist. `disconnected` means the session dropped
/// mid-flight and a bounded reconnect may follow; `failed` means
/// transcription is unavailable for the rest of the session. In both
/// cases the protection session continues acoustically.
enum TranscriptionSessionStatus { connecting, live, disconnected, failed, ended }

/// Contract for streaming speech-to-text.
///
/// SafeCallBloc depends on this interface only — vendors are
/// interchangeable. Implementations convert audio → text; they never
/// score threats (that stays in `SemanticThreatService`).
abstract interface class IStreamingTranscriptionService {
  /// Whether the provider has usable credentials. When false the
  /// session continues acoustically with transcription marked
  /// unavailable.
  bool get isConfigured;

  /// Display label recorded on incident reports (e.g.
  /// 'AssemblyAI Streaming').
  String get providerLabel;

  /// Partial + final transcript events.
  Stream<TranscriptEvent> get events;

  /// Session lifecycle — consumers use this to reflect transcription
  /// availability truthfully instead of inferring it from config.
  Stream<TranscriptionSessionStatus> get status;

  /// Opens the streaming session for [sampleRate] Hz mono PCM16.
  Future<void> start({required int sampleRate});

  /// Forwards one little-endian PCM16 audio chunk.
  void sendAudio(Uint8List pcm16le);

  /// Flushes and closes the session, releasing resources.
  Future<void> stop();
}
