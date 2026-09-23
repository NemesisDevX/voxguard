import 'package:flutter/foundation.dart';

/// Developer-only integration diagnostics for final live QA.
///
/// Reports which configuration each integration RESOLVED to — never
/// the values themselves. The point is to let a judging/QA build
/// distinguish:
///   not configured → configured → provider unreachable / auth
///   failure / timeout (surfaced by each service's safe errors at
///   runtime) → connected → degraded/fallback.
///
/// This is intentionally NOT wired into user-facing UI — PauseSignal's
/// truthful provider surfaces are the paywall backend badge and the
/// SafeCall transcription state. Call [debugPrintIntegrationReport]
/// from a debug session or drive [integrationDiagnostics] from tests.
enum IntegrationStatus {
  /// No build-time value supplied — the feature must stay off.
  notConfigured,

  /// A value is present and the integration will attempt to use it.
  /// Runtime success still depends on the provider/relay.
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

// Compile-time presence flags — booleans only, values never escape.
const _hasRcAndroidKey =
    String.fromEnvironment('REVENUECAT_ANDROID_KEY') != '';
const _hasRcIosKey =
    String.fromEnvironment('REVENUECAT_IOS_KEY') != '';
const _hasRcTestStoreKey =
    String.fromEnvironment('REVENUECAT_TEST_STORE_KEY') != '';
const _hasAaiBroker =
    String.fromEnvironment('ASSEMBLYAI_TOKEN_BROKER_URL') != '';
const _hasAaiTempToken =
    String.fromEnvironment('ASSEMBLYAI_TEMP_TOKEN') != '';
const _hasAaiDevKey =
    String.fromEnvironment('ASSEMBLYAI_API_KEY') != '';
const _hasTranscriptionRelay =
    String.fromEnvironment('VOXGUARD_RECORDING_TRANSCRIPTION_URL') != '';
const _hasSemanticProxy =
    String.fromEnvironment('VOXGUARD_SEMANTIC_PROXY_URL') != '';
const _hasGroqDevKey =
    String.fromEnvironment('GROQ_API_KEY') != '';
const _devRemoteArmed = bool.fromEnvironment(
  'VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC',
  defaultValue: false,
);
const _hasOneSignalAppId =
    String.fromEnvironment('ONESIGNAL_APP_ID') != '';
const _hasAlertRelay =
    String.fromEnvironment('VOXGUARD_ALERT_RELAY_URL') != '';
const _hasRelayToken =
    String.fromEnvironment('VOXGUARD_RELAY_TOKEN') != '';

/// The backend the purchase factory will resolve for THIS build mode
/// on the given platform — mirrors `createPurchaseServiceFor`'s order.
String resolvedPurchaseBackendLabel(TargetPlatform platform) {
  final isStorePlatform = platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;
  if (!isStorePlatform) return 'demo_store';
  final hasPlatformKey = platform == TargetPlatform.android
      ? _hasRcAndroidKey
      : _hasRcIosKey;
  if (hasPlatformKey) return 'real_store';
  if (kReleaseMode) return 'unavailable';
  if (_hasRcTestStoreKey) return 'test_store';
  return 'demo_store';
}

/// Snapshot of every integration's resolved configuration.
/// [platform] is a parameter so tests can pin both branches without
/// depending on the host platform; null uses the real platform.
List<IntegrationDiagnostic> integrationDiagnostics({
  TargetPlatform? platform,
}) {
  final purchaseBackend =
      resolvedPurchaseBackendLabel(platform ?? defaultTargetPlatform);
  return [
    IntegrationDiagnostic(
      name: 'revenuecat',
      status: purchaseBackend == 'unavailable'
          ? IntegrationStatus.notConfigured
          : IntegrationStatus.configured,
      detail: 'backend=$purchaseBackend',
    ),
    IntegrationDiagnostic(
      name: 'assemblyai.streaming',
      status: _hasAaiBroker || _hasAaiTempToken
          ? IntegrationStatus.configured
          : _hasAaiDevKey
              ? IntegrationStatus.devOnlyArmed
              : IntegrationStatus.notConfigured,
      detail: _hasAaiBroker
          ? 'brokered-token'
          : _hasAaiTempToken
              ? 'static-temp-token'
              : _hasAaiDevKey
                  ? 'dev-api-key (never ship)'
                  : 'none',
    ),
    IntegrationDiagnostic(
      name: 'assemblyai.recording',
      status: _hasTranscriptionRelay && _hasRelayToken
          ? IntegrationStatus.configured
          : IntegrationStatus.notConfigured,
      detail: _hasTranscriptionRelay
          ? (_hasRelayToken ? 'relay+token' : 'relay set, token MISSING')
          : 'none',
    ),
    IntegrationDiagnostic(
      name: 'groq.semantic',
      status: _hasSemanticProxy
          ? IntegrationStatus.configured
          : (_hasGroqDevKey && _devRemoteArmed)
              ? IntegrationStatus.devOnlyArmed
              : IntegrationStatus.notConfigured,
      detail: _hasSemanticProxy
          ? (_hasRelayToken ? 'proxy+token' : 'proxy set, token MISSING')
          : (_hasGroqDevKey && _devRemoteArmed)
              ? 'dev-direct-key (never ship)'
              : 'local-rules-only',
    ),
    IntegrationDiagnostic(
      name: 'onesignal.identity',
      status: _hasOneSignalAppId
          ? IntegrationStatus.configured
          : IntegrationStatus.notConfigured,
      detail: _hasOneSignalAppId ? 'app-id set' : 'none',
    ),
    IntegrationDiagnostic(
      name: 'family_shield.relay',
      status: _hasAlertRelay && _hasRelayToken
          ? IntegrationStatus.configured
          : IntegrationStatus.notConfigured,
      detail: _hasAlertRelay
          ? (_hasRelayToken ? 'relay+token' : 'relay set, token MISSING')
          : 'none',
    ),
  ];
}

/// Debug-build-only report — `debugPrint` is itself a no-op in
/// release, and the guard keeps the call sites honest.
void debugPrintIntegrationReport({TargetPlatform? platform}) {
  if (!kDebugMode) return;
  debugPrint('─ PauseSignal integration diagnostics ─');
  for (final d in integrationDiagnostics(platform: platform)) {
    debugPrint('  $d');
  }
}
