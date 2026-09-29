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
421 Flutter tests + 74 relay tests. Full localization across English,
Arabic (true RTL), Spanish, and French — 581 keys each.

## RevenueCat integration

Subscriptions are built on `purchases_flutter` with `CustomerInfo` as
the sole entitlement authority:

- Entitlements `sentinel` and `family_vault`; packages
  `sentinel_monthly`, `sentinel_annual`, `family_vault_monthly`,
  `family_vault_annual` — real localized prices rendered from the
  current Offering.
- Four honest backends: production store, **RevenueCat Test Store**
  (the judging path — real SDK, sandbox transactions, dashboard
  evidence), a clearly-labelled local **Demo Store** for keyless
  sessions, and a truthful *unavailable* state for misconfigured
  release builds.
- Entitlements gate real behavior: transcription, fused scoring, and
  outbound Family Shield dispatch all resolve from `CustomerInfo` —
  a purchase result alone never unlocks anything.

*Repository-side Test Store integration is implemented; live
verification evidence is collected in the judging build.*

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
- 421 + 74 passing tests, CI green, release safety pinned by
  regression tests.

## What we learned

Assistive safety UX is mostly about *truth management*: a risk tool
that lies about its own capability is worse than no tool. Also —
deterministic rule engines get you surprisingly far for scam
semantics in two languages before you need an LLM.

## What's next

- RevenueCat Test Store + relay-backed provider verification in live
  QA (infrastructure is implemented and documented in
  `docs/FINAL_LIVE_QA_HANDOFF.md`).
- Physical-device QA and iOS build (requires macOS/Xcode).
- Calibrated acoustic models; Live Shield ambient mode.

## Disclosures

- **Demo Attack is simulated** — generated audio + scripted dialogue
  through the identical pipeline; always labelled.
- The video's paywall runs in **Demo Store** state (no real charge);
  judging builds use RevenueCat's hosted Test Store.
- AssemblyAI / Groq / OneSignal paths are implemented server-side but
  not exercised live in the demo assets.
- Recorded on an Android emulator, not a physical device.
