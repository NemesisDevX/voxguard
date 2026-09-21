import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'received_family_alert_repository.dart';

/// A privacy-minimal resolution event sent back from a trusted
/// person's device to the alerting device.
final class FamilyShieldResponse {
  const FamilyShieldResponse({
    required this.incidentId,
    required this.responderExternalId,
    required this.resolution,
    this.receivedAt,
  });

  /// The original alert's incident reference.
  final String incidentId;

  /// `vg_…` identity of the device that resolved the alert.
  final String responderExternalId;

  /// `safe` or `stillSuspicious` — never `unresolved` on the wire.
  final AlertResolution resolution;

  /// Local receipt time — set when stored, absent on the wire.
  final DateTime? receivedAt;

  /// Local key — incident + responder, so two responders on one
  /// incident never collide.
  String get key => '$incidentId|$responderExternalId';

  static final _externalIdPattern = RegExp(r'^vg_[0-9a-f]{32}$');
  static const _validResolutions = {
    AlertResolution.safe,
    AlertResolution.stillSuspicious,
  };

  /// Parses notification `additionalData`; returns null unless all
  /// routing fields are present and well-formed. Never throws —
  /// malformed or unrelated payloads are ignored.
  static FamilyShieldResponse? fromAdditionalData(
      Map<String, dynamic>? data) {
    if (data == null || data['kind'] != 'family_shield_response') {
      return null;
    }
    final incidentId = data['incident_id'];
    final responder = data['responder_external_id'];
    final resName = data['resolution'];
    final resolution = resName is String
        ? AlertResolution.values.asNameMap()[resName]
        : null;
    if (incidentId is! String || incidentId.isEmpty) return null;
    if (responder is! String || !_externalIdPattern.hasMatch(responder)) {
      return null;
    }
    if (resolution == null || !_validResolutions.contains(resolution)) {
      return null;
    }
    return FamilyShieldResponse(
      incidentId: incidentId,
      responderExternalId: responder,
      resolution: resolution,
    );
  }

  Map<String, dynamic> toJson() => {
        'incident_id': incidentId,
        'responder_external_id': responderExternalId,
        'resolution': resolution.name,
        if (receivedAt != null)
          'received_at': receivedAt!.toIso8601String(),
      };

  static final _incidentPattern =
      RegExp(r'^[A-Za-z0-9_\-.:@]{1,64}$');

  /// Strict load validation — skip corrupted rows safely.
  static FamilyShieldResponse? fromJson(Map<String, dynamic> json) {
    final incidentId = json['incident_id'];
    final responder = json['responder_external_id'];
    final resName = json['resolution'];
    if (incidentId is! String || !_incidentPattern.hasMatch(incidentId)) {
      return null;
    }
    if (responder is! String ||
        !_externalIdPattern.hasMatch(responder)) {
      return null;
    }
    final resolution = AlertResolution.values.asNameMap()[resName];
    if (resolution == null || !_validResolutions.contains(resolution)) {
      return null;
    }
    return FamilyShieldResponse(
      incidentId: incidentId,
      responderExternalId: responder,
      resolution: resolution,
      receivedAt: DateTime.tryParse('${json['received_at'] ?? ''}'),
    );
  }
}

/// Local store for resolution events arriving back at the device
/// that raised the alert.
abstract interface class IFamilyShieldResponseStore {
  /// Insert or update; keyed by incident+responder.
  Future<void> upsert(FamilyShieldResponse response);

  /// All responses for one incident, newest first.
  Future<List<FamilyShieldResponse>> forIncident(String incidentId);

  ValueListenable<List<FamilyShieldResponse>> get responses;
}

/// SharedPreferences-backed — no database dependency.
final class PersistedFamilyShieldResponseStore
    implements IFamilyShieldResponseStore {
  PersistedFamilyShieldResponseStore({SharedPreferences? prefs})
      : _prefs = prefs;

  static const _key = 'voxguard.family_shield_responses';
  static const _maxStored = 200;

  final SharedPreferences? _prefs;
  final _list = ValueNotifier<List<FamilyShieldResponse>>(const []);
  Future<void>? _loadFuture;

  Future<SharedPreferences> get _store =>
      _prefs != null ? Future.value(_prefs) : SharedPreferences.getInstance();

  Future<void> _ensureLoaded() => _loadFuture ??= _doLoad();

  Future<void> _doLoad() async {
    final raw = (await _store).getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final seen = <String>{};
      final list = <FamilyShieldResponse>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final r = FamilyShieldResponse.fromJson(e);
        if (r == null || !seen.add(r.key)) continue;
        if (list.length >= _maxStored) break;
        list.add(r);
      }
      _list.value = list;
    } on FormatException {
      _list.value = const [];
    }
  }

  Future<void> _persist() async {
    await (await _store).setString(
      _key,
      jsonEncode([for (final r in _list.value) r.toJson()]),
    );
  }

  @override
  Future<void> upsert(FamilyShieldResponse response) async {
    await _ensureLoaded();
    final stamped = response.receivedAt == null
        ? FamilyShieldResponse(
            incidentId: response.incidentId,
            responderExternalId: response.responderExternalId,
            resolution: response.resolution,
            receivedAt: DateTime.now(),
          )
        : response;
    if (_list.value.any((r) => r.key == stamped.key)) {
      _list.value = [
        for (final r in _list.value) r.key == stamped.key ? stamped : r,
      ];
    } else {
      _list.value = [stamped, ..._list.value].take(_maxStored).toList();
    }
    await _persist();
  }

  @override
  Future<List<FamilyShieldResponse>> forIncident(String incidentId) async {
    await _ensureLoaded();
    return [for (final r in _list.value) if (r.incidentId == incidentId) r];
  }

  @override
  ValueListenable<List<FamilyShieldResponse>> get responses {
    _ensureLoaded();
    return _list;
  }
}

/// Process-wide accessor.
final class FamilyShieldResponseLocator {
  FamilyShieldResponseLocator._();

  static IFamilyShieldResponseStore? _instance;

  static IFamilyShieldResponseStore get instance =>
      _instance ??= PersistedFamilyShieldResponseStore();

  @visibleForTesting
  static set instance(IFamilyShieldResponseStore store) =>
      _instance = store;
}
