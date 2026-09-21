import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Human verification outcome on the receiving device — kept
/// strictly separate from AI threat assessment.
enum AlertResolution { unresolved, safe, stillSuspicious }

/// A Family Shield alert this device received from a trusted
/// contact's device. Privacy-minimal: no transcript, audio, names,
/// or phone numbers — only opaque `vg_…` ids and routing metadata.
final class ReceivedFamilyAlert {
  const ReceivedFamilyAlert({
    required this.incidentId,
    required this.senderExternalId,
    required this.riskLevel,
    required this.receivedAt,
    this.analysisScope = 'full',
    this.resolution = AlertResolution.unresolved,
    this.resolvedAt,
  });

  final String incidentId;
  final String senderExternalId;
  final String riskLevel;
  final DateTime receivedAt;

  /// `full` or `partial` — whether conversation-risk signals were
  /// analyzed on the sender's side. Drives scope-honest receiver copy.
  final String analysisScope;
  final AlertResolution resolution;
  final DateTime? resolvedAt;

  /// Stable local key — sender + incident, so two different senders
  /// using the same incident id never collide.
  String get key => '$senderExternalId|$incidentId';

  ReceivedFamilyAlert copyWith({
    AlertResolution? resolution,
    DateTime? resolvedAt,
  }) =>
      ReceivedFamilyAlert(
        incidentId: incidentId,
        senderExternalId: senderExternalId,
        riskLevel: riskLevel,
        receivedAt: receivedAt,
        analysisScope: analysisScope,
        resolution: resolution ?? this.resolution,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  Map<String, dynamic> toJson() => {
        'incident_id': incidentId,
        'sender_external_id': senderExternalId,
        'risk_level': riskLevel,
        'received_at': receivedAt.toIso8601String(),
        'analysis_scope': analysisScope,
        'resolution': resolution.name,
        if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      };

  static final _externalIdPattern = RegExp(r'^vg_[0-9a-f]{32}$');
  static final _incidentPattern =
      RegExp(r'^[A-Za-z0-9_\-.:@]{1,64}$');
  static const _validRiskLevels = {'safe', 'suspicious', 'highRisk'};

  /// Strict load validation — corrupted or tampered rows are
  /// skipped, never repaired into fake alerts.
  static ReceivedFamilyAlert? fromJson(Map<String, dynamic> json) {
    final incidentId = json['incident_id'];
    final sender = json['sender_external_id'];
    final risk = json['risk_level'];
    final receivedAt = DateTime.tryParse('${json['received_at'] ?? ''}');
    final resName = json['resolution'];
    if (incidentId is! String || !_incidentPattern.hasMatch(incidentId)) {
      return null;
    }
    if (sender is! String || !_externalIdPattern.hasMatch(sender)) {
      return null;
    }
    if (risk is! String || !_validRiskLevels.contains(risk)) {
      return null;
    }
    if (receivedAt == null) return null;
    final resolution = AlertResolution.values.asNameMap()[resName];
    if (resolution == null) return null;
    // Rows persisted before analysis_scope existed were all live-call
    // alerts — 'full' is the honest default; malformed values drop.
    final scope = json['analysis_scope'];
    if (scope != null && scope != 'full' && scope != 'partial') {
      return null;
    }
    return ReceivedFamilyAlert(
      incidentId: incidentId,
      senderExternalId: sender,
      riskLevel: risk,
      receivedAt: receivedAt,
      analysisScope: scope is String ? scope : 'full',
      resolution: resolution,
      resolvedAt: DateTime.tryParse('${json['resolved_at'] ?? ''}'),
    );
  }
}

/// Local store for Family Shield alerts this device has received.
abstract interface class IReceivedFamilyAlertRepository {
  /// Insert or update; keyed by sender+incident so duplicate
  /// push/tap delivery never creates a second record.
  Future<void> upsert(ReceivedFamilyAlert alert);

  Future<ReceivedFamilyAlert?> lookup(String key);

  /// Newest first.
  Future<List<ReceivedFamilyAlert>> recent({int limit = 50});

  /// Persist a human resolution — returns the updated alert, or
  /// null if the key is unknown.
  Future<ReceivedFamilyAlert?> setResolution(
    String key,
    AlertResolution resolution,
  );

  ValueListenable<List<ReceivedFamilyAlert>> get alerts;
}

/// SharedPreferences-backed store — no database dependency.
final class PersistedReceivedFamilyAlertRepository
    implements IReceivedFamilyAlertRepository {
  PersistedReceivedFamilyAlertRepository({SharedPreferences? prefs})
      : _prefs = prefs;

  static const _key = 'voxguard.received_family_alerts';
  static const _maxStored = 50;

  final SharedPreferences? _prefs;
  final _list = ValueNotifier<List<ReceivedFamilyAlert>>(const []);
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
      // Sanitize: well-formed rows only, dedupe by stable key, cap
      // applies during load — not only on insert.
      final seen = <String>{};
      final list = <ReceivedFamilyAlert>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final a = ReceivedFamilyAlert.fromJson(e);
        if (a == null || !seen.add(a.key)) continue;
        if (list.length >= _maxStored) break;
        list.add(a);
      }
      _list.value = list;
    } on FormatException {
      _list.value = const [];
    }
  }

  Future<void> _persist() async {
    await (await _store).setString(
      _key,
      jsonEncode([for (final a in _list.value) a.toJson()]),
    );
  }

  @override
  Future<void> upsert(ReceivedFamilyAlert alert) async {
    await _ensureLoaded();
    final idx = _list.value.indexWhere((a) => a.key == alert.key);
    if (idx >= 0) {
      // Keep the earliest receipt time and any existing resolution —
      // a duplicate delivery must not reset human state.
      final existing = _list.value[idx];
      _list.value = [
        for (final a in _list.value)
          a.key == alert.key ? existing : a,
      ];
    } else {
      _list.value =
          [alert, ..._list.value].take(_maxStored).toList();
    }
    await _persist();
  }

  @override
  Future<ReceivedFamilyAlert?> lookup(String key) async {
    await _ensureLoaded();
    for (final a in _list.value) {
      if (a.key == key) return a;
    }
    return null;
  }

  @override
  Future<List<ReceivedFamilyAlert>> recent({int limit = 50}) async {
    await _ensureLoaded();
    return _list.value.take(limit).toList();
  }

  @override
  Future<ReceivedFamilyAlert?> setResolution(
    String key,
    AlertResolution resolution,
  ) async {
    await _ensureLoaded();
    ReceivedFamilyAlert? updated;
    _list.value = [
      for (final a in _list.value)
        a.key == key
            ? (updated = a.copyWith(
                resolution: resolution, resolvedAt: DateTime.now()))
            : a,
    ];
    await _persist();
    return updated;
  }

  @override
  ValueListenable<List<ReceivedFamilyAlert>> get alerts {
    _ensureLoaded();
    return _list;
  }
}

/// Process-wide accessor.
final class ReceivedFamilyAlertLocator {
  ReceivedFamilyAlertLocator._();

  static IReceivedFamilyAlertRepository? _instance;

  static IReceivedFamilyAlertRepository get instance =>
      _instance ??= PersistedReceivedFamilyAlertRepository();

  @visibleForTesting
  static set instance(IReceivedFamilyAlertRepository repo) =>
      _instance = repo;
}
