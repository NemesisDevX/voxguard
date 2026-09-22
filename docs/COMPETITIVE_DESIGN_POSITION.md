# PauseSignal — Competitive Design Position

Status: internal design-position note. Factual UX differentiation —
no claims about competitor quality, detection accuracy, or business.

---

## The differentiated loop

PauseSignal's primary surfaces are built around one sequence:

```
evidence → pause → independent verification → trusted human response
```

Everything on the primary screens serves that loop. The Signal Lens
shows two evidence streams (what is being said; what the audio
sounds like) and hands the decision to a person.

---

## How the UX differs from adjacent categories

### Caller-ID apps (e.g. Truecaller, Hiya)

- **Their unit of UX is the lookup:** a name/reputation verdict
  attached to an incoming call, driven by a crowdsourced database.
  Their screens answer "*who* is calling?".
- **PauseSignal never identifies callers.** It has no contact database,
  no spam-score lookup, no caller name claims. Its screens answer
  "*what signals did this conversation produce?*" — evidence the
  user can inspect, not a reputation label.
- Visual difference: no incoming-call card, no red "SPAM" banner,
  no crowd-sourced stats. The home hero is an action ("Start a
  protection check"), not a directory.

### Deepfake / voice-clone probability tools (e.g. AIKIZI-style)

- **Their unit of UX is a percentage:** "X% AI-generated". The
  product IS the probability.
- **PauseSignal deliberately refuses a probability.** The Risk Signal
  score is labelled a *signal*, capped by a band system
  (SAFE / CAUTION / HIGH RISK), and the acoustic engine is described
  in-product as "an assistive heuristic prototype, not a forensic
  verdict". Acoustic-only results render as `PARTIAL ANALYSIS` with
  a visibly missing layer — the opposite of a confident percentage.
- Visual difference: a missing conversation layer draws as a broken
  outline, not a low score. Incompleteness is a first-class visual
  state.

### Safe-word / family-phrase products (e.g. KinProof-style)

- **Their unit of UX is the pre-arranged secret:** setup flows
  center on choosing and storing a family safe word.
- **PauseSignal treats the safe phrase as *advice*, not a feature
  surface** ("agree on a family safe phrase offline"). Nothing is
  stored, challenged, or verified by the app — the phrase is a human
  practice the app recommends, not a protocol the app runs.
- Visual difference: no safe-word setup wizard, no challenge/response
  UI. Family Shield is a *human response loop* — alerts carry only an
  opaque ID, a risk band, and an incident reference.

### Generic security dashboards (e.g. NORA-style scanners)

- **Their unit of UX is telemetry:** grids of metrics, logs,
  shields, radar sweeps — "the system is working" rendered as the
  main content.
- **PauseSignal enforces one-statement-per-screen hierarchy.** Home has
  one hero action. SafeCall leads with the Signal Lens and a
  human-readable interpretation ("Pause before acting."); raw DSP
  values live in a collapsed TECHNICAL DETAILS section. Incident
  detail uses progressive disclosure — state → why flagged →
  evidence → verify → family → collapsed technical record.
- Visual difference: danger states replace the score-first layout
  with a pause card and a verification CTA. Calm is the default;
  color budget is spent only when evidence earns it.

---

## What PauseSignal does NOT compete on

- Caller-ID database size or coverage.
- Automatic call blocking or native cellular interception
  (explicitly disclaimed in-product).
- AI voice-clone probability scoring.
- Family safe-word management.
- Background interception of any kind — sessions are user-started.

## What the design optimizes for instead

- **Two visible evidence streams** instead of one opaque verdict.
- **A pause, not an alarm**, at the high-risk moment.
- **Independent verification as the primary action** on every
  elevated surface.
- **A human second set of eyes** (Family Shield) rendered as human
  judgment — visually separate from machine analysis, never merged
  into the score.
- **Honest incompleteness** — partial analysis is a visible gap,
  never a safe-looking result.
