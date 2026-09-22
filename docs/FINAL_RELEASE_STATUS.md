# Final Release Status — VoxGuard

Statuses: `DONE` / `FAILED` / `NOT RUN` / `BLOCKED_EXTERNAL` /
`BLOCKED_DECISION`. Generated during the foundation-freeze pass after
Sprint 6. External items are explicitly blocked on credentials, hardware,
or accounts — nothing unverified is claimed DONE.

## Repo-side product work

| Item | Status | Proof |
|------|--------|-------|
| Truth sweep — no interception/background/probability/guarantee claims | DONE | repo sweep; disclaimer strings in `app_strings.dart` |
| Package-ID collision resolved | DONE | `com.nemesisdevx.voxguard` — Android `applicationId`/`namespace`, Kotlin package path, iOS/macOS bundle IDs, Linux app ID, Windows runner; zero active release configuration uses `com.voxguard.app` (historical docs retain it factually) |
| Incident deletion | DONE | `IIncidentRepository.deleteIncident` — persisted + in-memory impls, AppBar delete action with confirm dialog; persisted impl writes storage first and reports failure only via `IncidentPersistenceException` (no silent swallow), UI shows safe retry copy |
| Live Shield removed from release UI | DONE | roadmap-only in README |
| Responsive + large-text smoke | DONE | `test/responsive_smoke_test.dart` |
| Arabic/RTL first-strong-direction detection | DONE | `threat_phrase_highlighter.dart` + tests |
| Reduced-motion respect (Signal Lens) | DONE | `MediaQuery.disableAnimations` wired — ambient breathing stops, state still renders |
| Acoustic-only truthfulness | DONE | `SignalLens.conversationAnalyzed` — missing conversation layer renders `ACOUSTIC ONLY` + real acoustic anomaly, never a fused SAFE verdict; `test/design_state_test.dart` |
| Semantic-analysis provenance | DONE | `SafeCallMonitoring.semanticAnalysisHasRun` — set only after `SemanticThreatService.analyze` completes over non-empty context (benign zero-signal results count); STT liveness, transcript text and displayed partials do NOT flip the lens; first partial stays `ACOUSTIC ONLY` through the ~1200 ms debounce, then full fused mode appears; reset returns scope to acoustic-only |
| Stale semantic-result safety | DONE | `_sessionGeneration` + `_semanticRequestSeq` — results validate generation AND request recency before committing; a Future from a torn-down session or a superseded request mutates nothing (generation bumps in `_teardownAudio`, covering end/reset/restart/close); `ISemanticThreatAnalyzer` seam allows deterministic completer-driven tests |
| Display name `VoxGuard` normalized | DONE | Android label, iOS `CFBundleDisplayName`, web title/manifest |
| Original VoxGuard icon — all densities + adaptive + web | DONE — **provisional** | `tool/generate_icons.py` → mipmap-*/AppIcon/web icons; shield motif predates the Signal Lens direction — final icon ships with the public rebrand per the SignalMark visual language |
| Branded launch screens (Android + iOS) | DONE | `launch_background.xml`, `LaunchScreen.storyboard` |
| `web/privacy.html` + `web/terms.html` | DONE | honest current-behavior copy; GitHub Issues as project support route |
| Legal link defaults | DONE | `LegalLinks` defaults to the deployed GitHub Pages URLs; `VOXGUARD_*_URL` dart-defines remain valid overrides |
| Android release-signing config | DONE | `key.properties` (storeFile/storePassword/keyAlias/keyPassword) takes priority, `VOXGUARD_KEYSTORE_FILE`/`VOXGUARD_KEYSTORE_PASSWORD`/`VOXGUARD_KEY_ALIAS`/`VOXGUARD_KEY_PASSWORD` env fallback; release without credentials fails loudly — `test/release_signing_config_test.dart` |
| iOS push entitlements wired | DONE | `RunnerDebug.entitlements` (development) / `RunnerRelease.entitlements` (production) + `CODE_SIGN_ENTITLEMENTS` in Runner Debug/Release/Profile configs |
| Screenshot harness reproducible | DONE | `test/screenshot_capture_test.dart` regenerates exactly the 7 committed filenames; fixtures use production `highRisk`; Arabic transcript renders real Noto Naskh glyphs via `fontFamilyFallback` |
| Third-party font licensing | DONE | `tool/fonts/NotoNaskhArabic.ttf` unmodified + verbatim upstream `tool/fonts/OFL.txt` (SIL OFL 1.1) + `tool/fonts/README.md` attribution |
| Store metadata pack | DONE | `docs/STORE_METADATA.md` |
| Shipaton submission pack | DONE | `docs/SHIPATON_SUBMISSION.md` |
| Demo script (<2 min) | DONE | `docs/DEMO_SCRIPT.md` |
| OneSignal campaign spec | DONE | `docs/ONESIGNAL_CAMPAIGN.md` |
| Purchase QA checklist | DONE | `docs/REVENUECAT_QA.md` |
| Hardware QA matrix | DONE | `docs/FINAL_QA.md` |
| 1179×2556 screenshots (7) | DONE | `submission/screenshots/` — real renders at native size, verified dimensions |
| 1024×1024 icon | DONE — provisional | `submission/voxguard-icon-1024.png` verified dimensions; not the final Design Award identity — pending public rebrand |
| MIT license (Next Gen OSS requirement) | DONE | `LICENSE` |

