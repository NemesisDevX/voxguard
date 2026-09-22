# PauseSignal — Next Gen Submission Handoff

Operational handoff for the human/external steps. Everything
repo-side is verified; everything external is explicitly labelled.
Nothing here is fabricated — credentials, accounts, device QA and
student eligibility remain human-owned.

**Active target: RevenueCat Shipaton 2026 — Next Gen Award only.**
Next Gen requires a working app + <2 min demo video + public
open-source repo + MIT license. A store listing, release keystore,
paid developer accounts, US availability, and judge free-trial/promo
codes are **NOT** Next Gen requirements — they remain future
commercial-release items (final section).

## Current verified repo baseline

| Item | Value |
|---|---|
| Branch | `main` |
| Public brand | **PauseSignal** — `Hear the signal. Pause. Verify.` (`docs/BRAND_RELEASE_DECISION.md`) |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 378 tests |
| `cd server && npm test` | PASS — 41 tests |
| `flutter build web --release --base-href /voxguard/` | PASS |
| `flutter build apk --debug` | PASS |
| Localization parity | 581 non-metadata ARB keys × `en`/`ar`/`es`/`fr`, identical key sets |
| iOS localization metadata | `knownRegions` = en/Base/ar/es/fr + per-locale `.strings` variant children (statically verified — no Xcode run) |
| Package ID | `com.nemesisdevx.voxguard` (unchanged — technical identity) |
| Version | `1.0.0+1` |
| Icon | SignalMark — `submission/pausesignal-icon-1024.png`, 1024×1024 |
| Screenshots | 7 frames, 1179×2556, `submission/screenshots/` |
| GitHub Pages privacy/terms | LIVE — `/voxguard/privacy.html`, `/voxguard/terms.html` |

## Next Gen submission — remaining human steps

- **Active-student eligibility + academic/student email** on Devpost.
- **RevenueCat dashboard**: create the project, configure the
  built-in Test Store with the four products/entitlements, copy the
  Test Store API key and Project ID
  (`docs/NEXT_GEN_REVENUECAT_TEST_STORE.md`).
- **Working judging build** with the Test Store key:
  `flutter build apk --debug --dart-define=REVENUECAT_TEST_STORE_KEY=<key>`
- **One real Test Store transaction observed** in the RevenueCat
  dashboard + `CustomerInfo` entitlement unlock in-app.
- **Public demo video < 2 min** per `docs/DEMO_SCRIPT.md`.
- **Devpost form** submission (deadline Sep 30, 2026 11:45 PM PDT).

Not required for Next Gen (do not let these block the submission):
store publication, store review, `key.properties` release signing,
paid Apple/Google developer accounts, US availability, promo codes /
free-trial judge access (the Test Store path IS the judging access).

## Exact commands

```bash
# Dependencies + static checks
flutter pub get
flutter analyze
flutter test
cd server && npm ci && npm test && cd ..

# Android judging build (Next Gen path — Test Store key required
# for the real RevenueCat purchase demo; without it debug builds
# fall back to the labelled Demo Store)
flutter build apk --debug \
  --dart-define=REVENUECAT_TEST_STORE_KEY=<test-store-key>

# Optional extra integrations for the judging build:
#   --dart-define=ONESIGNAL_APP_ID=<app-id>
#   --dart-define=VOXGUARD_ALERT_RELAY_URL=<relay-url>
#   --dart-define=VOXGUARD_RELAY_TOKEN=<relay-token>
#   --dart-define=ASSEMBLYAI_TOKEN_BROKER_URL=<broker-url>
#   --dart-define=VOXGUARD_RECORDING_TRANSCRIPTION_URL=<relay-url>

# Web demo deploy source (GitHub Pages serves /voxguard/)
flutter build web --release --base-href /voxguard/

# Regenerate judging screenshots
flutter test test/screenshot_capture_test.dart --update-goldens \
  --dart-define=CAPTURE_SHOTS=true

# Regenerate the icon set
python tool/generate_icons.py
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
10. **RevenueCat Test Store purchase** on the judging build —
    paywall shows REVENUECAT TEST STORE, entitlement activates from
    `CustomerInfo`, transaction visible in the dashboard.
11. Restore Purchases on a second install/device.
12. Entitlement refresh without restart.
13. Family Shield end-to-end on two physical devices (relay + OneSignal configured).
14. OneSignal notification: foreground, background, tap → alert route.
15. Arabic RTL sweep; French/Spanish smoke.
16. Reduced motion; Guided Mode; text-size floor.
17. Offline / relay-down / provider-unconfigured error states.

## Future commercial release — NOT Next Gen blockers

Kept honest and separate; none of these gate the Next Gen submission:

- Android release keystore (`android/key.properties` or the four
  `VOXGUARD_KEYSTORE_*` env vars) — `flutter build appbundle
  --release` still fails loudly without them by design.
- Google Play / App Store listings, review, US availability.
- Paid developer accounts; iOS build + signing (needs macOS/Xcode).
- Production RevenueCat platform keys (`REVENUECAT_ANDROID_KEY` /
  `REVENUECAT_IOS_KEY`) + sandbox-purchase QA
  (`docs/REVENUECAT_SETUP.md`, `docs/REVENUECAT_QA.md`).
- OneSignal App ID + REST key (server-side only) + relay deployment;
  two-device Family Shield proof.
- AssemblyAI production broker/relay credentials.
- A commercial-release judge/store promo mechanism, if ever needed.

## Secret handling

Never commit credentials — `.gitignore` covers `key.properties`,
`*.jks`, `.env`. The tracked tree passed a secret-pattern audit at
the previous RC SHA and again in this state.
