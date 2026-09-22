import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/legal_links.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/localized_text.dart';
import '../../../../core/services/preferences/app_preferences.dart';
import '../../../../core/services/push/onesignal_push_identity_service.dart';
import '../../../../core/services/push/push_identity_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/widgets/family_receiver_card.dart';
import '../../../home/presentation/widgets/trusted_circle_card.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../widgets/subscription_card.dart';

/// App version — kept in step with `pubspec.yaml` manually; adding
/// package_info_plus just for this label isn't worth the dependency.
const kAppVersion = '1.0.0';

/// Settings — the Control Center. Calm sections: Profile, Appearance,
/// Safety & Family, Notifications, Subscription, About & Privacy.
/// Every preference applies instantly and persists locally.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = AppPreferencesLocator.instance;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _SectionHeader(l10n.settingsSectionProfile),
          _ProfileSection(prefs: prefs),
          _SectionHeader(l10n.settingsSectionAppearance),
          _AppearanceSection(prefs: prefs),
          _SectionHeader(l10n.settingsSectionSafety),
          const FamilyReceiverCard(),
          const SizedBox(height: 12),
          const TrustedCircleCard(),
          _SectionHeader(l10n.settingsSectionNotifications),
          const _NotificationsSection(),
          _SectionHeader(l10n.settingsSectionSubscription),
          const SubscriptionCard(),
          _SectionHeader(l10n.settingsSectionAbout),
          const _AboutSection(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 0, 10),
      child: Text(title, style: AppTypography.labelSmall),
    );
  }
}

