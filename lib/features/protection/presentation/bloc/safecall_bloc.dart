import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio/audio_stream_source.dart';
import '../../../../core/services/audio/demo_audio_source.dart';
import '../../../../core/services/audio/microphone_audio_source.dart';
import '../../../../core/services/audio/pcm_codec.dart';
import '../../../../core/services/transcription/assemblyai_streaming_service.dart';
import '../../../../core/services/transcription/streaming_transcription_service.dart';
import '../../../forensics/domain/models/incident_report.dart';
import '../../../forensics/domain/services/incident_repository.dart';
import '../../../paywall/domain/services/product_access.dart';
import '../../domain/models/audio_forensic_metrics.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/semantic_threat_signals.dart';
import '../../domain/models/transcript_snippet.dart';
import '../../domain/services/acoustic_forensics_service.dart';
import '../../domain/services/semantic_threat_service.dart';
import '../../domain/services/threat_fusion_engine.dart';
import '../../domain/services/transcript_buffer.dart';
import 'safecall_event.dart';
import 'safecall_state.dart';

/// Orchestrates a SafeCall protection session.
///
/// Two session modes share one pipeline:
///
///   Live Mic — real microphone PCM via [MicrophoneAudioSource],
///              streaming STT via [IStreamingTranscriptionService]
///              when configured.
///   Demo     — deterministic generated PCM via [DemoAudioSource] plus
///              the scripted Egyptian-Arabic scam dialogue.
///
/// Every chunk — whatever its provenance — flows through
/// `AcousticForensicsService` → `ThreatFusionEngine` → HUD, and its
/// PCM16 bytes are folded into a session SHA-256 digest. Committed
/// transcript segments accumulate in a [TranscriptBuffer] whose
/// rolling context feeds `SemanticThreatService`, so scam phrases
/// split across STT chunks still resolve.
final class SafeCallBloc extends Bloc<SafeCallEvent, SafeCallState> {
  SafeCallBloc({
    AcousticForensicsService? acousticService,
    SemanticThreatService? semanticService,
    ThreatFusionEngine? fusionEngine,
    IAudioStreamSource? microphoneSource,
    DemoAudioSource? demoSource,
    IStreamingTranscriptionService? transcriptionService,
    IProductAccess? productAccess,
    @visibleForTesting SafeCallState? initialState,
  })  : _acousticService = acousticService ?? AcousticForensicsService(),
        _semanticService = semanticService ?? SemanticThreatService(),
        _fusionEngine = fusionEngine ?? ThreatFusionEngine(),
        _micSource = microphoneSource ?? MicrophoneAudioSource(),
        _demoSource = demoSource ?? DemoAudioSource(),
        _stt = transcriptionService ?? AssemblyAiStreamingService(),
        _productAccess = productAccess ?? ProductAccessLocator.instance,
        super(initialState ?? const SafeCallInitial()) {
    on<StartLiveMicSessionEvent>(
        (e, emit) => _serialized(() => _onStartLiveMic(e, emit)));
    on<StartDemoSessionEvent>(
        (e, emit) => _serialized(() => _onStartDemo(e, emit)));
    on<IncomingAudioChunkEvent>(_onAudioChunk);
    on<IncomingTranscriptSnippetEvent>(_onTranscript);
    on<IncomingTranscriptPartialEvent>(_onTranscriptPartial);
    on<AnalyzeTranscriptContextEvent>(
        (_, emit) => _runSemanticAnalysis(emit));
    on<TranscriptionStatusChangedEvent>(_onSttStatus);
    on<SimulateDemoAttackEvent>(_onSimulateDemo);
    on<EndCallEvent>((e, emit) => _serialized(() => _onEnd(e, emit)));
    on<ResetCallEvent>(
        (e, emit) => _serialized(() => _onReset(e, emit)));
  }

  /// Presentation-test seam — starts the bloc preloaded with a state
  /// the real audio pipeline would take seconds of fake timers to
  /// reach (e.g. a high-risk monitoring snapshot).
  @visibleForTesting
  factory SafeCallBloc.seeded(SafeCallState seed) =>
      SafeCallBloc(initialState: seed);

  // ── Session constants ────────────────────────────────────────────
  static const double _acousticSmoothing = 0.35;

