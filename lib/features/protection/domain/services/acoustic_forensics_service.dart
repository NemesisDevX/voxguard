import 'dart:math';

import '../models/audio_forensic_metrics.dart';

/// Engine A — Acoustic Forensics.
///
/// Extracts real spectral features from raw audio chunks and scores how
/// "synthetic" the voice stream looks. Voice-synthesis / vocoder output
/// is typically characterized by:
///  - a static magnitude spectrum (very low spectral flux),
///  - an abnormally sharp high-frequency cutoff (low spectral rolloff),
///  - a flat, tonal zero-crossing profile (low ZCR variance).
///
/// The service is stateful only in that it tracks the previous chunk's
/// magnitude spectrum to compute spectral flux; call [reset] between
/// calls.
final class AcousticForensicsService {
  AcousticForensicsService({this.sampleRate = 16000});

  /// Sample rate of the incoming PCM stream.
  final int sampleRate;

  List<double>? _previousMagnitudes;

  /// Clears inter-chunk state (call when a new call/session starts).
  void reset() => _previousMagnitudes = null;

  /// Analyzes a mono PCM chunk (normalized -1.0 – 1.0 samples) and
  /// returns the forensic feature snapshot.
  AudioForensicMetrics analyze(List<double> samples) {
    if (samples.isEmpty) return const AudioForensicMetrics.zero();

    final magnitudes = _magnitudeSpectrum(samples);
    final zcr = _zeroCrossingRate(samples);
    final rolloff = _spectralRolloff(magnitudes);
    final flux = _spectralFlux(magnitudes);

    _previousMagnitudes = magnitudes;

    return AudioForensicMetrics(
      spectralFlux: flux,
      spectralRolloffRatio: rolloff,
      zeroCrossingRate: zcr,
      syntheticVoiceScore: _scoreSynthetic(flux, rolloff, zcr),
    );
  }

  // ── Feature extraction ───────────────────────────────────────────

  /// Fraction of adjacent samples that change sign.
  double _zeroCrossingRate(List<double> x) {
    var crossings = 0;
    for (var i = 1; i < x.length; i++) {
      if ((x[i] >= 0) != (x[i - 1] >= 0)) crossings++;
    }
    return crossings / x.length;
  }

  /// Frequency (as a ratio of Nyquist) below which 85% of spectral
  /// energy is concentrated.
  double _spectralRolloff(List<double> mags) {
    var total = 0.0;
    for (final m in mags) {
      total += m;
    }
    if (total <= 0) return 0;

    final threshold = total * 0.85;
    var cumulative = 0.0;
    for (var i = 0; i < mags.length; i++) {
      cumulative += mags[i];
      if (cumulative >= threshold) {
        // i maps to frequency i * nyquist / mags.length
        return i / mags.length;
      }
    }
    return 1;
  }

  /// Mean relative magnitude change vs. the previous chunk. Natural
  /// speech/noise is spectrally dynamic; static harmonic synthesis is
  /// not.
  double _spectralFlux(List<double> mags) {
    final prev = _previousMagnitudes;
    if (prev == null || prev.length != mags.length) return 0;

    var delta = 0.0;
    var base = 0.0;
    for (var i = 0; i < mags.length; i++) {
      delta += (mags[i] - prev[i]).abs();
      base += prev[i];
    }
    if (base <= 0) return 0;
    return delta / base;
  }

  // ── Synthetic-voice scoring ──────────────────────────────────────

  /// Combines the three forensic cues into a 0 – 1 synthetic score.
  ///
  ///  - [flux]:    ~1.0 for noisy/dynamic speech, ~0.02 for a static
  ///               harmonic stack → normalized with ×6 gain.
  ///  - [rolloff]: natural speech spreads energy across the band;
  ///               band-limited TTS rolls off well below 45% Nyquist.
  ///  - [zcr]:     a ~200 Hz tone at 16 kHz yields ZCR ≈ 0.025, while
  ///               real speech/noise sits far above 0.12.
  double _scoreSynthetic(double flux, double rolloff, double zcr) {
    final fluxNorm = (flux * 6).clamp(0.0, 1.0);
    final flatness = 1 - fluxNorm;
    final hfCutoff = ((0.45 - rolloff) / 0.45).clamp(0.0, 1.0);
    final zcrAnomaly = ((0.12 - zcr) / 0.12).clamp(0.0, 1.0);

    return (0.45 * flatness + 0.35 * hfCutoff + 0.20 * zcrAnomaly)
        .clamp(0.0, 1.0);
  }

  // ── FFT (iterative radix-2) ──────────────────────────────────────

  /// Magnitude spectrum (first N/2 bins) of the input, which is
  /// zero-padded or truncated to the nearest power of two.
  List<double> _magnitudeSpectrum(List<double> samples) {
    var n = 1;
    while (n < samples.length) {
      n <<= 1;
    }
    if (n > 2048) n = 2048;

    final re = List<double>.filled(n, 0);
    final im = List<double>.filled(n, 0);
    final limit = min(n, samples.length);
    for (var i = 0; i < limit; i++) {
      re[i] = samples[i];
    }

    // Bit-reversal permutation.
    for (var i = 1, j = 0; i < n; i++) {
      var bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }

    // Cooley–Tukey butterflies.
    for (var len = 2; len <= n; len <<= 1) {
      final ang = -2 * pi / len;
      final wRe = cos(ang);
      final wIm = sin(ang);
      final half = len >> 1;
      for (var i = 0; i < n; i += len) {
        var curRe = 1.0;
        var curIm = 0.0;
        for (var k = 0; k < half; k++) {
          final uRe = re[i + k];
          final uIm = im[i + k];
          final vRe = re[i + k + half] * curRe - im[i + k + half] * curIm;
          final vIm = re[i + k + half] * curIm + im[i + k + half] * curRe;
          re[i + k] = uRe + vRe;
          im[i + k] = uIm + vIm;
          re[i + k + half] = uRe - vRe;
          im[i + k + half] = uIm - vIm;
          final nextRe = curRe * wRe - curIm * wIm;
          curIm = curRe * wIm + curIm * wRe;
          curRe = nextRe;
        }
      }
    }

    final bins = n >> 1;
    final mags = List<double>.filled(bins, 0);
    for (var i = 0; i < bins; i++) {
      mags[i] = sqrt(re[i] * re[i] + im[i] * im[i]) / n;
    }
    return mags;
  }
}
