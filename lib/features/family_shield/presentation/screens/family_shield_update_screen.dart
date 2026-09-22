import 'package:flutter/material.dart';

import '../../../../core/services/family/family_shield_response.dart';
import '../../../../core/services/family/received_family_alert_repository.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';

/// Fallback shown when a `family_shield_response` notification is
/// tapped but no matching local incident exists — the remote
/// `incident_id` is a reference, not proof of a local record.
class FamilyShieldUpdateScreen extends StatelessWidget {
  const FamilyShieldUpdateScreen({
    super.key,
    required this.response,
    this.responderName,
  });

  final FamilyShieldResponse response;

  /// Resolved from the local Trusted Circle — null for unrecognized
  /// identities.
  final String? responderName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isSafe = response.resolution == AlertResolution.safe;
    final color =
        isSafe ? p.statusSafe : p.statusWarning;
    // An opaque vg_… id is not proof of trust — never label an
    // unrecognized identity as a "trusted person".
    final who = responderName ?? l10n.unrecognizedIdentity;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyUpdateTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSafe
                    ? Icons.verified_user_outlined
                    : Icons.warning_amber_outlined,
                color: color,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                isSafe
                    ? l10n.familyUpdateMarkedSafe(who)
                    : l10n.familyUpdateConcerned(who),
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '${l10n.familyUpdateHumanNote}\n\n'
                '${l10n.familyUpdateIncidentId(response.incidentId)}'
                '${response.receivedAt != null ? '\n${l10n.familyUpdateReceivedAt(_fmt(response.receivedAt!))}' : ''}',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}
