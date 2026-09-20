import 'package:flutter_test/flutter_test.dart';
import 'package:voxguard/core/services/push/identity_store.dart';
import 'package:voxguard/core/services/push/onesignal_push_identity_service.dart';
import 'package:voxguard/core/services/push/onesignal_sdk.dart';
import 'package:voxguard/core/services/push/push_identity_service.dart';

/// Scripted OneSignal SDK stand-in.
final class FakeOneSignalSdk implements IOneSignalSdk {
  var initialized = false;
  String? initializedAppId;
  String? loggedInAs;
  var permission = false;
  var canRequest = true;
  String? subscriptionId;
  var optedIn = false;
  var requestPermissionCalls = 0;
  var loginCalls = 0;

  void Function()? _subObserver;
  void Function(Map<String, dynamic>)? _clickListener;
  void Function(Map<String, dynamic>)? _foregroundListener;

  @override
  Future<void> initialize(String appId) async {
    initialized = true;
    initializedAppId = appId;
  }

  @override
  Future<void> login(String externalId) async {
    loginCalls++;
    loggedInAs = externalId;
  }

  @override
  Future<void> logout() async => loggedInAs = null;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permission;
  }

  @override
  Future<bool> permissionGranted() async => permission;

  @override
  Future<bool> canRequestPermission() async => canRequest;

  @override
  String? get pushSubscriptionId => subscriptionId;

  @override
  bool get pushOptedIn => optedIn;

  @override
  void addSubscriptionObserver(void Function() onChanged) =>
      _subObserver = onChanged;

  @override
  void addClickListener(
    void Function(Map<String, dynamic> additionalData) onClick,
  ) =>
      _clickListener = onClick;

  @override
  void addForegroundListener(
    void Function(Map<String, dynamic> additionalData) onForeground,
  ) =>
      _foregroundListener = onForeground;

  /// Simulate a subscription appearing/changing.
  void fireSubscriptionChanged() => _subObserver?.call();

  /// Simulate a notification tap.
  void fireClick(Map<String, dynamic> data) => _clickListener?.call(data);

  /// Simulate a foreground notification.
  void fireForeground(Map<String, dynamic> data) =>
      _foregroundListener?.call(data);
}

void main() {
  late FakeOneSignalSdk sdk;
  late InMemoryIdentityStore store;

  setUp(() {
    sdk = FakeOneSignalSdk();
    store = InMemoryIdentityStore();
  });

  PushIdentityService service({String appId = 'app-1'}) =>
      PushIdentityService(
        sdk: sdk,
        store: store,
        appId: appId,
        platformSupported: true,
      );

  group('identity', () {
    test('generates a vg_ id once and persists it', () async {
      final s = service();
      final id = await s.voxGuardIdentity();
      expect(id, startsWith('vg_'));
      expect(id.length, greaterThan(10));
      expect(await store.read(), id);

      // A second service instance reuses the persisted identity.
      final s2 = service();
      expect(await s2.voxGuardIdentity(), id);
    });

    test('resetIdentity produces a new persisted id', () async {
      final s = service();
      final first = await s.voxGuardIdentity();
      await s.resetIdentity();
      final second = await s.voxGuardIdentity();
      expect(second, isNot(first));
      expect(await store.read(), second);
    });
  });

  group('registration lifecycle', () {
    test('missing app id → notConfigured, never crashes', () async {
      final s = service(appId: '');
      await s.initialize();
      expect(sdk.initialized, isFalse);
      expect(s.registration.value.status,
          PushRegistrationStatus.notConfigured);
      // Identity still exists for consistency.
      expect(s.registration.value.voxguardExternalId, isNotNull);
    });

    test('unsupported platform → unavailable state', () async {
      final s = PushIdentityService(
        sdk: sdk,
        store: store,
        appId: 'app-1',
        platformSupported: false,
      );
      await s.initialize();
      expect(s.registration.value.status,
          PushRegistrationStatus.unsupported);
    });

    test('fresh device → permissionRequired before any request',
        () async {
      final s = service();
      await s.initialize();
      expect(s.registration.value.status,
          PushRegistrationStatus.permissionRequired);
      expect(sdk.requestPermissionCalls, 0);
    });

    test('enableAlerts → permission grant → login with vg_ id → '
        'registered', () async {
      sdk.permission = true;
      final s = service();
      await s.initialize();

      await s.enableAlerts();

      expect(sdk.requestPermissionCalls, 1);
      expect(sdk.loginCalls, 1);
      expect(sdk.loggedInAs, startsWith('vg_'));

      // Subscription arrives via observer (async in real life).
      sdk.subscriptionId = 'os-sub-1';
      sdk.optedIn = true;
      sdk.fireSubscriptionChanged();
      await Future<void>.delayed(Duration.zero);

      final reg = s.registration.value;
      expect(reg.status, PushRegistrationStatus.registered);
      expect(reg.pushSubscriptionId, 'os-sub-1');
      expect(reg.optedIn, isTrue);
      expect(reg.voxguardExternalId, sdk.loggedInAs);
    });

    test('permission denied → permissionDenied, no login', () async {
      sdk.permission = false;
      sdk.canRequest = false;
      final s = service();
      await s.initialize();

      await s.enableAlerts();

      expect(s.registration.value.status,
          PushRegistrationStatus.permissionDenied);
      expect(sdk.loginCalls, 0);
    });

    test('subscription opt-out updates state without restart', () async {
      sdk.permission = true;
      sdk.subscriptionId = 'os-sub-1';
      sdk.optedIn = true;
      final s = service();
      await s.initialize();
      await s.enableAlerts();
      expect(s.registration.value.status,
          PushRegistrationStatus.registered);

      sdk.optedIn = false;
      sdk.subscriptionId = null;
      sdk.fireSubscriptionChanged();
      await Future<void>.delayed(Duration.zero);

      expect(s.registration.value.status,
          PushRegistrationStatus.registering);
    });

    test('raw push token is never exposed on the registration model',
        () async {
      final s = service();
      await s.initialize();
      // Model surface: no token field exists — only subscriptionId.
      final reg = s.registration.value;
      expect(reg.toString().contains('token'), isFalse);
    });
  });

  group('alert tap metadata', () {
    test('valid family_shield payload parses; unrelated ignored', () async {
      final s = service();
      await s.initialize();

      final taps = <FamilyAlertTap>[];
      s.alertTaps.listen(taps.add);

      sdk.fireClick({'kind': 'promo'}); // ignored
      sdk.fireClick({
        'kind': 'family_shield_alert',
        'incident_id': 'INC-1',
        'risk_level': 'highRisk',
      });
      await Future<void>.delayed(Duration.zero);

      expect(taps.length, 1);
      expect(taps.single.incidentId, 'INC-1');
      expect(taps.single.riskLevel, 'highRisk');
    });

    test('fromAdditionalData returns null for non-family payloads', () {
      expect(FamilyAlertTap.fromAdditionalData(null), isNull);
      expect(FamilyAlertTap.fromAdditionalData({'kind': 'x'}), isNull);
    });
  });
}
