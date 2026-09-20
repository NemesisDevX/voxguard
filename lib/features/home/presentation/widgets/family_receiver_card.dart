import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/push/onesignal_push_identity_service.dart';
import '../../../../core/services/push/push_identity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Family Shield receiver setup — lets this device become reachable by
/// another VoxGuard installation's alerts via its opaque `vg_…`
/// identity. Hackathon-grade UX; the full Trusted Circle flow is a
/// later phase.
class FamilyReceiverCard extends StatefulWidget {
  const FamilyReceiverCard({super.key});

  @override
  State<FamilyReceiverCard> createState() => _FamilyReceiverCardState();
}

class _FamilyReceiverCardState extends State<FamilyReceiverCard> {
  final _testRecipientCtrl = TextEditingController();

  IPushIdentityService get _push => PushIdentityLocator.instance;

  @override
  void dispose() {
    _testRecipientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FamilyPushRegistration>(
      valueListenable: _push.registration,
      builder: (context, reg, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.family_restroom,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Family Shield Receiver',
                      style: AppTypography.titleMedium),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Get an alert when someone in your trusted circle '
                'encounters a high-risk call.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 14),
              _statusRow(reg),
              if (reg.voxguardExternalId != null) ...[
                const SizedBox(height: 10),
                _idRow(reg.voxguardExternalId!),
              ],
              const SizedBox(height: 14),
              Text(
                'Share this ID only with someone you want to receive '
                'Family Shield alerts from.',
                style: AppTypography.labelSmall,
              ),
              if (reg.status ==
                      PushRegistrationStatus.permissionRequired ||
                  reg.status ==
                      PushRegistrationStatus.permissionDenied) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _push.enableAlerts,
                    icon: const Icon(Icons.notifications_active_outlined,
                        size: 18),
                    label: const Text('Enable Family Alerts'),
                  ),
                ),
                if (reg.status == PushRegistrationStatus.permissionDenied)
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text('Open system settings'),
                  ),
              ],
              if (reg.status == PushRegistrationStatus.notConfigured)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Push setup unavailable — ONESIGNAL_APP_ID not '
                    'configured in this build.',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.statusWarning),
                  ),
                ),
              if (kDebugMode) ...[
                const Divider(height: 28, color: AppColors.borderSubtle),
                Text('DEV · Test alert recipient',
                    style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _testRecipientCtrl,
                        style: AppTypography.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'vg_… external id of test device',
                          isDense: true,
                        ),
                        onSubmitted: (v) => DemoFamilyContactRepository
                            .setTestRecipientOverride(v),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Set test recipient',
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () => DemoFamilyContactRepository
                          .setTestRecipientOverride(
                              _testRecipientCtrl.text),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusRow(FamilyPushRegistration reg) {
    final (label, color) = switch (reg.status) {
      PushRegistrationStatus.registered => (
          'Ready to receive alerts',
          AppColors.statusSafe
        ),
      PushRegistrationStatus.registering => (
          'Registering…',
          AppColors.statusWarning
        ),
      PushRegistrationStatus.permissionRequired => (
          'Notification permission needed',
          AppColors.statusWarning
        ),
      PushRegistrationStatus.permissionDenied => (
          'Notifications blocked — enable in system settings',
          AppColors.statusDanger
        ),
      PushRegistrationStatus.notConfigured => (
          'Push not configured',
          AppColors.textMuted
        ),
      PushRegistrationStatus.unsupported => (
          'Not supported on this platform',
          AppColors.textMuted
        ),
      PushRegistrationStatus.error => (
          'Registration error${reg.errorDetail != null ? ': ${reg.errorDetail}' : ''}',
          AppColors.statusDanger
        ),
    };
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: AppTypography.bodyMedium.copyWith(color: color)),
        ),
      ],
    );
  }

  Widget _idRow(String id) {
    final shown =
        id.length > 14 ? '${id.substring(0, 10)}…${id.substring(id.length - 4)}' : id;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Family Shield ID', style: AppTypography.labelSmall),
              const SizedBox(height: 2),
              Text(shown,
                  style: AppTypography.bodyMedium
                      .copyWith(fontFamily: 'monospace')),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy Family Shield ID',
          icon: const Icon(Icons.copy_outlined,
              size: 18, color: AppColors.textMuted),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: id));
            messenger.showSnackBar(
              const SnackBar(content: Text('Family Shield ID copied')),
            );
          },
        ),
      ],
    );
  }
}
