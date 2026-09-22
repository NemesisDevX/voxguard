# PauseSignal Demo Script — < 2:00

Target: one continuous, visually driven capture on a real device.
No long intro. No title card longer than 2 s. Demo Attack mode is
fully on-device — recording works offline.

| Time | Beat | Screen / action | VO |
|------|------|-----------------|----|
| 0:00–0:12 | Problem + promise | Title card: *"PauseSignal — hear the signal. Pause. Verify."* Cut to Home (readiness hero, calm). | "Voice scams now sound exactly like your family. PauseSignal gives you a second of doubt before you act." |
| 0:12–0:38 | Threat escalation | SafeCall → Demo Attack → Simulate scam. The Signal Lens paths diverge amber → oxide red; Arabic transcript lands RTL; evidence chips stack (impersonation, money demand, secrecy). | "A caller claims to be family, demands money, insists on secrecy. PauseSignal's engines flag it live." |
| 0:38–0:55 | Evidence + verify | Scroll transcript — flagged phrases highlighted. Show signal detail meters elevated. End call → incident report. | "Not a verdict — evidence. Every signal is shown so you can verify independently." |
| 0:55–1:15 | Family Shield loop | Device A: post-call sheet → send Family Shield alert. Device B: notification arrives → "Dad received a suspicious-call warning" → Call Dad / Mark Safe / Still Suspicious. Response lands back on A. | "One tap alerts your Trusted Circle — no audio, no transcript, just the signal. They verify by calling the number they already trust." |
| 1:15–1:35 | Recording analysis honesty | Analyze Recording → pick file → result shows **Partial Analysis** when only acoustics ran; transcript-backed result shows full fused score. | "If only acoustics were analyzed, PauseSignal says so — partial analysis, never a fake verdict." |
| 1:35–1:48 | Plans | Paywall → three tiers, Test Store prices, restore. (Judging build: **REVENUECAT TEST STORE** badge — real RevenueCat transactions; plain debug build: labeled Demo Store.) | "Free protection for everyone. Sentinel adds live transcription; Family Vault alerts your circle for real. Purchases run through RevenueCat's Test Store." |
| 1:48–2:00 | Impact + close | Montage: Signal Lens high-risk → family alert → Mark Safe green. End card: PauseSignal mark + tagline + "Shipaton Next Gen". | "Scams win when panic replaces verification. PauseSignal buys the pause that stops them." |

## Capture notes

- For Next Gen judging use the Test Store build
  (`--dart-define=REVENUECAT_TEST_STORE_KEY=...`) and keep the
  "REVENUECAT TEST STORE" badge visible — do not crop it out. If the
  demo build is used instead, keep the "DEMO STORE" badge visible
  the same way.
- Two devices for Family Shield; a cut between send (A) and receive
  (B) is honest — never fake a simultaneous split-screen that didn't
  happen.
- Screen record at native resolution; the 1179×2556 requirement is
  for screenshots, video just needs device footage.
- Upload to YouTube or Vimeo, public, before the deadline.
- `BLOCKED_EXTERNAL` — recording requires physical hardware.
