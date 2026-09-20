import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'audio_stream_source.dart';
import 'pcm_codec.dart';

/// Real device-microphone capture via the `record` plugin.
///
/// Emits mono PCM16 at 16 kHz — the exact format
/// `AcousticForensicsService` and the streaming STT provider consume.
///
/// Supported on Android/iOS/macOS. On Web and desktop platforms where
/// raw PCM16 streaming is unavailable, [isSupported] is false and
/// [start] surfaces [AudioSourceException.unsupported] — the UI layer
/// turns that into an honest error state instead of a crash.
final class MicrophoneAudioSource implements IAudioStreamSource {
  MicrophoneAudioSource({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  static const int _sampleRate = 16000;

  final AudioRecorder _recorder;
  final _controller = StreamController<AudioChunk>();
  StreamSubscription<Uint8List>? _sub;
  bool _running = false;

  @override
  AudioSourceType get type => AudioSourceType.microphone;

  @override
  int get sampleRate => _sampleRate;

  @override
  Stream<AudioChunk> get chunks => _controller.stream;

  /// Raw PCM16 streaming is supported on the mobile/desktop record
  /// backends, not on the web MediaRecorder backend.
  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<MicPermissionState> ensurePermission() async {
    if (!isSupported) return MicPermissionState.unsupported;

    final status = await Permission.microphone.status;
    if (status.isPermanentlyDenied) return MicPermissionState.permanentlyDenied;
    if (status.isRestricted) return MicPermissionState.restricted;

    if (status.isGranted || status.isLimited) {
      return MicPermissionState.granted;
    }

    // First request — this is where the OS prompt appears.
    final requested = await Permission.microphone.request();
    if (requested.isGranted || requested.isLimited) {
      // Belt-and-suspenders: the recorder plugin also tracks grants.
      return await _recorder.hasPermission()
          ? MicPermissionState.granted
          : MicPermissionState.denied;
    }
    return requested.isPermanentlyDenied
        ? MicPermissionState.permanentlyDenied
        : MicPermissionState.denied;
  }

  @override
  Future<void> start() async {
    if (_running) return;
    if (!isSupported) {
      throw const AudioSourceException(
        AudioSourceFailure.unsupported,
        'Raw microphone streaming is not supported on this platform.',
      );
    }
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _running = true;
    _sub = stream.listen(
      (bytes) {
        if (_controller.isClosed) return;
        _controller.add(
          AudioChunk(
            samples: PcmCodec.pcm16ToSamples(bytes),
            pcm16Bytes: bytes,
          ),
        );
      },
      onError: (Object e, StackTrace st) {
        if (!_controller.isClosed) {
          _controller.addError(
            AudioSourceException(
              AudioSourceFailure.captureFailed,
              'Microphone capture failed: $e',
            ),
          );
        }
      },
    );
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _sub?.cancel();
    _sub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  /// Releases the recorder plugin — call when the owning bloc closes.
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _controller.close();
  }
}

/// What went wrong starting/sustaining an audio source.
enum AudioSourceFailure { permissionDenied, unsupported, captureFailed }

/// Typed failure surfaced to the UI so it can offer retry / demo
/// fallback without crashing the session.
final class AudioSourceException implements Exception {
  const AudioSourceException(this.failure, this.message);

  final AudioSourceFailure failure;
  final String message;

  @override
  String toString() => 'AudioSourceException($failure): $message';
}
