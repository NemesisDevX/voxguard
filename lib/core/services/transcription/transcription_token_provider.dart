import 'dart:convert';

import 'package:http/http.dart' as http;

/// Mints the short-lived AssemblyAI streaming token a client puts on
/// the WebSocket `?token=` query parameter.
///
/// AssemblyAI streaming tokens are one-time-use and expire quickly
/// (≤ 600 s), which makes them safe for client-side transport — unlike
/// the permanent API key, which must never ship inside a released app.
///
/// Production architecture:
///
///   App → VoxGuard Token Broker → short-lived AssemblyAI token → WS
///
/// where the broker is any trusted server-side/edge endpoint holding
/// the provider secret.
abstract interface class ITranscriptionTokenProvider {
  /// Whether this provider can produce a token at all.
  bool get isConfigured;

  /// Whether [mintToken] can produce a *fresh* token on each call.
  ///
  /// AssemblyAI streaming tokens are one-time-use: a provider that
  /// returns the same static token cannot support reconnects, and the
  /// streaming service uses this flag to avoid retrying with an
  /// already-consumed token.
  bool get canMintFreshToken;

  /// Returns a fresh short-lived streaming token.
  Future<String> mintToken();
}

/// AssemblyAI's documented token endpoint.
const String kAssemblyAiTokenEndpoint =
    'https://streaming.assemblyai.com/v3/token';

/// Token lifetime requested from AssemblyAI (seconds). 600 is the
/// documented maximum for temporary streaming tokens.
const int kAssemblyAiTokenTtlSeconds = 600;

/// Resolves the token provider from `--dart-define` configuration.
///
/// Precedence:
///   1. `ASSEMBLYAI_TOKEN_BROKER_URL` — production path: a trusted
///      endpoint that mints short-lived tokens server-side.
///   2. `ASSEMBLYAI_TEMP_TOKEN` — a pre-minted short-lived token
///      (CI / demo convenience).
///   3. `ASSEMBLYAI_API_KEY` — DEVELOPMENT ONLY: the client mints its
///      own token over HTTPS. Never ship this in a released build.
ITranscriptionTokenProvider transcriptionTokenProviderFromEnvironment({
  http.Client? httpClient,
}) {
  const brokerUrl = String.fromEnvironment(
    'ASSEMBLYAI_TOKEN_BROKER_URL',
    defaultValue: '',
  );
  if (brokerUrl.isNotEmpty) {
    return BrokeredTokenProvider(brokerUrl, httpClient: httpClient);
  }
  const tempToken = String.fromEnvironment(
    'ASSEMBLYAI_TEMP_TOKEN',
    defaultValue: '',
  );
  if (tempToken.isNotEmpty) return StaticTokenProvider(tempToken);
  const apiKey = String.fromEnvironment(
    'ASSEMBLYAI_API_KEY',
    defaultValue: '',
  );
  return DevApiKeyTokenProvider(apiKey, httpClient: httpClient);
}

/// Production path — asks a trusted broker endpoint for a short-lived
/// token. The broker holds the permanent provider secret; the app only
/// ever sees expiring tokens.
///
/// Contract: `GET <brokerUrl>` → `200 { "token": "…" }`.
final class BrokeredTokenProvider implements ITranscriptionTokenProvider {
  BrokeredTokenProvider(this.brokerUrl, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const _timeout = Duration(seconds: 10);

  final String brokerUrl;
  final http.Client _http;

  @override
  bool get isConfigured => brokerUrl.isNotEmpty;

  @override
  bool get canMintFreshToken => true;

  @override
  Future<String> mintToken() async {
    final response =
        await _http.get(Uri.parse(brokerUrl)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError(
        'Token broker request failed (${response.statusCode})',
      );
    }
    return _extractToken(response.body, source: 'token broker');
  }
}

/// A pre-minted short-lived token supplied at build/run time.
///
/// The same token is returned on every call, so it is valid for
/// exactly one session — [canMintFreshToken] is false and reconnects
/// degrade to `failed` instead of replaying a consumed token.
final class StaticTokenProvider implements ITranscriptionTokenProvider {
  const StaticTokenProvider(this.token);

  final String token;

  @override
  bool get isConfigured => token.isNotEmpty;

  @override
  bool get canMintFreshToken => false;

  @override
  Future<String> mintToken() async => token;
}

/// DEVELOPMENT ONLY — mints a streaming token directly from a
/// permanent AssemblyAI API key via the documented HTTPS endpoint.
///
/// This exists so developers can run Live Mic locally with
/// `--dart-define=ASSEMBLYAI_API_KEY=…`. A released build must use
/// [BrokeredTokenProvider] instead: the permanent key must never be
/// distributed inside the app.
final class DevApiKeyTokenProvider implements ITranscriptionTokenProvider {
  DevApiKeyTokenProvider(this.apiKey, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const _timeout = Duration(seconds: 10);

  final String apiKey;
  final http.Client _http;

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  bool get canMintFreshToken => true;

  @override
  Future<String> mintToken() async {
    final response = await _http
        .get(
          Uri.parse(
            '$kAssemblyAiTokenEndpoint'
            '?expires_in_seconds=$kAssemblyAiTokenTtlSeconds',
          ),
          headers: {'Authorization': apiKey},
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError(
        'AssemblyAI token request failed (${response.statusCode})',
      );
    }
    return _extractToken(response.body, source: 'token endpoint');
  }
}

String _extractToken(String body, {required String source}) {
  final decoded = jsonDecode(body);
  final token = decoded is Map<String, dynamic> ? decoded['token'] : null;
  if (token is! String || token.isEmpty) {
    throw StateError('Missing "token" in $source response');
  }
  return token;
}
