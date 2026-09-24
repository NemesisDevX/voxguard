# Final Live-QA Handoff — PauseSignal

**The single operational source of truth for the credentials +
live-QA phase.** Everything below assumes the frozen pre-credential
build. Detailed per-topic docs are linked, not duplicated.

> **Never paste real values into this file, source, tests, or git.**
> All secrets travel via `wrangler secret put`, env vars, or
> `--dart-define` — transiently, never committed.

---

## A. Frozen product state

| Item | State |
|---|---|
| Branch / SHA | `main` @ `d77a714471cee5c9d150ae6282d4cc8f67689f42` |
| Flutter tests | 421/421 pass |
| Server tests | 74/74 pass |
| `flutter analyze` | 0 issues |
| Web release build | PASS (`--base-href /voxguard/`) |
| Android debug APK | PASS (`build/app/outputs/flutter-apk/app-debug.apk`) |
| CI | green on the exact SHA |
| Wrangler dry-run | PASS — `npx wrangler deploy --dry-run` (26.32 KiB, no bindings needed) |

Product code, premium UI, scoring, entitlements, protocol, and
monetization are **frozen**. Changes in this phase are limited to
documentation, scripts, and evidence-backed defects.

## B. External services still NOT live

Do not claim otherwise in any artifact:

- RevenueCat Test Store — no transaction has run
- AssemblyAI — no token minted, no live transcription
- Groq — no proxied call has run
- OneSignal — no push delivered; no two-device round trip
- Physical-device QA — emulator-only evidence so far
- iOS — not built or verified (no macOS/Xcode evidence)

## C. Credential intake matrix

Classification: **public build config** / **shared relay credential** /
**server-only secret** / **submission metadata** / **dashboard-only**.

### Mobile / judging build (`--dart-define`)

| Variable | Class | OK in judging APK? | Must never exist in Flutter? | Feature | If absent | Supplied via |
|---|---|---|---|---|---|---|
| `REVENUECAT_TEST_STORE_KEY` | public build config | yes — non-release only (factory refuses it in release) | n/a | Paywall → RevenueCat Test Store | debug → Demo Store; release → Unavailable | `--dart-define` |
| `VOXGUARD_RELAY_TOKEN` | shared relay credential | yes | no — it *is* the client half | Auth on all relay routes | relay features report not-configured / 401 | `--dart-define` (same value as server `RELAY_CLIENT_TOKEN`) |
| `VOXGUARD_ALERT_RELAY_URL` | public build config | yes | no | Family Shield outbound alerts | labelled Demo Mode broadcast | `--dart-define` |
| `VOXGUARD_RECORDING_TRANSCRIPTION_URL` | public build config | yes | no | Analyze Recording → enhanced transcription | option disabled, acoustic-only | `--dart-define` |
| `ASSEMBLYAI_TOKEN_BROKER_URL` | public build config | yes | no | SafeCall streaming token mint | acoustic-only, truthful UI | `--dart-define` |
| `VOXGUARD_SEMANTIC_PROXY_URL` | public build config | yes | no | SafeCall cloud semantic pass | local bilingual engine | `--dart-define` |
| `ONESIGNAL_APP_ID` | public build config | yes | no | Family Shield receiver registration | receiver card shows not-configured | `--dart-define` |

Dev-only defines (`ASSEMBLYAI_API_KEY`, `ASSEMBLYAI_TEMP_TOKEN`,
`GROQ_API_KEY`, `VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC`) are
**release-inaccessible by code** — the resolver and diagnostics both
ignore them in release builds. Never compile them into a judging or
release build anyway.

### Server (Cloudflare Worker env — `server/`)

| Variable | Class | Must never exist in Flutter? | Feature | Supplied via |
|---|---|---|---|---|
| `ASSEMBLYAI_API_KEY` | server-only secret | **yes** | `/aai-token` + `/transcription/jobs` | `wrangler secret put` |
| `GROQ_API_KEY` | server-only secret | **yes** | `/semantic` | `wrangler secret put` |
| `ONESIGNAL_REST_API_KEY` | server-only secret | **yes** | `/alert` | `wrangler secret put` |
| `ONESIGNAL_APP_ID` | dashboard-only value (non-secret) | no | `/alert` target app | `wrangler.toml [vars]` or `wrangler secret put` |
| `RELAY_CLIENT_TOKEN` | shared relay credential | no — client carries `VOXGUARD_RELAY_TOKEN` twin | auth boundary on every route | `wrangler secret put` |
| `ALLOWED_ORIGINS` | public config | no | CORS allowlist | `wrangler.toml [vars]` |

### Submission metadata

| Value | Class | Where used |
|---|---|---|
| RevenueCat Project ID | submission metadata | Devpost/Next Gen form — record during dashboard setup |

## D. Exact dashboard work required (human)

