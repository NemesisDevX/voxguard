import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/l10n.dart';
import 'core/services/preferences/app_preferences.dart';
import 'core/services/push/onesignal_push_identity_service.dart';
import 'core/theme/app_theme.dart';
import 'features/family_shield/family_alert_coordinator.dart';
import 'features/onboarding/presentation/screens/startup_gate.dart';
import 'features/paywall/domain/services/purchase_service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local preferences hydrate before the first frame so the very
  // first pixels already honor locale/theme/motion — no flash of
  // defaults. Pure SharedPreferences; no account, no network.
  final preferences = AppPreferencesLocator.instance =
      await AppPreferences.load();
  await preferences.init();
  // Subscribe BEFORE push init so a cold-start notification tap is
  // never lost; the coordinator holds a pending event until the
  // Navigator is mounted.
  final coordinator = FamilyAlertCoordinator(
    messengerKey: FamilyAlertNavigator.messengerKey,
  )..start();
  // Push identity init is permission-free: reads subscription state and
  // attaches observers. The native permission prompt only ever fires
  // from the Family Shield card's explicit enable button. No App ID →
  // resolves to `notConfigured`; app never blocks on it.
  unawaited(PushIdentityLocator.instance.initialize());
  // Purchase backend init is non-blocking and failure-safe: a store
  // outage resolves entitlement to free, never crashes the app.
  // Reactive state lets features unlock the moment entitlements land.
  unawaited(
    PurchaseServiceLocator.instance.initialize().catchError((_) {}),
  );
  runApp(VoxGuardApp(coordinator: coordinator));
}

/// Root application widget — PauseSignal, consumer-first AI voice-threat
/// monitor and scam-risk defense system.
class VoxGuardApp extends StatelessWidget {
  const VoxGuardApp({super.key, this.coordinator});

  /// Notification routing — created in `main` so it subscribes before
  /// the first frame. Optional for widget tests.
  final FamilyAlertCoordinator? coordinator;

  static ThemeMode _materialThemeMode(AppThemeMode mode) =>
      switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferencesLocator.instance;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final reduced = prefs.wantsReducedMotion;
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(prefs.accent),
          darkTheme: AppTheme.dark(prefs.accent),
          themeMode: _materialThemeMode(prefs.themeMode),
          // Instant swap when the user prefers reduced motion; a short
          // tasteful crossfade otherwise.
          themeAnimationDuration:
              reduced ? Duration.zero : const Duration(milliseconds: 180),
          themeAnimationCurve: Curves.easeOut,
          locale: prefs.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          navigatorKey: FamilyAlertNavigator.key,
          scaffoldMessengerKey: FamilyAlertNavigator.messengerKey,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final osScale = mq.textScaler.scale(1.0);
            // The app text-size preset is a *floor*: it can enlarge
            // text beyond the OS scale but never shrink it below the
            // user's OS accessibility setting.
            final effectiveScale = osScale > prefs.textScaleFloor
                ? osScale
                : prefs.textScaleFloor;
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(effectiveScale),
                // OS reduced-motion wins; the app setting ORs on top —
                // either source suppresses ambient animation.
                disableAnimations:
                    mq.disableAnimations || prefs.wantsReducedMotion,
              ),
              child: child!,
            );
          },
          home: const StartupGate(),
        );
      },
    );
  }
}
