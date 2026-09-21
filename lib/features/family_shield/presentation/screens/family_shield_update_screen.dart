import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/family/family_shield_response.dart';
import '../../../../core/services/family/received_family_alert_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
    final isSafe = response.resolution == AlertResolution.safe;
    final color =
        isSafe ? AppColors.statusSafe : AppColors.statusWarning;
    // An opaque vg_… id is not proof of trust — never label an
    // unrecognized identity as a "trusted person".
    final who = responderName ?? AppStrings.unrecognizedIdentity;
    return Scaffold(
      appBar: AppBar(title: const Text('Family Shield Update')),
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
                    ? '$who marked this situation safe'
                    : '$who is still concerned',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'This is a human verification update — it does not '
                'change the AI risk assessment.\n\n'
                'Incident ${response.incidentId}'
                '${response.receivedAt != null ? '\nReceived ${_fmt(response.receivedAt!)}' : ''}',
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
