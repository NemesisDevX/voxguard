import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../forensics/presentation/screens/incidents_history_screen.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../../protection/presentation/bloc/safecall_state.dart';
import '../../../protection/presentation/screens/safecall_screen.dart';
import '../../../protection/presentation/widgets/post_call_safety_sheet.dart';
import '../widgets/protection_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  Future<void> _openSafeCall() async {
    final ended = await Navigator.of(context).push<SafeCallEnded>(
      MaterialPageRoute<SafeCallEnded>(
        builder: (_) => const SafeCallScreen(),
      ),
    );
    if (ended == null || !mounted) return;

    // Post-call safety flow: why flagged → verify identity → optional
    // demo family alert → incident summary → natural upgrade moment.
    await PostCallSafetySheet.show(context, ended);
  }

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
          const _PlaceholderTab(
            icon: Icons.settings_outlined,
            title: AppStrings.settingsPlaceholder,
            description: AppStrings.settingsPlaceholderDesc,
          ),
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
            onTap: () => onComingSoon(AppStrings.analyzeRecording),
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.borderSubtle),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
