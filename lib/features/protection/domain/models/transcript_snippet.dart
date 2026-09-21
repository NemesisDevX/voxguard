import 'package:equatable/equatable.dart';

/// A single line of live call dialogue shown in the transcript feed.
final class TranscriptSnippet extends Equatable {
  const TranscriptSnippet({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  /// Speaker label, e.g. "Caller" or "You".
  final String speaker;

  /// Spoken text as transcribed.
  final String text;

  /// When the snippet arrived.
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Strict decode — bounded strings, parseable timestamp.
  static TranscriptSnippet? fromJson(Map<String, dynamic> json) {
    final speaker = json['speaker'];
    final text = json['text'];
    final ts = DateTime.tryParse('${json['timestamp'] ?? ''}');
    if (speaker is! String ||
        speaker.isEmpty ||
        speaker.length > 64 ||
        text is! String ||
        text.isEmpty ||
        text.length > 8000 ||
        ts == null) {
      return null;
    }
    return TranscriptSnippet(
        speaker: speaker, text: text, timestamp: ts);
  }

  @override
  List<Object?> get props => [speaker, text, timestamp];
}
