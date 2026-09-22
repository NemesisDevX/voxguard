import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../features/forensics/domain/models/incident_report.dart';
import '../../../features/paywall/domain/services/product_access.dart';
import '../../../features/protection/domain/models/composite_threat_report.dart';
import '../family/received_family_alert_repository.dart';
import '../push/onesignal_push_identity_service.dart';
import 'family_alert_service.dart';
import 'family_contact_repository.dart';
import '../../l10n/l10n.dart';

/// Family Shield broadcast client.
///
/// **Security boundary:** the OneSignal REST API key must live on a
/// server-side relay — never inside the Flutter client. This service
/// POSTs a compact alert request to a minimal backend/edge endpoint
/// (`--dart-define=VOXGUARD_ALERT_RELAY_URL=https://…`), which owns the
/// OneSignal credentials and fans the notification out to family
/// `external_id` aliases.
///
/// Without a configured relay the service runs in explicit **Demo
/// Mode**: the payload is built and logged identically but never
/// leaves the device, so the full Family Shield journey stays
/// demoable for judging without shipping secrets.
final class FamilyShieldAlertService implements IFamilyAlertService {
  FamilyShieldAlertService({
    http.Client? httpClient,
    String? relayUrl,
    String? relayToken,
    Future<String> Function()? senderIdentity,
    IProductAccess? productAccess,
  })  : _client = httpClient ?? http.Client(),
        _relayUrl = relayUrl ??
            const String.fromEnvironment(
              'VOXGUARD_ALERT_RELAY_URL',
              defaultValue: '',
            ),
        _relayToken = relayToken ??
            const String.fromEnvironment(
              'VOXGUARD_RELAY_TOKEN',
              defaultValue: '',
            ),
        _senderIdentity =
            senderIdentity ?? PushIdentityLocator.instance.voxGuardIdentity,
        _productAccess = productAccess ?? ProductAccessLocator.instance;

  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String _relayUrl;

  /// Shared relay client token — abuse resistance for the public
  /// endpoint, NOT a high-security secret. The OneSignal REST key
  /// stays server-side regardless. Production should move to
  /// authenticated users / device attestation.
  final String _relayToken;

  /// Resolves this device's own `vg_…` identity — included as
  /// `sender_external_id` so receivers can tell which trusted
  /// contact raised the alert. Opaque id only, never name/phone.
  final Future<String> Function() _senderIdentity;

  /// Product-access layer — the real outbound path requires Family
  /// Vault. Demo Mode (no relay) is never gated: simulated alerts
  /// must stay demoable for everyone.
  final IProductAccess _productAccess;

  final ValueNotifier<bool> _enabled = ValueNotifier<bool>(true);

  /// Whether a real relay endpoint is configured. When false the
  /// service simulates broadcasts instead of hitting the network.
  bool get isRelayConfigured => _relayUrl.isNotEmpty;

  @override
  ValueListenable<bool> get isFamilyShieldEnabled => _enabled;

  @override
  bool get isDemoMode => !isRelayConfigured;

  @override
  void toggleFamilyShield(bool enabled) => _enabled.value = enabled;

