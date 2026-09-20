import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:voxguard/core/services/audio/audio_stream_source.dart';
import 'package:voxguard/core/services/audio/demo_audio_source.dart';
import 'package:voxguard/core/services/transcription/assemblyai_streaming_service.dart';
import 'package:voxguard/core/services/transcription/streaming_transcription_service.dart';
import 'package:voxguard/core/services/transcription/transcription_token_provider.dart';
import 'package:voxguard/features/forensics/domain/services/incident_repository.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_bloc.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_event.dart';
import 'package:voxguard/features/protection/presentation/bloc/safecall_state.dart';
import 'package:web_socket/testing.dart';
import 'package:web_socket/web_socket.dart'
    show TextDataReceived, WebSocket;
import 'package:web_socket_channel/adapter_web_socket_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ── Fakes ────────────────────────────────────────────────────────────

/// A connected fake WebSocket client/server pair — the service drives
/// [channel] (built on the client socket) while the test plays the
/// AssemblyAI server through [server].
final class FakeChannelPair {
  FakeChannelPair() {
    final (client, server) = fakes();
    channel = AdapterWebSocketChannel(client);
    this.server = server;
  }

  late final WebSocketChannel channel;
  late final WebSocket server;

  /// Server pushes a protocol message (e.g. `{"type":"Begin"}`).
  void serverSays(Map<String, dynamic> msg) =>
      server.sendText(jsonEncode(msg));

  /// Server drops the connection mid-session.
  void drop() => server.close();

  /// Frames the client sent (binary PCM or the Terminate JSON).
  Future<List<Object>> sent() async {
    final received = <Object>[];
    await for (final e in server.events) {
      switch (e) {
        case TextDataReceived(:final text):
          received.add(text);
        default:
          break;
      }
    }
    return received;
  }
}

/// Scripted token provider.
final class FakeTokenProvider implements ITranscriptionTokenProvider {
  FakeTokenProvider({this.token = 'tok', this.fail = false});

  final String token;
  final bool fail;
  var mintCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<String> mintToken() async {
    mintCalls++;
    if (fail) throw StateError('mint failed');
    return '$token-$mintCalls';
  }
}

/// Mic source stub for bloc-level tests.
final class FakeMicSource implements IAudioStreamSource {
  final _controller = StreamController<AudioChunk>();

  @override
  AudioSourceType get type => AudioSourceType.microphone;

  @override
  int get sampleRate => 16000;

  @override
  Stream<AudioChunk> get chunks => _controller.stream;

  @override
  bool get isSupported => true;

  @override
  Future<MicPermissionState> ensurePermission() async =>
      MicPermissionState.granted;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  group('token providers', () {
    test('dev API-key provider mints via the documented token endpoint',
        () async {
      Uri? hit;
      final client = http_testing.MockClient((req) async {
        hit = req.url;
        return http.Response(jsonEncode({'token': 'minted-1'}), 200);
      });
      final p = DevApiKeyTokenProvider('dev-key', httpClient: client);

      expect(await p.mintToken(), 'minted-1');
      expect(hit!.host, 'streaming.assemblyai.com');
      expect(hit!.path, '/v3/token');
      expect(hit!.queryParameters['expires_in_seconds'], '600');
    });

    test('broker provider GETs the configured endpoint', () async {
      Uri? hit;
      final client = http_testing.MockClient((req) async {
        hit = req.url;
        return http.Response(jsonEncode({'token': 'broker-tok'}), 200);
      });
      final p = BrokeredTokenProvider(
        'https://relay.example.com/aai-token',
        httpClient: client,
      );

      expect(await p.mintToken(), 'broker-tok');
      expect(hit!.host, 'relay.example.com');
    });

    test('mint failure propagates (non-200 and missing token)', () async {
      final bad = http_testing.MockClient(
        (_) async => http.Response('nope', 500),
      );
      expect(
        () => DevApiKeyTokenProvider('k', httpClient: bad).mintToken(),
        throwsStateError,
      );

      final empty = http_testing.MockClient(
        (_) async => http.Response('{}', 200),
      );
      expect(
        () => DevApiKeyTokenProvider('k', httpClient: empty).mintToken(),
        throwsStateError,
      );
    });

    test('static provider returns the pre-minted token', () async {
      expect(await const StaticTokenProvider('abc').mintToken(), 'abc');
      expect(const StaticTokenProvider('').isConfigured, isFalse);
    });
  });

