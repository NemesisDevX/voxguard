import 'package:flutter/foundation.dart';

/// Developer-only integration diagnostics for final live QA.
///
/// Reports which configuration each integration RESOLVED to — never
/// the values themselves. The point is to let a judging/QA build
/// distinguish:
///   not configured → incomplete configuration → configured →
///   provider unreachable / auth failure / timeout (surfaced by each
///   service's safe errors at runtime) → connected →
///   degraded/fallback.
///
/// A fallback/demo backend must NEVER read as a live integration:
/// `demo_store`, `unavailable`, and missing-auth surfaces all report
/// [IntegrationStatus.notConfigured] or
/// [IntegrationStatus.incompleteConfiguration], never `configured`.
///
/// This is intentionally NOT wired into user-facing UI — PauseSignal's
/// truthful provider surfaces are the paywall backend badge and the
/// SafeCall transcription state. Call [debugPrintIntegrationReport]
/// from a debug session or drive [integrationDiagnostics] from tests.
enum IntegrationStatus {
  /// No usable build-time value — the feature must stay off, or the
  /// resolved backend is a fallback/demo surface rather than a live
  /// integration.
  notConfigured,

  /// A partial configuration exists (e.g. a relay URL without the
  /// shared relay token the endpoint requires). The integration will
  /// fail at runtime — QA must not read this as ready.
  incompleteConfiguration,

  /// A complete, live path is configured. Runtime success still
  /// depends on the provider/relay.
  configured,

  /// A development-only escape hatch is armed (e.g. a direct provider
  /// key in the client). Never acceptable in a released build.
  devOnlyArmed,
}

/// One line of the report: what a human checking QA needs to know.
final class IntegrationDiagnostic {
  const IntegrationDiagnostic({
    required this.name,
    required this.status,
    required this.detail,
  });

  /// Stable machine id, e.g. `revenuecat` or `assemblyai.streaming`.
  final String name;

  final IntegrationStatus status;

  /// Sanitised explanation — flags which alternative paths are armed.
  /// Never contains a key, URL credential, or token value.
  final String detail;

  @override
  String toString() => '$name: ${status.name} ($detail)';
}

/// Compile-time presence snapshot — booleans only, values never
/// escape. Construct via [IntegrationConfig.fromEnvironment] for the
/// real build, or by hand in tests to pin every state.
final class IntegrationConfig {
  IntegrationConfig._({
    required this.hasRcAndroidKey,
    required this.hasRcIosKey,
    required this.hasRcTestStoreKey,
    required this.hasAaiBroker,
    required this.hasAaiTempToken,
    required this.hasAaiDevKey,
    required this.hasTranscriptionRelay,
    required this.hasSemanticProxy,
    required this.hasGroqDevKey,
    required this.devRemoteArmed,
    required this.hasOneSignalAppId,
    required this.hasAlertRelay,
    required this.hasRelayToken,
  });

  /// Reads the real `--dart-define` surface. Presence only — the
  /// values themselves are discarded into booleans.
  factory IntegrationConfig.fromEnvironment() => IntegrationConfig._(
        hasRcAndroidKey: String.fromEnvironment('REVENUECAT_ANDROID_KEY') != '',
        hasRcIosKey: String.fromEnvironment('REVENUECAT_IOS_KEY') != '',
        hasRcTestStoreKey:
            String.fromEnvironment('REVENUECAT_TEST_STORE_KEY') != '',
        hasAaiBroker:
            String.fromEnvironment('ASSEMBLYAI_TOKEN_BROKER_URL') != '',
        hasAaiTempToken:
            String.fromEnvironment('ASSEMBLYAI_TEMP_TOKEN') != '',
        hasAaiDevKey: String.fromEnvironment('ASSEMBLYAI_API_KEY') != '',
        hasTranscriptionRelay: String.fromEnvironment(
                'VOXGUARD_RECORDING_TRANSCRIPTION_URL') !=
            '',
        hasSemanticProxy:
            String.fromEnvironment('VOXGUARD_SEMANTIC_PROXY_URL') != '',
        hasGroqDevKey: String.fromEnvironment('GROQ_API_KEY') != '',
        devRemoteArmed: bool.fromEnvironment(
          'VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC',
        ),
        hasOneSignalAppId:
            String.fromEnvironment('ONESIGNAL_APP_ID') != '',
        hasAlertRelay:
            String.fromEnvironment('VOXGUARD_ALERT_RELAY_URL') != '',
        hasRelayToken: String.fromEnvironment('VOXGUARD_RELAY_TOKEN') != '',
      );

