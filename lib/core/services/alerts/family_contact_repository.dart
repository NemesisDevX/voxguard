import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';

/// A trusted person reachable by Family Shield alerts.
///
/// [externalId] is the opaque `vg_…` PauseSignal identity the relay
/// targets via OneSignal `external_id` — never a phone number, email
/// or name. [trustedPhone] is local contact metadata only: it is
/// stored on-device, never sent to the relay and never included in a
/// notification payload.
final class FamilyContact {
  const FamilyContact({
    required this.id,
    required this.name,
    required this.externalId,
    this.trustedPhone,
    required this.updatedAt,
  });

  /// Stable local identifier (`fc_…`), independent of the person's
  /// PauseSignal identity.
  final String id;

  /// User-supplied display name. Local only.
  final String name;

  /// Their `vg_…` Family Shield ID — the only field that crosses the
  /// network boundary.
  final String externalId;

  /// Optional phone number for the user's own verification calls.
  /// Never leaves this device.
  final String? trustedPhone;

  final DateTime updatedAt;

  FamilyContact copyWith({
    String? name,
    String? externalId,
    String? trustedPhone,
    bool clearPhone = false,
  }) =>
      FamilyContact(
        id: id,
        name: name ?? this.name,
        externalId: externalId ?? this.externalId,
        trustedPhone: clearPhone ? null : (trustedPhone ?? this.trustedPhone),
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'external_id': externalId,
        if (trustedPhone != null) 'trusted_phone': trustedPhone,
        'updated_at': updatedAt.toIso8601String(),
      };

