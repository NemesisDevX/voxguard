import 'package:equatable/equatable.dart';

/// Acoustic forensic features extracted from an incoming audio chunk.
///
/// Produced by `AcousticForensicsService` (Engine A) and consumed by the
/// threat fusion engine. All values are normalized to 0.0 – 1.0.
final class AudioForensicMetrics extends Equatable {
  const AudioForensicMetrics({
    required this.spectralFlux,
    required this.spectralRolloffRatio,
    required this.zeroCrossingRate,
    required this.syntheticVoiceScore,
  });

  /// Neutral baseline — no suspicious acoustic evidence.
  const AudioForensicMetrics.zero()
      : spectralFlux = 0,
        spectralRolloffRatio = 0,
        zeroCrossingRate = 0,
        syntheticVoiceScore = 0;

  /// Frame-to-frame spectral change. Synthetic voices are typically
  /// "static" spectrally → low flux.
  final double spectralFlux;

  /// Frequency below which ~85% of spectral energy sits, expressed as a
  /// ratio of Nyquist. TTS/vocoder audio often shows an abnormally low,
  /// hard high-frequency cutoff.
  final double spectralRolloffRatio;

  /// Sign changes per sample. Human speech has varied ZCR; flat tonal
  /// synthesis produces abnormally low, stable values.
  final double zeroCrossingRate;

  /// Engine A output: likelihood the voice is synthetic (0.0 – 1.0).
  final double syntheticVoiceScore;

  /// Whether the synthetic-voice indicator is in the elevated band.
  bool get isSyntheticElevated => syntheticVoiceScore >= 0.70;

  /// Linear interpolation between two metric snapshots — used to smooth
  /// meter updates as chunks stream in.
  AudioForensicMetrics lerpTo(AudioForensicMetrics other, double t) {
    double l(double a, double b) => a + (b - a) * t;
    return AudioForensicMetrics(
      spectralFlux: l(spectralFlux, other.spectralFlux),
      spectralRolloffRatio:
          l(spectralRolloffRatio, other.spectralRolloffRatio),
      zeroCrossingRate: l(zeroCrossingRate, other.zeroCrossingRate),
      syntheticVoiceScore:
          l(syntheticVoiceScore, other.syntheticVoiceScore),
    );
  }

  @override
  List<Object?> get props => [
        spectralFlux,
        spectralRolloffRatio,
        zeroCrossingRate,
        syntheticVoiceScore,
      ];
}
