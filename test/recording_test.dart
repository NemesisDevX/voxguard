import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voxguard/core/services/alerts/family_contact_repository.dart';
import 'package:voxguard/core/services/audio/pcm_codec.dart';
import 'package:voxguard/core/services/family/family_shield_response.dart';
import 'package:voxguard/core/services/push/onesignal_push_identity_service.dart';
import 'package:voxguard/core/services/push/push_identity_service.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/forensics/domain/services/incident_repository.dart';
import 'package:voxguard/features/forensics/presentation/screens/incident_detail_screen.dart';
import 'package:voxguard/features/home/presentation/screens/home_screen.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/domain/services/acoustic_forensics_service.dart';
import 'package:voxguard/features/recording/domain/models/recording_models.dart';
import 'package:voxguard/features/recording/domain/services/recorded_transcription_service.dart';
import 'package:voxguard/features/recording/domain/services/recording_analyzer.dart';
import 'package:voxguard/features/recording/domain/services/recording_audio_decoder.dart';
import 'package:voxguard/features/recording/domain/services/recording_file_picker.dart';
import 'package:voxguard/features/recording/presentation/screens/analyze_recording_screen.dart';

// ── Fakes ──────────────────────────────────────────────────────────

final class _FakePicker implements IRecordingFilePicker {
  _FakePicker(this.result);
  PickedRecording? result;
  int calls = 0;
  @override
  Future<PickedRecording?> pickRecording() async {
    calls++;
    return result;
  }
}

final class _FakeDecoder implements IRecordingAudioDecoder {
  _FakeDecoder({this.info, this.pcm, this.inspectError, this.decodeError});

  RecordingAudioInfo? info;
  Uint8List? pcm;
  Object? inspectError;
  Object? decodeError;
  int inspectCalls = 0;
  int decodeCalls = 0;

  @override
  Future<RecordingAudioInfo> inspect(PickedRecording file) async {
    inspectCalls++;
    final e = inspectError;
    if (e != null) throw e;
    return info ??
        const RecordingAudioInfo(
          duration: Duration(seconds: 3),
          sampleRate: 16000,
          channels: 1,
          format: 'wav',
        );
  }

  @override
  Future<Uint8List> decodeToPcm16(PickedRecording file) async {
    decodeCalls++;
    final e = decodeError;
    if (e != null) throw e;
    return pcm ?? PcmCodec.samplesToPcm16(List.filled(4096, 0.1));
  }
}

/// Counting acoustic fake — verifies chunk coverage + per-recording
/// resets without touching the real FFT pipeline.
final class _SpyAcoustic implements IAcousticAnalyzer {
  _SpyAcoustic([this.metrics = _lowMetrics]);

  static const _lowMetrics = AudioForensicMetrics(
    spectralFlux: 0.6,
    spectralRolloffRatio: 0.6,
    zeroCrossingRate: 0.4,
    syntheticVoiceScore: 0.10,
  );
  static const _elevatedMetrics = AudioForensicMetrics(
    spectralFlux: 0.02,
    spectralRolloffRatio: 0.05,
    zeroCrossingRate: 0.02,
    syntheticVoiceScore: 0.90,
  );

  final AudioForensicMetrics metrics;
  int resets = 0;
  final List<int> chunkSizes = [];

  @override
  void reset() => resets++;

  @override
  AudioForensicMetrics analyze(List<double> samples) {
    chunkSizes.add(samples.length);
    return metrics;
  }
}

final class _FakeTranscription implements IRecordedTranscriptionService {
  _FakeTranscription({this.configured = true});

  final bool configured;
  int submitCalls = 0;
  int pollCalls = 0;
  int lastByteCount = 0;
  String? lastFormatHint;
  Object? submitError;
  final List<RecordedTranscriptJob> pollQueue = [];

  @override
  bool get isConfigured => configured;

  @override
  Future<String> submitJob(
    Uint8List audioBytes, {
    required String formatHint,
  }) async {
    submitCalls++;
    lastByteCount = audioBytes.length;
    lastFormatHint = formatHint;
    final e = submitError;
    if (e != null) throw e;
    return 'job-1';
  }

  @override
  Future<RecordedTranscriptJob> pollJob(String jobId) async {
    pollCalls++;
    if (pollQueue.isNotEmpty) return pollQueue.removeAt(0);
    return const RecordedTranscriptJob(
      status: RecordedTranscriptionStatus.completed,
      text: 'transcribed',
    );
  }
}

