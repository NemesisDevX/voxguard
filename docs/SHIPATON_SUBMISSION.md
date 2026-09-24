# Shipaton 2026 Submission Pack — PauseSignal (Next Gen Award)

Target category: **Next Gen Award only**. Next Gen substitutes a
working app + demo video + public open-source repository for a store
listing — **no App Store / Google Play / Galaxy Store listing, store
review, release keystore, or paid developer account is required for
this submission.**

Prepared against the published Shipaton 2026 rules (Devpost,
deadline **Sep 30, 2026, 11:45 PM PDT**; official rules last updated
**August 31, 2026**). Nothing below claims eligibility that has not
been executed — external steps are marked `HUMAN/EXTERNAL`.

## Next Gen requirements

### REPO / DONE

| Requirement | Status |
|-------------|--------|
| Public GitHub repository | **VERIFIED** — `github.com/NemesisDevX/voxguard` returns 200 unauthenticated |
| Open-source license | **VERIFIED** — `LICENSE` (MIT) at repo root |
| 1024×1024 app icon | **DONE** — `submission/pausesignal-icon-1024.png`, SignalMark, verified 1024×1024 |
| 1179×2556 screenshot(s), no device frame | **DONE** — `submission/screenshots/` (7 frames at exact native resolution) |
| Working Android build | **DONE** — `flutter build apk --debug` PASS; emulator smoke QA DONE |
| App uses RevenueCat SDK for ≥1 purchase | **Repo-side DONE** — `purchases_flutter`, real SDK integration; judging path uses the RevenueCat **Test Store** (`docs/NEXT_GEN_REVENUECAT_TEST_STORE.md`) |
| Accurate English submission text | DONE — this file + `docs/STORE_METADATA.md` description |

### HUMAN / EXTERNAL PENDING

| Requirement | Status |
|-------------|--------|
| Active-student eligibility + qualifying academic/student email on Devpost | `HUMAN/EXTERNAL` — entrant attestation; nothing in the repo proves enrollment, age, consent, or academic-email eligibility |
| Minor-entrant consent | `HUMAN/EXTERNAL` — per the official rules: entrants under the age of majority where they reside, but at least 13 years old, may enter Next Gen subject to the parent/legal-guardian conditions in the official rules |
| Real RevenueCat Test Store integration demonstrated | `HUMAN/EXTERNAL` — needs a Test Store API key + dashboard config; the `--dart-define=REVENUECAT_TEST_STORE_KEY=...` seam is implemented and tested |
| RevenueCat Project ID on the Devpost form | `HUMAN/EXTERNAL` — dashboard value |
| Public demo video < 2 min | `HUMAN/EXTERNAL` — script ready: `docs/DEMO_SCRIPT.md`; recording deferred |
| Final Devpost submission | `HUMAN/EXTERNAL` — human submits |

### QA status (factual)

| Item | Status |
|---|---|
| Android debug/judging APK build | **PASS** |
| Android emulator smoke QA | **DONE** — zero-config launch, RTL, SafeCall demo, honest fallback states |
| Physical Android device QA | **PENDING** — checklist ready in `docs/FINAL_LIVE_QA_HANDOFF.md` §J |
| iOS build | **NOT VERIFIED** — no macOS/Xcode evidence |

**Explicitly NOT Next Gen blockers** (future commercial-release items,
tracked in `docs/RELEASE_HANDOFF.md`): store publication, store review,
Android release keystore, paid Apple/Google developer accounts, US
store availability, judge free-trial/promo codes.

## Project identity

- **Name:** PauseSignal
- **Tagline:** Hear the signal. Pause. Verify.
- **Short pitch:** Consumer-first AI-assisted protection against
  voice impersonation and coercion scams.
- **Internal note:** the repository, package name, and technical
  identifiers still say `voxguard` — that is the internal project
  identity (`docs/BRAND_RELEASE_DECISION.md`).

## Submission story

Voice impersonation fraud scales cheaply: a cloned or pressured
voice — a "child" in trouble, a "bank" demanding urgency — turns
panic into wire transfers in minutes. The most vulnerable users are
the least technical: parents, grandparents, people whose scam
literacy is *"hang up and hope."*

PauseSignal's loop is **HEAR → UNDERSTAND → WARN → EXPLAIN → VERIFY →
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
persisted by PauseSignal; Trusted Circle stays local; Family Shield
payloads are opaque IDs and risk metadata.

**Monetization:** freemium via RevenueCat — Quick Check (free),
Sentinel Shield (cloud transcription + fused scoring), Family Vault
(real outbound family alerts). For Next Gen judging, the app uses
RevenueCat's official **Test Store** through the real
`purchases_flutter` SDK — RevenueCat-hosted test transactions, real
`CustomerInfo` entitlements, clearly labelled *REVENUECAT TEST STORE*
in-app and never a real-money charge. The local simulated **DEMO
STORE** remains a separate, distinctly labelled backend.

## Judging path (Next Gen)

1. Build the judging APK:
   `flutter build apk --debug --dart-define=REVENUECAT_TEST_STORE_KEY=<test-store-key>`
2. Open the paywall — it is labelled **REVENUECAT TEST STORE**.
3. Purchase a package; the entitlement activates from real
   `CustomerInfo` returned by RevenueCat.
4. Restore Purchases verifies the same entitlement path.
5. The transaction appears in the RevenueCat dashboard's Test Store
   sandbox view.

Full dashboard setup: `docs/NEXT_GEN_REVENUECAT_TEST_STORE.md`.

## Devpost checklist

- [ ] Project name + tagline (above) — REPO/DONE
- [ ] Description (`docs/STORE_METADATA.md` full description) — REPO/DONE
- [ ] Public repo URL + OSS license — REPO/DONE: repo public, `LICENSE` MIT
- [ ] 1179×2556 screenshot — REPO/DONE: `submission/screenshots/01_home_threatcore.png` + alternates
- [ ] 1024×1024 icon — REPO/DONE: `submission/pausesignal-icon-1024.png`
- [ ] Test Store judging notes — REPO/DONE: `docs/NEXT_GEN_REVENUECAT_TEST_STORE.md`
- [ ] YouTube/Vimeo video link (<2 min, public) — `HUMAN/EXTERNAL` (deferred)
- [ ] RevenueCat Project ID — `HUMAN/EXTERNAL` (dashboard)
- [ ] Student eligibility + academic email — `HUMAN/EXTERNAL`
- [ ] Guardian consent if entrant is a minor — `HUMAN/EXTERNAL` (official-rules conditions)
- [ ] Team member details — `HUMAN/EXTERNAL`