1. **RevenueCat** — create/reuse *PauseSignal* project; record
   **Project ID**; create 4 Test Store products; attach to existing
   entitlements `sentinel` + `family_vault`; ensure CURRENT Offering
   carries packages `sentinel_monthly`, `sentinel_annual`,
   `family_vault_monthly`, `family_vault_annual`; copy Test Store
   public SDK key. Detail: `docs/NEXT_GEN_REVENUECAT_TEST_STORE.md`.
2. **AssemblyAI** — create account, generate one API key.
3. **Groq** — create account, generate one API key.
4. **OneSignal** — create/reuse app, Android platform configured,
   copy App ID + REST API key.
5. **Cloudflare** — account with Workers access; `wrangler login`
   (browser OAuth, one-time).

## E. Deployment order

```bash
# 1. Relay token — generate ONCE, same value both sides.
#    PowerShell:
[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
#    or Git Bash / Linux / macOS:
openssl rand -base64 32

# 2. Server secrets (interactive prompts — never echoed to git):
cd server
npx wrangler secret put ASSEMBLYAI_API_KEY
npx wrangler secret put GROQ_API_KEY
npx wrangler secret put ONESIGNAL_REST_API_KEY
npx wrangler secret put RELAY_CLIENT_TOKEN   # value from step 1

# 3. Non-secret vars — edit wrangler.toml [vars]:
#    ONESIGNAL_APP_ID  = "<onesignal app id>"
#    ALLOWED_ORIGINS  = "https://nemesisdevx.github.io,http://localhost,http://127.0.0.1"

# 4. Deploy:
npx wrangler deploy        # note the workers.dev URL it prints
```

`RELAY_CLIENT_TOKEN` is **abuse resistance, not end-user auth** — a
shared secret distributed inside the app. To rotate after judging:
`wrangler secret put RELAY_CLIENT_TOKEN` with a new value, redeploy,
and stop shipping the old `VOXGUARD_RELAY_TOKEN`.

## F. App build / run order

Windows PowerShell is the primary environment:

```powershell
# 1. Session env (values never echoed by the scripts):
$env:REVENUECAT_TEST_STORE_KEY           = "test_..."
$env:VOXGUARD_RELAY_TOKEN                = "<same as RELAY_CLIENT_TOKEN>"
$env:VOXGUARD_ALERT_RELAY_URL            = "https://<worker>.workers.dev/alert"
$env:VOXGUARD_RECORDING_TRANSCRIPTION_URL= "https://<worker>.workers.dev"
$env:ASSEMBLYAI_TOKEN_BROKER_URL         = "https://<worker>.workers.dev/aai-token"
$env:VOXGUARD_SEMANTIC_PROXY_URL         = "https://<worker>.workers.dev"
$env:ONESIGNAL_APP_ID                    = "<onesignal app id>"

# 2. Sanity-check config WITHOUT printing values:
.\scripts\judge_local.ps1 doctor

# 3. Build + install:
.\scripts\judge_local.ps1 apk
#    or run attached:
.\scripts\judge_local.ps1 run -d emulator-5554

# Git Bash equivalent: ./scripts/judge_local.sh doctor|apk|run|relay
```

For local relay development instead of deployed Worker:
`./scripts/judge_local.sh relay` reads `server/.dev.vars`
(gitignored) — see `server/.env.example` for the shape.

## G. Verification criteria (live-QA pass/fail)

| Integration | Pass means | Evidence |
|---|---|---|
| RevenueCat | paywall shows **REVENUECAT TEST STORE** badge; real package prices render; test purchase completes; `CustomerInfo` grants entitlement; restore re-derives it; dashboard shows the sandbox transaction | screenshot + dashboard screenshot (not committed) |
| AssemblyAI streaming | `isTranscriptionLive` after Begin handshake; real transcript text streams; semantic engine consumes committed turns; forced failure degrades to acoustic-only with truthful label | app-state screenshot + sanitized log |
| AssemblyAI prerecorded | upload → `202 {job_id}` → poll → transcript → local semantic analysis; provider failure → graceful degradation, no raw provider error | app state |
| Groq proxy | `/semantic` returns compact signal object; app semantic risk updates; provider outage → local fallback | sanitized relay log + app state |
| OneSignal | receiver device registers `vg_` identity; sender alert → second device receives push; Safe/Still Suspicious response reaches sender | second-device observation |

## H. Failure troubleshooting matrix

