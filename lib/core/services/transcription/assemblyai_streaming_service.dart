import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'streaming_transcription_service.dart';

/// AssemblyAI Universal-Streaming (v3) transcription client.
///
/// **Credential model:** browsers cannot set WebSocket headers, so
/// this client *always* authenticates via a short-lived token on the
/// `?token=` query parameter — AssemblyAI's documented mechanism for
/// client-side streaming:
///
///   1. `GET https://streaming.assemblyai.com/v3/token?expires_in_seconds=…`
///      (Authorization: API key) → `{ "token": "…" }` — one-time use.
///   2. `wss://streaming.assemblyai.com/v3/ws?sample_rate=…&token=…`
///
/// Development builds may pass `--dart-define=ASSEMBLYAI_API_KEY=…`,
/// which is used only to mint that token over HTTPS.
///
/// **Production:** the permanent API key must not ship inside the app.
/// A backend/edge endpoint should mint the short-lived token and hand
/// it to the client (`--dart-define=ASSEMBLYAI_TEMP_TOKEN=…` models
/// that path today). Tokens are one-time-use and expire in ≤600 s.
///
/// Message handling: `Turn` events carry `transcript` + `end_of_turn`;
/// audio is sent as binary PCM16LE frames; sessions close with a
/// `{"type":"Terminate"}` frame.
final class AssemblyAiStreamingService
    implements IStreamingTranscriptionService {
  AssemblyAiStreamingService({
    http.Client? httpClient,
    String? apiKey,
    String? temporaryToken,
    WebSocketChannel Function(Uri uri)? channelFactory,
  })  : _http = httpClient ?? http.Client(),
        _apiKey = apiKey ??
            const String.fromEnvironment('ASSEMBLYAI_API_KEY',
                defaultValue: ''),
        _temporaryToken = temporaryToken ??
            const String.fromEnvironment('ASSEMBLYAI_TEMP_TOKEN',
                defaultValue: ''),
        _channelFactory = channelFactory;

  static const _wsBase = 'wss://streaming.assemblyai.com/v3/ws';
  static const _tokenEndpoint = 'https://streaming.assemblyai.com/v3/token';
  static const _timeout = Duration(seconds: 10);

  final http.Client _http;
  final String _apiKey;
  final String _temporaryToken;
  final WebSocketChannel Function(Uri uri)? _channelFactory;

  final _events = StreamController<TranscriptEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  bool _running = false;

  @override
  bool get isConfigured => _apiKey.isNotEmpty || _temporaryToken.isNotEmpty;

  @override
  String get providerLabel => 'AssemblyAI Streaming';

  @override
  Stream<TranscriptEvent> get events => _events.stream;

  @override
  Future<void> start({required int sampleRate}) async {
    if (_running || !isConfigured) return;

    final token = await _resolveToken();
    final uri = Uri.parse(_wsBase).replace(queryParameters: {
      'sample_rate': '$sampleRate',
      'token': token,
    });

    final channel =
        (_channelFactory ?? WebSocketChannel.connect)(uri);
    _channel = channel;
    _running = true;

    _channelSub = channel.stream.listen(
      _onMessage,
      onError: (Object e) => debugPrint('[AssemblyAI] stream error: $e'),
      onDone: () => _running = false,
      cancelOnError: false,
    );
  }

  /// Dev builds mint a one-time token from the configured API key;
  /// production supplies a pre-minted short-lived token directly.
  Future<String> _resolveToken() async {
    if (_temporaryToken.isNotEmpty) return _temporaryToken;

    final response = await _http
        .get(
          Uri.parse('$_tokenEndpoint?expires_in_seconds=600'),
          headers: {'Authorization': _apiKey},
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError(
        'AssemblyAI token request failed (${response.statusCode})',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'];
    if (token is! String || token.isEmpty) {
      throw StateError('AssemblyAI token response missing "token"');
    }
    return token;
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return;
    }
    if (msg['type'] != 'Turn') return;

    final text = msg['transcript'];
    if (text is! String || text.trim().isEmpty) return;

    _events.add(
      TranscriptEvent(text: text, isFinal: msg['end_of_turn'] == true),
    );
  }

  @override
  void sendAudio(Uint8List pcm16le) {
    if (!_running || _channel == null) return;
    _channel!.sink.add(pcm16le);
  }

  @override
  Future<void> stop() async {
    if (!_running && _channel == null) return;
    _running = false;
    try {
      _channel?.sink.add(jsonEncode({'type': 'Terminate'}));
      await _channel?.sink.close().timeout(_timeout);
    } on Exception {
      // Closing must never throw into the session teardown path.
    }
    await _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
  }
}
