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
final class DemoFamilyContactRepository implements IFamilyContactRepository {
  const DemoFamilyContactRepository();

  static const _demoContacts = [
    FamilyContact(name: 'Maya (Demo)', externalId: 'demo_family_maya'),
    FamilyContact(name: 'Omar (Demo)', externalId: 'demo_family_omar'),
  ];

  @override
  Future<List<FamilyContact>> getFamilyContacts() async => _demoContacts;
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
