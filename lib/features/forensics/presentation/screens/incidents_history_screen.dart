import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/services/incident_repository.dart';
import 'incident_detail_screen.dart';

/// "Incidents" tab — a calm safety log, not a forensic console.
/// Each card leads with when it happened and the one-line reason;
/// technical IDs stay visible but quiet.
class IncidentsHistoryScreen extends StatelessWidget {
  const IncidentsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<List<IncidentReport>>(
        valueListenable: IncidentRepositoryLocator.instance.incidents,
        builder: (context, incidents, _) {
          if (incidents.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: incidents.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _IncidentCard(incident: incidents[i]),
          );
        },
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final IncidentReport incident;

  /// Partial (acoustic-only) records never wear a full-call verdict.
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
          ThreatRiskLevel.highRisk => 'HIGH RISK',
          ThreatRiskLevel.suspicious => 'SUSPICIOUS',
          ThreatRiskLevel.safe => 'SAFE',
        };

  /// "Urgent Money Request + Voice Impersonation" style summary.
  /// Partial records describe the acoustic signal only.
  String get _summary {
    if (incident.analysisIsPartial) {
      final score =
          (incident.acousticMetrics.syntheticVoiceScore * 100).round();
      return 'Acoustic anomaly $score/100 — '
          'conversation-risk not analyzed';
    }
    final reasons = incident.threatReasons
        .where((r) => r != 'No significant threat indicators')
        .take(2)
        .map((r) => r.replaceAll(' detected', '').replaceAll(' claim: "', ' — "').replaceAll(' tactics', ''))
        .join(' + ');
    return reasons.isEmpty ? 'No significant threats' : reasons;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IncidentDetailScreen(incident: incident),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // One-line reason first — the human summary leads,
                  // the incident id stays quiet underneath.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _summary,
                          style: AppTypography.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${incident.timestampLabel}  ·  ${incident.durationLabel}',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _riskColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: _riskColor.withValues(alpha: 0.55)),
                    ),
                    child: Text(
                      _riskLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _riskColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.graphic_eq,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${incident.audioSourceLabel} · ',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    incident.id,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.borderSubtle),
            SizedBox(height: 16),
            Text('No incidents recorded', style: AppTypography.titleMedium),
            SizedBox(height: 8),
            Text(
              'Flagged sessions and analyzed recordings will appear '
              'here as a safety log.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
