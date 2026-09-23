import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';
import 'package:voxguard/features/protection/domain/services/semantic_threat_service.dart';
import 'package:voxguard/features/protection/domain/services/threat_fusion_engine.dart';
import 'package:voxguard/core/utils/threat_phrase_highlighter.dart';

void main() {
  final engine = ThreatFusionEngine();

  AudioForensicMetrics acoustic(double synthetic) => AudioForensicMetrics(
        spectralFlux: 0.1,
        spectralRolloffRatio: 0.1,
        zeroCrossingRate: 0.03,
        syntheticVoiceScore: synthetic,
      );

  SemanticThreatSignals semantic({
    double urgency = 0,
    double financial = 0,
    double secrecy = 0,
    List<String> claims = const [],
  }) =>
      SemanticThreatSignals(
        urgencyScore: urgency,
        financialDemandScore: financial,
        secrecyScore: secrecy,
        detectedKeywords: const [],
        impersonationClaims: claims,
      );

  group('ThreatFusionEngine', () {
    test('flags SAFE for a clean call', () {
      final report = engine.fuse(
        acoustic(0.05),
        semantic(urgency: 0.05, financial: 0.02, secrecy: 0.03),
      );

      expect(report.riskLevel, ThreatRiskLevel.safe);
      expect(report.compositeRiskScore, lessThan(0.40));
      expect(report.recommendedAction, 'Continue monitoring');
    });

    test('flags HIGH RISK for a coordinated scam signature', () {
      final report = engine.fuse(
        acoustic(0.85),
        semantic(
          urgency: 0.9,
          financial: 0.95,
          secrecy: 0.85,
          claims: const ['أنا أخوك'],
        ),
      );

      expect(report.riskLevel, ThreatRiskLevel.highRisk);
      expect(report.compositeRiskScore, greaterThan(0.85));
      expect(report.primaryThreatReasons, isNotEmpty);
      expect(
        report.recommendedAction,
        contains('End call'),
      );
    });

    test('applies +15% amplification when all three semantic signals exceed 0.75', () {
      final unamplified = engine.fuse(
        acoustic(0.5),
        semantic(urgency: 0.8, financial: 0.8, secrecy: 0.7),
      );
      final amplified = engine.fuse(
        acoustic(0.5),
        semantic(urgency: 0.8, financial: 0.8, secrecy: 0.8),
      );

      // Same signals except secrecy crossing the 0.75 threshold → the
      // boosted score must exceed the plain weighted blend.
      expect(
        amplified.compositeRiskScore,
        greaterThan(unamplified.compositeRiskScore),
      );
    });

    test('flags SUSPICIOUS for a mid-range composite', () {
      final report = engine.fuse(
        acoustic(0.3),
        semantic(urgency: 0.8, financial: 0.5, secrecy: 0.4),
      );

      expect(report.riskLevel, ThreatRiskLevel.suspicious);
      expect(report.compositeRiskScore,
          inInclusiveRange(0.40, 0.75));
    });
  });

  group('SemanticThreatService (local engine)', () {
    final service = SemanticThreatService();

    test('detects the Arabic demo scam script', () {
      final signals = service.analyzeLocally(
        'أنا أخوك، حول لي 2,000 جنيه بسرعة على المحفظة، '
        'متقولش لحد الموضوع خطير',
      );

      expect(signals.financialDemandScore, greaterThan(0.75));
      expect(signals.urgencyScore, greaterThan(0.5));
      expect(signals.secrecyScore, greaterThan(0.5));
      expect(signals.impersonationClaims, isNotEmpty);
      expect(signals.detectedKeywords, isNotEmpty);
    });

    test('detects English scam phrases', () {
      final signals = service.analyzeLocally(
        "This is your bank security. Transfer the money now, "
        "it's an emergency. Don't tell anyone.",
      );

      expect(signals.urgencyScore, greaterThan(0));
      expect(signals.financialDemandScore, greaterThan(0));
      expect(signals.secrecyScore, greaterThan(0));
    });

    test('returns zero scores for benign conversation', () {
      final signals = service.analyzeLocally(
        'Hey, are we still on for dinner tonight?',
      );

      expect(signals.urgencyScore, 0);
      expect(signals.financialDemandScore, 0);
      expect(signals.secrecyScore, 0);
      expect(signals.impersonationClaims, isEmpty);
    });
  });

  group('SemanticThreatService (semantic proxy path)', () {
    SemanticThreatService proxied(
      http_testing.MockClient client, {
      String relayToken = 'relay-tok',
    }) =>
        SemanticThreatService(
          httpClient: client,
          proxyUrl: 'https://relay.example.com',
          relayToken: relayToken,
        );

    test('configured proxy POSTs transcript + bearer token to /semantic',
        () async {
      Uri? hit;
      Map<String, dynamic>? sent;
      String? auth;
      final client = http_testing.MockClient((req) async {
        hit = req.url;
        auth = req.headers['Authorization'];
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'urgency_score': 0.9,
            'financial_demand_score': 0.8,
            'secrecy_score': 0.6,
            'detected_keywords': ['now'],
            'impersonation_claims': ['i am your son'],
          }),
          200,
        );
      });
      final svc = proxied(client);
      expect(svc.proxyConfigured, isTrue);

      final signals = await svc.analyze('send money now');
      expect(hit!.path, '/semantic');
      expect(auth, 'Bearer relay-tok');
      expect(sent, {'transcript': 'send money now'});
      expect(signals.urgencyScore, 0.9);
      expect(signals.impersonationClaims, ['i am your son']);
    });

    test('transcript is truncated to the proxy bound before sending',
        () async {
      int? sentLength;
      final client = http_testing.MockClient((req) async {
        sentLength = (jsonDecode(req.body)
            as Map<String, dynamic>)['transcript']
            .toString()
            .length;
        return http.Response(
          jsonEncode({
            'urgency_score': 0.0,
            'financial_demand_score': 0.0,
            'secrecy_score': 0.0,
          }),
          200,
        );
      });
      final svc = proxied(client);
      await svc.analyze('x' * 20000);
      expect(sentLength, 12000);
    });

    test('proxy non-200 falls back to the local engine', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response('upstream down', 502),
      );
      final svc = proxied(client);
      // Local rules catch this — proxy failure must not hide it.
      final signals = await svc.analyze('transfer money now');
      expect(signals.financialDemandScore, greaterThan(0));
      expect(signals.urgencyScore, greaterThan(0));
    });

    test('malformed proxy JSON falls back to local rules', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response('{"urgency_score":"high"}', 200),
      );
      final svc = proxied(client);
      final signals = await svc.analyze('send a wire now');
      expect(signals.financialDemandScore, greaterThan(0));
    });

    test('proxy unreachable falls back to local rules', () async {
      final client = http_testing.MockClient(
        (_) async => throw http.ClientException('dns'),
      );
      final svc = proxied(client);
      final signals = await svc.analyze('urgent transfer now');
      expect(signals.urgencyScore, greaterThan(0));
    });

    test('unconfigured proxy stays fully local — zero HTTP calls',
        () async {
      var hit = false;
      final client = http_testing.MockClient((_) async {
        hit = true;
        return http.Response('{}', 200);
      });
      final svc = SemanticThreatService(httpClient: client, proxyUrl: '');
      expect(svc.proxyConfigured, isFalse);
      await svc.analyze('send money now');
      expect(hit, isFalse);
    });

    test('empty transcript short-circuits before any remote call',
        () async {
      var hit = false;
      final client = http_testing.MockClient((_) async {
        hit = true;
        return http.Response('{}', 200);
      });
      final svc = proxied(client);
      final signals = await svc.analyze('   ');
      expect(signals.urgencyScore, 0);
      expect(hit, isFalse);
    });
  });

  group('SemanticThreatSignals.evidenceCategories', () {
    test('exposes all four evidence buckets for the demo scam script', () {
      final signals = SemanticThreatService().analyzeLocally(
        'أنا أخوك، حول لي 2,000 جنيه بسرعة على المحفظة، '
        'متقولش لحد الموضوع خطير',
      );

      expect(
        signals.evidenceCategories,
        containsAll([
          EvidenceCategory.impersonation,
          EvidenceCategory.moneyRequest,
          EvidenceCategory.urgency,
          EvidenceCategory.secrecy,
        ]),
      );
      expect(signals.flaggedPhrases, isNotEmpty);
    });

    test('is empty for benign signals', () {
      expect(
        const SemanticThreatSignals.empty().evidenceCategories,
        isEmpty,
      );
    });
  });

  group('isRtlText — first strong direction wins', () {
    test('Arabic lead → rtl', () {
      expect(isRtlText('حول الفلوس دلوقتي'), isTrue);
    });

    test('English lead → ltr', () {
      expect(isRtlText('Transfer the money now'), isFalse);
    });

    test('neutral punctuation/digits before Arabic still → rtl', () {
      expect(isRtlText('"123" — حول الفلوس'), isTrue);
      expect(isRtlText('"أخوك" — transfer now'), isTrue);
    });

    test('neutral lead then English → ltr (IDs never flip)', () {
      expect(isRtlText('INC-2026-0001 flagged'), isFalse);
      expect(isRtlText('(vg_abc123) verified'), isFalse);
    });

    test('empty and symbol-only strings stay ltr', () {
      expect(isRtlText(''), isFalse);
      expect(isRtlText('123 — !!!'), isFalse);
    });
  });
}

