# Store Metadata — VoxGuard

Copy deck for Google Play / App Store listings. All claims match
shipped behavior — see `docs/FINAL_QA.md` for what is and is not
verified on hardware.

## Identity

| Field | Value |
|-------|-------|
| App name | **VoxGuard** |
| Subtitle / short description | Voice scam risk defense — hear the threat before you trust the voice. |
| Category | Tools / Safety |
| Package / bundle ID | `com.nemesisdevx.voxguard` (Android + iOS) |
| Content rating | Everyone |

## Full description

> VoxGuard helps you think twice before trusting a suspicious voice.
>
> Start a protection session and VoxGuard listens through your
> microphone — a caller on speakerphone, a voice note, or a message
> played nearby — and surfaces risk signals in real time:
>
> • **ThreatCore** — a calm, glanceable risk indicator that escalates
>   only when the evidence does.
> • **Multi-signal threat radar** — acoustic anomaly indicators plus
>   conversation-risk signals (urgency, financial demands, secrecy
>   requests, impersonation claims) analyzed on-device in English and
>   Egyptian Arabic.
> • **Live transcript with evidence highlighting** — when
>   transcription is configured, suspicious phrases are flagged
>   inline so you can see *why* VoxGuard is concerned.
> • **Incident reports** — every flagged session is saved on-device
>   with its audio digest, provenance, and recommended next steps.
> • **Analyze Recording** — check a saved audio file or paste a
>   transcript; acoustic-only results are honestly labeled as
>   partial analysis.
> • **Family Shield** — send a privacy-minimal alert to your Trusted
>   Circle when something feels wrong. They verify independently —
>   by calling the number they already trust — and their human
>   response comes back to you. No audio, transcript, or phone
>   numbers ever leave in an alert.
>
> VoxGuard does not intercept calls, does not judge callers, and does
> not claim certainty. It gives you risk signals and a moment to
> verify — because the best defense against voice scams is a second
> of doubt.

## Feature bullets (short form)

- User-started protection sessions — never background listening
- Acoustic anomaly + conversation-risk signals, fused into one score
- On-device bilingual analysis (English + Egyptian Arabic)
- Honest partial-analysis labeling when only acoustics were analyzed
- Privacy-minimal Family Shield alerts with human verification loop
- Local incident history with forensic detail and audio digest

## Subscription descriptions

| Tier | Listing copy |
|------|--------------|
| Quick Check (Free) | Live Mic acoustic monitoring, on-device recording analysis, local incident history, Family Shield receive & respond. |
| Sentinel Shield | Adds automatic Live Mic transcription and transcript-backed conversation-risk analysis (requires configured infrastructure), enhanced recording transcription, fused multi-signal Threat Score. |
| Family Vault | Adds real outbound Family Shield alerts to your Trusted Circle (up to 5 locally saved contacts) with the human safety-resolution loop. |

Prices are shown by the store from the current RevenueCat Offering —
never quote fixed prices in listing text.

## Privacy summary

- Microphone is requested only after you choose Live Mic — never at
  launch, never in the background.
- Live Mic audio is processed in memory; VoxGuard does not store raw
  microphone recordings.
- With an entitled plan and configured infrastructure, Live Mic
  audio may stream to the transcription provider for analysis.
- Analyze Recording uploads your selected file only when you choose
  enhanced transcription.
- Incident metadata and Trusted Circle contacts stay on-device.
- Family Shield alerts carry only opaque IDs, risk level, and
  analysis scope — no audio, transcript, names, or numbers.

## URLs

| Field | Value |
|-------|-------|
| Privacy policy | `https://nemesisdevx.github.io/voxguard/privacy.html` — live (HTTP 200 verified); in-app default in `LegalLinks`, overridable via `VOXGUARD_PRIVACY_POLICY_URL` |
| Terms | `https://nemesisdevx.github.io/voxguard/terms.html` — live (HTTP 200 verified); same override via `VOXGUARD_TERMS_URL` |
| Support URL | `https://github.com/NemesisDevX/voxguard/issues` — project support and issue reports |

## Reviewer notes

- Demo Mode (SafeCall → "Demo Attack") runs a fully scripted,
  on-device scenario — no microphone, network, or account needed to
  evaluate the core loop.
- The Demo Store backend exercises the complete paywall flow without
  real purchases; real-store access for reviewers is via the
  RevenueCat Offering on keyed builds.
- Microphone permission is exercised via Live Mic only.
- Family Shield end-to-end requires two devices or the documented
  relay test harness (`docs/FAMILY_SHIELD_SMOKE_TEST.md`).
