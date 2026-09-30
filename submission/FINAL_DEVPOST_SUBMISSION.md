# Final Devpost Submission — PauseSignal (Next Gen)

*Paste-ready draft. `TODO:` fields require the human submitter.*

---

**Project name:** PauseSignal

**Tagline:** Hear the signal. Pause. Verify.

**Category:** Next Gen Award

**Public repository:** https://github.com/NemesisDevX/voxguard (MIT License)

**Video URL:** `TODO: paste public YouTube/Vimeo link (<2 min)`

**RevenueCat Project ID:** `TODO: from RevenueCat dashboard`

## Description

A parent answers the phone. It's their child's voice — panicked,
begging for an emergency transfer. It's a deepfake. PauseSignal
exists for the seconds between *hearing* and *acting*: it listens
alongside the user, scores two independent kinds of evidence in real
time, and turns panic into a guided verification ritual instead of a
wire transfer.

## What it does

- **SafeCall** monitors a call's audio live (explicit user start —
  never background listening) or runs a clearly-labelled **Demo
  Attack** simulation for evaluation.
- **Engine A — acoustic forensics:** spectral flux, spectral rolloff,
  and zero-crossing-rate heuristics over real 16 kHz PCM — a
  heuristic prototype, honestly labelled.
- **Engine B — semantic threat engine:** a deterministic bilingual
  rule engine (English + Egyptian Arabic) detecting urgency,
  financial demands, secrecy pressure, and impersonation claims —
  on-device by default.
- **Threat Score (0–100):** fuses both engines
  (`semantic×0.65 + acoustic×0.35`, +15% coordinated-scam
  amplification), rendered on the Signal Lens HUD.
- **Incident reports:** every high-risk session persists a forensic
  record — SHA-256 audio provenance, flagged phrases, plain-language
  reasons, verification steps.
- **Family Shield:** privacy-minimal alerts to a trusted circle via
  an opaque `vg_` identity — no audio, transcripts, or phone numbers
  in the payload; receivers resolve Safe / Still Suspicious.
- **Analyze Recording:** upload a call recording for on-device
  acoustic analysis; optional relay transcription is explicit opt-in.

## How we built it

Flutter 3.41 / Dart 3.11, flutter_bloc, a feature/domain/data split
with an `IAudioStreamSource` seam (live PCM and demo PCM share one
pipeline), a zero-dependency Cloudflare Worker relay holding all
provider credentials, `purchases_flutter` for subscriptions behind a
decoupled interface, and CI that ships the web build to GitHub Pages.
427 Flutter tests + 74 relay tests. Full localization across English,
Arabic (true RTL), Spanish, and French — 581 keys each.

## RevenueCat integration

Subscriptions are built on `purchases_flutter` with `CustomerInfo` as
the sole entitlement authority:

- Entitlements `sentinel` and `family_vault`. The live Offering
  (verified via the SDK on 2026-09-30) resolves
  `$rc_monthly`→`sentinel_monthly` ($1.05), `$rc_annual`→
  `sentinel_annual` ($4.99), `$rc_two_month`→`family_vault_monthly`
  ($15.99), and a custom `Annual` package→`family_vault_annual`
  ($55.99) — real localized prices rendered from the current
  Offering via dashboard-agnostic identifier mapping.
- Four honest backends: production store, **RevenueCat Test Store**
  (the judging path — real SDK, sandbox transactions, dashboard
  evidence), a clearly-labelled local **Demo Store** for keyless
  sessions, and a truthful *unavailable* state for misconfigured
  release builds.
- Entitlements gate real behavior: transcription, fused scoring, and
  outbound Family Shield dispatch all resolve from `CustomerInfo` —
  a purchase result alone never unlocks anything.

*Verified live on 2026-09-30 with the RevenueCat Test Store SDK:
genuine sandbox purchases for Sentinel monthly ($1.05) and Family
Vault monthly ($15.99) completed through the native Test Store
purchase sheet, `CustomerInfo` reported `sentinel` and
`family_vault` active, the entitlement-gated UI updated accordingly
(Family Vault correctly takes precedence when both are active),
Restore Purchases re-derived the tier from `CustomerInfo`, and a
cancelled purchase granted nothing. Test Store transactions never
charge real money.*

## Challenges

- Keeping a multi-signal product **honest** when integrations are
  absent — degraded states are first-class UI, never fake green.
- Provider secrets on a mobile client — solved with a tiny edge relay
  and compile-time defines; permanent keys are server-side and
  release builds code-reject direct-key paths.
- Egyptian-Arabic scam semantics — built as a first-class lexicon,
  not a translation of the English one.

## Accomplishments

- A complete, runnable consumer app with real audio processing —
  every screen works with zero credentials.
- Truthful capability labelling throughout: DEMO / LIVE / PARTIAL /
  unavailable states are never disguised.
- 427 + 74 passing tests, CI green, release safety pinned by
  regression tests.

## What we learned

Assistive safety UX is mostly about *truth management*: a risk tool
that lies about its own capability is worse than no tool. Also —
deterministic rule engines get you surprisingly far for scam
semantics in two languages before you need an LLM.

## What's next

- Relay-backed provider verification in live QA (AssemblyAI / Groq /
  OneSignal infrastructure is implemented and documented in
  `docs/FINAL_LIVE_QA_HANDOFF.md`; intentionally deferred to keep
  the submission honest — no fabricated evidence).
- Physical-device QA and iOS build (requires macOS/Xcode).
- Calibrated acoustic models; Live Shield ambient mode.

## Disclosures

- **Demo Attack is simulated** — generated audio + scripted dialogue
  through the identical pipeline; always labelled.
- The video's subscription segment runs on **RevenueCat's hosted
  Test Store** via `purchases_flutter` — a genuine sandbox
  transaction against the real SDK, not a real-money charge. Demo
  Attack remains simulated and labelled.
- AssemblyAI / Groq / OneSignal paths are implemented server-side but
  not exercised live in the demo assets.
- Recorded on an Android emulator, not a physical device.
