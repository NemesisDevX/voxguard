import 'dart:typed_data';

/// One chunk of captured/generated audio in the format the analysis
/// pipeline consumes.
///
/// [samples] are normalized mono PCM (-1.0 – 1.0) for
/// `AcousticForensicsService`; [pcm16Bytes] are the same audio as
/// little-endian PCM16 for the streaming transcription provider and
/// the session SHA-256 digest.
final class AudioChunk {
  const AudioChunk({required this.samples, required this.pcm16Bytes});

  final List<double> samples;
  final Uint8List pcm16Bytes;
}

/// Where the audio in a protection session originates.
enum AudioSourceType {
  /// Real device microphone capture.
  microphone,

  /// Deterministic generated PCM (Demo Mode).
  demo;

  /// Human-readable provenance recorded on incident reports.
  String get incidentLabel => switch (this) {
        AudioSourceType.microphone => 'Live Microphone',
        AudioSourceType.demo => 'Generated Demo Audio',
      };
}

/// Result of a microphone permission check/request.
enum MicPermissionState { granted, denied, permanentlyDenied, restricted, unsupported }

/// Contract for anything that produces PCM chunks for the threat
/// pipeline. The bloc, engines and UI are agnostic to the source —
/// demo and microphone audio flow through the identical path.
abstract interface class IAudioStreamSource {
  /// Provenance of this source's audio.
  AudioSourceType get type;

  /// PCM sample rate this source emits (16 kHz mono).
  int get sampleRate;

  /// Continuous chunk stream. Emits only while [start]ed.
  Stream<AudioChunk> get chunks;

  /// Whether this source can produce audio on the current platform.
  bool get isSupported;

  /// Ensures capture permission. Demo sources always return
  /// [MicPermissionState.granted].
  Future<MicPermissionState> ensurePermission();

  /// Begins emitting chunks.
  Future<void> start();

  /// Stops emitting and releases capture resources.
  Future<void> stop();
}
