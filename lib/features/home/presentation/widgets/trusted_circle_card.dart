import 'package:flutter/material.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';

/// Trusted Circle — the up-to-5 real people Family Shield alerts
/// target. Contacts persist locally (SharedPreferences); only their
/// opaque `vg_…` Family Shield IDs ever cross the network boundary.
class TrustedCircleCard extends StatelessWidget {
  const TrustedCircleCard({super.key});

  IFamilyContactRepository get _repo => FamilyContactLocator.instance;

  String _shortId(String externalId) => externalId.length > 12
      ? '${externalId.substring(0, 6)}…${externalId.substring(externalId.length - 4)}'
      : externalId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<List<FamilyContact>>(
        // Ensure the persisted store is loaded before first paint.
        valueListenable: _repo.contacts,
        builder: (context, contacts, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.group_outlined,
                      color: p.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.trustedCircleTitle,
                        style: AppTypography.titleMedium),
                  ),
                  Text(
                    '${contacts.length} of ${FamilyContactRules.maxContacts}',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.trustedCircleDesc,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final c in contacts) _contactTile(context, c),
              if (contacts.length < FamilyContactRules.maxContacts)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _editSheet(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: Text(l10n.actionAddPerson),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _contactTile(BuildContext context, FamilyContact c) {
  final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined,
              size: 18, color: p.statusSafe),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: AppTypography.titleMedium),
                Text(
                  _shortId(c.externalId) +
                      (c.trustedPhone == null
                          ? l10n.trustedPhoneNone
                          : l10n.trustedPhoneStored),
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.actionEdit,
            icon: Icon(Icons.edit_outlined,
                size: 18, color: p.textMuted),
            onPressed: () => _editSheet(context, existing: c),
          ),
          IconButton(
            tooltip: l10n.actionRemove,
            icon: Icon(Icons.delete_outline,
                size: 18, color: p.statusWarning),
            onPressed: () => _repo.remove(c.id),
          ),
        ],
      ),
    );
  }

  Future<void> _editSheet(BuildContext context,
      {FamilyContact? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final idCtrl = TextEditingController(text: existing?.externalId);
    final phoneCtrl = TextEditingController(text: existing?.trustedPhone);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing == null ? l10n.trustedAddTitle : l10n.trustedEditTitle,
                style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.trustedFindIdHint,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.trustedNameField),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: idCtrl,
              decoration: InputDecoration(
                labelText: l10n.familyShieldIdLabel,
                hintText: 'vg_…',
              ),
              autocorrect: false,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(
                labelText: l10n.trustedPhoneField,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    try {
      if (existing == null) {
        await _repo.add(
          name: nameCtrl.text,
          externalId: idCtrl.text,
          trustedPhone: phoneCtrl.text,
        );
      } else {
        await _repo.update(
          existing.id,
          name: nameCtrl.text,
          externalId: idCtrl.text,
          trustedPhone: phoneCtrl.text,
          clearPhone: phoneCtrl.text.trim().isEmpty,
        );
      }
    } on FamilyContactException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.serviceMessage(e.message))));
      }
    }
  }
}
