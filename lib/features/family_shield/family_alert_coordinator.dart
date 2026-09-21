import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/alerts/family_contact_repository.dart';
import '../../core/services/family/family_shield_response.dart';
import '../../core/services/family/received_family_alert_repository.dart';
import '../../core/services/push/onesignal_push_identity_service.dart';
import '../../core/services/push/push_identity_service.dart';
import '../forensics/domain/services/incident_repository.dart';
import '../forensics/presentation/screens/incident_detail_screen.dart';
import 'presentation/screens/family_alert_screen.dart';
import 'presentation/screens/family_shield_update_screen.dart';

/// Routes Family Shield notification events into the app:
///
/// - `alertTaps` (real user interaction) → persist + navigate to
///   [FamilyAlertScreen].
/// - `alertReceived` (foreground arrival) → persist + show a small
///   in-app "View" prompt — never auto-navigates.
/// - `responseTaps`/`responseReceived` → persist the resolution and
///   navigate to the matching incident detail when tapped.
///
/// A tap that arrives before the Navigator is mounted is held as a
/// single pending event and flushed on the next frame — startup taps
/// are not lost, and each event navigates at most once.
final class FamilyAlertCoordinator {
  FamilyAlertCoordinator({
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? messengerKey,
    IPushIdentityService? push,
    IFamilyContactRepository? contacts,
    IReceivedFamilyAlertRepository? alerts,
    IFamilyShieldResponseStore? responses,
    IIncidentRepository? incidents,
  })  : _navigatorKey = navigatorKey ?? FamilyAlertNavigator.key,
        _messengerKey = messengerKey,
        _push = push ?? PushIdentityLocator.instance,
        _contacts = contacts ?? FamilyContactLocator.instance,
        _alerts = alerts ?? ReceivedFamilyAlertLocator.instance,
        _responses = responses ?? FamilyShieldResponseLocator.instance,
        _incidents = incidents ?? IncidentRepositoryLocator.instance;

  final GlobalKey<NavigatorState> _navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? _messengerKey;
  final IPushIdentityService _push;
  final IFamilyContactRepository _contacts;
  final IReceivedFamilyAlertRepository _alerts;
  final IFamilyShieldResponseStore _responses;
  final IIncidentRepository _incidents;

  final _subs = <StreamSubscription<Object>>[];
  final _navigatedAlertKeys = <String>{};

  /// `incident|responder` → the resolution last surfaced to the user.
  /// Dedupes only the CURRENT duplicate state: `safe → safe` is a
  /// redelivery, `safe → stillSuspicious → safe` surfaces all three.
  final _lastSurfacedResponse = <String, AlertResolution>{};
  FamilyAlertTap? _pendingAlertTap;
  FamilyShieldResponse? _pendingResponseTap;
  bool _flushScheduled = false;

  /// Call once at app startup — before or alongside push
  /// initialization — so a cold-start tap is never lost.
  void start() {
    _subs
      ..add(_push.alertTaps.listen(_onAlertTap))
      ..add(_push.alertReceived.listen(_onAlertReceived))
      ..add(_push.responseTaps.listen(_onResponseTap))
      ..add(_push.responseReceived.listen(_onResponse));
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
  }

  // ── Incoming danger alerts ──────────────────────────────────────

  Future<void> _onAlertReceived(FamilyAlertTap event) async {
    await _persistAlert(event);
    // Foreground arrival is NOT a click — offer an in-app affordance
    // and let the user choose.
    _messengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: const Text('Family Shield alert received'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => unawaited(_navigateToAlert(event)),
        ),
      ),
    );
  }

  Future<void> _onAlertTap(FamilyAlertTap event) async {
    final alert = await _persistAlert(event);
    await _navigateToAlert(event, stored: alert);
  }

  Future<ReceivedFamilyAlert> _persistAlert(FamilyAlertTap event) async {
    final alert = ReceivedFamilyAlert(
      incidentId: event.incidentId,
      senderExternalId: event.senderExternalId,
      riskLevel: event.riskLevel,
      receivedAt: DateTime.now(),
      analysisScope: event.analysisScope,
    );
    await _alerts.upsert(alert);
    return (await _alerts.lookup(alert.key)) ?? alert;
  }

  // ── Resolution responses (sender side) ─────────────────────────

  Future<void> _onResponse(FamilyShieldResponse response) =>
      _responses.upsert(response);

  Future<void> _onResponseTap(FamilyShieldResponse response) async {
    await _responses.upsert(response);
    await _navigateToResponse(response);
  }

  // ── Navigation ─────────────────────────────────────────────────

  Future<void> _navigateToAlert(
    FamilyAlertTap event, {
    ReceivedFamilyAlert? stored,
  }) async {
    final nav = _navigatorKey.currentState;
    if (nav == null) {
      _pendingAlertTap ??= event; // hold one pending alert
      _scheduleFlush();
      return;
    }
    final dedupeKey = 'alert|${event.senderExternalId}|${event.incidentId}';
    if (!_navigatedAlertKeys.add(dedupeKey)) return;
    final alert = stored ??
        await _alerts.lookup(
            '${event.senderExternalId}|${event.incidentId}') ??
        await _persistAlert(event);
    final contacts = await _contacts.getFamilyContacts();
    FamilyContact? sender;
    for (final c in contacts) {
      if (c.externalId == event.senderExternalId) sender = c;
    }
    unawaited(nav.push(MaterialPageRoute<void>(
      builder: (_) => FamilyAlertScreen(alert: alert, sender: sender),
    )));
  }

  Future<void> _navigateToResponse(FamilyShieldResponse response) async {
    final nav = _navigatorKey.currentState;
    if (nav == null) {
      _pendingResponseTap ??= response;
      _scheduleFlush();
      return;
    }
    // Dedupe only a consecutive/current duplicate: a genuinely changed
    // resolution (even back to a previously-seen value) is surfaced.
    final key =
        'resp|${response.responderExternalId}|${response.incidentId}';
    if (_lastSurfacedResponse[key] == response.resolution) return;
    _lastSurfacedResponse[key] = response.resolution;
    final incident =
        await _incidents.getIncidentById(response.incidentId);
    final contacts = await _contacts.getFamilyContacts();
    String? responderName;
    for (final c in contacts) {
      if (c.externalId == response.responderExternalId) {
        responderName = c.name;
      }
    }
    if (incident != null) {
      unawaited(nav.push(MaterialPageRoute<void>(
        builder: (_) => IncidentDetailScreen(incident: incident),
      )));
    } else {
      unawaited(nav.push(MaterialPageRoute<void>(
        builder: (_) => FamilyShieldUpdateScreen(
          response: response,
          responderName: responderName,
        ),
      )));
    }
  }

  /// Flush a pending tap once the Navigator exists — re-arms each
  /// frame while a pending event is held. Dedupe keys make
  /// double-navigation impossible.
  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _flushScheduled = false;
      final alertTap = _pendingAlertTap;
      final responseTap = _pendingResponseTap;
      if (alertTap == null && responseTap == null) return;
      if (_navigatorKey.currentState == null) {
        _scheduleFlush(); // navigator still not mounted — try next frame
        return;
      }
      _pendingAlertTap = null;
      _pendingResponseTap = null;
      if (alertTap != null) await _navigateToAlert(alertTap);
      if (responseTap != null) await _navigateToResponse(responseTap);
    });
  }
}

/// Shared navigator key so [FamilyAlertCoordinator] can route taps
/// without a BuildContext.
final class FamilyAlertNavigator {
  FamilyAlertNavigator._();

  static final key = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
}