| Symptom | Most likely cause | Check |
|---|---|---|
| Paywall says DEMO STORE | `REVENUECAT_TEST_STORE_KEY` not compiled into the build | rebuild with the define; debug/non-release only |
| Paywall shows "Subscriptions aren't configured" | release build with only a Test Store key — working as designed | use debug/judging build or a real platform key |
| Offering/packages empty | products not attached to entitlements, or CURRENT Offering unset / wrong package IDs | dashboard → Offering must contain the 4 exact identifiers |
| Purchase completes but nothing unlocks | entitlement ID mismatch — app reads `sentinel`/`family_vault` only | dashboard entitlement attachment; `CustomerInfo` is the only authority |
| SafeCall stays acoustic-only | broker URL missing, relay-token mismatch, provider handshake failed | `judge_local doctor`; relay 401 → token mismatch; 503 → `ASSEMBLYAI_API_KEY` missing server-side |
| Streaming reconnects die | one-time token consumed — client must re-mint per connect | confirm broker URL reachable; tokens are ≤600 s, single-use |
| Recording enhanced mode absent | `VOXGUARD_RECORDING_TRANSCRIPTION_URL` unset — by design | set the define; on-device mode stays available |
| Recording upload fails fast | >25 MB or unsupported format hint | file bounds are enforced client- and server-side |
| Semantics always local | proxy URL/token missing, or provider failed (fallback is intended) | `doctor` output; relay `/semantic` 401 → token; 503 → `GROQ_API_KEY` |
| Family Shield alert 401 | `VOXGUARD_RELAY_TOKEN` ≠ `RELAY_CLIENT_TOKEN` | regenerate pair — values must match exactly |
| Alert accepted, never received | OneSignal app ID mismatch, platform not configured, identity not registered, or `ONESIGNAL_REST_API_KEY` wrong | receiver card state; OneSignal dashboard delivery log; `docs/FAMILY_SHIELD_SMOKE_TEST.md` |
| Receiver "Push not configured" | `ONESIGNAL_APP_ID` absent from build | doctor mode shows `missing` |
| Relay CORS failure on web | origin not in `ALLOWED_ORIGINS` | add origin to `wrangler.toml [vars]`, redeploy |
| `wrangler deploy` auth error | not logged in | `npx wrangler login` (browser OAuth) |

## I. Evidence checklist (collect during live QA — do NOT commit account screenshots)

| # | Evidence | Type |
|---|---|---|
| 1 | Paywall with REVENUECAT TEST STORE badge + real prices | app screenshot |
| 2 | Completed Test Store purchase → entitlement unlocked | app state |
| 3 | RevenueCat dashboard sandbox transaction | dashboard screenshot (external) |
| 4 | Restore Purchases re-derives tier | app state |
| 5 | Live Mic session with real transcript streaming | app screenshot |
| 6 | Relay log: `token_minted` / `provider_poll_status` (sanitized) | terminal log |
| 7 | Recording → job id → transcript → local analysis | app state |
| 8 | `/semantic` proxied response reflected in risk UI | app state + log |
| 9 | Two-device Family Shield: alert out, push received, response returned | second-device observation |
| 10 | Forced provider failure → truthful degraded UI | app screenshot |

## J. Physical-device checklist (when hardware is available)

- **Install/startup:** fresh install → onboarding → language picker → optional name → permissions only on demand.
- **Live Mic:** deny → honest state; allow → real PCM flows; permanently deny → settings shortcut offered; start/stop clean; background/foreground behavior observed; no second source steals the mic mid-session.
- **SafeCall:** acoustic-only run; STT run (transcript streams); semantic updates; end call → incident persisted with SHA-256 provenance.
- **Recording:** valid file; >25 MB rejected honestly; >15 min rejected; enhanced transcription gated + works; cancellation mid-poll safe.
- **RevenueCat:** purchase; cancel; failure; restore; cold-restart persistence.
- **Family Shield:** identity registered; alert out; second-device receipt; response round trip.
- **UI:** dark + light; Arabic RTL + English + Spanish + French; large text; Reduced Motion.
- **Network:** cold start offline; drop mid-session; restore — every transition stays truthful.

## K. Submission checklist

- [ ] Public repo renders: README, screenshots, MIT `LICENSE`
- [ ] `submission/SUBMISSION_DRAFT.md` finalized with real evidence
- [ ] RevenueCat Project ID recorded
- [ ] Live-QA evidence captured (section I)
- [ ] Demo video recorded *(deferred — separate task)*
- [ ] Final `docs/RELEASE_CANDIDATE_MANIFEST.md` SHA updated post-QA

## L. Explicit stop conditions

Stop and reassess — do not improvise — if:

- any provider credential would need to be embedded in the client
- a required entitlement/package ID can't be created as specified
- the relay must change its request contract
- scoring, pricing, or protocol semantics need to change
- an irreversible external-account action appears necessary

---

*Existing detail docs: `LIVE_INTEGRATIONS_FINAL_SETUP.md` (config
contract) · `NEXT_GEN_REVENUECAT_TEST_STORE.md` (dashboard) ·
`FAMILY_SHIELD_SMOKE_TEST.md` (two-device) · `server/README.md`
(routes/auth) · `REVENUECAT_QA.md` (purchase QA).*