  static FamilyContact? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final externalId = json['external_id'];
    final phone = json['trusted_phone'];
    final updatedAt = DateTime.tryParse('${json['updated_at'] ?? ''}');
    if (id is! String || name is! String || externalId is! String) {
      return null;
    }
    return FamilyContact(
      id: id,
      name: name,
      externalId: externalId,
      trustedPhone: phone is String ? phone : null,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Rejection reason surfaced to the Trusted Circle UI.
final class FamilyContactException implements Exception {
  const FamilyContactException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Source of family contacts for the Family Shield broadcast flow.
abstract interface class IFamilyContactRepository {
  /// Contacts that receive Family Shield broadcasts.
  Future<List<FamilyContact>> getFamilyContacts();

  /// Reactive contact list — drives the Trusted Circle UI.
  ValueListenable<List<FamilyContact>> get contacts;

  /// Adds a person. Throws [FamilyContactException] on invalid input,
  /// duplicate External ID, or when the circle is already full.
  Future<FamilyContact> add({
    required String name,
    required String externalId,
    String? trustedPhone,
  });

  /// Updates fields of an existing contact.
  Future<void> update(
    String id, {
    String? name,
    String? externalId,
    String? trustedPhone,
    bool clearPhone = false,
  });

  /// Removes a contact by local id.
  Future<void> remove(String id);
}

/// Shared validation for contact fields.
final class FamilyContactRules {
  FamilyContactRules._();

  /// Family Shield External IDs are exactly `vg_<32 lowercase hex>`.
  static final externalIdPattern = RegExp(r'^vg_[0-9a-f]{32}$');

  /// Local contact ids minted by this app (`fc_` + 16 hex chars).
  static final localIdPattern = RegExp(r'^fc_[0-9a-f]{16}$');

  /// Trusted phone numbers are local metadata — bounded length only.
  static const maxPhoneLength = 32;

  /// The Trusted Circle is hard-capped at 5 — same bound the relay
  /// enforces on `family_external_ids`.
  static const maxContacts = 5;

  /// A persisted/external contact is only trusted when every field
  /// passes — corrupted rows are skipped, never repaired into fake
  /// contacts.
  static bool isWellFormed(FamilyContact c) =>
      localIdPattern.hasMatch(c.id) &&
      c.name.trim().isNotEmpty &&
      externalIdPattern.hasMatch(c.externalId) &&
      (c.trustedPhone == null ||
          c.trustedPhone!.length <= maxPhoneLength);

  static void validateFields({
    required String name,
    required String externalId,
    String? trustedPhone,
  }) {
    if (name.trim().isEmpty) {
      throw FamilyContactException(l10n.msgNameRequired);
    }
    if (!externalIdPattern.hasMatch(externalId.trim())) {
      throw FamilyContactException(l10n.msgFamilyIdInvalid);
    }
    if (trustedPhone != null &&
        trustedPhone.length > FamilyContactRules.maxPhoneLength) {
      throw const FamilyContactException('Phone number is too long.');
    }
  }
}

String _newContactId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(8, (_) => rng.nextInt(256));
  return 'fc_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

/// Real, persisted Trusted Circle — SharedPreferences-backed, no
/// database dependency. Survives restarts; drives the production
/// Family Shield recipient list.
final class PersistedFamilyContactRepository
    implements IFamilyContactRepository {
  PersistedFamilyContactRepository({SharedPreferences? prefs})
      : _prefs = prefs;

  static const _key = 'voxguard.trusted_circle';

  /// Injectable for tests; lazy-resolved otherwise.
  final SharedPreferences? _prefs;

  final _list = ValueNotifier<List<FamilyContact>>(const []);

  /// Shared in-flight load — concurrent first readers await the same
  /// persistence read instead of observing a premature empty list.
  Future<void>? _loadFuture;

  /// Dev/test recipient override for the two-device smoke test —
  /// `VOXGUARD_TEST_FAMILY_EXTERNAL_ID` dart-define or the debug
  /// Settings field. When set it replaces the persisted circle.
  static const _envOverride = String.fromEnvironment(
    'VOXGUARD_TEST_FAMILY_EXTERNAL_ID',
    defaultValue: '',
  );
  static String? _runtimeOverride;

  /// Registers a dev/test recipient — pass null/empty to clear.
  static void setTestRecipientOverride(String? externalId) {
    _runtimeOverride =
        (externalId == null || externalId.trim().isEmpty)
            ? null
            : externalId.trim();
  }

  /// The dev/test override only counts when it is a real `vg_…`
  /// identity — a malformed value is ignored rather than sent to the
  /// relay.
  static String? get _override {
    final v = _runtimeOverride ?? (_envOverride.isEmpty ? null : _envOverride);
    return v != null && FamilyContactRules.externalIdPattern.hasMatch(v)
        ? v
        : null;
  }

  Future<SharedPreferences> get _store =>
      _prefs != null ? Future.value(_prefs) : SharedPreferences.getInstance();

  Future<void> _ensureLoaded() => _loadFuture ??= _doLoad();

  Future<void> _doLoad() async {
    final raw = (await _store).getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      // Sanitize: keep only well-formed contacts, dedupe by external
      // id, never load more than the cap. Corrupted rows are skipped.
      final seen = <String>{};
      final list = <FamilyContact>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final c = FamilyContact.fromJson(e);
        if (c == null ||
            !FamilyContactRules.isWellFormed(c) ||
            !seen.add(c.externalId)) {
          continue;
        }
        if (list.length >= FamilyContactRules.maxContacts) break;
        list.add(c);
      }
      _list.value = list;
    } on FormatException {
      // Corrupted payload → start clean rather than crash.
      _list.value = const [];
    }
  }

  Future<void> _persist() async {
    await (await _store).setString(
      _key,
      jsonEncode([for (final c in _list.value) c.toJson()]),
    );
  }

  @override
  ValueListenable<List<FamilyContact>> get contacts {
    // First listener → load persisted circle (updates _list async).
    _ensureLoaded();
    return _list;
  }

  @override
  Future<List<FamilyContact>> getFamilyContacts() async {
    // Dev/test override still wins — the smoke test targets one real
    // device without touching the persisted circle.
    final override = _override;
    if (override != null) {
      return [
        FamilyContact(
          id: 'fc_dev_override',
          name: 'Test Device (Dev)',
          externalId: override,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ];
    }
    await _ensureLoaded();
    return _list.value;
  }

  @override
  Future<FamilyContact> add({
    required String name,
    required String externalId,
    String? trustedPhone,
  }) async {
    await _ensureLoaded();
    FamilyContactRules.validateFields(
      name: name,
      externalId: externalId,
      trustedPhone: trustedPhone,
    );
    final ext = externalId.trim();
    if (_list.value.length >= FamilyContactRules.maxContacts) {
      throw const FamilyContactException(
        'Trusted Circle is full (5 people). Remove someone first.',
      );
    }
    if (_list.value.any((c) => c.externalId == ext)) {
      throw const FamilyContactException(
        'That Family Shield ID is already in your Trusted Circle.',
      );
    }
    final contact = FamilyContact(
      id: _newContactId(),
      name: name.trim(),
      externalId: ext,
      trustedPhone:
          (trustedPhone == null || trustedPhone.trim().isEmpty)
              ? null
              : trustedPhone.trim(),
      updatedAt: DateTime.now(),
    );
    _list.value = [..._list.value, contact];
    await _persist();
    return contact;
  }

  @override
  Future<void> update(
    String id, {
    String? name,
    String? externalId,
    String? trustedPhone,
    bool clearPhone = false,
  }) async {
    await _ensureLoaded();
    final idx = _list.value.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final nextName = name?.trim() ?? _list.value[idx].name;
    final nextExt = externalId?.trim() ?? _list.value[idx].externalId;
    final nextPhone = clearPhone
        ? null
        : (trustedPhone?.trim().isEmpty ?? true
            ? _list.value[idx].trustedPhone
            : trustedPhone!.trim());
    FamilyContactRules.validateFields(
      name: nextName,
      externalId: nextExt,
      trustedPhone: nextPhone,
    );
    if (_list.value.any((c) => c.id != id && c.externalId == nextExt)) {
      throw const FamilyContactException(
        'That Family Shield ID is already in your Trusted Circle.',
      );
    }
    final updated = _list.value[idx].copyWith(
      name: nextName,
      externalId: nextExt,
      trustedPhone: nextPhone,
      clearPhone: clearPhone,
    );
    _list.value = [
      for (final c in _list.value) c.id == id ? updated : c,
    ];
    await _persist();
  }

  @override
  Future<void> remove(String id) async {
    await _ensureLoaded();
    _list.value = [for (final c in _list.value) if (c.id != id) c];
    await _persist();
  }
}

/// Demo contact list for explicit Demo Mode only — never a
/// production recipient source. Contacts appear as "… (Demo)".
final class DemoFamilyContactRepository implements IFamilyContactRepository {
  const DemoFamilyContactRepository();

  static final _demoContacts = [
    FamilyContact(
      id: 'fc_demo_maya',
      name: 'Maya (Demo)',
      externalId: 'demo_family_maya',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    FamilyContact(
      id: 'fc_demo_omar',
      name: 'Omar (Demo)',
      externalId: 'demo_family_omar',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];

  @override
  ValueListenable<List<FamilyContact>> get contacts =>
      ValueNotifier(_demoContacts);

  @override
  Future<List<FamilyContact>> getFamilyContacts() async => _demoContacts;

  @override
  Future<FamilyContact> add({
    required String name,
    required String externalId,
    String? trustedPhone,
  }) =>
      throw UnsupportedError('Demo contacts are read-only');

  @override
  Future<void> update(
    String id, {
    String? name,
    String? externalId,
    String? trustedPhone,
    bool clearPhone = false,
  }) =>
      throw UnsupportedError('Demo contacts are read-only');

  @override
  Future<void> remove(String id) =>
      throw UnsupportedError('Demo contacts are read-only');
}

/// Process-wide accessor for the contact repository.
final class FamilyContactLocator {
  FamilyContactLocator._();

  static IFamilyContactRepository? _instance;

  /// Production default is the persisted Trusted Circle — demo
  /// contacts are only used when the alert service itself is in
  /// Demo Mode (no relay configured).
  static IFamilyContactRepository get instance =>
      _instance ??= PersistedFamilyContactRepository();

  @visibleForTesting
  static set instance(IFamilyContactRepository repo) => _instance = repo;
}