/// Shared settings surface — a card wrapping section content.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// A tappable settings row — label + current value + chevron.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: p.textMuted),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(label, style: AppTypography.titleMedium),
            ),
            Flexible(
              child: Text(
                value,
                style: AppTypography.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Generic option sheet — radio list used by every enum preference.
Future<void> _pickOption<T>({
  required BuildContext context,
  required String title,
  required List<(T, String)> options,
  required T current,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: AppTypography.titleLarge),
            ),
            RadioGroup<T>(
              groupValue: current,
              onChanged: (v) {
                if (v != null) onSelected(v);
                Navigator.of(sheetCtx).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (value, label) in options)
                    RadioListTile<T>(
                      title: Text(label),
                      value: value,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

// ── Profile ──────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.prefs});
  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SettingsCard(
      children: [
        _NavRow(
          icon: Icons.person_outline,
          label: l10n.settingsDisplayName,
          value: prefs.displayName ?? l10n.settingsDisplayNameNone,
          onTap: () => _editName(context),
        ),
        _NavRow(
          icon: Icons.language_outlined,
          label: l10n.settingsLanguage,
          value: switch (prefs.localeOption) {
            AppLocaleOption.system => l10n.languageSystem,
            AppLocaleOption.en => l10n.languageEn,
            AppLocaleOption.ar => l10n.languageAr,
            AppLocaleOption.es => l10n.languageEs,
            AppLocaleOption.fr => l10n.languageFr,
          },
          onTap: () => _pickOption<AppLocaleOption>(
            context: context,
            title: l10n.settingsLanguage,
            current: prefs.localeOption,
            onSelected: (v) =>
                context.savePreference(prefs.setLocale(v)),
            options: [
              (AppLocaleOption.system, l10n.languageSystem),
              (AppLocaleOption.en, l10n.languageEn),
              (AppLocaleOption.ar, l10n.languageAr),
              (AppLocaleOption.es, l10n.languageEs),
              (AppLocaleOption.fr, l10n.languageFr),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Text(l10n.settingsDisplayNameNote,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context) async {
    final l10n = context.l10n;
    final ctrl = TextEditingController(text: prefs.displayName ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.settingsDisplayName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: AppPreferences.maxDisplayNameLength,
          decoration: InputDecoration(hintText: l10n.settingsDisplayNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(ctrl.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (saved != null && context.mounted) {
      context.savePreference(prefs.setDisplayName(saved));
    }
  }
}

// ── Appearance ───────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.prefs});
  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SettingsCard(
      children: [
        _NavRow(
          icon: Icons.brightness_6_outlined,
          label: l10n.settingsTheme,
          value: switch (prefs.themeMode) {
            AppThemeMode.system => l10n.themeSystem,
            AppThemeMode.light => l10n.themeLight,
            AppThemeMode.dark => l10n.themeDark,
          },
          onTap: () => _pickOption<AppThemeMode>(
            context: context,
            title: l10n.settingsTheme,
            current: prefs.themeMode,
            onSelected: (v) =>
                context.savePreference(prefs.setThemeMode(v)),
            options: [
              (AppThemeMode.system, l10n.themeSystem),
              (AppThemeMode.light, l10n.themeLight),
              (AppThemeMode.dark, l10n.themeDark),
            ],
          ),
        ),
        _AccentRow(prefs: prefs),
        _NavRow(
          icon: Icons.format_size,
          label: l10n.settingsTextSize,
          value: switch (prefs.textSize) {
            AppTextSize.system => l10n.textSizeSystem,
            AppTextSize.large => l10n.textSizeLarge,
            AppTextSize.extraLarge => l10n.textSizeExtraLarge,
          },
          onTap: () => _pickOption<AppTextSize>(
            context: context,
            title: l10n.settingsTextSize,
            current: prefs.textSize,
            onSelected: (v) =>
                context.savePreference(prefs.setTextSize(v)),
            options: [
              (AppTextSize.system, l10n.textSizeSystem),
              (AppTextSize.large, l10n.textSizeLarge),
              (AppTextSize.extraLarge, l10n.textSizeExtraLarge),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Text(l10n.textSizeNote,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ),
        _NavRow(
          icon: Icons.assistant_outlined,
          label: l10n.settingsExperience,
          value: switch (prefs.experienceMode) {
            ExperienceMode.standard => l10n.experienceStandard,
            ExperienceMode.guided => l10n.experienceGuided,
          },
          onTap: () => _pickOption<ExperienceMode>(
            context: context,
            title: l10n.settingsExperience,
            current: prefs.experienceMode,
            onSelected: (v) =>
                context.savePreference(prefs.setExperienceMode(v)),
            options: [
              (ExperienceMode.standard, l10n.experienceStandard),
              (ExperienceMode.guided, l10n.experienceGuided),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Text(l10n.experienceGuidedDesc,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ),
        _NavRow(
          icon: Icons.animation_outlined,
          label: l10n.settingsMotion,
          value: switch (prefs.motion) {
            AppMotionPref.system => l10n.motionSystem,
            AppMotionPref.reduced => l10n.motionReduced,
          },
          onTap: () => _pickOption<AppMotionPref>(
            context: context,
            title: l10n.settingsMotion,
            current: prefs.motion,
            onSelected: (v) =>
                context.savePreference(prefs.setMotion(v)),
            options: [
              (AppMotionPref.system, l10n.motionSystem),
              (AppMotionPref.reduced, l10n.motionReduced),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Text(l10n.motionNote,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ),
        _HapticsRow(prefs: prefs),
      ],
    );
  }
}

/// Accent choices as filled swatches — a curated set, not a picker.
class _AccentRow extends StatelessWidget {
  const _AccentRow({required this.prefs});
  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, size: 19, color: p.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.settingsAccent,
                style: AppTypography.titleMedium),
          ),
          for (final accent in AppAccent.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: _AccentSwatch(
                accent: accent,
                selected: prefs.accent == accent,
                tooltip: switch (accent) {
                  AppAccent.periwinkle => l10n.accentPeriwinkle,
                  AppAccent.softBlue => l10n.accentSoftBlue,
                  AppAccent.softViolet => l10n.accentSoftViolet,
                },
                onTap: () =>
                    context.savePreference(prefs.setAccent(accent)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = AppPalette.accentFor(accent, p.brightness);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected ? p.textPrimary : Colors.transparent,
              width: 2.4,
            ),
          ),
          child: selected
              ? Icon(Icons.check, size: 14, color: p.onAccent)
              : null,
        ),
      ),
    );
  }
}

class _HapticsRow extends StatelessWidget {
  const _HapticsRow({required this.prefs});
  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.vibration, size: 19, color: p.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text(l10n.settingsHaptics, style: AppTypography.titleMedium),
          ),
          Switch(
            value: prefs.hapticsEnabled,
            onChanged: (on) => context.savePreference(
                prefs.setHaptics(on ? AppHapticsPref.on : AppHapticsPref.off)),
          ),
        ],
      ),
    );
  }
}

// ── Notifications — truthful state, real action ──────────────────────

/// Reports the REAL push registration/permission state and offers the
/// honest action (system settings) — no fake sound pickers.
class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return ValueListenableBuilder<FamilyPushRegistration>(
      valueListenable: PushIdentityLocator.instance.registration,
      builder: (context, reg, _) {
        final (state, color) = switch (reg.status) {
          PushRegistrationStatus.registered =>
            (l10n.notifStateGranted, p.statusSafe),
          PushRegistrationStatus.permissionDenied =>
            (l10n.notifStateDenied, p.statusWarning),
          PushRegistrationStatus.permissionRequired =>
            (l10n.notifStateUnknown, p.textMuted),
          PushRegistrationStatus.notConfigured =>
            (l10n.familyStateNotConfigured, p.textMuted),
          PushRegistrationStatus.unsupported =>
            (l10n.familyStateUnsupported, p.textMuted),
          PushRegistrationStatus.registering =>
            (l10n.familyStateRegistering, p.textMuted),
          PushRegistrationStatus.error =>
            (l10n.familyStateError(''), p.statusWarning),
        };
        return _SettingsCard(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined,
                      size: 19, color: p.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.settingsNotificationState,
                        style: AppTypography.titleMedium),
                  ),
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(state,
                        style:
                            AppTypography.bodyMedium.copyWith(color: color),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text(l10n.settingsNotificationNote,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: TextButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.tune, size: 16),
                label: Text(l10n.settingsOpenNotifSettings),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── About & Privacy ──────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return _SettingsCard(
      children: [
        _NavRow(
          icon: Icons.help_outline,
          label: l10n.howItWorksTitle,
          value: '',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const OnboardingScreen(reviewMode: true),
            ),
          ),
        ),
        if (LegalLinks.privacyPolicy != null)
          _NavRow(
            icon: Icons.privacy_tip_outlined,
            label: l10n.privacy,
            value: '',
            onTap: () => unawaited(launchUrl(LegalLinks.privacyPolicy!,
                mode: LaunchMode.externalApplication)),
          ),
        if (LegalLinks.terms != null)
          _NavRow(
            icon: Icons.description_outlined,
            label: l10n.terms,
            value: '',
            onTap: () => unawaited(launchUrl(LegalLinks.terms!,
                mode: LaunchMode.externalApplication)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.translate, size: 16, color: p.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.settingsAnalysisLangs,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.smartphone_outlined, size: 16, color: p.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l10n.settingsLocalOnly}\n${l10n.settingsVersion(kAppVersion)}',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
