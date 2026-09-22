# Personalization & Localization

Status: **implemented foundation** — covers the preference model,
first-run Welcome Setup, interface localization, theme/accent/text
scaling, Guided Mode, motion and haptics rules. Public rebrand is
still `BLOCKED_DECISION` (`BRAND_RELEASE_DECISION.md`); everything
here is name-agnostic.

---

## 1. Preference model

`AppPreferences` (`lib/core/services/preferences/app_preferences.dart`)
is the single persistent, local-only preference store, hydrated before
`runApp` and exposed through `AppPreferencesLocator` (same locator
style as the rest of the codebase). `ChangeNotifier` — the root
`VoxGuardApp` rebuilds on every change, so edits apply instantly
without restart.

| Preference | Values | Storage key |
|---|---|---|
| Setup completed | bool | `vg.pref.setup_completed` |
| Display name | trimmed string, ≤ 32 chars | `vg.pref.display_name` |
| Locale | `system`, `en`, `ar`, `es`, `fr` | `vg.pref.locale` |
| Theme mode | `system`, `light`, `dark` | `vg.pref.theme_mode` |
| Accent | `periwinkle`, `softBlue`, `softViolet` | `vg.pref.accent` |
| Text size | `system`, `large`, `extraLarge` | `vg.pref.text_size` |
| Motion | `system`, `reduced` | `vg.pref.motion` |
| Haptics | `on`, `off` | `vg.pref.haptics` |
| Experience mode | `standard`, `guided` | `vg.pref.experience_mode` |

Storage uses stable **enum IDs**, never localized strings — a rename
or translation change can never orphan a setting. Corrupt/unknown
persisted values fall back to safe defaults; startup cannot crash on
bad data (`_enumById`). Tests use `AppPreferences.inMemory(...)`.

### Local-only privacy

Nothing in this layer leaves the device: no account, no sync, no
analytics. The display name is rendered on the user's own Home screen
and is **never** placed in Family Shield payloads (asserted by
`test/personalization_test.dart` → "local display name never enters
the alert payload").

## 2. First-run Welcome Setup

`StartupGate` chains: `LaunchSplash` → `WelcomeSetupScreen`
(first run only) → existing safety/privacy onboarding → `HomeScreen`.

- Language picker offers Follow device / English / العربية /
  Español / Français — text labels only, **no flags**. Selection
  applies immediately to the welcome screen itself (the whole app
  rebuilds on the preference notification).
- "What should we call you?" — optional, skippable, trimmed, ≤ 32
  chars, local-only. No account, no login, no cloud.
- No microphone or notification permission is requested during
  Welcome Setup (covered by test).
- `LaunchSplash` is a finite 900 ms SignalMark converge animation —
  no fake progress, no artificial delay; under reduced motion it is
  a static fade. The gate stays `home:` so Family Shield cold-start
  routing through the shared navigator key is unaffected.

## 3. Localization

Proper Flutter localization: `flutter_localizations` + `gen_l10n`
(`l10n.yaml`, sources in `lib/l10n/arb/`, output in
`lib/l10n/generated/`). **532 message keys**, identical sets across
`en`, `ar`, `es`, `fr` — parity enforced by test.

- `context.l10n` for widgets; `l10n`/`l10nGlobal` accessor resolves
  the pinned preference locale → platform locale → English, and is
  binding-safe for domain/service code paths in tests.
- `LocalizedText` (`lib/core/l10n/localized_text.dart`) maps frozen
  domain/service English messages to localized strings at the
  presentation layer — engines and persisted data are untouched;
  unrecognized messages pass through unchanged.
- Arabic uses full RTL layout automatically. Mixed Arabic/Latin
  transcript rendering keeps the existing first-strong-direction
  behavior (Noto Naskh fallback in captures).

### Analysis-language limitation (must stay truthful)

Interface localization does **not** expand engine coverage.
Conversation-risk analysis currently supports **English and Egyptian
Arabic only**. Settings → About states this in every locale:
*"Conversation-risk analysis currently supports English and Egyptian
Arabic. The app interface language can be changed independently."*

## 4. Theme, accent, text size

`AppPalette` (`lib/core/theme/app_palette.dart`) is a
`ThemeExtension` carrying the full token set — background, surface,
elevated surface, card, border, primary/muted text, accent, and the
semantic safety colors (`statusSafe`, `statusWarning`,
`statusDanger`, `signalSemantic`, `signalAcoustic`, `signalAbsent`).

- Dark: deep ink `#0B0D13`, blue-tinted surfaces, warm off-white
  text, periwinkle accent. Light: warm off-white `#F6F3EC`, white
  elevated surfaces, ink text, cool borders. Both are real themes,
  not a scaffold repaint.
- Accent is a closed set of three curated families. Accents tint
  interactive surfaces only — they can **never** recolor safety
  semantics (test-enforced: status/signal colors identical across
  accents in both brightnesses).
- Theme changes apply instantly via `ListenableBuilder` on prefs;
  `themeAnimationDuration` is a 180 ms crossfade, or zero under
  reduced motion.
- Text size is a **floor**, not an override: effective scale =
  `max(osScale, appFloor)` where floors are 1.0 / 1.18 / 1.35. The
  app can enlarge text but can never shrink below the user's OS
  accessibility setting.

## 5. Guided Mode

Standard / Guided in Settings. Guided is **not** an "elderly mode":
larger primary actions, clearer guidance, technical evidence
de-emphasized but never removed, more spacing. Implemented as shared
layout conditions (`context.isGuided`) inside the existing screens —
not a parallel implementation, and risk behavior is untouched
(test-verified).

## 6. Motion and haptics

- Motion: Follow system / Reduced. The root `MediaQuery` ORs the OS
  `disableAnimations` with the app preference — **either source
  wins**. Under reduced motion: Signal Lens breathing stops,
  theme transitions are instant, launch animation is a static fade.
  Meaningful state changes (risk bands, evidence) are never
  animated away.
- Haptics: `AppHaptics.confirm/.tap/.alert` is the single
  preference-aware wrapper; every `HapticFeedback` call goes through
  it. `Haptics: Off` suppresses all app haptics (test-verified at
  the platform channel). Haptics stay restrained — monitoring start,
  risk-band escalation, important confirmations, Family Shield
  human responses. Never continuous, never per transcript update.

## 7. Notifications section truthfulness

Settings → Notifications shows the **real** push permission /
registration state and opens the device's app-notification settings
via `permission_handler.openAppSettings()`. There is deliberately
no fake custom sound picker — notification sound and per-app
behavior are controlled by the OS, and the UI says so.

## 8. Tests

`test/personalization_test.dart` (21 tests) covers: ARB parity and
truth sweep, preference defaults/round-trip/corrupt-fallback/name
sanitization, Welcome Setup skip + name persistence + immediate
language switch + RTL + no permission prompts, accent vs semantic
color separation, text-scale floor both directions, reduced motion
from OS and app, haptics suppression, Guided Mode presentation
delta, Family Shield payload name exclusion, and 360 px / 1.5×
rendering in all four locales.