  @override
  Future<AlertDispatchResult> triggerFamilyEmergencyAlert({
    required IncidentReport incident,
    required List<String> familyMemberIds,
  }) async {
    if (!_enabled.value) {
      return AlertDispatchResult(
        status: AlertDispatchStatus.disabled,
        detail: l10n.msgFamilyDisabled,
      );
    }

    // Plan gate — defense-in-depth at the operation boundary. The
    // real relay path requires Family Vault; zero network I/O happens
    // for entitled-less callers. Demo Mode below stays ungated.
    if (isRelayConfigured &&
        !_productAccess.capabilities.familyShieldOutbound) {
      return AlertDispatchResult(
        status: AlertDispatchStatus.locked,
        detail: l10n.familyVaultUnlocksAlerts,
      );
    }

    // Real mode enforces the identity contract at the network
    // boundary: only well-formed `vg_…` ids may be targeted — demo
    // ids or malformed values are dropped, never sent to the relay.
    final recipients = isRelayConfigured
        ? [
            for (final id in familyMemberIds)
              if (FamilyContactRules.externalIdPattern.hasMatch(id)) id,
          ]
        : familyMemberIds;

    // Real mode + empty Trusted Circle → send nothing. Demo ids are
    // never substituted as a fallback.
    if (isRelayConfigured && recipients.isEmpty) {
      return AlertDispatchResult(
        status: AlertDispatchStatus.noRecipients,
        detail: l10n.msgNeedTrustedContact,
      );
    }

    final payload =
        _buildPayload(incident, recipients, await _senderIdentity());

    if (!isRelayConfigured) {
      // Demo Mode broadcast — deterministic, offline-safe.
      debugPrint('[FamilyShield·demo] ${jsonEncode(payload)}');
      return AlertDispatchResult(
        status: AlertDispatchStatus.simulated,
        detail: l10n.msgDemoAlertDelivered(recipients.length),
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_relayUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (_relayToken.isNotEmpty)
                'Authorization': 'Bearer $_relayToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 202) {
        // The relay + OneSignal API accepted the alert — that is NOT
        // confirmed delivery to a device.
        return AlertDispatchResult(
          status: AlertDispatchStatus.accepted,
          detail: l10n.msgAlertDelivered(recipients.length),
        );
      }
      // Relay rejected the request (auth or payload) vs. the relay or
      // upstream being unavailable — the UI distinguishes honestly.
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 429) {
        return AlertDispatchResult(
          status: AlertDispatchStatus.rejected,
          detail: l10n.msgRelayRejected(response.statusCode),
        );
      }
      return AlertDispatchResult(
        status: AlertDispatchStatus.unavailable,
        detail: l10n.msgAlertUnavailable(response.statusCode),
      );
    } on Exception {
      return AlertDispatchResult(
        status: AlertDispatchStatus.unavailable,
        detail: l10n.msgAlertNetworkError,
      );
    }
  }

  /// Compact, privacy-minimal alert request the relay fans out via
  /// OneSignal. Contains no user audio, transcript, names, phone
  /// numbers or credentials — just the incident reference, target
  /// aliases, and the sender's opaque `vg_…` identity so receivers
  /// know which trusted contact raised the alert.
  Map<String, Object?> _buildPayload(
    IncidentReport incident,
    List<String> familyMemberIds,
    String senderExternalId,
  ) {
    return {
      'kind': 'family_shield_alert',
      'incident_id': incident.id,
      'risk_level': incident.riskLevel.name,
      // Partial (acoustic-only) records must never arrive described
      // as a fully analyzed call.
      'analysis_scope': incident.analysisIsPartial ? 'partial' : 'full',
      'sender_external_id': senderExternalId,
      'family_external_ids': familyMemberIds,
      'title': l10n.pushAlertTitle,
      'body': _alertBody(incident),
    };
  }

  /// Scope- and risk-aware notification body — a partial recording
  /// analysis is an acoustic warning, not a "high-risk call".
  static String _alertBody(IncidentReport incident) {
    if (incident.analysisIsPartial) {
      return l10n.pushAlertBodyPartial;
    }
    return incident.riskLevel == ThreatRiskLevel.highRisk
        ? l10n.pushAlertBodyHigh
        : l10n.pushAlertBodySuspicious;
  }

  /// Sends a `family_shield_response` back to the alerting device.
  /// Local resolution is owned by the caller — a network failure here
  /// must not roll back the user's local state.
  @override
  Future<AlertDispatchResult> sendFamilyShieldResponse({
    required String incidentId,
    required AlertResolution resolution,
    required String targetExternalId,
  }) async {
    if (!_enabled.value) {
      return AlertDispatchResult(
        status: AlertDispatchStatus.disabled,
        detail: l10n.msgFamilyDisabled,
      );
    }
    // `unresolved` is a local state, never a wire resolution — reject
    // client-side without any network I/O.
    if (resolution == AlertResolution.unresolved) {
      return AlertDispatchResult(
        status: AlertDispatchStatus.rejected,
        detail: l10n.msgResolutionRequired,
      );
    }
    if (!FamilyContactRules.externalIdPattern.hasMatch(targetExternalId)) {
      return AlertDispatchResult(
        status: AlertDispatchStatus.rejected,
        detail: l10n.msgInvalidShieldId,
      );
    }
    final payload = {
      'kind': 'family_shield_response',
      'incident_id': incidentId,
      'resolution': resolution.name,
      'responder_external_id': await _senderIdentity(),
      'target_external_id': targetExternalId,
    };

    if (!isRelayConfigured) {
      debugPrint('[FamilyShield·demo-response] ${jsonEncode(payload)}');
      return AlertDispatchResult(
        status: AlertDispatchStatus.simulated,
        detail: l10n.msgDemoResponseSent,
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_relayUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (_relayToken.isNotEmpty)
                'Authorization': 'Bearer $_relayToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 202) {
        return AlertDispatchResult(
          status: AlertDispatchStatus.accepted,
          detail: l10n.msgFamilyUpdateSent,
        );
      }
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 429) {
        return AlertDispatchResult(
          status: AlertDispatchStatus.rejected,
          detail: l10n.msgResponseRejected(response.statusCode),
        );
      }
      return AlertDispatchResult(
        status: AlertDispatchStatus.unavailable,
        detail: l10n.msgAlertUnavailable(response.statusCode),
      );
    } on Exception {
      return AlertDispatchResult(
        status: AlertDispatchStatus.unavailable,
        detail: l10n.msgResponseNetworkError,
      );
    }
  }
}

/// Process-wide accessor for the alert service.
final class FamilyAlertLocator {
  FamilyAlertLocator._();

  static IFamilyAlertService? _instance;

  static IFamilyAlertService get instance =>
      _instance ??= FamilyShieldAlertService();

  @visibleForTesting
  static set instance(IFamilyAlertService service) => _instance = service;
}
