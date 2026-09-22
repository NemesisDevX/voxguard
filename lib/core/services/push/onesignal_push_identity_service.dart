import 'dart:async';

import 'package:flutter/foundation.dart';

import '../family/family_shield_response.dart';
import 'identity_store.dart';
import 'onesignal_sdk.dart';
import 'push_identity_service.dart';

/// Production push identity service.
///
/// Identity model (three distinct identifiers):
///  - `vg_…` **PauseSignal External ID** — opaque, locally generated,
///    persisted via [IIdentityStore]; the relay targets it through
///    OneSignal `external_id`.
///  - **OneSignal push subscription ID** — provider routing handle,
///    surfaced only as a diagnostic.
///  - **Raw FCM/APNs token** — never leaves the SDK.
///
/// The `onesignal_flutter` plugin declares Android + iOS platform
/// implementations only — every other platform (web, desktop)
/// resolves to [PushRegistrationStatus.unsupported] without ever
/// touching the native SDK.
final class PushIdentityService implements IPushIdentityService {
  PushIdentityService({
    IOneSignalSdk? sdk,
    IIdentityStore? store,
    String? appId,
    bool? platformSupported,
  })  : _sdk = sdk ?? OneSignalSdk(),
        _store = store ?? SharedPrefsIdentityStore(),
        _appId = appId ??
            const String.fromEnvironment('ONESIGNAL_APP_ID',
                defaultValue: ''),
        _platformSupported = platformSupported;

  final IOneSignalSdk _sdk;
  final IIdentityStore _store;
  final String _appId;

  /// Injectable for tests; defaults to "not web".
  final bool? _platformSupported;

  final _registration = ValueNotifier<FamilyPushRegistration>(
    const FamilyPushRegistration(status: PushRegistrationStatus.notConfigured),
  );
  final _taps = StreamController<FamilyAlertTap>.broadcast();
  final _received = StreamController<FamilyAlertTap>.broadcast();
  final _responseTaps = StreamController<FamilyShieldResponse>.broadcast();
  final _responseReceived =
      StreamController<FamilyShieldResponse>.broadcast();

  bool _initialized = false;
  Future<void>? _initFuture;
  String? _externalId;

  /// The external ID successfully linked via `OneSignal.login` this
  /// run. `registered` requires this — a push subscription whose
  /// external_id is not linked cannot be targeted by the relay.
  String? _linkedExternalId;

