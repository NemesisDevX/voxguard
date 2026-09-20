import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../forensics/presentation/screens/incident_detail_screen.dart';
import '../../../forensics/presentation/screens/incidents_history_screen.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../../paywall/presentation/widgets/family_shield_upsell_sheet.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/presentation/bloc/safecall_state.dart';
import '../../../protection/presentation/screens/safecall_screen.dart';
import '../widgets/action_card.dart';
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

    // A high-risk interception is the strongest upgrade trigger.
    if (ended.peakRiskLevel == ThreatRiskLevel.highRisk) {
      await showFamilyShieldUpsell(context);
    }
    if (!mounted) return;

    // Forensic record was persisted on-call-end — surface it.
    final incident = ended.incident;
    if (incident != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('High-risk threat logged.'),
          action: SnackBarAction(
            label: 'View Incident Report',
            textColor: AppColors.statusWarning,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => IncidentDetailScreen(incident: incident),
              ),
            ),
          ),
        ),
      );
    }
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
          const Text(AppStrings.quickActions, style: AppTypography.labelSmall),
          const SizedBox(height: 12),
          ActionCard(
            icon: Icons.phone_in_talk_outlined,
            title: AppStrings.startSafeCall,
            description: AppStrings.startSafeCallDesc,
            accentColor: AppColors.statusSafe,
            onTap: onSafeCall,
          ),
          const SizedBox(height: 12),
          ActionCard(
            icon: Icons.hearing,
            title: AppStrings.liveShield,
            description: AppStrings.liveShieldDesc,
            accentColor: AppColors.accent,
            onTap: () => onComingSoon(AppStrings.liveShield),
          ),
          const SizedBox(height: 12),
          ActionCard(
            icon: Icons.upload_file_outlined,
            title: AppStrings.analyzeRecording,
            description: AppStrings.analyzeRecordingDesc,
            accentColor: AppColors.statusWarning,
            onTap: () => onComingSoon(AppStrings.analyzeRecording),
          ),
        ],
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
