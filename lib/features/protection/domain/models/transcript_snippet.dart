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

  @override
  List<Object?> get props => [speaker, text, timestamp];
}
