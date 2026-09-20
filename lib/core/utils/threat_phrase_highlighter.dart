import 'package:flutter/material.dart';

import '../../features/protection/domain/services/semantic_threat_service.dart';
import '../theme/app_colors.dart';

/// Splits [text] into [TextSpan]s, painting impersonation and
/// money-demand phrases crimson, and urgency/secrecy phrases amber.
///
/// Used by both the live transcript feed and the forensic detail view
/// so evidence highlighting is identical everywhere.
List<TextSpan> buildThreatSpans(
  String text,
  List<String> phrases, {
  required TextStyle baseStyle,
}) {
  final ranges = <_PhraseRange>[];
  for (final phrase in phrases) {
    var cursor = 0;
    while (cursor < text.length) {
      final hit = _indexOfPhrase(text, phrase, cursor);
      if (hit < 0) break;
      ranges.add(_PhraseRange(hit, hit + phrase.length, phrase));
      cursor = hit + phrase.length;
    }
  }
  if (ranges.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  ranges.sort((a, b) => a.start.compareTo(b.start));

  final spans = <TextSpan>[];
  var cursor = 0;
  for (final r in ranges) {
    if (r.start < cursor) continue; // overlapping match — skip
    if (r.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, r.start)));
    }
    final color = threatPhraseColor(r.phrase);
    spans.add(
      TextSpan(
        text: text.substring(r.start, r.end),
        style: baseStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          backgroundColor: color.withValues(alpha: 0.16),
        ),
      ),
    );
    cursor = r.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

/// Crimson for impersonation + money demands, amber for
/// urgency + secrecy.
Color threatPhraseColor(String phrase) {
  if (SemanticThreatService.impersonationLexicon.contains(phrase) ||
      SemanticThreatService.financialLexicon.contains(phrase)) {
    return AppColors.statusDanger;
  }
  return AppColors.statusWarning;
}

/// True when [text] begins with an Arabic codepoint — drives RTL
/// rendering in transcript bubbles.
bool isRtlText(String text) => text.isNotEmpty && text.codeUnitAt(0) > 0x0600;

int _indexOfPhrase(String text, String phrase, int from) {
  if (phrase.codeUnits.every((c) => c < 128)) {
    return text.toLowerCase().indexOf(phrase.toLowerCase(), from);
  }
  return text.indexOf(phrase, from);
}

class _PhraseRange {
  const _PhraseRange(this.start, this.end, this.phrase);
  final int start;
  final int end;
  final String phrase;
}
