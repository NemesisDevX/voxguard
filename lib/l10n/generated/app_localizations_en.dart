// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'VoxGuard';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionDone => 'Done';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSkip => 'Skip for now';

  @override
  String get actionSkipSetup => 'Skip';

  @override
  String get actionRetry => 'Try Again';

  @override
  String get actionBack => 'Back';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionView => 'View';

  @override
  String get actionOpenSystemSettings => 'Open System Settings';

  @override
  String get actionCopyId => 'Copy ID';

  @override
  String get actionAddPerson => 'Add person';

  @override
  String get howItWorksTitle => 'How VoxGuard Works';

  @override
  String get exploreApp => 'Explore VoxGuard';

  @override
  String get unrecognizedIdentity => 'An unrecognized VoxGuard identity';

  @override
  String get safecallIntro =>
      'VoxGuard listens through your microphone for suspicious voice and conversation patterns.';

  @override
  String get familyAlertUnknownSender =>
      'Family Shield alert from an unrecognized VoxGuard identity.';

  @override
  String get pushAlertTitle => '🚨 VoxGuard Family Shield Alert';

  @override
  String get incidentReportTitle => 'VoxGuard Incident Report';

  @override
  String get recordingUnreadable =>
      'VoxGuard could not read this recording — it may be corrupted or an unsupported format.';

  @override
  String get recordingUndecodable =>
      'VoxGuard could not decode this recording — the format may not be supported on this device.';

  @override
  String get recordingAnalyzerIntro =>
      'VoxGuard examines acoustic anomalies and, when you choose transcription, conversation-risk signals.';

  @override
  String get partialRecordingNote =>
      'Conversation-risk signals were not analyzed, so VoxGuard cannot produce a complete Threat Score.';

  @override
  String get enhancedModeLockedDesc =>
      'Sentinel Shield adds enhanced transcription — the recording is sent through VoxGuard’s transcription relay only after you opt in. On-device analysis stays free.';

  @override
  String get enhancedModeReadyDesc =>
      'To create a transcript, this recording will be sent through VoxGuard’s transcription relay to the configured speech-to-text provider. VoxGuard does not permanently store the recording.';

  @override
  String get onboardingSignalsBody =>
      'During a SafeCall session you start yourself, VoxGuard listens for risk signals — never identity certainty — and explains what it heard in plain language.';

  @override
  String get onboardingNoInterception =>
      'VoxGuard does not intercept your phone\'s cellular calls — a protection session is always your choice.';

  @override
  String get onboardingFamilyBody =>
      'When a call feels wrong, people you trust can help you decide. Each VoxGuard installation receives an opaque Family Shield ID — trusted people save it in their own Trusted Circle to receive your private safety alerts and respond.';

  @override
  String get onboardingPrivacyMic =>
      'Microphone audio is processed in memory while a session runs — VoxGuard never stores an audio recording. Live Mic asks for microphone access only when you choose it; Demo Mode works without it.';

  @override
  String get onboardingPrivacyAlerts =>
      'Family Shield alerts carry only an opaque VoxGuard ID, an incident reference, and a risk band — never audio, transcripts, names, or phone numbers.';

  @override
  String get whyFlaggedTitle => 'Why VoxGuard Flagged This Call';

  @override
  String get whyElevatedAcousticTitle =>
      'WHY VOXGUARD FOUND ELEVATED ACOUSTIC SIGNALS';

  @override
  String get whyFlaggedRecordingTitle => 'WHY VOXGUARD FLAGGED THIS RECORDING';

  @override
  String get whyFlaggedCallTitle => 'WHY VOXGUARD FLAGGED THIS CALL';

  @override
  String get whyFlaggedItTitle => 'WHY VOXGUARD FLAGGED IT';

  @override
  String get welcomeTitle => 'A calmer way to answer.';

  @override
  String get welcomeSubtitle =>
      'VoxGuard helps you pause, verify, and stay in control when a call feels wrong.';

  @override
  String get welcomeLanguageLabel => 'CHOOSE YOUR LANGUAGE';

  @override
  String get welcomeLanguageSystem => 'Follow device language';

  @override
  String get welcomeNamePrompt => 'What should we call you?';

  @override
  String get welcomeNameHint => 'First name or nickname';

  @override
  String get welcomeNameNote => 'Optional — stored only on this device.';

  @override
  String get welcomeContinue => 'Continue';

  @override
  String get onboardingVoiceTitle =>
      'A familiar voice can still be misleading.';

  @override
  String get onboardingVoiceBody1 =>
      'Scammers clone voices, spoof numbers, and pressure the people you love. Hearing a familiar voice is not proof of who is speaking.';

  @override
  String get onboardingVoiceBody2 =>
      'Urgency, secrecy, and payment pressure are the real tells — not the voice itself.';

  @override
  String get onboardingVoiceBody3 =>
      'Caller ID and sound alone can never prove identity.';

  @override
  String get onboardingSignalsTitle => 'Two signals. One human decision.';

  @override
  String get onboardingSignalSemantic =>
      'Conversation signal — urgency, payment demands, secrecy pressure in what is being said.';

  @override
  String get onboardingSignalAcoustic =>
      'Voice-acoustic signal — anomaly indicators; an assistive heuristic, not a forensic verdict.';

  @override
  String get onboardingSignalScore =>
      'The Risk Signal score is a signal, not the probability that a call is fake.';

  @override
  String get onboardingVerifyTitle =>
      'When something feels wrong, verify independently.';

  @override
  String get onboardingVerifyBody =>
      'A risk signal is a reason to pause — not a verdict. The strongest move is always yours:';

  @override
  String get onboardingVerifyStep1 =>
      'Pause — never send money, codes, or details under pressure.';

  @override
  String get onboardingVerifyStep2 =>
      'Call the person back on a number you already trust — never one the caller gave you.';

  @override
  String get onboardingVerifyStep3 =>
      'Agree on a family safe phrase offline — ask for it when a call feels wrong.';

  @override
  String get onboardingFamilyTitle => 'Family Shield: a second set of eyes.';

  @override
  String get onboardingFamilyBody1 =>
      'Names and trusted phone numbers stay on the device that saved them.';

  @override
  String get onboardingFamilyBody2 =>
      'Setting up your Trusted Circle is optional — you can do it later in Settings.';

  @override
  String get onboardingFamilyIdPending =>
      'Your Family Shield ID appears here once the app finishes setting up.';

  @override
  String onboardingYourId(String id) {
    return 'Your ID: $id';
  }

  @override
  String get familyShieldIdCopied => 'Family Shield ID copied';

  @override
  String get familyAlertsEnabled => 'Family alerts enabled';

  @override
  String get onboardingNotifOff =>
      'Notifications are off — you can enable them later from your device\'s Settings app.';

  @override
  String get onboardingPushUnsupported =>
      'Push alerts aren\'t supported on this platform.';

  @override
  String get onboardingPushNotConfigured =>
      'Push alerts aren\'t configured in this build.';

  @override
  String get onboardingEnablingNotif => 'Enabling notifications…';

  @override
  String get onboardingEnableAlerts => 'Enable Family Alerts';

  @override
  String get onboardingPrivacyTitle => 'Your voice stays in your control.';

  @override
  String get onboardingPrivacyBody =>
      'When cloud transcription is configured, live audio streams to the configured transcription provider to produce transcript text for analysis.';

  @override
  String get onboardingPrivacyLoop =>
      'Evidence → Pause → Verify → People you trust';

  @override
  String get onboardingPrivacyChoice =>
      'Start a SafeCall session when you want protection — you always choose Live Mic or Demo Mode yourself.';

  @override
  String get startupStoreError =>
      'Couldn\'t save your progress — onboarding will show again next launch.';

  @override
  String get shieldStatusReady => 'VoxGuard Ready';

  @override
  String get shieldSubtitle => 'Real-time voice defense standing by';

  @override
  String homeGreetingNamed(String name) {
    return 'Good to see you, $name.';
  }

  @override
  String get quickActions => 'PROTECTION';

  @override
  String get startSafeCall => 'Start SafeCall';

  @override
  String get startSafeCallDesc =>
      'In-app protected call with live threat telemetry.';

  @override
  String get protectionCheckTitle => 'Start a protection check';

  @override
  String get protectionCheckDesc =>
      'Use speakerphone or play suspicious audio nearby — VoxGuard listens for risk signals.';

  @override
  String get protectionCheckCta => 'Start SafeCall';

  @override
  String get analyzeRecording => 'Analyze Recording';

  @override
  String get analyzeRecordingDesc =>
      'Check a saved call recording or voice note.';

  @override
  String get incidentLogTooltip => 'Incident log';

  @override
  String get familyShieldTitle => 'Family Shield';

  @override
  String get familyReadyWithCircle => 'Trusted Circle ready';

  @override
  String get familyNeedsSetup => 'Needs setup';

  @override
  String get familyStatusHint =>
      'A second set of eyes when a call feels wrong.';

  @override
  String get navShield => 'Protect';

  @override
  String get navIncidents => 'Incidents';

  @override
  String get navSettings => 'Settings';

  @override
  String get safeCallTitle => 'SafeCall';

  @override
  String get safeCallActive => 'PROTECTION SESSION ACTIVE';

  @override
  String get unknownCaller => 'Unknown Caller';

  @override
  String get maskedNumber => '+1 (•••) ••• ••42';

  @override
  String get endCall => 'End';

  @override
  String get endCallAndVerify => 'End call & verify';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get signalSynthetic => 'Acoustic Anomaly Indicators';

  @override
  String get signalUrgency => 'Urgent Pressure';

  @override
  String get signalFinancial => 'Financial Transfer Demand';

  @override
  String get signalSecrecy => 'Secrecy & Isolation Request';

  @override
  String get statusNormal => 'NORMAL';

  @override
  String get statusElevated => 'ELEVATED';

  @override
  String get bannerProtected => 'PROTECTED';

  @override
  String get bannerProtectedDetail =>
      'All signals nominal — no threat indicators';

  @override
  String get bannerElevated => 'ELEVATED RISK';

  @override
  String get bannerElevatedDetail => 'Suspicious pattern — monitoring closely';

  @override
  String get bannerThreat => 'High-Risk Call Detected';

  @override
  String get bannerThreatDetail =>
      'Impersonation and financial demand patterns flagged';

  @override
  String get threatScoreLabel => 'Threat Score';

  @override
  String get simulateScam => 'Simulate Scam';

  @override
  String get stopSimulation => 'Stop Demo';

  @override
  String get pauseHeadline => 'Pause before acting.';

  @override
  String get verifyBeforeYouAct => 'Verify before you act.';

  @override
  String get technicalDetails => 'TECHNICAL DETAILS';

  @override
  String get liveTranscript => 'LIVE TRANSCRIPT';

  @override
  String get transcriptEmpty =>
      'Transcript appears here during a protected call.';

  @override
  String get transcriptDemoPending => 'Demo transcript will appear here.';

  @override
  String get transcriptListening => 'Listening for speech…';

  @override
  String get transcriptNoLive =>
      'Voice analysis active — live transcription unavailable.';

  @override
  String get speakerCaller => 'Caller';

  @override
  String get speakerYou => 'You';

  @override
  String get safeCallPickerTitle => 'Start a Protection Session';

  @override
  String get modeLiveMic => 'Live Mic';

  @override
  String get modeLiveMicDesc =>
      'Analyze real microphone audio — speakerphone calls or a voice played nearby.';

  @override
  String get modeLiveMicBadge => 'REAL SESSION';

  @override
  String get modeDemo => 'Demo Attack';

  @override
  String get modeDemoDesc =>
      'Run the scripted judging scenario — generated audio and demo transcript. Nothing is real audio.';

  @override
  String get modeDemoBadge => 'DEMONSTRATION';

  @override
  String get modeLiveBadgeShort => 'LIVE MIC';

  @override
  String get modeDemoBadgeShort => 'DEMO';

  @override
  String get modeDemoModeLabel => 'DEMO MODE';

  @override
  String durationMinSec(int m, int ss) {
    return '$m:$ss';
  }

  @override
  String durationHourMinSec(int h, int mm, int ss) {
    return '$h:$mm:$ss';
  }

  @override
  String get lensBandSafe => 'SAFE';

  @override
  String get lensBandCaution => 'CAUTION';

  @override
  String get lensBandHigh => 'HIGH RISK';

  @override
  String get lensInterpSafe => 'Signals look normal — keep listening.';

  @override
  String get lensInterpCaution => 'Something feels off — watch the signals.';

  @override
  String get lensInterpHigh => 'Pause before acting.';

  @override
  String get lensRiskSignal => 'RISK SIGNAL';

  @override
  String lensA11yPartial(int acoustic) {
    return 'Partial signal — acoustic anomaly $acoustic of 100. Conversation analysis not run.';
  }

  @override
  String lensA11yFull(String band, int score, int acoustic) {
    return 'Risk signal $band, $score of 100. Acoustic analysis $acoustic of 100.';
  }

  @override
  String get lensDemoAudio => 'DEMO AUDIO';

  @override
  String get lensLayerConversation => 'Conversation';

  @override
  String get lensLayerVoice => 'Voice acoustics';

  @override
  String get lensNotAnalyzed => 'not analyzed';

  @override
  String get signalPartialState => 'ACOUSTIC ONLY';

  @override
  String get acousticAnomalyLabel => 'ACOUSTIC ANOMALY';

  @override
  String get conversationNotAnalyzed =>
      'Conversation-risk signals were not analyzed.';

  @override
  String get acousticOnlyMonitoring =>
      'Acoustic monitoring is active. Conversation analysis requires transcription.';

  @override
  String get bannerAcousticOnly =>
      'Acoustic monitoring only — conversation signals not analyzed';

  @override
  String get bannerAcousticElevated =>
      'Acoustic anomaly elevated — conversation signals not analyzed';

  @override
  String get acousticAnomalyElevatedNote =>
      'Elevated acoustic anomaly indicators observed.';

  @override
  String get postCallEnded => 'Protection session ended';

  @override
  String get postCallReview =>
      'Review the evidence before taking further action.';

  @override
  String get postCallPause => 'Pause.';

  @override
  String get postCallVerifyCta => 'Verify independently';

  @override
  String get callSavedNumberHint =>
      'Call the person back using a number you already trust.';

  @override
  String get verifyIdentityTitle => 'Verify Identity';

  @override
  String get verifyIdentityBody =>
      'Call the person back using a number you already trust — never the number that just called you.';

  @override
  String get callTrustedContact => 'Call Trusted Contact';

  @override
  String get sendDemoFamilyAlert => 'Send Demo Family Alert';

  @override
  String get familyAlertSent => 'Demo alert broadcast to family';

  @override
  String get familySafePhrase =>
      'Tip: agree on a family safe phrase offline — ask the caller for it.';

  @override
  String get viewIncidentReport => 'View Incident Report';

  @override
  String get incidentLogged => 'High-risk call logged';

  @override
  String get postCallNoFlags =>
      'No high-risk patterns were flagged during this call.';

  @override
  String get postCallSessionSummary => 'SESSION SUMMARY';

  @override
  String get postCallFamilyShield => 'FAMILY SHIELD';

  @override
  String get postCallFamilyDemoNote =>
      'Demo Mode — sends a simulated alert to demo contacts; no real notification is delivered.';

  @override
  String get postCallFamilyPrompt =>
      'Ask a person you trust for a second set of eyes — send them a Family Shield alert.';

  @override
  String get postCallSendFamilyAlert => 'Send Family Alert';

  @override
  String get postCallSendFamilyAlertDesc =>
      'Send a Family Shield alert to people in your Trusted Circle';

  @override
  String get verifyStepCall => 'Call the person on a saved, trusted number.';

  @override
  String get verifyStepPhrase => 'Ask for your family safe phrase if unsure.';

  @override
  String sheetScoreSummary(String headline, int score) {
    return '$headline Threat Score: $score/100.';
  }

  @override
  String get incidentsTitle => 'Incidents';

  @override
  String get incidentEmptyTitle => 'No incidents recorded';

  @override
  String get incidentEmptyBody =>
      'Flagged sessions and analyzed recordings will appear here as a safety log.';

  @override
  String get bandPartial => 'PARTIAL ANALYSIS';

  @override
  String get bandHigh => 'HIGH RISK';

  @override
  String get bandCritical => 'CRITICAL / HIGH RISK';

  @override
  String get bandSuspicious => 'SUSPICIOUS';

  @override
  String get bandSafe => 'SAFE';

  @override
  String incidentPartialSummary(int score) {
    return 'Acoustic anomaly $score/100 — conversation-risk not analyzed';
  }

  @override
  String get incidentNoThreats => 'No significant threats detected';

  @override
  String incidentReasonsDetected(int count) {
    return '$count detected';
  }

  @override
  String get incidentDeleteTitle => 'Delete this incident?';

  @override
  String incidentDeleteBody(String id) {
    return '$id will be permanently removed from this device. This cannot be undone.';
  }

  @override
  String get incidentDeleteTooltip => 'Delete incident';

  @override
  String get incidentDeleteFailed =>
      'Couldn\'t delete this incident. Please try again.';

  @override
  String get incidentCopied => 'Incident report copied to clipboard.';

  @override
  String get incidentFamilyResponses => 'FAMILY SHIELD RESPONSES';

  @override
  String familyMarkedSafe(String name) {
    return '$name marked this situation safe';
  }

  @override
  String familyStillConcerned(String name) {
    return '$name is still concerned';
  }

  @override
  String get incidentRecommended => 'RECOMMENDED NEXT STEPS';

  @override
  String get incidentTechnicalEvidence => 'TECHNICAL EVIDENCE';

  @override
  String get incidentAudioSha => 'AUDIO SHA-256';

  @override
  String get incidentAcousticSignals => 'ACOUSTIC ANOMALY SIGNALS';

  @override
  String get metricSpectralFlux => 'Spectral Flux';

  @override
  String get metricSpectralRolloff => 'Spectral Rolloff';

  @override
  String get metricZeroCrossing => 'Zero-Crossing Rate';

  @override
  String get metricAcousticScore => 'Acoustic Anomaly Score';

  @override
  String get incidentSemanticSignals => 'SEMANTIC THREAT SIGNALS';

  @override
  String get semUrgency => 'URGENCY';

  @override
  String get semFinancial => 'FINANCIAL';

  @override
  String get semSecrecy => 'SECRECY';

  @override
  String get incidentTranscriptTimeline => 'TRANSCRIPT TIMELINE';

  @override
  String get incidentNoTranscript => 'No transcript captured.';

  @override
  String get incidentBroadcast => 'Broadcast to Family Shield';

  @override
  String get incidentBroadcastDemoNote =>
      'Demo Mode — no real notification is sent';

  @override
  String get incidentShare => 'Share Incident Report';

  @override
  String incidentScoreLine(int score) {
    return '$score/100';
  }

  @override
  String get acousticAnomalyPrefix => 'Acoustic anomaly ';

  @override
  String get analyzeRecordingTitle => 'Analyze Recording';

  @override
  String get recordingStepTitle => 'Analyze a call recording or voice note';

  @override
  String get recordingFormats =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — up to 25 MB or 15 minutes.';

  @override
  String get recordingChooseAudio => 'Choose audio';

  @override
  String get recordingPrivacyLabel => 'PRIVACY';

  @override
  String get recordingKeepLocal => 'Keep audio on this device';

  @override
  String get recordingKeepLocalDesc =>
      'Acoustic analysis runs locally. Nothing is uploaded.';

  @override
  String get recordingIncludeConversation => 'Include conversation analysis';

  @override
  String get recordingCloudNotConfigured =>
      'Cloud transcription isn’t configured in this build. Acoustic analysis is still available on-device.';

  @override
  String get recordingCancelAnalysis => 'Cancel analysis';

  @override
  String get recordingAnalyzeAction => 'Analyze recording';

  @override
  String get recordingChooseDifferent => 'Choose a different file';

  @override
  String get recordingViewIncident => 'View Incident Report';

  @override
  String get recordingAnalyzeAnother => 'Analyze another recording';

  @override
  String get recordingMetaFormat => 'Format';

  @override
  String get recordingMetaSize => 'Size';

  @override
  String get recordingMetaDuration => 'Duration';

  @override
  String get recordingSentinelBadge => 'SENTINEL';

  @override
  String get recordingManualTranscript => 'Add transcript text instead';

  @override
  String get recordingManualTranscriptLabel => 'USER-PROVIDED TRANSCRIPT';

  @override
  String get recordingManualTranscriptHint =>
      'Paste transcript text you already have — it stays on this device.';

  @override
  String get recordingStagePreparing => 'Preparing audio';

  @override
  String get recordingStageAcoustic => 'Analyzing acoustic signals';

  @override
  String get recordingStageUploading => 'Uploading for transcription';

  @override
  String get recordingStageTranscribing => 'Transcribing conversation';

  @override
  String get recordingStageEvaluating => 'Evaluating conversation risk';

  @override
  String get recordingStageBuilding => 'Building result';

  @override
  String get recordingThreatScore => 'Threat Score';

  @override
  String get recordingConvNotAnalyzed => 'CONVERSATION SIGNAL · NOT ANALYZED';

  @override
  String get recordingAcousticSignals => 'ACOUSTIC ANOMALY SIGNALS';

  @override
  String get recordingAcousticScore => 'Acoustic anomaly score';

  @override
  String get recordingMetricFlux => 'Spectral flux';

  @override
  String get recordingMetricRolloff => 'Spectral rolloff';

  @override
  String get recordingMetricZcr => 'Zero-crossing rate';

  @override
  String get recordingTranscriptLabel => 'RECORDING TRANSCRIPT';

  @override
  String get recordingVerifyTitle => 'VERIFY BEFORE YOU ACT';

  @override
  String get recordingVerifyBody =>
      'This is an acoustic-only check — the conversation itself was not analyzed. Never rely on a partial result to decide a recording is safe: verify the speaker through a channel you already trust.';

  @override
  String get stepPickRecording => 'PICK A RECORDING';

  @override
  String get stepPrivacyDepth => 'CHOOSE PRIVACY DEPTH';

  @override
  String get stepAnalyze => 'ANALYZE';

  @override
  String get stepResult => 'UNDERSTAND THE RESULT';

  @override
  String get familyAlertTitle => 'Family Shield Alert';

  @override
  String familyAlertAcoustic(String name) {
    return '$name asked you to verify an elevated acoustic warning from a recording.';
  }

  @override
  String familyAlertHighRisk(String name) {
    return '$name may be dealing with a high-risk call.';
  }

  @override
  String familyAlertSuspicious(String name) {
    return '$name received a suspicious-call warning from VoxGuard.';
  }

  @override
  String get familyMarkedSafeNote =>
      'Marked safe after independent verification.';

  @override
  String get familyStillSuspiciousNote =>
      'Still suspicious — keep verification going.';

  @override
  String familyUpdateFailed(String localCopy) {
    return '$localCopy Family update could not be sent — check your connection.';
  }

  @override
  String get familyBandAlert => 'ALERT';

  @override
  String get familyVerifyDirectly => 'Verify directly';

  @override
  String familyVerifyCall(String name) {
    return 'Call $name using the trusted number you saved — not a number provided by the suspicious caller.';
  }

  @override
  String get familyVerifyChannel =>
      'Verify through a channel you already trust. Do not act on instructions from the alert alone.';

  @override
  String familyCallAction(String name) {
    return 'Call $name';
  }

  @override
  String familyCallActionUnknown(String name) {
    return 'Call $name';
  }

  @override
  String get familyCallContact => 'Call contact';

  @override
  String get familyNoTrustedNumber =>
      'No trusted number saved. Contact them through a number you already trust.';

  @override
  String get familyMarkSafe => 'Mark Safe';

  @override
  String get familyStillSuspicious => 'Still Suspicious';

  @override
  String get familyTipNoMoney => 'Do not send money or gift codes.';

  @override
  String get familyTipNoCodes => 'Do not share OTP, PIN, or banking details.';

  @override
  String get familyTipChannel => 'Verify through another independent channel.';

  @override
  String get familyTipAuthorities =>
      'Contact their bank, carrier, or local authorities if needed.';

  @override
  String get familyDetailsTitle => 'Details';

  @override
  String familyDetailsBody(String incident, String time, String status) {
    return 'Incident $incident\nReceived $time\n$status';
  }

  @override
  String get familyStatusSafe => 'Safe after verification';

  @override
  String get familyStatusSuspicious => 'Still suspicious';

  @override
  String get familyStatusUnresolved => 'Unresolved';

  @override
  String get familyPrivacyNote =>
      'Privacy: only an opaque device identity and risk level were shared. No audio, transcript, names, or phone numbers are included in Family Shield alerts.';

  @override
  String get familyUpdateTitle => 'Family Shield Update';

  @override
  String familyUpdateMarkedSafe(String who) {
    return '$who marked this situation safe';
  }

  @override
  String familyUpdateConcerned(String who) {
    return '$who is still concerned';
  }

  @override
  String familyUpdateHumanNote(String incident) {
    return 'This is a human verification update — it does not change the AI risk assessment.\n\nIncident $incident';
  }

  @override
  String get familyAlertReceived => 'Family Shield alert received';

  @override
  String get familyAlertFraming =>
      'Someone you know is asking for a second set of eyes.';

  @override
  String get yourJudgment => 'YOUR JUDGMENT';

  @override
  String get humanResponseNote =>
      'Your call is the verification — not the app. Marking safe or suspicious is a human response; it does not change the risk analysis.';

  @override
  String get familyReceiverTitle => 'Family Shield Receiver';

  @override
  String get familyReceiverDesc =>
      'Get an alert when someone in your trusted circle encounters a high-risk call.';

  @override
  String get familyReceiverShareHint =>
      'Share this ID only with someone you want to receive Family Shield alerts from.';

  @override
  String get familyReceiverEnable => 'Enable Family Alerts';

  @override
  String get familyReceiverOpenSettings => 'Open system settings';

  @override
  String get familyReceiverNotConfigured =>
      'Push setup unavailable — ONESIGNAL_APP_ID not configured in this build.';

  @override
  String get familyReceiverDevRecipient => 'DEV · Test alert recipient';

  @override
  String get familyReceiverSetTest => 'Set test recipient';

  @override
  String get familyStateReady => 'Ready to receive alerts';

  @override
  String get familyStateRegistering => 'Registering…';

  @override
  String get familyStateNeedPermission => 'Notification permission needed';

  @override
  String get familyStateBlocked =>
      'Notifications blocked — enable in system settings';

  @override
  String get familyStateNotConfigured => 'Push not configured';

  @override
  String get familyStateUnsupported => 'Not supported on this platform';

  @override
  String familyStateError(String detail) {
    return 'Registration error$detail';
  }

  @override
  String get familyShieldIdLabel => 'Family Shield ID';

  @override
  String get familyShieldIdCopy => 'Copy Family Shield ID';

  @override
  String get familyShieldIdCopiedShort => 'Family Shield ID copied';

  @override
  String get trustedCircleTitle => 'Trusted Circle';

  @override
  String trustedCircleCount(int count, String max) {
    return '$count of $max';
  }

  @override
  String get trustedCircleDesc =>
      'The people you can ask for a second set of eyes. Alerts reach them by Family Shield ID — phone numbers stay on this device.';

  @override
  String get trustedNoPhone => ' · no phone';

  @override
  String get trustedPhoneStored => ' · phone stored';

  @override
  String get trustedPhoneNone => ' · no phone';

  @override
  String get trustedAddTitle => 'Add trusted person';

  @override
  String get trustedEditTitle => 'Edit person';

  @override
  String get trustedFindIdHint =>
      'They can find their Family Shield ID in their own app under Settings → Family Shield Receiver.';

  @override
  String get trustedNameField => 'Name';

  @override
  String get trustedShieldIdField => 'Family Shield ID';

  @override
  String get trustedPhoneField => 'Trusted phone number (optional)';

  @override
  String get paywallTitle => 'Two signals.\nOne human decision.';

  @override
  String get paywallSubtitle =>
      'VoxGuard flags risk — you verify. Paid plans extend what the two signals can see.';

  @override
  String get securityBadge => 'Billing handled by your app store';

  @override
  String get demoStoreBadge => 'DEMO STORE';

  @override
  String get demoStoreNotice =>
      'Simulated checkout — no real charge will occur.';

  @override
  String get storeUnavailableNotice =>
      'Subscriptions aren\'t configured in this build.';

  @override
  String get monthly => 'Monthly';

  @override
  String get annual => 'Annual';

  @override
  String get mostPopular => 'MOST POPULAR';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get continueFree => 'Continue with Free';

  @override
  String get subscribeNow => 'Subscribe';

  @override
  String get activateDemoPlan => 'Activate Demo Plan';

  @override
  String get demoPlanActivated => 'Demo plan activated — no real charge';

  @override
  String get noPurchasesRestored => 'No active purchases found.';

  @override
  String get terms => 'Terms of Service';

  @override
  String get privacy => 'Privacy Policy';

  @override
  String get restore => 'Restore Purchases';

  @override
  String get upgradeTooltip => 'View plans';

  @override
  String get plansLoadError => 'Could not load plans.';

  @override
  String get planNotAvailable => 'That plan is not available in this store.';

  @override
  String get prefSaveFailed =>
      'Couldn\'t save that setting — please try again.';

  @override
  String planActivated(String name) {
    return '$name activated — shield upgraded';
  }

  @override
  String get planFreeLabel => 'Free';

  @override
  String get planNotAvailableShort => 'Not available';

  @override
  String get planFreeBadge => 'FREE TIER';

  @override
  String get planSentinelBadge => 'SENTINEL ACTIVE';

  @override
  String get planFamilyBadge => 'FAMILY VAULT ACTIVE';

  @override
  String get tierQuickCheck => 'Quick Check';

  @override
  String get tierQuickCheckTag => 'Local safety tools';

  @override
  String get tierQuickCheckF1 => 'Live Mic acoustic anomaly monitoring';

  @override
  String get tierQuickCheckF2 => 'On-device recording analysis';

  @override
  String get tierQuickCheckF3 => 'Manual transcript check — analyzed locally';

  @override
  String get tierQuickCheckF4 => 'Local incident history';

  @override
  String get tierQuickCheckF5 => 'Receive & respond to Family Shield alerts';

  @override
  String get tierSentinel => 'Sentinel Shield';

  @override
  String get tierSentinelTag => 'Conversation-aware protection';

  @override
  String get tierSentinelF1 => 'Everything in Quick Check';

  @override
  String get tierSentinelF2 =>
      'Automatic Live Mic transcription & enhanced recording transcription — when infrastructure is configured';

  @override
  String get tierSentinelF3 => 'Transcript-backed conversation-risk analysis';

  @override
  String get tierSentinelF4 => 'Fused multi-signal threat scoring';

  @override
  String get tierFamily => 'Family Vault';

  @override
  String get tierFamilyTag => 'The human verification loop';

  @override
  String get tierFamilyF1 => 'Everything in Sentinel Shield';

  @override
  String get tierFamilyF2 => 'Send Family Shield alerts to your Trusted Circle';

  @override
  String get tierFamilyF3 => 'Up to 5 locally-saved Trusted Circle contacts';

  @override
  String get tierFamilyF4 => 'Safety responses loop back privately';

  @override
  String get familyVaultUnlocksAlerts =>
      'Family Vault lets you send safety alerts to your Trusted Circle.';

  @override
  String get acousticProtectionActive =>
      'Acoustic protection active. Transcript-backed conversation analysis unlocks with Sentinel Shield.';

  @override
  String currentPlan(String tier) {
    return 'Current plan: $tier';
  }

  @override
  String get currentPlanDemo => ' (demo)';

  @override
  String get viewPlans => 'View plans';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get purchasesRestored => 'Purchases restored.';

  @override
  String get purchasesRestoreFailed =>
      'Purchases could not be restored right now.';

  @override
  String get subscriptionSection => 'Subscription';

  @override
  String get demoStoreSection => 'DEMO STORE';

  @override
  String get billingMonthly => 'Monthly';

  @override
  String get billingAnnual => 'Annual';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'PROFILE';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsSectionSafety => 'SAFETY & FAMILY';

  @override
  String get settingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get settingsSectionSubscription => 'SUBSCRIPTION';

  @override
  String get settingsSectionAbout => 'ABOUT & PRIVACY';

  @override
  String get settingsDisplayName => 'Display name';

  @override
  String get settingsDisplayNameNone => 'Not set';

  @override
  String get settingsDisplayNameHint => 'What should we call you?';

  @override
  String get settingsDisplayNameNote =>
      'Stored only on this device — never shared.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEn => 'English';

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEs => 'Español';

  @override
  String get languageFr => 'Français';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsAccent => 'Accent';

  @override
  String get accentPeriwinkle => 'Periwinkle';

  @override
  String get accentSoftBlue => 'Soft Blue';

  @override
  String get accentSoftViolet => 'Soft Violet';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get textSizeSystem => 'System';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra Large';

  @override
  String get textSizeNote =>
      'Never smaller than your device’s accessibility setting.';

  @override
  String get settingsExperience => 'Experience';

  @override
  String get experienceStandard => 'Standard';

  @override
  String get experienceGuided => 'Guided';

  @override
  String get experienceGuidedDesc =>
      'Larger actions, clearer guidance, less technical detail up front.';

  @override
  String get settingsMotion => 'Motion';

  @override
  String get motionSystem => 'Follow system';

  @override
  String get motionReduced => 'Reduced';

  @override
  String get motionNote =>
      'Reduced motion pauses ambient animation. Risk changes always stay visible.';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get hapticsOn => 'On';

  @override
  String get hapticsOff => 'Off';

  @override
  String get settingsFamilyStatus => 'Family Shield alerts';

  @override
  String get settingsNotificationState => 'Notification permission';

  @override
  String get notifStateGranted => 'Allowed';

  @override
  String get notifStateDenied => 'Off — enable in device settings';

  @override
  String get notifStateUnknown => 'Not determined';

  @override
  String get settingsNotificationNote =>
      'Notification sound and delivery are controlled by your device notification settings.';

  @override
  String get settingsOpenNotifSettings => 'Open notification settings';

  @override
  String get settingsHowItWorks => 'How it works';

  @override
  String get settingsAnalysisLangs =>
      'Conversation-risk analysis currently supports English and Egyptian Arabic. The app interface language can be changed independently.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsLocalOnly =>
      'Your name, language, and appearance preferences stay on this device.';

  @override
  String get msgFamilyShieldDisabled => 'Family Shield is disabled.';

  @override
  String get msgNeedTrustedContact =>
      'Add someone to your Trusted Circle before sending a Family Shield alert.';

  @override
  String msgDemoAlertBroadcast(int count) {
    return 'Demo alert broadcast to $count family member(s).';
  }

  @override
  String msgAlertAccepted(int count) {
    return 'Alert accepted for delivery to $count family member(s).';
  }

  @override
  String msgRelayRejected(int code) {
    return 'Relay rejected the alert ($code).';
  }

  @override
  String msgServiceUnavailable(int code) {
    return 'Alert service unavailable ($code).';
  }

  @override
  String get msgNetworkAlert => 'Network error — alert could not be sent.';

  @override
  String get msgNetworkResponse =>
      'Network error — response could not be sent.';

  @override
  String get msgChooseResponse =>
      'Choose Safe or Still Suspicious before responding.';

  @override
  String get msgInvalidTarget =>
      'Response target is not a valid Family Shield ID.';

  @override
  String get msgDemoResponse =>
      'Demo — response simulated, nothing left this device.';

  @override
  String get msgFamilyUpdateSent => 'Family update sent.';

  @override
  String get msgCircleFull =>
      'Trusted Circle is full (5 people). Remove someone first.';

  @override
  String get msgDuplicateContact =>
      'That Family Shield ID is already in your Trusted Circle.';

  @override
  String get msgNameRequired => 'Name is required.';

  @override
  String get msgInvalidShieldId =>
      'Response target is not a valid Family Shield ID.';

  @override
  String get msgPhoneTooLong => 'Phone number is too long.';

  @override
  String get msgDemoReadOnly => 'Demo contacts are read-only';

  @override
  String get msgPushSetupFailed => 'Push setup failed on this device.';

  @override
  String get msgPushLinkFailed => 'Could not link your Family Shield ID.';

  @override
  String get msgPushEnableFailed => 'Could not enable push alerts. Try again.';

  @override
  String get msgPushStateFailed => 'Push state could not be read.';

  @override
  String get msgMicUnsupported =>
      'Microphone capture is not supported on this platform. Try Demo Mode instead.';

  @override
  String get msgMicBlocked =>
      'Microphone access is blocked. Enable it in system settings, or use Demo Mode.';

  @override
  String get msgMicDenied =>
      'Microphone permission was denied. Grant access to run Live Mic, or use Demo Mode.';

  @override
  String get msgMicFailed =>
      'Microphone failed to start. Check the device and retry, or use Demo Mode.';

  @override
  String get msgFileEmpty => 'That file appears to be empty.';

  @override
  String get msgFileTooLarge =>
      'That file is too large — recordings up to 25 MB are supported.';

  @override
  String get msgFileTooLong =>
      'That recording is too long — up to 15 minutes are supported.';

  @override
  String get msgFileNoAudio =>
      'The recording decoded to no audio — nothing to analyze.';

  @override
  String get msgEmptyTranscript => 'Provider returned an empty transcript.';

  @override
  String get msgTranscriptionFailed =>
      'The transcription provider could not process the audio.';

  @override
  String get msgTranscriptionTimeout =>
      'Transcription timed out — the acoustic result is still available.';

  @override
  String get msgCloudNotConfigured =>
      'Cloud transcription isn\'t configured in this build. Acoustic analysis is still available on-device.';

  @override
  String get msgEnhancedLocked =>
      'Enhanced recording transcription is included with Sentinel Shield. On-device acoustic analysis is still available.';

  @override
  String get msgSubsNotConfigured =>
      'Subscriptions are not configured in this build.';

  @override
  String get msgSubsInitFailed => 'Subscriptions could not be initialized.';

  @override
  String get msgPlansLoadFailed => 'Plans could not be loaded from the store.';

  @override
  String get msgPurchaseFailed => 'The purchase could not be completed.';

  @override
  String get msgNoConnection =>
      'No connection — check your network and try again.';

  @override
  String get msgStoreUnavailable =>
      'The store is unavailable right now. Try again later.';

  @override
  String get msgPurchaseNotAllowed =>
      'Purchases are not allowed on this device or account.';

  @override
  String get msgPurchasePending => 'The payment is pending approval.';

  @override
  String get msgRestoreFailed => 'Purchases could not be restored right now.';

  @override
  String get msgNoPaidPlans => 'No paid plans are available in this store yet.';

  @override
  String get msgPurchasePendingActivation =>
      'The purchase did not activate a plan yet — it may take a moment. Use Restore Purchases to check again.';

  @override
  String get msgDemoCheckoutFailed =>
      'Demo checkout failed — please try again.';

  @override
  String get msgTokenFailed => 'Could not prepare transcription — try again.';

  @override
  String get reasonFinancial => 'Financial transfer demand detected';

  @override
  String get reasonSecrecy => 'Secrecy & isolation pressure';

  @override
  String get reasonUrgency => 'Urgency manipulation tactics';

  @override
  String reasonImpersonation(String claim) {
    return 'Identity impersonation claim: “$claim”';
  }

  @override
  String get reasonAcoustic => 'Acoustic anomaly indicators elevated';

  @override
  String get reasonCoordinated => 'Coordinated scam pattern — amplified';

  @override
  String get reasonNone => 'No significant threat indicators';

  @override
  String get actionContinueMonitoring => 'Continue monitoring';

  @override
  String get actionAdviseCaution => 'Advise caution — verify caller identity';

  @override
  String get actionEndCall =>
      'End call immediately and alert a trusted contact';

  @override
  String get actionEndCallShort => 'End the call immediately';

  @override
  String get actionNoCodes => 'Do not share OTPs, PINs or banking details';

  @override
  String get actionVerifyChannel =>
      'Verify the caller through an official channel';

  @override
  String get actionReport => 'Report the number to your carrier or authorities';

  @override
  String get actionEnableFamily => 'Enable Family Shield alerts for relatives';

  @override
  String get actionNoTimeOffers =>
      'Do not act on time-limited offers under pressure';

  @override
  String get evidenceImpersonation => 'Impersonation';

  @override
  String get evidenceMoney => 'Money Request';

  @override
  String get evidenceUrgency => 'Urgency';

  @override
  String get evidenceSecrecy => 'Secrecy';

  @override
  String get sourceLiveMic => 'Live Microphone';

  @override
  String get sourceLiveMicSession => 'Live Microphone Session';

  @override
  String get sourceDemoAudio => 'Generated Demo Audio';

  @override
  String get sourceDemoTranscript => 'Local Demo Transcript';

  @override
  String get sourceUserTranscript => 'User-provided transcript';

  @override
  String get sourceUploadedRecording => 'Uploaded Recording';

  @override
  String get sourceRecording => 'Recording';

  @override
  String get sourceAssemblyAiPrerecorded => 'AssemblyAI Pre-recorded';

  @override
  String get sourceAssemblyAiStreaming => 'AssemblyAI Streaming';

  @override
  String get sourceNoneAcoustic => 'None — acoustic analysis only';

  @override
  String get callerUnknown => 'Unknown Caller (+20 10 ••• ••42)';

  @override
  String get callerSuspicious => 'Suspicious Contact (+1 888 ••• 0112)';

  @override
  String get reportDisclaimer =>
      'AI-generated forensic telemetry. Not a legal or judicial determination.';

  @override
  String get reportAnalysisPartial =>
      'Analysis: Partial — acoustic signals only';

  @override
  String reportAcousticScore(int score) {
    return 'Acoustic anomaly score: $score/100';
  }

  @override
  String get reportConvNotAnalyzed =>
      'Conversation-risk signals were not analyzed.';

  @override
  String reportRiskLine(String risk, int score) {
    return 'Risk: $risk — Threat Score: $score/100';
  }

  @override
  String reportIdLine(String id) {
    return 'ID: $id';
  }

  @override
  String reportTimeLine(String time) {
    return 'Time: $time';
  }

  @override
  String reportCallerLine(String caller) {
    return 'Caller: $caller';
  }

  @override
  String reportDurationLine(String duration) {
    return 'Duration: $duration';
  }

  @override
  String reportSignalsLine(String reasons) {
    return 'Signals: $reasons';
  }

  @override
  String reportAudioSourceLine(String source) {
    return 'Audio source: $source';
  }

  @override
  String reportTranscriptionLine(String source) {
    return 'Transcription: $source';
  }

  @override
  String reportShaLine(String sha) {
    return 'Audio SHA-256: $sha';
  }

  @override
  String get elevatedAcousticSummary =>
      'Elevated acoustic anomalies — conversation-risk signals were not analyzed';

  @override
  String get demoTranscript1 =>
      'This is urgent — act now before the offer expires.';

  @override
  String get demoTranscript2 => 'Don\'t tell anyone until it\'s done.';

  @override
  String get metricAcousticAnomaly => 'Acoustic Anomaly Score';

  @override
  String get recordingFormatsHint =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — up to 25 MB or 15 minutes.';

  @override
  String get recordingAcousticScoreLabel => 'Acoustic anomaly score';

  @override
  String get recordingVerifyNormalBody =>
      'A score is a risk signal, not proof. Verify the speaker through a number you already trust — never one provided in the recording — before acting on any request.';

  @override
  String familyVerifyKnownSender(String name) {
    return 'Call $name using the trusted number you saved — not a number provided by the suspicious caller.';
  }

  @override
  String get familyVerifyUnknownSender =>
      'Verify through a channel you already trust. Do not act on instructions from the alert alone.';

  @override
  String get familyResolutionSafe => 'Safe after verification';

  @override
  String get familyResolutionStillSuspicious => 'Still suspicious';

  @override
  String get familyResolutionUnresolved => 'Unresolved';

  @override
  String familyResolutionLabel(String status) {
    return 'Resolution: $status';
  }

  @override
  String get familyReceiverReady => 'Ready to receive alerts';

  @override
  String get familyReceiverShareNote =>
      'Share this ID only with someone you want to receive Family Shield alerts from.';

  @override
  String get familyShieldIdCopyTooltip => 'Copy Family Shield ID';

  @override
  String get msgFamilyDisabled => 'Family Shield is disabled.';

  @override
  String msgAlertDelivered(int count) {
    return 'Alert accepted for delivery to $count family member(s).';
  }

  @override
  String get msgFamilyIdInvalid =>
      'Family Shield ID must look like vg_ followed by 32 hex characters. Ask your family member to copy it from their app (Settings → Family Shield Receiver).';

  @override
  String get msgMicStartFailed =>
      'Microphone failed to start. Check the device and retry, or use Demo Mode.';

  @override
  String get scoreUrgency => 'URGENCY';

  @override
  String get scoreFinancial => 'FINANCIAL';

  @override
  String get scoreSecrecy => 'SECRECY';

  @override
  String get demoBadgeCompact => 'DEMO';

  @override
  String get postCallDemoAlertDesc =>
      'Demo Mode — sends a simulated alert to demo contacts; no real notification is delivered.';

  @override
  String get postCallAskTrustDesc =>
      'Ask a person you trust for a second set of eyes — send them a Family Shield alert.';

  @override
  String get recordingConversationAbsent =>
      'CONVERSATION SIGNAL · NOT ANALYZED';

  @override
  String msgDemoAlertDelivered(int count) {
    return 'Demo alert broadcast to $count family member(s).';
  }

  @override
  String msgResponseRejected(int code) {
    return 'Relay rejected the response ($code).';
  }

  @override
  String msgAlertUnavailable(int code) {
    return 'Alert service unavailable ($code).';
  }

  @override
  String get msgAlertNetworkError => 'Network error — alert could not be sent.';

  @override
  String get msgResponseNetworkError =>
      'Network error — response could not be sent.';

  @override
  String get msgResolutionRequired =>
      'Choose Safe or Still Suspicious before responding.';

  @override
  String get msgDemoResponseSent =>
      'Demo — response simulated, nothing left this device.';

  @override
  String get pushAlertBodyHigh =>
      'A high-risk call was flagged on a monitored device. Verify directly with your relative before any funds move.';

  @override
  String get pushAlertBodySuspicious =>
      'A suspicious-call warning was flagged on a monitored device. Verify directly with your relative before any funds move.';

  @override
  String get pushAlertBodyPartial =>
      'Elevated acoustic signals were flagged in a recording on a monitored device. Conversation-risk signals were not analyzed — verify directly with your relative.';

  @override
  String get familyReceiverTestDeviceHint => 'vg_… external id of test device';

  @override
  String get verifyStepHangup => 'Hang up — do not send money.';

  @override
  String familyUpdateIncidentId(String id) {
    return 'Incident $id';
  }

  @override
  String familyUpdateReceivedAt(String time) {
    return 'Received $time';
  }
}
