import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:voxguard/core/services/alerts/family_alert_service.dart';
import 'package:voxguard/core/services/alerts/family_shield_alert_service.dart';
import 'package:voxguard/core/services/family/received_family_alert_repository.dart';
import 'package:voxguard/features/forensics/domain/models/incident_report.dart';
import 'package:voxguard/features/paywall/domain/models/billing_cycle.dart';
import 'package:voxguard/features/paywall/domain/models/entitlement_state.dart';
import 'package:voxguard/features/paywall/domain/models/subscription_tier.dart';
import 'package:voxguard/features/paywall/domain/services/i_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/mock_sandbox_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/product_access.dart';
import 'package:voxguard/features/paywall/domain/services/purchase_service_factory_io.dart';
import 'package:voxguard/features/paywall/domain/services/revenuecat_purchase_service.dart';
import 'package:voxguard/features/paywall/domain/services/unavailable_purchase_service.dart';
import 'package:voxguard/features/protection/domain/models/audio_forensic_metrics.dart';
import 'package:voxguard/features/protection/domain/models/composite_threat_report.dart';
import 'package:voxguard/features/protection/domain/models/semantic_threat_signals.dart';

import 'helpers/fake_product_access.dart';

/// Minimal incident fixture for Family Shield dispatch tests.
IncidentReport _incident() => IncidentReport(
      id: 'INC-2026-0001',
      timestamp: DateTime(2026, 9, 20),
      callerLabel: 'Unknown Caller',
      callDurationSeconds: 45,
      audioDigestSha256: 'ab' * 32,
      audioSourceLabel: 'Live Microphone',
      transcriptionSourceLabel: 'None',
      peakRiskScore: 0.8,
      riskLevel: ThreatRiskLevel.highRisk,
      threatReasons: const ['Urgency + financial pressure'],
      acousticMetrics: const AudioForensicMetrics(
        spectralFlux: 0.1,
        spectralRolloffRatio: 0.2,
        zeroCrossingRate: 0.1,
        syntheticVoiceScore: 0.7,
      ),
      semanticSignals: const SemanticThreatSignals.empty(),
      transcriptSnippets: const [],
      recommendedActions: const ['Verify the caller'],
    );

const _vgSender = 'vg_00000000000000000000000000000009';
const _vgRecipient = 'vg_0000000000000000000000000000000a';

