import 'package:flutter/material.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/alerts/family_shield_alert_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../forensics/domain/models/incident_report.dart';
import '../../../forensics/presentation/screens/incident_detail_screen.dart';
import '../../../paywall/domain/models/entitlement_state.dart';
import '../../../paywall/domain/models/subscription_tier.dart';
import '../../../paywall/domain/services/product_access.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';
import '../../domain/models/composite_threat_report.dart';
import '../../domain/models/semantic_threat_signals.dart';
import '../bloc/safecall_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/services/preferences/app_preferences.dart';

/// Post-call safety flow shown when a protection session ends.
///
/// Sequence: what happened → why it was flagged → what to do now
/// (independent verification, primary) → family help → incident
/// evidence. For high-risk sessions the header is a pause, not an
/// alarm.
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
    final p = context.palette;
    final incident = result.incident;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: p.borderSubtle)),
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
                  color: p.borderSubtle,
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
              const _VerifyCard(),
              const SizedBox(height: 16),
              _FamilyShieldCard(incident: incident),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
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
                  label: Text(
                    l10n.viewIncidentReport,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.textPrimary,
                    side: BorderSide(color: p.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Upsell only when the user doesn't already hold the
              // Family Vault entitlement — paid users never see a
              // "buy what you own" nudge.
              ValueListenableBuilder<EntitlementState>(
                valueListenable:
                    ProductAccessLocator.instance.entitlement,
                builder: (context, entitlement, _) {
                  if (entitlement.tier == TierId.familyVault) {
                    return const SizedBox.shrink();
                  }
                  return _UpgradeRow(incident: incident);
                },
              ),
            ] else ...[
              const _SessionEndedCard(),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.actionDone,
                  style: TextStyle(color: p.textMuted),
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

/// High-risk: "Pause." — one word of clarity, then the verification
/// instruction. Safe sessions get a quiet confirmation.
class _Header extends StatelessWidget {
  const _Header({required this.result});

  final SafeCallEnded result;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final highRisk = result.peakRiskLevel == ThreatRiskLevel.highRisk;
    final color =
        highRisk ? p.statusDanger : p.statusSafe;
    final score = result.incident == null
        ? null
        : (result.incident!.peakRiskScore * 100).round();
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Icon(
            highRisk
                ? Icons.pause_circle_outline
                : Icons.check_circle_outline,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          highRisk ? l10n.postCallPause : l10n.postCallEnded,
          style: AppTypography.displayLarge.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          highRisk
              ? '${l10n.verifyBeforeYouAct} '
                  '${l10n.threatScoreLabel}: $score/100.'
              : l10n.postCallReview,
          style: AppTypography.bodyLarge,
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
    final p = context.palette;
    return _Section(
      title: l10n.whyFlaggedTitle.toUpperCase(),
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
                  Icon(Icons.flag_outlined,
                      size: 14, color: p.statusDanger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.threatReason(r), style: AppTypography.bodyLarge)),
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
                  _chip(e, p),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(EvidenceCategory e, AppPalette p) {
    final color = switch (e) {
      EvidenceCategory.impersonation ||
      EvidenceCategory.moneyRequest =>
        p.statusDanger,
      _ => p.statusWarning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        localizeEvidenceLabel(l10n, e.label),
        style:
            AppTypography.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

// ── What to do now — independent verification (the primary card) ────

class _VerifyCard extends StatelessWidget {
  const _VerifyCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: p.accent.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 16, color: p.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.verifyBeforeYouAct,
                  style: AppTypography.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.verifyIdentityBody,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: 12),
          _Step(number: '1', text: l10n.verifyStepHangup),
          _Step(
            number: '2',
            text: l10n.verifyStepCall,
          ),
          _Step(
            number: '3',
            text: l10n.verifyStepPhrase,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familySafePhrase,
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
    final p = context.palette;
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
              color: p.accent.withValues(alpha: 0.15),
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: p.accent,
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
    final p = context.palette;
    final demo = FamilyAlertLocator.instance.isDemoMode;
    return ValueListenableBuilder<EntitlementState>(
      valueListenable: ProductAccessLocator.instance.entitlement,
      builder: (context, entitlement, _) {
        // The real outbound path requires Family Vault; demo mode is
        // ungated so the journey stays demoable for everyone.
        final locked =
            !demo && !ProductAccessLocator
                .instance.capabilities.familyShieldOutbound;
        return _Section(
          title: l10n.postCallFamilyShield,
          icon: Icons.group_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                demo
                    ? l10n.postCallDemoAlertDesc
                    : locked
                        ? l10n.familyVaultUnlocksAlerts
                        : l10n.postCallAskTrustDesc,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: context.isGuided ? 56 : 44,
                child: OutlinedButton.icon(
                  onPressed: _sending
                      ? null
                      : locked
                          ? () => PaywallScreen.show(context,
                              preselect: TierId.familyVault)
                          : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          locked
                              ? Icons.lock_outline
                              : Icons.broadcast_on_personal,
                          size: 18,
                        ),
                  label: Text(
                    demo
                        ? l10n.sendDemoFamilyAlert
                        : l10n.postCallSendFamilyAlert,
                    style:
                        const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.statusDanger,
                    side: BorderSide(
                        color: p.statusDanger
                            .withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 8),
                Text(
                  context.serviceMessage(_result!),
                  style: AppTypography.bodyMedium
                      .copyWith(color: p.statusSafe),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Upgrade nudge ────────────────────────────────────────────────────

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({required this.incident});

  final IncidentReport incident;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        PaywallScreen.show(context, preselect: TierId.familyVault);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 20, color: p.statusWarning),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.postCallSendFamilyAlertDesc,
                style: AppTypography.bodyLarge,
              ),
            ),
            Icon(Icons.chevron_right, color: p.textMuted),
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
      title: l10n.postCallSessionSummary,
      icon: Icons.check_circle_outline,
      child: Text(
        l10n.postCallNoFlags,
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
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: p.textMuted),
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
