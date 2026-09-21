import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has completed first-run onboarding.
abstract interface class IOnboardingStateStore {
  Future<bool> isCompleted();

  /// Marks the current onboarding version complete — survives
  /// restarts. Future copy changes can bump the version to re-show.
  Future<void> markCompleted();
}

/// SharedPreferences-backed — versioned integer, not a bare boolean,
/// so a future onboarding revision can re-run if needed.
final class PrefsOnboardingStateStore implements IOnboardingStateStore {
  PrefsOnboardingStateStore({SharedPreferences? prefs})
      : _prefs = prefs;

  static const _key = 'voxguard.onboarding_version';
  static const currentVersion = 1;

  final SharedPreferences? _prefs;

  Future<SharedPreferences> get _store =>
      _prefs != null ? Future.value(_prefs) : SharedPreferences.getInstance();

  @override
  Future<bool> isCompleted() async =>
      (await _store).getInt(_key) == currentVersion;

  @override
  Future<void> markCompleted() async {
    await (await _store).setInt(_key, currentVersion);
  }
}

/// Process-wide accessor.
final class OnboardingStateLocator {
  OnboardingStateLocator._();

  static IOnboardingStateStore? _instance;

  static IOnboardingStateStore get instance =>
      _instance ??= PrefsOnboardingStateStore();

  @visibleForTesting
  static set instance(IOnboardingStateStore store) => _instance = store;
}
