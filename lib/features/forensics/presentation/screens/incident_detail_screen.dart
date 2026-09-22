import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/alerts/family_shield_alert_service.dart';
import '../../../../core/services/family/family_shield_response.dart';
import '../../../../core/services/family/received_family_alert_repository.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/threat_phrase_highlighter.dart';
import '../../../paywall/domain/models/subscription_tier.dart';
import '../../../paywall/domain/services/product_access.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/domain/models/semantic_threat_signals.dart';
import '../../../protection/domain/models/transcript_snippet.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/services/incident_repository.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';
import '../../../../core/theme/app_palette.dart';

/// Forensic viewer for a single flagged incident — consumer-first
/// evidence hierarchy with technical telemetry collapsed by default.
class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incident});

  final IncidentReport incident;

  /// A partial record is an acoustic warning, not a call verdict —
  /// it renders in warning color with its own label.
  Color _riskColor(AppPalette p) => incident.analysisIsPartial
      ? p.statusWarning
      : switch (incident.riskLevel) {
          ThreatRiskLevel.highRisk => p.statusDanger,
          ThreatRiskLevel.suspicious => p.statusWarning,
          ThreatRiskLevel.safe => p.statusSafe,
        };

  String get _riskLabel => incident.analysisIsPartial
      ? l10n.bandPartial
      : switch (incident.riskLevel) {
          ThreatRiskLevel.highRisk => l10n.bandCritical,
          ThreatRiskLevel.suspicious => l10n.bandSuspicious,
          ThreatRiskLevel.safe => l10n.bandSafe,
        };

  Future<void> _broadcast(BuildContext context) async {
    final demo = FamilyAlertLocator.instance.isDemoMode;
    // Real outbound alerts are a Family Vault capability — the
    // service enforces the same gate, this is the UI boundary.
    if (!demo &&
        !ProductAccessLocator
            .instance.capabilities.familyShieldOutbound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.familyVaultUnlocksAlerts),
        ),
      );
      PaywallScreen.show(context, preselect: TierId.familyVault);
      return;
    }
    // Demo Mode → labelled demo contacts; real relay → persisted
    // Trusted Circle only (empty circle yields a truthful no-op).
    final repo = FamilyAlertLocator.instance.isDemoMode
        ? const DemoFamilyContactRepository()
        : FamilyContactLocator.instance;
    final contacts = await repo.getFamilyContacts();
    if (!context.mounted) return;
    final result =
        await FamilyAlertLocator.instance.triggerFamilyEmergencyAlert(
      incident: incident,
      familyMemberIds: [for (final c in contacts) c.externalId],
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.serviceMessage(result.detail))),
      );
    }
  }

  void _share(BuildContext context) {
    Clipboard.setData(ClipboardData(text: incident.toShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.incidentCopied)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
  final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.incidentDeleteTitle),
        content: Text(l10n.incidentDeleteBody(incident.id)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.actionDelete,
              style: TextStyle(
                color: p.statusDanger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await IncidentRepositoryLocator.instance.deleteIncident(incident.id);
    } on IncidentPersistenceException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.incidentDeleteFailed)),
        );
      }
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(incident.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.incidentDeleteTooltip,
            color: p.statusDanger,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _HeaderCard(
              incident: incident, color: _riskColor(p), label: _riskLabel),
          const SizedBox(height: 16),
          _FamilyResponsesCard(incidentId: incident.id),
          _WhyFlaggedCard(incident: incident),
          const SizedBox(height: 16),
          _TranscriptCard(incident: incident),
          const SizedBox(height: 16),
          _ActionsCard(
            incident: incident,
            onBroadcast: () => _broadcast(context),
            onShare: () => _share(context),
          ),
          const SizedBox(height: 16),
          _TechnicalEvidenceSection(incident: incident),
          const SizedBox(height: 20),
          Text(
            // The persisted field stays stable English; the known
            // default localizes, a future custom value passes through.
            incident.disclaimer == IncidentReport.legalDisclaimer
                ? l10n.reportDisclaimer
                : incident.disclaimer,
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

// ── Family Shield human resolutions ──────────────────────────────────

/// Human verification layer — trusted contacts' responses to this
/// incident's Family Shield alert. Strictly separate from the AI
/// assessment: a "marked safe" here never alters the risk score.
class _FamilyResponsesCard extends StatelessWidget {
  const _FamilyResponsesCard({required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<FamilyShieldResponse>>(
      valueListenable: FamilyShieldResponseLocator.instance.responses,
      builder: (context, responses, _) {
        final mine =
            [for (final r in responses) if (r.incidentId == incidentId) r];
        if (mine.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _Card(
            title: l10n.incidentFamilyResponses,
            icon: Icons.group_outlined,
            child: Column(
              children: [
                for (final r in mine) _ResponseRow(response: r),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResponseRow extends StatelessWidget {
  const _ResponseRow({required this.response});

  final FamilyShieldResponse response;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isSafe = response.resolution == AlertResolution.safe;
    return FutureBuilder<String>(
      future: _responderName(),
      builder: (context, snap) {
        final name = snap.data ?? l10n.unrecognizedIdentity;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                isSafe
                    ? Icons.verified_user_outlined
                    : Icons.warning_amber_outlined,
                size: 18,
                color: isSafe
                    ? p.statusSafe
                    : p.statusWarning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSafe
                      ? l10n.familyMarkedSafe(name)
                      : l10n.familyStillConcerned(name),
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _responderName() async {
    final contacts =
        await FamilyContactLocator.instance.getFamilyContacts();
    for (final c in contacts) {
      if (c.externalId == response.responderExternalId) return c.name;
    }
    // Unknown id — opaque, not evidence of trust.
    return l10n.unrecognizedIdentity;
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
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: p.accent),
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
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.bgElevated,
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
            '${incident.timestampLabel}  ·  ${context.sourceLabel(incident.callerLabel)}  ·  ${incident.durationLabel}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 10),
          if (incident.analysisIsPartial) ...[
            Row(
              children: [
                Text(
                  l10n.acousticAnomalyPrefix,
                  style: AppTypography.labelLarge
                      .copyWith(color: p.textMuted),
                ),
                Text(
                  '${(incident.acousticMetrics.syntheticVoiceScore * 100).round()}/100',
                  style: AppTypography.statLarge.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.conversationNotAnalyzed,
              style: AppTypography.bodyMedium,
            ),
          ] else
            Row(
              children: [
                Text(
                  '${l10n.threatScoreLabel} ',
                  style: AppTypography.labelLarge
                      .copyWith(color: p.textMuted),
                ),
                Text(
                  '${(incident.peakRiskScore * 100).round()}/100',
                  style: AppTypography.statLarge.copyWith(color: color),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Why flagged — the consumer-facing explanation ────────────────────

class _WhyFlaggedCard extends StatelessWidget {
  const _WhyFlaggedCard({required this.incident});

  final IncidentReport incident;

  /// Source-aware title — an uploaded recording is not a call, and a
  /// partial analysis is an acoustic warning rather than a verdict.
  String get _title {
    if (incident.audioSourceLabel == 'Uploaded Recording') {
      return incident.analysisIsPartial
          ? l10n.whyElevatedAcousticTitle
          : l10n.whyFlaggedRecordingTitle;
    }
    return l10n.whyFlaggedCallTitle;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = incident.semanticSignals;
    return _Card(
      title: _title,
      icon: Icons.help_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strongest evidence — reasons the fusion engine produced.
          for (final r in incident.threatReasons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag_outlined,
                      size: 14, color: p.statusDanger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.threatReason(r), style: AppTypography.bodyLarge)),
                ],
              ),
            ),
          if (s.evidenceCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in s.evidenceCategories)
                  _evidenceChip(e, p),
              ],
            ),
          ],
          if (incident.recommendedActions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: p.borderSubtle),
            const SizedBox(height: 12),
            Text(
              l10n.incidentRecommended,
              style: AppTypography.labelSmall
                  .copyWith(color: p.textMuted),
            ),
            const SizedBox(height: 8),
            for (final a in incident.recommendedActions.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: p.statusSafe),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(context.threatReason(a), style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: p.accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: p.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.verifyIdentityBody,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _evidenceChip(EvidenceCategory e, AppPalette p) {
    final color = switch (e) {
      EvidenceCategory.impersonation ||
      EvidenceCategory.moneyRequest =>
        p.statusDanger,
      _ => p.statusWarning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        localizeEvidenceLabel(l10n, e.label),
        style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

// ── Collapsible technical evidence ───────────────────────────────────

class _TechnicalEvidenceSection extends StatefulWidget {
  const _TechnicalEvidenceSection({required this.incident});

  final IncidentReport incident;

  @override
  State<_TechnicalEvidenceSection> createState() =>
      _TechnicalEvidenceSectionState();
}

class _TechnicalEvidenceSectionState extends State<_TechnicalEvidenceSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.biotech_outlined,
                      size: 16, color: p.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.incidentTechnicalEvidence,
                      style: AppTypography.labelSmall,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: p.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  _IntegrityCard(incident: widget.incident),
                  const SizedBox(height: 10),
                  _AcousticCard(incident: widget.incident),
                  const SizedBox(height: 10),
                  _SemanticCard(incident: widget.incident),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
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
    final p = context.palette;
    return _Card(
      title: l10n.incidentAudioSha,
      icon: Icons.fingerprint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.audioDigestSha256,
            style: AppTypography.bodyMedium.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.graphic_eq,
                  size: 14, color: p.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${context.sourceLabel(incident.audioSourceLabel)} · '
                  '${context.sourceLabel(incident.transcriptionSourceLabel)}',
                  style: AppTypography.bodyMedium,
                ),
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
  final p = context.palette;
    final m = incident.acousticMetrics;
    return _Card(
      title: l10n.incidentAcousticSignals,
      icon: Icons.graphic_eq,
      child: Column(
        children: [
          _metricRow(l10n.metricSpectralFlux, m.spectralFlux, invertRisk: true, p: p),
          _metricRow(l10n.metricSpectralRolloff, m.spectralRolloffRatio,
              invertRisk: true, p: p),
          _metricRow(l10n.metricZeroCrossing, m.zeroCrossingRate,
              invertRisk: true, p: p),
          _metricRow(l10n.metricAcousticAnomaly, m.syntheticVoiceScore, p: p),
        ],
      ),
    );
  }

  /// [invertRisk] — for flux/rolloff/ZCR, LOW values are the anomaly
  /// (a static spectrum signals synthesis), so the bar inverts.
  Widget _metricRow(String label, double value, {bool invertRisk = false, required AppPalette p}) {
    final riskValue = invertRisk ? 1 - value : value;
    final color = p.forThreat(riskValue);
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
                    p.borderSubtle.withValues(alpha: 0.6),
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
    final p = context.palette;
    final s = incident.semanticSignals;
    return _Card(
      title: l10n.incidentSemanticSignals,
      icon: Icons.psychology_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _scoreBadge(l10n.scoreUrgency, s.urgencyScore, p),
              _scoreBadge(l10n.scoreFinancial, s.financialDemandScore, p),
              _scoreBadge(l10n.scoreSecrecy, s.secrecyScore, p),
            ],
          ),
          if (s.detectedKeywords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in s.detectedKeywords)
                  _keywordChip(k, p.statusWarning, p),
                for (final c in s.impersonationClaims)
                  _keywordChip(c, p.statusDanger, p),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreBadge(String label, double score, AppPalette p) {
    final color = p.forThreat(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label ${(score * 100).round()}/100',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _keywordChip(String text, Color color, AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: p.textPrimary,
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
  final p = context.palette;
    return _Card(
      title: l10n.incidentTranscriptTimeline,
      icon: Icons.forum_outlined,
      child: incident.transcriptSnippets.isEmpty
          ? Text(l10n.incidentNoTranscript,
              style: AppTypography.bodyMedium)
          : Column(
              children: [
                for (final s in incident.transcriptSnippets)
                  _bubble(s, p),
              ],
            ),
    );
  }

  Widget _bubble(TranscriptSnippet s, AppPalette p) {
    final isCaller = s.speaker != l10n.speakerYou;
    return Align(
      alignment: isCaller ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isCaller ? p.bgElevated : p.accentMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCaller
                ? p.borderSubtle
                : p.accent.withValues(alpha: 0.4),
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
                    ? p.statusWarning
                    : p.statusSafe,
              ),
            ),
            const SizedBox(height: 3),
            // Text.rich inherits DefaultTextStyle so transcript spans
            // pick up the ambient font family + fallback list.
            Text.rich(
              textDirection: isRtlText(s.text)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              TextSpan(
                style: AppTypography.bodyLarge.copyWith(fontSize: 13.5),
                children: buildThreatSpans(
                  s.text,
                  incident.flaggedPhrases,
                  baseStyle:
                      AppTypography.bodyLarge.copyWith(fontSize: 13.5),
                  palette: p,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final p = context.palette;
    final isDemo = FamilyAlertLocator.instance.isDemoMode;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onBroadcast,
            icon: const Icon(Icons.broadcast_on_personal, size: 20),
            label: Text(
              isDemo
                  ? l10n.sendDemoFamilyAlert
                  : l10n.incidentBroadcast,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.statusDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (isDemo)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.incidentBroadcastDemoNote,
              style: AppTypography.bodyMedium,
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share, size: 18),
            label: Text(
              l10n.incidentShare,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.textPrimary,
              side: BorderSide(color: p.borderSubtle),
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
