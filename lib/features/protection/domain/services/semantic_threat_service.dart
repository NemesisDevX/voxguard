import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/semantic_threat_signals.dart';

/// Engine B — Semantic Threat Engine.
///
/// Evaluates the call transcript for scam semantics. When a Groq API
/// key is configured (`--dart-define=GROQ_API_KEY=...`), analysis is
/// delegated to a Llama-3 chat completion; otherwise — and on any API
/// failure — a deterministic bilingual (EN / Egyptian-Arabic) rule
/// engine produces the same signal shape locally.
///
/// Minimal contract for the conversation-risk engine — the seam the
/// SafeCall bloc depends on. Tests inject a controllable fake through
/// it; [SemanticThreatService] is the production implementation
/// (deterministic local rules + explicit opt-in dev remote).
abstract interface class ISemanticThreatAnalyzer {
  /// Analyzes accumulated transcript text and returns threat signals.
  Future<SemanticThreatSignals> analyze(String transcript);
}

/// **Security note:** remote Groq semantics are a *development-only*
/// escape hatch — production VoxGuard uses the deterministic local
/// rule engine. Remote analysis requires BOTH a key AND the explicit
/// opt-in flag `VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC=true`; a key
/// alone (e.g. left in a release build) is not enough. A permanent
/// Groq key must never ship in a released build.
final class SemanticThreatService implements ISemanticThreatAnalyzer {
  SemanticThreatService({
    http.Client? httpClient,
    String? apiKey,
    bool? devRemoteSemantic,
  })  : _client = httpClient ?? http.Client(),
        _apiKey = apiKey ??
            const String.fromEnvironment('GROQ_API_KEY', defaultValue: ''),
        _devRemote = devRemoteSemantic ??
            const bool.fromEnvironment(
              'VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC',
              defaultValue: false,
            );

  static const _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';
  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String _apiKey;

  /// Explicit developer opt-in for remote transcript analysis. Without
  /// it — even with a key present — everything stays on-device.
  final bool _devRemote;

  /// True only when remote Groq analysis is *both* keyed and opted in.
  bool get remoteSemanticEnabled => _apiKey.isNotEmpty && _devRemote;

  /// Analyzes accumulated transcript text and returns threat signals.
  ///
  /// Uses Groq only when [remoteSemanticEnabled]; otherwise — and on
  /// any remote failure — the deterministic local rule engine runs.
  @override
  Future<SemanticThreatSignals> analyze(String transcript) async {
    if (transcript.trim().isEmpty) {
      return const SemanticThreatSignals.empty();
    }
    if (remoteSemanticEnabled) {
      try {
        return await _analyzeWithGroq(transcript);
      } on Exception {
        // Network/parse failure — degrade gracefully to local rules.
      }
    }
    return analyzeLocally(transcript);
  }

  // ── Groq API path ────────────────────────────────────────────────

