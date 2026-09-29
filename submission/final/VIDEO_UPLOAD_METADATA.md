# Video Upload Metadata — PauseSignal Shipaton 2026

## File

- **File:** `pausesignal-shipaton-2026.mp4`
- **Runtime:** 93 s (1:33) — under the 2-minute Next Gen ceiling
- **SHA-256:** `fe8fb0cfe5018a3298f11deb88de763f680263fbf2567dab7caa51c6b4c0d922`
- **Resolution:** 1080×2160 portrait (native emulator capture, H.264 + silent AAC)
- **Audio:** silent track — no copyrighted music, no narration

## Proposed YouTube/Vimeo title

**PauseSignal — Hear the signal. Pause. Verify. (Shipaton 2026 Next Gen)**

## Concise description (YouTube/Vimeo)

PauseSignal is consumer protection against voice-impersonation and
coercion scams. Two evidence engines — acoustic anomaly analysis and a
bilingual (English + Egyptian Arabic) semantic threat engine — fuse
into one understandable Threat Score that creates a pause before
action. This video demonstrates the labelled Demo Attack flow, a real
persisted incident report with SHA-256 audio provenance, Analyze
Recording, Family Shield's privacy-minimal alert design, and the
RevenueCat-powered subscription paywall running in its clearly
labelled Demo Store state. Repository-side RevenueCat Test Store
integration is implemented; live Test Store verification runs in the
judging build. Open source (MIT): https://github.com/NemesisDevX/voxguard

## Devpost video summary (short field)

Multi-signal voice-scam defense: acoustic forensics + bilingual
semantic rules fused into a real-time Threat Score. Shown end-to-end:
labelled Demo Attack escalation, HIGH RISK verification guidance,
forensic incident report, recording analysis, Family Shield demo
state, and the RevenueCat subscription paywall. External provider
integrations are implemented server-side and honestly labelled where
not yet live.

## Truth disclosures (for judges)

- Demo Attack is a **simulated** scenario: generated audio + scripted
  Egyptian-Arabic dialogue through the identical analysis pipeline;
  all DEMO badges visible on camera.
- Subscription shown in **DEMO STORE** state (simulated checkout, no
  real charge); the shipped judging path uses RevenueCat's hosted
  **Test Store** via the real `purchases_flutter` SDK — see
  `docs/NEXT_GEN_REVENUECAT_TEST_STORE.md`.
- AssemblyAI / Groq / OneSignal relay paths are implemented
  (`server/`) but not exercised live in this video; the app reports
  their absence truthfully on camera.
- Captured on an Android emulator — not a physical device.

## Scene map

| Time | Content |
|---|---|
| 0:00–0:05 | Title card — name, tagline, problem |
| 0:05–0:08 | Welcome — four-language picker |
| 0:08–0:16 | Home + SafeCall picker (REAL SESSION / DEMO) |
| 0:16–0:24 | Demo session — acoustic-only start, DEMO MODE badges |
| 0:24–0:40 | Escalation SAFE → CAUTION → HIGH RISK 90+ |
| 0:40–0:52 | Pause sheet — flags, verification steps, Family Shield demo |
| 0:52–1:04 | Incident report INC — bilingual transcript + evidence |
| 1:04–1:09 | Analyze Recording picker |
| 1:09–1:17 | Settings — Family Shield identity, subscription state |
| 1:17–1:24 | Paywall — DEMO STORE badge, three tiers |
| 1:24–1:32 | Demo activation → "Sentinel Shield (demo)" |
| 1:32–1:33 | End card — tagline, repo, license |
