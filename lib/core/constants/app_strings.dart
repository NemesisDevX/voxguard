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

  // ── Placeholder tabs ─────────────────────────────────────────────
  static const String incidentsEmpty = 'No incidents recorded';
  static const String incidentsEmptyDesc =
      'Blocked threats and flagged calls will appear here.';
  static const String settingsPlaceholder = 'Settings';
  static const String settingsPlaceholderDesc =
      'Protection preferences, trusted contacts and alerts.';
}