  /// Light amplitude smoothing — keeps the Signal Lens pulse reactive
  /// to speech without jittering on every 30 ms frame.
  static const double _amplitudeSmoothing = 0.4;

  /// Debounce for semantic analysis of partial STT hypotheses —
  /// committed segments analyze immediately; partials wait this long.
  static const Duration _partialAnalysisDebounce =
      Duration(milliseconds: 1200);

  /// Scripted scam monologue (Egyptian Arabic) injected progressively
  /// by [SimulateDemoAttackEvent] in demo sessions.
  static const List<String> _demoScript = [
    'ألو… أنا أخوك، الصوت متغير شوية عشان الخط',
    'أنا في مشكلة كبيرة ومحتاجك تساعدني دلوقتي',
    'حول لي 2,000 جنيه بسرعة على المحفظة',
    'ومتقولش لحد، الموضوع خطير وبيني وبينك',
  ];
  static const Duration _demoLineInterval = Duration(milliseconds: 1400);

  // ── Dependencies & session state ─────────────────────────────────
  final AcousticForensicsService _acousticService;
  final SemanticThreatService _semanticService;
  final ThreatFusionEngine _fusionEngine;
  final IAudioStreamSource _micSource;
  final DemoAudioSource _demoSource;
  final IStreamingTranscriptionService _stt;

  /// Product-access layer — gates cloud STT by entitlement. Demo
  /// sessions never touch this: the scripted transcript path stays
  /// free for everyone.
  final IProductAccess _productAccess;
  final Random _rng = Random();

  StreamSubscription<AudioChunk>? _audioSub;
  StreamSubscription<TranscriptEvent>? _sttSub;
  StreamSubscription<TranscriptionSessionStatus>? _sttStatusSub;
  final List<Timer> _demoTimers = [];
  Timer? _partialDebounce;

  IAudioStreamSource? _activeSource;
  bool _demoActive = false;
  bool _sttLive = false;

  /// Whether the streaming provider actually delivered transcript
  /// this session — incident provenance must credit a provider that
  /// contributed data even if it disconnected before call end.
  bool _sttContributed = false;
  double _lastAmplitude = 0;
  ThreatRiskLevel _peakRisk = ThreatRiskLevel.safe;
  List<TranscriptSnippet> _transcript = const [];
  final TranscriptBuffer _buffer = TranscriptBuffer();
  String _partialTranscript = '';

  /// Forensic bookkeeping — call start time and a genuine rolling
  /// SHA-256 digest over every normalized PCM byte analyzed.
  DateTime? _sessionStart;
  final BytesBuilder _audioBytes = BytesBuilder(copy: false);
  String? _finalizedDigest;
  AudioForensicMetrics _acoustic = const AudioForensicMetrics.zero();
  SemanticThreatSignals _semantic = const SemanticThreatSignals.empty();

  /// Session-transition mutex. Bloc handlers are serialized per event
  /// TYPE only — Start/Reset/End are different types and would
  /// otherwise interleave mid-teardown. Every session-control handler
  /// runs inside this tail so at most one transition — and one audio
  /// source — exists at any moment.
  Future<void> _transitionTail = Future.value();

