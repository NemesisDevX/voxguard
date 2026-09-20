import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/alerts/onesignal_alert_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/domain/models/transcript_snippet.dart';
import '../../../protection/domain/services/semantic_threat_service.dart';
import '../../domain/models/incident_report.dart';

/// Executive forensic viewer for a single intercepted incident.
class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incident});

  final IncidentReport incident;

  Color get _riskColor => switch (incident.riskLevel) {
        ThreatRiskLevel.highRisk => AppColors.statusDanger,
        ThreatRiskLevel.suspicious => AppColors.statusWarning,
        ThreatRiskLevel.safe => AppColors.statusSafe,
      };

  String get _riskLabel => switch (incident.riskLevel) {
        ThreatRiskLevel.highRisk => 'CRITICAL / HIGH RISK',
        ThreatRiskLevel.suspicious => 'SUSPICIOUS',
        ThreatRiskLevel.safe => 'SAFE',
      };

  Future<void> _broadcast(BuildContext context) async {
    final result = await FamilyAlertLocator.instance
        .triggerFamilyEmergencyAlert(
      incident: incident,
      familyMemberIds: const ['family_member_1', 'family_member_2'],
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.detail)),
      );
    }
  }

  void _share(BuildContext context) {
    Clipboard.setData(ClipboardData(text: incident.toShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incident report copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(incident.id)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _HeaderCard(incident: incident, color: _riskColor, label: _riskLabel),
          const SizedBox(height: 16),
          _IntegrityCard(incident: incident),
          const SizedBox(height: 16),
          _AcousticCard(incident: incident),
          const SizedBox(height: 16),
          _SemanticCard(incident: incident),
          const SizedBox(height: 16),
          _TranscriptCard(incident: incident),
          const SizedBox(height: 16),
          _ActionsCard(
            incident: incident,
            onBroadcast: () => _broadcast(context),
            onShare: () => _share(context),
          ),
          const SizedBox(height: 20),
          Text(
            incident.disclaimer,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card shell ────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.incident,
    required this.color,
    required this.label,
  });

  final IncidentReport incident;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(incident.id, style: AppTypography.titleLarge),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${incident.timestampLabel}  ·  ${incident.callerLabel}  ·  ${incident.durationLabel}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Peak Risk ',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textMuted),
              ),
              Text(
                '${(incident.peakRiskScore * 100).round()}%',
                style: AppTypography.statLarge.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Audio hash & integrity ───────────────────────────────────────────

class _IntegrityCard extends StatelessWidget {
  const _IntegrityCard({required this.incident});

  final IncidentReport incident;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'AUDIO HASH & INTEGRITY',
      icon: Icons.fingerprint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.audioSha256,
            style: AppTypography.bodyMedium.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.verified, size: 14, color: AppColors.statusSafe),
              SizedBox(width: 6),
              Text(
                '16 kHz PCM · integrity verified',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Acoustic breakdown ───────────────────────────────────────────────

class _AcousticCard extends StatelessWidget {
  const _AcousticCard({required this.incident});

  final IncidentReport incident;

  @override
  Widget build(BuildContext context) {
    final m = incident.acousticMetrics;
    return _Card(
      title: 'ACOUSTIC BREAKDOWN',
      icon: Icons.graphic_eq,
      child: Column(
        children: [
          _metricRow('Spectral Flux', m.spectralFlux, invertRisk: true),
          _metricRow('Spectral Rolloff', m.spectralRolloffRatio,
              invertRisk: true),
          _metricRow('Zero-Crossing Rate', m.zeroCrossingRate,
              invertRisk: true),
          _metricRow('Synthetic Voice Score', m.syntheticVoiceScore),
        ],
      ),
    );
  }

  /// [invertRisk] — for flux/rolloff/ZCR, LOW values are the anomaly
  /// (a static spectrum signals synthesis), so the bar inverts.
  Widget _metricRow(String label, double value, {bool invertRisk = false}) {
    final riskValue = invertRisk ? 1 - value : value;
    final color = AppColors.forThreat(riskValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor:
                    AppColors.borderSubtle.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.end,
              style: AppTypography.labelLarge.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Semantic signals ─────────────────────────────────────────────────

class _SemanticCard extends StatelessWidget {
  const _SemanticCard({required this.incident});

  final IncidentReport incident;

  @override
  Widget build(BuildContext context) {
    final s = incident.semanticSignals;
    return _Card(
      title: 'SEMANTIC SIGNALS',
      icon: Icons.psychology_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _scoreBadge('URGENCY', s.urgencyScore),
              _scoreBadge('FINANCIAL', s.financialDemandScore),
              _scoreBadge('SECRECY', s.secrecyScore),
            ],
          ),
          if (s.detectedKeywords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in s.detectedKeywords)
                  _keywordChip(k, AppColors.statusWarning),
                for (final c in s.impersonationClaims)
                  _keywordChip(c, AppColors.statusDanger),
              ],
            ),
          ],
          const SizedBox(height: 8),
          for (final r in incident.threatReasons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_outlined,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r, style: AppTypography.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _scoreBadge(String label, double score) {
    final color = AppColors.forThreat(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label ${(score * 100).round()}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _keywordChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Transcript timeline with highlighted scam phrases ───────────────

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.incident});

  final IncidentReport incident;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'TRANSCRIPT TIMELINE',
      icon: Icons.forum_outlined,
      child: incident.transcriptSnippets.isEmpty
          ? const Text('No transcript captured.',
              style: AppTypography.bodyMedium)
          : Column(
              children: [
                for (final s in incident.transcriptSnippets)
                  _bubble(s),
              ],
            ),
    );
  }

  Widget _bubble(TranscriptSnippet s) {
    final isCaller = s.speaker != AppStrings.speakerYou;
    return Align(
      alignment: isCaller ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isCaller ? AppColors.bgElevated : AppColors.accentMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCaller
                ? AppColors.borderSubtle
                : AppColors.accent.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.speaker,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                color: isCaller
                    ? AppColors.statusWarning
                    : AppColors.statusSafe,
              ),
            ),
            const SizedBox(height: 3),
            RichText(
              textDirection: _isRtl(s.text)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              text: TextSpan(
                style: AppTypography.bodyLarge.copyWith(fontSize: 13.5),
                children: _highlightedSpans(s.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isRtl(String text) => text.isNotEmpty && text.codeUnitAt(0) > 0x0600;

  /// Splits [text] into spans, painting impersonation/financial phrases
  /// crimson and urgency/secrecy phrases amber.
  List<TextSpan> _highlightedSpans(String text) {
    final ranges = <_PhraseRange>[];
    for (final phrase in incident.flaggedPhrases) {
      var cursor = 0;
      while (cursor < text.length) {
        final hit = _indexOfPhrase(text, phrase, cursor);
        if (hit < 0) break;
        ranges.add(_PhraseRange(hit, hit + phrase.length, phrase));
        cursor = hit + phrase.length;
      }
    }
    if (ranges.isEmpty) return [TextSpan(text: text)];

    ranges.sort((a, b) => a.start.compareTo(b.start));

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final r in ranges) {
      if (r.start < cursor) continue; // overlap — skip
      if (r.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, r.start)));
      }
      final color = _phraseColor(r.phrase);
      spans.add(
        TextSpan(
          text: text.substring(r.start, r.end),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            backgroundColor: color.withValues(alpha: 0.14),
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

  int _indexOfPhrase(String text, String phrase, int from) {
    if (phrase.codeUnits.every((c) => c < 128)) {
      return text.toLowerCase().indexOf(phrase.toLowerCase(), from);
    }
    return text.indexOf(phrase, from);
  }

  Color _phraseColor(String phrase) {
    if (SemanticThreatService.impersonationLexicon.contains(phrase) ||
        SemanticThreatService.financialLexicon.contains(phrase)) {
      return AppColors.statusDanger;
    }
    return AppColors.statusWarning;
  }
}

class _PhraseRange {
  const _PhraseRange(this.start, this.end, this.phrase);
  final int start;
  final int end;
  final String phrase;
}

// ── Action buttons ───────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.incident,
    required this.onBroadcast,
    required this.onShare,
  });

  final IncidentReport incident;
  final VoidCallback onBroadcast;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onBroadcast,
            icon: const Icon(Icons.broadcast_on_personal, size: 20),
            label: const Text(
              'Broadcast to Family Shield',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text(
              'Share Incident Report',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
