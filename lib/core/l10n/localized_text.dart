import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n.dart';

/// Presentation-layer localization for strings produced by frozen
/// domain services (fusion reasons, service results, source labels).
///
/// The engines keep emitting stable English messages — they are
/// persisted and protocol-relevant, so they are never rewritten.
/// Instead the UI translates *known* messages through this map;
/// anything unrecognized passes through unchanged so unexpected
/// server/domain text is still shown rather than swallowed.
extension LocalizedText on BuildContext {
  /// Localizes a service/domain message if it is a known string.
  String serviceMessage(String message) =>
      localizeServiceMessage(l10n, message);

  /// Localizes a fusion-engine / seeded threat reason.
  String threatReason(String reason) => localizeThreatReason(l10n, reason);

  /// Localizes audio-source / transcription-source / caller labels.
  String sourceLabel(String label) => localizeSourceLabel(l10n, label);

  /// Localizes an evidence-category label from the semantic engine.
  String evidenceLabel(String label) =>
      localizeEvidenceLabel(l10n, label);

  /// Runs a preference write and surfaces one localized retry message
  /// when the store reports failure — the UI never claims a setting
  /// persisted when it didn't. Successful writes are silent.
  void savePreference(Future<bool> write) {
    unawaited(write.then((ok) {
      if (!ok && mounted) {
        ScaffoldMessenger.of(this).showSnackBar(
          SnackBar(content: Text(l10n.prefSaveFailed)),
        );
      }
    }));
  }
}

/// Context-free variants for getters, services and other sites
/// without a `BuildContext` — pass the resolved `l10n`/`l10nGlobal`.
String localizeServiceMessage(AppLocalizations l10n, String message) {
  final mapped = _serviceMap[message];
  if (mapped != null) return mapped(l10n);
  // Parameterized family: "Demo alert broadcast to N family member(s)."
  final demo = RegExp(r'^Demo alert broadcast to (\d+) family member')
      .firstMatch(message);
  if (demo != null) {
    return l10n.msgDemoAlertBroadcast(int.parse(demo.group(1)!));
  }
  final accepted =
      RegExp(r'^Alert accepted for delivery to (\d+) family member')
          .firstMatch(message);
  if (accepted != null) {
    return l10n.msgAlertAccepted(int.parse(accepted.group(1)!));
  }
  final relay = RegExp(r'^Relay rejected the (alert|response) \((\d+)\)')
      .firstMatch(message);
  if (relay != null) {
    return l10n.msgRelayRejected(int.parse(relay.group(2)!));
  }
  final unavailable =
      RegExp(r'^Alert service unavailable \((\d+)\)').firstMatch(message);
  if (unavailable != null) {
    return l10n.msgServiceUnavailable(int.parse(unavailable.group(1)!));
  }
  final regError = RegExp(r'^Registration error(.*)').firstMatch(message);
  if (regError != null) {
    return l10n.familyStateError(regError.group(1)!);
  }
  return message;
}

/// Localizes a fusion-engine / seeded threat reason.
String localizeThreatReason(AppLocalizations l10n, String reason) {
  final mapped = _reasonMap[reason];
  if (mapped != null) return mapped(l10n);
  final imp =
      RegExp(r'^Identity impersonation claim: "(.*)"$').firstMatch(reason);
  if (imp != null) return l10n.reasonImpersonation(imp.group(1)!);
  return reason;
}

/// Localizes audio-source / transcription-source / caller labels.
String localizeSourceLabel(AppLocalizations l10n, String label) =>
    _sourceMap[label]?.call(l10n) ?? label;

/// Localizes an evidence-category label from the semantic engine.
String localizeEvidenceLabel(AppLocalizations l10n, String label) =>
    _evidenceMap[label]?.call(l10n) ?? label;

/// Localizes a persisted `ThreatRiskLevel` enum name for reports.
/// Unknown names pass through so future levels stay visible.
String localizeRiskLevel(AppLocalizations l10n, String levelName) =>
    _riskLevelMap[levelName]?.call(l10n) ?? levelName;

Map<String, String Function(AppLocalizations)> _riskLevelMap = {
  'safe': (l) => l.bandSafe,
  'suspicious': (l) => l.bandSuspicious,
  'highRisk': (l) => l.bandHigh,
};

