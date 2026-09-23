# Live Integrations — Final Setup Contract

Everything PauseSignal needs from the outside world for the final
live-QA phase. Repository-side infrastructure is complete; this file
lists **only the values a human must supply** and where each belongs.

> **Never paste real values into this file, source, tests, or git.**
> Supply them transiently via `--dart-define` / server env vars.

## Mobile build-time (`--dart-define`)

| Variable | Secret? | OK in judging APK? | Feature | If absent |
|---|---|---|---|---|
| `REVENUECAT_TEST_STORE_KEY` | public SDK key — keep out of repo anyway | yes — **debug builds only** (the factory refuses it in release) | Paywall → RevenueCat Test Store | falls to Demo Store (debug) / Unavailable (release) |
| `REVENUECAT_ANDROID_KEY` / `REVENUECAT_IOS_KEY` | public SDK key | yes — production path | Paywall → real store | demo/unavailable backend |
| `VOXGUARD_RELAY_TOKEN` | shared relay token — abuse resistance, not a credential | yes | Relay auth for transcription, token broker, semantic proxy, Family Shield relay | relay-backed features report "not configured" |
| `VOXGUARD_ALERT_RELAY_URL` | no | yes | Family Shield outbound alerts | alerts report relay not configured |
| `VOXGUARD_RECORDING_TRANSCRIPTION_URL` | no | yes | Analyze Recording → enhanced transcription | enhanced mode hidden; on-device analysis only |
| `ASSEMBLYAI_TOKEN_BROKER_URL` | no | yes | SafeCall live transcription (brokered token mint) | streaming STT off → acoustic-only (truthful UI) |
| `VOXGUARD_SEMANTIC_PROXY_URL` | no | yes | SafeCall cloud semantic analysis | local bilingual rule engine (authoritative fallback) |
| `ONESIGNAL_APP_ID` | public app id | yes | Family Shield receiver registration | receiver setup reports unavailable |

### Development-only defines — never ship in a released build

| Variable | Purpose | Guard |
|---|---|---|
| `ASSEMBLYAI_API_KEY` | dev: mint streaming tokens client-side | dev path only; production uses the broker |
| `ASSEMBLYAI_TEMP_TOKEN` | CI/demo: pre-minted one-shot token | one session only, no reconnects |
| `GROQ_API_KEY` | dev: direct Groq calls | requires `VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC=true` **and** is documented never to ship |
| `VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC` | explicit opt-in for the dev direct path | off by default |

## Server-only (Cloudflare Worker env — `server/`)

| Variable | Secret? | Feature |
|---|---|---|
| `ASSEMBLYAI_API_KEY` | **secret** | `POST /transcription/jobs` + `GET /aai-token` |
| `GROQ_API_KEY` | **secret** | `POST /semantic` |
| `ONESIGNAL_REST_API_KEY` | **secret** | `POST /alert` |
| `ONESIGNAL_APP_ID` | no | `POST /alert` target app |
| `RELAY_CLIENT_TOKEN` | shared token | auth boundary on every route |
| `ALLOWED_ORIGINS` | no | CORS allowlist |

## Submission metadata (not a secret)

- **RevenueCat Project ID** — record during live QA for judging notes.

## Failure truth contract

Every absent value resolves to a truthful state — never a fake
success: unconfigured relay → feature hidden/locked; provider failure
→ safe consumer error; missing Test Store key in release →
unavailable backend; malformed provider output → local fallback.
