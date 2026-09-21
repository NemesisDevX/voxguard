# Shipaton 2026 Submission Pack — VoxGuard

Prepared against the published Shipaton 2026 rules (Devpost,
deadline **Sep 30, 2026, 11:45 PM PDT**). Nothing below claims
eligibility that has not been executed — external steps are marked.

## Hard requirements (all categories)

| Requirement | Status |
|-------------|--------|
| iOS/iPadOS/macOS/Android app using RevenueCat SDK for ≥1 purchase | **Repo-side DONE** — `purchases_flutter 10.13.1`, real store backend Android/iOS |
| New app — first public version inside the submission window | `BLOCKED_EXTERNAL` — depends on first store release date |
| Fully published store listing (Play/App/Galaxy) — TestFlight/testing tracks do not count | `BLOCKED_EXTERNAL` — needs signing key + store account |
| Available to download in the United States | `BLOCKED_EXTERNAL` — store distribution setting |
| Public YouTube/Vimeo demo video < 2 min, on-device footage | `BLOCKED_EXTERNAL` — script ready: `docs/DEMO_SCRIPT.md` |
| Text description of features | DONE — `docs/STORE_METADATA.md` |
| 1179×2556 screenshot(s), no device frame | **DONE** — `submission/screenshots/` (7 frames rendered at exact native resolution) |
| 1024×1024 icon | **DONE (provisional)** — `submission/voxguard-icon-1024.png` verified 1024×1024; shield motif is a placeholder pending the public rebrand — the final icon follows the SignalMark direction (`docs/DESIGN_SYSTEM.md`) |
| App works as shown in video/description | Partially — device QA matrix pending: `docs/FINAL_QA.md` |

## Project identity

- **Name:** VoxGuard
- **Tagline:** Hear the threat before you trust the voice.
- **Short pitch:** Consumer-first AI-assisted protection against
  voice impersonation and coercion scams.

## Submission story

Voice impersonation fraud scales cheaply: a cloned or pressured
voice — a "child" in trouble, a "bank" demanding urgency — turns
panic into wire transfers in minutes. The most vulnerable users are
the least technical: parents, grandparents, people whose scam
literacy is *"hang up and hope."*

VoxGuard's loop is **HEAR → UNDERSTAND → WARN → EXPLAIN → VERIFY →
PROTECT FAMILY**:

1. The user starts a protection session (mic only after explicit
   choice — never background listening).
2. Engine A extracts acoustic anomaly indicators from PCM in real
   time; Engine B runs deterministic bilingual (EN + Egyptian
   Arabic) conversation-risk analysis on the transcript.
3. A fusion engine produces a composite Threat Score — a *product
   risk score*, never a probability claim.
4. The UI escalates calmly: amber for suspicion, crimson for active
   threat — always with the evidence attached.
5. Post-call, the incident report explains *why*: flagged phrases,
   signal meters, audio digest, recommended actions.
6. Family Shield sends a privacy-minimal alert (opaque IDs + risk
   level only) to the Trusted Circle; a human verifies independently
   and their resolution — safe or still suspicious — loops back.

**Architecture:** Flutter client (on-device DSP + semantic engine,
AssemblyAI streaming when entitled and configured), Cloudflare
Worker relay → OneSignal for Family Shield, RevenueCat for
entitlements. No accounts, no cloud incident sync, no PII beyond a
locally saved trusted phone number.

**Privacy:** mic permission on user action only; raw audio never
persisted by VoxGuard; Trusted Circle stays local; Family Shield
payloads are opaque IDs and risk metadata.

**Monetization:** freemium via RevenueCat — Quick Check (free),
Sentinel Shield (cloud transcription + fused scoring), Family Vault
(real outbound family alerts). Real store on Android/iOS; Demo
Store clearly labeled elsewhere.

## Categories

### Next Gen Award (student-only)

- Public open-source repo: `github.com/NemesisDevX/voxguard` —
  MIT license at repo root, full source + docs.
- Next Gen substitutes repo + demo video for a store listing —
  but the store path above is still the goal.
- `BLOCKED_EXTERNAL` — student status must be attested by the
  entrant on the Devpost form; nothing in the repo proves it.

### RevenueCat Design Award

Judgable design details:

- **Signal Lens** — the signature visual: two evidence paths
  (conversation + acoustic) that run together when calm and diverge
  under risk — *two signals → one human decision*. An absent layer
  renders as a broken outline, never fabricated.
- **Evidence-first hierarchy** — state and human interpretation
  first, then evidence chips, then flagged transcript phrases, then
  collapsed technical detail; the score never leads alone.
- **Privacy-first onboarding** — permission rationale before any
  system prompt.
- **Partial-analysis honesty** — acoustic-only results are labeled
  "Partial Analysis" / "ACOUSTIC ONLY" everywhere they appear,
  including share text; a missing conversation signal can never
  render as a fused SAFE verdict.
- **Family Shield human-resolution loop** — the receiver *verifies
  independently*; the app never declares a caller safe.
- **Calm safety palette** — graphite base, restrained accents, no
  hacker aesthetic; reduced-motion respected.

### RevenueCat Peace Prize

Real societal benefit, no fabricated metrics:

- Voice impersonation and "family emergency" scams cause billions in
  reported losses annually and target the elderly hardest.
- VoxGuard's core mechanic — *pause and verify on a number you
  already trust* — is the exact behavior fraud-resistance guidance
  recommends; the app operationalizes it.
- Family Shield extends protection asymmetrically: a technical user
  can shield a non-technical parent, and the parent's side needs
  only a phone call.

### Keep Them Coming Back — OneSignal

- **Implemented integration:** OneSignal push drives the entire
  Family Shield loop — danger alerts outbound, human-resolution
  responses inbound, tap routing, explicit opt-in.
- **Campaign:** `docs/ONESIGNAL_CAMPAIGN.md` — "Family Safety
  Check-In" re-engagement concept, deployment checklist ready.
- `BLOCKED_EXTERNAL` — campaign deployment requires OneSignal
  Dashboard credentials; not yet deployed. `ONESIGNAL_APP_ID`
  submitted on the Devpost form at submission time.

## Submission checklist (Devpost form)

- [ ] Project name + tagline (above)
- [ ] Description (`docs/STORE_METADATA.md` full description)
- [ ] Public store link — `BLOCKED_EXTERNAL`
- [ ] YouTube/Vimeo video link (<2 min, public) — `BLOCKED_EXTERNAL`
- [ ] 1179×2556 screenshot — `submission/screenshots/01_home_threatcore.png` + alternates
- [ ] 1024×1024 icon — `submission/voxguard-icon-1024.png`
- [ ] RevenueCat Project ID — `BLOCKED_EXTERNAL` (dashboard)
- [ ] OneSignal App ID (OneSignal category) — `BLOCKED_EXTERNAL`
- [ ] Public repo URL + OSS license (Next Gen) — repo public + `LICENSE` present
- [ ] Team member details — `BLOCKED_EXTERNAL`
