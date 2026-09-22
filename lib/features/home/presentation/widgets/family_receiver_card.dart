import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/push/onesignal_push_identity_service.dart';
import '../../../../core/services/push/push_identity_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';

/// Family Shield receiver setup — lets this device become reachable by
/// another VoxGuard installation's alerts via its opaque `vg_…`
/// identity. Outgoing contacts live in the [TrustedCircleCard].
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
    final p = context.palette;
    return ValueListenableBuilder<FamilyPushRegistration>(
      valueListenable: _push.registration,
      builder: (context, reg, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.family_restroom,
                      color: p.accent, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(l10n.familyReceiverTitle,
                        style: AppTypography.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.familyReceiverDesc,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 14),
              _statusRow(reg, p),
              if (reg.voxguardExternalId != null) ...[
                const SizedBox(height: 10),
                _idRow(reg.voxguardExternalId!, p),
              ],
              const SizedBox(height: 14),
              Text(
                l10n.familyReceiverShareNote,
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
                    label: Text(l10n.familyReceiverEnable),
                  ),
                ),
                if (reg.status == PushRegistrationStatus.permissionDenied)
                  TextButton(
                    onPressed: openAppSettings,
                    child: Text(l10n.familyReceiverOpenSettings),
                  ),
              ],
              if (reg.status == PushRegistrationStatus.notConfigured)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.familyReceiverNotConfigured,
                    style: AppTypography.labelSmall
                        .copyWith(color: p.statusWarning),
                  ),
                ),
              if (kDebugMode) ...[
                Divider(height: 28, color: p.borderSubtle),
                Text(l10n.familyReceiverDevRecipient,
                    style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _testRecipientCtrl,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: l10n.familyReceiverTestDeviceHint,
                          isDense: true,
                        ),
                        onSubmitted: (v) =>
                            PersistedFamilyContactRepository
                                .setTestRecipientOverride(v),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.familyReceiverSetTest,
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () =>
                          PersistedFamilyContactRepository
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

  Widget _statusRow(FamilyPushRegistration reg, AppPalette p) {
    final (label, color) = switch (reg.status) {
      PushRegistrationStatus.registered => (
          l10n.familyReceiverReady,
          p.statusSafe
        ),
      PushRegistrationStatus.registering => (
          l10n.familyStateRegistering,
          p.statusWarning
        ),
      PushRegistrationStatus.permissionRequired => (
          l10n.familyStateNeedPermission,
          p.statusWarning
        ),
      PushRegistrationStatus.permissionDenied => (
          l10n.familyStateBlocked,
          p.statusDanger
        ),
      PushRegistrationStatus.notConfigured => (
          l10n.familyStateNotConfigured,
          p.textMuted
        ),
      PushRegistrationStatus.unsupported => (
          l10n.familyStateUnsupported,
          p.textMuted
        ),
      PushRegistrationStatus.error => (
          context.serviceMessage(reg.errorDetail ?? ''),
          p.statusDanger
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

  Widget _idRow(String id, AppPalette p) {
    final shown =
        id.length > 14 ? '${id.substring(0, 10)}…${id.substring(id.length - 4)}' : id;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.familyShieldIdLabel, style: AppTypography.labelSmall),
              const SizedBox(height: 2),
              Text(shown,
                  style: AppTypography.bodyMedium
                      .copyWith(fontFamily: 'monospace')),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.familyShieldIdCopyTooltip,
          icon: Icon(Icons.copy_outlined,
              size: 18, color: p.textMuted),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: id));
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.familyShieldIdCopied)),
            );
          },
        ),
      ],
    );
  }
}
