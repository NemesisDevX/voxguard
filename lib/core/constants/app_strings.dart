/// Centralized user-facing strings for VoxGuard.
abstract final class AppStrings {
  AppStrings._();

  // ── Global ───────────────────────────────────────────────────────
  static const String appName = 'VoxGuard';

  // ── Home ─────────────────────────────────────────────────────────
  static const String shieldStatusReady = 'VoxGuard Ready';
  static const String shieldSubtitle = 'Real-time voice defense standing by';
  static const String quickActions = 'PROTECTION';

  static const String startSafeCall = 'Start SafeCall';
  static const String startSafeCallDesc =
      'In-app protected call with live threat telemetry.';

  /// Home hero — the readiness-first primary action.
  static const String protectionCheckTitle = 'Start a protection check';
  static const String protectionCheckDesc =
      'Use speakerphone or play suspicious audio nearby — '
      'VoxGuard listens for risk signals.';
  static const String protectionCheckCta = 'Start SafeCall';

  static const String analyzeRecording = 'Analyze Recording';
  static const String analyzeRecordingDesc =
      'Check a saved call recording or voice note.';

  static const String incidentLogTooltip = 'Incident log';

  // ── Family Shield readiness (home status surface) ────────────────
  static const String familyShieldTitle = 'Family Shield';
  static const String familyReadyWithCircle = 'Trusted Circle ready';
  static const String familyAlertsEnabled = 'Family alerts enabled';
  static const String familyNeedsSetup = 'Needs setup';
  static const String familyStatusHint =
      'A second set of eyes when a call feels wrong.';

  // ── Bottom navigation ────────────────────────────────────────────
  static const String navShield = 'Protect';
  static const String navIncidents = 'Incidents';
  static const String navSettings = 'Settings';

  // ── SafeCall HUD ─────────────────────────────────────────────────
  static const String safeCallTitle = 'SafeCall';
  static const String safeCallActive = 'PROTECTION SESSION ACTIVE';
  static const String unknownCaller = 'Unknown Caller';
  static const String maskedNumber = '+1 (•••) ••• ••42';
  static const String endCall = 'End';

  static const String threatRadarTitle = 'MULTI-SIGNAL THREAT RADAR';
  static const String liveBadge = 'LIVE';

  static const String signalSynthetic = 'Synthetic Voice Indicators';
  static const String signalUrgency = 'Urgent Pressure';
  static const String signalFinancial = 'Financial Transfer Demand';
  static const String signalSecrecy = 'Secrecy & Isolation Request';

  static const String statusNormal = 'NORMAL';
  static const String statusElevated = 'ELEVATED';

  static const String bannerProtected = 'PROTECTED';
  static const String bannerProtectedDetail = 'All signals nominal — no threat indicators';
  static const String bannerElevated = 'ELEVATED RISK';
  static const String bannerElevatedDetail = 'Suspicious pattern — monitoring closely';
  static const String bannerThreat = 'High-Risk Call Detected';
  static const String bannerThreatDetail =
      'Impersonation and financial demand patterns flagged';
  static const String threatScoreLabel = 'Threat Score';

  static const String simulateScam = 'Simulate Scam';
  static const String stopSimulation = 'Stop Demo';

  /// High-risk live-session cue — the emotional signature.
  static const String pauseHeadline = 'Pause before acting.';
  static const String verifyBeforeYouAct = 'Verify before you act.';
  static const String endCallAndVerify = 'End call & verify';
  static const String technicalDetails = 'TECHNICAL DETAILS';

  static const String liveTranscript = 'LIVE TRANSCRIPT';
  static const String transcriptEmpty =
      'Transcript appears here during a protected call.';
  static const String speakerCaller = 'Caller';
  static const String speakerYou = 'You';

  // ── Paywall ──────────────────────────────────────────────────────
  static const String paywallTitle =
      'Two signals.\nOne human decision.';
  static const String paywallSubtitle =
      'VoxGuard flags risk — you verify. Paid plans extend what the '
      'two signals can see.';
  static const String securityBadge =
      'Billing handled by your app store';
  static const String demoStoreBadge = 'DEMO STORE';
  static const String demoStoreNotice =
      'Simulated checkout — no real charge will occur.';
  static const String storeUnavailableNotice =
      "Subscriptions aren't configured in this build.";
  static const String monthly = 'Monthly';
  static const String annual = 'Annual';
  static const String mostPopular = 'MOST POPULAR';
  static const String upgradeNow = 'Upgrade Now';
  static const String continueFree = 'Continue with Free';
  static const String subscribeNow = 'Subscribe';
  static const String activateDemoPlan = 'Activate Demo Plan';
  static const String demoPlanActivated =
      'Demo plan activated — no real charge';
  static const String noPurchasesRestored = 'No active purchases found.';
  static const String terms = 'Terms of Service';
  static const String privacy = 'Privacy Policy';
  static const String restore = 'Restore Purchases';
  static const String upgradeTooltip = 'View plans';
  static const String plansLoadError = 'Could not load plans.';
  static const String retry = 'Try Again';
  static const String planNotAvailable =
      'That plan is not available in this store.';

  // ── Entitlement gates ────────────────────────────────────────────
  static const String familyVaultUnlocksAlerts =
      'Family Vault lets you send safety alerts to your Trusted Circle.';
  static const String acousticProtectionActive =
      'Acoustic protection active. Transcript-backed conversation '
      'analysis unlocks with Sentinel Shield.';

  // ── Plan badges ──────────────────────────────────────────────────
  static const String planFree = 'FREE TIER';
  static const String planSentinel = 'SENTINEL ACTIVE';
  static const String planFamily = 'FAMILY VAULT ACTIVE';

  // ── Post-call verification flow ──────────────────────────────────
  static const String postCallEnded = 'Protection session ended';
  static const String postCallReview =
      'Review the evidence before taking further action.';
  static const String postCallPause = 'Pause.';
  static const String postCallVerifyCta = 'Verify independently';
  static const String callSavedNumberHint =
      'Call the person back using a number you already trust.';
  static const String whyFlaggedTitle = 'Why VoxGuard Flagged This Call';
  static const String verifyIdentityTitle = 'Verify Identity';
  static const String verifyIdentityBody =
      'Call the person back using a number you already trust — never '
      'the number that just called you.';
  static const String callTrustedContact = 'Call Trusted Contact';
  static const String sendDemoFamilyAlert = 'Send Demo Family Alert';
  static const String familyAlertSent = 'Demo alert broadcast to family';
  static const String familySafePhrase =
      'Tip: agree on a family safe phrase offline — ask the caller for it.';
  static const String viewIncidentReport = 'View Incident Report';
  static const String incidentLogged = 'High-risk call logged';

  // ── Analyze Recording step labels ────────────────────────────────
  static const String stepPickRecording = 'PICK A RECORDING';
  static const String stepPrivacyDepth = 'CHOOSE PRIVACY DEPTH';
  static const String stepAnalyze = 'ANALYZE';
  static const String stepResult = 'UNDERSTAND THE RESULT';

  // ── Family Shield receiver — human framing ───────────────────────
  static const String familyAlertFraming =
      'Someone you know is asking for a second set of eyes.';
  static const String yourJudgment = 'YOUR JUDGMENT';
  static const String humanResponseNote =
      'Your call is the verification — not the app. Marking safe or '
      'suspicious is a human response; it does not change the '
      'risk analysis.';
}
