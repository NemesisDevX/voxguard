/// Centralized user-facing strings for VoxGuard.
abstract final class AppStrings {
  AppStrings._();

  // ── Global ───────────────────────────────────────────────────────
  static const String appName = 'VoxGuard';

  // ── Home ─────────────────────────────────────────────────────────
  static const String shieldStatusReady = 'Shield Status: Ready & Monitoring';
  static const String shieldSubtitle = 'Real-time voice defense active';
  static const String quickActions = 'PROTECTION ACTIONS';

  static const String startSafeCall = 'Start SafeCall';
  static const String startSafeCallDesc =
      'In-app protected call with real-time stream threat interceptor.';

  static const String liveShield = 'Live Shield';
  static const String liveShieldDesc =
      'Ambient mic monitor for speakerphone & surrounding calls.';

  static const String analyzeRecording = 'Analyze Recording';
  static const String analyzeRecordingDesc =
      'Upload call audio or voice note for deep forensic scan.';

  static const String incidentLogTooltip = 'Incident log';

  // ── Bottom navigation ────────────────────────────────────────────
  static const String navShield = 'Shield';
  static const String navIncidents = 'Incidents';
  static const String navSettings = 'Settings';

  // ── SafeCall HUD ─────────────────────────────────────────────────
  static const String safeCallTitle = 'SafeCall';
  static const String safeCallActive = 'PROTECTED CALL ACTIVE';
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
  static const String bannerThreat = 'THREAT DETECTED';
  static const String bannerThreatDetail = 'High Risk — Impersonation Pattern Detected';

  static const String simulateScam = 'Simulate Scam';
  static const String stopSimulation = 'Stop Simulation';

  static const String liveTranscript = 'LIVE TRANSCRIPT';
  static const String transcriptEmpty =
      'Listening — transcription will appear here.';
  static const String speakerCaller = 'Caller';
  static const String speakerYou = 'You';

  // ── Paywall ──────────────────────────────────────────────────────
  static const String paywallTitle =
      'Upgrade Your Shield.\nProtect What Matters.';
  static const String paywallSubtitle =
      'Scam calls are evolving. Your defense should too.';
  static const String securityBadge = 'Bank-Grade Encryption · Cancel Anytime';
  static const String monthly = 'Monthly';
  static const String annual = 'Annual';
  static const String saveBadge = 'SAVE 35%';
  static const String mostPopular = 'MOST POPULAR';
  static const String trialBanner =
      '7-Day Free Trial included. No charge today.';
  static const String startTrial = 'Start 7-Day Free Trial';
  static const String upgradeNow = 'Upgrade Now';
  static const String continueFree = 'Continue with Free';
  static const String terms = 'Terms of Service';
  static const String privacy = 'Privacy Policy';
  static const String restore = 'Restore Purchases';
  static const String upgradeTooltip = 'Upgrade to Pro';
  static const String plansLoadError = 'Could not load plans.';
  static const String retry = 'Try Again';

  // ── Plan badges ──────────────────────────────────────────────────
  static const String planFree = 'FREE TIER';
  static const String planSentinel = 'SENTINEL ACTIVE';
  static const String planFamily = 'FAMILY VAULT ACTIVE';

  // ── Post-intercept upsell ────────────────────────────────────────
  static const String upsellTitle = 'Family Shield intercepted an attack';
  static const String upsellBody =
      'Upgrade to Family Vault to auto-alert relatives the moment a '
      'high-risk call is intercepted on any protected device.';
  static const String upsellCta = 'Upgrade to Family Vault';
  static const String upsellDismiss = 'Maybe later';

  // ── Placeholder tabs ─────────────────────────────────────────────
  static const String incidentsEmpty = 'No incidents recorded';
  static const String incidentsEmptyDesc =
      'Blocked threats and flagged calls will appear here.';
  static const String settingsPlaceholder = 'Settings';
  static const String settingsPlaceholderDesc =
      'Protection preferences, trusted contacts and alerts.';
}
