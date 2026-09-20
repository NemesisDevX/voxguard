import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../forensics/domain/models/incident_report.dart';
import '../../../forensics/domain/services/incident_repository.dart';
import '../../domain/models/audio_forensic_metrics.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/semantic_threat_signals.dart';
import '../../domain/models/transcript_snippet.dart';
import '../../domain/services/acoustic_forensics_service.dart';
import '../../domain/services/semantic_threat_service.dart';
import '../../domain/services/threat_fusion_engine.dart';
import 'safecall_event.dart';
import 'safecall_state.dart';

/// Orchestrates a SafeCall monitoring session.
///
/// Simulates an incoming PCM audio stream, feeds every chunk through
/// Engine A (acoustic forensics), forwards transcript snippets through
/// Engine B (semantic analysis), and emits the fused threat report.
///
/// [SimulateDemoAttackEvent] toggles a scripted scam conversation that
/// escalates every signal to high risk for demos.
final class SafeCallBloc extends Bloc<SafeCallEvent, SafeCallState> {
  SafeCallBloc({
    AcousticForensicsService? acousticService,
    SemanticThreatService? semanticService,
    ThreatFusionEngine? fusionEngine,
  })  : _acousticService = acousticService ?? AcousticForensicsService(),
        _semanticService = semanticService ?? SemanticThreatService(),
        _fusionEngine = fusionEngine ?? ThreatFusionEngine(),
        super(const SafeCallInitial()) {
    on<StartCallEvent>(_onStart);
    on<IncomingAudioChunkEvent>(_onAudioChunk);
    on<IncomingTranscriptSnippetEvent>(_onTranscript);
    on<SimulateDemoAttackEvent>(_onSimulateDemo);
    on<EndCallEvent>(_onEnd);
    on<ResetCallEvent>(_onReset);
  }

  // ── Simulation constants ─────────────────────────────────────────
  static const int _sampleRate = 16000;
  static const int _chunkSize = 512;
  static const Duration _audioInterval = Duration(milliseconds: 420);
  static const Duration _demoLineInterval = Duration(milliseconds: 1400);
  static const double _acousticSmoothing = 0.35;

  /// Scripted scam monologue (Egyptian Arabic) injected progressively
  /// by [SimulateDemoAttackEvent].
  static const List<String> _demoScript = [
    'ألو… أنا أخوك، الصوت متغير شوية عشان الخط',
    'أنا في مشكلة كبيرة ومحتاجك تساعدني دلوقتي',
    'حول لي 2,000 جنيه بسرعة على المحفظة',
    'ومتقولش لحد، الموضوع خطير وبيني وبينك',
  ];

  // ── Dependencies & session state ─────────────────────────────────
  final AcousticForensicsService _acousticService;
  final SemanticThreatService _semanticService;
  final ThreatFusionEngine _fusionEngine;
  final Random _rng = Random();

  Timer? _audioTimer;
  final List<Timer> _demoTimers = [];

  int _sampleOffset = 0;
  bool _demoActive = false;
  double _lastAmplitude = 0;
  ThreatRiskLevel _peakRisk = ThreatRiskLevel.safe;
  List<TranscriptSnippet> _transcript = const [];

  /// Forensic bookkeeping — call start time and a rolling 32-bit
  /// fingerprint of the streamed audio (stand-in for SHA-256). Kept
  /// under 2^32 so it compiles identically on web and native.
  DateTime? _callStart;
  int _audioHash = 0x811c9dc5;
  AudioForensicMetrics _acoustic = const AudioForensicMetrics.zero();
  SemanticThreatSignals _semantic = const SemanticThreatSignals.empty();

  // ── Event handlers ───────────────────────────────────────────────

  void _onStart(StartCallEvent event, Emitter<SafeCallState> emit) {
    _resetSession();
    _callStart = DateTime.now();
    _startAudioFeed();
    emit(_snapshot());
  }

  void _onAudioChunk(
    IncomingAudioChunkEvent event,
    Emitter<SafeCallState> emit,
  ) {
    if (state is! SafeCallMonitoring) return;

    var sumSq = 0.0;
    for (final s in event.samples) {
      sumSq += s * s;
    }
    _lastAmplitude =
        sqrt(sumSq / max(1, event.samples.length)).clamp(0.0, 1.0);

    final raw = _acousticService.analyze(event.samples);
    _acoustic = _acoustic.lerpTo(raw, _acousticSmoothing);
    emit(_snapshot());
  }

  Future<void> _onTranscript(
    IncomingTranscriptSnippetEvent event,
    Emitter<SafeCallState> emit,
  ) async {
    if (state is! SafeCallMonitoring) return;

    _transcript = [
      ..._transcript,
      TranscriptSnippet(
        speaker: event.speaker,
        text: event.text,
        timestamp: DateTime.now(),
      ),
    ];

    // Analyze the accumulated caller speech as one document.
    final callerSpeech = _transcript
        .where((s) => s.speaker != 'You')
        .map((s) => s.text)
        .join(' ');
    _semantic = await _semanticService.analyze(callerSpeech);
    if (state is! SafeCallMonitoring || emit.isDone) return;
    emit(_snapshot());
  }

