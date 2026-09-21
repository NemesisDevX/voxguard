import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/alerts/family_contact_repository.dart';
import '../../../../core/services/alerts/family_shield_alert_service.dart';
import '../../../../core/services/family/received_family_alert_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
      return 'Family Shield alert from an unrecognized '
          'VoxGuard identity.';
    }
    if (_partial) {
      return '$_senderName asked you to verify an elevated acoustic '
          'warning from a recording.';
    }
    return widget.alert.riskLevel == 'highRisk'
        ? '$_senderName may be dealing with a high-risk call.'
        : '$_senderName received a suspicious-call warning '
            'from VoxGuard.';
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

    final result = await FamilyAlertLocator.instance
        .sendFamilyShieldResponse(
      incidentId: widget.alert.incidentId,
      resolution: resolution,
      targetExternalId: widget.alert.senderExternalId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final localCopy = resolution == AlertResolution.safe
        ? 'Marked safe after independent verification.'
        : 'Still suspicious — keep verification going.';
    _note = result.attempted
        ? localCopy
        : '$localCopy Family update could not be sent '
            '(${result.detail})';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = switch (widget.alert.riskLevel) {
      'highRisk' => AppColors.statusDanger,
      'suspicious' => AppColors.statusWarning,
      _ => AppColors.statusSafe,
    };
    final phone = widget.sender?.trustedPhone;

    return Scaffold(
      appBar: AppBar(title: const Text('Family Shield Alert')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                    ? 'PARTIAL ANALYSIS'
                    : switch (widget.alert.riskLevel) {
                        'highRisk' => 'HIGH RISK',
                        'suspicious' => 'SUSPICIOUS',
                        _ => 'ALERT',
                      },
                style: AppTypography.titleMedium.copyWith(
                    color: riskColor, letterSpacing: 1.2),
              ),
            ),
            if (_partial) ...[
              const SizedBox(height: 8),
              Text(
                'Conversation-risk signals were not analyzed.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 24),

            Text('Verify directly', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(
              _knownSender
                  ? 'Call $_senderName using the trusted number you '
                      'saved — not a number provided by the '
                      'suspicious caller.'
                  : 'Verify through a channel you already trust. '
                      'Do not act on instructions from the alert '
                      'alone.',
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
                  label: Text(
                      'Call ${_knownSender ? _senderName : 'contact'}'),
                ),
              )
            else
              Text(
                'No trusted number saved. Contact them through a '
                'number you already trust.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
              ),

            const SizedBox(height: 24),
            Text('Your assessment', style: AppTypography.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resolution == AlertResolution.safe
                        ? null
                        : () => _resolve(AlertResolution.safe),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark Safe'),
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
                    label: const Text('Still Suspicious'),
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
                  color: AppColors.statusWarning
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.statusWarning
                          .withValues(alpha: 0.4)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Guidance('Do not send money or gift codes.'),
                    _Guidance(
                        'Do not share OTP, PIN, or banking details.'),
                    _Guidance(
                        'Verify through another independent channel.'),
                    _Guidance(
                        'Contact their bank, carrier, or local '
                        'authorities if needed.'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            Text('Details', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            Text(
              'Incident ${widget.alert.incidentId}\n'
              'Received ${_formatTime(widget.alert.receivedAt)}\n'
              'Resolution: ${switch (_resolution) {
                AlertResolution.safe => 'Safe after verification',
                AlertResolution.stillSuspicious => 'Still suspicious',
                AlertResolution.unresolved => 'Unresolved',
              }}\n\n'
              'Privacy: only an opaque device identity and risk level '
              'were shared. No audio, transcript, names, or phone '
              'numbers are included in Family Shield alerts.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: 14, color: AppColors.statusWarning),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