/// Minimal push fake — keeps `FamilyReceiverCard` off the OneSignal
/// platform channel in widget tests.
final class _FakePush implements IPushIdentityService {
  final _registration = ValueNotifier<FamilyPushRegistration>(
    const FamilyPushRegistration(
      status: PushRegistrationStatus.notConfigured,
    ),
  );
  @override
  ValueListenable<FamilyPushRegistration> get registration =>
      _registration;
  @override
  Stream<FamilyAlertTap> get alertTaps => const Stream.empty();
  @override
  Stream<FamilyAlertTap> get alertReceived => const Stream.empty();
  @override
  Stream<FamilyShieldResponse> get responseTaps => const Stream.empty();
  @override
  Stream<FamilyShieldResponse> get responseReceived =>
      const Stream.empty();
  @override
  Future<String> voxGuardIdentity() async =>
      'vg_${'0' * 32}';
  @override
  Future<void> initialize() async {}
  @override
  Future<void> enableAlerts() async {}
  @override
  Future<void> resetIdentity() async {}
}

// ── Fixtures ───────────────────────────────────────────────────────

PickedRecording _file({
  String name = 'call.mp3',
  int? sizeBytes,
  Uint8List? bytes,
}) {
  final b = bytes ?? Uint8List.fromList(List.filled(2048, 7));
  return PickedRecording(
    name: name,
    extension: 'mp3',
    sizeBytes: sizeBytes ?? b.length,
    bytes: b,
  );
}

RecordingAnalyzer _analyzer({
  _FakeDecoder? decoder,
  _SpyAcoustic? acoustic,
  _FakeTranscription? transcription,
  IIncidentRepository? incidents,
}) {
  return RecordingAnalyzer(
    decoder: decoder ?? _FakeDecoder(),
    acousticService: acoustic ?? _SpyAcoustic(),
    transcriptionService: transcription ?? _FakeTranscription(),
    incidentRepository: incidents ?? InMemoryIncidentRepository(seed: false),
    pollInterval: Duration.zero,
  );
}

/// Egyptian-Arabic scam script — hits impersonation + financial +
/// urgency + secrecy so all three fused vectors exceed 0.75.
const _scamTranscript =
    'أنا أخوك، حول لي فلوس على المحفظة بسرعة دلوقتي ومتقولش لحد';

