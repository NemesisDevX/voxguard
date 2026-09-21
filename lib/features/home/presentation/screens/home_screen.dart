import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppColors.statusSafe, size: 26),
            SizedBox(width: 10),
            Text(AppStrings.appName),
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
          _ShieldTab(onSafeCall: _openSafeCall, onComingSoon: _showComingSoon),
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
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
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
  const _ShieldTab({required this.onSafeCall, required this.onComingSoon});

  final VoidCallback onSafeCall;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const ProtectionBanner(),
          const SizedBox(height: 28),

          // Hero — SafeCall is the product's primary experience.
          _HeroSafeCallCard(onTap: onSafeCall),

          const SizedBox(height: 32),

          // Secondary, unfinished capabilities live in Labs — visually
          // demoted so they never compete with the hero path.
          Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.labsTitle,
                  style: AppTypography.labelSmall,
                ),
              ),
              Text(
                'EXPERIMENTAL',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 9,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LabTile(
            icon: Icons.hearing,
            title: AppStrings.liveShield,
            description: AppStrings.liveShieldDesc,
            onTap: () => onComingSoon(AppStrings.liveShield),
          ),
          const SizedBox(height: 8),
          _LabTile(
            icon: Icons.upload_file_outlined,
            title: AppStrings.analyzeRecording,
            description: AppStrings.analyzeRecordingDesc,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AnalyzeRecordingScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The primary hero card — large, calm, unmistakably the main action.
class _HeroSafeCallCard extends StatelessWidget {
  const _HeroSafeCallCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.statusSafe.withValues(alpha: 0.35),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.statusSafe.withValues(alpha: 0.10),
                AppColors.bgElevated,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.statusSafe.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_outlined,
                        color: AppColors.statusSafe,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.startSafeCall,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.startSafeCallDesc,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact secondary tile for Labs features.
class _LabTile extends StatelessWidget {
  const _LabTile({
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
                    child: Text('How VoxGuard Works',
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
                Row(
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
                      const SizedBox(width: 16),
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
                      const SizedBox(width: 16),
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
