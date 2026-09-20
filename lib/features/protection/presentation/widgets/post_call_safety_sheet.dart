import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/alerts/family_shield_alert_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../forensics/domain/models/incident_report.dart';
import '../../../forensics/presentation/screens/incident_detail_screen.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/semantic_threat_signals.dart';
import '../bloc/safecall_state.dart';

/// Post-call safety flow shown when a protection session ends.
///
/// For high-risk sessions this walks the user through:
///   HIGH RISK → WHY FLAGGED → VERIFY IDENTITY → trusted-number
///   guidance → optional Family Shield alert → incident summary →
///   optional upgrade.
///
/// Generic, relationship-free copy — no hard-coded "Brother" claims.
class PostCallSafetySheet extends StatelessWidget {
  const PostCallSafetySheet({super.key, required this.result});

  /// The ended session — carries the persisted [IncidentReport] when
  /// the call ended at high risk.
  final SafeCallEnded result;

  /// Presents the sheet. Returns nothing; navigation happens inside.
  static Future<void> show(BuildContext context, SafeCallEnded result) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostCallSafetySheet(result: result),
    );
  }

  bool get _highRisk => result.peakRiskLevel == ThreatRiskLevel.highRisk;

  @override
  Widget build(BuildContext context) {
    final incident = result.incident;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _Header(result: result),
            const SizedBox(height: 20),
            if (_highRisk && incident != null) ...[
              _WhyFlaggedSection(incident: incident),
              const SizedBox(height: 16),
              const _VerifyIdentityCard(),
              const SizedBox(height: 16),
              _FamilyShieldCard(incident: incident),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            IncidentDetailScreen(incident: incident),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 20),
                  label: const Text(
                    AppStrings.viewIncidentReport,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _UpgradeRow(incident: incident),
            ] else ...[
              const _SessionEndedCard(),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Done',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.result});

  final SafeCallEnded result;

  @override
  Widget build(BuildContext context) {
    final highRisk = result.peakRiskLevel == ThreatRiskLevel.highRisk;
    final color =
        highRisk ? AppColors.statusDanger : AppColors.statusSafe;
    final score = result.incident == null
        ? null
        : (result.incident!.peakRiskScore * 100).round();
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Icon(
            highRisk ? Icons.gpp_maybe_outlined : Icons.verified_user_outlined,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          highRisk
              ? AppStrings.bannerThreat
              : AppStrings.postCallEnded,
          style: AppTypography.displaySmall.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          highRisk
              ? '${AppStrings.threatScoreLabel}: $score/100 — '
                  '${AppStrings.postCallReview}'
              : AppStrings.postCallReview,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Why flagged ──────────────────────────────────────────────────────

class _WhyFlaggedSection extends StatelessWidget {
  const _WhyFlaggedSection({required this.incident});

  final IncidentReport incident;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: AppStrings.whyFlaggedTitle.toUpperCase(),
      icon: Icons.help_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in incident.threatReasons.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_outlined,
                      size: 14, color: AppColors.statusDanger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r, style: AppTypography.bodyLarge)),
                ],
              ),
            ),
          if (incident.semanticSignals.evidenceCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e
                    in incident.semanticSignals.evidenceCategories)
                  _chip(e),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(EvidenceCategory e) {
    final color = switch (e) {
      EvidenceCategory.impersonation ||
      EvidenceCategory.moneyRequest =>
        AppColors.statusDanger,
      _ => AppColors.statusWarning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        e.label,
        style:
            AppTypography.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

// ── Verify identity ──────────────────────────────────────────────────

class _VerifyIdentityCard extends StatelessWidget {
  const _VerifyIdentityCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: AppStrings.verifyIdentityTitle.toUpperCase(),
      icon: Icons.verified_user_outlined,
      accent: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.verifyIdentityBody,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: 10),
          const _Step(number: '1', text: 'Hang up — do not send money.'),
          const _Step(
            number: '2',
            text: 'Call the person on a saved, trusted number.',
          ),
          const _Step(
            number: '3',
            text: 'Ask for your family safe phrase if unsure.',
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.familySafePhrase,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.15),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

// ── Family Shield demo alert ─────────────────────────────────────────

class _FamilyShieldCard extends StatefulWidget {
  const _FamilyShieldCard({required this.incident});

  final IncidentReport incident;

  @override
  State<_FamilyShieldCard> createState() => _FamilyShieldCardState();
}

class _FamilyShieldCardState extends State<_FamilyShieldCard> {
  bool _sending = false;
  String? _result;

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _result = null;
    });
    // Demo Mode targets the labelled demo contacts; a configured
    // relay targets only the persisted Trusted Circle.
    final repo = FamilyAlertLocator.instance.isDemoMode
        ? const DemoFamilyContactRepository()
        : FamilyContactLocator.instance;
    final contacts = await repo.getFamilyContacts();
    final result =
        await FamilyAlertLocator.instance.triggerFamilyEmergencyAlert(
      incident: widget.incident,
      familyMemberIds: [for (final c in contacts) c.externalId],
    );
    if (mounted) {
      setState(() {
        _sending = false;
        _result = result.detail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = FamilyAlertLocator.instance.isDemoMode;
    return _Section(
      title: 'FAMILY SHIELD',
      icon: Icons.family_restroom_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            demo
                ? 'Demo Mode — sends a simulated alert to demo contacts; '
                    'no real notification is delivered.'
                : 'Alert your configured family contacts.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.broadcast_on_personal, size: 18),
              label: Text(
                demo
                    ? AppStrings.sendDemoFamilyAlert
                    : 'Send Family Alert',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusDanger,
                side: BorderSide(
                    color: AppColors.statusDanger.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            Text(
              _result!,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.statusSafe),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Upgrade nudge ────────────────────────────────────────────────────

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({required this.incident});

  final IncidentReport incident;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        PaywallScreen.show(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 20, color: AppColors.statusWarning),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Auto-alert relatives on high-risk calls',
                style: AppTypography.bodyLarge,
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Non-high-risk session end ────────────────────────────────────────

class _SessionEndedCard extends StatelessWidget {
  const _SessionEndedCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'SESSION SUMMARY',
      icon: Icons.check_circle_outline,
      child: const Text(
        'No high-risk patterns were flagged during this call.',
        style: AppTypography.bodyLarge,
      ),
    );
  }
}

// ── Shared section shell ─────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.accent = AppColors.textMuted,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTypography.labelSmall)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