IncidentReport _incident({String id = 'INC-2026-0001'}) => IncidentReport(
      id: id,
      timestamp: DateTime(2026, 1, 1),
      callerLabel: 'Uploaded Recording',
      callDurationSeconds: 12,
      audioDigestSha256: 'a' * 64,
      audioSourceLabel: 'Uploaded Recording',
      transcriptionSourceLabel: 'AssemblyAI Pre-recorded',
      peakRiskScore: 0.9,
      riskLevel: ThreatRiskLevel.highRisk,
      threatReasons: const ['Financial transfer demand detected'],
      acousticMetrics: const AudioForensicMetrics(
        spectralFlux: 0.02,
        spectralRolloffRatio: 0.05,
        zeroCrossingRate: 0.02,
        syntheticVoiceScore: 0.9,
      ),
      semanticSignals: const SemanticThreatSignals.empty(),
      transcriptSnippets: const [],
      recommendedActions: const ['Verify the caller'],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    IncidentRepositoryLocator.instance =
        InMemoryIncidentRepository(seed: false);
    FamilyContactLocator.instance = PersistedFamilyContactRepository();
    PushIdentityLocator.instance = _FakePush();
  });

  // ── File handling ──────────────────────────────────────────────

  group('file handling', () {
    test('picker cancellation is harmless', () async {
      final picker = _FakePicker(null);
      final result = await picker.pickRecording();
      expect(result, isNull);
      expect(picker.calls, 1);
    });

    test('empty file is rejected before decoding', () async {
      final decoder = _FakeDecoder();
      final analyzer = _analyzer(decoder: decoder);
      await expectLater(
        analyzer.analyze(
          _file(bytes: Uint8List(0), sizeBytes: 0),
          mode: RecordingPrivacyMode.onDevice,
        ),
        throwsA(isA<RecordingAnalysisException>()),
      );
      expect(decoder.inspectCalls, 0);
      expect(decoder.decodeCalls, 0);
    });

    test('oversized file is rejected before full processing', () async {
      final decoder = _FakeDecoder();
      final analyzer = _analyzer(decoder: decoder);
      await expectLater(
        analyzer.analyze(
          _file(sizeBytes: RecordingAnalyzer.maxSourceBytes + 1),
          mode: RecordingPrivacyMode.onDevice,
        ),
        throwsA(isA<RecordingAnalysisException>()),
      );
      expect(decoder.inspectCalls, 0); // rejected on reported size
    });

    test('over-duration recording is rejected after metadata', () async {
      final decoder = _FakeDecoder(
        info: const RecordingAudioInfo(
          duration: Duration(minutes: 16),
          sampleRate: 16000,
          channels: 1,
          format: 'wav',
        ),
      );
      final analyzer = _analyzer(decoder: decoder);
      await expectLater(
        analyzer.analyze(_file(), mode: RecordingPrivacyMode.onDevice),
        throwsA(isA<RecordingAnalysisException>()),
      );
      expect(decoder.inspectCalls, 1);
      expect(decoder.decodeCalls, 0); // never fully decoded
    });

    test('unsupported/corrupt codec fails truthfully', () async {
      final decoder = _FakeDecoder(
        inspectError: const RecordingAnalysisException(
          'unsupported',
          code: 'unsupported',
        ),
      );
      final analyzer = _analyzer(decoder: decoder);
      await expectLater(
        analyzer.analyze(_file(), mode: RecordingPrivacyMode.onDevice),
        throwsA(
          isA<RecordingAnalysisException>()
              .having((e) => e.code, 'code', 'unsupported'),
        ),
      );
    });

    test('decoder failure surfaces a clear error, not a crash', () async {
      final decoder = _FakeDecoder(
        decodeError: const RecordingAnalysisException(
          'decode failed',
          code: 'decodeFailed',
        ),
      );
      final analyzer = _analyzer(decoder: decoder);
      await expectLater(
        analyzer.analyze(_file(), mode: RecordingPrivacyMode.onDevice),
        throwsA(
          isA<RecordingAnalysisException>()
              .having((e) => e.code, 'code', 'decodeFailed'),
        ),
      );
    });

    test('normalization targets 16 kHz mono PCM16', () {
      // The plugin decoder's contract — one normalized format for the
      // whole pipeline.
      expect(PluginRecordingAudioDecoder.targetSampleRate, 16000);
      expect(PluginRecordingAudioDecoder.targetChannels, 1);
      expect(PluginRecordingAudioDecoder.targetBitDepth, 16);
    });

    test('SHA-256 is computed over the normalized PCM, not the file',
        () async {
      final pcm = PcmCodec.samplesToPcm16(
        List.generate(4096, (i) => (i % 100) / 100),
      );
      final decoder = _FakeDecoder(pcm: pcm);
      final analyzer = _analyzer(decoder: decoder);
      final result = await analyzer.analyze(
        _file(bytes: Uint8List.fromList([1, 2, 3])),
        mode: RecordingPrivacyMode.onDevice,
      );
      expect(result, isNotNull);
      // Digest matches the exact decoded bytes, not the source file.
      expect(
        result!.audioDigestSha256,
        sha256.convert(pcm).toString(),
      );
    });
  });

  // ── Local-only analysis ──────────────────────────────────────────

  group('on-device analysis', () {
    test('local mode performs zero transcription network calls',
        () async {
      final transcription = _FakeTranscription();
      final analyzer = _analyzer(transcription: transcription);
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
      );
      expect(result, isNotNull);
      expect(transcription.submitCalls, 0);
      expect(transcription.pollCalls, 0);
    });

    test('whole recording is analyzed across multiple chunks', () async {
      final acoustic = _SpyAcoustic();
      // 5 chunks worth of PCM16 (2048 samples each + tail).
      final pcm = PcmCodec.samplesToPcm16(
        List.filled(RecordingAnalyzer.chunkSamples * 4 + 500, 0.2),
      );
      final analyzer = _analyzer(
        decoder: _FakeDecoder(pcm: pcm),
        acoustic: acoustic,
      );
      await analyzer.analyze(_file(), mode: RecordingPrivacyMode.onDevice);
      expect(acoustic.chunkSizes.length, 5);
      expect(acoustic.chunkSizes.sublist(0, 4),
          everyElement(RecordingAnalyzer.chunkSamples));
      expect(acoustic.chunkSizes.last, 500);
    });

    test('acoustic service is reset between recordings', () async {
      final acoustic = _SpyAcoustic();
      final analyzer = _analyzer(acoustic: acoustic);
      await analyzer.analyze(_file(), mode: RecordingPrivacyMode.onDevice);
      await analyzer.analyze(_file(), mode: RecordingPrivacyMode.onDevice);
      expect(acoustic.resets, 2);
    });

    test('acoustic-only result is partial — never a normal verdict',
        () async {
      final analyzer = _analyzer();
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
      );
      expect(result!.isPartial, isTrue);
      expect(result.report, isNull);
      expect(result.semanticSignals, isNull);
      expect(result.transcriptSourceLabel, contains('acoustic'));
    });

    test('elevated acoustic-only persists a clearly-partial incident',
        () async {
      final incidents = InMemoryIncidentRepository(seed: false);
      final analyzer = _analyzer(
        incidents: incidents,
        acoustic: _SpyAcoustic(_SpyAcoustic._elevatedMetrics),
        // Enough chunks for the EMA to converge past the 0.70
        // elevated threshold (same smoothing semantics as SafeCall).
        decoder: _FakeDecoder(
          pcm: PcmCodec.samplesToPcm16(
            List.filled(RecordingAnalyzer.chunkSamples * 8, 0.1),
          ),
        ),
      );
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
      );
      expect(result!.incident, isNotNull);
      expect(result.incident!.analysisIsPartial, isTrue);
      expect(result.incident!.audioSourceLabel, 'Uploaded Recording');
      expect(result.incident!.callerLabel, isNot(contains('Caller')));
      final all = await incidents.getAllIncidents();
      expect(all.single.analysisIsPartial, isTrue);
    });

    test('low-anomaly acoustic-only result is not persisted', () async {
      final incidents = InMemoryIncidentRepository(seed: false);
      final analyzer = _analyzer(incidents: incidents);
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
      );
      expect(result!.incident, isNull);
      expect(await incidents.getAllIncidents(), isEmpty);
    });

    test('cancelled analysis returns null', () async {
      final analyzer = _analyzer();
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        isCancelled: () => true,
      );
      expect(result, isNull);
    });
  });

  // ── Transcript analysis ──────────────────────────────────────────

  group('transcript analysis', () {
    test('manual transcript feeds the semantic engine', () async {
      final analyzer = _analyzer();
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: _scamTranscript,
      );
      expect(result!.isPartial, isFalse);
      expect(result.report, isNotNull);
      expect(result.transcriptSourceLabel, 'User-provided transcript');
      expect(result.semanticSignals!.detectedKeywords, isNotEmpty);
      expect(result.semanticSignals!.impersonationClaims, isNotEmpty);
    });

    test('provider transcript feeds the semantic engine', () async {
      final transcription = _FakeTranscription()
        ..pollQueue.add(const RecordedTranscriptJob(
          status: RecordedTranscriptionStatus.completed,
          text: _scamTranscript,
        ));
      final analyzer = _analyzer(transcription: transcription);
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.enhancedTranscription,
      );
      expect(result!.isPartial, isFalse);
      expect(result.transcriptSourceLabel, 'AssemblyAI Pre-recorded');
      expect(result.report, isNotNull);
      expect(transcription.submitCalls, 1);
    });

    test('provider failure degrades to a truthful partial result',
        () async {
      final transcription = _FakeTranscription()
        ..submitError = const RecordedTranscriptionException('down');
      final analyzer = _analyzer(transcription: transcription);
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.enhancedTranscription,
      );
      expect(result!.isPartial, isTrue);
      expect(result.report, isNull);
      expect(result.transcriptText, isNull); // never fabricated
    });

    test('unconfigured transcription is rejected with clear copy',
        () async {
      final analyzer = _analyzer(
        transcription: _FakeTranscription(configured: false),
      );
      await expectLater(
        analyzer.analyze(
          _file(),
          mode: RecordingPrivacyMode.enhancedTranscription,
        ),
        throwsA(
          isA<RecordingAnalysisException>().having(
            (e) => e.code,
            'code',
            'transcriptionUnavailable',
          ),
        ),
      );
    });

    test('full analysis uses the real ThreatFusionEngine math',
        () async {
      // All three vectors ≈ 1.0 + impersonation → amplified composite.
      final analyzer = _analyzer();
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: _scamTranscript,
      );
      final report = result!.report!;
      // semantic≈1.0 → composite = 1.0*0.65 amplified → ~0.78+.
      expect(report.compositeRiskScore, greaterThan(0.70));
      expect(report.riskLevel, ThreatRiskLevel.highRisk);
      expect(report.primaryThreatReasons, isNotEmpty);
    });

    test('Arabic scam transcript produces expected semantic signals',
        () async {
      final analyzer = _analyzer();
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: _scamTranscript,
      );
      final s = result!.semanticSignals!;
      expect(s.urgencyScore, greaterThan(0));
      expect(s.financialDemandScore, greaterThan(0));
      expect(s.secrecyScore, greaterThan(0));
      expect(s.impersonationClaims, isNotEmpty);
    });

    test('no fake speaker labels — stored snippet says Recording',
        () async {
      final incidents = InMemoryIncidentRepository(seed: false);
      final analyzer = _analyzer(incidents: incidents);
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: _scamTranscript,
      );
      final incident = result!.incident!;
      expect(incident.transcriptSnippets.single.speaker, 'Recording');
      expect(incident.transcriptSnippets.single.speaker,
          isNot('Caller'));
    });

    test('flagged full analysis persists; safe does not', () async {
      final incidents = InMemoryIncidentRepository(seed: false);
      final analyzer = _analyzer(incidents: incidents);
      // High-risk transcript → persisted.
      final flagged = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: _scamTranscript,
      );
      expect(flagged!.incident, isNotNull);
      // Benign transcript → safe → not persisted.
      final calm = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: 'Hi grandma, how was your weekend?',
      );
      expect(calm!.incident, isNull);
      expect((await incidents.getAllIncidents()).length, 1);
    });
  });

  // ── Recorded transcription client ────────────────────────────────

  group('recorded transcription client', () {
    final audio = Uint8List.fromList([1, 2, 3, 4, 5]);

    test('unconfigured service refuses before any network call',
        () async {
      var httpCalls = 0;
      final svc = RelayRecordedTranscriptionService(
        httpClient: http_testing.MockClient((req) async {
          httpCalls++;
          return http.Response('{}', 200);
        }),
        baseUrl: '',
        token: '',
      );
      expect(svc.isConfigured, isFalse);
      await expectLater(
        svc.submitJob(audio, formatHint: 'mp3'),
        throwsA(isA<RecordedTranscriptionException>()),
      );
      expect(httpCalls, 0);
    });

    test('job creation posts raw audio with auth + format hint',
        () async {
      Uri? uri;
      Map<String, String>? headers;
      List<int>? body;
      final svc = RelayRecordedTranscriptionService(
        httpClient: http_testing.MockClient((req) async {
          uri = req.url;
          headers = req.headers;
          body = req.bodyBytes;
          return http.Response('{"job_id":"job-9"}', 202);
        }),
        baseUrl: 'https://relay.example.com',
        token: 'tok',
      );
      final id = await svc.submitJob(audio, formatHint: 'mp3');
      expect(id, 'job-9');
      expect(uri!.path, '/transcription/jobs');
      expect(headers!['Authorization'], 'Bearer tok');
      expect(headers!['X-Audio-Format'], 'mp3');
      expect(body, audio); // raw bytes — no wrapping
    });

    test('polling maps queued → processing → completed → error',
        () async {
      var n = 0;
      final svc = RelayRecordedTranscriptionService(
        httpClient: http_testing.MockClient((req) async {
          n++;
          final statuses = ['queued', 'processing', 'completed'];
          final s = statuses[(n - 1).clamp(0, 2)];
          final body = s == 'completed'
              ? '{"status":"completed","text":"hello world"}'
              : '{"status":"$s"}';
          return http.Response(body, 200);
        }),
        baseUrl: 'https://relay.example.com',
        token: 'tok',
      );
      expect((await svc.pollJob('j')).status,
          RecordedTranscriptionStatus.queued);
      expect((await svc.pollJob('j')).status,
          RecordedTranscriptionStatus.processing);
      final done = await svc.pollJob('j');
      expect(done.status, RecordedTranscriptionStatus.completed);
      expect(done.text, 'hello world');
    });

    test('provider error maps to a safe failure status', () async {
      final svc = RelayRecordedTranscriptionService(
        httpClient: http_testing.MockClient((req) async {
          return http.Response('{"status":"error"}', 200);
        }),
        baseUrl: 'https://relay.example.com',
        token: 'tok',
      );
      expect((await svc.pollJob('j')).status,
          RecordedTranscriptionStatus.failed);
    });

    test('non-2xx responses raise a safe exception', () async {
      final svc = RelayRecordedTranscriptionService(
        httpClient: http_testing.MockClient((req) async {
          return http.Response('server exploded', 500);
        }),
        baseUrl: 'https://relay.example.com',
        token: 'tok',
      );
      await expectLater(
        svc.submitJob(audio, formatHint: 'mp3'),
        throwsA(isA<RecordedTranscriptionException>()),
      );
      await expectLater(
        svc.pollJob('j'),
        throwsA(isA<RecordedTranscriptionException>()),
      );
    });

    test('malformed job response raises a safe exception', () async {
      final svc = RelayRecordedTranscriptionService(
        httpClient: http_testing.MockClient((req) async {
          return http.Response('{"nope":true}', 202);
        }),
        baseUrl: 'https://relay.example.com',
        token: 'tok',
      );
      await expectLater(
        svc.submitJob(audio, formatHint: 'mp3'),
        throwsA(isA<RecordedTranscriptionException>()),
      );
    });
  });

  // ── Persistence ──────────────────────────────────────────────────

  group('persisted incident repository', () {
    test('a fresh production history is honestly empty', () async {
      final repo = PersistedIncidentRepository();
      expect(await repo.getAllIncidents(), isEmpty);
    });

    test('incident survives repository recreation', () async {
      final repo = PersistedIncidentRepository();
      await repo.saveIncident(_incident());
      final recreated = PersistedIncidentRepository();
      final all = await recreated.getAllIncidents();
      expect(all.single.id, 'INC-2026-0001');
      expect(all.single.audioSourceLabel, 'Uploaded Recording');
    });

    test('duplicate ids upsert rather than duplicate', () async {
      final repo = PersistedIncidentRepository();
      await repo.saveIncident(_incident());
      await repo.saveIncident(_incident());
      expect((await repo.getAllIncidents()).length, 1);
    });

    test('corrupt saved rows are skipped safely', () async {
      final good = _incident();
      SharedPreferences.setMockInitialValues({
        'voxguard.incidents_v1': jsonEncode([
          'garbage',
          42,
          {'id': 5},
          good.toJson(),
          {'id': 'INC-2026-0001', 'bogus': true}, // dup id, malformed
        ]),
      });
      final repo = PersistedIncidentRepository();
      final all = await repo.getAllIncidents();
      expect(all.length, 1);
      expect(all.single.id, good.id);
    });

    test('non-list storage degrades to empty, not a crash', () async {
      SharedPreferences.setMockInitialValues({
        'voxguard.incidents_v1': '{"not":"a list"}',
      });
      final repo = PersistedIncidentRepository();
      expect(await repo.getAllIncidents(), isEmpty);
    });

    test('repository cap is enforced, newest kept', () async {
      final repo = PersistedIncidentRepository(maxIncidents: 3);
      for (var i = 0; i < 5; i++) {
        await repo.saveIncident(_incident(id: 'INC-2026-000$i'));
      }
      final all = await repo.getAllIncidents();
      expect(all.length, 3);
      expect(all.first.id, 'INC-2026-0004'); // newest first
      expect(all.any((i) => i.id == 'INC-2026-0000'), isFalse);
    });

    test('recording provenance survives a persistence round-trip',
        () async {
      final incidents = PersistedIncidentRepository();
      final analyzer = _analyzer(incidents: incidents);
      final result = await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: _scamTranscript,
      );
      expect(result!.incident, isNotNull);
      final recreated = PersistedIncidentRepository();
      final restored =
          await recreated.getIncidentById(result.incident!.id);
      expect(restored, isNotNull);
      expect(restored!.audioSourceLabel, 'Uploaded Recording');
      expect(restored.transcriptionSourceLabel,
          'User-provided transcript');
      expect(restored.analysisIsPartial, isFalse);
      expect(restored.audioDigestSha256,
          result.audioDigestSha256);
    });

    test('raw audio bytes are never persisted', () async {
      final incidents = PersistedIncidentRepository();
      final analyzer = _analyzer(incidents: incidents);
      await analyzer.analyze(
        _file(),
        mode: RecordingPrivacyMode.onDevice,
        manualTranscript: _scamTranscript,
      );
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('voxguard.incidents_v1')!;
      final rows = jsonDecode(raw) as List;
      for (final row in rows) {
        final keys = (row as Map).keys.join(',');
        expect(keys, isNot(contains('bytes')));
        expect(keys, isNot(contains('pcm')));
        expect(keys, isNot(contains('audio_data')));
      }
      // Only the 64-char digest travels — no audio payload.
      expect(raw.length, lessThan(20000));
    });
  });

  // ── UI ───────────────────────────────────────────────────────────

  Widget app(Widget child) => MaterialApp(home: child);

  group('Analyze Recording UI', () {
    testWidgets('home tile opens the real screen, not coming soon',
        (tester) async {
      await tester.pumpWidget(app(const HomeScreen()));
      await tester.pump();
      await tester.ensureVisible(find.text('Analyze Recording'));
      await tester.pump();
      await tester.tap(find.text('Analyze Recording'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyzeRecordingScreen), findsOneWidget);
      expect(find.textContaining('coming soon'), findsNothing);
    });

    testWidgets('picker cancellation keeps the empty state',
        (tester) async {
      await tester.pumpWidget(app(AnalyzeRecordingScreen(
        picker: _FakePicker(null),
        analyzer: _analyzer(),
      )));
      await tester.tap(find.text('Choose audio'));
      await tester.pumpAndSettle();
      expect(find.text('Analyze a call recording or voice note'),
          findsOneWidget);
    });

    testWidgets('selected file shows summary + privacy modes',
        (tester) async {
      await tester.pumpWidget(app(AnalyzeRecordingScreen(
        picker: _FakePicker(_file()),
        analyzer: _analyzer(),
      )));
      await tester.tap(find.text('Choose audio'));
      await tester.pumpAndSettle();
      expect(find.text('call.mp3'), findsOneWidget);
      expect(find.text('Keep audio on this device'), findsOneWidget);
      expect(find.text('Include conversation analysis'),
          findsOneWidget);
    });

    testWidgets('on-device result renders Partial Analysis, '
        'never a Threat Score', (tester) async {
      await tester.pumpWidget(app(AnalyzeRecordingScreen(
        picker: _FakePicker(_file()),
        analyzer: _analyzer(),
      )));
      await tester.tap(find.text('Choose audio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analyze recording'));
      await tester.pumpAndSettle();
      expect(find.text('PARTIAL ANALYSIS'), findsOneWidget);
      expect(find.text('Threat Score'), findsNothing);
      expect(find.textContaining('cannot produce a complete'),
          findsOneWidget);
    });

    testWidgets('full result shows the threat band + incident',
        (tester) async {
      final incidents = InMemoryIncidentRepository(seed: false);
      await tester.pumpWidget(app(AnalyzeRecordingScreen(
        picker: _FakePicker(_file()),
        analyzer: _analyzer(incidents: incidents),
      )));
      await tester.tap(find.text('Choose audio'));
      await tester.pumpAndSettle();
      // Provide a transcript via the manual path.
      await tester.tap(find.text('Add transcript text instead'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), _scamTranscript);
      // The button sits below the expanded field — scroll the
      // ListView until it is built, then tap.
      await tester.scrollUntilVisible(
        find.text('Analyze recording'),
        200,
        scrollable: find.ancestor(
          of: find.text('call.mp3'),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Analyze recording'));
      await tester.pumpAndSettle();
      expect(find.text('Threat Score'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
      // Flagged → persisted → reachable through the incident button.
      expect(await incidents.getAllIncidents(), isNotEmpty);
      await tester.scrollUntilVisible(
        find.text('View Incident Report'),
        200,
        // Result state has a single Scrollable — the body ListView.
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('View Incident Report'));
      await tester.pumpAndSettle();
      expect(find.byType(IncidentDetailScreen), findsOneWidget);
    });

    testWidgets('unconfigured transcription disables enhanced mode',
        (tester) async {
      await tester.pumpWidget(app(AnalyzeRecordingScreen(
        picker: _FakePicker(_file()),
        analyzer: _analyzer(
          transcription: _FakeTranscription(configured: false),
        ),
      )));
      await tester.tap(find.text('Choose audio'));
      await tester.pumpAndSettle();
      expect(find.textContaining('isn\u2019t configured in this'),
          findsOneWidget);
    });
  });
}
