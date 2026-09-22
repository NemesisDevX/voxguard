import 'package:flutter/material.dart';

import '../../features/protection/domain/services/semantic_threat_service.dart';
import '../theme/app_palette.dart';

/// Splits [text] into [TextSpan]s, painting impersonation and
/// money-demand phrases crimson, and urgency/secrecy phrases amber.
///
/// Used by both the live transcript feed and the forensic detail view
/// so evidence highlighting is identical everywhere.
List<TextSpan> buildThreatSpans(
  String text,
  List<String> phrases, {
  required TextStyle baseStyle,
  required AppPalette palette,
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
    final color = threatPhraseColor(r.phrase, palette);
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
Color threatPhraseColor(String phrase, AppPalette palette) {
  if (SemanticThreatService.impersonationLexicon.contains(phrase) ||
      SemanticThreatService.financialLexicon.contains(phrase)) {
    return palette.statusDanger;
  }
  return palette.statusWarning;
}

/// True when the first *strong-directional* character in [text] is
/// RTL (Arabic/Hebrew blocks + presentation forms). Neutral
/// punctuation, digits and Latin lead-ins are skipped so mixed
/// strings like `"أخوك" — transfer now` still resolve correctly and
/// numbers/technical IDs are never force-reversed.
bool isRtlText(String text) {
  const scanLimit = 64;
  final units = text.codeUnits;
  final limit = units.length < scanLimit ? units.length : scanLimit;
  for (var i = 0; i < limit; i++) {
    final c = units[i];
    // RTL strong ranges: Hebrew, Arabic, Arabic Supplement,
    // Arabic Extended-A, Arabic Presentation Forms A & B.
    if ((c >= 0x0590 && c <= 0x05FF) ||
        (c >= 0x0600 && c <= 0x06FF) ||
        (c >= 0x0750 && c <= 0x077F) ||
        (c >= 0x08A0 && c <= 0x08FF) ||
        (c >= 0xFB50 && c <= 0xFDFF) ||
        (c >= 0xFE70 && c <= 0xFEFF)) {
      return true;
    }
    // LTR strong: Latin letters/digits settle direction first.
    if ((c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A)) {
      return false;
    }
  }
  return false;
}

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
