import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistence for the local PauseSignal identity (`vg_…`).
abstract interface class IIdentityStore {
  Future<String?> read();
  Future<void> write(String id);
  Future<void> clear();
}

/// Generates a privacy-minimal opaque identity: `vg_<32 hex chars>`
/// from a CSPRNG. Not an account — just a stable local identifier the
/// relay can target via OneSignal `external_id`.
String generateVoxGuardIdentity() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return 'vg_$hex';
}

/// SharedPreferences-backed store — survives restarts.
final class SharedPrefsIdentityStore implements IIdentityStore {
  static const _key = 'voxguard.family_shield_id';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// In-memory store for tests.
final class InMemoryIdentityStore implements IIdentityStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String id) async => value = id;

  @override
  Future<void> clear() async => value = null;
}
