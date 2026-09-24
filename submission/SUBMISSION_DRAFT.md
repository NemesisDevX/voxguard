# Submission Draft — PauseSignal

*Shipaton 2026 — Next Gen. Draft text only; placeholders marked
`TODO(live-QA)` are filled after the credentials + live-verification
phase. Nothing below claims an external service is live.*

---

**Project name:** PauseSignal
**Tagline:** *Hear the signal. Pause. Verify.*
**Public repository:** https://github.com/NemesisDevX/voxguard
**License:** MIT
**RevenueCat Project ID:** `TODO(live-QA)`
**Demo video:** `TODO(deferred)`
**Live-integration evidence:** `TODO(live-QA)`

## Problem

Voice-cloning and impersonation scams exploit the few seconds when
panic overrides judgment: a parent hears "their child" begging for an
emergency transfer and acts before thinking. Single-model detectors
fail — a clean recording beats a deepfake classifier, and a reworded
script beats a text filter.

## Solution

PauseSignal creates a **pause before action**. It monitors call audio
and scores two independent evidence axes simultaneously — acoustic
anomaly indicators and the semantic fingerprint of the conversation —
then fuses them into one understandable Threat Score (0–100) with
plain-language reasons, verification steps, and an optional family
alert loop. It never declares a caller safe; it helps the user verify.

## How it works

- **Engine A — Acoustic forensics:** spectral flux, spectral rolloff,
  and zero-crossing-rate heuristics over real microphone PCM (16 kHz
  mono). A heuristic prototype — honestly labelled, not a validated
  deepfake classifier.
- **Engine B — Semantic threat engine:** a deterministic bilingual
  rule engine (English + Egyptian Arabic) covering urgency, financial
  demand, secrecy/isolation, and impersonation claims — fully
  on-device. An optional server-side Groq proxy exists for richer
  analysis; transcript text is the only thing that leaves, and the
  local engine remains the authoritative fallback.
- **Threat fusion:** `Composite = Semantic×0.65 + Acoustic×0.35`, with
  +15% amplification when urgency, financial demand, and secrecy all
  spike together — the coordinated-scam signature. Bands: Safe
  <0.40 · Suspicious <0.75 · High Risk ≥0.75.
- **Incidents:** high-risk sessions persist a forensic report —
  SHA-256 audio provenance, evidence chips, flagged phrases, and
  recommended verification steps.

## Core experience

- **SafeCall Live Mic** — real microphone session, `LIVE` badging,
  truthful acoustic-only operation when transcription isn't
  configured.
- **SafeCall Demo Attack** — deterministic generated-audio scenario
  (scripted Egyptian-Arabic scam dialogue), always labelled
  `DEMO MODE`, exercising the identical pipeline.
- **Analyze Recording** — upload a call recording; on-device acoustic
  analysis by default, with an explicit opt-in relay transcription
  path and honest *Partial Analysis* when conversation signals are
  absent.
- **Family Shield** — privacy-minimal alerts to a trusted circle via
  a server-side OneSignal relay; receivers can respond
  Safe / Still Suspicious. No audio, transcripts, or phone numbers
  ever leave the device through this channel.

## RevenueCat integration

- `purchases_flutter` behind a decoupled `IPurchaseService`
  interface; `CustomerInfo` is the sole entitlement authority.
- Entitlements: `sentinel` (Sentinel Shield) and `family_vault`
  (Family Vault) — Family Vault includes everything Sentinel does.
- Packages: `sentinel_monthly`, `sentinel_annual`,
  `family_vault_monthly`, `family_vault_annual` — real prices render
  from the current Offering's `priceString`; nothing is hard-coded.
- **Backends chosen truthfully:** production store (platform keys),
  **RevenueCat Test Store** (judging path, labelled in-app), labelled
  local **Demo Store** for keyless/web sessions, and a locked
  *unavailable* state for misconfigured release builds — a Test Store
  key alone can never arm a release build.

*Repository-side integration implemented; final live provider
verification pending credentials.*

## Next Gen implementation

