<div align="center">

# PauseSignal

### Hear the signal. Pause. Verify.

AI Voice Scam Defense & Real-Time Threat Telemetry

**Real-time multi-signal defense against audio deepfakes, voice impersonation, and coercion scams.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-10B981.svg)](LICENSE)
[![CI](https://github.com/NemesisDevX/voxguard/actions/workflows/ci.yml/badge.svg)](https://github.com/NemesisDevX/voxguard/actions/workflows/ci.yml)
[![CI/CD](https://img.shields.io/github/actions/workflow/status/NemesisDevX/voxguard/ci.yml?branch=main&label=CI%2FCD)](https://github.com/NemesisDevX/voxguard/actions)
[![Platforms](https://img.shields.io/badge/Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-1E2333)](https://github.com/NemesisDevX/voxguard)

**[▶ Live Demo — nemesisdevx.github.io/voxguard](https://nemesisdevx.github.io/voxguard/)**

</div>

---

## The Problem

A parent answers a call. The voice on the other end is *their son* — panicking, begging for an emergency money transfer. It's a deepfake. By the time anyone realizes, the money is gone.

Voice-cloning scams now cost consumers billions annually. And yet, nearly every defense on the market makes the same fatal assumption: **that a single model can catch every scam.**

## Why Single-Model Detectors Fail

A pure deepfake detector can be beaten with a clean recording of a real voice. A pure text classifier can be beaten by a scammer who simply changes the script. **Any single signal is a single point of failure.**

PauseSignal's answer is **multi-signal threat fusion**: acoustic anomaly indicators of the voice *and* the semantic fingerprint of the conversation are scored simultaneously and fused into a composite **Threat Score (0–100)** in real time. Acoustic anomaly indicators can contribute to the Threat Score even when semantic scam indicators are absent — and vice versa. Only a call that is clean on **both** axes stays green.

> PauseSignal is an assistive consumer safety tool — a risk *score*, not a probability, and not a validated forensic verdict. The acoustic engine is a **heuristic prototype**, not a scientifically validated deepfake classifier.

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       PauseSignal Pipeline                         │
│                                                                  │
│  Audio Sources        │                    ┌─── Live Transcript    │
│  • Live Mic PCM       ├──► AssemblyAI ─────┤   (streaming, when    │
│  • Demo PCM (labelled)│    streaming STT   │    STT configured)   │
│                     ▼                    ▼                       │
│           ┌──────────────────┐  ┌──────────────────────┐        │
│           │ ENGINE A         │  │ ENGINE B             │        │
│           │ Acoustic         │  │ Semantic Threat      │        │
│           │ Forensics        │  │ Engine               │        │
│           │                  │  │                      │        │
│           │ • Spectral Flux  │  │ • Deterministic EN+AR│        │
│           │ • Spectral       │  │   rule engine        │        │
│           │   Rolloff (HF    │  │   (production path,  │        │
│           │   cutoff)        │  │   on-device)         │        │
│           │ • Zero-Crossing  │  │ • Urgency / FinDemand│        │
│           │   Rate           │  │ • Secrecy / Isolation│        │
│           │                  │  │ • Impersonation      │        │
│           │                  │  │                      │        │
│           │                  │  │ (Groq = dev-only     │        │
│           │                  │  │  experiment, gated)  │        │
│           └────────┬─────────┘  └──────────┬───────────┘        │
│                  │ syntheticScore    combinedScore              │
│                  ▼                    ▼                          │
│           ┌─────────────────────────────────┐                    │
│           │    THREAT FUSION MATRIX         │                    │
│           │                                 │                    │
│           │  Composite = Sem×0.65 + Ac×0.35 │                    │
│           │  +15% amplification when        │                    │
│           │  urgency+financial+secrecy      │                    │
│           │  all > 0.75                     │                    │
│           │                                 │                    │
│           │  Safe <0.40 | Suspicious <0.75  │                    │
│           │  High Risk ≥0.75                │                    │
│           └────────┬───────────────┬────────┘                    │
│                  ▼               ▼                               │
│        ┌──────────────┐  ┌──────────────────┐                   │
│        │ Signal Lens  │  │ Incident Report  │                   │
│        │ HUD (two     │  │ persisted        │                   │
│        │  signals →   │  │ (fingerprint,    │                   │
│        │              │  │  telemetry,      │                   │
│        │              │  │  transcript)     │                   │
│        └──────────────┘  └────────┬─────────┘                   │
│                                   ▼                              │
│                        ┌────────────────────┐                   │
│                        │ Family Shield      │                   │
│                        │ alert → server     │                   │
│                        │ relay → OneSignal  │                   │
│                        │ (demo mode without │                   │
│                        │  relay endpoint)   │                   │
│                        └────────────────────┘                   │
│                                                                  │
│  RevenueCat Subscription Engine ── entitlements gate premium     │
│  tiers (Sentinel Shield / Family Vault) — real store on          │
│  Android/iOS; labelled Demo Store on Web/Desktop.                │
└──────────────────────────────────────────────────────────────────┘
```

### Audio Sources — same pipeline, honest provenance

Every session picks one source behind `IAudioStreamSource`; downstream analysis is identical either way:

- **Live Mic** — real microphone capture (`record` package, mono 16 kHz PCM16), permission requested only when the user starts a session. PCM feeds the acoustic engine, the session SHA-256 digest, and — when configured — streaming STT.
- **Demo Attack** — `DemoAudioSource` generates deterministic PCM and a scripted Egyptian-Arabic scam dialogue for judging. Always labelled `DEMO MODE` / `DEMO AUDIO`; never presented as captured audio.

**Streaming transcription** uses AssemblyAI's `universal-3-5-pro` streaming model, explicitly configured in `AssemblyAiStreamingConfig` — Arabic + English streaming transcription with native code-switching, biased via the documented `language_codes=["en","ar"]` parameter. Auth is always a short-lived token on the socket URL: production obtains it from `ASSEMBLYAI_TOKEN_BROKER_URL`; `ASSEMBLYAI_API_KEY` is a development-only fallback that mints tokens client-side and must never ship in a release. If the token mint or socket handshake fails, the session continues acoustically and the UI marks transcription unavailable — `isTranscriptionLive` only reports true after the provider's `Begin` handshake, and a mid-session drop triggers exactly one bounded reconnect before degrading.

### Engine A — Acoustic Forensics

Real DSP on every incoming audio chunk (heuristic prototype — not a validated classifier):

- **Spectral Flux** — iterative radix-2 FFT measures frame-to-frame spectral change. Synthesized voices are spectrally *static*.
- **Spectral Rolloff** — the frequency containing 85% of spectral energy. TTS/vocoder output shows an abnormally hard high-frequency cutoff.
- **Zero-Crossing Rate** — tonal synthesis produces unnaturally flat ZCR profiles vs. human speech.

### Engine B — Semantic Threat Engine

- **Production**: a deterministic bilingual rule engine — English + Egyptian-Arabic lexicons for urgency (`بسرعة`, `دلوقتي`), financial demands (`حول`, `جنيه`, `محفظة`, `انستاباي`), secrecy/isolation (`متقولش لحد`, `بيني وبينك`), and impersonation claims (`أنا أخوك`). Zero network dependency.
- **Production cloud path**: `VOXGUARD_SEMANTIC_PROXY_URL` points SafeCall at the relay's `POST /semantic` route — transcript text (bounded) is the only payload, the `GROQ_API_KEY` stays server-side, the response is a strictly-validated compact signal object, and any provider failure falls back to the local engine. Recording analysis never uses it.
- **Developer experimentation only**: direct Groq API calls (`llama-3.3-70b-versatile`, JSON-mode) are gated behind BOTH `GROQ_API_KEY` and the explicit opt-in flag `VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC=true` — and are **code-disabled in release builds** regardless of the flags. A permanent Groq key must never ship in a released build.
- **Analyze Recording never calls Groq**: user-provided and provider-produced recording transcripts are analyzed by the local engine only.

### Threat Fusion Matrix

`Composite = Semantic × 0.65 + Acoustic × 0.35` — semantic evidence weighs more (a real voice running a scam script is still a scam). When **all three** semantic vectors exceed 0.75 — the classic coordinated-scam signature — a **+15% amplification** kicks in. Bands: **Safe <0.40 · Suspicious <0.75 · High Risk ≥0.75**.

---

## Three Core Operational Modes

| Mode | What it does |
|------|-------------|
| **SafeCall — Live Mic** | Microphone protection session (`LIVE MIC` badge): real PCM → acoustic forensics → AssemblyAI streaming STT when configured → semantic analysis → fused Threat Score. Acoustic analysis keeps working even without STT credentials. |
| **SafeCall — Demo Attack** | Deterministic judging scenario (`DEMO MODE`): generated PCM + scripted Egyptian-Arabic scam dialogue → same pipeline → evidence chips, highlighted phrases, HIGH RISK escalation, verification flow. |
| **Live Shield** *(planned)* | Ambient microphone monitor for speakerphone and surrounding conversations — not yet implemented. |
| **Analyze Recording** | Upload a call recording or voice note (common supported formats include WAV/MP3/M4A/AAC/OGG/OPUS/FLAC — codec availability may vary by platform/browser; ≤25 MB / ≤15 min) → normalized to the same 16 kHz mono PCM16 the live pipeline uses → chunked acoustic forensics → optional relay-based transcription + local semantic analysis → fused verdict, or an honest **Partial Analysis** when conversation signals weren't analyzed. |

Every high-risk session auto-persists an **Incident Report**: ID, timestamp, genuine **SHA-256 digest** of the analyzed PCM, audio/transcription source labels (*Live Microphone* / *Generated Demo Audio* / *Uploaded Recording*), consumer-first "Why PauseSignal Flagged This Call" evidence, phrase-highlighted transcript, and recommended verification steps — viewable in the Incidents tab, with raw telemetry under a collapsible *Technical Evidence* section.

### Analyze Recording — privacy modes

After picking a file, the user makes an explicit choice — nothing is uploaded on selection alone:

- **Keep audio on this device** — local decode + acoustic analysis only; zero network calls. An optional *user-provided transcript* field lets a privacy-conscious user paste text they already have for semantic analysis (clearly labelled `User-provided transcript`).
- **Include conversation analysis** — the recording is sent through the PauseSignal transcription relay (`VOXGUARD_RECORDING_TRANSCRIPTION_URL`) to the configured speech-to-text provider; PauseSignal does not permanently store it. Requires an explicit tap and shows the upload stage only in this mode. If the relay isn't configured, the option is disabled with an explanation and acoustic analysis remains available.

**Partial results are never a "safe" verdict.** Conversation-risk signals carry 65% of the fused score, so an acoustic-only run renders *Partial Analysis* + the acoustic anomaly score — no composite Threat Score, no green SAFE badge. Flagged results persist as real local incidents (`PersistedIncidentRepository`, SharedPreferences JSON, capped at 50); the original audio file itself is never copied into PauseSignal storage — only the report and the PCM SHA-256 survive.

> **Privacy boundary:** raw microphone audio is processed in memory and never stored by PauseSignal. When live transcription is configured, PCM is streamed to the transcription provider for the duration of the session only. No audio or transcripts are sent to Family Shield — alert payloads carry an incident reference and risk band only.

---

## Personalization & Localization

- **Welcome Setup** (first run, before safety onboarding): interface language picker — English / العربية / Español / Français, no flags, applies instantly — plus an *optional* local-only display name (≤32 chars, trimmed, skippable, never synced, never in Family Shield payloads).
- **Full localization** via `flutter_localizations` + `gen_l10n`: 581 message keys with enforced parity across all four ARB locales (en/ar/es/fr); Arabic renders true RTL. Interface language is independent of analysis coverage — **conversation-risk analysis supports English and Egyptian Arabic**; the app says so in Settings → About.
- **Themes**: System / Light / Dark with a real token layer (`AppPalette` ThemeExtension) — deep ink dark, warm off-white light.
- **Accents**: Periwinkle / Soft Blue / Soft Violet — tint interactive surfaces only; safety colors (safe/warning/danger) are provably accent-proof.
- **Text size**: System / Large / Extra Large as a floor — never smaller than the OS accessibility scale.
- **Guided Mode**: larger actions, clearer guidance, de-emphasized technical detail — same risk behavior, no parallel screens.
- **Motion**: Follow system / Reduced — either OS or app preference stops ambient animation (Signal Lens breathing, launch converge, theme transitions).
- **Haptics**: On / Off — every haptic routes through the preference-aware `AppHaptics` wrapper.
- **Settings Control Center**: Profile, Appearance, Safety & Family, Notifications (real push-permission state + device settings shortcut), Subscription, About & Privacy.

Details: `docs/PERSONALIZATION_AND_LOCALIZATION.md` · `docs/DESIGN_SYSTEM.md`

---

## Monetization Architecture

The enforced product model — the same matrix `ProductAccess` and the paywall apply in code:

**Quick Check — Free**
- Live Mic acoustic anomaly monitoring
- On-device recording analysis
- Manual transcript check — analyzed locally
- Local incident history
- Receive & respond to Family Shield alerts

**Sentinel Shield** — everything above plus:
- Automatic Live Mic transcription when infrastructure is configured
- Transcript-backed conversation-risk analysis
- Enhanced recording transcription
- Fused multi-signal Threat Score

**Family Vault** — everything above plus:
- Real outbound Family Shield alerts (explicitly user-triggered)
- Up to 5 locally-saved Trusted Circle contacts
- Human safety-resolution loop (private Safe / Still Suspicious responses)

Real prices come from the store's **current RevenueCat Offering** — the paywall renders each package's localized `priceString`; no production price is hard-coded anywhere. The Demo Store's simulated prices are always labelled as simulation in-app, and real-store purchasing for this release is scoped to **Android and iOS** — Web/Desktop builds run the explicitly-labelled Demo Store.

Built on `purchases_flutter` (RevenueCat) behind a decoupled `IPurchaseService` interface — four backends, picked by `PurchaseServiceFactory` at first use:

- **`RevenueCatPurchaseService` (real store)** — production checkout on Android/iOS, keyed via `--dart-define=REVENUECAT_ANDROID_KEY=...` / `REVENUECAT_IOS_KEY=...`
- **`RevenueCatPurchaseService` (Test Store)** — the genuine RevenueCat-hosted Test Store through the real SDK, for Shipaton judging/development builds on Android/iOS, keyed via `--dart-define=REVENUECAT_TEST_STORE_KEY=...`; labelled **REVENUECAT TEST STORE** in-app, verified by RevenueCat, never a real-money charge, never selectable in a release build
- **`MockSandboxPurchaseService`** — full lifecycle simulation on Web/Desktop and keyless *debug* sessions; the paywall labels itself **DEMO STORE** with "no real charge" copy
- **`UnavailablePurchaseService`** — keyless *release* builds lock the paywall truthfully ("Subscriptions aren't configured in this build") rather than faking purchases — a Test Store key alone never rescues a release build
- **Conditional-import factory** — `purchases_flutter` is *never compiled* into web builds; every platform gets a working paywall

**Truthful paywall:** the paywall renders only packages the current Offering returns — localized `priceString`, billing-cycle toggle only when both cycles exist, trial copy only when the store package actually provides one. Entitlement changes propagate live via `EntitlementState`/`ProductAccess` and gate real behavior: Free gets on-device analysis + Family Shield receive/respond, Sentinel unlocks cloud transcription, Family Vault unlocks outbound Family Shield dispatch. Full configuration reference: `docs/REVENUECAT_SETUP.md`.

---

## OneSignal Family Shield

Privacy-by-design emergency alerting. When a call ends at high risk, the post-call verification flow offers an optional family broadcast:

```
High-Risk Session Ends
      │
      ▼
Incident Report persisted locally
      │
      ▼
POST → minimal server-side relay (VOXGUARD_ALERT_RELAY_URL)
  ├── family_external_ids → configured contacts only
  ├── title: "🚨 PauseSignal Family Shield Alert"
  ├── body:  "A high-risk call was flagged on a protected
  │           device. Verify directly before funds move."
  └── incident_id + risk_level reference
      │
      ▼
Relay holds OneSignal credentials → fans out via
include_aliases.external_id push to relatives
```

**Receiving device:** any PauseSignal install can become a real Family Shield receiver — *Settings → Family Shield Receiver → Enable Family Alerts* requests notification permission (only ever from that button, never at launch), generates an opaque `vg_…` identity persisted locally, and links it via `OneSignal.login(externalId)` so the relay's `include_aliases.external_id` reaches the device. The `onesignal_flutter` 5.x SDK is isolated behind `IPushIdentityService`; a live `FamilyPushRegistration` state tracks permission → registered transitions via the push-subscription observer (no polling). Two-device test procedure: `docs/FAMILY_SHIELD_SMOKE_TEST.md`.

**Security boundary:** the OneSignal REST API key lives on the relay — never inside the Flutter client (the SDK only needs the App ID, which is not a secret). The client payload carries no raw audio, no transcript, no PII — just an incident reference and risk band. Without a relay URL the app runs an explicitly-labelled **Demo Mode** broadcast (`IFamilyContactRepository` → `DemoFamilyContactRepository`), keeping the full journey demoable without shipping secrets. "Alert accepted" means the relay + OneSignal API accepted the notification — confirmed device receipt is only observable on the receiving device.

---

## Quickstart

### Live Demo

**[https://nemesisdevx.github.io/voxguard/](https://nemesisdevx.github.io/voxguard/)** — a **browser demo experience** of the app. Intentionally unavailable on web: the raw Live Mic PCM capture pipeline, OneSignal mobile push, and native real-store purchasing — Demo Attack, Demo Store checkout, and simulated Family Shield alerts engage automatically so every flow is explorable.

### Local Run

```bash
git clone https://github.com/NemesisDevX/voxguard.git
cd voxguard
flutter pub get

# Any platform — sandbox services engage without keys:
flutter run -d chrome        # web
flutter run                  # attached device

# Full integrations via --dart-define:
flutter run \
  --dart-define=ASSEMBLYAI_TOKEN_BROKER_URL=https://your-relay.example.com/aai-token \
  --dart-define=VOXGUARD_SEMANTIC_PROXY_URL=https://your-relay.example.com \
  --dart-define=VOXGUARD_RELAY_TOKEN=<shared-relay-token> \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_... \
  --dart-define=VOXGUARD_ALERT_RELAY_URL=https://your-relay.example.com/alert
```

| `--dart-define` | Service | Without it |
|---|---|---|
| `VOXGUARD_SEMANTIC_PROXY_URL` | **Production cloud-semantic path** — SafeCall posts bounded transcript text to the relay's `/semantic` route; provider key stays server-side; failure falls back locally | deterministic bilingual rule engine |
| `GROQ_API_KEY` + `VOXGUARD_ENABLE_DEV_REMOTE_SEMANTIC=true` | **Developer experimentation only** — direct Llama-3 semantic calls require BOTH the key and the opt-in flag, and are code-disabled in release builds | deterministic bilingual rule engine (the production fallback) |
| `ASSEMBLYAI_TOKEN_BROKER_URL` | **Production transcription path** — the client GETs a short-lived streaming token (≤600 s, one-time use) from a trusted broker that holds the provider secret server-side | falls through to the next option |
| `ASSEMBLYAI_API_KEY` | **Development only** — the client mints its own short-lived token via `GET /v3/token`. Never ship a permanent provider key in a released build | Live Mic runs acoustic-only; UI shows "Live transcription unavailable" |
| `ASSEMBLYAI_TEMP_TOKEN` | Pre-minted short-lived token (CI/demo convenience) | — |
| `REVENUECAT_ANDROID_KEY` / `REVENUECAT_IOS_KEY` | real store checkout + entitlement gating | debug → Demo Store (or Test Store if its key is set); release → truthfully locked paywall |
| `REVENUECAT_TEST_STORE_KEY` | **Shipaton judging path** — RevenueCat Test Store via the real SDK on Android/iOS non-release builds; labelled REVENUECAT TEST STORE | debug → Demo Store; never selected in release |
| `VOXGUARD_TERMS_URL` / `VOXGUARD_PRIVACY_POLICY_URL` | renders the legal-link buttons on the paywall | buttons never render — dead links are impossible |
| `VOXGUARD_ALERT_RELAY_URL` | live Family Shield push via the `server/` edge relay (Cloudflare Worker) | explicit Demo Mode broadcast |
| `VOXGUARD_RELAY_TOKEN` | shared relay client token (`Bearer` auth). **Required when the deployed relay enforces it** — the relay rejects unauthenticated requests with 401. Demo-grade abuse resistance, not a truly private mobile secret | relay returns 401 (alert not sent) |
| `ONESIGNAL_APP_ID` | enables Family Shield push registration via the OneSignal Flutter SDK — an App ID is a client-safe identifier, not the REST secret | receiver card shows "Push not configured"; app runs normally |
| `VOXGUARD_TEST_FAMILY_EXTERNAL_ID` | dev-only recipient override — a real `vg_…` id from a second device for the two-device push smoke test | persisted Trusted Circle used |
| `VOXGUARD_RECORDING_TRANSCRIPTION_URL` | prerecorded transcription relay base URL (`POST/GET /transcription/jobs` on the same Worker) — provider key stays server-side | enhanced transcription mode disabled; acoustic-only analysis remains |

**Demo path**: Home → *Start SafeCall* → *Demo Attack* → tap **Simulate Scam** (FAB) → Arabic demo dialogue streams in with phrase highlights + evidence chips → the Signal Lens diverges SAFE → CAUTION → HIGH RISK → end the call → post-call sheet walks *why flagged → verify identity → demo family alert → incident report*.

**Live Mic path**: *Start SafeCall* → *Live Mic* → grant microphone permission → speak (or play suspicious audio on speakerphone) near the device → amplitude reacts, acoustic metrics update, transcript streams in when a transcription credential (`ASSEMBLYAI_TOKEN_BROKER_URL` or the dev-only `ASSEMBLYAI_API_KEY`) is set → semantic signals escalate the Threat Score.

### Testing & CI

```bash
flutter analyze
flutter test            # Flutter suite
cd server && npm test   # relay suite (node:test, offline)
flutter build web --release --base-href /voxguard/
flutter build apk --debug
```

Every push to `main` runs the full pipeline — analyze → Flutter tests → relay tests → web + APK builds → auto-deploy to GitHub Pages → APK artifact upload (see `.github/workflows/ci.yml`). The CI badge above reflects the live result.

Release signing reads `android/key.properties` (gitignored) first, then falls back to `VOXGUARD_KEYSTORE_FILE`, `VOXGUARD_KEYSTORE_PASSWORD`, `VOXGUARD_KEY_ALIAS`, `VOXGUARD_KEY_PASSWORD` environment variables. A release build without either fails loudly — debug keys are never substituted.

### Release & submission docs

| Doc | Contents |
|-----|----------|
| `docs/SHIPATON_SUBMISSION.md` | Shipaton 2026 **Next Gen** submission requirements + checklist |
| `docs/NEXT_GEN_REVENUECAT_TEST_STORE.md` | RevenueCat Test Store judging setup — dashboard + dart-define |
| `docs/STORE_METADATA.md` | Store listing copy, subscription descriptions, reviewer notes (future commercial release) |
| `docs/DEMO_SCRIPT.md` | <2 min timestamped demo video script |
| `docs/ONESIGNAL_CAMPAIGN.md` | OneSignal integration spec + deploy checklist (technical reference) |
| `docs/REVENUECAT_SETUP.md` / `docs/REVENUECAT_QA.md` | Store configuration + real-device purchase QA |
| `docs/FINAL_QA.md` / `docs/FINAL_RELEASE_STATUS.md` | Hardware QA matrix + external blocker report |
| `docs/BRAND_RELEASE_DECISION.md` | Public brand resolved: **PauseSignal** — technical identifiers unchanged |
| `submission/` | 1024×1024 icon + 1179×2556 screenshots |

---

## Tech Stack

- **Flutter 3.41 / Dart 3.11** — Material 3 token-based design system, light + dark (`AppPalette` ThemeExtension; Periwinkle/Soft Blue/Soft Violet accents, accent-proof safety colors)
- **flutter_bloc** — `SafeCallBloc` (streaming threat telemetry), `PaywallBloc` (checkout lifecycle)
- **purchases_flutter** — RevenueCat subscriptions + cross-platform sandbox
- **http** — Groq chat completions + Family Shield relay broadcast
- **equatable** — immutable domain models

## Forensic Disclaimer

> PauseSignal telemetry — including acoustic metrics, semantic scores, and composite risk assessments — is **AI-generated forensic telemetry**. It is an assistive signal for user protection, **not a legal or judicial determination**. Always verify suspicious requests through an independent, trusted channel.

---

<div align="center">

Built for the **RevenueCat Shipaton 2026 — Next Gen Award** · MIT License

Judging path: working Android app + public repo + <2 min demo video +
RevenueCat Test Store purchase flow — no store listing required.

</div>
