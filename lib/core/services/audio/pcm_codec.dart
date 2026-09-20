import 'dart:math';
import 'dart:typed_data';

/// Conversions between normalized samples (-1.0 – 1.0) and raw
/// little-endian PCM16 bytes — the two representations the pipeline
/// carries through every [AudioChunk].
abstract final class PcmCodec {
  PcmCodec._();

  /// Decodes interleaved little-endian PCM16 bytes into normalized
  /// mono samples. Odd trailing bytes are ignored.
  static List<double> pcm16ToSamples(Uint8List bytes) {
    final count = bytes.lengthInBytes ~/ 2;
    final view = ByteData.sublistView(bytes);
    final out = List<double>.filled(count, 0);
    for (var i = 0; i < count; i++) {
      out[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  /// Encodes normalized samples to little-endian PCM16 bytes.
  /// Deterministic — this is what the session SHA-256 digests.
  static Uint8List samplesToPcm16(List<double> samples) {
    final bytes = Uint8List(samples.length * 2);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      view.setInt16(i * 2, v, Endian.little);
    }
    return bytes;
  }

  /// Root-mean-square amplitude of normalized samples (0.0 – 1.0).
  static double rms(List<double> samples) {
    if (samples.isEmpty) return 0;
    var sumSq = 0.0;
    for (final s in samples) {
      sumSq += s * s;
    }
    return sqrt(sumSq / samples.length).clamp(0.0, 1.0);
  }
}
