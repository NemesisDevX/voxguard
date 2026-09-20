import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'streaming_transcription_service.dart';
import 'transcription_token_provider.dart';

/// Streaming configuration for AssemblyAI — the single location where
/// the speech model and language steering live.
///
/// `universal-3-5-pro` is AssemblyAI's current flagship streaming
/// model: Arabic and English with native code-switching across 18
/// languages. `languageCodes` uses the documented `language_codes`
/// connection parameter to bias decoding toward Arabic + English while
/// still allowing code-switching between them. AssemblyAI offers no
/// Egyptian-dialect-specific streaming model, so `ar` is the honest
/// configuration.
final class AssemblyAiStreamingConfig {
  const AssemblyAiStreamingConfig({
    this.speechModel = 'universal-3-5-pro',
    this.languageCodes = const ['en', 'ar'],
  });

  /// `speech_model` connection parameter.
  final String speechModel;

  /// `language_codes` connection parameter — ISO codes the model is
  /// biased toward. Empty list = native code-switching across all
  /// supported languages.
  final List<String> languageCodes;
}

/// AssemblyAI Universal-Streaming (v3) transcription client.
///
/// **Credential model:** browsers cannot set WebSocket headers, so
/// this client *always* authenticates via a short-lived token on the
/// `?token=` query parameter — AssemblyAI's documented mechanism for
/// client-side streaming:
///
///   1. `ITranscriptionTokenProvider.mintToken()` → one-time token.
///   2. `wss://streaming.assemblyai.com/v3/ws?sample_rate=…&speech_model=…&token=…`
///
/// **Production:** use `BrokeredTokenProvider` (via
/// `--dart-define=ASSEMBLYAI_TOKEN_BROKER_URL=…`) so the permanent API
/// key stays server-side. `--dart-define=ASSEMBLYAI_API_KEY=…` exists
/// for development only and must never ship in a released build.
///
/// **Liveness:** [TranscriptionSessionStatus.live] is emitted only
/// after the socket connects *and* AssemblyAI acknowledges the session
/// with a `Begin` message — configuration alone never counts as live.
/// A mid-session drop emits `disconnected`, triggers exactly one
/// bounded reconnect with a fresh token, then `failed` if that fails.
///
/// Message handling: `Turn` events carry `transcript` + `end_of_turn`;
/// audio is sent as binary PCM16LE frames; sessions close with a
/// `{"type":"Terminate"}` frame. Duplicate partials/finals and empty
/// turns are filtered here so downstream never sees them.
final class AssemblyAiStreamingService
    implements IStreamingTranscriptionService {
  AssemblyAiStreamingService({
    ITranscriptionTokenProvider? tokenProvider,
    AssemblyAiStreamingConfig config = const AssemblyAiStreamingConfig(),
    WebSocketChannel Function(Uri uri)? channelFactory,
    Duration handshakeTimeout = const Duration(seconds: 8),
  })  : _tokenProvider =
            tokenProvider ?? transcriptionTokenProviderFromEnvironment(),
        _config = config,
        _channelFactory = channelFactory,
        _handshakeTimeout = handshakeTimeout;

  static const _wsBase = 'wss://streaming.assemblyai.com/v3/ws';
  static const _timeout = Duration(seconds: 10);

  /// Exactly one reconnect is attempted on an unexpected mid-session
  /// drop — enough to ride out a transient network blip without
  /// creating a reconnect loop that drains battery or spams tokens.
  static const _maxReconnectAttempts = 1;

  final ITranscriptionTokenProvider _tokenProvider;
  final AssemblyAiStreamingConfig _config;
  final WebSocketChannel Function(Uri uri)? _channelFactory;
  final Duration _handshakeTimeout;

  final _events = StreamController<TranscriptEvent>.broadcast();
  final _status = StreamController<TranscriptionSessionStatus>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  bool _running = false;
  bool _stopping = false;
  int _reconnectsUsed = 0;
  int _sampleRate = 16000;
  String _lastPartial = '';
  String _lastFinal = '';

  @override
  bool get isConfigured => _tokenProvider.isConfigured;

  @override
  String get providerLabel => 'AssemblyAI Streaming';

  @override
  Stream<TranscriptEvent> get events => _events.stream;

  @override
  Stream<TranscriptionSessionStatus> get status => _status.stream;

  @override
  Future<void> start({required int sampleRate}) async {
    if (_running || !isConfigured) return;
    _sampleRate = sampleRate;
    _stopping = false;
    _reconnectsUsed = 0;
    _lastPartial = '';
    _lastFinal = '';
    _status.add(TranscriptionSessionStatus.connecting);
    await _connect();
  }

  /// Opens the socket and waits for the provider's `Begin` handshake —
  /// until that lands, the session is not live and `start` propagates
  /// the failure so the caller can degrade to acoustic-only.
  Future<void> _connect() async {
    final token = await _tokenProvider.mintToken();
    final uri = Uri.parse(_wsBase).replace(queryParameters: {
      'sample_rate': '$_sampleRate',
      'speech_model': _config.speechModel,
      if (_config.languageCodes.isNotEmpty)
        'language_codes': jsonEncode(_config.languageCodes),
      'token': token,
    });

    final channel =
        (_channelFactory ?? WebSocketChannel.connect)(uri);
    await channel.ready.timeout(_handshakeTimeout);

    final begun = Completer<void>();
    final sub = channel.stream.listen(
      (raw) => _onMessage(raw, begun),
      onError: (Object _) => _onChannelClosed(begun),
      onDone: () => _onChannelClosed(begun),
      cancelOnError: false,
    );
    _channel = channel;
    _channelSub = sub;

    await begun.future.timeout(
      _handshakeTimeout,
      onTimeout: () =>
          throw TimeoutException('AssemblyAI session never began'),
    );
    _running = true;
    _status.add(TranscriptionSessionStatus.live);
  }

  /// Socket dropped while the session should be live. One bounded
  /// reconnect with a freshly minted token; if that fails the status
  /// goes `failed` and audio stays acoustic-only — SafeCall itself is
  /// never torn down by a cloud STT drop.
  void _onChannelClosed(Completer<void> begun) {
    // A drop during the handshake fails the connect attempt fast
    // instead of hanging until the timeout.
    if (!begun.isCompleted) {
      begun.completeError(StateError('WebSocket closed during handshake'));
    }
    if (_stopping || !_running) return;
    _running = false;
    if (_reconnectsUsed >= _maxReconnectAttempts) {
      _status.add(TranscriptionSessionStatus.failed);
      return;
    }
    _reconnectsUsed++;
    _status.add(TranscriptionSessionStatus.disconnected);
    _connect().catchError((Object _) {
      _status.add(TranscriptionSessionStatus.failed);
    });
  }

  void _onMessage(dynamic raw, Completer<void> begun) {
    if (raw is! String) return;
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return;
    }
    switch (msg['type']) {
      case 'Begin':
        if (!begun.isCompleted) begun.complete();
      case 'Turn':
        final text = msg['transcript'];
        if (text is! String || text.trim().isEmpty) return;
        if (msg['end_of_turn'] == true) {
          // Dedupe: providers occasionally re-emit an identical final.
          if (text == _lastFinal) return;
          _lastFinal = text;
          _lastPartial = '';
          _events.add(TranscriptEvent(text: text, isFinal: true));
        } else {
          // Dedupe: suppress repeated identical partial hypotheses.
          if (text == _lastPartial) return;
          _lastPartial = text;
          _events.add(TranscriptEvent(text: text, isFinal: false));
        }
    }
  }

  @override
  void sendAudio(Uint8List pcm16le) {
    if (!_running || _channel == null) return;
    _channel!.sink.add(pcm16le);
  }

  @override
  Future<void> stop() async {
    _stopping = true;
    final wasRunning = _running;
    _running = false;
    try {
      _channel?.sink.add(jsonEncode({'type': 'Terminate'}));
      await _channel?.sink.close().timeout(_timeout);
    } catch (_) {
      // Closing must never throw into the session teardown path.
    }
    await _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
    if (wasRunning) _status.add(TranscriptionSessionStatus.ended);
  }
}
