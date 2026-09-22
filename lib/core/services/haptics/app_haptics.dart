import 'dart:async';

import 'package:flutter/services.dart';

import '../preferences/app_preferences.dart';

/// Centralized, preference-aware haptics.
///
/// Every app haptic goes through here so the user's `Haptics: Off`
/// preference suppresses feedback globally. Haptics stay restrained
/// and semantically tied to risk/action states — monitoring start,
/// risk-band escalation, important confirmations, Family Shield
/// human responses. Never continuous; never per transcript tick.
abstract final class AppHaptics {
  AppHaptics._();

  /// Significant confirmation — monitoring start, Family Shield
  /// response, important committed action.
  static void confirm([AppPreferences? prefs]) {
    if (!_enabled(prefs)) return;
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Light interactive cue — selection changes, card taps that commit
  /// meaningful state (not every keystroke or transcript tick).
  static void tap([AppPreferences? prefs]) {
    if (!_enabled(prefs)) return;
    unawaited(HapticFeedback.lightImpact());
  }

  /// Risk-band escalation — the strongest cue; reserved for a state
  /// crossing into elevated/high risk.
  static void alert([AppPreferences? prefs]) {
    if (!_enabled(prefs)) return;
    unawaited(HapticFeedback.heavyImpact());
  }

  static bool _enabled(AppPreferences? prefs) =>
      (prefs ?? AppPreferencesLocator.instance).hapticsEnabled;
}
