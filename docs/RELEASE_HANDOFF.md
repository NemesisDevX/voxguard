# Release Candidate 1 — Handoff

Operational handoff for the human/external release steps. Everything
repo-side is verified; everything external is explicitly labelled.
Nothing here is fabricated — credentials, accounts, device QA and the
public brand remain human-owned.

## Current verified repo baseline

| Item | Value |
|---|---|
| Commit | `dc517e0ef160ceb9d8ae2fb69b3496b7515e77f3` (`fix: close remaining localization bypasses`) + this handoff commit |
| Branch | `main` |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 361 tests |
| `cd server && npm test` | PASS — 41 tests |
| `flutter build web --release --base-href /voxguard/` | PASS |
| `flutter build apk --debug` | PASS |
| `flutter build appbundle --release` | BLOCKED_EXTERNAL — keystore absent; build aborts loudly with `BLOCKED_EXTERNAL — release keystore required` (verified behavior, not a defect) |
| Localization parity | 577 non-metadata ARB keys × `en`/`ar`/`es`/`fr`, identical key sets |
| Package ID | `com.nemesisdevx.voxguard` (final for this release line) |
| Version | `1.0.0+1` |
| Public brand | `BLOCKED_DECISION` — see `docs/BRAND_RELEASE_DECISION.md` |
| GitHub Pages privacy/terms | LIVE — HTTP 200 verified earlier (`/voxguard/privacy.html`, `/voxguard/terms.html`) |

## Human decisions required

- **Final public product name / brand.** "VoxGuard" is the internal
  working name only — a published product plus a related trademark
  filing already use it. Keep or replace is a human call; the rename
  inventory is ready (`docs/BRAND_RENAME_INVENTORY.md`).
- **Judge premium-access method** for Shipaton (demo mode is already
  sufficient for the judging loop; a RevenueCat promotional/sandbox
  grant is the alternative).
- **US availability** at store distribution time.

## Credentials / accounts required

| What | Where it goes | Status |
|---|---|---|
| Android keystore `.jks` + store/key passwords + alias | `android/key.properties` or env `VOXGUARD_KEYSTORE_FILE` / `VOXGUARD_KEYSTORE_PASSWORD` / `VOXGUARD_KEY_ALIAS` / `VOXGUARD_KEY_PASSWORD` | BLOCKED_EXTERNAL — do NOT commit |
| Google Play Console account | store listing, review, US availability | BLOCKED_EXTERNAL |
| Apple Developer account + APNs key/provisioning | iOS build + push signing | BLOCKED_EXTERNAL |
| RevenueCat public SDK keys | `--dart-define=REVENUECAT_ANDROID_KEY` / `REVENUECAT_IOS_KEY` | BLOCKED_EXTERNAL |
| RevenueCat dashboard config | entitlements `sentinel`, `family_vault`; products/offering per `docs/REVENUECAT_SETUP.md` | BLOCKED_EXTERNAL |
| OneSignal App ID | `--dart-define=ONESIGNAL_APP_ID` | BLOCKED_EXTERNAL |
| OneSignal REST API key | **server-side only** (`server/.env`), never the client | BLOCKED_EXTERNAL |
| Alert relay deployment | `--dart-define=VOXGUARD_ALERT_RELAY_URL` + `VOXGUARD_RELAY_TOKEN`; server env in `server/.env.example` | BLOCKED_EXTERNAL |
| AssemblyAI production path | `ASSEMBLYAI_TOKEN_BROKER_URL` (streaming) + `VOXGUARD_RECORDING_TRANSCRIPTION_URL` (prerecorded, relay holds `ASSEMBLYAI_API_KEY` server-side) | BLOCKED_EXTERNAL |
| Live transcription relay | same relay/token pair as Family Shield | BLOCKED_EXTERNAL |

Never commit any of these values — `.gitignore` already covers
`key.properties`/`*.jks`/`.env`; the tracked tree passed a
secret-pattern audit at this SHA.

## Exact release commands

```bash
# Dependencies + static checks
flutter pub get
flutter analyze
flutter test
cd server && npm ci && npm test && cd ..

# Web release (GitHub Pages deploys /voxguard/)
flutter build web --release --base-href /voxguard/

# Android debug APK (no credentials needed)
flutter build apk --debug

# Android release AAB — once the keystore exists locally:
#   android/key.properties with storeFile/storePassword/keyAlias/
#   keyPassword, or the four VOXGUARD_* env vars.
flutter build appbundle --release \
  --dart-define=ONESIGNAL_APP_ID=<app-id> \
  --dart-define=VOXGUARD_ALERT_RELAY_URL=<relay-url> \
  --dart-define=VOXGUARD_RELAY_TOKEN=<relay-token> \
  --dart-define=REVENUECAT_ANDROID_KEY=<goog_...> \
  --dart-define=ASSEMBLYAI_TOKEN_BROKER_URL=<broker-url> \
  --dart-define=VOXGUARD_RECORDING_TRANSCRIPTION_URL=<relay-url>

# Optional dart-defines:
#   REVENUECAT_IOS_KEY        iOS real-store key
#   VOXGUARD_PRIVACY_POLICY_URL / VOXGUARD_TERMS_URL  (defaults are live)
#   VOXGUARD_TEST_FAMILY_EXTERNAL_ID               dev recipient override
# Dev-only escape hatches (NEVER in a shipped build):
#   ASSEMBLYAI_API_KEY, GROQ_API_KEY,
#   VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC
```

## Physical QA matrix

Every row is **NOT RUN** until executed on real hardware. Order:

1. Fresh install → launch → Welcome Setup → safety onboarding.
2. Live Mic permission prompt at first session start (not before).
3. Live Mic session — acoustic anomaly indicators live.
4. Acoustic-only state before conversation analysis completes.
5. Semantic/conversation state after analysis runs (EN + Egyptian AR).
6. Post-call sheet — Family Alert send (demo vs real relay truthfully labelled).
7. Recording Analysis — pick file, partial on-device result.
8. Real transcription provider path (broker/relay configured build).
9. Incident persistence → detail → share text → delete.
10. RevenueCat sandbox purchase on a keyed build.
11. Restore Purchases on a second install/device.
12. Entitlement refresh without restart.
13. Family Shield end-to-end on two physical devices (relay + OneSignal configured).
14. OneSignal notification: foreground, background, tap → alert route.
15. Arabic RTL sweep; French/Spanish smoke.
16. Reduced motion; Guided Mode; text-size floor.
17. Offline / relay-down / provider-unconfigured error states.

## Shipaton handoff — human artifacts still required

- Final public brand decision (then run the rename inventory pass).
- Live store URL + US availability confirmation.
- RevenueCat Project ID for the Devpost form.
- Premium judge-access method decision.
- Final screenshots after any brand change (harness:
  `test/screenshot_capture_test.dart --update-goldens --dart-define=CAPTURE_SHOTS=true`).
- Public demo video per `docs/DEMO_SCRIPT.md`.
- Devpost submission form itself (deadline Sep 30, 2026 11:45 PM PDT).
- OneSignal campaign deployment proof if targeting that prize —
  spec in `docs/ONESIGNAL_CAMPAIGN.md`; currently BLOCKED_EXTERNAL.
