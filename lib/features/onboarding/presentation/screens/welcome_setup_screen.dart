import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/preferences/app_preferences.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/signal_mark.dart';

/// First-run Welcome Setup — runs before the safety/privacy
/// onboarding. Language + an optional local-only display name.
///
/// Emotionally calm by design: a restrained tonal gradient hero,
/// the SignalMark, generous spacing. No flags, no permissions, no
/// account, no cloud — the name never leaves SharedPreferences.
class WelcomeSetupScreen extends StatefulWidget {
  const WelcomeSetupScreen({super.key, required this.onDone});

  /// Called after setup completes (name saved or skipped) so the
  /// gate can advance to the safety onboarding.
  final VoidCallback onDone;

  @override
  State<WelcomeSetupScreen> createState() => _WelcomeSetupScreenState();
}

class _WelcomeSetupScreenState extends State<WelcomeSetupScreen> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  AppPreferences get _prefs => AppPreferencesLocator.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool saveName}) async {
    if (_saving) return;
    _saving = true;
    if (saveName) {
      await _prefs.setDisplayName(_nameCtrl.text);
    }
    await _prefs.completeSetup();
    // The gate listens to preferences and advances itself; the
    // callback exists for direct-push contexts (tests).
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // One restrained gradient — the welcome hero is one of the
          // few surfaces where tonal depth earns its place.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.bgSurface, p.bgBase],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            children: [
              Center(child: SignalMark(size: 72, color: p.accent,
                  secondaryColor: p.signalAcoustic)),
              const SizedBox(height: 26),
              Text(
                l10n.welcomeTitle,
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 34),
              Text(l10n.welcomeLanguageLabel,
                  style: AppTypography.labelSmall),
              const SizedBox(height: 10),
              _LanguagePicker(prefs: _prefs),
              const SizedBox(height: 30),
              Text(l10n.welcomeNamePrompt, style: AppTypography.titleMedium),
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                maxLength: AppPreferences.maxDisplayNameLength,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: l10n.welcomeNameHint,
                  counterText: '',
                ),
                onSubmitted: (_) => _finish(saveName: true),
              ),
              const SizedBox(height: 6),
              Text(l10n.welcomeNameNote, style: AppTypography.bodyMedium),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => _finish(saveName: true),
                child: Text(l10n.welcomeContinue),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _finish(saveName: false),
                  child: Text(l10n.actionSkipSetup),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Language choice as text-only segmented options — deliberately no
/// country flags. Selecting one applies immediately (the whole app
/// rebuilds on the preference change).
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.prefs});

  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = <(AppLocaleOption, String)>[
      (AppLocaleOption.system, l10n.welcomeLanguageSystem),
      (AppLocaleOption.en, l10n.languageEn),
      (AppLocaleOption.ar, l10n.languageAr),
      (AppLocaleOption.es, l10n.languageEs),
      (AppLocaleOption.fr, l10n.languageFr),
    ];
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        return Column(
          children: [
            for (final (option, label) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _LanguageTile(
                    label: label,
                    selected: prefs.localeOption == option,
                    onTap: () => unawaited(prefs.setLocale(option)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: selected ? p.accentMuted.withValues(alpha: 0.35) : p.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? p.accent : p.borderSubtle,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.titleMedium)),
              if (selected)
                Icon(Icons.check_circle, size: 18, color: p.accent),
            ],
          ),
        ),
      ),
    );
  }
}