void main() {
  group('ProductCapabilities — plan matrix', () {
    test('free: local analysis + demo + receive/respond only', () {
      const caps = ProductCapabilities(TierId.free);
      expect(caps.liveCloudTranscription, isFalse);
      expect(caps.enhancedRecording, isFalse);
      expect(caps.familyShieldOutbound, isFalse);
    });

    test('sentinel: transcript-backed analysis, no outbound alerts',
        () {
      const caps = ProductCapabilities(TierId.sentinel);
      expect(caps.liveCloudTranscription, isTrue);
      expect(caps.enhancedRecording, isTrue);
      expect(caps.familyShieldOutbound, isFalse);
    });

    test('family_vault: superset including outbound alerts', () {
      const caps = ProductCapabilities(TierId.familyVault);
      expect(caps.liveCloudTranscription, isTrue);
      expect(caps.enhancedRecording, isTrue);
      expect(caps.familyShieldOutbound, isTrue);
    });
  });

  group('ProductAccess — derives from entitlement stream', () {
    test('capabilities follow the service entitlement reactively',
        () async {
      final service = MockSandboxPurchaseService(
          networkDelay: Duration.zero, checkoutDelay: Duration.zero);
      final access = ProductAccess(service);
      await service.initialize();
      expect(access.capabilities.liveCloudTranscription, isFalse);

      final pkgs = await service.getPackages();
      await service.purchasePackage(pkgs.firstWhere(
          (p) => p.identifier == 'family_vault_monthly'));
      expect(access.capabilities.familyShieldOutbound, isTrue);
      expect(access.capabilities.liveCloudTranscription, isTrue);
    });
  });

  group('purchase backend selection', () {
    test('mobile + key → real store backend', () {
      final svc = createPurchaseServiceFor(
        isMobileStorePlatform: true,
        hasRevenueCatKey: true,
        isReleaseBuild: true,
      );
      expect(svc, isA<RevenueCatPurchaseService>());
      expect(svc.backendMode, PurchaseBackendMode.realStore);
    });

    test('mobile RELEASE without key → unavailable, never demo',
        () {
      final svc = createPurchaseServiceFor(
        isMobileStorePlatform: true,
        hasRevenueCatKey: false,
        isReleaseBuild: true,
      );
      expect(svc, isA<UnavailablePurchaseService>());
      expect(svc.backendMode, PurchaseBackendMode.unavailable);
    });

    test('mobile DEBUG without key → labelled demo store', () {
      final svc = createPurchaseServiceFor(
        isMobileStorePlatform: true,
        hasRevenueCatKey: false,
        isReleaseBuild: false,
      );
      expect(svc, isA<MockSandboxPurchaseService>());
      expect(svc.backendMode, PurchaseBackendMode.demoStore);
    });

    test('non-store platform → demo store', () {
      final svc = createPurchaseServiceFor(
        isMobileStorePlatform: false,
        hasRevenueCatKey: false,
        isReleaseBuild: true,
      );
      expect(svc, isA<MockSandboxPurchaseService>());
      expect(svc.backendMode, PurchaseBackendMode.demoStore);
    });
  });

  group('UnavailablePurchaseService — production guard', () {
    test('no checkout can ever activate a paid plan', () async {
      final svc = UnavailablePurchaseService();
      await svc.initialize();
      expect(await svc.getPackages(), isEmpty);
      expect(svc.entitlement.value.tier, TierId.free);
      await expectLater(
        svc.purchasePackage(
          const StorePackage(
            identifier: 'sentinel_monthly',
            tierId: TierId.sentinel,
            cycle: BillingCycle.monthly,
            priceString: r'$9.99',
            title: 'x',
          ),
        ),
        throwsA(isA<PurchaseServiceException>()),
      );
      expect(await svc.restorePurchases(), isNull);
      expect(svc.entitlement.value.tier, TierId.free);
    });
  });

  group('Family Shield outbound gate', () {
    Future<AlertDispatchResult> sendWith(
      IProductAccess access, {
      required String relayUrl,
      required void Function() onHit,
    }) {
      final service = FamilyShieldAlertService(
        httpClient: http_testing.MockClient((_) async {
          onHit();
          return http.Response('{"ok":true}', 202);
        }),
        relayUrl: relayUrl,
        senderIdentity: () async => _vgSender,
        productAccess: access,
      );
      return service.triggerFamilyEmergencyAlert(
        incident: _incident(),
        familyMemberIds: const [_vgRecipient],
      );
    }

    test('free plan → locked, zero relay requests', () async {
      var hit = false;
      final result = await sendWith(
        FakeProductAccess(),
        relayUrl: 'https://relay.example.com/alert',
        onHit: () => hit = true,
      );
      expect(result.status, AlertDispatchStatus.locked);
      expect(result.attempted, isFalse);
      expect(result.detail, contains('Family Vault'));
      expect(hit, isFalse);
    });

    test('sentinel → still locked for outbound alerts', () async {
      var hit = false;
      final result = await sendWith(
        FakeProductAccess(TierId.sentinel),
        relayUrl: 'https://relay.example.com/alert',
        onHit: () => hit = true,
      );
      expect(result.status, AlertDispatchStatus.locked);
      expect(hit, isFalse);
    });

    test('family_vault → real relay request proceeds', () async {
      var hit = false;
      final result = await sendWith(
        FakeProductAccess(TierId.familyVault),
        relayUrl: 'https://relay.example.com/alert',
        onHit: () => hit = true,
      );
      expect(result.status, AlertDispatchStatus.accepted);
      expect(hit, isTrue);
    });

    test('demo mode is never gated — simulated alert works free',
        () async {
      var hit = false;
      final result = await sendWith(
        FakeProductAccess(), // free
        relayUrl: '',
        onHit: () => hit = true,
      );
      expect(result.status, AlertDispatchStatus.simulated);
      expect(hit, isFalse);
    });
  });

  group('Family Shield response — never gated', () {
    test('free receiver can still respond Safe/Still Suspicious',
        () async {
      var hit = false;
      final service = FamilyShieldAlertService(
        httpClient: http_testing.MockClient((_) async {
          hit = true;
          return http.Response('{"ok":true}', 202);
        }),
        relayUrl: 'https://relay.example.com/alert',
        senderIdentity: () async => _vgSender,
        productAccess: FakeProductAccess(), // free
      );
      final result = await service.sendFamilyShieldResponse(
        incidentId: 'INC-2026-0001',
        resolution: AlertResolution.safe,
        targetExternalId: _vgRecipient,
      );
      expect(result.status, AlertDispatchStatus.accepted);
      expect(hit, isTrue);
    });
  });
}