  /// Test-visible constructor — pins any combination without
  /// compile-time defines.
  @visibleForTesting
  IntegrationConfig({
    required bool hasRcAndroidKey,
    required bool hasRcIosKey,
    required bool hasRcTestStoreKey,
    required bool hasAaiBroker,
    required bool hasAaiTempToken,
    required bool hasAaiDevKey,
    required bool hasTranscriptionRelay,
    required bool hasSemanticProxy,
    required bool hasGroqDevKey,
    required bool devRemoteArmed,
    required bool hasOneSignalAppId,
    required bool hasAlertRelay,
    required bool hasRelayToken,
  }) : this._(
          hasRcAndroidKey: hasRcAndroidKey,
          hasRcIosKey: hasRcIosKey,
          hasRcTestStoreKey: hasRcTestStoreKey,
          hasAaiBroker: hasAaiBroker,
          hasAaiTempToken: hasAaiTempToken,
          hasAaiDevKey: hasAaiDevKey,
          hasTranscriptionRelay: hasTranscriptionRelay,
          hasSemanticProxy: hasSemanticProxy,
          hasGroqDevKey: hasGroqDevKey,
          devRemoteArmed: devRemoteArmed,
          hasOneSignalAppId: hasOneSignalAppId,
          hasAlertRelay: hasAlertRelay,
          hasRelayToken: hasRelayToken,
        );

  final bool hasRcAndroidKey;
  final bool hasRcIosKey;
  final bool hasRcTestStoreKey;
  final bool hasAaiBroker;
  final bool hasAaiTempToken;
  final bool hasAaiDevKey;
  final bool hasTranscriptionRelay;
  final bool hasSemanticProxy;
  final bool hasGroqDevKey;
  final bool devRemoteArmed;
  final bool hasOneSignalAppId;
  final bool hasAlertRelay;
  final bool hasRelayToken;
}

/// The backend the purchase factory will resolve for THIS build mode
/// on the given platform — mirrors `createPurchaseServiceFor`'s order.
String resolvedPurchaseBackendLabel(
  TargetPlatform platform, {
  IntegrationConfig? config,
  bool? isRelease,
}) {
  final c = config ?? IntegrationConfig.fromEnvironment();
  final isStorePlatform = platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;
  if (!isStorePlatform) return 'demo_store';
  final hasPlatformKey = platform == TargetPlatform.android
      ? c.hasRcAndroidKey
      : c.hasRcIosKey;
  if (hasPlatformKey) return 'real_store';
  if (isRelease ?? kReleaseMode) return 'unavailable';
  if (c.hasRcTestStoreKey) return 'test_store';
  return 'demo_store';
}