  /// `onesignal_flutter` ships Android + iOS implementations only.
  bool get _supported =>
      _platformSupported ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));

  @override
  ValueListenable<FamilyPushRegistration> get registration =>
      _registration;

  @override
  Stream<FamilyAlertTap> get alertTaps => _taps.stream;

  @override
  Stream<FamilyAlertTap> get alertReceived => _received.stream;

  @override
  Stream<FamilyShieldResponse> get responseTaps => _responseTaps.stream;

  @override
  Stream<FamilyShieldResponse> get responseReceived =>
      _responseReceived.stream;

  static final _identityPattern = RegExp(r'^vg_[0-9a-f]{32}$');

  @override
  Future<String> voxGuardIdentity() async {
    if (_externalId != null) return _externalId!;
    final existing = await _store.read();
    // Validate the persisted value before trusting it — a malformed
    // or truncated identity is discarded and regenerated rather
    // than sent to the provider.
    if (existing != null && _identityPattern.hasMatch(existing)) {
      return _externalId = existing;
    }
    final fresh = generateVoxGuardIdentity();
    await _store.write(fresh);
    return _externalId = fresh;
  }

  @override
  Future<void> initialize() async {
    await voxGuardIdentity();
    if (_appId.isEmpty) {
      _publish(PushRegistrationStatus.notConfigured);
      return;
    }
    if (!_supported) {
      _publish(PushRegistrationStatus.unsupported);
      return;
    }
    // In-flight init takes precedence over the `_initialized` flag —
    // `_doInitialize` still touches SDK listeners and identity login
    // after the raw `sdk.initialize` call returns, so a flag check
    // alone could let a caller slip through mid-lifecycle. Anyone
    // arriving while a future exists awaits THAT future.
    final inFlight = _initFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    if (_initialized) {
      await _refreshState();
      return;
    }
    final future = _doInitialize();
    _initFuture = future;
    try {
      await future;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _doInitialize() async {
    try {
      await _sdk.initialize(_appId);
      _sdk.addSubscriptionObserver(_refreshState);
      _sdk.addClickListener(_onClick);
      _sdk.addForegroundListener(_onForeground);
      // Link our identity up front — login is not gated on
      // notification permission and the relay targets external_id.
      // A failed login is recoverable later via enableAlerts().
      await _linkIdentity();
      // Only a fully completed lifecycle counts as initialized:
      // SDK ready + listeners installed + identity linkage attempted.
      // Concurrent callers can't observe this flag mid-lifecycle —
      // they all funnel through `_initFuture` above.
      _initialized = true;
      await _refreshState();
    } catch (e, st) {
      debugPrint('PushIdentityService.initialize failed: $e\n$st');
      _publish(PushRegistrationStatus.error,
          errorDetail: 'Push setup failed on this device.');
    }
  }

  /// Associates the local `vg_…` identity with the OneSignal user.
  /// A completed `login` is the client-side linkage signal — the SDK
  /// exposes no deeper server-state inspection. Failure clears
  /// [_linkedExternalId] so `registered` can never be claimed.
  Future<void> _linkIdentity() async {
    try {
      await _sdk.login(await voxGuardIdentity());
      _linkedExternalId = _externalId;
    } catch (e) {
      _linkedExternalId = null;
      debugPrint('PushIdentityService: identity link failed: $e');
      _publish(PushRegistrationStatus.error,
          errorDetail: 'Could not link your Family Shield ID.');
    }
  }

  /// User-intentional enable flow — called from the receiver card's
  /// "Enable Family Alerts" button, never at app launch.
  @override
  Future<void> enableAlerts() async {
    if (!_initialized || _appId.isEmpty || !_supported) {
      await initialize();
      if (!_initialized) return;
    }
    _publish(PushRegistrationStatus.registering);
    try {
      final granted = await _sdk.requestPermission();
      if (!granted) {
        _publish(
          await _sdk.canRequestPermission()
              ? PushRegistrationStatus.permissionRequired
              : PushRegistrationStatus.permissionDenied,
        );
        return;
      }
      // Bridge: the relay's include_aliases.external_id reaches this
      // device only after login links our vg_… identity. Normally
      // already linked at init; re-link here so a previous transient
      // login failure heals on the next explicit enable.
      if (_linkedExternalId != _externalId) await _linkIdentity();
      await _refreshState();
    } catch (e, st) {
      debugPrint('PushIdentityService.enableAlerts failed: $e\n$st');
      _publish(PushRegistrationStatus.error,
          errorDetail: 'Could not enable push alerts. Try again.');
    }
  }

  @override
  Future<void> resetIdentity() async {
    // Unlink the old external ID from the OneSignal user before
    // minting a replacement — otherwise both identities could
    // remain associated with this device's subscription.
    if (_initialized) {
      try {
        await _sdk.logout();
      } catch (_) {}
      _linkedExternalId = null;
    }
    await _store.clear();
    _externalId = null;
    await voxGuardIdentity();
    if (_initialized) {
      await _linkIdentity();
    }
    await _refreshState();
  }

  /// Recomputes truthful registration state — called on init, after
  /// enable, and from the subscription observer (no polling).
  ///
  /// `registered` means genuinely addressable: permission granted,
  /// subscription opted in, a non-empty OneSignal subscription ID,
  /// AND the `vg_…` identity successfully linked via login — the
  /// relay targets `external_id`, so an unlinked subscription is
  /// unreachable even when everything else looks ready.
  Future<void> _refreshState() async {
    if (!_initialized) return;
    try {
      final granted = await _sdk.permissionGranted();
      final subId = _sdk.pushSubscriptionId;
      final optedIn = _sdk.pushOptedIn;
      final linked = _linkedExternalId == _externalId;
      _registration.value = FamilyPushRegistration(
        status: !granted
            ? (await _sdk.canRequestPermission()
                ? PushRegistrationStatus.permissionRequired
                : PushRegistrationStatus.permissionDenied)
            : (optedIn &&
                    subId != null &&
                    subId.isNotEmpty &&
                    linked)
                ? PushRegistrationStatus.registered
                : PushRegistrationStatus.registering,
        voxguardExternalId: _externalId,
        pushSubscriptionId: subId,
        optedIn: optedIn,
      );
    } catch (e, st) {
      debugPrint('PushIdentityService._refreshState failed: $e\n$st');
      _publish(PushRegistrationStatus.error,
          errorDetail: 'Push state could not be read.');
    }
  }

  void _onClick(Map<String, dynamic> additionalData) {
    // Route by kind — a resolution response is not a danger alert.
    final tap = FamilyAlertTap.fromAdditionalData(additionalData);
    if (tap != null) {
      _taps.add(tap);
      return;
    }
    final response =
        FamilyShieldResponse.fromAdditionalData(additionalData);
    if (response != null) _responseTaps.add(response);
  }

  void _onForeground(Map<String, dynamic> additionalData) {
    // Foreground ARRIVAL is not a tap — alert receipts emit on the
    // separate alertReceived stream so navigation hooks only real
    // user interaction. Default display is preserved by the adapter.
    final received = FamilyAlertTap.fromAdditionalData(additionalData);
    if (received != null) {
      _received.add(received);
      return;
    }
    final response =
        FamilyShieldResponse.fromAdditionalData(additionalData);
    if (response != null) _responseReceived.add(response);
  }

  void _publish(PushRegistrationStatus status, {String? errorDetail}) {
    _registration.value = FamilyPushRegistration(
      status: status,
      voxguardExternalId: _externalId,
      errorDetail: errorDetail,
    );
  }
}

/// Process-wide accessor.
final class PushIdentityLocator {
  PushIdentityLocator._();

  static IPushIdentityService? _instance;

  static IPushIdentityService get instance =>
      _instance ??= PushIdentityService();

  @visibleForTesting
  static set instance(IPushIdentityService service) => _instance = service;
}
