import 'dart:async';

import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Thin adapter over the `onesignal_flutter` static SDK so the push
/// identity service stays unit-testable. One method per SDK call —
/// no PauseSignal logic lives here.
abstract interface class IOneSignalSdk {
  /// `OneSignal.initialize(appId)`
  Future<void> initialize(String appId);

  /// `OneSignal.login(externalId)` — links our `vg_…` External ID to
  /// this device's OneSignal user, which is what lets the relay's
  /// `include_aliases.external_id` reach this device.
  Future<void> login(String externalId);

  /// `OneSignal.logout()`
  Future<void> logout();

  /// `OneSignal.Notifications.requestPermission(fallbackToSettings)`
  /// — returns true when permission is (or becomes) granted.
  Future<bool> requestPermission();

  /// `OneSignal.Notifications.permission` — current grant state.
  Future<bool> permissionGranted();

  /// `OneSignal.Notifications.canRequest()` — false once the user has
  /// permanently declined on platforms that only prompt once.
  Future<bool> canRequestPermission();

  /// `OneSignal.User.pushSubscription.id` — OneSignal's subscription
  /// handle (diagnostic only; the raw FCM/APNs token stays internal).
  String? get pushSubscriptionId;

  /// `OneSignal.User.pushSubscription.optedIn`
  bool get pushOptedIn;

  /// `OneSignal.User.pushSubscription.addObserver` — fires on any
  /// subscription change (permission grant, token refresh, opt-out).
  void addSubscriptionObserver(void Function() onChanged);

  /// `OneSignal.Notifications.addClickListener` — receives the
  /// notification's `additionalData` map.
  void addClickListener(
    void Function(Map<String, dynamic> additionalData) onClick,
  );

  /// `OneSignal.Notifications.addForegroundWillDisplayListener` —
  /// keeps default display behavior while surfacing metadata.
  void addForegroundListener(
    void Function(Map<String, dynamic> additionalData) onForeground,
  );
}

/// Real adapter — the only place `package:onesignal_flutter` is
/// referenced.
final class OneSignalSdk implements IOneSignalSdk {
  @override
  Future<void> initialize(String appId) => OneSignal.initialize(appId);

  @override
  Future<void> login(String externalId) => OneSignal.login(externalId);

  @override
  Future<void> logout() => OneSignal.logout();

  @override
  Future<bool> requestPermission() =>
      OneSignal.Notifications.requestPermission(true);

  @override
  Future<bool> permissionGranted() async =>
      OneSignal.Notifications.permission;

  @override
  Future<bool> canRequestPermission() =>
      OneSignal.Notifications.canRequest();

  @override
  String? get pushSubscriptionId => OneSignal.User.pushSubscription.id;

  @override
  bool get pushOptedIn => OneSignal.User.pushSubscription.optedIn ?? false;

  @override
  void addSubscriptionObserver(void Function() onChanged) {
    OneSignal.User.pushSubscription.addObserver((_) => onChanged());
  }

  @override
  void addClickListener(
    void Function(Map<String, dynamic> additionalData) onClick,
  ) {
    OneSignal.Notifications.addClickListener(
      (event) => onClick(event.notification.additionalData ?? {}),
    );
  }

  @override
  void addForegroundListener(
    void Function(Map<String, dynamic> additionalData) onForeground,
  ) {
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      onForeground(event.notification.additionalData ?? {});
      event.notification.display(); // keep normal foreground display
    });
  }
}
