import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/core/diagnostics/integration_diagnostics.dart';

/// All-off baseline — tests flip individual flags.
final _none = IntegrationConfig(
  hasRcAndroidKey: false,
  hasRcIosKey: false,
  hasRcTestStoreKey: false,
  hasAaiBroker: false,
  hasAaiTempToken: false,
  hasAaiDevKey: false,
  hasTranscriptionRelay: false,
  hasSemanticProxy: false,
  hasGroqDevKey: false,
  devRemoteArmed: false,
  hasOneSignalAppId: false,
  hasAlertRelay: false,
  hasRelayToken: false,
);

IntegrationConfig _cfg({
  bool hasRcAndroidKey = false,
  bool hasRcIosKey = false,
  bool hasRcTestStoreKey = false,
  bool hasAaiBroker = false,
  bool hasAaiTempToken = false,
  bool hasAaiDevKey = false,
  bool hasTranscriptionRelay = false,
  bool hasSemanticProxy = false,
  bool hasGroqDevKey = false,
  bool devRemoteArmed = false,
  bool hasOneSignalAppId = false,
  bool hasAlertRelay = false,
  bool hasRelayToken = false,
}) =>
    IntegrationConfig(
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

IntegrationDiagnostic _byName(
        List<IntegrationDiagnostic> report, String name) =>
    report.firstWhere((d) => d.name == name);

void main() {
  group('integrationDiagnostics', () {
    test('reports every integration surface', () {
      final report = integrationDiagnostics(
        platform: TargetPlatform.android,
      );
      final names = report.map((d) => d.name).toSet();
      expect(
        names,
        containsAll({
          'revenuecat',
          'assemblyai.streaming',
          'assemblyai.recording',
          'groq.semantic',
          'onesignal.identity',
          'family_shield.relay',
        }),
      );
    });

    test('non-store platforms resolve the demo store backend', () {
      expect(
        resolvedPurchaseBackendLabel(
          TargetPlatform.windows,
          config: _none,
          isRelease: false,
        ),
        'demo_store',
      );
    });

    // ── RevenueCat truth: only real RevenueCat backends count ─────

    test('revenuecat test_store → configured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasRcTestStoreKey: true),
          isRelease: false,
        ),
        'revenuecat',
      );
      expect(d.status, IntegrationStatus.configured);
      expect(d.detail, 'backend=test_store');
    });

    test('revenuecat real_store → configured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasRcAndroidKey: true),
          isRelease: true,
        ),
        'revenuecat',
      );
      expect(d.status, IntegrationStatus.configured);
      expect(d.detail, 'backend=real_store');
    });

    test('revenuecat demo_store → notConfigured (demo is never a '
        'live integration)', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _none,
          isRelease: false,
        ),
        'revenuecat',
      );
      expect(d.status, IntegrationStatus.notConfigured);
      expect(d.detail, 'backend=demo_store');
    });

    test('revenuecat unavailable (release, no key) → notConfigured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _none,
          isRelease: true,
        ),
        'revenuecat',
      );
      expect(d.status, IntegrationStatus.notConfigured);
      expect(d.detail, 'backend=unavailable');
    });

    test('release + test-store key only → unavailable backend, '
        'notConfigured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasRcTestStoreKey: true),
          isRelease: true,
        ),
        'revenuecat',
      );
      expect(d.status, IntegrationStatus.notConfigured);
      expect(d.detail, 'backend=unavailable');
    });

    // ── AssemblyAI streaming: broker needs the relay token ────────

    test('broker + relay token → configured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasAaiBroker: true, hasRelayToken: true),
          isRelease: false,
        ),
        'assemblyai.streaming',
      );
      expect(d.status, IntegrationStatus.configured);
      expect(d.detail, 'brokered-token');
    });

    test('broker without relay token → incompleteConfiguration '
        '(endpoint would 401)', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasAaiBroker: true),
          isRelease: false,
        ),
        'assemblyai.streaming',
      );
      expect(d.status, IntegrationStatus.incompleteConfiguration);
      expect(d.detail, contains('token MISSING'));
    });

    test('temp token or dev key alone → devOnlyArmed, never '
        'configured', () {
      for (final c in [
        _cfg(hasAaiTempToken: true),
        _cfg(hasAaiDevKey: true),
      ]) {
        final d = _byName(
          integrationDiagnostics(
            platform: TargetPlatform.android,
            config: c,
            isRelease: false,
          ),
          'assemblyai.streaming',
        );
        expect(d.status, IntegrationStatus.devOnlyArmed);
      }
    });

    // Diagnostics must mirror resolveTranscriptionTokenProvider —
    // dev credentials are IGNORED in release, never "armed".
    test('release + only temp token → notConfigured (ignored)', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasAaiTempToken: true),
          isRelease: true,
        ),
        'assemblyai.streaming',
      );
      expect(d.status, IntegrationStatus.notConfigured);
      expect(d.detail, 'dev credential present but ignored in release');
    });

    test('release + only API key → notConfigured (ignored)', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasAaiDevKey: true),
          isRelease: true,
        ),
        'assemblyai.streaming',
      );
      expect(d.status, IntegrationStatus.notConfigured);
      expect(d.detail, 'dev credential present but ignored in release');
    });

    test('release + broker + token → still configured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasAaiBroker: true, hasRelayToken: true),
          isRelease: true,
        ),
        'assemblyai.streaming',
      );
      expect(d.status, IntegrationStatus.configured);
    });

    test('release + broker without token → incompleteConfiguration',
        () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasAaiBroker: true),
          isRelease: true,
        ),
        'assemblyai.streaming',
      );
      expect(d.status, IntegrationStatus.incompleteConfiguration);
    });

    test('release + nothing → notConfigured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _none,
          isRelease: true,
        ),
        'assemblyai.streaming',
      );
      expect(d.status, IntegrationStatus.notConfigured);
      expect(d.detail, 'none');
    });

    // ── Groq semantic: proxy needs the relay token; dev path is
    //    release-disabled ──────────────────────────────────────────

    test('proxy + relay token → configured', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasSemanticProxy: true, hasRelayToken: true),
          isRelease: true,
        ),
        'groq.semantic',
      );
      expect(d.status, IntegrationStatus.configured);
      expect(d.detail, 'proxy+token');
    });

    test('proxy without relay token → incompleteConfiguration', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasSemanticProxy: true),
          isRelease: false,
        ),
        'groq.semantic',
      );
      expect(d.status, IntegrationStatus.incompleteConfiguration);
      expect(d.detail, contains('token MISSING'));
    });

    test('debug + direct key + opt-in → devOnlyArmed', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasGroqDevKey: true, devRemoteArmed: true),
          isRelease: false,
        ),
        'groq.semantic',
      );
      expect(d.status, IntegrationStatus.devOnlyArmed);
      expect(d.detail, contains('never ship'));
    });

    test('release + direct key + opt-in → NOT armed — the direct path '
        'is disabled in release', () {
      final d = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasGroqDevKey: true, devRemoteArmed: true),
          isRelease: true,
        ),
        'groq.semantic',
      );
      expect(d.status, IntegrationStatus.notConfigured);
      expect(d.detail, 'local-rules-only');
    });

    // ── Relay-backed surfaces pair URL + token ─────────────────────

    test('recording relay + token → configured; url alone → '
        'incompleteConfiguration', () {
      expect(
        _byName(
          integrationDiagnostics(
            platform: TargetPlatform.android,
            config:
                _cfg(hasTranscriptionRelay: true, hasRelayToken: true),
            isRelease: false,
          ),
          'assemblyai.recording',
        ).status,
        IntegrationStatus.configured,
      );
      expect(
        _byName(
          integrationDiagnostics(
            platform: TargetPlatform.android,
            config: _cfg(hasTranscriptionRelay: true),
            isRelease: false,
          ),
          'assemblyai.recording',
        ).status,
        IntegrationStatus.incompleteConfiguration,
      );
    });

    test('OneSignal App ID alone → identity configured; family relay '
        'still independently requires url + token', () {
      final report = integrationDiagnostics(
        platform: TargetPlatform.android,
        config: _cfg(hasOneSignalAppId: true),
        isRelease: false,
      );
      expect(
        _byName(report, 'onesignal.identity').status,
        IntegrationStatus.configured,
      );
      expect(
        _byName(report, 'family_shield.relay').status,
        IntegrationStatus.notConfigured,
      );
      final relayOnly = _byName(
        integrationDiagnostics(
          platform: TargetPlatform.android,
          config: _cfg(hasAlertRelay: true),
          isRelease: false,
        ),
        'family_shield.relay',
      );
      expect(relayOnly.status, IntegrationStatus.incompleteConfiguration);
    });

    // ── Hygiene ────────────────────────────────────────────────────

    test('report lines never contain secret-shaped values', () {
      final config = _cfg(
        hasRcTestStoreKey: true,
        hasAaiBroker: true,
        hasSemanticProxy: true,
        hasAlertRelay: true,
        hasTranscriptionRelay: true,
        hasRelayToken: true,
        hasOneSignalAppId: true,
        hasGroqDevKey: true,
        devRemoteArmed: true,
        hasAaiTempToken: true,
        hasAaiDevKey: true,
      );
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.windows,
      ]) {
        for (final d in integrationDiagnostics(platform: platform,
            config: config)) {
          expect(d.detail, isNot(contains('key=')));
          expect(d.detail, isNot(contains('http'))); // no URLs leak
          expect(d.toString(), isNot(matches(r'(sk_|goog_|appl_|Bearer)')));
        }
      }
    });

    test('debugPrintIntegrationReport runs in debug test builds', () {
      // Smoke — must not throw; output goes to the test log only.
      debugPrintIntegrationReport(platform: TargetPlatform.android);
    });
  });
}