  group('AssemblyAiStreamingService', () {
    test('explicit speech model + ar/en language bias reach the WS URI',
        () async {
      Uri? uri;
      final pair = FakeChannelPair();
      final service = AssemblyAiStreamingService(
        tokenProvider: FakeTokenProvider(),
        channelFactory: (u) {
          uri = u;
          return pair.channel;
        },
      );

      final started = service.start(sampleRate: 16000);
      pair.serverSays({'type': 'Begin'});
      await started;

      expect(uri!.host, 'streaming.assemblyai.com');
      expect(uri!.path, '/v3/ws');
      expect(uri!.queryParameters['sample_rate'], '16000');
      expect(uri!.queryParameters['speech_model'], 'universal-3-5-pro');
      expect(
        jsonDecode(uri!.queryParameters['language_codes']!),
        ['en', 'ar'],
      );
      expect(uri!.queryParameters['token'], 'tok-1');
      await service.stop();
    });

    test('live status only after Begin handshake, not before', () async {
      final pair = FakeChannelPair();
      final statuses = <TranscriptionSessionStatus>[];
      final service = AssemblyAiStreamingService(
        tokenProvider: FakeTokenProvider(),
        channelFactory: (_) => pair.channel,
      );
      service.status.listen(statuses.add);

      var startDone = false;
      final started =
          service.start(sampleRate: 16000).then((_) => startDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(startDone, isFalse); // socket open but no Begin yet
      expect(statuses, isNot(contains(TranscriptionSessionStatus.live)));

      pair.serverSays({'type': 'Begin'});
      await started;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(startDone, isTrue);
      expect(statuses.last, TranscriptionSessionStatus.live);
      await service.stop();
    });

    test('duplicate partials/finals and empty turns are filtered',
        () async {
      final pair = FakeChannelPair();
      final events = <TranscriptEvent>[];
      final service = AssemblyAiStreamingService(
        tokenProvider: FakeTokenProvider(),
        channelFactory: (_) => pair.channel,
      );
      service.events.listen(events.add);

      final started = service.start(sampleRate: 16000);
      pair.serverSays({'type': 'Begin'});
      await started;

      pair.serverSays({'type': 'Turn', 'transcript': ''});
      pair.serverSays(
          {'type': 'Turn', 'transcript': 'hello', 'end_of_turn': false});
      pair.serverSays(
          {'type': 'Turn', 'transcript': 'hello', 'end_of_turn': false});
      pair.serverSays(
          {'type': 'Turn', 'transcript': 'hello world', 'end_of_turn': true});
      pair.serverSays(
          {'type': 'Turn', 'transcript': 'hello world', 'end_of_turn': true});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.length, 2);
      expect(events[0].isFinal, isFalse);
      expect(events[1].isFinal, isTrue);
      await service.stop();
    });

    test('mid-session drop triggers one bounded reconnect, then failed',
        () async {
      final pairs = <FakeChannelPair>[];
      final statuses = <TranscriptionSessionStatus>[];
      final provider = FakeTokenProvider();
      final service = AssemblyAiStreamingService(
        tokenProvider: provider,
        channelFactory: (_) {
          final p = FakeChannelPair();
          pairs.add(p);
          return p.channel;
        },
      );
      service.status.listen(statuses.add);

      final started = service.start(sampleRate: 16000);
      // Let mintToken + channelFactory resolve before playing server.
      while (pairs.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      pairs[0].serverSays({'type': 'Begin'});
      await started;

      // Drop #1 → disconnected + reconnect with a fresh token.
      pairs[0].drop();
      while (pairs.length < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(
        statuses,
        contains(TranscriptionSessionStatus.disconnected),
      );
      expect(provider.mintCalls, 2); // fresh token per attempt

      // Reconnect succeeds → live again.
      pairs[1].serverSays({'type': 'Begin'});
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(statuses.last, TranscriptionSessionStatus.live);

      // Drop #2 → no more retries → failed.
      pairs[1].drop();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(statuses.last, TranscriptionSessionStatus.failed);
      expect(pairs.length, 2);
      await service.stop();
    });
  });

  group('bloc integration', () {
    setUp(() {
      IncidentRepositoryLocator.instance = InMemoryIncidentRepository();
    });

    test('token mint failure → session runs acoustic-only', () async {
      final stt = AssemblyAiStreamingService(
        tokenProvider: FakeTokenProvider(fail: true),
        channelFactory: (_) => FakeChannelPair().channel,
      );
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: FakeMicSource(),
        transcriptionService: stt,
      );
      bloc.add(const StartLiveMicSessionEvent());
      await Future<void>.delayed(const Duration(milliseconds: 40));

      final s = bloc.state;
      expect(s, isA<SafeCallMonitoring>());
      expect((s as SafeCallMonitoring).isTranscriptionLive, isFalse);
      await bloc.close();
    });

    test('mid-session STT drop degrades state but keeps session alive',
        () async {
      final pairs = <FakeChannelPair>[];
      final stt = AssemblyAiStreamingService(
        tokenProvider: FakeTokenProvider(),
        channelFactory: (_) {
          final p = FakeChannelPair();
          pairs.add(p);
          return p.channel;
        },
        handshakeTimeout: const Duration(milliseconds: 50),
      );
      final bloc = SafeCallBloc(
        demoSource: DemoAudioSource(),
        microphoneSource: FakeMicSource(),
        transcriptionService: stt,
      );
      bloc.add(const StartLiveMicSessionEvent());
      while (pairs.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      pairs[0].serverSays({'type': 'Begin'});
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(
        (bloc.state as SafeCallMonitoring).isTranscriptionLive,
        isTrue,
      );

      // Drop → service attempts its single bounded reconnect; the
      // second fake channel never completes the Begin handshake →
      // status goes failed → bloc flips transcription to unavailable
      // while the protection session itself stays up.
      pairs[0].drop();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final s = bloc.state;
      expect(s, isA<SafeCallMonitoring>());
      expect((s as SafeCallMonitoring).isTranscriptionLive, isFalse);
      await bloc.close();
    });
  });
}