Map<String, String Function(AppLocalizations)> _serviceMap = {
  'Family Shield is disabled.': (l) => l.msgFamilyShieldDisabled,
  'Family Vault lets you send safety alerts to your Trusted Circle.':
      (l) => l.familyVaultUnlocksAlerts,
  'Add someone to your Trusted Circle before sending a Family Shield alert.':
      (l) => l.msgNeedTrustedContact,
  'Network error — alert could not be sent.': (l) => l.msgNetworkAlert,
  'Network error — response could not be sent.':
      (l) => l.msgNetworkResponse,
  'Choose Safe or Still Suspicious before responding.':
      (l) => l.msgChooseResponse,
  'Response target is not a valid Family Shield ID.':
      (l) => l.msgInvalidTarget,
  'Demo — response simulated, nothing left this device.':
      (l) => l.msgDemoResponse,
  'Family update sent.': (l) => l.msgFamilyUpdateSent,
  'Trusted Circle is full (5 people). Remove someone first.':
      (l) => l.msgCircleFull,
  'That Family Shield ID is already in your Trusted Circle.':
      (l) => l.msgDuplicateContact,
  'Name is required.': (l) => l.msgNameRequired,
  'Phone number is too long.': (l) => l.msgPhoneTooLong,
  'Demo contacts are read-only': (l) => l.msgDemoReadOnly,
  'Push setup failed on this device.': (l) => l.msgPushSetupFailed,
  'Could not link your Family Shield ID.': (l) => l.msgPushLinkFailed,
  'Could not enable push alerts. Try again.': (l) => l.msgPushEnableFailed,
  'Push state could not be read.': (l) => l.msgPushStateFailed,
  'Microphone capture is not supported on this platform. Try Demo Mode instead.':
      (l) => l.msgMicUnsupported,
  'Microphone access is blocked. Enable it in system settings, or use Demo Mode.':
      (l) => l.msgMicBlocked,
  'Microphone permission was denied. Grant access to run Live Mic, or use Demo Mode.':
      (l) => l.msgMicDenied,
  'Microphone failed to start. Check the device and retry, or use Demo Mode.':
      (l) => l.msgMicFailed,
  'That file appears to be empty.': (l) => l.msgFileEmpty,
  'The recording decoded to no audio — nothing to analyze.':
      (l) => l.msgFileNoAudio,
  'Provider returned an empty transcript.': (l) => l.msgEmptyTranscript,
  'The transcription provider could not process the audio.':
      (l) => l.msgTranscriptionFailed,
  'Transcription timed out — the acoustic result is still available.':
      (l) => l.msgTranscriptionTimeout,
  'Subscriptions are not configured in this build.':
      (l) => l.msgSubsNotConfigured,
  'Subscriptions could not be initialized.': (l) => l.msgSubsInitFailed,
  'Plans could not be loaded from the store.': (l) => l.msgPlansLoadFailed,
  'That plan is not available in this store.': (l) => l.planNotAvailable,
  'The purchase could not be completed.': (l) => l.msgPurchaseFailed,
  'No connection — check your network and try again.':
      (l) => l.msgNoConnection,
  'The store is unavailable right now. Try again later.':
      (l) => l.msgStoreUnavailable,
  'Purchases are not allowed on this device or account.':
      (l) => l.msgPurchaseNotAllowed,
  'The payment is pending approval.': (l) => l.msgPurchasePending,
  'Purchases could not be restored right now.': (l) => l.msgRestoreFailed,
  'No paid plans are available in this store yet.': (l) => l.msgNoPaidPlans,
  'The purchase did not activate a plan yet — it may take a moment. Use Restore Purchases to check again.':
      (l) => l.msgPurchasePendingActivation,
  'Demo checkout failed — please try again.': (l) => l.msgDemoCheckoutFailed,
};

Map<String, String Function(AppLocalizations)> _reasonMap = {
  'Financial transfer demand detected': (l) => l.reasonFinancial,
  'Secrecy & isolation pressure': (l) => l.reasonSecrecy,
  'Urgency manipulation tactics': (l) => l.reasonUrgency,
  'Acoustic anomaly indicators elevated': (l) => l.reasonAcoustic,
  'Coordinated scam pattern — amplified': (l) => l.reasonCoordinated,
  'No significant threat indicators': (l) => l.reasonNone,
  'Continue monitoring': (l) => l.actionContinueMonitoring,
  'Advise caution — verify caller identity': (l) => l.actionAdviseCaution,
  'End call immediately and alert a trusted contact':
      (l) => l.actionEndCall,
  'End the call immediately': (l) => l.actionEndCallShort,
  'Do not share OTPs, PINs or banking details': (l) => l.actionNoCodes,
  'Verify the caller through an official channel':
      (l) => l.actionVerifyChannel,
  'Report the number to your carrier or authorities': (l) => l.actionReport,
  'Contact the relevant bank/carrier/authority if needed':
      (l) => l.actionContactAuthority,
  'Enable Family Shield alerts for relatives': (l) => l.actionEnableFamily,
  'Do not act on time-limited offers under pressure':
      (l) => l.actionNoTimeOffers,
  'Elevated acoustic anomalies — conversation-risk signals were not analyzed':
      (l) => l.elevatedAcousticSummary,
  'Do not send money or share OTPs/PINs based on this recording':
      (l) => l.familyTipNoMoney,
  'Verify the speaker through a number you already trust':
      (l) => l.actionVerifyChannel,
};

Map<String, String Function(AppLocalizations)> _sourceMap = {
  'Live Microphone': (l) => l.sourceLiveMic,
  'Live Microphone Session': (l) => l.sourceLiveMicSession,
  'Generated Demo Audio': (l) => l.sourceDemoAudio,
  'Local Demo Transcript': (l) => l.sourceDemoTranscript,
  'User-provided transcript': (l) => l.sourceUserTranscript,
  'Uploaded Recording': (l) => l.sourceUploadedRecording,
  'Recording': (l) => l.sourceRecording,
  'AssemblyAI Pre-recorded': (l) => l.sourceAssemblyAiPrerecorded,
  'AssemblyAI Streaming': (l) => l.sourceAssemblyAiStreaming,
  'None — acoustic analysis only': (l) => l.sourceNoneAcoustic,
  'Unknown Caller (+20 10 ••• ••42)': (l) => l.callerUnknown,
  'Suspicious Contact (+1 888 ••• 0112)': (l) => l.callerSuspicious,
};

Map<String, String Function(AppLocalizations)> _evidenceMap = {
  'Impersonation': (l) => l.evidenceImpersonation,
  'Money Request': (l) => l.evidenceMoney,
  'Urgency': (l) => l.evidenceUrgency,
  'Secrecy': (l) => l.evidenceSecrecy,
};