  Future<void> _serialized(Future<void> Function() work) {
    final completer = Completer<void>();
    final prev = _transitionTail;
    _transitionTail = completer.future;
    prev.whenComplete(() async {
      try {
        await work();
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  // ── Session start ────────────────────────────────────────────────

  Future<void> _onStartLiveMic(
    StartLiveMicSessionEvent event,
    Emitter<SafeCallState> emit,
  ) async {
    if (!isClosed) {
      emit(const SafeCallStarting(
          audioSourceType: AudioSourceType.microphone));
    }

    // Teardown the previous session BEFORE any validation — if mic
    // permission is denied the user lands on an error state with no
    // audio source still running underneath it.
    await _teardownAudio();
    _resetSession();

    if (!_micSource.isSupported) {
      emit(const SafeCallError(
        message: 'Microphone capture is not supported on this '
            'platform. Try Demo Mode instead.',
      ));
      return;
    }

    final permission = await _micSource.ensurePermission();
    switch (permission) {
      case MicPermissionState.unsupported:
        emit(const SafeCallError(
          message: 'Microphone capture is not supported on this '
              'platform. Try Demo Mode instead.',
        ));
        return;
      case MicPermissionState.permanentlyDenied:
      case MicPermissionState.restricted:
        emit(const SafeCallError(
          message: 'Microphone access is blocked. Enable it in system '
              'settings, or use Demo Mode.',
          permanentlyDenied: true,
        ));
        return;
      case MicPermissionState.denied:
        emit(const SafeCallError(
          message: 'Microphone permission was denied. Grant access to '
              'run Live Mic, or use Demo Mode.',
        ));
        return;
      case MicPermissionState.granted:
        break;
    }

    _activeSource = _micSource;

    // Start streaming STT only when the plan entitles it AND the
    // provider is configured. A paid entitlement cannot manufacture
    // missing infrastructure; a missing entitlement must not start
    // the cloud stream even when configured — free Live Mic stays
    // acoustic-only.
    _sttLive = false;
    if (_stt.isConfigured &&
        _productAccess.capabilities.liveCloudTranscription) {
      try {
        await _stt.start(sampleRate: _micSource.sampleRate);
        _sttSub = _stt.events.listen(
          (e) {
            // Mark real transcript contribution for incident
            // provenance — survives a later STT disconnect.
            if (e.text.trim().isNotEmpty) _sttContributed = true;
            if (e.isFinal) {
              add(IncomingTranscriptSnippetEvent(
                  speaker: 'Caller', text: e.text));
            } else {
              add(IncomingTranscriptPartialEvent(e.text));
            }
          },
          onError: (_) {}, // STT errors degrade to acoustic-only.
        );
        // Liveness is authoritative from the provider — the session is
        // only "transcription live" once it confirms usable, and a
        // mid-session drop flips the UI back to acoustic-only without
        // touching the protection session.
        _sttStatusSub = _stt.status.listen((status) => add(
              TranscriptionStatusChangedEvent(
                status == TranscriptionSessionStatus.live,
              ),
            ));
        _sttLive = true;
      } catch (_) {
        _sttLive = false;
      }
    }

    try {
      await _micSource.start();
    } catch (_) {
      await _teardownAudio();
      emit(const SafeCallError(
        message: 'Microphone failed to start. Check the device and '
            'retry, or use Demo Mode.',
      ));
      return;
    }

    _sessionStart = DateTime.now();
    _listenToSource(_micSource);
    if (!emit.isDone) emit(_snapshot());
  }

  Future<void> _onStartDemo(
    StartDemoSessionEvent event,
    Emitter<SafeCallState> emit,
  ) async {
    // Same teardown-first rule as Live Mic — never two live sources.
    await _teardownAudio();
    _resetSession();
    _activeSource = _demoSource;
    _sessionStart = DateTime.now();
    await _demoSource.start();
    _listenToSource(_demoSource);
    emit(_snapshot());
  }

  /// Subscribes the shared pipeline to [source]. The same handler runs
  /// regardless of provenance — acoustic analysis, amplitude, STT
  /// forwarding and digest folding are all source-agnostic.
  void _listenToSource(IAudioStreamSource source) {
    _audioSub?.cancel();
    _audioSub = source.chunks.listen(
      (chunk) => add(IncomingAudioChunkEvent(chunk)),
      onError: (Object e) {
        if (state is SafeCallMonitoring) {
          add(const EndCallEvent());
        }
      },
    );
  }

  // ── Pipeline events ──────────────────────────────────────────────

  void _onAudioChunk(
    IncomingAudioChunkEvent event,
    Emitter<SafeCallState> emit,
  ) {
    if (state is! SafeCallMonitoring && state is! SafeCallStarting) return;

    final chunk = event.chunk;

    // Genuine session digest over the exact bytes analyzed.
    _audioBytes.add(chunk.pcm16Bytes);

    // Forward to streaming STT in live mic sessions.
    if (_sttLive) _stt.sendAudio(chunk.pcm16Bytes);

    final rms = PcmCodec.rms(chunk.samples);
    _lastAmplitude = _amplitudeSmoothing * rms +
        (1 - _amplitudeSmoothing) * _lastAmplitude;

    final raw = _acousticService.analyze(chunk.samples);
    _acoustic = _acoustic.lerpTo(raw, _acousticSmoothing);
    emit(_snapshot());
  }

  Future<void> _onTranscript(
    IncomingTranscriptSnippetEvent event,
    Emitter<SafeCallState> emit,
  ) async {
    if (state is! SafeCallMonitoring) return;

    _buffer.commit(event.text);
    _partialTranscript = '';
    _transcript = [
      ..._transcript,
      TranscriptSnippet(
        speaker: event.speaker,
        text: event.text,
        timestamp: DateTime.now(),
      ),
    ];
    await _runSemanticAnalysis(emit);
  }

  void _onTranscriptPartial(
    IncomingTranscriptPartialEvent event,
    Emitter<SafeCallState> emit,
  ) {
    if (state is! SafeCallMonitoring) return;

    _buffer.updatePartial(event.text);
    _partialTranscript = _buffer.partial;
    emit(_snapshot());

    // Debounced semantic pass over the rolling context — partials
    // display instantly but analysis waits for text to settle.
    _partialDebounce?.cancel();
    _partialDebounce = Timer(_partialAnalysisDebounce, () {
      if (!isClosed && state is SafeCallMonitoring) {
        add(const AnalyzeTranscriptContextEvent());
      }
    });
  }

  /// Internal: provider session-status changes. A mid-session STT drop
  /// only downgrades `isTranscriptionLive` — acoustic analysis and the
  /// protection session continue untouched.
  void _onSttStatus(
    TranscriptionStatusChangedEvent event,
    Emitter<SafeCallState> emit,
  ) {
    if (_sttLive == event.live) return;
    _sttLive = event.live;
    if (state is SafeCallMonitoring) emit(_snapshot());
  }

  /// Internal debounce target — keeps analysis off the per-partial
  /// hot path.
  Future<void> _runSemanticAnalysis(Emitter<SafeCallState> emit) async {
    // Analyze the accumulated caller speech as one rolling document so
    // phrases split across STT segments still resolve.
    _semantic =
        await _semanticService.analyze(_buffer.analysisContext);
    if (state is! SafeCallMonitoring || emit.isDone) return;
    emit(_snapshot());
  }

  void _onSimulateDemo(
    SimulateDemoAttackEvent event,
    Emitter<SafeCallState> emit,
  ) {
    if (state is! SafeCallMonitoring || !_activeSourceIsDemo) return;

    if (_demoActive) {
      _cancelDemoTimers();
      _demoActive = false;
      _demoSource.setAttackMode(false);
      emit(_snapshot(demoActive: false));
      return;
    }

    _demoActive = true;
    _demoSource.setAttackMode(true);
    emit(_snapshot(demoActive: true));

    for (var i = 0; i < _demoScript.length; i++) {
      final line = _demoScript[i];
      _demoTimers.add(
        Timer(_demoLineInterval * (i + 1), () {
          if (!isClosed && _demoActive) {
            add(
              IncomingTranscriptSnippetEvent(speaker: 'Caller', text: line),
            );
          }
        }),
      );
    }
  }

  bool get _activeSourceIsDemo =>
      _activeSource?.type == AudioSourceType.demo;

  // ── Session end ──────────────────────────────────────────────────

  Future<void> _onEnd(
    EndCallEvent event,
    Emitter<SafeCallState> emit,
  ) async {
    final sourceType = _activeSource?.type ?? AudioSourceType.demo;
    final transcriptionLabel = _transcriptionSourceLabel;
    await _teardownAudio();

    IncidentReport? incident;
    if (_peakRisk == ThreatRiskLevel.highRisk) {
      incident = _buildIncidentReport(sourceType, transcriptionLabel);
      await IncidentRepositoryLocator.instance.saveIncident(incident);
    }
    if (emit.isDone) return;
    emit(SafeCallEnded(peakRiskLevel: _peakRisk, incident: incident));
  }

  /// Builds the incident record for a session that ended at high risk.
  IncidentReport _buildIncidentReport(
    AudioSourceType sourceType,
    String transcriptionLabel,
  ) {
    final report = _fusionEngine.fuse(_acoustic, _semantic);
    final duration = _sessionStart == null
        ? 0
        : DateTime.now().difference(_sessionStart!).inSeconds;
    return IncidentReport(
      id: _nextIncidentId(),
      timestamp: DateTime.now(),
      callerLabel: sourceType == AudioSourceType.microphone
          ? 'Live Microphone Session'
          : 'Unknown Caller (+20 10 ••• ••42)',
      callDurationSeconds: duration,
      audioDigestSha256: _audioDigest,
      audioSourceLabel: sourceType.incidentLabel,
      transcriptionSourceLabel: transcriptionLabel,
      peakRiskScore: report.compositeRiskScore,
      riskLevel: _peakRisk,
      threatReasons: report.primaryThreatReasons,
      acousticMetrics: _acoustic,
      semanticSignals: _semantic,
      transcriptSnippets: _transcript,
      recommendedActions: const [
        'End the call immediately',
        'Do not share OTPs, PINs or banking details',
        'Verify the caller through an official channel',
        'Report the number to your carrier or authorities',
        'Enable Family Shield alerts for relatives',
      ],
    );
  }

  /// Provenance label for the transcription that fed this session.
  /// Credits a provider that delivered transcript data even if it
  /// disconnected before the call ended — current liveness alone
  /// would falsify the record.
  String get _transcriptionSourceLabel {
    if (_activeSourceIsDemo) return 'Local Demo Transcript';
    if (_sttLive || _sttContributed) return _stt.providerLabel;
    return 'None — acoustic analysis only';
  }

  /// Genuine SHA-256 over every normalized PCM16 byte streamed this
  /// session — deterministic on web and native alike.
  ///
  /// `BytesBuilder.takeBytes()` is destructive, so the digest is
  /// finalized exactly once and cached — a second read can never
  /// silently return the digest of an empty buffer.
  String get _audioDigest =>
      _finalizedDigest ??=
          sha256.convert(_audioBytes.takeBytes()).toString();

  String _nextIncidentId() =>
      'INC-${DateTime.now().year}-${(1000 + _rng.nextInt(9000))}';

  /// Reset is a full session transition: bloc event handlers run
  /// sequentially, so awaiting teardown here guarantees no new
  /// session can start while the old source/STT are still closing.
  /// `SafeCallInitial` is only emitted after teardown completes.
  Future<void> _onReset(
    ResetCallEvent event,
    Emitter<SafeCallState> emit,
  ) async {
    await _teardownAudio();
    _resetSession();
    emit(const SafeCallInitial());
  }

  // ── Session plumbing ─────────────────────────────────────────────

  SafeCallMonitoring _snapshot({bool? demoActive}) {
    final report = _fusionEngine.fuse(_acoustic, _semantic);
    if (report.riskLevel.index > _peakRisk.index) {
      _peakRisk = report.riskLevel;
    }
    return SafeCallMonitoring(
      acoustic: _acoustic,
      semantic: _semantic,
      report: report,
      transcript: _transcript,
      audioSourceType:
          _activeSource?.type ?? AudioSourceType.demo,
      demoActive: demoActive ?? _demoActive,
      audioAmplitude: _lastAmplitude,
      isTranscriptionLive: _sttLive,
      cloudTranscriptionEntitled:
          _productAccess.capabilities.liveCloudTranscription,
      partialTranscript: _partialTranscript,
    );
  }

  /// Stops capture + STT without touching accumulated session state.
  Future<void> _teardownAudio() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _activeSource?.stop();
    await _sttSub?.cancel();
    _sttSub = null;
    await _sttStatusSub?.cancel();
    _sttStatusSub = null;
    await _stt.stop();
    _sttLive = false;
    _activeSource = null;
    _cancelDemoTimers();
    _partialDebounce?.cancel();
  }

  void _resetSession() {
    _transcript = const [];
    _buffer.reset();
    _partialTranscript = '';
    _acoustic = const AudioForensicMetrics.zero();
    _semantic = const SemanticThreatSignals.empty();
    _demoActive = false;
    _sttLive = false;
    _sttContributed = false;
    _lastAmplitude = 0;
    _peakRisk = ThreatRiskLevel.safe;
    _sessionStart = null;
    _audioBytes.takeBytes(); // drain
    _finalizedDigest = null;
    _acousticService.reset();
    _demoSource.setAttackMode(false);
  }

  void _cancelDemoTimers() {
    for (final t in _demoTimers) {
      t.cancel();
    }
    _demoTimers.clear();
  }

  @override
  Future<void> close() async {
    await _teardownAudio();
    // Release plugin resources owned by concrete sources; injected
    // test doubles only implement the stream contract.
    final mic = _micSource;
    if (mic is MicrophoneAudioSource) await mic.dispose();
    await _demoSource.dispose();
    return super.close();
  }
}

