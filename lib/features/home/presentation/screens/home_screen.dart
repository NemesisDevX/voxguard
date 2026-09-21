import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/push/onesignal_push_identity_service.dart';
import '../../../../core/services/push/push_identity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/signal_mark.dart';
import '../../../forensics/presentation/screens/incidents_history_screen.dart';
import '../../../paywall/domain/models/entitlement_state.dart';
import '../../../paywall/domain/models/subscription_tier.dart';
import '../../../paywall/domain/services/i_purchase_service.dart';
import '../../../paywall/domain/services/purchase_service_locator.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../protection/presentation/safecall_launcher.dart';
import '../../../recording/presentation/screens/analyze_recording_screen.dart';
import '../widgets/family_receiver_card.dart';
import '../widgets/protection_banner.dart';
import '../widgets/trusted_circle_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  Future<void> _openSafeCall() => launchSafeCall(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            SignalMark(size: 24),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.upgradeTooltip,
            icon: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.statusWarning,
            ),
            onPressed: () => PaywallScreen.show(context),
          ),
          IconButton(
            tooltip: AppStrings.incidentLogTooltip,
            icon: const Icon(Icons.history, color: AppColors.textMuted),
            onPressed: () => setState(() => _tabIndex = 1),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _ShieldTab(
            onSafeCall: _openSafeCall,
            onOpenFamily: () => setState(() => _tabIndex = 2),
          ),
          const IncidentsHistoryScreen(),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.graphic_eq),
              label: AppStrings.navShield,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              label: AppStrings.navIncidents,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: AppStrings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShieldTab extends StatelessWidget {
  const _ShieldTab({required this.onSafeCall, required this.onOpenFamily});

  final VoidCallback onSafeCall;
  final VoidCallback onOpenFamily;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const ProtectionBanner(),
          const SizedBox(height: 28),

          // Hero — the primary experience. One statement, one action.
          _HeroProtectionCard(onTap: onSafeCall),

          const SizedBox(height: 14),

          // Secondary product path — a real, shipped feature.
          _ActionTile(
            icon: Icons.audio_file_outlined,
            title: AppStrings.analyzeRecording,
            description: AppStrings.analyzeRecordingDesc,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AnalyzeRecordingScreen(),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Calm Family Shield readiness — a status surface, never
          // an emergency banner when nothing is happening.
          _FamilyShieldStatusCard(onTap: onOpenFamily),
        ],
      ),
    );
  }
}

/// The hero — large, calm, unmistakably the main action.
class _HeroProtectionCard extends StatelessWidget {
  const _HeroProtectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SignalMark(size: 40),
                    Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  AppStrings.protectionCheckTitle,
                  style: AppTypography.displaySmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.protectionCheckDesc,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.graphic_eq, size: 18),
                    label: const Text(
                      AppStrings.protectionCheckCta,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact secondary tile for real product paths beside the hero.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTypography.bodyMedium
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Family Shield readiness — reports the real local state: trusted
/// people saved, alert registration status. A status surface, not
/// an emergency banner; tapping it opens the Settings tab where the
/// circle is managed.
class _FamilyShieldStatusCard extends StatelessWidget {
  const _FamilyShieldStatusCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: ValueListenableBuilder<List<FamilyContact>>(
            valueListenable: FamilyContactLocator.instance.contacts,
            builder: (context, contacts, _) {
              return ValueListenableBuilder<FamilyPushRegistration>(
                valueListenable:
                    PushIdentityLocator.instance.registration,
                builder: (context, reg, _) {
                  final ready = contacts.isNotEmpty;
                  final alertsOn = reg.status ==
                      PushRegistrationStatus.registered;
                  final (status, color) = !ready
                      ? (
                          AppStrings.familyNeedsSetup,
                          AppColors.statusWarning
                        )
                      : (
                          alertsOn
                              ? '${AppStrings.familyReadyWithCircle} · '
                                  '${AppStrings.familyAlertsEnabled}'
                              : AppStrings.familyReadyWithCircle,
                          alertsOn
                              ? AppColors.statusSafe
                              : AppColors.textMuted,
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group_outlined,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(AppStrings.familyShieldTitle,
                                style: AppTypography.titleMedium),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textMuted, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        AppStrings.familyStatusHint,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Compact settings surface — hosts the Family Shield receiver card.
/// Push permission is only ever requested from the card's explicit
/// "Enable Family Alerts" button, never at app launch.
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SubscriptionCard(),
        const SizedBox(height: 16),
        const FamilyReceiverCard(),
        const SizedBox(height: 16),
        const TrustedCircleCard(),
        const SizedBox(height: 16),
        // Re-open the onboarding/privacy walkthrough — review mode
        // never touches completion state.
        Material(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const OnboardingScreen(reviewMode: true),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.help_outline,
                      color: AppColors.textMuted, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(AppStrings.howItWorksTitle,
                        style: AppTypography.titleMedium),
                  ),
                  Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Subscription section — current plan truth plus store actions.
/// Reactive to entitlement changes: a purchase/restore/expiration
/// updates this card without a restart. Never shows internal
/// entitlement ids; demo backend is labelled "Demo Store".
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context) {
    final service = PurchaseServiceLocator.instance;
    return ValueListenableBuilder<EntitlementState>(
      valueListenable: service.entitlement,
      builder: (context, entitlement, _) {
        final tier = SubscriptionTiers.byId(entitlement.tier);
        final isDemo = entitlement.isDemo;
        final isUnavailable =
            entitlement.backend == PurchaseBackendMode.unavailable;
        return Material(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined,
                        color: AppColors.statusWarning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Subscription',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    if (isDemo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'DEMO STORE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.statusWarning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isUnavailable
                      ? AppStrings.storeUnavailableNotice
                      : 'Current plan: ${tier?.name ?? 'Quick Check'}'
                          '${isDemo && entitlement.tier != TierId.free ? ' (demo)' : ''}',
                  style: AppTypography.bodyMedium
                      .copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => PaywallScreen.show(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View plans',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (!isUnavailable) ...[
                      TextButton(
                        onPressed: () => _restore(context, service),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          AppStrings.restore,
                          style: TextStyle(fontSize: 12),
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
                          foregroundColor: AppColors.textMuted,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Manage subscription',
                          style: TextStyle(fontSize: 12),
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
    try {
      final restored = await service.restorePurchases();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restored == null
                ? AppStrings.noPurchasesRestored
                : 'Purchases restored.',
          ),
        ),
      );
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Purchases could not be restored right now.'),
        ),
      );
    }
  }
}
