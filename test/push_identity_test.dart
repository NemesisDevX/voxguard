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
  var logoutCalls = 0;
  var observerAdds = 0;
  var clickListenerAdds = 0;
  var foregroundListenerAdds = 0;

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
  Future<void> logout() async {
    logoutCalls++;
    loggedInAs = null;
  }

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
  void addSubscriptionObserver(void Function() onChanged) {
    observerAdds++;
    _subObserver = onChanged;
  }

  @override
  void addClickListener(
    void Function(Map<String, dynamic> additionalData) onClick,
  ) {
    clickListenerAdds++;
    _clickListener = onClick;
  }

  @override
  void addForegroundListener(
    void Function(Map<String, dynamic> additionalData) onForeground,
  ) {
    foregroundListenerAdds++;
    _foregroundListener = onForeground;
  }

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

    test('registered requires permission + optedIn + subscription id',
        () async {
      final cases = <(bool, String?, PushRegistrationStatus)>[
        // (optedIn, subId, expected) — granted permission assumed.
        (true, 'os-sub', PushRegistrationStatus.registered),
        (true, null, PushRegistrationStatus.registering),
        (true, '', PushRegistrationStatus.registering),
        (false, 'os-sub', PushRegistrationStatus.registering),
        (false, null, PushRegistrationStatus.registering),
      ];
      for (final (optedIn, subId, expected) in cases) {
        sdk.permission = true;
        sdk.optedIn = optedIn;
        sdk.subscriptionId = subId;
        final s = service();
        await s.initialize();
        expect(
          s.registration.value.status,
          expected,
          reason: 'optedIn=$optedIn subId=$subId',
        );
      }
    });

    test('repeated initialize does not duplicate listeners', () async {
      final s = service();
      await s.initialize();
      await s.initialize();
      await s.initialize();
      expect(sdk.observerAdds, 1);
      expect(sdk.clickListenerAdds, 1);
      expect(sdk.foregroundListenerAdds, 1);
    });

    test('resetIdentity logs out the old external id before relogin',
        () async {
      sdk.permission = true;
      sdk.subscriptionId = 'os-sub-1';
      sdk.optedIn = true;
      final s = service();
      await s.initialize();
      await s.enableAlerts();
      final firstId = sdk.loggedInAs;

      await s.resetIdentity();

      expect(sdk.logoutCalls, 1);
      expect(sdk.loggedInAs, isNotNull);
      expect(sdk.loggedInAs, isNot(firstId));
      expect(sdk.loggedInAs, startsWith('vg_'));
    });

    test('malformed persisted identity is regenerated safely',
        () async {
      await store.write('vg_not-a-real-id');
      final s = service();
      final id = await s.voxGuardIdentity();
      expect(id, isNot('vg_not-a-real-id'));
      expect(id, matches(RegExp(r'^vg_[0-9a-f]{32}$')));
      expect(await store.read(), id);
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

    test('malformed metadata fields never throw', () {
      // OneSignal can deliver arbitrary JSON types — every one of
      // these must parse safely to null fields instead of crashing.
      final parsed = FamilyAlertTap.fromAdditionalData({
        'kind': 'family_shield_alert',
        'incident_id': 123,
        'risk_level': <String>[],
      });
      expect(parsed, isNotNull);
      expect(parsed!.incidentId, isNull);
      expect(parsed.riskLevel, isNull);

      expect(
        FamilyAlertTap.fromAdditionalData({
          'kind': null,
          'incident_id': 'INC-1',
        }),
        isNull,
      );
      expect(
        FamilyAlertTap.fromAdditionalData({
          'kind': 'family_shield_alert',
          'incident_id': {'nested': true},
        }),
        isNotNull,
      );
    });

    test('foreground arrival emits alertReceived, never alertTaps',
        () async {
      final s = service();
      await s.initialize();

      final taps = <FamilyAlertTap>[];
      final received = <FamilyAlertTap>[];
      s.alertTaps.listen(taps.add);
      s.alertReceived.listen(received.add);

      const payload = {
        'kind': 'family_shield_alert',
        'incident_id': 'INC-9',
        'risk_level': 'highRisk',
      };
      sdk.fireForeground(payload); // arrives while app is open
      await Future<void>.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received.single.incidentId, 'INC-9');
      expect(taps, isEmpty, reason: 'receipt is not a user tap');

      sdk.fireClick(payload); // actual user interaction
      await Future<void>.delayed(Duration.zero);
      expect(taps.length, 1);
      expect(received.length, 1);
    });
  });
}
