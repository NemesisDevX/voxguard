import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Status of a prerecorded transcription job — the compact, PauseSignal
/// vocabulary the relay returns (provider internals never surface).
enum RecordedTranscriptionStatus {
  queued,
  processing,
  completed,
  failed,
}

/// One poll result for a prerecorded transcription job.
final class RecordedTranscriptJob {
  const RecordedTranscriptJob({required this.status, this.text});

  final RecordedTranscriptionStatus status;

  /// Transcript text — present only when [status] is `completed`.
  final String? text;
}

/// Prerecorded-file transcription — a SEPARATE contract from
/// `IStreamingTranscriptionService` (live WebSocket mic sessions).
/// Never stream a file through the live pipeline.
abstract interface class IRecordedTranscriptionService {
  /// False when no transcription endpoint is configured — the UI must
  /// offer acoustic-only analysis instead of a dead action.
  bool get isConfigured;

  /// Uploads the original recording bytes and returns an opaque job
  /// reference. Called only after an explicit user opt-in.
  Future<String> submitJob(
    Uint8List audioBytes, {
    required String formatHint,
  });

  /// Polls a submitted job. Provider failures surface as
  /// `status: failed` — never raw provider error bodies.
  Future<RecordedTranscriptJob> pollJob(String jobId);
}

/// Failure talking to the transcription relay — safe, generic copy.
final class RecordedTranscriptionException implements Exception {
  const RecordedTranscriptionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Client for the PauseSignal transcription relay (`server/` Worker):
///   POST {base}/transcription/jobs      — raw audio bytes
///   GET  {base}/transcription/jobs/{id} — compact status
///
/// The provider API key lives ONLY server-side (`ASSEMBLYAI_API_KEY`);
/// the client authenticates with the shared relay token — abuse
/// resistance, not strong authentication.
final class RelayRecordedTranscriptionService
    implements IRecordedTranscriptionService {
  RelayRecordedTranscriptionService({
    http.Client? httpClient,
    String? baseUrl,
    String? token,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'VOXGUARD_RECORDING_TRANSCRIPTION_URL',
                  defaultValue: '',
                ))
            .trim(),
        _token = (token ??
                const String.fromEnvironment(
                  'VOXGUARD_RELAY_TOKEN',
                  defaultValue: '',
                ))
            .trim();

  static const _timeout = Duration(seconds: 30);

  final http.Client _client;
  final String _baseUrl;
  final String _token;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty && _token.isNotEmpty;

  Uri get _jobsUri => Uri.parse('$_baseUrl/transcription/jobs');

  @override
  Future<String> submitJob(
    Uint8List audioBytes, {
    required String formatHint,
  }) async {
    if (!isConfigured) {
      throw const RecordedTranscriptionException(
        'Cloud transcription isn\'t configured in this build.',
      );
    }
    http.Response res;
    try {
      res = await _client
          .post(
            _jobsUri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/octet-stream',
              // Minimal format hint for the provider decoder — the
              // filename itself never leaves the device.
              'X-Audio-Format': formatHint,
            },
            body: audioBytes,
          )
          .timeout(_timeout);
    } catch (_) {
      throw const RecordedTranscriptionException(
        'Couldn\'t reach the transcription service.',
      );
    }
    if (res.statusCode != 202) {
      throw const RecordedTranscriptionException(
        'The transcription service rejected the upload.',
      );
    }
    try {
      final decoded = jsonDecode(res.body);
      final id = decoded is Map ? decoded['job_id'] : null;
      if (id is! String || id.isEmpty) throw const FormatException();
      return id;
    } catch (_) {
      throw const RecordedTranscriptionException(
        'The transcription service returned an unexpected response.',
      );
    }
  }

  @override
  Future<RecordedTranscriptJob> pollJob(String jobId) async {
    if (!isConfigured) {
      throw const RecordedTranscriptionException(
        'Cloud transcription isn\'t configured in this build.',
      );
    }
    http.Response res;
    try {
      res = await _client
          .get(
            Uri.parse('$_baseUrl/transcription/jobs/$jobId'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(_timeout);
    } catch (_) {
      throw const RecordedTranscriptionException(
        'Couldn\'t reach the transcription service.',
      );
    }
    if (res.statusCode != 200) {
      throw const RecordedTranscriptionException(
        'The transcription service returned an unexpected response.',
      );
    }
    try {
      final decoded = jsonDecode(res.body);
      final status = decoded is Map ? decoded['status'] : null;
      final text = decoded is Map ? decoded['text'] : null;
      return switch (status) {
        'queued' => const RecordedTranscriptJob(
            status: RecordedTranscriptionStatus.queued),
        'processing' => const RecordedTranscriptJob(
            status: RecordedTranscriptionStatus.processing),
        'completed' => RecordedTranscriptJob(
            status: RecordedTranscriptionStatus.completed,
            text: text is String ? text : ''),
        'error' || 'failed' => const RecordedTranscriptJob(
            status: RecordedTranscriptionStatus.failed),
        _ => throw const FormatException(),
      };
    } on FormatException {
      throw const RecordedTranscriptionException(
        'The transcription service returned an unexpected response.',
      );
    }
  }
}

/// Process-wide accessor for the prerecorded transcription service.
final class RecordedTranscriptionLocator {
  RecordedTranscriptionLocator._();

  static IRecordedTranscriptionService? _instance;

  static IRecordedTranscriptionService get instance =>
      _instance ??= RelayRecordedTranscriptionService();

  @visibleForTesting
  static set instance(IRecordedTranscriptionService svc) =>
      _instance = svc;
}
