# VoxGuard Design System

Status: **internal design reference** — VoxGuard is a working
project name, not the final public brand. The visual system is
deliberately name-agnostic: the `SignalMark` glyph and Signal Lens
metaphor carry no letters, no shield, and no wordmark dependency, so
a later rename only touches the `appName` ARB key and store assets.

---

## 1. Product design principles

In priority order — when two rules conflict, the higher one wins:

1. **Calm before alarm.** The resting state is quiet. Color and
   motion budgets are spent only when evidence earns them.
2. **Evidence before score.** Every surface leads with what was
   observed (signals, phrases, provenance) and demotes the number.
3. **Verification before trust.** The primary action in every
   elevated state is *verify independently* — never "trust this
   result".
4. **Human judgment stays visible.** Machine analysis and human
   Family Shield responses render in visually separated surfaces.
   A human response never edits the AI score.
5. **Partial analysis looks incomplete, never safe.** A missing
   signal layer draws as broken/absent — a `PARTIAL ANALYSIS` label
   — never as a clean SAFE verdict or a composite Threat Score.
6. **Danger creates clarity, not panic.** The high-risk state is a
   pause ("Pause. Verify before you act."), not an alarm screen.

Tone targets: consumer-first, warm but serious, premium, high-trust.
Not enterprise cybersecurity software, not a caller-ID database, not
an AI-assistant chat surface.

---

## 2. The Signal Lens metaphor

The product signature is **TWO SIGNALS → ONE HUMAN DECISION**.

```
        ╭── Layer A: CONVERSATION ──╮
        │   what is being said      │
        │   (semantic evidence)     │
        ╰── Layer B: VOICE ─────────╯
            acoustic anomalies
                ↓
        ONE HUMAN DECISION
        pause → verify independently
```

- **Layer A — Conversation** (`AppColors.signalSemantic`, muted
  periwinkle): the semantic engine's evidence — urgency, payment
  demand, secrecy, impersonation claims.
- **Layer B — Voice acoustics** (`AppColors.signalAcoustic`, warm
  sand): the acoustic engine's anomaly indicators.
- Each layer's stroke sweeps in proportion to the evidence that
  layer *actually produced*. Endpoint positions are the readout —
  when risk rises, the two paths visibly diverge and pick up a
  subtle instability jitter.
- **Absent layer:** when conversation analysis never ran (acoustic-
  only sessions), Layer A draws as a broken dashed outline in
  `signalAbsent`. The layer is visibly *missing* — it is never
  drawn at "zero" or fabricated.
- The composite number inside the lens is labelled **RISK SIGNAL** —
  a product risk band, never a statistical probability, never a
  speedometer.
- On verification (post-call flow, Family Shield), the visual weight
  shifts from the lens toward human action surfaces — detect →
  resolve.

`SignalLens` (`lib/features/protection/presentation/widgets/
signal_lens.dart`) is the single component implementing this. It is
a `StatefulWidget` with a breathing `AnimationController` (2.6 s
reverse loop), a `TweenAnimationBuilder` score tween, and a
`CustomPainter` drawing both tracks, arcs, terminal nodes, and the
absent-layer dashes.

---

## 3. Color

Defined in `lib/core/theme/app_colors.dart` — flat, restrained,
no gradients, no neon borders.

| Token | Value | Meaning |
|---|---|---|
| `bgBase` | `#0E1014` | Deep graphite foundation |
| `bgSurface` | `#15181F` | Warm elevated surface |
| `bgElevated` | `#1D2029` | Cards that need lift |
| `surfaceCard` | `#21252F` | Standard card |
| `borderSubtle` | `#343A47` | Hairline borders |
| `textPrimary` | `#F4F1EA` | Warm off-white — never `#FFF` |
| `textMuted` | `#9AA1BC` | Secondary/metadata periwinkle |
| `statusSafe` | `#3ED0A0` | Verified / calm mint |
| `statusWarning` | `#E3A63C` | Uncertainty — warm amber |
| `statusDanger` | `#E15B44` | Active danger — oxide, sparingly |
| `accent` | `#8B9CC9` | Muted periwinkle brand accent |
| `signalSemantic` | `#8B9CC9` | Layer A — conversation |
| `signalAcoustic` | `#C9B284` | Layer B — voice acoustics |
| `signalAbsent` | `#4A4F5E` | A layer that did not run |

Rules:

- `statusDanger` appears **only** when evidence reaches the high-risk
  band or a destructive action needs it.
- `AppColors.forThreat(score)` is the single score→color mapping
  (`<0.4` safe, `<0.7` warning, else danger).
- `AppColors.forSignalLayer(layer, score)` lerps a layer's own hue
  toward its status color — layers keep identity at low evidence and
  converge on the risk band as evidence accumulates.

### Theme-aware palette

`lib/core/theme/app_palette.dart` — `AppPalette` is the
`ThemeExtension` all presentation code consumes via
`context.palette` (never `AppColors` directly in widgets; painters
and context-less helpers receive a palette explicitly).

| Brightness | Base | Surface | Text | Accent-aware |
|---|---|---|---|---|
| Dark | `#0E1014` deep ink | `#15181F`→`#1D2029` | `#F4F1EA` warm off-white | periwinkle `#8B9CC9` |
| Light | `#F6F3EC` warm off-white | `#FFFFFF` elevated | `#1F2430` ink | periwinkle `#5468A8` |

- Semantic colors (`statusSafe/Warning/Danger`, `signal*`) are
  centrally owned per-brightness — accents and user customization
  can never recolor them (test-enforced).
- Curated accents: `periwinkle`, `softBlue`, `softViolet` — tint
  interactive surfaces only (buttons, selection, nav highlight).
