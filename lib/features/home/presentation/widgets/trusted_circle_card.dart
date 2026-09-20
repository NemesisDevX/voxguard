import 'package:flutter/material.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
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
                  const Icon(Icons.group_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Trusted Circle',
                        style: AppTypography.titleMedium),
                  ),
                  Text(
                    '${contacts.length} of ${FamilyContactRules.maxContacts}',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Family Shield alerts go only to these people. '
                'Family Shield IDs route private safety alerts. '
                'Phone numbers stay on this device and are never '
                'included in alert payloads.',
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
                    label: const Text('Add person'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _contactTile(BuildContext context, FamilyContact c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: AppColors.statusSafe),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: AppTypography.titleMedium),
                Text(
                  _shortId(c.externalId) +
                      (c.trustedPhone == null
                          ? ' · no phone'
                          : ' · phone stored'),
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textMuted),
            onPressed: () => _editSheet(context, existing: c),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.statusWarning),
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
            Text(existing == null ? 'Add trusted person' : 'Edit person',
                style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'They can find their Family Shield ID in their own app '
              'under Settings → Family Shield Receiver.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                labelText: 'Family Shield ID',
                hintText: 'vg_…',
              ),
              autocorrect: false,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Trusted phone number (optional)',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save'),
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
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