Judging path: Android debug/judging APK + `REVENUECAT_TEST_STORE_KEY`
dart-define → real `purchases_flutter` SDK against RevenueCat's
hosted Test Store → real `CustomerInfo`, sandbox transactions visible
in the RevenueCat dashboard, no real money. Setup detail:
`docs/NEXT_GEN_REVENUECAT_TEST_STORE.md`.

## Technical architecture

Flutter 3.41 / Dart 3.11 · flutter_bloc state management · modular
feature/domain/data layering · `IAudioStreamSource` abstraction
(same pipeline for live PCM and demo PCM) · conditional imports keep
`purchases_flutter` out of web builds · Cloudflare Worker relay
(`server/`, zero runtime deps) holds all provider secrets:
`POST /alert`, `GET|POST /aai-token`, `POST /transcription/jobs`,
`GET /transcription/jobs/{id}`, `POST /semantic` — shared-token auth,
rate limits, bounded timeouts, sanitized errors, no secret logging.

## Privacy approach

Raw mic audio is processed in memory and never stored. Recording
analysis defaults to on-device; enhanced transcription is an explicit
opt-in. Family Shield payloads carry an incident reference and risk
band only — no audio, transcript, or PII. Provider keys never ship in
the client; the AssemblyAI streaming token is short-lived and
one-time-use; the broker route is `Cache-Control: no-store`.

## Accessibility & localization

581 localization keys at full parity across English, Arabic (true
RTL), Spanish, and French · System/Light/Dark themes · Large/Extra
Large text floor · Guided Mode · Reduced Motion · haptics control.

## Technologies used

Flutter · Dart · flutter_bloc · purchases_flutter (RevenueCat) ·
onesignal_flutter · record · http · Cloudflare Workers · node:test ·
GitHub Actions CI/CD + GitHub Pages.

## Challenges

- Designing multi-signal fusion that stays honest when inputs are
  absent — degraded states are first-class UI, never fake green.
- Keeping provider secrets off the client while remaining demoable —
  solved via a zero-dependency edge relay and compile-time config.
- Egyptian-Arabic scam semantics — handled by a dedicated bilingual
  lexicon, not a translated afterthought.

## What we built

A complete consumer app: onboarding + personalization, SafeCall
(live + demo), Analyze Recording, incident history with forensic
reports, Family Shield sender/receiver flows, a truthful paywall, and
a relay covering four integrations — with CI, tests (421 Flutter +
74 server), and localization across four languages.

## Future work

- Live Shield ambient monitoring (designed, not yet implemented).
- Calibrated acoustic models beyond the heuristic prototype.
- Production auth on the relay (authenticated users / attestation).
- iOS release.

---

## Judge walkthrough (text-only)

1. **Open PauseSignal** — Home shows a readiness hero, a truthful
   free-tier badge, and calm Family Shield status.
2. **Start SafeCall** — the picker offers **Live Mic** (real capture)
   and **Demo** (labelled simulation); the distinction is explicit.
3. **Demo Attack** — deterministic audio + a scripted Egyptian-Arabic
   scam dialogue drive the real pipeline. The **Signal Lens** HUD
   shows the two evidence axes diverging as the Threat Score climbs
   SAFE → CAUTION → HIGH RISK, with evidence chips naming the signals
   that fired and highlighted phrases in the transcript feed.
4. **HIGH RISK** — the escalation flow leads with *verify identity
   independently*, not panic; an optional Family Shield alert is
   offered, clearly labelled when the relay isn't configured.
5. **Incident Report** — the session persists with a real SHA-256
   audio digest, source provenance, consumer-readable reasons, and a
   collapsible technical-evidence section.
6. **Family Shield** — trusted-circle management (≤5), receiver
   registration with an opaque `vg_` identity, Safe / Still
   Suspicious responses.
7. **Analyze Recording** — file picker, explicit privacy-mode choice
   (on-device vs. relay transcription), honest *Partial Analysis*
   when conversation signals weren't processed.
8. **Paywall** — Sentinel / Family Vault tiers; backend badge states
   plainly whether it's RevenueCat Test Store, a real store, or the
   labelled Demo Store.
9. **Settings** — language (EN/AR/ES/FR), theme, text size, Guided
   Mode, Reduced Motion, notifications truth, subscription state.

Every surface states what is real, demo, or unavailable — that
honesty is the product's thesis applied to itself.
