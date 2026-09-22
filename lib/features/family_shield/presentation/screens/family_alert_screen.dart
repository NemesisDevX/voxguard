import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/alerts/family_shield_alert_service.dart';
import '../../../../core/services/family/received_family_alert_repository.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/services/haptics/app_haptics.dart';

/// Thin seam over `url_launcher` so tests can observe the `tel:` URI
/// without touching platform channels.
final class TrustedPhoneLauncher {
  TrustedPhoneLauncher._();

  static Future<bool> Function(Uri uri) _launch = launchUrl;

  /// Dials [phone] via the system dialer — the number is a locally
  /// stored trusted contact field, never a caller-supplied one.
  static Future<bool> callTrusted(String phone) =>
      _launch(Uri(scheme: 'tel', path: phone));

  @visibleForTesting
  static set launchImpl(Future<bool> Function(Uri uri) impl) =>
      _launch = impl;
}

/// Family Alert screen — the receiving side of the Family Shield
/// loop. Consumer-first: who raised it, the risk band, how to verify
/// (call the *saved* trusted number), and a human resolution.
/// Deliberately shows no transcript, audio, or caller details.
class FamilyAlertScreen extends StatefulWidget {
  const FamilyAlertScreen({
    super.key,
    required this.alert,
    this.sender,
  });

  final ReceivedFamilyAlert alert;

  /// Resolved locally from the Trusted Circle — null for an
  /// unrecognized `vg_…` identity (never fabricated).
  final FamilyContact? sender;

  @override
  State<FamilyAlertScreen> createState() => _FamilyAlertScreenState();
}

class _FamilyAlertScreenState extends State<FamilyAlertScreen> {
  late AlertResolution _resolution = widget.alert.resolution;
  bool _busy = false;
  String? _note;

  String get _senderName => widget.sender?.name ?? '';
  bool get _knownSender => widget.sender != null;
  bool get _partial => widget.alert.analysisScope == 'partial';

  /// Scope- and risk-aware headline — a partial recording analysis is
  /// an acoustic warning, never a "high-risk call"; a suspicious
  /// alert is a warning, never a confirmed scam.
  String get _headline {
    if (!_knownSender) {
      return l10n.familyAlertUnknownSender;
    }
    if (_partial) {
      return l10n.familyAlertAcoustic(_senderName);
    }
    return widget.alert.riskLevel == 'highRisk'
        ? l10n.familyAlertHighRisk(_senderName)
        : l10n.familyAlertSuspicious(_senderName);
  }

  Future<void> _resolve(AlertResolution resolution) async {
    if (_busy || _resolution == resolution) return;
    setState(() {
      _busy = true;
      _note = null;
    });
    // Local first — the user's decision must survive network failure.
    await ReceivedFamilyAlertLocator.instance
        .setResolution(widget.alert.key, resolution);
    if (mounted) setState(() => _resolution = resolution);
    // A human response landed — one restrained confirmation pulse.
    AppHaptics.confirm();

    final result = await FamilyAlertLocator.instance
        .sendFamilyShieldResponse(
      incidentId: widget.alert.incidentId,
      resolution: resolution,
      targetExternalId: widget.alert.senderExternalId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final localCopy = resolution == AlertResolution.safe
        ? l10n.familyMarkedSafeNote
        : l10n.familyStillSuspiciousNote;
    _note = result.attempted
        ? localCopy
        : '${l10n.familyUpdateFailed(localCopy)} '
            '(${context.serviceMessage(result.detail)})';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final riskColor = switch (widget.alert.riskLevel) {
      'highRisk' => p.statusDanger,
      'suspicious' => p.statusWarning,
      _ => p.statusSafe,
    };
    final phone = widget.sender?.trustedPhone;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyAlertTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.familyAlertFraming,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(_headline, style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: riskColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                _partial
                    ? l10n.bandPartial
                    : switch (widget.alert.riskLevel) {
                        'highRisk' => l10n.bandHigh,
                        'suspicious' => l10n.bandSuspicious,
                        _ => l10n.familyBandAlert,
                      },
                style: AppTypography.titleMedium.copyWith(
                    color: riskColor, letterSpacing: 1.2),
              ),
            ),
            if (_partial) ...[
              const SizedBox(height: 8),
              Text(
                l10n.conversationNotAnalyzed,
                style: AppTypography.bodyMedium
                    .copyWith(color: p.textMuted),
              ),
            ],
            const SizedBox(height: 24),

            Text(l10n.familyVerifyDirectly, style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(
              _knownSender
                  ? l10n.familyVerifyKnownSender(_senderName)
                  : l10n.familyVerifyUnknownSender,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),

            if (phone != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      TrustedPhoneLauncher.callTrusted(phone),
                  icon: const Icon(Icons.call_outlined),
                  label: Text(_knownSender
                      ? l10n.familyCallAction(_senderName)
                      : l10n.familyCallContact),
                ),
              )
            else
              Text(
                l10n.familyNoTrustedNumber,
                style: AppTypography.bodyMedium
                    .copyWith(color: p.textMuted),
              ),

            const SizedBox(height: 24),
            Text(l10n.yourJudgment,
                style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(
              l10n.humanResponseNote,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resolution == AlertResolution.safe
                        ? null
                        : () => _resolve(AlertResolution.safe),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.familyMarkSafe),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _resolution == AlertResolution.stillSuspicious
                            ? null
                            : () =>
                                _resolve(AlertResolution.stillSuspicious),
                    icon: const Icon(Icons.warning_amber_outlined),
                    label: Text(l10n.familyStillSuspicious),
                  ),
                ),
              ],
            ),
            if (_note != null) ...[
              const SizedBox(height: 10),
              Text(_note!, style: AppTypography.bodyMedium),
            ],
            if (_resolution == AlertResolution.stillSuspicious) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.statusWarning
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: p.statusWarning
                          .withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Guidance(l10n.familyTipNoMoney),
                    _Guidance(l10n.familyTipNoCodes),
                    _Guidance(l10n.familyTipChannel),
                    _Guidance(l10n.familyTipAuthorities),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            Text(l10n.familyDetailsTitle, style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            Text(
              '${l10n.familyDetailsBody(
                widget.alert.incidentId,
                _formatTime(widget.alert.receivedAt),
                l10n.familyResolutionLabel(switch (_resolution) {
                  AlertResolution.safe => l10n.familyResolutionSafe,
                  AlertResolution.stillSuspicious =>
                      l10n.familyResolutionStillSuspicious,
                  AlertResolution.unresolved =>
                      l10n.familyResolutionUnresolved,
                }),
              )}\n\n${l10n.familyPrivacyNote}',
              style: AppTypography.bodyMedium
                  .copyWith(color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)} '
      '${_two(t.hour)}:${_two(t.minute)}';
  String _two(int v) => v.toString().padLeft(2, '0');
}

class _Guidance extends StatelessWidget {
  const _Guidance(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              size: 14, color: p.statusWarning),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