- Restrained gradients appear only where hierarchy earns them:
  Welcome Setup hero, launch surface — never on every card, never
  glassmorphism, never glow borders.
- Text size pref is a floor (`max(osScale, floor)`) — 1.0 / 1.18 /
  1.35; the app never shrinks text below the OS setting.
- Reduced motion: `MediaQuery.disableAnimations` ORs OS + app pref;
  breathing stops, theme swap is instant, launch is a static fade.

Full rules: `docs/PERSONALIZATION_AND_LOCALIZATION.md`.

---

## 4. Typography

`lib/core/theme/app_typography.dart` — the hierarchy enforces
**one primary statement, one dominant action, supporting evidence
below**:

- `displayLarge` / `displaySmall` — the single screen statement
  ("Pause.", "Start a protection check").
- `titleLarge` / `titleMedium` — section titles, card headlines.
- `bodyLarge` / `bodyMedium` — human-readable interpretation and
  evidence.
- `labelSmall` — ALL-CAPS section labels (sparingly), badges.
- `statLarge` — the Risk Signal numeral.

Anti-patterns enforced: no five-equally-weighted card grids on
primary screens, no walls of tiny telemetry labels, no long
paragraphs on action surfaces. Technical evidence exists but is
visually secondary (collapsed sections, muted text).

Arabic transcript text renders RTL via `isRtlText` detection and
`fontFamilyFallback` (Noto Naskh) — never matched against the
English keyword highlighter.

---

## 5. Spacing & shape

- Page padding: `20` horizontal, `8–24` vertical.
- Card radius: `14` (standard), `16` (sections), `22` (hero).
- Card internals: `14–18` padding, `8–12` element gaps.
- Section rhythm: `28` between major groups, `14–16` between cards.
- Borders: 1 px `borderSubtle`; `1.2–1.6` only on selected/active.

---

## 6. Component hierarchy

| Component | Role |
|---|---|
| `SignalMark` | Two-arc brand glyph — no shield, no letters |
| `SignalLens` | Two-layer evidence lens + state label + legend |
| `ProtectionBanner` | Calm readiness strip + live plan badge |
| `_HeroProtectionCard` | Home: one statement + one action |
| `_FamilyShieldStatusCard` | Readiness status, never an alarm |
| `_ModeCard` | SafeCall picker — Live Mic (REAL SESSION) vs Demo Attack (DEMONSTRATION) |
| `_PauseCard` | High-risk pause/verify moment |
| `_Section` / `_Card` | Labelled evidence containers |
| `_TechnicalRecord` | Collapsed SHA-256/provenance details |

---

## 7. Animation rules

Motion communicates **state**, never decoration:

- **Breathing** (2.6 s, ±2 %): signal paths stay alive while
  monitoring. Stops entirely under reduced-motion.
- **Score tween** (500 ms `easeOutCubic`): evidence arrival shifts
  the lens smoothly.
- **Risk jitter**: arc endpoints shear ±0.018 rad at CAUTION and
  ±0.045 rad at HIGH RISK — instability *is* the escalation.
- **State transitions** (300 ms `AnimatedSwitcher`): band labels
  cross-fade.
- **Convergence**: verification/human-response surfaces are static —
  stability is the message.

Banned: ornamental particles, looping scanners, radar sweeps,
animation that delays a safety action.

Reduced-motion contract: `MediaQuery.disableAnimations` stops the
breathing controller and zeroes switcher/tween durations. State
renders instantly and identically — reduced motion never hides
evidence.

---

## 8. Haptics

Restrained, state-only:

- session start / demo toggle → `lightImpact`
- risk-band **upward** transition → one `mediumImpact`
- Family Shield resolution recorded → one `mediumImpact`

Never continuous vibration during monitoring.

---

## 9. Accessibility

- Touch targets ≥ 44 px on all primary actions.
- State is never color-only: band labels are text; the lens has a
  `Semantics` label; the missing layer is a broken *shape*, not
  just a grey.
- Text scale 1.3×/1.5× and 320 px widths are covered by
  `responsive_smoke_test.dart`; overflow is solved with wrapping /
  scroll, not by shrinking text below readable sizes.
- Arabic transcript content renders RTL end-to-end.
- Danger surfaces keep ≥ 4.5:1 text contrast on `bgBase`.

---

## 10. Partial-analysis visual semantics

An acoustic-only result is **incomplete by design**:

- Label: `PARTIAL ANALYSIS` — never SAFE / SUSPICIOUS / HIGH RISK.
- Color: amber (`statusWarning`), not green.
- The Signal Lens draws Layer A as a broken dashed outline.
- Recording results get a dashed-border card + the absent-layer
  legend idiom ("CONVERSATION SIGNAL · NOT ANALYZED").
- No composite Threat Score is ever rendered for a partial record —
  in UI *and* in `IncidentReport.toShareText()`.

## 11. Human-vs-AI visual semantics

- Machine analysis lives inside the Signal Lens / evidence cards
  with periwinkle/sand layer hues.
- Human response surfaces (Family Shield card, receiver screen,
  response rows) use the mint `statusSafe` family and are labelled
  as human judgment ("YOUR JUDGMENT", "Human check-ins — separate
  from the analysis above").
- A Family Shield response never mutates the AI score; the two are
  rendered in separate containers so they can't visually merge.

## 12. Anti-patterns deliberately avoided

- Shield-as-main-UI, radar screens, matrix/hacker motifs.
- Neon glow borders, cyberpunk palettes, blue/purple AI gradients.
- "92% scam probability" certainty theatre.
- Generic caller-ID cards, red spam banners.
- Fake biometric/identity verification indicators.
- Decorative waveforms with no data behind them.
- Fear-selling paywall copy ("most secure", "bank-grade").
- Alert-style Family Shield surfaces when nothing is happening.
