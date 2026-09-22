import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../services/preferences/app_preferences.dart';

export '../../l10n/generated/app_localizations.dart'
    show AppLocalizations;

/// `context.l10n` — the single accessor for generated localizations.
///
/// Falls back to the globally resolved locale when the widget tree
/// has no Localizations delegates (e.g. a bare MaterialApp in a
/// widget test), so screens stay renderable everywhere.
extension L10nContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? l10nGlobal;
}

/// Context-free accessor resolving the *current* interface locale:
/// the user's pinned preference when set, otherwise the platform
/// locale negotiated against the supported set (English fallback).
///
/// Resolved at call time, so a locale switch is picked up by the next
/// read — which is exactly when widgets rebuild after the preference
/// change. Domain services and non-build code use this; build methods
/// may equally use `context.l10n`.
AppLocalizations get l10n => l10nGlobal;

/// The context-free accessor behind [l10n] — also usable directly.
AppLocalizations get l10nGlobal =>
    lookupAppLocalizations(_resolvedLocale());

Locale _resolvedLocale() {
  final pinned = AppPreferencesLocator.instance.locale;
  if (pinned != null) return pinned;
  Locale? platform;
  try {
    platform = WidgetsBinding.instance.platformDispatcher.locale;
  } catch (_) {
    // No binding (plain unit test / headless service call) — fall
    // through to English rather than crashing a domain path.
  }
  if (platform != null) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == platform.languageCode) {
        return supported;
      }
    }
  }
  return const Locale('en');
}
