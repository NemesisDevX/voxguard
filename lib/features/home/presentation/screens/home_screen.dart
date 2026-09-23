import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/preferences/app_preferences.dart';
import '../../../../core/services/push/onesignal_push_identity_service.dart';
import '../../../../core/services/push/push_identity_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/chrome.dart';
import '../../../../core/widgets/signal_mark.dart';
import '../../../../core/widgets/surfaces.dart';
import '../../../forensics/presentation/screens/incidents_history_screen.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../../protection/presentation/safecall_launcher.dart';
import '../../../recording/presentation/screens/analyze_recording_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/protection_banner.dart';

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
    final l10n = context.l10n;
    final p = context.palette;
    return Scaffold(
      // Floating chrome — content passes under the frosted bar and
      // nav pill; each tab clears it through the injected SafeArea.
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: GlassAppBar(
        title: Row(
          children: [
            SignalMark(size: 24, color: p.accent,
                secondaryColor: p.signalAcoustic),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.upgradeTooltip,
            icon: Icon(
              Icons.workspace_premium_outlined,
              color: p.statusWarning,
            ),
            onPressed: () => PaywallScreen.show(context),
          ),
          IconButton(
            tooltip: l10n.incidentLogTooltip,
            icon: Icon(Icons.history, color: p.textMuted),
            onPressed: () => setState(() => _tabIndex = 1),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          IndexedStack(
            index: _tabIndex,
            children: [
              _ShieldTab(
                onSafeCall: _openSafeCall,
                onOpenFamily: () => setState(() => _tabIndex = 2),
              ),
              const IncidentsHistoryScreen(),
              const SettingsScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: [
          GlassNavItem(icon: Icons.graphic_eq, label: l10n.navShield),
          GlassNavItem(
              icon: Icons.receipt_long_outlined,
              label: l10n.navIncidents),
          GlassNavItem(
              icon: Icons.settings_outlined, label: l10n.navSettings),
        ],
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
    final l10n = context.l10n;
    final prefs = AppPreferencesLocator.instance;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, c) => ListenableBuilder(
          listenable: prefs,
          builder: (context, _) {
            // Read inside the builder — a Settings name change rebuilds
            // this subtree and must see the new value, not a stale one.
            final name = prefs.displayName;
            return SingleChildScrollView(
              // SafeArea already carries the chrome insets the Scaffold
              // injects (frosted bar top, floating nav bottom) — the
              // list only adds breathing room.
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: c.maxHeight - 26),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProtectionBanner(),
                      // Optional local name — a quiet greeting, not a
                      // social profile. Absent by default; never
                      // rendered as an empty placeholder.
                      if (name != null && name.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          l10n.homeGreetingNamed(name),
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                      // The hero cluster centers in the free space;
                      // the status card anchors at the bottom.
                      const Spacer(flex: 2),
                      const SizedBox(height: 28),

                      // Hero — the primary experience. One statement,
                      // one action.
                      _HeroProtectionCard(onTap: onSafeCall),

                      const SizedBox(height: 14),

                      // Secondary product path — a real, shipped
                      // feature.
                      _ActionTile(
                        icon: Icons.audio_file_outlined,
                        title: l10n.analyzeRecording,
                        description: l10n.analyzeRecordingDesc,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const AnalyzeRecordingScreen(),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),
                      const SizedBox(height: 20),

                      // Calm Family Shield readiness — a status
                      // surface, never an emergency banner when
                      // nothing is happening.
                      _FamilyShieldStatusCard(onTap: onOpenFamily),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The hero — the product's centerpiece. A lifted glass panel with
/// the SignalMark suspended in a soft accent glow, one statement,
/// one dominant action.
class _HeroProtectionCard extends StatelessWidget {
  const _HeroProtectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final guided = AppPreferencesLocator.instance.isGuided;
    return Pressable(
      haptic: true,
      scale: 0.985,
      child: SurfaceCard(
        elevated: true,
        radius: 26,
        tint: p.accent,
        tintAlpha: 0.05,
        onTap: onTap,
        padding: EdgeInsets.fromLTRB(22, guided ? 30 : 26, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The mark floats in its own light — a radial glow halo
            // behind it gives the hero real depth without animation.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.accent.withValues(alpha: 0.22),
                    p.accent.withValues(alpha: 0.0),
                  ],
                ),
                border: Border.all(
                  color: p.accent.withValues(alpha: 0.28),
                ),
              ),
              child: Center(
                child: SignalMark(
                    size: 34,
                    color: p.accent,
                    secondaryColor: p.signalAcoustic),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.protectionCheckTitle,
              style: AppTypography.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.protectionCheckDesc,
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: guided ? 24 : 20),
            SizedBox(
              width: double.infinity,
              // Guided Mode: a taller, more confident primary CTA.
              height: guided ? 56 : 48,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.graphic_eq, size: 18),
                label: Text(
                  l10n.protectionCheckCta,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: guided ? 16 : null,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
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
    final p = context.palette;
    return Pressable(
      child: SurfaceCard(
        radius: 16,
        onTap: onTap,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: p.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style:
                        AppTypography.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textMuted, size: 18),
          ],
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
    final l10n = context.l10n;
    final p = context.palette;
    return Pressable(
      child: SurfaceCard(
        radius: 16,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
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
                      ? (l10n.familyNeedsSetup, p.statusWarning)
                      : (
                          alertsOn
                              ? '${l10n.familyReadyWithCircle} · '
                                  '${l10n.familyAlertsEnabled}'
                              : l10n.familyReadyWithCircle,
                          alertsOn ? p.statusSafe : p.textMuted,
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group_outlined,
                              color: p.accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l10n.familyShieldTitle,
                                style: AppTypography.titleMedium),
                          ),
                          Icon(Icons.chevron_right,
                              color: p.textMuted, size: 18),
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
                      Text(
                        l10n.familyStatusHint,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
    );
  }
}
