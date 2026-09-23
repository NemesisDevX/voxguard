import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/core/diagnostics/integration_diagnostics.dart';

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
        resolvedPurchaseBackendLabel(TargetPlatform.windows),
        'demo_store',
      );
      expect(
        resolvedPurchaseBackendLabel(TargetPlatform.linux),
        'demo_store',
      );
    });

    test('report lines never contain secret-shaped values', () {
      // Every diagnostic detail must be a sanitised label — the report
      // exists precisely so QA can read state without exposing keys.
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.windows,
      ]) {
        for (final d in integrationDiagnostics(platform: platform)) {
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
