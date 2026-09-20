<div align="center">

# 🛡️ VoxGuard

### AI Voice Scam Interceptor & Real-Time Voice Defense System

**Real-time multi-signal defense against audio deepfakes, voice impersonation, and coercion scams.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-10B981.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-27%2F27%20Passing-10B981)](https://github.com/NemesisDevX/voxguard/actions)
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

VoxGuard's answer is **multi-signal threat fusion**: the acoustic fingerprint of the voice *and* the semantic fingerprint of the conversation are scored simultaneously and fused into a composite risk verdict in real time. A synthetic voice with a clean script is flagged. A real voice running a coercion script is flagged. Only a call that is clean on **both** axes stays green.

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        VoxGuard Pipeline                         │
│                                                                  │
│  Incoming Audio ─────┐                    ┌─── Live Transcript    │
│                     ▼                    ▼                       │
│           ┌──────────────────┐  ┌──────────────────────┐        │
│           │ ENGINE A         │  │ ENGINE B             │        │
│           │ Acoustic         │  │ Semantic Threat      │        │
│           │ Forensics        │  │ Engine               │        │
│           │                  │  │                      │        │
│           │ • Spectral Flux  │  │ • Groq Llama-3 API   │        │
│           │ • Spectral       │  │ • Deterministic EN+AR│        │
│           │   Rolloff (HF    │  │   fallback rules     │        │
│           │   cutoff)        │  │ • Urgency / FinDemand│        │
│           │ • Zero-Crossing  │  │ • Secrecy / Isolation│        │
│           │   Rate           │  │ • Impersonation      │        │
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
│        │ Threat HUD   │  │ Forensic Incident│                   │
│        │ (live meters │  │ Report persisted │                   │
│        │  + banner)   │  │ (SHA-256, telemetry, transcript)     │
│        └──────────────┘  └────────┬─────────┘                   │
│                                   ▼                              │
│                        ┌────────────────────┐                   │
│                        │ OneSignal Family   │                   │
│                        │ Shield Broadcast   │                   │
│                        │ (emergency push    │                   │
│                        │  to relatives)     │                   │
│                        └────────────────────┘                   │
│                                                                  │
│  RevenueCat Subscription Engine ── entitlements gate premium     │
│  tiers (Sentinel Shield / Family Vault) across all platforms.    │
└──────────────────────────────────────────────────────────────────┘
```

### Engine A — Acoustic Forensics

Real DSP on every incoming audio chunk (not heuristics-over-random):

- **Spectral Flux** — iterative radix-2 FFT measures frame-to-frame spectral change. Synthesized voices are spectrally *static*.
- **Spectral Rolloff** — the frequency containing 85% of spectral energy. TTS/vocoder output shows an abnormally hard high-frequency cutoff.
- **Zero-Crossing Rate** — tonal synthesis produces unnaturally flat ZCR profiles vs. human speech.

### Engine B — Semantic Threat Engine

- **Primary**: Groq API (`llama-3.3-70b-versatile`, JSON-mode) for contextual conversation analysis.
- **Fallback**: a deterministic bilingual rule engine — English + Egyptian-Arabic lexicons for urgency (`بسرعة`, `دلوقتي`), financial demands (`حول`, `جنيه`, `محفظة`, `انستاباي`), secrecy/isolation (`متقولش لحد`, `بيني وبينك`), and impersonation claims (`أنا أخوك`). Zero network dependency.

### Threat Fusion Matrix

`Composite = Semantic × 0.65 + Acoustic × 0.35` — semantic evidence weighs more (a real voice running a scam script is still a scam). When **all three** semantic vectors exceed 0.75 — the classic coordinated-scam signature — a **+15% amplification** kicks in. Bands: **Safe <0.40 · Suspicious <0.75 · High Risk ≥0.75**.

---

## Three Core Operational Modes

| Mode | What it does |
|------|-------------|
| **SafeCall** | In-app protected call channel. Streams audio through both engines live — waveform, 4-signal threat radar, composite banner, and a scripted demo attack for judges. |
| **Live Shield** | Ambient microphone monitor for speakerphone and surrounding conversations. |
| **Analyze Recording** | Upload call audio or voice notes for deep post-hoc forensic auditing. |

Every high-risk interception auto-persists a **Forensic Incident Report**: ID, timestamps, audio integrity hash, per-engine telemetry, phrase-highlighted transcript, and recommended actions — viewable in the Incidents tab.

---

## Monetization Architecture *(HAMM Award)*

| | **Quick Check** (Free) | **Sentinel Shield** | **Family Vault** |
|---|---|---|---|
| Price | $0 | $9.99/mo · $79.99/yr | $19.99/mo · $149.99/yr |
| Call analyses | 5 / month | **Unlimited** | Unlimited |
| SafeCall + Live Shield | Standard | ✅ Full | ✅ Full |
| Dual-engine fusion | — | ✅ | ✅ |
| Protected devices | 1 | 1 | **Up to 5** |
| Family Shield broadcast | — | — | ✅ OneSignal alerts |
| Shared threat log | — | — | ✅ |

Built on `purchases_flutter` (RevenueCat) behind a decoupled `IPurchaseService` interface:

- **`RevenueCatPurchaseService`** — production path on Android/iOS/macOS, keyed via `--dart-define=REVENUECAT_ANDROID_KEY=...`
- **`MockSandboxPurchaseService`** — full lifecycle simulation (checkout, entitlements, restore) on Web/Desktop and keyless debug sessions
- **Conditional-import factory** — `purchases_flutter` is *never compiled* into web builds; every platform gets a working paywall

High-conversion paywall: billing-cycle pill toggle (SAVE 35%), tier cards with a MOST POPULAR highlight, 7-day free trial banner, and post-interception upsells triggered at the exact moment a threat is witnessed.

---

## OneSignal Family Shield *(OneSignal Award)*

Privacy-by-design emergency broadcasting. When a call ends at high risk:

```
High-Risk Intercept
      │
      ▼
Forensic Incident persisted locally
      │
      ▼
POST api.onesignal.com/notifications
  ├── include_aliases.external_id → family members only
  ├── title: "🚨 VoxGuard Family Shield Alert"
  ├── body:  "Potential scam call intercepted on Abdo's device.
  │           Verify directly before sending funds."
  └── data:  { incident_id, risk_level }
```

No raw audio, no transcript, no PII leaves the device — only an incident reference and risk band. Runs as a **pure-Dart REST client** (identical on Android/iOS/Web) with automatic **simulated-broadcast fallback** when `ONESIGNAL_APP_ID`/`ONESIGNAL_API_KEY` aren't configured.

---

## Quickstart

### Live Demo

**[https://nemesisdevx.github.io/voxguard/](https://nemesisdevx.github.io/voxguard/)** — the full app runs in your browser (sandbox purchase + simulated alert modes engage automatically).

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
  --dart-define=GROQ_API_KEY=gsk_... \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_... \
  --dart-define=ONESIGNAL_APP_ID=... \
  --dart-define=ONESIGNAL_API_KEY=...
```

| `--dart-define` | Service | Without it |
|---|---|---|
| `GROQ_API_KEY` | Llama-3 semantic analysis | deterministic bilingual rule engine |
| `REVENUECAT_ANDROID_KEY` / `REVENUECAT_IOS_KEY` | real store checkout | sandbox purchase lifecycle |
| `ONESIGNAL_APP_ID` / `ONESIGNAL_API_KEY` | live push broadcast | simulated broadcast |

**Demo path**: Home → *Start SafeCall* → tap **Simulate Scam** (FAB) → watch the radar escalate 0% → ~100% → end the call → incident auto-logged → Family Shield upsell → Incidents tab → full forensic report.

### Testing & CI

```bash
flutter analyze   # 0 issues
flutter test      # 27/27 passing
flutter build web --release --base-href /voxguard/
flutter build apk --debug
```

Every push to `main` runs the full pipeline — analyze → test → web + APK builds → auto-deploy to GitHub Pages → APK artifact upload (see `.github/workflows/ci.yml`).

---

## Tech Stack

- **Flutter 3.41 / Dart 3.11** — Material 3 dark design system (deep zinc `#0B0D13`, emerald/amber/crimson semantics)
- **flutter_bloc** — `SafeCallBloc` (streaming threat telemetry), `PaywallBloc` (checkout lifecycle)
- **purchases_flutter** — RevenueCat subscriptions + cross-platform sandbox
- **http** — Groq chat completions + OneSignal REST broadcast
- **equatable** — immutable domain models

## Forensic Disclaimer

> VoxGuard telemetry — including acoustic metrics, semantic scores, and composite risk assessments — is **AI-generated forensic telemetry**. It is an assistive signal for user protection, **not a legal or judicial determination**. Always verify suspicious requests through an independent, trusted channel.

---

<div align="center">
Built for the RevenueCat Shipaton · MIT License
</div>
