# Final QA Matrix — PauseSignal

Statuses: `PASS / FAIL / NOT RUN / BLOCKED_EXTERNAL`.
Nothing is marked PASS from automated tests alone where physical
observation is required.

## Device A — core loop (physical hardware required)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 1 | First-run onboarding | Slides render; privacy copy before any prompt | NOT RUN |
| 2 | Launch prompt check | No permission dialogs fire automatically on first open | NOT RUN |
| 3 | Live Mic permission | OS prompt appears only after choosing Live Mic | NOT RUN |
| 4 | Real microphone acoustic response | Live speech/audio moves amplitude + metrics | NOT RUN |
| 5 | Streaming STT (entitled + configured) | Live transcript lands, flagged phrases highlight | NOT RUN |
| 6 | Incident persistence | Flagged session appears in History, survives restart | NOT RUN |
| 7 | Demo Attack | Fully on-device scripted scenario escalates to high risk | NOT RUN |

## Analyze Recording

| # | Test | Expected | Result |
|---|------|----------|--------|
| 8 | WAV import | File loads, acoustic analysis runs | NOT RUN |
| 9 | MP3/M4A import | Decodes where platform codec support exists | NOT RUN |
| 10 | Local mode | On-device result, labeled correctly | NOT RUN |
| 11 | Manual transcript | Pasted text analyzed locally (English + Arabic) | NOT RUN |
| 12 | Enhanced transcription | Entitled + configured only; uploads selected file | NOT RUN |
| 13 | Partial fallback | Acoustic-only result labeled "Partial Analysis" | NOT RUN |

## Device A → Device B — Family Shield (two physical devices)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 14 | Receiver registration | Device B: Enable Family Alerts → `vg_` ID linked | NOT RUN |
| 15 | Trusted Circle add | Device A saves B's `vg_` ID (max 5) | NOT RUN |
| 16 | Family Vault send | Device A sends alert after flagged session | NOT RUN |
| 17 | Actual notification receipt | Device B receives push via relay → OneSignal | NOT RUN |
| 18 | Tap routing | Tap opens FamilyAlertScreen with sender name | NOT RUN |
| 19 | Saved-number dialing | "Call Dad" dials the locally saved trusted number | NOT RUN |
| 20 | Mark Safe | Response notifies Device A | NOT RUN |
| 21 | Still Suspicious | Response notifies Device A | NOT RUN |
| 22 | Foreground behavior | In-app "View" affordance, never auto-navigates | NOT RUN |

## RevenueCat

**Next Gen judging path — Test Store:**

| # | Test | Expected | Result |
|---|------|----------|--------|
| R1 | Judging build with `REVENUECAT_TEST_STORE_KEY` | Paywall shows **REVENUECAT TEST STORE** badge + notice | NOT RUN — needs dashboard key |
| R2 | Test Store purchase | Real RevenueCat sheet; entitlement activates from `CustomerInfo` | NOT RUN |
| R3 | Feature unlock | Purchased tier's features unlock in-app | NOT RUN |
| R4 | Dashboard proof | Transaction visible in RevenueCat Test Store data | NOT RUN |
| R5 | Restore Purchases | Same tier re-derived on reinstall/second device | NOT RUN |
| R6 | Cancellation | Sheet dismissed → paywall stays interactive, no entitlement | NOT RUN |
| R7 | Release-build safety | `REVENUECAT_TEST_STORE_KEY` alone never enables a release build — unavailable state shown | Covered by unit tests; physical release check NOT RUN |

Production-store matrix (future commercial release):
`docs/REVENUECAT_QA.md` — all rows `NOT RUN` pending keyed build +
sandbox account.

## Automated verification (this environment)

| Check | Result |
|-------|--------|
| `flutter analyze` | see FINAL_RELEASE_STATUS.md |
| `flutter test` | see FINAL_RELEASE_STATUS.md |
| `flutter build web --release --base-href /voxguard/` | see FINAL_RELEASE_STATUS.md |
| `flutter build apk --debug` | see FINAL_RELEASE_STATUS.md |
| `server: npm ci && npm test` | see FINAL_RELEASE_STATUS.md |
| Responsive smoke (320px, 360px, ×1.35/1.5 text, short heights) | see FINAL_RELEASE_STATUS.md |
| `flutter build appbundle --release` | `BLOCKED_EXTERNAL` — release keystore required (`android/key.properties` schema configured; build fails loudly without it, never debug-signs) |
| iOS build | `NOT RUN` — macOS/Xcode unavailable on this machine |
