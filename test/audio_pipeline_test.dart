import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/core/services/audio/audio_stream_source.dart';
import 'package:voxguard/core/services/audio/demo_audio_source.dart';
import 'package:voxguard/core/services/audio/pcm_codec.dart';
import 'package:voxguard/core/services/transcription/streaming_transcription_service.dart';
import 'package:voxguard/features/protection/domain/services/semantic_threat_service.dart';
import 'package:voxguard/features/protection/domain/services/transcript_buffer.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_bloc.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_event.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_state.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/domain/services/incident_repository.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/domain/models/transcript_snippet.dart';

// ── Fakes ────────────────────────────────────────────────────────────

/// Scripted mic source — permission state and chunk stream are
/// controlled by the test.
final class FakeMicSource implements IAudioStreamSource {
  FakeMicSource({this.permission = MicPermissionState.granted});

  MicPermissionState permission;
  // Broadcast like the real source — sessions re-subscribe on restart.
  final _controller = StreamController<AudioChunk>.broadcast();
  var startCalls = 0;
  var stopCalls = 0;

  @override
  AudioSourceType get type => AudioSourceType.microphone;

  @override
  int get sampleRate => 16000;

  @override
  Stream<AudioChunk> get chunks => _controller.stream;

  @override
  bool get isSupported => true;

  @override
  Future<MicPermissionState> ensurePermission() async => permission;

  @override
  Future<void> start() async => startCalls++;

  @override
  Future<void> stop() async => stopCalls++;

  void emit(List<double> samples) => _controller.add(
        AudioChunk(
          samples: samples,
          pcm16Bytes: PcmCodec.samplesToPcm16(samples),
        ),
      );
}

/// No-op STT — records sendAudio calls; can be told to fail on start.
final class FakeSttService implements IStreamingTranscriptionService {
  FakeSttService({this.configured = true, this.failStart = false});

  final bool configured;
  final bool failStart;
  final sentBytes = <int>[];
  var startCalls = 0;

  final _events = StreamController<TranscriptEvent>.broadcast();
  final _status =
      StreamController<TranscriptionSessionStatus>.broadcast();

  @override
  bool get isConfigured => configured;

  @override
  String get providerLabel => 'FakeSTT';

  @override
  Stream<TranscriptEvent> get events => _events.stream;

  @override
  Stream<TranscriptionSessionStatus> get status => _status.stream;

  @override
  Future<void> start({required int sampleRate}) async {
    startCalls++;
    if (failStart) throw StateError('STT unavailable');
  }

  @override
  void sendAudio(Uint8List pcm16le) => sentBytes.add(pcm16le.length);

  @override
  Future<void> stop() async {}

  void emitFinal(String text) =>
      _events.add(TranscriptEvent(text: text, isFinal: true));
}

/// Demo source with observable lifecycle counters — the real
/// implementation is final-ish for test purposes, so extend it.
final class SpyDemoSource extends DemoAudioSource {
  var startCalls = 0;
  var stopCalls = 0;

  @override
  Future<void> start() async {
    startCalls++;
    await super.start();
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    await super.stop();
  }
}