  Future<SemanticThreatSignals> _analyzeWithGroq(String transcript) async {
    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'temperature': 0,
            'response_format': {'type': 'json_object'},
            'messages': [
              {
                'role': 'system',
                'content': 'You are a scam-call detection engine. '
                    'Analyze the call transcript (it may be Arabic or '
                    'English) and respond ONLY with compact JSON: '
                    '{"urgency_score":0.0-1.0,'
                    '"financial_demand_score":0.0-1.0,'
                    '"secrecy_score":0.0-1.0,'
                    '"detected_keywords":["..."],'
                    '"impersonation_claims":["..."]}',
              },
              {'role': 'user', 'content': transcript},
            ],
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Groq API error ${response.statusCode}',
        Uri.parse(_endpoint),
      );
    }

    final envelope =
        jsonDecode(response.body) as Map<String, dynamic>;
    final content = (envelope['choices'] as List).first['message']
        ['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;

    return SemanticThreatSignals(
      urgencyScore: _asScore(parsed['urgency_score']),
      financialDemandScore: _asScore(parsed['financial_demand_score']),
      secrecyScore: _asScore(parsed['secrecy_score']),
      detectedKeywords: _asStringList(parsed['detected_keywords']),
      impersonationClaims: _asStringList(parsed['impersonation_claims']),
    );
  }

  double _asScore(Object? value) {
    if (value is num) return value.toDouble().clamp(0.0, 1.0);
    return 0;
  }

  List<String> _asStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  // ── Local deterministic rule engine ─────────────────────────────

  /// High-precision fallback analyzer. Counts lexicon hits per threat
  /// vector: 1 hit → 0.5, 2 hits → 0.8, 3+ hits → 1.0.
  SemanticThreatSignals analyzeLocally(String transcript) {
    final urgencyHits = _matchAll(transcript, urgencyLexicon);
    final financialHits = _matchAll(transcript, financialLexicon);
    final secrecyHits = _matchAll(transcript, secrecyLexicon);
    final impersonationHits = _matchAll(transcript, impersonationLexicon);

    return SemanticThreatSignals(
      urgencyScore: _hitsToScore(urgencyHits.length),
      financialDemandScore: _hitsToScore(financialHits.length),
      secrecyScore: _hitsToScore(secrecyHits.length),
      detectedKeywords: [
        ...urgencyHits,
        ...financialHits,
        ...secrecyHits,
      ],
      impersonationClaims: impersonationHits,
    );
  }

  double _hitsToScore(int hits) {
    if (hits <= 0) return 0;
    return (0.5 + 0.3 * (hits - 1)).clamp(0.0, 1.0);
  }

  /// Returns the distinct lexicon entries present in [text].
  List<String> _matchAll(String text, Set<String> lexicon) {
    final hits = <String>[];
    for (final term in lexicon) {
      if (_containsTerm(text, term)) hits.add(term);
    }
    return hits;
  }

  /// ASCII terms match on word boundaries (so "now" doesn't fire on
  /// "know"); Arabic terms match as substrings since affixes attach
  /// directly to the stem.
  bool _containsTerm(String text, String term) {
    if (_isAscii(term)) {
      return RegExp('\\b${RegExp.escape(term)}\\b', caseSensitive: false)
          .hasMatch(text);
    }
    return text.contains(term);
  }

  bool _isAscii(String s) => s.codeUnits.every((c) => c < 128);

  // ── Threat lexicons (EN + Egyptian Arabic) ──────────────────────

  static const urgencyLexicon = {
    'quickly', 'now', 'emergency', 'urgent', 'immediately',
    'right away', 'hurry', 'asap', 'act fast',
    'بسرعة', 'ضروري', 'دلوقتي', 'عاجل', 'حالاً', 'حالا',
    'الحقني', 'مستعجل', 'فوراً', 'فورا', 'خطير',
  };

  static const financialLexicon = {
    'transfer', 'bank', 'wallet', 'cash', 'money', 'payment',
    'send money', 'gift card', 'wire', 'deposit',
    'حول', 'حوالة', 'فلوس', 'جنيه', 'محفظة', 'تحويل',
    'فودافون كاش', 'انستاباي', 'ادفع', 'حساب',
  };

  static const secrecyLexicon = {
    "don't tell", 'do not tell', 'keep it secret', 'between us',
    'our secret', 'tell no one', "don't tell anyone", 'stay alone',
    'متقولش', 'ماتقولش', 'متقولش لحد', 'بيني وبينك', 'سر',
    'محدش يعرف', 'لوحدك', 'متحدش',
  };

  static const impersonationLexicon = {
    "i'm your", 'i am your', 'this is your', 'your brother',
    'your son', 'your boss', 'bank security', 'its me', "it's me",
    'أنا أخوك', 'أنا اخوك', 'أخوك', 'أنا قريبك', 'أنا ابنك',
    'أنا مديرك', 'أنا من البنك', 'أنا من شركة',
  };
}