## External requirements — none fabricated

| Requirement | Status | Blocker |
|-------------|--------|---------|
| Public release brand | BLOCKED_DECISION | `docs/BRAND_RELEASE_DECISION.md` — existing published "VoxGuard" product + related trademark filing; rename reserved for design sprint |
| Android release keystore | BLOCKED_EXTERNAL | `android/key.properties` + `.jks` not present in repo (correctly gitignored); build configured to fail loudly without them |
| `flutter build appbundle --release` | BLOCKED_EXTERNAL | needs the keystore above — verified to abort with `BLOCKED_EXTERNAL — release keystore required` |
| Google Play developer account | BLOCKED_EXTERNAL | account + $25 fee, external |
| Google Play production eligibility (closed testing etc.) | BLOCKED_EXTERNAL | account policy requirements |
| Apple Developer account | BLOCKED_EXTERNAL | $99/yr, external |
| iOS build verification | NOT RUN | no macOS/Xcode on this machine |
| iOS push signing | BLOCKED_EXTERNAL | needs Apple Team ID, provisioning profile, APNs key — entitlements files are wired, credentials are external |
| Store listing live | BLOCKED_EXTERNAL | store accounts + review time |
| US availability | BLOCKED_EXTERNAL | store distribution checkbox |
| RevenueCat Dashboard products/entitlements/Offering | BLOCKED_EXTERNAL | dashboard config; docs in `docs/REVENUECAT_SETUP.md` |
| Real sandbox purchase observed | NOT RUN | keyed build + physical device |
| Judge premium-access method | BLOCKED_EXTERNAL | choose at submission: demo mode suffices for judging loop; or RC promotional/sandbox access |
| Privacy URL live | DONE | `https://nemesisdevx.github.io/voxguard/privacy.html` — HTTP 200 verified |
| Terms URL live | DONE | `https://nemesisdevx.github.io/voxguard/terms.html` — HTTP 200 verified |
| OneSignal campaign deployed | BLOCKED_EXTERNAL | dashboard credentials; spec in `docs/ONESIGNAL_CAMPAIGN.md` |
| OneSignal App ID | BLOCKED_EXTERNAL | `ONESIGNAL_APP_ID` dart-define at build time |
| Physical two-device push test | NOT RUN | needs 2 devices + configured relay/OneSignal |
| Physical Live Mic/STT test | NOT RUN | physical device + mic |
| Prerecorded transcription real-provider test | NOT RUN | `ASSEMBLYAI_*` config + device |
| Public YouTube/Vimeo demo | BLOCKED_EXTERNAL | record per `docs/DEMO_SCRIPT.md` |
| RevenueCat Project ID | BLOCKED_EXTERNAL | dashboard value for Devpost form |
| Devpost submission | BLOCKED_EXTERNAL | manual submission before Sep 30, 2026 11:45 PM PDT |

## Automated verification (latest run — stale-semantic-result patch)

| Check | Result |
|-------|--------|
| `flutter pub get` | PASS |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 308/308 |
| `flutter build web --release --base-href /voxguard/` | PASS |
| `flutter build apk --debug` | PASS |
| `cd server && npm ci && npm test` | PASS — 41/41 |
| Screenshot capture (`--update-goldens --dart-define=CAPTURE_SHOTS=true`) | PASS — 7 PNGs at 1179×2556, exact committed filenames, Arabic glyphs verified rendered |
| Submission icon | `submission/voxguard-icon-1024.png` — 1024×1024 verified |
| `flutter build appbundle --release` | Expected fail-loud: `BLOCKED_EXTERNAL — release keystore required` (correct — no credentials present) |
| iOS build | NOT RUN — no macOS/Xcode |
