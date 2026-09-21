/// Build-configured legal document links for the paywall/settings.
///
/// Defaults point at the GitHub Pages deployment of `web/privacy.html`
/// and `web/terms.html`. Optional dart-define overrides:
///   --dart-define=VOXGUARD_PRIVACY_POLICY_URL=https://...
///   --dart-define=VOXGUARD_TERMS_URL=https://...
///
/// Values are validated as absolute https URLs; an invalid override
/// falls back to null and callers must NOT render dead buttons.
abstract final class LegalLinks {
  LegalLinks._();

  static const String _defaultPrivacy =
      'https://nemesisdevx.github.io/voxguard/privacy.html';
  static const String _defaultTerms =
      'https://nemesisdevx.github.io/voxguard/terms.html';

  static const String _privacyRaw =
      String.fromEnvironment('VOXGUARD_PRIVACY_POLICY_URL');
  static const String _termsRaw =
      String.fromEnvironment('VOXGUARD_TERMS_URL');

  static Uri? get privacyPolicy =>
      _privacyRaw.isEmpty ? _httpsOrNull(_defaultPrivacy) : _httpsOrNull(_privacyRaw);
  static Uri? get terms =>
      _termsRaw.isEmpty ? _httpsOrNull(_defaultTerms) : _httpsOrNull(_termsRaw);

  static Uri? _httpsOrNull(String raw) {
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }
}
