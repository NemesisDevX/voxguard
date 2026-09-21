/// Build-configured legal document links for the paywall/settings.
///
/// Supplied via dart-defines:
///   --dart-define=VOXGUARD_PRIVACY_POLICY_URL=https://...
///   --dart-define=VOXGUARD_TERMS_URL=https://...
///
/// Both are validated as absolute https URLs; when absent or invalid
/// the getters return null and callers must NOT render dead buttons.
/// Production URLs are locked in during the release sprint.
abstract final class LegalLinks {
  LegalLinks._();

  static const String _privacyRaw =
      String.fromEnvironment('VOXGUARD_PRIVACY_POLICY_URL');
  static const String _termsRaw =
      String.fromEnvironment('VOXGUARD_TERMS_URL');

  static Uri? get privacyPolicy => _httpsOrNull(_privacyRaw);
  static Uri? get terms => _httpsOrNull(_termsRaw);

  static Uri? _httpsOrNull(String raw) {
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }
}
