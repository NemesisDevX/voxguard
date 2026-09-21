# Final Release Status — VoxGuard

Statuses: `DONE` / `FAILED` / `NOT RUN` / `BLOCKED_EXTERNAL`.
Generated during the Sprint 6 finalization pass. External items are
explicitly blocked on credentials, hardware, or accounts — nothing
unverified is claimed DONE.

## Repo-side product work

| Item | Status | Proof |
|------|--------|-------|
| Truth sweep — no interception/background/probability/guarantee claims | DONE | repo sweep; disclaimer strings in `app_strings.dart` |
| Live Shield removed from release UI | DONE | roadmap-only in README |
| Responsive + large-text smoke | DONE | `test/responsive_smoke_test.dart` — 6/6 |
| Arabic/RTL first-strong-direction detection | DONE | `threat_phrase_highlighter.dart` + tests |
| Reduced-motion respect (ThreatCore) | DONE | `MediaQuery.disableAnimations` wired |
| Display name `VoxGuard` normalized | DONE | Android label, iOS `CFBundleDisplayName`, web title/manifest |
| Original VoxGuard icon — all densities + adaptive + web | DONE | `tool/generate_icons.py` → mipmap-*/AppIcon/web icons |
| Branded launch screens (Android + iOS) | DONE | `launch_background.xml`, `LaunchScreen.storyboard` |
| `web/privacy.html` + `web/terms.html` | DONE | honest current-behavior copy, placeholders marked |
| Android release-signing config (key.properties, fail-loud) | DONE | `android/app/build.gradle.kts` |
| iOS `Runner.entitlements` prepared (aps-environment) | DONE | file present; Xcode capability wiring is manual step |
| Store metadata pack | DONE | `docs/STORE_METADATA.md` |
| Shipaton submission pack | DONE | `docs/SHIPATON_SUBMISSION.md` |
| Demo script (<2 min) | DONE | `docs/DEMO_SCRIPT.md` |
| OneSignal campaign spec | DONE | `docs/ONESIGNAL_CAMPAIGN.md` |
| Purchase QA checklist | DONE | `docs/REVENUECAT_QA.md` |
| Hardware QA matrix | DONE | `docs/FINAL_QA.md` |
| 1179×2556 screenshots (7) | DONE | `submission/screenshots/` — real renders at native size |
| 1024×1024 icon | DONE | `submission/voxguard-icon-1024.png` verified dimensions |
| MIT license (Next Gen OSS requirement) | DONE | `LICENSE` |

## External requirements — none fabricated

| Requirement | Status | Blocker |
|-------------|--------|---------|
| Android release keystore | BLOCKED_EXTERNAL | `android/key.properties` + `.jks` not present in repo (correctly gitignored); build configured to fail loudly without them |
| `flutter build appbundle --release` | BLOCKED_EXTERNAL | needs the keystore above |
| Google Play developer account | BLOCKED_EXTERNAL | account + $25 fee, external |
| Google Play production eligibility (closed testing etc.) | BLOCKED_EXTERNAL | account policy requirements |
| Apple Developer account | BLOCKED_EXTERNAL | $99/yr, external |
| iOS build verification | NOT RUN | no macOS/Xcode on this machine |
| iOS push capability wiring | BLOCKED_EXTERNAL | needs Xcode: add Push Notifications capability → `Runner.entitlements`, flip `aps-environment` to `production` for release |
| Store listing live | BLOCKED_EXTERNAL | store accounts + review time |
| US availability | BLOCKED_EXTERNAL | store distribution checkbox |
| RevenueCat Dashboard products/entitlements/Offering | BLOCKED_EXTERNAL | dashboard config; docs in `docs/REVENUECAT_SETUP.md` |
| Real sandbox purchase observed | NOT RUN | keyed build + physical device |
| Judge premium-access method | BLOCKED_EXTERNAL | choose at submission: demo mode suffices for judging loop; or RC promotional/sandbox access |
| Privacy URL live | BLOCKED_EXTERNAL | `web/privacy.html` ready; needs host (e.g. GitHub Pages) |
| Terms URL live | BLOCKED_EXTERNAL | `web/terms.html` ready; same |
| OneSignal campaign deployed | BLOCKED_EXTERNAL | dashboard credentials; spec in `docs/ONESIGNAL_CAMPAIGN.md` |
| OneSignal App ID | BLOCKED_EXTERNAL | `ONESIGNAL_APP_ID` dart-define at build time |
| Physical two-device push test | NOT RUN | needs 2 devices + configured relay/OneSignal |
| Physical Live Mic/STT test | NOT RUN | physical device + mic |
| Prerecorded transcription real-provider test | NOT RUN | `ASSEMBLYAI_*` config + device |
| Public YouTube/Vimeo demo | BLOCKED_EXTERNAL | record per `docs/DEMO_SCRIPT.md` |
| RevenueCat Project ID | BLOCKED_EXTERNAL | dashboard value for Devpost form |
| Devpost submission | BLOCKED_EXTERNAL | manual submission before Sep 30, 2026 11:45 PM PDT |

## Automated verification (latest run)

See Part U results in the sprint report — `flutter pub get`,
`analyze`, `test`, web release build, APK debug build, server
`npm ci && npm test`. Numbers are reported only from observed runs.
