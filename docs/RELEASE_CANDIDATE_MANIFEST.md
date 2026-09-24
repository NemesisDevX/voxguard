# Release Candidate Manifest — PauseSignal

*Factual snapshot of the pre-credential build. Update the SHA and
live-status rows after the credentials + live-QA phase.*

## Build identity

| Field | Value |
|---|---|
| Product | PauseSignal — *Hear the signal. Pause. Verify.* |
| Repository | `NemesisDevX/voxguard` (public, MIT) |
| Dart package | `voxguard` |
| Android application ID | `com.nemesisdevx.voxguard` |
| Branch | `main` |
| Product-code freeze SHA | `d77a714471cee5c9d150ae6282d4cc8f67689f42` — last commit touching product/server source; docs-only commits may follow on `main` |
| Flutter | 3.41.2 (stable) |
| Dart | 3.11.0 |
| Android SDK target | API 36 verified on emulator (sdk gphone64 x86_64) |

## Build outputs

| Artifact | Path / location |
|---|---|
| Android debug/judging APK | `build/app/outputs/flutter-apk/app-debug.apk` |
| Web release | `build/web/` → GitHub Pages `https://nemesisdevx.github.io/voxguard/` (browser demo experience, not mobile parity) |
| Release signing | `android/key.properties` or `VOXGUARD_KEYSTORE_*` env — debug keys never substituted |

## Monetization contract

- Entitlements: `sentinel`, `family_vault`
- Packages: `sentinel_monthly`, `sentinel_annual`,
  `family_vault_monthly`, `family_vault_annual`
- Backends: production store / RevenueCat Test Store / labelled Demo
  Store / truthful Unavailable — `CustomerInfo` sole authority.

## Localization

581 keys per locale — English, Arabic (RTL), Spanish, French — parity
enforced by test.

## Server routes (Cloudflare Worker — `server/`)

| Route | Purpose |
|---|---|
| `POST /alert` | Family Shield → OneSignal relay |
| `GET\|POST /aai-token` | AssemblyAI streaming-token broker (`Cache-Control: no-store`) |
| `POST /transcription/jobs` | prerecorded transcription submit (≤25 MB) |
| `GET /transcription/jobs/{id}` | compact job status polling |
| `POST /semantic` | Groq semantic proxy (normalized signals only) |

## Integration status

| Integration | Repo state | Live? |
|---|---|---|
| RevenueCat | implemented, Test Store path ready | **no** — needs dashboard + key |
| AssemblyAI streaming | broker path implemented | **no** — needs `ASSEMBLYAI_API_KEY` |
| AssemblyAI prerecorded | relay implemented | **no** — same secret |
| Groq semantic | proxy implemented; local fallback authoritative | **no** — needs `GROQ_API_KEY` |
| OneSignal / Family Shield | relay + receiver registration implemented | **no** — needs app + REST key |

## Test / build state at this SHA

`flutter analyze` 0 issues · Flutter tests 421/421 · server tests
74/74 · web release build PASS · Android debug APK PASS · CI green ·
wrangler deploy dry-run PASS.

## Judging assets

- `submission/screenshots/01–07_*.png` — 7 frames, 1179×2556
- `submission/review/*.png` — 4 review captures, 1179×2556
- `submission/pausesignal-icon-1024.png` — 1024×1024 SignalMark
- `submission/README.md` — asset provenance
- `submission/SUBMISSION_DRAFT.md` — draft text + judge walkthrough
- `docs/FINAL_LIVE_QA_HANDOFF.md` — operational handoff

## Remaining human actions (ordered)

1. RevenueCat dashboard: project, Project ID, 4 products, 2
   entitlements, CURRENT Offering, Test Store key
2. AssemblyAI API key → `wrangler secret put ASSEMBLYAI_API_KEY`
3. Groq API key → `wrangler secret put GROQ_API_KEY`
4. OneSignal app → App ID + `wrangler secret put ONESIGNAL_REST_API_KEY`
5. `RELAY_CLIENT_TOKEN` secret + `wrangler.toml [vars]` → `wrangler deploy`
6. Judging-build env per `docs/FINAL_LIVE_QA_HANDOFF.md` §F
7. Emulator live QA → physical Android QA
8. Evidence capture → finalize `submission/SUBMISSION_DRAFT.md`
9. Demo video (deferred) → submission

*No external provider has been verified live as of this SHA.*
