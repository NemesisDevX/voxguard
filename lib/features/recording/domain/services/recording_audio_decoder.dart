import 'dart:typed_data';

import 'package:audio_decoder/audio_decoder.dart';

import '../../../../core/constants/app_strings.dart';
import '../models/recording_models.dart';

/// VoxGuard seam over the platform audio decoder. All analysis runs on
/// ONE normalized format — 16 kHz / mono / PCM16 little-endian — the
/// same format the SafeCall pipeline feeds `AcousticForensicsService`.
abstract interface class IRecordingAudioDecoder {
  /// Metadata probe — duration/rate/channels. Throws
  /// [RecordingAnalysisException] when the container can't be read.
  Future<RecordingAudioInfo> inspect(PickedRecording file);

  /// Full decode → raw PCM16 LE bytes, mono, 16,000 Hz, no WAV header.
  /// Throws [RecordingAnalysisException] on unsupported/corrupt input.
  Future<Uint8List> decodeToPcm16(PickedRecording file);
}

/// `audio_decoder`-backed implementation — native decoders on
/// Android/iOS/macOS/Windows/Linux, Web Audio API on web.
final class PluginRecordingAudioDecoder implements IRecordingAudioDecoder {
  const PluginRecordingAudioDecoder();

  /// The single format VoxGuard's acoustic engine consumes.
  static const targetSampleRate = 16000;
  static const targetChannels = 1;
  static const targetBitDepth = 16;

  @override
  Future<RecordingAudioInfo> inspect(PickedRecording file) async {
    try {
      final info = await AudioDecoder.getAudioInfoBytes(
        file.bytes,
        formatHint: file.extension,
      );
      return RecordingAudioInfo(
        duration: info.duration,
        sampleRate: info.sampleRate,
        channels: info.channels,
        format: info.format,
      );
    } catch (_) {
      throw RecordingAnalysisException(
        AppStrings.recordingUnreadable,
        code: 'unsupported',
      );
    }
  }

  @override
  Future<Uint8List> decodeToPcm16(PickedRecording file) async {
    try {
      return await AudioDecoder.convertToWavBytes(
        file.bytes,
        formatHint: file.extension,
        sampleRate: targetSampleRate,
        channels: targetChannels,
        bitDepth: targetBitDepth,
        includeHeader: false,
      );
    } catch (_) {
      throw RecordingAnalysisException(
        AppStrings.recordingUndecodable,
        code: 'decodeFailed',
      );
    }
  }
}
