import 'dart:async';
import 'dart:math';

import 'audio_stream_source.dart';
import 'pcm_codec.dart';

/// Deterministic generated-PCM source for Demo Mode.
///
/// Produces two spectral profiles:
///  - natural: broadband noise + wandering formant (dynamic spectrum —
///    reads as a human voice to Engine A),
///  - attack:  band-limited harmonic stack with a hard HF cutoff and
///    static spectrum (the synthesized-voice signature).
///
/// [setAttackMode] flips the profile mid-stream so the demo escalates
/// visibly alongside the scripted transcript.
class DemoAudioSource implements IAudioStreamSource {
  DemoAudioSource({
    this.chunkInterval = const Duration(milliseconds: 420),
    this.chunkSize = 512,
  });

  final Duration chunkInterval;
  final int chunkSize;

  static const int _sampleRate = 16000;

  // Broadcast: the bloc unsubscribes/re-subscribes across sessions —
  // a single-subscription controller would throw "already listened"
  // on restart and its close() can hang on stale listener state.
  final _controller = StreamController<AudioChunk>.broadcast();
  final Random _rng = Random();

  Timer? _timer;
  int _sampleOffset = 0;
  bool _attackMode = false;
  bool _running = false;

  /// Whether emitted chunks carry the synthetic (attack) profile.
  bool get attackMode => _attackMode;

  /// Switches between the natural and synthetic spectral profiles.
  void setAttackMode(bool enabled) => _attackMode = enabled;

  @override
  AudioSourceType get type => AudioSourceType.demo;

  @override
  int get sampleRate => _sampleRate;

  @override
  Stream<AudioChunk> get chunks => _controller.stream;

  @override
  bool get isSupported => true;

  @override
  Future<MicPermissionState> ensurePermission() async =>
      MicPermissionState.granted;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(chunkInterval, (_) {
      if (!_controller.isClosed) _controller.add(_generateChunk());
    });
  }

  @override
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Releases the stream — call when the bloc is disposed.
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  AudioChunk _generateChunk() {
    final samples = List<double>.filled(chunkSize, 0);
    for (var i = 0; i < chunkSize; i++) {
      final t = (_sampleOffset + i) / _sampleRate;
      if (_attackMode) {
        samples[i] = 0.50 * sin(2 * pi * 190 * t) +
            0.28 * sin(2 * pi * 380 * t) +
            0.15 * sin(2 * pi * 570 * t) +
            (_rng.nextDouble() - 0.5) * 0.04;
      } else {
        final wander =
            260 + 140 * sin(2 * pi * 1.7 * t) + 60 * sin(2 * pi * 3.9 * t);
        samples[i] = (_rng.nextDouble() - 0.5) * 0.55 +
            0.35 * sin(2 * pi * wander * t) +
            0.15 * sin(2 * pi * 3400 * t) * sin(2 * pi * 5 * t);
      }
    }
    _sampleOffset += chunkSize;
    return AudioChunk(
      samples: samples,
      pcm16Bytes: PcmCodec.samplesToPcm16(samples),
    );
  }
}
