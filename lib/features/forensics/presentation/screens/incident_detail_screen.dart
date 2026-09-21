import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/alerts/family_shield_alert_service.dart';
import '../../../../core/services/family/family_shield_response.dart';
import '../../../../core/services/family/received_family_alert_repository.dart';
import '../../../../core/theme/app_colors.dart';
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

/// Forensic viewer for a single flagged incident — consumer-first
/// evidence hierarchy with technical telemetry collapsed by default.
class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incident});

  final IncidentReport incident;

  /// A partial record is an acoustic warning, not a call verdict —
  /// it renders in warning color with its own label.
  Color get _riskColor => incident.analysisIsPartial
      ? AppColors.statusWarning
      : switch (incident.riskLevel) {
          ThreatRiskLevel.highRisk => AppColors.statusDanger,
          ThreatRiskLevel.suspicious => AppColors.statusWarning,
          ThreatRiskLevel.safe => AppColors.statusSafe,
        };

  String get _riskLabel => incident.analysisIsPartial
      ? 'PARTIAL ANALYSIS'
      : switch (incident.riskLevel) {
          ThreatRiskLevel.highRisk => 'CRITICAL / HIGH RISK',
          ThreatRiskLevel.suspicious => 'SUSPICIOUS',
          ThreatRiskLevel.safe => 'SAFE',
        };

  Future<void> _broadcast(BuildContext context) async {
    final demo = FamilyAlertLocator.instance.isDemoMode;
    // Real outbound alerts are a Family Vault capability — the
    // service enforces the same gate, this is the UI boundary.
    if (!demo &&
        !ProductAccessLocator
            .instance.capabilities.familyShieldOutbound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.familyVaultUnlocksAlerts),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this incident?'),
        content: Text(
          '${incident.id} will be permanently removed from this device. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.statusDanger,
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
          const SnackBar(
            content: Text(
              "Couldn't delete this incident. Please try again.",
            ),
          ),
        );
      }
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(incident.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete incident',
            color: AppColors.statusDanger,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _HeaderCard(incident: incident, color: _riskColor, label: _riskLabel),
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
            title: 'FAMILY SHIELD RESPONSES',
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
    final isSafe = response.resolution == AlertResolution.safe;
    return FutureBuilder<String>(
      future: _responderName(),
      builder: (context, snap) {
        final name = snap.data ?? AppStrings.unrecognizedIdentity;
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
                    ? AppColors.statusSafe
                    : AppColors.statusWarning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSafe
                      ? '$name marked this situation safe'
                      : '$name is still concerned',
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
    return AppStrings.unrecognizedIdentity;
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
          if (incident.analysisIsPartial) ...[
            Row(
              children: [
                Text(
                  'Acoustic anomaly ',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.textMuted),
                ),
                Text(
                  '${(incident.acousticMetrics.syntheticVoiceScore * 100).round()}/100',
                  style: AppTypography.statLarge.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Conversation-risk signals were not analyzed.',
              style: AppTypography.bodyMedium,
            ),
          ] else
            Row(
              children: [
                Text(
                  '${AppStrings.threatScoreLabel} ',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.textMuted),
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
          ? 'WHY VOXGUARD FOUND ELEVATED ACOUSTIC SIGNALS'
          : 'WHY VOXGUARD FLAGGED THIS RECORDING';
    }
    return 'WHY VOXGUARD FLAGGED THIS CALL';
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.flag_outlined,
                      size: 14, color: AppColors.statusDanger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r, style: AppTypography.bodyLarge)),
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
                  _evidenceChip(e),
              ],
            ),
          ],
          if (incident.recommendedActions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 12),
            Text(
              'RECOMMENDED NEXT STEPS',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            for (final a in incident.recommendedActions.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.statusSafe),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.verifyIdentityBody,
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

  Widget _evidenceChip(EvidenceCategory e) {
    final color = switch (e) {
      EvidenceCategory.impersonation ||
      EvidenceCategory.moneyRequest =>
        AppColors.statusDanger,
      _ => AppColors.statusWarning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        e.label,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
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
                  const Icon(Icons.biotech_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'TECHNICAL EVIDENCE',
                      style: AppTypography.labelSmall,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
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
    return _Card(
      title: 'AUDIO SHA-256',
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
              const Icon(Icons.graphic_eq,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${incident.audioSourceLabel} · '
                  '${incident.transcriptionSourceLabel}',
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
    final m = incident.acousticMetrics;
    return _Card(
      title: 'ACOUSTIC ANOMALY SIGNALS',
      icon: Icons.graphic_eq,
      child: Column(
        children: [
          _metricRow('Spectral Flux', m.spectralFlux, invertRisk: true),
          _metricRow('Spectral Rolloff', m.spectralRolloffRatio,
              invertRisk: true),
          _metricRow('Zero-Crossing Rate', m.zeroCrossingRate,
              invertRisk: true),
          _metricRow('Acoustic Anomaly Score', m.syntheticVoiceScore),
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
      title: 'SEMANTIC THREAT SIGNALS',
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
        '$label ${(score * 100).round()}/100',
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
                  ? AppStrings.sendDemoFamilyAlert
                  : 'Broadcast to Family Shield',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
        if (isDemo)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Demo Mode — no real notification is sent',
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
