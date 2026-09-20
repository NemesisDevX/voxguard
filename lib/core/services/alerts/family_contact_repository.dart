import 'package:flutter/foundation.dart';

/// A family member reachable by Family Shield alerts.
///
/// [externalId] is the alias the notification relay uses to route the
/// push — in production it maps to a OneSignal `external_id`. Names
/// and ids are user-supplied preferences, not secrets, so local
/// persistence is acceptable.
final class FamilyContact {
  const FamilyContact({required this.name, required this.externalId});

  final String name;
  final String externalId;
}

/// Source of family contacts for the Family Shield broadcast flow.
///
/// Production builds would back this with the user's configured
/// contacts (local store + optional sync). This codebase ships an
/// explicitly-named demo implementation — no fake production identity
/// infrastructure.
abstract interface class IFamilyContactRepository {
  /// Contacts that receive Family Shield broadcasts.
  Future<List<FamilyContact>> getFamilyContacts();
}

/// Demo contact list used when no production contact backend exists.
/// Clearly labelled — contacts appear as "… (Demo)" in the UI.
///
/// **Dev/test override:** for the two-device smoke test, a real
/// `vg_…` External ID from Device B can be injected via
/// `--dart-define=VOXGUARD_TEST_FAMILY_EXTERNAL_ID=vg_…` or set at
/// runtime through [testRecipientOverride]. When present, it replaces
/// the demo contacts so the alert targets a real device.
final class DemoFamilyContactRepository implements IFamilyContactRepository {
  const DemoFamilyContactRepository();

  static const _demoContacts = [
    FamilyContact(name: 'Maya (Demo)', externalId: 'demo_family_maya'),
    FamilyContact(name: 'Omar (Demo)', externalId: 'demo_family_omar'),
  ];

  static const _envOverride = String.fromEnvironment(
    'VOXGUARD_TEST_FAMILY_EXTERNAL_ID',
    defaultValue: '',
  );

  /// Runtime override (set from the Settings dev field). Cleared on
  /// restart unless seeded via the dart-define.
  static String? _runtimeOverride;

  /// Registers a dev/test recipient — pass null/empty to clear.
  static void setTestRecipientOverride(String? externalId) {
    _runtimeOverride =
        (externalId == null || externalId.trim().isEmpty)
            ? null
            : externalId.trim();
  }

  static String? get _override =>
      _runtimeOverride ?? (_envOverride.isEmpty ? null : _envOverride);

  @override
  Future<List<FamilyContact>> getFamilyContacts() async {
    final override = _override;
    if (override != null) {
      return [FamilyContact(name: 'Test Device (Dev)', externalId: override)];
    }
    return _demoContacts;
  }
}

/// Process-wide accessor for the contact repository.
final class FamilyContactLocator {
  FamilyContactLocator._();

  static IFamilyContactRepository? _instance;

  static IFamilyContactRepository get instance =>
      _instance ??= const DemoFamilyContactRepository();

  @visibleForTesting
  static set instance(IFamilyContactRepository repo) => _instance = repo;
}
