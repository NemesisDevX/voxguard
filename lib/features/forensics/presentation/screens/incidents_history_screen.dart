import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/services/incident_repository.dart';
import 'incident_detail_screen.dart';

/// "Incidents" tab — forensic history of intercepted calls.
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

  Color get _riskColor => switch (incident.riskLevel) {
        ThreatRiskLevel.highRisk => AppColors.statusDanger,
        ThreatRiskLevel.suspicious => AppColors.statusWarning,
        ThreatRiskLevel.safe => AppColors.statusSafe,
      };

  String get _riskLabel => switch (incident.riskLevel) {
        ThreatRiskLevel.highRisk => 'HIGH RISK',
        ThreatRiskLevel.suspicious => 'SUSPICIOUS',
        ThreatRiskLevel.safe => 'SAFE',
      };

  /// "Urgent Money Request + Voice Impersonation" style summary.
  String get _summary {
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
                children: [
                  Expanded(
                    child: Text(
                      incident.id,
                      style: AppTypography.titleMedium,
                    ),
                  ),
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
              const SizedBox(height: 6),
              Text(
                '${incident.timestampLabel}  ·  ${incident.durationLabel}  ·  ${incident.callerLabel}',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: _riskColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _summary,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              'Blocked threats and flagged calls will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
