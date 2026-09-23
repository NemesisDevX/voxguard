import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../paywall/domain/models/entitlement_state.dart';
import '../../../paywall/domain/models/subscription_tier.dart';
import '../../../paywall/domain/services/i_purchase_service.dart';
import '../../../paywall/domain/services/purchase_service_locator.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../../../core/widgets/surfaces.dart';

/// Subscription section — current plan truth plus store actions.
/// Reactive to entitlement changes: a purchase/restore/expiration
/// updates this card without a restart. Never shows internal
/// entitlement ids; demo backend is labelled "Demo Store".
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key});

  static String _tierLabel(AppLocalizations l10n, TierId? id) =>
      switch (id) {
        TierId.sentinel => l10n.tierSentinel,
        TierId.familyVault => l10n.tierFamily,
        _ => l10n.tierQuickCheck,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final service = PurchaseServiceLocator.instance;
    return ValueListenableBuilder<EntitlementState>(
      valueListenable: service.entitlement,
      builder: (context, entitlement, _) {
        final isDemo = entitlement.isDemo;
        final isTestStore =
            entitlement.backend == PurchaseBackendMode.testStore;
        final isUnavailable =
            entitlement.backend == PurchaseBackendMode.unavailable;
        return SurfaceCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined,
                        color: p.statusWarning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.subscriptionSection,
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    if (isDemo || isTestStore)
                      StatusPill(
                        color: isDemo ? p.statusWarning : p.accent,
                        label: isDemo
                            ? l10n.demoStoreSection
                            : l10n.testStoreSection,
                        icon: isDemo
                            ? Icons.science_outlined
                            : Icons.verified_outlined,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isUnavailable
                      ? l10n.storeUnavailableNotice
                      : l10n.currentPlan(_tierLabel(
                              l10n, entitlement.tier)) +
                          (isDemo && entitlement.tier != TierId.free
                              ? l10n.currentPlanDemo
                              : isTestStore &&
                                      entitlement.tier != TierId.free
                                  ? l10n.currentPlanTestStore
                                  : ''),
                  style:
                      AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => PaywallScreen.show(context),
                      style: TextButton.styleFrom(
                        foregroundColor: p.accent,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.viewPlans,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (!isUnavailable) ...[
                      TextButton(
                        onPressed: () => _restore(context, service),
                        style: TextButton.styleFrom(
                          foregroundColor: p.textMuted,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.restore,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    if (entitlement.managementUrl != null) ...[
                      TextButton(
                        onPressed: () => launchUrl(
                          entitlement.managementUrl!,
                          mode: LaunchMode.externalApplication,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: p.textMuted,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.manageSubscription,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _restore(
      BuildContext context, IPurchaseService service) async {
    final l10n = context.l10n;
    try {
      final restored = await service.restorePurchases();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restored == null
                ? l10n.noPurchasesRestored
                : l10n.purchasesRestored,
          ),
        ),
      );
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.purchasesRestoreFailed)),
      );
    }
  }
}