  void _onSimulateDemo(
    SimulateDemoAttackEvent event,
    Emitter<SafeCallState> emit,
  ) {
    if (state is! SafeCallMonitoring) return;

    if (_demoActive) {
      // Toggle off — cancel pending injections; acoustic feed returns
      // to the natural profile on the next chunk.
      _cancelDemoTimers();
      _demoActive = false;
      emit(_snapshot(demoActive: false));
      return;
    }

    _demoActive = true;
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

  Future<void> _onEnd(
    EndCallEvent event,
    Emitter<SafeCallState> emit,
  ) async {
    _stopSession();

    IncidentReport? incident;
    if (_peakRisk == ThreatRiskLevel.highRisk) {
      incident = _buildIncidentReport();
      await IncidentRepositoryLocator.instance.saveIncident(incident);
    }
    if (emit.isDone) return;
    emit(SafeCallEnded(peakRiskLevel: _peakRisk, incident: incident));
  }

  /// Builds the forensic record for a call that ended at high risk.
  IncidentReport _buildIncidentReport() {
    final report = _fusionEngine.fuse(_acoustic, _semantic);
    final duration = _callStart == null
        ? 0
        : DateTime.now().difference(_callStart!).inSeconds;
    return IncidentReport(
      id: _nextIncidentId(),
      timestamp: DateTime.now(),
      callerLabel: 'Unknown Caller (+20 10 ••• ••42)',
      callDurationSeconds: duration,
      audioFingerprint: _audioFingerprint,
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

  String _nextIncidentId() =>
      'INC-${DateTime.now().year}-${(1000 + _rng.nextInt(9000))}';

  /// 64-char hex fingerprint derived from the rolling 32-bit hash —
  /// deterministic integrity evidence for the simulated audio stream.
  /// Uses only ≤2^48 intermediates so it is exact on both JS and
  /// native number representations.
  String get _audioFingerprint {
    final buf = StringBuffer();
    var h = _audioHash & 0xFFFFFFFF;
    for (var i = 0; i < 8; i++) {
      buf.write(h.toRadixString(16).padLeft(8, '0'));
      h = (h * 0x9e37 + i) & 0xFFFFFFFF;
    }
    return buf.toString();
  }

  void _onReset(ResetCallEvent event, Emitter<SafeCallState> emit) {
    _stopSession();
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
      demoActive: demoActive ?? _demoActive,
      audioAmplitude: _lastAmplitude,
    );
  }

  void _startAudioFeed() {
    _audioTimer?.cancel();
    _audioTimer = Timer.periodic(_audioInterval, (_) {
      if (isClosed) return;
      add(IncomingAudioChunkEvent(_generateChunk(synthetic: _demoActive)));
    });
  }

  void _resetSession() {
    _transcript = const [];
    _acoustic = const AudioForensicMetrics.zero();
    _semantic = const SemanticThreatSignals.empty();
    _demoActive = false;
    _lastAmplitude = 0;
    _peakRisk = ThreatRiskLevel.safe;
    _callStart = null;
    _audioHash = 0x811c9dc5;
    _acousticService.reset();
  }

  void _stopSession() {
    _audioTimer?.cancel();
    _audioTimer = null;
    _cancelDemoTimers();
  }

  void _cancelDemoTimers() {
    for (final t in _demoTimers) {
      t.cancel();
    }
    _demoTimers.clear();
  }

  // ── Simulated audio source ───────────────────────────────────────

  /// Generates a synthetic PCM chunk.
  ///
  ///  - `synthetic: true`  → band-limited harmonic stack (~190/380/570
  ///    Hz) with a hard HF cutoff and nearly static spectrum — the
  ///    signature Engine A flags as a synthesized voice.
  ///  - `synthetic: false` → broadband noise plus a wandering formant
  ///    tone — spectrally dynamic, high rolloff, high ZCR.
  List<double> _generateChunk({required bool synthetic}) {
    final out = List<double>.filled(_chunkSize, 0);
    for (var i = 0; i < _chunkSize; i++) {
      final t = (_sampleOffset + i) / _sampleRate;
      if (synthetic) {
        out[i] = 0.50 * sin(2 * pi * 190 * t) +
            0.28 * sin(2 * pi * 380 * t) +
            0.15 * sin(2 * pi * 570 * t) +
            (_rng.nextDouble() - 0.5) * 0.04;
      } else {
        final wander =
            260 + 140 * sin(2 * pi * 1.7 * t) + 60 * sin(2 * pi * 3.9 * t);
        out[i] = (_rng.nextDouble() - 0.5) * 0.55 +
            0.35 * sin(2 * pi * wander * t) +
            0.15 * sin(2 * pi * 3400 * t) * sin(2 * pi * 5 * t);
      }
    }
    _sampleOffset += _chunkSize;
    _foldChunkIntoFingerprint(out);
    return out;
  }

  /// 32-bit rolling hash (×31) over quantized samples — deterministic
  /// integrity fingerprint of everything streamed this call. Shift-add
  /// multiply keeps intermediates ≤2^37 for exact web semantics.
  void _foldChunkIntoFingerprint(List<double> chunk) {
    for (final s in chunk) {
      final byte = (s * 127).round() & 0xFF;
      _audioHash = ((_audioHash << 5) - _audioHash + byte) & 0xFFFFFFFF;
    }
  }

  @override
  Future<void> close() {
    _stopSession();
    return super.close();
  }
}
