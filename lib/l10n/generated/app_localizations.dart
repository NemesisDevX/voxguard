import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal'**
  String get appName;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionContactAuthority.
  ///
  /// In en, this message translates to:
  /// **'Contact the relevant bank/carrier/authority if needed'**
  String get actionContactAuthority;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get actionSkip;

  /// No description provided for @actionSkipSetup.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkipSetup;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get actionRetry;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// No description provided for @actionOpenSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open System Settings'**
  String get actionOpenSystemSettings;

  /// No description provided for @actionCopyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get actionCopyId;

  /// No description provided for @actionAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get actionAddPerson;

  /// No description provided for @howItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How PauseSignal Works'**
  String get howItWorksTitle;

  /// No description provided for @exploreApp.
  ///
  /// In en, this message translates to:
  /// **'Explore PauseSignal'**
  String get exploreApp;

  /// No description provided for @unrecognizedIdentity.
  ///
  /// In en, this message translates to:
  /// **'An unrecognized PauseSignal identity'**
  String get unrecognizedIdentity;

  /// No description provided for @safecallIntro.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal listens through your microphone for suspicious voice and conversation patterns.'**
  String get safecallIntro;

  /// No description provided for @familyAlertUnknownSender.
  ///
  /// In en, this message translates to:
  /// **'Family Shield alert from an unrecognized PauseSignal identity.'**
  String get familyAlertUnknownSender;

  /// No description provided for @pushAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'🚨 PauseSignal Family Shield Alert'**
  String get pushAlertTitle;

  /// No description provided for @incidentReportTitle.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal Incident Report'**
  String get incidentReportTitle;

  /// No description provided for @recordingUnreadable.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal could not read this recording — it may be corrupted or an unsupported format.'**
  String get recordingUnreadable;

  /// No description provided for @recordingUndecodable.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal could not decode this recording — the format may not be supported on this device.'**
  String get recordingUndecodable;

  /// No description provided for @recordingAnalyzerIntro.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal examines acoustic anomalies and, when you choose transcription, conversation-risk signals.'**
  String get recordingAnalyzerIntro;

  /// No description provided for @partialRecordingNote.
  ///
  /// In en, this message translates to:
  /// **'Conversation-risk signals were not analyzed, so PauseSignal cannot produce a complete Threat Score.'**
  String get partialRecordingNote;

  /// No description provided for @enhancedModeLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Sentinel Shield adds enhanced transcription — the recording is sent through PauseSignal’s transcription relay only after you opt in. On-device analysis stays free.'**
  String get enhancedModeLockedDesc;

  /// No description provided for @enhancedModeReadyDesc.
  ///
  /// In en, this message translates to:
  /// **'To create a transcript, this recording will be sent through PauseSignal’s transcription relay to the configured speech-to-text provider. PauseSignal does not permanently store the recording.'**
  String get enhancedModeReadyDesc;

  /// No description provided for @onboardingSignalsBody.
  ///
  /// In en, this message translates to:
  /// **'During a SafeCall session you start yourself, PauseSignal listens for risk signals — never identity certainty — and explains what it heard in plain language.'**
  String get onboardingSignalsBody;

  /// No description provided for @onboardingNoInterception.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal does not intercept your phone\'s cellular calls — a protection session is always your choice.'**
  String get onboardingNoInterception;

  /// No description provided for @onboardingFamilyBody.
  ///
  /// In en, this message translates to:
  /// **'When a call feels wrong, people you trust can help you decide. Each PauseSignal installation receives an opaque Family Shield ID — trusted people save it in their own Trusted Circle to receive your private safety alerts and respond.'**
  String get onboardingFamilyBody;

  /// No description provided for @onboardingPrivacyMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone audio is processed in memory while a session runs — PauseSignal never stores an audio recording. Live Mic asks for microphone access only when you choose it; Demo Mode works without it.'**
  String get onboardingPrivacyMic;

  /// No description provided for @onboardingPrivacyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Family Shield alerts carry only an opaque PauseSignal ID, an incident reference, and a risk band — never audio, transcripts, names, or phone numbers.'**
  String get onboardingPrivacyAlerts;

  /// No description provided for @whyFlaggedTitle.
  ///
  /// In en, this message translates to:
  /// **'Why PauseSignal Flagged This Call'**
  String get whyFlaggedTitle;

  /// No description provided for @whyElevatedAcousticTitle.
  ///
  /// In en, this message translates to:
  /// **'WHY VOXGUARD FOUND ELEVATED ACOUSTIC SIGNALS'**
  String get whyElevatedAcousticTitle;

  /// No description provided for @whyFlaggedRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'WHY VOXGUARD FLAGGED THIS RECORDING'**
  String get whyFlaggedRecordingTitle;

  /// No description provided for @whyFlaggedCallTitle.
  ///
  /// In en, this message translates to:
  /// **'WHY VOXGUARD FLAGGED THIS CALL'**
  String get whyFlaggedCallTitle;

  /// No description provided for @whyFlaggedItTitle.
  ///
  /// In en, this message translates to:
  /// **'WHY VOXGUARD FLAGGED IT'**
  String get whyFlaggedItTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A calmer way to answer.'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal helps you pause, verify, and stay in control when a call feels wrong.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR LANGUAGE'**
  String get welcomeLanguageLabel;

  /// No description provided for @welcomeLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow device language'**
  String get welcomeLanguageSystem;

  /// No description provided for @welcomeNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get welcomeNamePrompt;

  /// No description provided for @welcomeNameHint.
  ///
  /// In en, this message translates to:
  /// **'First name or nickname'**
  String get welcomeNameHint;

  /// No description provided for @welcomeNameNote.
  ///
  /// In en, this message translates to:
  /// **'Optional — stored only on this device.'**
  String get welcomeNameNote;

  /// No description provided for @welcomeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get welcomeContinue;

  /// No description provided for @onboardingVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'A familiar voice can still be misleading.'**
  String get onboardingVoiceTitle;

  /// No description provided for @onboardingVoiceBody1.
  ///
  /// In en, this message translates to:
  /// **'Scammers clone voices, spoof numbers, and pressure the people you love. Hearing a familiar voice is not proof of who is speaking.'**
  String get onboardingVoiceBody1;

  /// No description provided for @onboardingVoiceBody2.
  ///
  /// In en, this message translates to:
  /// **'Urgency, secrecy, and payment pressure are the real tells — not the voice itself.'**
  String get onboardingVoiceBody2;

  /// No description provided for @onboardingVoiceBody3.
  ///
  /// In en, this message translates to:
  /// **'Caller ID and sound alone can never prove identity.'**
  String get onboardingVoiceBody3;

  /// No description provided for @onboardingSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Two signals. One human decision.'**
  String get onboardingSignalsTitle;

  /// No description provided for @onboardingSignalSemantic.
  ///
  /// In en, this message translates to:
  /// **'Conversation signal — urgency, payment demands, secrecy pressure in what is being said.'**
  String get onboardingSignalSemantic;

  /// No description provided for @onboardingSignalAcoustic.
  ///
  /// In en, this message translates to:
  /// **'Voice-acoustic signal — anomaly indicators; an assistive heuristic, not a forensic verdict.'**
  String get onboardingSignalAcoustic;

  /// No description provided for @onboardingSignalScore.
  ///
  /// In en, this message translates to:
  /// **'The Risk Signal score is a signal, not the probability that a call is fake.'**
  String get onboardingSignalScore;

  /// No description provided for @onboardingVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'When something feels wrong, verify independently.'**
  String get onboardingVerifyTitle;

  /// No description provided for @onboardingVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'A risk signal is a reason to pause — not a verdict. The strongest move is always yours:'**
  String get onboardingVerifyBody;

  /// No description provided for @onboardingVerifyStep1.
  ///
  /// In en, this message translates to:
  /// **'Pause — never send money, codes, or details under pressure.'**
  String get onboardingVerifyStep1;

  /// No description provided for @onboardingVerifyStep2.
  ///
  /// In en, this message translates to:
  /// **'Call the person back on a number you already trust — never one the caller gave you.'**
  String get onboardingVerifyStep2;

  /// No description provided for @onboardingVerifyStep3.
  ///
  /// In en, this message translates to:
  /// **'Agree on a family safe phrase offline — ask for it when a call feels wrong.'**
  String get onboardingVerifyStep3;

  /// No description provided for @onboardingFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Shield: a second set of eyes.'**
  String get onboardingFamilyTitle;

  /// No description provided for @onboardingFamilyBody1.
  ///
  /// In en, this message translates to:
  /// **'Names and trusted phone numbers stay on the device that saved them.'**
  String get onboardingFamilyBody1;

  /// No description provided for @onboardingFamilyBody2.
  ///
  /// In en, this message translates to:
  /// **'Setting up your Trusted Circle is optional — you can do it later in Settings.'**
  String get onboardingFamilyBody2;

  /// No description provided for @onboardingFamilyIdPending.
  ///
  /// In en, this message translates to:
  /// **'Your Family Shield ID appears here once the app finishes setting up.'**
  String get onboardingFamilyIdPending;

  /// No description provided for @onboardingYourId.
  ///
  /// In en, this message translates to:
  /// **'Your ID: {id}'**
  String onboardingYourId(String id);

  /// No description provided for @familyShieldIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Family Shield ID copied'**
  String get familyShieldIdCopied;

  /// No description provided for @familyAlertsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Family alerts enabled'**
  String get familyAlertsEnabled;

  /// No description provided for @onboardingNotifOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off — you can enable them later from your device\'s Settings app.'**
  String get onboardingNotifOff;

  /// No description provided for @onboardingPushUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Push alerts aren\'t supported on this platform.'**
  String get onboardingPushUnsupported;

  /// No description provided for @onboardingPushNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Push alerts aren\'t configured in this build.'**
  String get onboardingPushNotConfigured;

  /// No description provided for @onboardingEnablingNotif.
  ///
  /// In en, this message translates to:
  /// **'Enabling notifications…'**
  String get onboardingEnablingNotif;

  /// No description provided for @onboardingEnableAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable Family Alerts'**
  String get onboardingEnableAlerts;

  /// No description provided for @onboardingPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your voice stays in your control.'**
  String get onboardingPrivacyTitle;

  /// No description provided for @onboardingPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'When cloud transcription is configured, live audio streams to the configured transcription provider to produce transcript text for analysis.'**
  String get onboardingPrivacyBody;

  /// No description provided for @onboardingPrivacyLoop.
  ///
  /// In en, this message translates to:
  /// **'Evidence → Pause → Verify → People you trust'**
  String get onboardingPrivacyLoop;

  /// No description provided for @onboardingPrivacyChoice.
  ///
  /// In en, this message translates to:
  /// **'Start a SafeCall session when you want protection — you always choose Live Mic or Demo Mode yourself.'**
  String get onboardingPrivacyChoice;

  /// No description provided for @startupStoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your progress — onboarding will show again next launch.'**
  String get startupStoreError;

  /// No description provided for @shieldStatusReady.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal Ready'**
  String get shieldStatusReady;

  /// No description provided for @shieldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time voice defense standing by'**
  String get shieldSubtitle;

  /// No description provided for @homeGreetingNamed.
  ///
  /// In en, this message translates to:
  /// **'Good to see you, {name}.'**
  String homeGreetingNamed(String name);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'PROTECTION'**
  String get quickActions;

  /// No description provided for @startSafeCall.
  ///
  /// In en, this message translates to:
  /// **'Start SafeCall'**
  String get startSafeCall;

  /// No description provided for @startSafeCallDesc.
  ///
  /// In en, this message translates to:
  /// **'In-app protected call with live threat telemetry.'**
  String get startSafeCallDesc;

  /// No description provided for @protectionCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a protection check'**
  String get protectionCheckTitle;

  /// No description provided for @protectionCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Use speakerphone or play suspicious audio nearby — PauseSignal listens for risk signals.'**
  String get protectionCheckDesc;

  /// No description provided for @protectionCheckCta.
  ///
  /// In en, this message translates to:
  /// **'Start SafeCall'**
  String get protectionCheckCta;

  /// No description provided for @analyzeRecording.
  ///
  /// In en, this message translates to:
  /// **'Analyze Recording'**
  String get analyzeRecording;

  /// No description provided for @analyzeRecordingDesc.
  ///
  /// In en, this message translates to:
  /// **'Check a saved call recording or voice note.'**
  String get analyzeRecordingDesc;

  /// No description provided for @incidentLogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Incident log'**
  String get incidentLogTooltip;

  /// No description provided for @familyShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Shield'**
  String get familyShieldTitle;

  /// No description provided for @familyReadyWithCircle.
  ///
  /// In en, this message translates to:
  /// **'Trusted Circle ready'**
  String get familyReadyWithCircle;

  /// No description provided for @familyNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get familyNeedsSetup;

  /// No description provided for @familyStatusHint.
  ///
  /// In en, this message translates to:
  /// **'A second set of eyes when a call feels wrong.'**
  String get familyStatusHint;

  /// No description provided for @navShield.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get navShield;

  /// No description provided for @navIncidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get navIncidents;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @safeCallTitle.
  ///
  /// In en, this message translates to:
  /// **'SafeCall'**
  String get safeCallTitle;

  /// No description provided for @safeCallActive.
  ///
  /// In en, this message translates to:
  /// **'PROTECTION SESSION ACTIVE'**
  String get safeCallActive;

  /// No description provided for @unknownCaller.
  ///
  /// In en, this message translates to:
  /// **'Unknown Caller'**
  String get unknownCaller;

  /// No description provided for @maskedNumber.
  ///
  /// In en, this message translates to:
  /// **'+1 (•••) ••• ••42'**
  String get maskedNumber;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endCall;

  /// No description provided for @endCallAndVerify.
  ///
  /// In en, this message translates to:
  /// **'End call & verify'**
  String get endCallAndVerify;

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveBadge;

  /// No description provided for @signalSynthetic.
  ///
  /// In en, this message translates to:
  /// **'Acoustic Anomaly Indicators'**
  String get signalSynthetic;

  /// No description provided for @signalUrgency.
  ///
  /// In en, this message translates to:
  /// **'Urgent Pressure'**
  String get signalUrgency;

  /// No description provided for @signalFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial Transfer Demand'**
  String get signalFinancial;

  /// No description provided for @signalSecrecy.
  ///
  /// In en, this message translates to:
  /// **'Secrecy & Isolation Request'**
  String get signalSecrecy;

  /// No description provided for @statusNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get statusNormal;

  /// No description provided for @statusElevated.
  ///
  /// In en, this message translates to:
  /// **'ELEVATED'**
  String get statusElevated;

  /// No description provided for @bannerProtected.
  ///
  /// In en, this message translates to:
  /// **'PROTECTED'**
  String get bannerProtected;

  /// No description provided for @bannerProtectedDetail.
  ///
  /// In en, this message translates to:
  /// **'All signals nominal — no threat indicators'**
  String get bannerProtectedDetail;

  /// No description provided for @bannerElevated.
  ///
  /// In en, this message translates to:
  /// **'ELEVATED RISK'**
  String get bannerElevated;

  /// No description provided for @bannerElevatedDetail.
  ///
  /// In en, this message translates to:
  /// **'Suspicious pattern — monitoring closely'**
  String get bannerElevatedDetail;

  /// No description provided for @bannerThreat.
  ///
  /// In en, this message translates to:
  /// **'High-Risk Call Detected'**
  String get bannerThreat;

  /// No description provided for @bannerThreatDetail.
  ///
  /// In en, this message translates to:
  /// **'Impersonation and financial demand patterns flagged'**
  String get bannerThreatDetail;

  /// No description provided for @threatScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Threat Score'**
  String get threatScoreLabel;

  /// No description provided for @simulateScam.
  ///
  /// In en, this message translates to:
  /// **'Simulate Scam'**
  String get simulateScam;

  /// No description provided for @stopSimulation.
  ///
  /// In en, this message translates to:
  /// **'Stop Demo'**
  String get stopSimulation;

  /// No description provided for @pauseHeadline.
  ///
  /// In en, this message translates to:
  /// **'Pause before acting.'**
  String get pauseHeadline;

  /// No description provided for @verifyBeforeYouAct.
  ///
  /// In en, this message translates to:
  /// **'Verify before you act.'**
  String get verifyBeforeYouAct;

  /// No description provided for @technicalDetails.
  ///
  /// In en, this message translates to:
  /// **'TECHNICAL DETAILS'**
  String get technicalDetails;

  /// No description provided for @liveTranscript.
  ///
  /// In en, this message translates to:
  /// **'LIVE TRANSCRIPT'**
  String get liveTranscript;

  /// No description provided for @transcriptEmpty.
  ///
  /// In en, this message translates to:
  /// **'Transcript appears here during a protected call.'**
  String get transcriptEmpty;

  /// No description provided for @transcriptDemoPending.
  ///
  /// In en, this message translates to:
  /// **'Demo transcript will appear here.'**
  String get transcriptDemoPending;

  /// No description provided for @transcriptListening.
  ///
  /// In en, this message translates to:
  /// **'Listening for speech…'**
  String get transcriptListening;

  /// No description provided for @transcriptNoLive.
  ///
  /// In en, this message translates to:
  /// **'Voice analysis active — live transcription unavailable.'**
  String get transcriptNoLive;

  /// No description provided for @speakerCaller.
  ///
  /// In en, this message translates to:
  /// **'Caller'**
  String get speakerCaller;

  /// No description provided for @speakerYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get speakerYou;

  /// No description provided for @safeCallPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a Protection Session'**
  String get safeCallPickerTitle;

  /// No description provided for @modeLiveMic.
  ///
  /// In en, this message translates to:
  /// **'Live Mic'**
  String get modeLiveMic;

  /// No description provided for @modeLiveMicDesc.
  ///
  /// In en, this message translates to:
  /// **'Analyze real microphone audio — speakerphone calls or a voice played nearby.'**
  String get modeLiveMicDesc;

  /// No description provided for @modeLiveMicBadge.
  ///
  /// In en, this message translates to:
  /// **'REAL SESSION'**
  String get modeLiveMicBadge;

  /// No description provided for @modeDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo Attack'**
  String get modeDemo;

  /// No description provided for @modeDemoDesc.
  ///
  /// In en, this message translates to:
  /// **'Run the scripted judging scenario — generated audio and demo transcript. Nothing is real audio.'**
  String get modeDemoDesc;

  /// No description provided for @modeDemoBadge.
  ///
  /// In en, this message translates to:
  /// **'DEMONSTRATION'**
  String get modeDemoBadge;

  /// No description provided for @modeLiveBadgeShort.
  ///
  /// In en, this message translates to:
  /// **'LIVE MIC'**
  String get modeLiveBadgeShort;

  /// No description provided for @modeDemoBadgeShort.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get modeDemoBadgeShort;

  /// No description provided for @modeDemoModeLabel.
  ///
  /// In en, this message translates to:
  /// **'DEMO MODE'**
  String get modeDemoModeLabel;

  /// No description provided for @durationMinSec.
  ///
  /// In en, this message translates to:
  /// **'{m}:{ss}'**
  String durationMinSec(int m, int ss);

  /// No description provided for @durationHourMinSec.
  ///
  /// In en, this message translates to:
  /// **'{h}:{mm}:{ss}'**
  String durationHourMinSec(int h, int mm, int ss);

  /// No description provided for @lensBandSafe.
  ///
  /// In en, this message translates to:
  /// **'SAFE'**
  String get lensBandSafe;

  /// No description provided for @lensBandCaution.
  ///
  /// In en, this message translates to:
  /// **'CAUTION'**
  String get lensBandCaution;

  /// No description provided for @lensBandHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH RISK'**
  String get lensBandHigh;

  /// No description provided for @lensInterpSafe.
  ///
  /// In en, this message translates to:
  /// **'Signals look normal — keep listening.'**
  String get lensInterpSafe;

  /// No description provided for @lensInterpCaution.
  ///
  /// In en, this message translates to:
  /// **'Something feels off — watch the signals.'**
  String get lensInterpCaution;

  /// No description provided for @lensInterpHigh.
  ///
  /// In en, this message translates to:
  /// **'Pause before acting.'**
  String get lensInterpHigh;

  /// No description provided for @lensRiskSignal.
  ///
  /// In en, this message translates to:
  /// **'RISK SIGNAL'**
  String get lensRiskSignal;

  /// No description provided for @lensA11yPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial signal — acoustic anomaly {acoustic} of 100. Conversation analysis not run.'**
  String lensA11yPartial(int acoustic);

  /// No description provided for @lensA11yFull.
  ///
  /// In en, this message translates to:
  /// **'Risk signal {band}, {score} of 100. Acoustic analysis {acoustic} of 100.'**
  String lensA11yFull(String band, int score, int acoustic);

  /// No description provided for @lensDemoAudio.
  ///
  /// In en, this message translates to:
  /// **'DEMO AUDIO'**
  String get lensDemoAudio;

  /// No description provided for @lensLayerConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get lensLayerConversation;

  /// No description provided for @lensLayerVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice acoustics'**
  String get lensLayerVoice;

  /// No description provided for @lensNotAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'not analyzed'**
  String get lensNotAnalyzed;

  /// No description provided for @signalPartialState.
  ///
  /// In en, this message translates to:
  /// **'ACOUSTIC ONLY'**
  String get signalPartialState;

  /// No description provided for @acousticAnomalyLabel.
  ///
  /// In en, this message translates to:
  /// **'ACOUSTIC ANOMALY'**
  String get acousticAnomalyLabel;

  /// No description provided for @conversationNotAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Conversation-risk signals were not analyzed.'**
  String get conversationNotAnalyzed;

  /// No description provided for @acousticOnlyMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Acoustic monitoring is active. Conversation analysis requires transcription.'**
  String get acousticOnlyMonitoring;

  /// No description provided for @bannerAcousticOnly.
  ///
  /// In en, this message translates to:
  /// **'Acoustic monitoring only — conversation signals not analyzed'**
  String get bannerAcousticOnly;

  /// No description provided for @bannerAcousticElevated.
  ///
  /// In en, this message translates to:
  /// **'Acoustic anomaly elevated — conversation signals not analyzed'**
  String get bannerAcousticElevated;

  /// No description provided for @acousticAnomalyElevatedNote.
  ///
  /// In en, this message translates to:
  /// **'Elevated acoustic anomaly indicators observed.'**
  String get acousticAnomalyElevatedNote;

  /// No description provided for @postCallEnded.
  ///
  /// In en, this message translates to:
  /// **'Protection session ended'**
  String get postCallEnded;

  /// No description provided for @postCallReview.
  ///
  /// In en, this message translates to:
  /// **'Review the evidence before taking further action.'**
  String get postCallReview;

  /// No description provided for @postCallPause.
  ///
  /// In en, this message translates to:
  /// **'Pause.'**
  String get postCallPause;

  /// No description provided for @postCallVerifyCta.
  ///
  /// In en, this message translates to:
  /// **'Verify independently'**
  String get postCallVerifyCta;

  /// No description provided for @callSavedNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Call the person back using a number you already trust.'**
  String get callSavedNumberHint;

  /// No description provided for @verifyIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get verifyIdentityTitle;

  /// No description provided for @verifyIdentityBody.
  ///
  /// In en, this message translates to:
  /// **'Call the person back using a number you already trust — never the number that just called you.'**
  String get verifyIdentityBody;

  /// No description provided for @callTrustedContact.
  ///
  /// In en, this message translates to:
  /// **'Call Trusted Contact'**
  String get callTrustedContact;

  /// No description provided for @sendDemoFamilyAlert.
  ///
  /// In en, this message translates to:
  /// **'Send Demo Family Alert'**
  String get sendDemoFamilyAlert;

  /// No description provided for @familyAlertSent.
  ///
  /// In en, this message translates to:
  /// **'Demo alert broadcast to family'**
  String get familyAlertSent;

  /// No description provided for @familySafePhrase.
  ///
  /// In en, this message translates to:
  /// **'Tip: agree on a family safe phrase offline — ask the caller for it.'**
  String get familySafePhrase;

  /// No description provided for @viewIncidentReport.
  ///
  /// In en, this message translates to:
  /// **'View Incident Report'**
  String get viewIncidentReport;

  /// No description provided for @incidentLogged.
  ///
  /// In en, this message translates to:
  /// **'High-risk call logged'**
  String get incidentLogged;

  /// No description provided for @postCallNoFlags.
  ///
  /// In en, this message translates to:
  /// **'No high-risk patterns were flagged during this call.'**
  String get postCallNoFlags;

  /// No description provided for @postCallSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'SESSION SUMMARY'**
  String get postCallSessionSummary;

  /// No description provided for @postCallFamilyShield.
  ///
  /// In en, this message translates to:
  /// **'FAMILY SHIELD'**
  String get postCallFamilyShield;

  /// No description provided for @postCallFamilyDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode — sends a simulated alert to demo contacts; no real notification is delivered.'**
  String get postCallFamilyDemoNote;

  /// No description provided for @postCallFamilyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask a person you trust for a second set of eyes — send them a Family Shield alert.'**
  String get postCallFamilyPrompt;

  /// No description provided for @postCallSendFamilyAlert.
  ///
  /// In en, this message translates to:
  /// **'Send Family Alert'**
  String get postCallSendFamilyAlert;

  /// No description provided for @postCallSendFamilyAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Send a Family Shield alert to people in your Trusted Circle'**
  String get postCallSendFamilyAlertDesc;

  /// No description provided for @verifyStepCall.
  ///
  /// In en, this message translates to:
  /// **'Call the person on a saved, trusted number.'**
  String get verifyStepCall;

  /// No description provided for @verifyStepPhrase.
  ///
  /// In en, this message translates to:
  /// **'Ask for your family safe phrase if unsure.'**
  String get verifyStepPhrase;

  /// No description provided for @sheetScoreSummary.
  ///
  /// In en, this message translates to:
  /// **'{headline} Threat Score: {score}/100.'**
  String sheetScoreSummary(String headline, int score);

  /// No description provided for @incidentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get incidentsTitle;

  /// No description provided for @incidentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No incidents recorded'**
  String get incidentEmptyTitle;

  /// No description provided for @incidentEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Flagged sessions and analyzed recordings will appear here as a safety log.'**
  String get incidentEmptyBody;

  /// No description provided for @bandPartial.
  ///
  /// In en, this message translates to:
  /// **'PARTIAL ANALYSIS'**
  String get bandPartial;

  /// No description provided for @bandHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH RISK'**
  String get bandHigh;

  /// No description provided for @bandCritical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL / HIGH RISK'**
  String get bandCritical;

  /// No description provided for @bandSuspicious.
  ///
  /// In en, this message translates to:
  /// **'SUSPICIOUS'**
  String get bandSuspicious;

  /// No description provided for @bandSafe.
  ///
  /// In en, this message translates to:
  /// **'SAFE'**
  String get bandSafe;

  /// No description provided for @incidentPartialSummary.
  ///
  /// In en, this message translates to:
  /// **'Acoustic anomaly {score}/100 — conversation-risk not analyzed'**
  String incidentPartialSummary(int score);

  /// No description provided for @incidentNoThreats.
  ///
  /// In en, this message translates to:
  /// **'No significant threats detected'**
  String get incidentNoThreats;

  /// No description provided for @incidentReasonsDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} detected'**
  String incidentReasonsDetected(int count);

  /// No description provided for @incidentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this incident?'**
  String get incidentDeleteTitle;

  /// No description provided for @incidentDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{id} will be permanently removed from this device. This cannot be undone.'**
  String incidentDeleteBody(String id);

  /// No description provided for @incidentDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete incident'**
  String get incidentDeleteTooltip;

  /// No description provided for @incidentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete this incident. Please try again.'**
  String get incidentDeleteFailed;

  /// No description provided for @incidentCopied.
  ///
  /// In en, this message translates to:
  /// **'Incident report copied to clipboard.'**
  String get incidentCopied;

  /// No description provided for @incidentFamilyResponses.
  ///
  /// In en, this message translates to:
  /// **'FAMILY SHIELD RESPONSES'**
  String get incidentFamilyResponses;

  /// No description provided for @familyMarkedSafe.
  ///
  /// In en, this message translates to:
  /// **'{name} marked this situation safe'**
  String familyMarkedSafe(String name);

  /// No description provided for @familyStillConcerned.
  ///
  /// In en, this message translates to:
  /// **'{name} is still concerned'**
  String familyStillConcerned(String name);

  /// No description provided for @incidentRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED NEXT STEPS'**
  String get incidentRecommended;

  /// No description provided for @incidentTechnicalEvidence.
  ///
  /// In en, this message translates to:
  /// **'TECHNICAL EVIDENCE'**
  String get incidentTechnicalEvidence;

  /// No description provided for @incidentAudioSha.
  ///
  /// In en, this message translates to:
  /// **'AUDIO SHA-256'**
  String get incidentAudioSha;

  /// No description provided for @incidentAcousticSignals.
  ///
  /// In en, this message translates to:
  /// **'ACOUSTIC ANOMALY SIGNALS'**
  String get incidentAcousticSignals;

  /// No description provided for @metricSpectralFlux.
  ///
  /// In en, this message translates to:
  /// **'Spectral Flux'**
  String get metricSpectralFlux;

  /// No description provided for @metricSpectralRolloff.
  ///
  /// In en, this message translates to:
  /// **'Spectral Rolloff'**
  String get metricSpectralRolloff;

  /// No description provided for @metricZeroCrossing.
  ///
  /// In en, this message translates to:
  /// **'Zero-Crossing Rate'**
  String get metricZeroCrossing;

  /// No description provided for @metricAcousticScore.
  ///
  /// In en, this message translates to:
  /// **'Acoustic Anomaly Score'**
  String get metricAcousticScore;

  /// No description provided for @incidentSemanticSignals.
  ///
  /// In en, this message translates to:
  /// **'SEMANTIC THREAT SIGNALS'**
  String get incidentSemanticSignals;

  /// No description provided for @semUrgency.
  ///
  /// In en, this message translates to:
  /// **'URGENCY'**
  String get semUrgency;

  /// No description provided for @semFinancial.
  ///
  /// In en, this message translates to:
  /// **'FINANCIAL'**
  String get semFinancial;

  /// No description provided for @semSecrecy.
  ///
  /// In en, this message translates to:
  /// **'SECRECY'**
  String get semSecrecy;

  /// No description provided for @incidentTranscriptTimeline.
  ///
  /// In en, this message translates to:
  /// **'TRANSCRIPT TIMELINE'**
  String get incidentTranscriptTimeline;

  /// No description provided for @incidentNoTranscript.
  ///
  /// In en, this message translates to:
  /// **'No transcript captured.'**
  String get incidentNoTranscript;

  /// No description provided for @incidentBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast to Family Shield'**
  String get incidentBroadcast;

  /// No description provided for @incidentBroadcastDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode — no real notification is sent'**
  String get incidentBroadcastDemoNote;

  /// No description provided for @incidentShare.
  ///
  /// In en, this message translates to:
  /// **'Share Incident Report'**
  String get incidentShare;

  /// No description provided for @incidentScoreLine.
  ///
  /// In en, this message translates to:
  /// **'{score}/100'**
  String incidentScoreLine(int score);

  /// No description provided for @acousticAnomalyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Acoustic anomaly '**
  String get acousticAnomalyPrefix;

  /// No description provided for @analyzeRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze Recording'**
  String get analyzeRecordingTitle;

  /// No description provided for @recordingStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze a call recording or voice note'**
  String get recordingStepTitle;

  /// No description provided for @recordingFormats.
  ///
  /// In en, this message translates to:
  /// **'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — up to 25 MB or 15 minutes.'**
  String get recordingFormats;

  /// No description provided for @recordingChooseAudio.
  ///
  /// In en, this message translates to:
  /// **'Choose audio'**
  String get recordingChooseAudio;

  /// No description provided for @recordingPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get recordingPrivacyLabel;

  /// No description provided for @recordingKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep audio on this device'**
  String get recordingKeepLocal;

  /// No description provided for @recordingKeepLocalDesc.
  ///
  /// In en, this message translates to:
  /// **'Acoustic analysis runs locally. Nothing is uploaded.'**
  String get recordingKeepLocalDesc;

  /// No description provided for @recordingIncludeConversation.
  ///
  /// In en, this message translates to:
  /// **'Include conversation analysis'**
  String get recordingIncludeConversation;

  /// No description provided for @recordingCloudNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud transcription isn’t configured in this build. Acoustic analysis is still available on-device.'**
  String get recordingCloudNotConfigured;

  /// No description provided for @recordingCancelAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Cancel analysis'**
  String get recordingCancelAnalysis;

  /// No description provided for @recordingAnalyzeAction.
  ///
  /// In en, this message translates to:
  /// **'Analyze recording'**
  String get recordingAnalyzeAction;

  /// No description provided for @recordingChooseDifferent.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file'**
  String get recordingChooseDifferent;

  /// No description provided for @recordingViewIncident.
  ///
  /// In en, this message translates to:
  /// **'View Incident Report'**
  String get recordingViewIncident;

  /// No description provided for @recordingAnalyzeAnother.
  ///
  /// In en, this message translates to:
  /// **'Analyze another recording'**
  String get recordingAnalyzeAnother;

  /// No description provided for @recordingMetaFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get recordingMetaFormat;

  /// No description provided for @recordingMetaSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get recordingMetaSize;

  /// No description provided for @recordingMetaDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get recordingMetaDuration;

  /// No description provided for @recordingSentinelBadge.
  ///
  /// In en, this message translates to:
  /// **'SENTINEL'**
  String get recordingSentinelBadge;

  /// No description provided for @recordingManualTranscript.
  ///
  /// In en, this message translates to:
  /// **'Add transcript text instead'**
  String get recordingManualTranscript;

  /// No description provided for @recordingManualTranscriptLabel.
  ///
  /// In en, this message translates to:
  /// **'USER-PROVIDED TRANSCRIPT'**
  String get recordingManualTranscriptLabel;

  /// No description provided for @recordingManualTranscriptHint.
  ///
  /// In en, this message translates to:
  /// **'Paste transcript text you already have — it stays on this device.'**
  String get recordingManualTranscriptHint;

  /// No description provided for @recordingStagePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing audio'**
  String get recordingStagePreparing;

  /// No description provided for @recordingStageAcoustic.
  ///
  /// In en, this message translates to:
  /// **'Analyzing acoustic signals'**
  String get recordingStageAcoustic;

  /// No description provided for @recordingStageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading for transcription'**
  String get recordingStageUploading;

  /// No description provided for @recordingStageTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing conversation'**
  String get recordingStageTranscribing;

  /// No description provided for @recordingStageEvaluating.
  ///
  /// In en, this message translates to:
  /// **'Evaluating conversation risk'**
  String get recordingStageEvaluating;

  /// No description provided for @recordingStageBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building result'**
  String get recordingStageBuilding;

  /// No description provided for @recordingThreatScore.
  ///
  /// In en, this message translates to:
  /// **'Threat Score'**
  String get recordingThreatScore;

  /// No description provided for @recordingConvNotAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'CONVERSATION SIGNAL · NOT ANALYZED'**
  String get recordingConvNotAnalyzed;

  /// No description provided for @recordingAcousticSignals.
  ///
  /// In en, this message translates to:
  /// **'ACOUSTIC ANOMALY SIGNALS'**
  String get recordingAcousticSignals;

  /// No description provided for @recordingAcousticScore.
  ///
  /// In en, this message translates to:
  /// **'Acoustic anomaly score'**
  String get recordingAcousticScore;

  /// No description provided for @recordingMetricFlux.
  ///
  /// In en, this message translates to:
  /// **'Spectral flux'**
  String get recordingMetricFlux;

  /// No description provided for @recordingMetricRolloff.
  ///
  /// In en, this message translates to:
  /// **'Spectral rolloff'**
  String get recordingMetricRolloff;

  /// No description provided for @recordingMetricZcr.
  ///
  /// In en, this message translates to:
  /// **'Zero-crossing rate'**
  String get recordingMetricZcr;

  /// No description provided for @recordingTranscriptLabel.
  ///
  /// In en, this message translates to:
  /// **'RECORDING TRANSCRIPT'**
  String get recordingTranscriptLabel;

  /// No description provided for @recordingVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'VERIFY BEFORE YOU ACT'**
  String get recordingVerifyTitle;

  /// No description provided for @recordingVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'This is an acoustic-only check — the conversation itself was not analyzed. Never rely on a partial result to decide a recording is safe: verify the speaker through a channel you already trust.'**
  String get recordingVerifyBody;

  /// No description provided for @stepPickRecording.
  ///
  /// In en, this message translates to:
  /// **'PICK A RECORDING'**
  String get stepPickRecording;

  /// No description provided for @stepPrivacyDepth.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE PRIVACY DEPTH'**
  String get stepPrivacyDepth;

  /// No description provided for @stepAnalyze.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE'**
  String get stepAnalyze;

  /// No description provided for @stepResult.
  ///
  /// In en, this message translates to:
  /// **'UNDERSTAND THE RESULT'**
  String get stepResult;

  /// No description provided for @familyAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Shield Alert'**
  String get familyAlertTitle;

  /// No description provided for @familyAlertAcoustic.
  ///
  /// In en, this message translates to:
  /// **'{name} asked you to verify an elevated acoustic warning from a recording.'**
  String familyAlertAcoustic(String name);

  /// No description provided for @familyAlertHighRisk.
  ///
  /// In en, this message translates to:
  /// **'{name} may be dealing with a high-risk call.'**
  String familyAlertHighRisk(String name);

  /// No description provided for @familyAlertSuspicious.
  ///
  /// In en, this message translates to:
  /// **'{name} received a suspicious-call warning from PauseSignal.'**
  String familyAlertSuspicious(String name);

  /// No description provided for @familyMarkedSafeNote.
  ///
  /// In en, this message translates to:
  /// **'Marked safe after independent verification.'**
  String get familyMarkedSafeNote;

  /// No description provided for @familyStillSuspiciousNote.
  ///
  /// In en, this message translates to:
  /// **'Still suspicious — keep verification going.'**
  String get familyStillSuspiciousNote;

  /// No description provided for @familyUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'{localCopy} Family update could not be sent — check your connection.'**
  String familyUpdateFailed(String localCopy);

  /// No description provided for @familyBandAlert.
  ///
  /// In en, this message translates to:
  /// **'ALERT'**
  String get familyBandAlert;

  /// No description provided for @familyVerifyDirectly.
  ///
  /// In en, this message translates to:
  /// **'Verify directly'**
  String get familyVerifyDirectly;

  /// No description provided for @familyVerifyCall.
  ///
  /// In en, this message translates to:
  /// **'Call {name} using the trusted number you saved — not a number provided by the suspicious caller.'**
  String familyVerifyCall(String name);

  /// No description provided for @familyVerifyChannel.
  ///
  /// In en, this message translates to:
  /// **'Verify through a channel you already trust. Do not act on instructions from the alert alone.'**
  String get familyVerifyChannel;

  /// No description provided for @familyCallAction.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String familyCallAction(String name);

  /// No description provided for @familyCallActionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String familyCallActionUnknown(String name);

  /// No description provided for @familyCallContact.
  ///
  /// In en, this message translates to:
  /// **'Call contact'**
  String get familyCallContact;

  /// No description provided for @familyNoTrustedNumber.
  ///
  /// In en, this message translates to:
  /// **'No trusted number saved. Contact them through a number you already trust.'**
  String get familyNoTrustedNumber;

  /// No description provided for @familyMarkSafe.
  ///
  /// In en, this message translates to:
  /// **'Mark Safe'**
  String get familyMarkSafe;

  /// No description provided for @familyStillSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Still Suspicious'**
  String get familyStillSuspicious;

  /// No description provided for @familyTipNoMoney.
  ///
  /// In en, this message translates to:
  /// **'Do not send money or gift codes.'**
  String get familyTipNoMoney;

  /// No description provided for @familyTipNoCodes.
  ///
  /// In en, this message translates to:
  /// **'Do not share OTP, PIN, or banking details.'**
  String get familyTipNoCodes;

  /// No description provided for @familyTipChannel.
  ///
  /// In en, this message translates to:
  /// **'Verify through another independent channel.'**
  String get familyTipChannel;

  /// No description provided for @familyTipAuthorities.
  ///
  /// In en, this message translates to:
  /// **'Contact their bank, carrier, or local authorities if needed.'**
  String get familyTipAuthorities;

  /// No description provided for @familyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get familyDetailsTitle;

  /// No description provided for @familyDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Incident {incident}\nReceived {time}\n{status}'**
  String familyDetailsBody(String incident, String time, String status);

  /// No description provided for @familyStatusSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe after verification'**
  String get familyStatusSafe;

  /// No description provided for @familyStatusSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Still suspicious'**
  String get familyStatusSuspicious;

  /// No description provided for @familyStatusUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get familyStatusUnresolved;

  /// No description provided for @familyPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Privacy: only an opaque device identity and risk level were shared. No audio, transcript, names, or phone numbers are included in Family Shield alerts.'**
  String get familyPrivacyNote;

  /// No description provided for @familyUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Shield Update'**
  String get familyUpdateTitle;

  /// No description provided for @familyUpdateMarkedSafe.
  ///
  /// In en, this message translates to:
  /// **'{who} marked this situation safe'**
  String familyUpdateMarkedSafe(String who);

  /// No description provided for @familyUpdateConcerned.
  ///
  /// In en, this message translates to:
  /// **'{who} is still concerned'**
  String familyUpdateConcerned(String who);

  /// No description provided for @familyUpdateHumanNote.
  ///
  /// In en, this message translates to:
  /// **'This is a human verification update — it does not change the AI risk assessment.\n\nIncident {incident}'**
  String familyUpdateHumanNote(String incident);

  /// No description provided for @familyAlertReceived.
  ///
  /// In en, this message translates to:
  /// **'Family Shield alert received'**
  String get familyAlertReceived;

  /// No description provided for @familyAlertFraming.
  ///
  /// In en, this message translates to:
  /// **'Someone you know is asking for a second set of eyes.'**
  String get familyAlertFraming;

  /// No description provided for @yourJudgment.
  ///
  /// In en, this message translates to:
  /// **'YOUR JUDGMENT'**
  String get yourJudgment;

  /// No description provided for @humanResponseNote.
  ///
  /// In en, this message translates to:
  /// **'Your call is the verification — not the app. Marking safe or suspicious is a human response; it does not change the risk analysis.'**
  String get humanResponseNote;

  /// No description provided for @familyReceiverTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Shield Receiver'**
  String get familyReceiverTitle;

  /// No description provided for @familyReceiverDesc.
  ///
  /// In en, this message translates to:
  /// **'Get an alert when someone in your trusted circle encounters a high-risk call.'**
  String get familyReceiverDesc;

  /// No description provided for @familyReceiverShareHint.
  ///
  /// In en, this message translates to:
  /// **'Share this ID only with someone you want to receive Family Shield alerts from.'**
  String get familyReceiverShareHint;

  /// No description provided for @familyReceiverEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Family Alerts'**
  String get familyReceiverEnable;

  /// No description provided for @familyReceiverOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get familyReceiverOpenSettings;

  /// No description provided for @familyReceiverNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Push setup unavailable — ONESIGNAL_APP_ID not configured in this build.'**
  String get familyReceiverNotConfigured;

  /// No description provided for @familyReceiverDevRecipient.
  ///
  /// In en, this message translates to:
  /// **'DEV · Test alert recipient'**
  String get familyReceiverDevRecipient;

  /// No description provided for @familyReceiverSetTest.
  ///
  /// In en, this message translates to:
  /// **'Set test recipient'**
  String get familyReceiverSetTest;

  /// No description provided for @familyStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to receive alerts'**
  String get familyStateReady;

  /// No description provided for @familyStateRegistering.
  ///
  /// In en, this message translates to:
  /// **'Registering…'**
  String get familyStateRegistering;

  /// No description provided for @familyStateNeedPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification permission needed'**
  String get familyStateNeedPermission;

  /// No description provided for @familyStateBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications blocked — enable in system settings'**
  String get familyStateBlocked;

  /// No description provided for @familyStateNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Push not configured'**
  String get familyStateNotConfigured;

  /// No description provided for @familyStateUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this platform'**
  String get familyStateUnsupported;

  /// No description provided for @familyStateError.
  ///
  /// In en, this message translates to:
  /// **'Registration error{detail}'**
  String familyStateError(String detail);

  /// No description provided for @familyShieldIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Shield ID'**
  String get familyShieldIdLabel;

  /// No description provided for @familyShieldIdCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy Family Shield ID'**
  String get familyShieldIdCopy;

  /// No description provided for @familyShieldIdCopiedShort.
  ///
  /// In en, this message translates to:
  /// **'Family Shield ID copied'**
  String get familyShieldIdCopiedShort;

  /// No description provided for @trustedCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted Circle'**
  String get trustedCircleTitle;

  /// No description provided for @trustedCircleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max}'**
  String trustedCircleCount(int count, String max);

  /// No description provided for @trustedCircleDesc.
  ///
  /// In en, this message translates to:
  /// **'The people you can ask for a second set of eyes. Alerts reach them by Family Shield ID — phone numbers stay on this device.'**
  String get trustedCircleDesc;

  /// No description provided for @trustedNoPhone.
  ///
  /// In en, this message translates to:
  /// **' · no phone'**
  String get trustedNoPhone;

  /// No description provided for @trustedPhoneStored.
  ///
  /// In en, this message translates to:
  /// **' · phone stored'**
  String get trustedPhoneStored;

  /// No description provided for @trustedPhoneNone.
  ///
  /// In en, this message translates to:
  /// **' · no phone'**
  String get trustedPhoneNone;

  /// No description provided for @trustedAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add trusted person'**
  String get trustedAddTitle;

  /// No description provided for @trustedEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit person'**
  String get trustedEditTitle;

  /// No description provided for @trustedFindIdHint.
  ///
  /// In en, this message translates to:
  /// **'They can find their Family Shield ID in their own app under Settings → Family Shield Receiver.'**
  String get trustedFindIdHint;

  /// No description provided for @trustedNameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get trustedNameField;

  /// No description provided for @trustedShieldIdField.
  ///
  /// In en, this message translates to:
  /// **'Family Shield ID'**
  String get trustedShieldIdField;

  /// No description provided for @trustedPhoneField.
  ///
  /// In en, this message translates to:
  /// **'Trusted phone number (optional)'**
  String get trustedPhoneField;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Two signals.\nOne human decision.'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PauseSignal flags risk — you verify. Paid plans extend what the two signals can see.'**
  String get paywallSubtitle;

  /// No description provided for @securityBadge.
  ///
  /// In en, this message translates to:
  /// **'Billing handled by your app store'**
  String get securityBadge;

  /// No description provided for @demoStoreBadge.
  ///
  /// In en, this message translates to:
  /// **'DEMO STORE'**
  String get demoStoreBadge;

  /// No description provided for @demoStoreNotice.
  ///
  /// In en, this message translates to:
  /// **'Simulated checkout — no real charge will occur.'**
  String get demoStoreNotice;

  /// No description provided for @testStoreBadge.
  ///
  /// In en, this message translates to:
  /// **'REVENUECAT TEST STORE'**
  String get testStoreBadge;

  /// No description provided for @testStoreNotice.
  ///
  /// In en, this message translates to:
  /// **'Purchases run through RevenueCat\'s official Test Store — verified by RevenueCat, never a real-money charge.'**
  String get testStoreNotice;

  /// No description provided for @storeUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions aren\'t configured in this build.'**
  String get storeUnavailableNotice;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopular;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @continueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue with Free'**
  String get continueFree;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeNow;

  /// No description provided for @activateDemoPlan.
  ///
  /// In en, this message translates to:
  /// **'Activate Demo Plan'**
  String get activateDemoPlan;

  /// No description provided for @demoPlanActivated.
  ///
  /// In en, this message translates to:
  /// **'Demo plan activated — no real charge'**
  String get demoPlanActivated;

  /// No description provided for @noPurchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'No active purchases found.'**
  String get noPurchasesRestored;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restore;

  /// No description provided for @upgradeTooltip.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get upgradeTooltip;

  /// No description provided for @plansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load plans.'**
  String get plansLoadError;

  /// No description provided for @planNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'That plan is not available in this store.'**
  String get planNotAvailable;

  /// No description provided for @prefSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that setting — please try again.'**
  String get prefSaveFailed;

  /// No description provided for @planActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} activated — shield upgraded'**
  String planActivated(String name);

  /// No description provided for @planFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFreeLabel;

  /// No description provided for @planNotAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get planNotAvailableShort;

  /// No description provided for @planFreeBadge.
  ///
  /// In en, this message translates to:
  /// **'FREE TIER'**
  String get planFreeBadge;

  /// No description provided for @planSentinelBadge.
  ///
  /// In en, this message translates to:
  /// **'SENTINEL ACTIVE'**
  String get planSentinelBadge;

  /// No description provided for @planFamilyBadge.
  ///
  /// In en, this message translates to:
  /// **'FAMILY VAULT ACTIVE'**
  String get planFamilyBadge;

  /// No description provided for @tierQuickCheck.
  ///
  /// In en, this message translates to:
  /// **'Quick Check'**
  String get tierQuickCheck;

  /// No description provided for @tierQuickCheckTag.
  ///
  /// In en, this message translates to:
  /// **'Local safety tools'**
  String get tierQuickCheckTag;

  /// No description provided for @tierQuickCheckF1.
  ///
  /// In en, this message translates to:
  /// **'Live Mic acoustic anomaly monitoring'**
  String get tierQuickCheckF1;

  /// No description provided for @tierQuickCheckF2.
  ///
  /// In en, this message translates to:
  /// **'On-device recording analysis'**
  String get tierQuickCheckF2;

  /// No description provided for @tierQuickCheckF3.
  ///
  /// In en, this message translates to:
  /// **'Manual transcript check — analyzed locally'**
  String get tierQuickCheckF3;

  /// No description provided for @tierQuickCheckF4.
  ///
  /// In en, this message translates to:
  /// **'Local incident history'**
  String get tierQuickCheckF4;

  /// No description provided for @tierQuickCheckF5.
  ///
  /// In en, this message translates to:
  /// **'Receive & respond to Family Shield alerts'**
  String get tierQuickCheckF5;

  /// No description provided for @tierSentinel.
  ///
  /// In en, this message translates to:
  /// **'Sentinel Shield'**
  String get tierSentinel;

  /// No description provided for @tierSentinelTag.
  ///
  /// In en, this message translates to:
  /// **'Conversation-aware protection'**
  String get tierSentinelTag;

  /// No description provided for @tierSentinelF1.
  ///
  /// In en, this message translates to:
  /// **'Everything in Quick Check'**
  String get tierSentinelF1;

  /// No description provided for @tierSentinelF2.
  ///
  /// In en, this message translates to:
  /// **'Automatic Live Mic transcription & enhanced recording transcription — when infrastructure is configured'**
  String get tierSentinelF2;

  /// No description provided for @tierSentinelF3.
  ///
  /// In en, this message translates to:
  /// **'Transcript-backed conversation-risk analysis'**
  String get tierSentinelF3;

  /// No description provided for @tierSentinelF4.
  ///
  /// In en, this message translates to:
  /// **'Fused multi-signal threat scoring'**
  String get tierSentinelF4;

  /// No description provided for @tierFamily.
  ///
  /// In en, this message translates to:
  /// **'Family Vault'**
  String get tierFamily;

  /// No description provided for @tierFamilyTag.
  ///
  /// In en, this message translates to:
  /// **'The human verification loop'**
  String get tierFamilyTag;

  /// No description provided for @tierFamilyF1.
  ///
  /// In en, this message translates to:
  /// **'Everything in Sentinel Shield'**
  String get tierFamilyF1;

  /// No description provided for @tierFamilyF2.
  ///
  /// In en, this message translates to:
  /// **'Send Family Shield alerts to your Trusted Circle'**
  String get tierFamilyF2;

  /// No description provided for @tierFamilyF3.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 locally-saved Trusted Circle contacts'**
  String get tierFamilyF3;

  /// No description provided for @tierFamilyF4.
  ///
  /// In en, this message translates to:
  /// **'Safety responses loop back privately'**
  String get tierFamilyF4;

  /// No description provided for @familyVaultUnlocksAlerts.
  ///
  /// In en, this message translates to:
  /// **'Family Vault lets you send safety alerts to your Trusted Circle.'**
  String get familyVaultUnlocksAlerts;

  /// No description provided for @acousticProtectionActive.
  ///
  /// In en, this message translates to:
  /// **'Acoustic protection active. Transcript-backed conversation analysis unlocks with Sentinel Shield.'**
  String get acousticProtectionActive;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan: {tier}'**
  String currentPlan(String tier);

  /// No description provided for @currentPlanDemo.
  ///
  /// In en, this message translates to:
  /// **' (demo)'**
  String get currentPlanDemo;

  /// No description provided for @currentPlanTestStore.
  ///
  /// In en, this message translates to:
  /// **' (Test Store)'**
  String get currentPlanTestStore;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get viewPlans;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get purchasesRestored;

  /// No description provided for @purchasesRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchases could not be restored right now.'**
  String get purchasesRestoreFailed;

  /// No description provided for @subscriptionSection.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionSection;

  /// No description provided for @demoStoreSection.
  ///
  /// In en, this message translates to:
  /// **'DEMO STORE'**
  String get demoStoreSection;

  /// No description provided for @testStoreSection.
  ///
  /// In en, this message translates to:
  /// **'REVENUECAT TEST STORE'**
  String get testStoreSection;

  /// No description provided for @billingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingMonthly;

  /// No description provided for @billingAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get billingAnnual;

  /// No description provided for @priceSuffixMonthly.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get priceSuffixMonthly;

  /// No description provided for @priceSuffixAnnual.
  ///
  /// In en, this message translates to:
  /// **'/yr'**
  String get priceSuffixAnnual;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get settingsSectionProfile;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionSafety.
  ///
  /// In en, this message translates to:
  /// **'SAFETY & FAMILY'**
  String get settingsSectionSafety;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionSubscription.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIPTION'**
  String get settingsSectionSubscription;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT & PRIVACY'**
  String get settingsSectionAbout;

  /// No description provided for @settingsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get settingsDisplayName;

  /// No description provided for @settingsDisplayNameNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsDisplayNameNone;

  /// No description provided for @settingsDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get settingsDisplayNameHint;

  /// No description provided for @settingsDisplayNameNote.
  ///
  /// In en, this message translates to:
  /// **'Stored only on this device — never shared.'**
  String get settingsDisplayNameNote;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageAr.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageAr;

  /// No description provided for @languageEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageEs;

  /// No description provided for @languageFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFr;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get settingsAccent;

  /// No description provided for @accentPeriwinkle.
  ///
  /// In en, this message translates to:
  /// **'Periwinkle'**
  String get accentPeriwinkle;

  /// No description provided for @accentSoftBlue.
  ///
  /// In en, this message translates to:
  /// **'Soft Blue'**
  String get accentSoftBlue;

  /// No description provided for @accentSoftViolet.
  ///
  /// In en, this message translates to:
  /// **'Soft Violet'**
  String get accentSoftViolet;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// No description provided for @textSizeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get textSizeSystem;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get textSizeExtraLarge;

  /// No description provided for @textSizeNote.
  ///
  /// In en, this message translates to:
  /// **'Never smaller than your device’s accessibility setting.'**
  String get textSizeNote;

  /// No description provided for @settingsExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get settingsExperience;

  /// No description provided for @experienceStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get experienceStandard;

  /// No description provided for @experienceGuided.
  ///
  /// In en, this message translates to:
  /// **'Guided'**
  String get experienceGuided;

  /// No description provided for @experienceGuidedDesc.
  ///
  /// In en, this message translates to:
  /// **'Larger actions, clearer guidance, less technical detail up front.'**
  String get experienceGuidedDesc;

  /// No description provided for @settingsMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get settingsMotion;

  /// No description provided for @motionSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get motionSystem;

  /// No description provided for @motionReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get motionReduced;

  /// No description provided for @motionNote.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion pauses ambient animation. Risk changes always stay visible.'**
  String get motionNote;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// No description provided for @hapticsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get hapticsOn;

  /// No description provided for @hapticsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get hapticsOff;

  /// No description provided for @settingsFamilyStatus.
  ///
  /// In en, this message translates to:
  /// **'Family Shield alerts'**
  String get settingsFamilyStatus;

  /// No description provided for @settingsNotificationState.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get settingsNotificationState;

  /// No description provided for @notifStateGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notifStateGranted;

  /// No description provided for @notifStateDenied.
  ///
  /// In en, this message translates to:
  /// **'Off — enable in device settings'**
  String get notifStateDenied;

  /// No description provided for @notifStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not determined'**
  String get notifStateUnknown;

  /// No description provided for @settingsNotificationNote.
  ///
  /// In en, this message translates to:
  /// **'Notification sound and delivery are controlled by your device notification settings.'**
  String get settingsNotificationNote;

  /// No description provided for @settingsOpenNotifSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get settingsOpenNotifSettings;

  /// No description provided for @settingsHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get settingsHowItWorks;

  /// No description provided for @settingsAnalysisLangs.
  ///
  /// In en, this message translates to:
  /// **'Conversation-risk analysis currently supports English and Egyptian Arabic. The app interface language can be changed independently.'**
  String get settingsAnalysisLangs;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Your name, language, and appearance preferences stay on this device.'**
  String get settingsLocalOnly;

  /// No description provided for @msgFamilyShieldDisabled.
  ///
  /// In en, this message translates to:
  /// **'Family Shield is disabled.'**
  String get msgFamilyShieldDisabled;

  /// No description provided for @msgNeedTrustedContact.
  ///
  /// In en, this message translates to:
  /// **'Add someone to your Trusted Circle before sending a Family Shield alert.'**
  String get msgNeedTrustedContact;

  /// No description provided for @msgDemoAlertBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Demo alert broadcast to {count} family member(s).'**
  String msgDemoAlertBroadcast(int count);

  /// No description provided for @msgAlertAccepted.
  ///
  /// In en, this message translates to:
  /// **'Alert accepted for delivery to {count} family member(s).'**
  String msgAlertAccepted(int count);

  /// No description provided for @msgRelayRejected.
  ///
  /// In en, this message translates to:
  /// **'Relay rejected the alert ({code}).'**
  String msgRelayRejected(int code);

  /// No description provided for @msgServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Alert service unavailable ({code}).'**
  String msgServiceUnavailable(int code);

  /// No description provided for @msgNetworkAlert.
  ///
  /// In en, this message translates to:
  /// **'Network error — alert could not be sent.'**
  String get msgNetworkAlert;

  /// No description provided for @msgNetworkResponse.
  ///
  /// In en, this message translates to:
  /// **'Network error — response could not be sent.'**
  String get msgNetworkResponse;

  /// No description provided for @msgChooseResponse.
  ///
  /// In en, this message translates to:
  /// **'Choose Safe or Still Suspicious before responding.'**
  String get msgChooseResponse;

  /// No description provided for @msgInvalidTarget.
  ///
  /// In en, this message translates to:
  /// **'Response target is not a valid Family Shield ID.'**
  String get msgInvalidTarget;

  /// No description provided for @msgDemoResponse.
  ///
  /// In en, this message translates to:
  /// **'Demo — response simulated, nothing left this device.'**
  String get msgDemoResponse;

  /// No description provided for @msgFamilyUpdateSent.
  ///
  /// In en, this message translates to:
  /// **'Family update sent.'**
  String get msgFamilyUpdateSent;

  /// No description provided for @msgCircleFull.
  ///
  /// In en, this message translates to:
  /// **'Trusted Circle is full (5 people). Remove someone first.'**
  String get msgCircleFull;

  /// No description provided for @msgDuplicateContact.
  ///
  /// In en, this message translates to:
  /// **'That Family Shield ID is already in your Trusted Circle.'**
  String get msgDuplicateContact;

  /// No description provided for @msgNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get msgNameRequired;

  /// No description provided for @msgInvalidShieldId.
  ///
  /// In en, this message translates to:
  /// **'Response target is not a valid Family Shield ID.'**
  String get msgInvalidShieldId;

  /// No description provided for @msgPhoneTooLong.
  ///
  /// In en, this message translates to:
  /// **'Phone number is too long.'**
  String get msgPhoneTooLong;

  /// No description provided for @msgDemoReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Demo contacts are read-only'**
  String get msgDemoReadOnly;

  /// No description provided for @msgPushSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Push setup failed on this device.'**
  String get msgPushSetupFailed;

  /// No description provided for @msgPushLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not link your Family Shield ID.'**
  String get msgPushLinkFailed;

  /// No description provided for @msgPushEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not enable push alerts. Try again.'**
  String get msgPushEnableFailed;

  /// No description provided for @msgPushStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Push state could not be read.'**
  String get msgPushStateFailed;

  /// No description provided for @msgMicUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Microphone capture is not supported on this platform. Try Demo Mode instead.'**
  String get msgMicUnsupported;

  /// No description provided for @msgMicBlocked.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is blocked. Enable it in system settings, or use Demo Mode.'**
  String get msgMicBlocked;

  /// No description provided for @msgMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission was denied. Grant access to run Live Mic, or use Demo Mode.'**
  String get msgMicDenied;

  /// No description provided for @msgMicFailed.
  ///
  /// In en, this message translates to:
  /// **'Microphone failed to start. Check the device and retry, or use Demo Mode.'**
  String get msgMicFailed;

  /// No description provided for @msgFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'That file appears to be empty.'**
  String get msgFileEmpty;

  /// No description provided for @msgFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large — recordings up to 25 MB are supported.'**
  String get msgFileTooLarge;

  /// No description provided for @msgFileTooLong.
  ///
  /// In en, this message translates to:
  /// **'That recording is too long — up to 15 minutes are supported.'**
  String get msgFileTooLong;

  /// No description provided for @msgFileNoAudio.
  ///
  /// In en, this message translates to:
  /// **'The recording decoded to no audio — nothing to analyze.'**
  String get msgFileNoAudio;

  /// No description provided for @msgEmptyTranscript.
  ///
  /// In en, this message translates to:
  /// **'Provider returned an empty transcript.'**
  String get msgEmptyTranscript;

  /// No description provided for @msgTranscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'The transcription provider could not process the audio.'**
  String get msgTranscriptionFailed;

  /// No description provided for @msgTranscriptionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Transcription timed out — the acoustic result is still available.'**
  String get msgTranscriptionTimeout;

  /// No description provided for @msgCloudNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud transcription isn\'t configured in this build. Acoustic analysis is still available on-device.'**
  String get msgCloudNotConfigured;

  /// No description provided for @msgEnhancedLocked.
  ///
  /// In en, this message translates to:
  /// **'Enhanced recording transcription is included with Sentinel Shield. On-device acoustic analysis is still available.'**
  String get msgEnhancedLocked;

  /// No description provided for @msgSubsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are not configured in this build.'**
  String get msgSubsNotConfigured;

  /// No description provided for @msgSubsInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions could not be initialized.'**
  String get msgSubsInitFailed;

  /// No description provided for @msgPlansLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Plans could not be loaded from the store.'**
  String get msgPlansLoadFailed;

  /// No description provided for @msgPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed.'**
  String get msgPurchaseFailed;

  /// No description provided for @msgNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection — check your network and try again.'**
  String get msgNoConnection;

  /// No description provided for @msgStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is unavailable right now. Try again later.'**
  String get msgStoreUnavailable;

  /// No description provided for @msgPurchaseNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not allowed on this device or account.'**
  String get msgPurchaseNotAllowed;

  /// No description provided for @msgPurchasePending.
  ///
  /// In en, this message translates to:
  /// **'The payment is pending approval.'**
  String get msgPurchasePending;

  /// No description provided for @msgRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchases could not be restored right now.'**
  String get msgRestoreFailed;

  /// No description provided for @msgNoPaidPlans.
  ///
  /// In en, this message translates to:
  /// **'No paid plans are available in this store yet.'**
  String get msgNoPaidPlans;

  /// No description provided for @msgPurchasePendingActivation.
  ///
  /// In en, this message translates to:
  /// **'The purchase did not activate a plan yet — it may take a moment. Use Restore Purchases to check again.'**
  String get msgPurchasePendingActivation;

  /// No description provided for @msgDemoCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Demo checkout failed — please try again.'**
  String get msgDemoCheckoutFailed;

  /// No description provided for @msgTokenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare transcription — try again.'**
  String get msgTokenFailed;

  /// No description provided for @reasonFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial transfer demand detected'**
  String get reasonFinancial;

  /// No description provided for @reasonSecrecy.
  ///
  /// In en, this message translates to:
  /// **'Secrecy & isolation pressure'**
  String get reasonSecrecy;

  /// No description provided for @reasonUrgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency manipulation tactics'**
  String get reasonUrgency;

  /// No description provided for @reasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Identity impersonation claim: “{claim}”'**
  String reasonImpersonation(String claim);

  /// No description provided for @reasonAcoustic.
  ///
  /// In en, this message translates to:
  /// **'Acoustic anomaly indicators elevated'**
  String get reasonAcoustic;

  /// No description provided for @reasonCoordinated.
  ///
  /// In en, this message translates to:
  /// **'Coordinated scam pattern — amplified'**
  String get reasonCoordinated;

  /// No description provided for @reasonNone.
  ///
  /// In en, this message translates to:
  /// **'No significant threat indicators'**
  String get reasonNone;

  /// No description provided for @actionContinueMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Continue monitoring'**
  String get actionContinueMonitoring;

  /// No description provided for @actionAdviseCaution.
  ///
  /// In en, this message translates to:
  /// **'Advise caution — verify caller identity'**
  String get actionAdviseCaution;

  /// No description provided for @actionEndCall.
  ///
  /// In en, this message translates to:
  /// **'End call immediately and alert a trusted contact'**
  String get actionEndCall;

  /// No description provided for @actionEndCallShort.
  ///
  /// In en, this message translates to:
  /// **'End the call immediately'**
  String get actionEndCallShort;

  /// No description provided for @actionNoCodes.
  ///
  /// In en, this message translates to:
  /// **'Do not share OTPs, PINs or banking details'**
  String get actionNoCodes;

  /// No description provided for @actionVerifyChannel.
  ///
  /// In en, this message translates to:
  /// **'Verify the caller through an official channel'**
  String get actionVerifyChannel;

  /// No description provided for @actionReport.
  ///
  /// In en, this message translates to:
  /// **'Report the number to your carrier or authorities'**
  String get actionReport;

  /// No description provided for @actionEnableFamily.
  ///
  /// In en, this message translates to:
  /// **'Enable Family Shield alerts for relatives'**
  String get actionEnableFamily;

  /// No description provided for @actionNoTimeOffers.
  ///
  /// In en, this message translates to:
  /// **'Do not act on time-limited offers under pressure'**
  String get actionNoTimeOffers;

  /// No description provided for @evidenceImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get evidenceImpersonation;

  /// No description provided for @evidenceMoney.
  ///
  /// In en, this message translates to:
  /// **'Money Request'**
  String get evidenceMoney;

  /// No description provided for @evidenceUrgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get evidenceUrgency;

  /// No description provided for @evidenceSecrecy.
  ///
  /// In en, this message translates to:
  /// **'Secrecy'**
  String get evidenceSecrecy;

  /// No description provided for @sourceLiveMic.
  ///
  /// In en, this message translates to:
  /// **'Live Microphone'**
  String get sourceLiveMic;

  /// No description provided for @sourceLiveMicSession.
  ///
  /// In en, this message translates to:
  /// **'Live Microphone Session'**
  String get sourceLiveMicSession;

  /// No description provided for @sourceDemoAudio.
  ///
  /// In en, this message translates to:
  /// **'Generated Demo Audio'**
  String get sourceDemoAudio;

  /// No description provided for @sourceDemoTranscript.
  ///
  /// In en, this message translates to:
  /// **'Local Demo Transcript'**
  String get sourceDemoTranscript;

  /// No description provided for @sourceUserTranscript.
  ///
  /// In en, this message translates to:
  /// **'User-provided transcript'**
  String get sourceUserTranscript;

  /// No description provided for @sourceUploadedRecording.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Recording'**
  String get sourceUploadedRecording;

  /// No description provided for @sourceRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get sourceRecording;

  /// No description provided for @sourceAssemblyAiPrerecorded.
  ///
  /// In en, this message translates to:
  /// **'AssemblyAI Pre-recorded'**
  String get sourceAssemblyAiPrerecorded;

  /// No description provided for @sourceAssemblyAiStreaming.
  ///
  /// In en, this message translates to:
  /// **'AssemblyAI Streaming'**
  String get sourceAssemblyAiStreaming;

  /// No description provided for @sourceNoneAcoustic.
  ///
  /// In en, this message translates to:
  /// **'None — acoustic analysis only'**
  String get sourceNoneAcoustic;

  /// No description provided for @callerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Caller (+20 10 ••• ••42)'**
  String get callerUnknown;

  /// No description provided for @callerSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Contact (+1 888 ••• 0112)'**
  String get callerSuspicious;

  /// No description provided for @reportDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-generated forensic telemetry. Not a legal or judicial determination.'**
  String get reportDisclaimer;

  /// No description provided for @reportAnalysisPartial.
  ///
  /// In en, this message translates to:
  /// **'Analysis: Partial — acoustic signals only'**
  String get reportAnalysisPartial;

  /// No description provided for @reportAcousticScore.
  ///
  /// In en, this message translates to:
  /// **'Acoustic anomaly score: {score}/100'**
  String reportAcousticScore(int score);

  /// No description provided for @reportConvNotAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Conversation-risk signals were not analyzed.'**
  String get reportConvNotAnalyzed;

  /// No description provided for @reportRiskLine.
  ///
  /// In en, this message translates to:
  /// **'Risk: {risk} — Threat Score: {score}/100'**
  String reportRiskLine(String risk, int score);

  /// No description provided for @reportIdLine.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String reportIdLine(String id);

  /// No description provided for @reportTimeLine.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String reportTimeLine(String time);

  /// No description provided for @reportCallerLine.
  ///
  /// In en, this message translates to:
  /// **'Caller: {caller}'**
  String reportCallerLine(String caller);

  /// No description provided for @reportDurationLine.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String reportDurationLine(String duration);

  /// No description provided for @reportSignalsLine.
  ///
  /// In en, this message translates to:
  /// **'Signals: {reasons}'**
  String reportSignalsLine(String reasons);

  /// No description provided for @reportAudioSourceLine.
  ///
  /// In en, this message translates to:
  /// **'Audio source: {source}'**
  String reportAudioSourceLine(String source);

  /// No description provided for @reportTranscriptionLine.
  ///
  /// In en, this message translates to:
  /// **'Transcription: {source}'**
  String reportTranscriptionLine(String source);

  /// No description provided for @reportShaLine.
  ///
  /// In en, this message translates to:
  /// **'Audio SHA-256: {sha}'**
  String reportShaLine(String sha);

  /// No description provided for @elevatedAcousticSummary.
  ///
  /// In en, this message translates to:
  /// **'Elevated acoustic anomalies — conversation-risk signals were not analyzed'**
  String get elevatedAcousticSummary;

  /// No description provided for @demoTranscript1.
  ///
  /// In en, this message translates to:
  /// **'This is urgent — act now before the offer expires.'**
  String get demoTranscript1;

  /// No description provided for @demoTranscript2.
  ///
  /// In en, this message translates to:
  /// **'Don\'t tell anyone until it\'s done.'**
  String get demoTranscript2;

  /// No description provided for @metricAcousticAnomaly.
  ///
  /// In en, this message translates to:
  /// **'Acoustic Anomaly Score'**
  String get metricAcousticAnomaly;

  /// No description provided for @recordingFormatsHint.
  ///
  /// In en, this message translates to:
  /// **'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — up to 25 MB or 15 minutes.'**
  String get recordingFormatsHint;

  /// No description provided for @recordingAcousticScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Acoustic anomaly score'**
  String get recordingAcousticScoreLabel;

  /// No description provided for @recordingVerifyNormalBody.
  ///
  /// In en, this message translates to:
  /// **'A score is a risk signal, not proof. Verify the speaker through a number you already trust — never one provided in the recording — before acting on any request.'**
  String get recordingVerifyNormalBody;

  /// No description provided for @familyVerifyKnownSender.
  ///
  /// In en, this message translates to:
  /// **'Call {name} using the trusted number you saved — not a number provided by the suspicious caller.'**
  String familyVerifyKnownSender(String name);

  /// No description provided for @familyVerifyUnknownSender.
  ///
  /// In en, this message translates to:
  /// **'Verify through a channel you already trust. Do not act on instructions from the alert alone.'**
  String get familyVerifyUnknownSender;

  /// No description provided for @familyResolutionSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe after verification'**
  String get familyResolutionSafe;

  /// No description provided for @familyResolutionStillSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Still suspicious'**
  String get familyResolutionStillSuspicious;

  /// No description provided for @familyResolutionUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get familyResolutionUnresolved;

  /// No description provided for @familyResolutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {status}'**
  String familyResolutionLabel(String status);

  /// No description provided for @familyReceiverReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to receive alerts'**
  String get familyReceiverReady;

  /// No description provided for @familyReceiverShareNote.
  ///
  /// In en, this message translates to:
  /// **'Share this ID only with someone you want to receive Family Shield alerts from.'**
  String get familyReceiverShareNote;

  /// No description provided for @familyShieldIdCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy Family Shield ID'**
  String get familyShieldIdCopyTooltip;

  /// No description provided for @msgFamilyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Family Shield is disabled.'**
  String get msgFamilyDisabled;

  /// No description provided for @msgAlertDelivered.
  ///
  /// In en, this message translates to:
  /// **'Alert accepted for delivery to {count} family member(s).'**
  String msgAlertDelivered(int count);

  /// No description provided for @msgFamilyIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Family Shield ID must look like vg_ followed by 32 hex characters. Ask your family member to copy it from their app (Settings → Family Shield Receiver).'**
  String get msgFamilyIdInvalid;

  /// No description provided for @msgMicStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Microphone failed to start. Check the device and retry, or use Demo Mode.'**
  String get msgMicStartFailed;

  /// No description provided for @scoreUrgency.
  ///
  /// In en, this message translates to:
  /// **'URGENCY'**
  String get scoreUrgency;

  /// No description provided for @scoreFinancial.
  ///
  /// In en, this message translates to:
  /// **'FINANCIAL'**
  String get scoreFinancial;

  /// No description provided for @scoreSecrecy.
  ///
  /// In en, this message translates to:
  /// **'SECRECY'**
  String get scoreSecrecy;

  /// No description provided for @demoBadgeCompact.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get demoBadgeCompact;

  /// No description provided for @postCallDemoAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode — sends a simulated alert to demo contacts; no real notification is delivered.'**
  String get postCallDemoAlertDesc;

  /// No description provided for @postCallAskTrustDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask a person you trust for a second set of eyes — send them a Family Shield alert.'**
  String get postCallAskTrustDesc;

  /// No description provided for @recordingConversationAbsent.
  ///
  /// In en, this message translates to:
  /// **'CONVERSATION SIGNAL · NOT ANALYZED'**
  String get recordingConversationAbsent;

  /// No description provided for @msgDemoAlertDelivered.
  ///
  /// In en, this message translates to:
  /// **'Demo alert broadcast to {count} family member(s).'**
  String msgDemoAlertDelivered(int count);

  /// No description provided for @msgResponseRejected.
  ///
  /// In en, this message translates to:
  /// **'Relay rejected the response ({code}).'**
  String msgResponseRejected(int code);

  /// No description provided for @msgAlertUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Alert service unavailable ({code}).'**
  String msgAlertUnavailable(int code);

  /// No description provided for @msgAlertNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error — alert could not be sent.'**
  String get msgAlertNetworkError;

  /// No description provided for @msgResponseNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error — response could not be sent.'**
  String get msgResponseNetworkError;

  /// No description provided for @msgResolutionRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose Safe or Still Suspicious before responding.'**
  String get msgResolutionRequired;

  /// No description provided for @msgDemoResponseSent.
  ///
  /// In en, this message translates to:
  /// **'Demo — response simulated, nothing left this device.'**
  String get msgDemoResponseSent;

  /// No description provided for @pushAlertBodyHigh.
  ///
  /// In en, this message translates to:
  /// **'A high-risk call was flagged on a monitored device. Verify directly with your relative before any funds move.'**
  String get pushAlertBodyHigh;

  /// No description provided for @pushAlertBodySuspicious.
  ///
  /// In en, this message translates to:
  /// **'A suspicious-call warning was flagged on a monitored device. Verify directly with your relative before any funds move.'**
  String get pushAlertBodySuspicious;

  /// No description provided for @pushAlertBodyPartial.
  ///
  /// In en, this message translates to:
  /// **'Elevated acoustic signals were flagged in a recording on a monitored device. Conversation-risk signals were not analyzed — verify directly with your relative.'**
  String get pushAlertBodyPartial;

  /// No description provided for @familyReceiverTestDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'vg_… external id of test device'**
  String get familyReceiverTestDeviceHint;

  /// No description provided for @verifyStepHangup.
  ///
  /// In en, this message translates to:
  /// **'Hang up — do not send money.'**
  String get verifyStepHangup;

  /// No description provided for @familyUpdateIncidentId.
  ///
  /// In en, this message translates to:
  /// **'Incident {id}'**
  String familyUpdateIncidentId(String id);

  /// No description provided for @familyUpdateReceivedAt.
  ///
  /// In en, this message translates to:
  /// **'Received {time}'**
  String familyUpdateReceivedAt(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