void main() {
  // ── PCM codec ────────────────────────────────────────────────────
  group('PcmCodec', () {
    test('PCM16 round-trip preserves normalized samples', () {
      final samples = [0.0, 0.5, -0.5, 1.0, -1.0];
      final bytes = PcmCodec.samplesToPcm16(samples);
      final back = PcmCodec.pcm16ToSamples(bytes);
      for (var i = 0; i < samples.length; i++) {
        expect(back[i], closeTo(samples[i], 0.001));
      }
    });

    test('rms is 0 for silence and near-full for loud signal', () {
      expect(PcmCodec.rms(List.filled(512, 0.0)), 0);
      expect(PcmCodec.rms(List.filled(512, 0.9)), closeTo(0.9, 0.001));
    });
  });

  // ── DemoAudioSource ──────────────────────────────────────────────
  group('DemoAudioSource', () {
    test('emits normalized chunks after start, stops cleanly', () async {
      final source = DemoAudioSource(
        chunkInterval: const Duration(milliseconds: 10),
        chunkSize: 64,
      );
      final received = <AudioChunk>[];
      final sub = source.chunks.listen(received.add);

      await source.start();
      await Future<void>.delayed(const Duration(milliseconds: 45));
      await source.stop();
      await sub.cancel();

      expect(received, isNotEmpty);
      for (final c in received) {
        expect(c.samples.length, 64);
        expect(c.pcm16Bytes.length, 128); // 64 samples × 2 bytes
        expect(
          c.samples.every((s) => s >= -1.0 && s <= 1.0),
          isTrue,
        );
      }
      expect(source.type, AudioSourceType.demo);
      await source.dispose();
    });
  });

  // ── TranscriptBuffer ─────────────────────────────────────────────
  group('TranscriptBuffer', () {
    test('rolling context merges segments split across STT chunks', () {
      final buffer = TranscriptBuffer();
      buffer.commit('أنا أخوك');
      buffer.commit('حول لي ألفين جنيه');
      buffer.updatePartial('بسرعة ومتقولش لحد');

      final signals = SemanticThreatService()
          .analyzeLocally(buffer.analysisContext);

      expect(signals.impersonationClaims, isNotEmpty);
      expect(signals.financialDemandScore, greaterThan(0));
      expect(signals.urgencyScore, greaterThan(0));
      expect(signals.secrecyScore, greaterThan(0));
      expect(
        signals.evidenceCategories,
        containsAll([
          EvidenceCategory.impersonation,
          EvidenceCategory.moneyRequest,
          EvidenceCategory.urgency,
          EvidenceCategory.secrecy,
        ]),
      );
    });
  });

  // ── SafeCallBloc provenance & lifecycle ──────────────────────────
  group('SafeCallBloc sessions', () {
    late InMemoryIncidentRepository incidents;

    setUp(() {
      incidents = InMemoryIncidentRepository();
      IncidentRepositoryLocator.instance = incidents;
    });

    test('demo session exposes demo provenance', () async {
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(
          chunkInterval: const Duration(milliseconds: 10),
        ),
        microphoneSource: FakeMicSource(),
        transcriptionService: FakeSttService(),
      );
      bloc.add(const StartDemoSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final s = bloc.state;
      expect(s, isA<SafeCallMonitoring>());
      final m = s as SafeCallMonitoring;
      expect(m.audioSourceType, AudioSourceType.demo);
      expect(m.isDemoMode, isTrue);
      expect(m.isTranscriptionLive, isFalse);
      await bloc.close();
    });

    test('mic session denied permission → SafeCallError, no capture',
        () async {
      final mic = FakeMicSource(permission: MicPermissionState.denied);
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: mic,
        transcriptionService: FakeSttService(),
      );
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bloc.state, isA<SafeCallError>());
      expect(mic.startCalls, 0);
      await bloc.close();
    });

    test('mic session permanently denied → settings-directed error',
        () async {
      final mic =
          FakeMicSource(permission: MicPermissionState.permanentlyDenied);
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: mic,
        transcriptionService: FakeSttService(),
      );
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final s = bloc.state as SafeCallError;
      expect(s.permanentlyDenied, isTrue);
      await bloc.close();
    });

    test('STT failure still runs acoustic analysis', () async {
      final mic = FakeMicSource();
      final stt = FakeSttService(failStart: true);
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: mic,
        transcriptionService: stt,
      );
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bloc.state, isA<SafeCallMonitoring>());
      expect(stt.startCalls, 1);

      mic.emit(List.filled(512, 0.4));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final m = bloc.state as SafeCallMonitoring;
      expect(m.isTranscriptionLive, isFalse);
      expect(m.audioSourceType, AudioSourceType.microphone);
      expect(m.audioAmplitude, greaterThan(0));
      await bloc.close();
    });

    test('live mic session forwards PCM to STT and digests audio',
        () async {
      final mic = FakeMicSource();
      final stt = FakeSttService();
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: mic,
        transcriptionService: stt,
      );
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect((bloc.state as SafeCallMonitoring).isTranscriptionLive,
          isTrue);

      mic.emit(List.filled(256, 0.3));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(stt.sentBytes, isNotEmpty);
      await bloc.close();
    });

    test('starting live mic while demo runs never leaves two '
        'active sources', () async {
      final demo = SpyDemoSource();
      final mic = FakeMicSource();
      final bloc = SafeCallBloc(
        demoSource: demo,
        microphoneSource: mic,
        transcriptionService: FakeSttService(),
      );

      bloc.add(const StartDemoSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(demo.startCalls, 1);
      expect(demo.stopCalls, 0);

      // Switch to Live Mic mid-demo — the demo timer must be
      // torn down before the mic takes over.
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(demo.stopCalls, 1);
      expect(mic.startCalls, 1);
      final m = bloc.state as SafeCallMonitoring;
      expect(m.audioSourceType, AudioSourceType.microphone);
      await bloc.close();
    });

    test('demo → live mic with denied permission leaves demo '
        'stopped, no active capture', () async {
      final demo = SpyDemoSource();
      final mic = FakeMicSource(permission: MicPermissionState.denied);
      final bloc = SafeCallBloc(
        demoSource: demo,
        microphoneSource: mic,
        transcriptionService: FakeSttService(),
      );
      bloc.add(const StartDemoSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(demo.startCalls, 1);

      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // Permission denied — but the demo session was already fully
      // stopped before the check; nothing keeps capturing.
      expect(bloc.state, isA<SafeCallError>());
      expect(demo.stopCalls, 1);
      expect(mic.startCalls, 0);
      await bloc.close();
    });

    test('reset → immediate start never overlaps sessions', () async {
      final demo = SpyDemoSource();
      final mic = FakeMicSource();
      final stt = FakeSttService();
      final bloc = SafeCallBloc(
        demoSource: demo,
        microphoneSource: mic,
        transcriptionService: stt,
      );
      bloc.add(const StartDemoSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // Fire reset + restart back-to-back — handlers are serialized,
      // so the demo teardown must fully precede the mic start.
      bloc.add(const ResetCallEvent());
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(demo.stopCalls, 1);
      expect(mic.startCalls, 1);
      expect(mic.stopCalls, 0);
      final m = bloc.state as SafeCallMonitoring;
      expect(m.audioSourceType, AudioSourceType.microphone);
      await bloc.close();
    });

    test('repeated start events do not stack sources', () async {
      final mic = FakeMicSource();
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: mic,
        transcriptionService: FakeSttService(),
      );
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // The first session was fully stopped before restart.
      expect(mic.stopCalls, greaterThanOrEqualTo(1));
      expect(bloc.state, isA<SafeCallMonitoring>());
      await bloc.close();
    });

    test('incident SHA-256 equals the digest of exactly the bytes '
        'streamed', () async {
      final mic = FakeMicSource();
      final stt = FakeSttService();
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: mic,
        transcriptionService: stt,
      );
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // Feed known audio and the full scam script — drives the
      // fusion engine to highRisk so an incident is produced.
      final allBytes = BytesBuilder();
      for (var i = 0; i < 3; i++) {
        final samples = List<double>.filled(256, 0.2 + i * 0.1);
        allBytes.add(PcmCodec.samplesToPcm16(samples));
        mic.emit(samples);
      }
      stt.emitFinal('أنا أخوك، محتاجك تحول لي 2000 جنيه بسرعة '
          'ومتقولش لحد');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      bloc.add(const EndCallEvent());
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final ended = bloc.state as SafeCallEnded;
      final incident = ended.incident;
      expect(incident, isNotNull);
      expect(
        incident!.audioDigestSha256,
        sha256.convert(allBytes.takeBytes()).toString(),
      );
      // Same digest must remain stable — the value was finalized
      // once, not recomputed against a drained buffer.
      expect(incident.audioDigestSha256.length, 64);
      await bloc.close();
    });
  });

  // ── Incident provenance & genuine SHA-256 ────────────────────────
  group('IncidentReport provenance', () {
    IncidentReport incident({
      String source = 'Live Microphone',
      String stt = 'AssemblyAI Streaming',
    }) =>
        IncidentReport(
          id: 'INC-2026-1',
          timestamp: DateTime(2026, 9, 20),
          callerLabel: 'Test',
          callDurationSeconds: 10,
          audioDigestSha256: sha256.convert(utf8.encode('audio')).toString(),
          audioSourceLabel: source,
          transcriptionSourceLabel: stt,
          peakRiskScore: 0.9,
          riskLevel: ThreatRiskLevel.highRisk,
          threatReasons: const ['x'],
          acousticMetrics: const AudioForensicMetrics.zero(),
          semanticSignals: const SemanticThreatSignals.empty(),
          transcriptSnippets: [
            TranscriptSnippet(
              speaker: 'Caller',
              text: 'hi',
              timestamp: DateTime(2026, 9, 20),
            ),
          ],
          recommendedActions: const ['x'],
        );

    test('source labels surface in the share text', () {
      final text = incident().toShareText();
      expect(text, contains('Live Microphone'));
      expect(text, contains('AssemblyAI Streaming'));
      expect(text, contains('Audio SHA-256'));
    });

    test('SHA-256 digest is a real 64-char hex digest', () {
      final digest = sha256.convert(utf8.encode('hello')).toString();
      expect(digest.length, 64);
      expect(
        digest,
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
    });
  });
}