/// Snapshot of every integration's resolved configuration.
/// [platform] and [config] are parameters so tests can pin every
/// branch without depending on the host platform or compile-time
/// defines; null/omitted uses the real values.
List<IntegrationDiagnostic> integrationDiagnostics({
  TargetPlatform? platform,
  IntegrationConfig? config,
  bool? isRelease,
}) {
  final c = config ?? IntegrationConfig.fromEnvironment();
  final purchaseBackend = resolvedPurchaseBackendLabel(
    platform ?? defaultTargetPlatform,
    config: c,
    isRelease: isRelease,
  );
  return [
    IntegrationDiagnostic(
      name: 'revenuecat',
      // Only REAL RevenueCat backends count as configured — the local
      // Demo Store and the unavailable backend are truthful fallbacks,
      // never live integrations.
      status: purchaseBackend == 'test_store' ||
              purchaseBackend == 'real_store'
          ? IntegrationStatus.configured
          : IntegrationStatus.notConfigured,
      detail: 'backend=$purchaseBackend',
    ),
    IntegrationDiagnostic(
      name: 'assemblyai.streaming',
      status: _assemblyAiStreamingStatus(c),
      detail: _assemblyAiStreamingDetail(c),
    ),
    IntegrationDiagnostic(
      name: 'assemblyai.recording',
      status: _has(c.hasTranscriptionRelay, c.hasRelayToken),
      detail: c.hasTranscriptionRelay
          ? (c.hasRelayToken ? 'relay+token' : 'relay set, token MISSING')
          : 'none',
    ),
    IntegrationDiagnostic(
      name: 'groq.semantic',
      status: _groqSemanticStatus(c, isRelease ?? kReleaseMode),
      detail: _groqSemanticDetail(c, isRelease ?? kReleaseMode),
    ),
    IntegrationDiagnostic(
      name: 'onesignal.identity',
      status: c.hasOneSignalAppId
          ? IntegrationStatus.configured
          : IntegrationStatus.notConfigured,
      detail: c.hasOneSignalAppId ? 'app-id set' : 'none',
    ),
    IntegrationDiagnostic(
      name: 'family_shield.relay',
      status: _has(c.hasAlertRelay, c.hasRelayToken),
      detail: c.hasAlertRelay
          ? (c.hasRelayToken ? 'relay+token' : 'relay set, token MISSING')
          : 'none',
    ),
  ];
}

/// URL + token both present → configured; URL alone → incomplete.
IntegrationStatus _has(bool url, bool token) => url && token
    ? IntegrationStatus.configured
    : url
        ? IntegrationStatus.incompleteConfiguration
        : IntegrationStatus.notConfigured;

IntegrationStatus _assemblyAiStreamingStatus(IntegrationConfig c) {
  if (c.hasAaiBroker) {
    // The broker endpoint enforces relay auth — a URL without the
    // shared token will only produce 401s.
    return c.hasRelayToken
        ? IntegrationStatus.configured
        : IntegrationStatus.incompleteConfiguration;
  }
  if (c.hasAaiTempToken) return IntegrationStatus.devOnlyArmed;
  if (c.hasAaiDevKey) return IntegrationStatus.devOnlyArmed;
  return IntegrationStatus.notConfigured;
}

String _assemblyAiStreamingDetail(IntegrationConfig c) => c.hasAaiBroker
    ? (c.hasRelayToken ? 'brokered-token' : 'broker set, token MISSING')
    : c.hasAaiTempToken
        ? 'static-temp-token (non-release only)'
        : c.hasAaiDevKey
            ? 'dev-api-key (never ship)'
            : 'none';

IntegrationStatus _groqSemanticStatus(IntegrationConfig c, bool isRelease) {
  if (c.hasSemanticProxy) {
    // The proxy endpoint enforces relay auth — a URL without the
    // shared token will only produce 401s.
    return c.hasRelayToken
        ? IntegrationStatus.configured
        : IntegrationStatus.incompleteConfiguration;
  }
  // The direct-key path is hard-disabled in release — it can never be
  // "armed" there even when the defines are present.
  if (!isRelease && c.hasGroqDevKey && c.devRemoteArmed) {
    return IntegrationStatus.devOnlyArmed;
  }
  return IntegrationStatus.notConfigured;
}

String _groqSemanticDetail(IntegrationConfig c, bool isRelease) =>
    c.hasSemanticProxy
        ? (c.hasRelayToken ? 'proxy+token' : 'proxy set, token MISSING')
        : (!isRelease && c.hasGroqDevKey && c.devRemoteArmed)
            ? 'dev-direct-key (never ship)'
            : 'local-rules-only';

/// Debug-build-only report — `debugPrint` is itself a no-op in
/// release, and the guard keeps the call sites honest.
void debugPrintIntegrationReport({TargetPlatform? platform}) {
  if (!kDebugMode) return;
  debugPrint('─ PauseSignal integration diagnostics ─');
  for (final d in integrationDiagnostics(platform: platform)) {
    debugPrint('  $d');
  }
}
