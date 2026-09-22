// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'PauseSignal';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionContactAuthority =>
      'Contactez la banque, l\'opérateur ou l\'autorité compétente si nécessaire';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionSkip => 'Ignorer pour l\'instant';

  @override
  String get actionSkipSetup => 'Ignorer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionRemove => 'Retirer';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionView => 'Voir';

  @override
  String get actionOpenSystemSettings => 'Ouvrir les réglages système';

  @override
  String get actionCopyId => 'Copier l\'ID';

  @override
  String get actionAddPerson => 'Ajouter une personne';

  @override
  String get howItWorksTitle => 'Comment fonctionne PauseSignal';

  @override
  String get exploreApp => 'Explorer PauseSignal';

  @override
  String get unrecognizedIdentity => 'Une identité PauseSignal non reconnue';

  @override
  String get safecallIntro =>
      'PauseSignal écoute via votre micro des schémas vocaux et conversationnels suspects.';

  @override
  String get familyAlertUnknownSender =>
      'Alerte Family Shield d\'une identité PauseSignal non reconnue.';

  @override
  String get pushAlertTitle => '🚨 Alerte PauseSignal Family Shield';

  @override
  String get incidentReportTitle => 'Rapport d\'incident PauseSignal';

  @override
  String get recordingUnreadable =>
      'PauseSignal n\'a pas pu lire cet enregistrement — il est peut-être corrompu ou dans un format non pris en charge.';

  @override
  String get recordingUndecodable =>
      'PauseSignal n\'a pas pu décoder cet enregistrement — le format n\'est peut-être pas pris en charge sur cet appareil.';

  @override
  String get recordingAnalyzerIntro =>
      'PauseSignal examine les anomalies acoustiques et, lorsque vous choisissez la transcription, les signaux de risque de la conversation.';

  @override
  String get partialRecordingNote =>
      'Les signaux de risque de la conversation n\'ont pas été analysés, PauseSignal ne peut donc pas produire un Score de Menace complet.';

  @override
  String get enhancedModeLockedDesc =>
      'Sentinel Shield ajoute la transcription améliorée — l\'enregistrement est envoyé via le relais de transcription de PauseSignal uniquement après votre accord. L\'analyse sur l\'appareil reste gratuite.';

  @override
  String get enhancedModeReadyDesc =>
      'Pour créer une transcription, cet enregistrement sera envoyé via le relais de transcription de PauseSignal au fournisseur de parole-texte configuré. PauseSignal ne conserve pas l\'enregistrement.';

  @override
  String get onboardingSignalsBody =>
      'Pendant une session SafeCall que vous lancez vous-même, PauseSignal écoute les signaux de risque — jamais une certitude d\'identité — et explique en langage clair ce qu\'il a entendu.';

  @override
  String get onboardingNoInterception =>
      'PauseSignal n\'intercepte pas les appels cellulaires de votre téléphone — une session de protection est toujours votre choix.';

  @override
  String get onboardingFamilyBody =>
      'Quand un appel semble louche, vos proches de confiance peuvent vous aider à décider. Chaque installation de PauseSignal reçoit un ID Family Shield opaque — vos proches l\'enregistrent dans leur propre Cercle de Confiance pour recevoir vos alertes de sécurité privées et y répondre.';

  @override
  String get onboardingPrivacyMic =>
      'L\'audio du micro est traité en mémoire pendant la session — PauseSignal ne stocke jamais d\'enregistrement audio. Live Mic ne demande l\'accès au micro que lorsque vous le choisissez ; le Mode Démo fonctionne sans lui.';

  @override
  String get onboardingPrivacyAlerts =>
      'Les alertes Family Shield ne portent qu\'un ID PauseSignal opaque, une référence d\'incident et un niveau de risque — jamais d\'audio, de transcription, de nom ni de numéro de téléphone.';

  @override
  String get whyFlaggedTitle => 'Pourquoi PauseSignal a signalé cet appel';

  @override
  String get whyElevatedAcousticTitle =>
      'POURQUOI VOXGUARD A DÉTECTÉ DES SIGNAUX ACOUSTIQUES ÉLEVÉS';

  @override
  String get whyFlaggedRecordingTitle =>
      'POURQUOI VOXGUARD A SIGNALÉ CET ENREGISTREMENT';

  @override
  String get whyFlaggedCallTitle => 'POURQUOI VOXGUARD A SIGNALÉ CET APPEL';

  @override
  String get whyFlaggedItTitle => 'POURQUOI VOXGUARD L\'A SIGNALÉ';

  @override
  String get welcomeTitle => 'Une façon plus sereine de répondre.';

  @override
  String get welcomeSubtitle =>
      'PauseSignal vous aide à faire une pause, vérifier et garder le contrôle quand un appel semble louche.';

  @override
  String get welcomeLanguageLabel => 'CHOISISSEZ VOTRE LANGUE';

  @override
  String get welcomeLanguageSystem => 'Suivre la langue de l\'appareil';

  @override
  String get welcomeNamePrompt => 'Comment devons-nous vous appeler ?';

  @override
  String get welcomeNameHint => 'Prénom ou surnom';

  @override
  String get welcomeNameNote =>
      'Facultatif — conservé uniquement sur cet appareil.';

  @override
  String get welcomeContinue => 'Continuer';

  @override
  String get onboardingVoiceTitle => 'Une voix familière peut encore tromper.';

  @override
  String get onboardingVoiceBody1 =>
      'Les escrocs clonent les voix, falsifient les numéros et pressent vos proches. Entendre une voix familière ne prouve pas qui parle.';

  @override
  String get onboardingVoiceBody2 =>
      'L\'urgence, le secret et la pression de paiement sont les vrais signaux — pas la voix elle-même.';

  @override
  String get onboardingVoiceBody3 =>
      'L\'identifiant d\'appelant et le son seuls ne peuvent jamais prouver une identité.';

  @override
  String get onboardingSignalsTitle => 'Deux signaux. Une décision humaine.';

  @override
  String get onboardingSignalSemantic =>
      'Signal de conversation — urgence, exigences de paiement, pression au secret dans ce qui est dit.';

  @override
  String get onboardingSignalAcoustic =>
      'Signal acoustique de la voix — indicateurs d\'anomalie ; une heuristique d\'aide, pas un verdict médico-légal.';

  @override
  String get onboardingSignalScore =>
      'Le score de Signal de Risque est un signal, pas la probabilité qu\'un appel soit faux.';

  @override
  String get onboardingVerifyTitle =>
      'Quand quelque chose semble louche, vérifiez par vous-même.';

  @override
  String get onboardingVerifyBody =>
      'Un signal de risque est une raison de pause — pas un verdict. Le meilleur réflexe reste le vôtre :';

  @override
  String get onboardingVerifyStep1 =>
      'Pause — n\'envoyez jamais d\'argent, de codes ni de données sous pression.';

  @override
  String get onboardingVerifyStep2 =>
      'Rappelez la personne sur un numéro que vous connaissez déjà — jamais celui donné par l\'appelant.';

  @override
  String get onboardingVerifyStep3 =>
      'Convenez hors ligne d\'une phrase de sécurité familiale — demandez-la quand un appel semble louche.';

  @override
  String get onboardingFamilyTitle =>
      'Family Shield : une paire d\'yeux en plus.';

  @override
  String get onboardingFamilyBody1 =>
      'Les noms et numéros de confiance restent sur l\'appareil qui les a enregistrés.';

  @override
  String get onboardingFamilyBody2 =>
      'Configurer votre Cercle de Confiance est facultatif — vous pouvez le faire plus tard dans Réglages.';

  @override
  String get onboardingFamilyIdPending =>
      'Votre ID Family Shield apparaît ici une fois l\'app configurée.';

  @override
  String onboardingYourId(String id) {
    return 'Votre ID : $id';
  }

  @override
  String get familyShieldIdCopied => 'ID Family Shield copié';

  @override
  String get familyAlertsEnabled => 'Alertes familiales activées';

  @override
  String get onboardingNotifOff =>
      'Les notifications sont désactivées — vous pouvez les activer plus tard depuis l\'app Réglages de l\'appareil.';

  @override
  String get onboardingPushUnsupported =>
      'Les alertes push ne sont pas prises en charge sur cette plateforme.';

  @override
  String get onboardingPushNotConfigured =>
      'Les alertes push ne sont pas configurées dans cette version.';

  @override
  String get onboardingEnablingNotif => 'Activation des notifications…';

  @override
  String get onboardingEnableAlerts => 'Activer les alertes familiales';

  @override
  String get onboardingPrivacyTitle => 'Votre voix reste sous votre contrôle.';

  @override
  String get onboardingPrivacyBody =>
      'Quand la transcription cloud est configurée, l\'audio en direct est envoyé au fournisseur de transcription configuré pour produire du texte à analyser.';

  @override
  String get onboardingPrivacyLoop =>
      'Preuve → Pause → Vérification → Personnes de confiance';

  @override
  String get onboardingPrivacyChoice =>
      'Lancez une session SafeCall quand vous voulez une protection — vous choisissez toujours Live Mic ou Mode Démo vous-même.';

  @override
  String get startupStoreError =>
      'Impossible d\'enregistrer votre progression — l\'assistant réapparaîtra au prochain lancement.';

  @override
  String get shieldStatusReady => 'PauseSignal prêt';

  @override
  String get shieldSubtitle => 'Défense vocale en temps réel en attente';

  @override
  String homeGreetingNamed(String name) {
    return 'Content de vous revoir, $name.';
  }

  @override
  String get quickActions => 'PROTECTION';

  @override
  String get startSafeCall => 'Démarrer SafeCall';

  @override
  String get startSafeCallDesc =>
      'Appel protégé dans l\'app avec télémétrie de menace en direct.';

  @override
  String get protectionCheckTitle => 'Lancer une vérification de protection';

  @override
  String get protectionCheckDesc =>
      'Utilisez le haut-parleur ou jouez un audio suspect à proximité — PauseSignal écoute les signaux de risque.';

  @override
  String get protectionCheckCta => 'Démarrer SafeCall';

  @override
  String get analyzeRecording => 'Analyser un enregistrement';

  @override
  String get analyzeRecordingDesc =>
      'Vérifiez un enregistrement d\'appel ou une note vocale.';

  @override
  String get incidentLogTooltip => 'Journal des incidents';

  @override
  String get familyShieldTitle => 'Family Shield';

  @override
  String get familyReadyWithCircle => 'Cercle de Confiance prêt';

  @override
  String get familyNeedsSetup => 'Configuration requise';

  @override
  String get familyStatusHint =>
      'Une paire d\'yeux en plus quand un appel semble louche.';

  @override
  String get navShield => 'Protéger';

  @override
  String get navIncidents => 'Incidents';

  @override
  String get navSettings => 'Réglages';

  @override
  String get safeCallTitle => 'SafeCall';

  @override
  String get safeCallActive => 'SESSION DE PROTECTION ACTIVE';

  @override
  String get unknownCaller => 'Appelant inconnu';

  @override
  String get maskedNumber => '+1 (•••) ••• ••42';

  @override
  String get endCall => 'Terminer';

  @override
  String get endCallAndVerify => 'Terminer et vérifier';

  @override
  String get liveBadge => 'EN DIRECT';

  @override
  String get signalSynthetic => 'Indicateurs d\'anomalie acoustique';

  @override
  String get signalUrgency => 'Pression d\'urgence';

  @override
  String get signalFinancial => 'Exigence de transfert financier';

  @override
  String get signalSecrecy => 'Demande de secret et d\'isolement';

  @override
  String get statusNormal => 'NORMAL';

  @override
  String get statusElevated => 'ÉLEVÉ';

  @override
  String get bannerProtected => 'PROTÉGÉ';

  @override
  String get bannerProtectedDetail =>
      'Tous les signaux nominaux — aucun indicateur de menace';

  @override
  String get bannerElevated => 'RISQUE ÉLEVÉ';

  @override
  String get bannerElevatedDetail => 'Schéma suspect — surveillance rapprochée';

  @override
  String get bannerThreat => 'Appel à haut risque détecté';

  @override
  String get bannerThreatDetail =>
      'Schémas d\'usurpation et d\'exigence financière signalés';

  @override
  String get threatScoreLabel => 'Score de menace';

  @override
  String get simulateScam => 'Simuler une arnaque';

  @override
  String get stopSimulation => 'Arrêter la démo';

  @override
  String get pauseHeadline => 'Faites une pause avant d\'agir.';

  @override
  String get verifyBeforeYouAct => 'Vérifiez avant d\'agir.';

  @override
  String get technicalDetails => 'DÉTAILS TECHNIQUES';

  @override
  String get liveTranscript => 'TRANSCRIPTION EN DIRECT';

  @override
  String get transcriptEmpty =>
      'La transcription apparaît ici pendant un appel protégé.';

  @override
  String get transcriptDemoPending =>
      'La transcription de démo apparaîtra ici.';

  @override
  String get transcriptListening => 'Écoute de la parole…';

  @override
  String get transcriptNoLive =>
      'Analyse vocale active — transcription en direct indisponible.';

  @override
  String get speakerCaller => 'Appelant';

  @override
  String get speakerYou => 'Vous';

  @override
  String get safeCallPickerTitle => 'Démarrer une session de protection';

  @override
  String get modeLiveMic => 'Micro en direct';

  @override
  String get modeLiveMicDesc =>
      'Analyse l’audio réel du micro — appels en haut-parleur ou voix jouée à proximité.';

  @override
  String get modeLiveMicBadge => 'SESSION RÉELLE';

  @override
  String get modeDemo => 'Attaque Démo';

  @override
  String get modeDemoDesc =>
      'Lance le scénario de démonstration — audio généré et transcription fictive. Aucun audio réel.';

  @override
  String get modeDemoBadge => 'DÉMONSTRATION';

  @override
  String get modeLiveBadgeShort => 'MICRO EN DIRECT';

  @override
  String get modeDemoBadgeShort => 'DÉMO';

  @override
  String get modeDemoModeLabel => 'MODE DÉMO';

  @override
  String durationMinSec(int m, int ss) {
    return '$m:$ss';
  }

  @override
  String durationHourMinSec(int h, int mm, int ss) {
    return '$h:$mm:$ss';
  }

  @override
  String get lensBandSafe => 'SÛR';

  @override
  String get lensBandCaution => 'PRUDENCE';

  @override
  String get lensBandHigh => 'HAUT RISQUE';

  @override
  String get lensInterpSafe =>
      'Les signaux semblent normaux — continuez d\'écouter.';

  @override
  String get lensInterpCaution =>
      'Quelque chose cloche — surveillez les signaux.';

  @override
  String get lensInterpHigh => 'Faites une pause avant d\'agir.';

  @override
  String get lensRiskSignal => 'SIGNAL DE RISQUE';

  @override
  String lensA11yPartial(int acoustic) {
    return 'Signal partiel — anomalie acoustique $acoustic sur 100. Analyse de conversation non exécutée.';
  }

  @override
  String lensA11yFull(String band, int score, int acoustic) {
    return 'Signal de risque $band, $score sur 100. Analyse acoustique $acoustic sur 100.';
  }

  @override
  String get lensDemoAudio => 'AUDIO DÉMO';

  @override
  String get lensLayerConversation => 'Conversation';

  @override
  String get lensLayerVoice => 'Acoustique vocale';

  @override
  String get lensNotAnalyzed => 'non analysé';

  @override
  String get signalPartialState => 'ACOUSTIQUE SEULE';

  @override
  String get acousticAnomalyLabel => 'ANOMALIE ACOUSTIQUE';

  @override
  String get conversationNotAnalyzed =>
      'Les signaux de risque de la conversation n\'ont pas été analysés.';

  @override
  String get acousticOnlyMonitoring =>
      'Surveillance acoustique active. L\'analyse de conversation requiert une transcription.';

  @override
  String get bannerAcousticOnly =>
      'Surveillance acoustique seule — signaux de conversation non analysés';

  @override
  String get bannerAcousticElevated =>
      'Anomalie acoustique élevée — signaux de conversation non analysés';

  @override
  String get acousticAnomalyElevatedNote =>
      'Indicateurs d\'anomalie acoustique élevés observés.';

  @override
  String get postCallEnded => 'Session de protection terminée';

  @override
  String get postCallReview =>
      'Passez en revue les preuves avant toute autre action.';

  @override
  String get postCallPause => 'Pause.';

  @override
  String get postCallVerifyCta => 'Vérifier par vous-même';

  @override
  String get callSavedNumberHint =>
      'Rappelez la personne sur un numéro en lequel vous avez déjà confiance.';

  @override
  String get verifyIdentityTitle => 'Vérifier l\'identité';

  @override
  String get verifyIdentityBody =>
      'Rappelez la personne sur un numéro en lequel vous avez déjà confiance — jamais celui qui vient de vous appeler.';

  @override
  String get callTrustedContact => 'Appeler un contact de confiance';

  @override
  String get sendDemoFamilyAlert => 'Envoyer une alerte familiale démo';

  @override
  String get familyAlertSent => 'Alerte démo diffusée à la famille';

  @override
  String get familySafePhrase =>
      'Astuce : convenez hors ligne d\'une phrase de sécurité familiale — demandez-la à l\'appelant.';

  @override
  String get viewIncidentReport => 'Voir le rapport d\'incident';

  @override
  String get incidentLogged => 'Appel à haut risque consigné';

  @override
  String get postCallNoFlags =>
      'Aucun schéma à haut risque n\'a été signalé pendant cet appel.';

  @override
  String get postCallSessionSummary => 'RÉSUMÉ DE SESSION';

  @override
  String get postCallFamilyShield => 'FAMILY SHIELD';

  @override
  String get postCallFamilyDemoNote =>
      'Mode Démo — envoie une alerte simulée aux contacts démo ; aucune notification réelle n\'est envoyée.';

  @override
  String get postCallFamilyPrompt =>
      'Demandez une paire d\'yeux en plus à une personne de confiance — envoyez-lui une alerte Family Shield.';

  @override
  String get postCallSendFamilyAlert => 'Envoyer une alerte familiale';

  @override
  String get postCallSendFamilyAlertDesc =>
      'Envoie une alerte Family Shield aux personnes de votre Cercle de Confiance';

  @override
  String get verifyStepCall =>
      'Appelez la personne sur un numéro enregistré et de confiance.';

  @override
  String get verifyStepPhrase =>
      'Demandez votre phrase de sécurité familiale en cas de doute.';

  @override
  String sheetScoreSummary(String headline, int score) {
    return '$headline Score de menace : $score/100.';
  }

  @override
  String get incidentsTitle => 'Incidents';

  @override
  String get incidentEmptyTitle => 'Aucun incident enregistré';

  @override
  String get incidentEmptyBody =>
      'Les sessions signalées et les enregistrements analysés apparaîtront ici comme journal de sécurité.';

  @override
  String get bandPartial => 'ANALYSE PARTIELLE';

  @override
  String get bandHigh => 'HAUT RISQUE';

  @override
  String get bandCritical => 'CRITIQUE / HAUT RISQUE';

  @override
  String get bandSuspicious => 'SUSPECT';

  @override
  String get bandSafe => 'SÛR';

  @override
  String incidentPartialSummary(int score) {
    return 'Anomalie acoustique $score/100 — risque de conversation non analysé';
  }

  @override
  String get incidentNoThreats => 'Aucune menace significative détectée';

  @override
  String incidentReasonsDetected(int count) {
    return '$count détectées';
  }

  @override
  String get incidentDeleteTitle => 'Supprimer cet incident ?';

  @override
  String incidentDeleteBody(String id) {
    return '$id sera définitivement supprimé de cet appareil. Action irréversible.';
  }

  @override
  String get incidentDeleteTooltip => 'Supprimer l\'incident';

  @override
  String get incidentDeleteFailed =>
      'Impossible de supprimer cet incident. Réessayez.';

  @override
  String get incidentCopied =>
      'Rapport d\'incident copié dans le presse-papiers.';

  @override
  String get incidentFamilyResponses => 'RÉPONSES FAMILY SHIELD';

  @override
  String familyMarkedSafe(String name) {
    return '$name a marqué la situation comme sûre';
  }

  @override
  String familyStillConcerned(String name) {
    return '$name est encore inquiet';
  }

  @override
  String get incidentRecommended => 'PROCHAINES ÉTAPES RECOMMANDÉES';

  @override
  String get incidentTechnicalEvidence => 'PREUVES TECHNIQUES';

  @override
  String get incidentAudioSha => 'SHA-256 AUDIO';

  @override
  String get incidentAcousticSignals => 'SIGNAUX D\'ANOMALIE ACOUSTIQUE';

  @override
  String get metricSpectralFlux => 'Flux spectral';

  @override
  String get metricSpectralRolloff => 'Coupure spectrale';

  @override
  String get metricZeroCrossing => 'Taux de passages par zéro';

  @override
  String get metricAcousticScore => 'Score d\'anomalie acoustique';

  @override
  String get incidentSemanticSignals => 'SIGNAUX DE MENACE SÉMANTIQUE';

  @override
  String get semUrgency => 'URGENCE';

  @override
  String get semFinancial => 'FINANCIER';

  @override
  String get semSecrecy => 'SECRET';

  @override
  String get incidentTranscriptTimeline => 'CHRONOLOGIE DE TRANSCRIPTION';

  @override
  String get incidentNoTranscript => 'Aucune transcription capturée.';

  @override
  String get incidentBroadcast => 'Diffuser à Family Shield';

  @override
  String get incidentBroadcastDemoNote =>
      'Mode Démo — aucune notification réelle n\'est envoyée';

  @override
  String get incidentShare => 'Partager le rapport d\'incident';

  @override
  String incidentScoreLine(int score) {
    return '$score/100';
  }

  @override
  String get acousticAnomalyPrefix => 'Anomalie acoustique ';

  @override
  String get analyzeRecordingTitle => 'Analyser un enregistrement';

  @override
  String get recordingStepTitle =>
      'Analysez un enregistrement d\'appel ou une note vocale';

  @override
  String get recordingFormats =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — jusqu\'à 25 Mo ou 15 minutes.';

  @override
  String get recordingChooseAudio => 'Choisir un audio';

  @override
  String get recordingPrivacyLabel => 'CONFIDENTIALITÉ';

  @override
  String get recordingKeepLocal => 'Garder l\'audio sur cet appareil';

  @override
  String get recordingKeepLocalDesc =>
      'L\'analyse acoustique s\'exécute localement. Rien n\'est téléversé.';

  @override
  String get recordingIncludeConversation =>
      'Inclure l\'analyse de conversation';

  @override
  String get recordingCloudNotConfigured =>
      'La transcription cloud n\'est pas configurée dans cette version. L\'analyse acoustique reste disponible sur l\'appareil.';

  @override
  String get recordingCancelAnalysis => 'Annuler l\'analyse';

  @override
  String get recordingAnalyzeAction => 'Analyser l\'enregistrement';

  @override
  String get recordingChooseDifferent => 'Choisir un autre fichier';

  @override
  String get recordingViewIncident => 'Voir le rapport d\'incident';

  @override
  String get recordingAnalyzeAnother => 'Analyser un autre enregistrement';

  @override
  String get recordingMetaFormat => 'Format';

  @override
  String get recordingMetaSize => 'Taille';

  @override
  String get recordingMetaDuration => 'Durée';

  @override
  String get recordingSentinelBadge => 'SENTINEL';

  @override
  String get recordingManualTranscript =>
      'Ajouter un texte de transcription à la place';

  @override
  String get recordingManualTranscriptLabel =>
      'TRANSCRIPTION FOURNIE PAR L\'UTILISATEUR';

  @override
  String get recordingManualTranscriptHint =>
      'Collez un texte de transcription que vous avez déjà — il reste sur cet appareil.';

  @override
  String get recordingStagePreparing => 'Préparation de l\'audio';

  @override
  String get recordingStageAcoustic => 'Analyse des signaux acoustiques';

  @override
  String get recordingStageUploading => 'Téléversement pour transcription';

  @override
  String get recordingStageTranscribing => 'Transcription de la conversation';

  @override
  String get recordingStageEvaluating => 'Évaluation du risque de conversation';

  @override
  String get recordingStageBuilding => 'Construction du résultat';

  @override
  String get recordingThreatScore => 'Score de menace';

  @override
  String get recordingConvNotAnalyzed => 'SIGNAL DE CONVERSATION · NON ANALYSÉ';

  @override
  String get recordingAcousticSignals => 'SIGNAUX D\'ANOMALIE ACOUSTIQUE';

  @override
  String get recordingAcousticScore => 'Score d\'anomalie acoustique';

  @override
  String get recordingMetricFlux => 'Flux spectral';

  @override
  String get recordingMetricRolloff => 'Coupure spectrale';

  @override
  String get recordingMetricZcr => 'Taux de passages par zéro';

  @override
  String get recordingTranscriptLabel => 'TRANSCRIPTION DE L\'ENREGISTREMENT';

  @override
  String get recordingVerifyTitle => 'VÉRIFIEZ AVANT D\'AGIR';

  @override
  String get recordingVerifyBody =>
      'Ceci est une vérification acoustique seule — la conversation elle-même n\'a pas été analysée. Ne vous fiez jamais à un résultat partiel pour juger un enregistrement sûr : vérifiez le locuteur via un canal en lequel vous avez déjà confiance.';

  @override
  String get stepPickRecording => 'CHOISISSEZ UN ENREGISTREMENT';

  @override
  String get stepPrivacyDepth => 'CHOISISSEZ LE NIVEAU DE CONFIDENTIALITÉ';

  @override
  String get stepAnalyze => 'ANALYSEZ';

  @override
  String get stepResult => 'COMPRENEZ LE RÉSULTAT';

  @override
  String get familyAlertTitle => 'Alerte Family Shield';

  @override
  String familyAlertAcoustic(String name) {
    return '$name vous demande de vérifier un avertissement acoustique élevé d\'un enregistrement.';
  }

  @override
  String familyAlertHighRisk(String name) {
    return '$name fait peut-être face à un appel à haut risque.';
  }

  @override
  String familyAlertSuspicious(String name) {
    return '$name a reçu un avertissement d\'appel suspect de PauseSignal.';
  }

  @override
  String get familyMarkedSafeNote =>
      'Marqué sûr après vérification indépendante.';

  @override
  String get familyStillSuspiciousNote =>
      'Toujours suspect — poursuivez la vérification.';

  @override
  String familyUpdateFailed(String localCopy) {
    return '$localCopy La mise à jour familiale n\'a pas pu être envoyée — vérifiez votre connexion.';
  }

  @override
  String get familyBandAlert => 'ALERTE';

  @override
  String get familyVerifyDirectly => 'Vérifiez directement';

  @override
  String familyVerifyCall(String name) {
    return 'Appelez $name au numéro de confiance enregistré — pas à un numéro fourni par l\'appelant suspect.';
  }

  @override
  String get familyVerifyChannel =>
      'Vérifiez via un canal en lequel vous avez déjà confiance. N\'agissez pas sur la base des seules instructions de l\'alerte.';

  @override
  String familyCallAction(String name) {
    return 'Appeler $name';
  }

  @override
  String familyCallActionUnknown(String name) {
    return 'Appeler $name';
  }

  @override
  String get familyCallContact => 'Appeler le contact';

  @override
  String get familyNoTrustedNumber =>
      'Aucun numéro de confiance enregistré. Contactez-les via un numéro en lequel vous avez déjà confiance.';

  @override
  String get familyMarkSafe => 'Marquer sûr';

  @override
  String get familyStillSuspicious => 'Toujours suspect';

  @override
  String get familyTipNoMoney => 'N\'envoyez ni argent ni cartes-cadeaux.';

  @override
  String get familyTipNoCodes =>
      'Ne partagez ni OTP, ni PIN, ni données bancaires.';

  @override
  String get familyTipChannel => 'Vérifiez via un autre canal indépendant.';

  @override
  String get familyTipAuthorities =>
      'Contactez leur banque, opérateur ou les autorités locales si besoin.';

  @override
  String get familyDetailsTitle => 'Détails';

  @override
  String familyDetailsBody(String incident, String time, String status) {
    return 'Incident $incident\nReçu $time\n$status';
  }

  @override
  String get familyStatusSafe => 'Sûr après vérification';

  @override
  String get familyStatusSuspicious => 'Toujours suspect';

  @override
  String get familyStatusUnresolved => 'Non résolu';

  @override
  String get familyPrivacyNote =>
      'Confidentialité : seuls une identité d\'appareil opaque et un niveau de risque ont été partagés. Les alertes Family Shield n\'incluent ni audio, ni transcription, ni noms, ni numéros de téléphone.';

  @override
  String get familyUpdateTitle => 'Mise à jour Family Shield';

  @override
  String familyUpdateMarkedSafe(String who) {
    return '$who a marqué la situation comme sûre';
  }

  @override
  String familyUpdateConcerned(String who) {
    return '$who est encore inquiet';
  }

  @override
  String familyUpdateHumanNote(String incident) {
    return 'Ceci est une mise à jour de vérification humaine — elle ne change pas l\'évaluation de risque de l\'IA.\n\nIncident $incident';
  }

  @override
  String get familyAlertReceived => 'Alerte Family Shield reçue';

  @override
  String get familyAlertFraming =>
      'Quelqu\'un que vous connaissez demande une paire d\'yeux en plus.';

  @override
  String get yourJudgment => 'VOTRE JUGEMENT';

  @override
  String get humanResponseNote =>
      'Votre appel est la vérification — pas l\'app. Marquer sûr ou suspect est une réponse humaine ; cela ne change pas l\'analyse de risque.';

  @override
  String get familyReceiverTitle => 'Récepteur Family Shield';

  @override
  String get familyReceiverDesc =>
      'Recevez une alerte quand un membre de votre cercle de confiance fait face à un appel à haut risque.';

  @override
  String get familyReceiverShareHint =>
      'Partagez cet ID uniquement avec les personnes dont vous voulez recevoir les alertes Family Shield.';

  @override
  String get familyReceiverEnable => 'Activer les alertes familiales';

  @override
  String get familyReceiverOpenSettings => 'Ouvrir les réglages système';

  @override
  String get familyReceiverNotConfigured =>
      'Configuration push indisponible — ONESIGNAL_APP_ID non configuré dans cette version.';

  @override
  String get familyReceiverDevRecipient => 'DEV · Destinataire d\'alerte test';

  @override
  String get familyReceiverSetTest => 'Définir le destinataire test';

  @override
  String get familyStateReady => 'Prêt à recevoir des alertes';

  @override
  String get familyStateRegistering => 'Enregistrement…';

  @override
  String get familyStateNeedPermission =>
      'Autorisation de notifications requise';

  @override
  String get familyStateBlocked =>
      'Notifications bloquées — activez-les dans les réglages système';

  @override
  String get familyStateNotConfigured => 'Push non configuré';

  @override
  String get familyStateUnsupported =>
      'Non pris en charge sur cette plateforme';

  @override
  String familyStateError(String detail) {
    return 'Erreur d\'enregistrement$detail';
  }

  @override
  String get familyShieldIdLabel => 'ID Family Shield';

  @override
  String get familyShieldIdCopy => 'Copier l\'ID Family Shield';

  @override
  String get familyShieldIdCopiedShort => 'ID Family Shield copié';

  @override
  String get trustedCircleTitle => 'Cercle de Confiance';

  @override
  String trustedCircleCount(int count, String max) {
    return '$count sur $max';
  }

  @override
  String get trustedCircleDesc =>
      'Les personnes à qui demander une paire d\'yeux en plus. Les alertes leur parviennent par ID Family Shield — les numéros de téléphone restent sur cet appareil.';

  @override
  String get trustedNoPhone => ' · sans téléphone';

  @override
  String get trustedPhoneStored => ' · téléphone enregistré';

  @override
  String get trustedPhoneNone => ' · aucun numéro';

  @override
  String get trustedAddTitle => 'Ajouter une personne de confiance';

  @override
  String get trustedEditTitle => 'Modifier la personne';

  @override
  String get trustedFindIdHint =>
      'Ils trouvent leur ID Family Shield dans leur propre app sous Réglages → Récepteur Family Shield.';

  @override
  String get trustedNameField => 'Nom';

  @override
  String get trustedShieldIdField => 'ID Family Shield';

  @override
  String get trustedPhoneField =>
      'Numéro de téléphone de confiance (facultatif)';

  @override
  String get paywallTitle => 'Deux signaux.\nUne décision humaine.';

  @override
  String get paywallSubtitle =>
      'PauseSignal signale le risque — vous vérifiez. Les forfaits payants étendent ce que les deux signaux voient.';

  @override
  String get securityBadge => 'Facturation gérée par votre boutique d\'apps';

  @override
  String get demoStoreBadge => 'BOUTIQUE DÉMO';

  @override
  String get demoStoreNotice => 'Paiement simulé — aucun débit réel.';

  @override
  String get testStoreBadge => 'REVENUECAT TEST STORE';

  @override
  String get testStoreNotice =>
      'Les achats passent par la Test Store officielle de RevenueCat — vérifiés par RevenueCat, sans débit réel.';

  @override
  String get storeUnavailableNotice =>
      'Les abonnements ne sont pas configurés dans cette version.';

  @override
  String get monthly => 'Mensuel';

  @override
  String get annual => 'Annuel';

  @override
  String get mostPopular => 'LE PLUS POPULAIRE';

  @override
  String get upgradeNow => 'Passer au niveau supérieur';

  @override
  String get continueFree => 'Continuer gratuitement';

  @override
  String get subscribeNow => 'S\'abonner';

  @override
  String get activateDemoPlan => 'Activer le forfait démo';

  @override
  String get demoPlanActivated => 'Forfait démo activé — aucun débit réel';

  @override
  String get noPurchasesRestored => 'Aucun achat actif trouvé.';

  @override
  String get terms => 'Conditions d\'utilisation';

  @override
  String get privacy => 'Politique de confidentialité';

  @override
  String get restore => 'Restaurer les achats';

  @override
  String get upgradeTooltip => 'Voir les forfaits';

  @override
  String get plansLoadError => 'Impossible de charger les forfaits.';

  @override
  String get planNotAvailable =>
      'Ce forfait n\'est pas disponible dans cette boutique.';

  @override
  String get prefSaveFailed =>
      'Impossible d\'enregistrer ce réglage — réessayez.';

  @override
  String planActivated(String name) {
    return '$name activé — protection améliorée';
  }

  @override
  String get planFreeLabel => 'Gratuit';

  @override
  String get planNotAvailableShort => 'Non disponible';

  @override
  String get planFreeBadge => 'NIVEAU GRATUIT';

  @override
  String get planSentinelBadge => 'SENTINEL ACTIF';

  @override
  String get planFamilyBadge => 'FAMILY VAULT ACTIF';

  @override
  String get tierQuickCheck => 'Quick Check';

  @override
  String get tierQuickCheckTag => 'Outils de sécurité locaux';

  @override
  String get tierQuickCheckF1 =>
      'Surveillance des anomalies acoustiques via micro en direct';

  @override
  String get tierQuickCheckF2 => 'Analyse d\'enregistrements sur l\'appareil';

  @override
  String get tierQuickCheckF3 =>
      'Vérification de transcription manuelle — analysée localement';

  @override
  String get tierQuickCheckF4 => 'Historique d\'incidents local';

  @override
  String get tierQuickCheckF5 =>
      'Recevoir et répondre aux alertes Family Shield';

  @override
  String get tierSentinel => 'Sentinel Shield';

  @override
  String get tierSentinelTag => 'Protection consciente de la conversation';

  @override
  String get tierSentinelF1 => 'Tout ce qui est dans Quick Check';

  @override
  String get tierSentinelF2 =>
      'Transcription automatique Live Mic et d\'enregistrements améliorée — quand l\'infrastructure est configurée';

  @override
  String get tierSentinelF3 =>
      'Analyse de risque de conversation adossée à la transcription';

  @override
  String get tierSentinelF4 => 'Score de menace fusionné multisignal';

  @override
  String get tierFamily => 'Family Vault';

  @override
  String get tierFamilyTag => 'La boucle de vérification humaine';

  @override
  String get tierFamilyF1 => 'Tout ce qui est dans Sentinel Shield';

  @override
  String get tierFamilyF2 =>
      'Envoyer des alertes Family Shield à votre Cercle de Confiance';

  @override
  String get tierFamilyF3 =>
      'Jusqu\'à 5 contacts de confiance enregistrés localement';

  @override
  String get tierFamilyF4 => 'Les réponses de sécurité reviennent en privé';

  @override
  String get familyVaultUnlocksAlerts =>
      'Family Vault vous permet d\'envoyer des alertes de sécurité à votre Cercle de Confiance.';

  @override
  String get acousticProtectionActive =>
      'Protection acoustique active. L\'analyse de conversation adossée à la transcription se débloque avec Sentinel Shield.';

  @override
  String currentPlan(String tier) {
    return 'Forfait actuel : $tier';
  }

  @override
  String get currentPlanDemo => ' (démo)';

  @override
  String get currentPlanTestStore => ' (boutique de test)';

  @override
  String get viewPlans => 'Voir les forfaits';

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get purchasesRestored => 'Achats restaurés.';

  @override
  String get purchasesRestoreFailed =>
      'Impossible de restaurer les achats pour l\'instant.';

  @override
  String get subscriptionSection => 'Abonnement';

  @override
  String get demoStoreSection => 'BOUTIQUE DÉMO';

  @override
  String get testStoreSection => 'REVENUECAT TEST STORE';

  @override
  String get billingMonthly => 'Mensuel';

  @override
  String get billingAnnual => 'Annuel';

  @override
  String get priceSuffixMonthly => '/mois';

  @override
  String get priceSuffixAnnual => '/an';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSectionProfile => 'PROFIL';

  @override
  String get settingsSectionAppearance => 'APPARENCE';

  @override
  String get settingsSectionSafety => 'SÉCURITÉ ET FAMILLE';

  @override
  String get settingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get settingsSectionSubscription => 'ABONNEMENT';

  @override
  String get settingsSectionAbout => 'À PROPOS ET CONFIDENTIALITÉ';

  @override
  String get settingsDisplayName => 'Nom affiché';

  @override
  String get settingsDisplayNameNone => 'Non défini';

  @override
  String get settingsDisplayNameHint => 'Comment devons-nous vous appeler ?';

  @override
  String get settingsDisplayNameNote =>
      'Conservé uniquement sur cet appareil — jamais partagé.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get languageEn => 'English';

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEs => 'Español';

  @override
  String get languageFr => 'Français';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsAccent => 'Accent';

  @override
  String get accentPeriwinkle => 'Pervenche';

  @override
  String get accentSoftBlue => 'Bleu doux';

  @override
  String get accentSoftViolet => 'Violet doux';

  @override
  String get settingsTextSize => 'Taille du texte';

  @override
  String get textSizeSystem => 'Système';

  @override
  String get textSizeLarge => 'Grand';

  @override
  String get textSizeExtraLarge => 'Très grand';

  @override
  String get textSizeNote =>
      'Jamais inférieur au réglage d\'accessibilité de votre appareil.';

  @override
  String get settingsExperience => 'Expérience';

  @override
  String get experienceStandard => 'Standard';

  @override
  String get experienceGuided => 'Guidée';

  @override
  String get experienceGuidedDesc =>
      'Actions plus grandes, guidage plus clair, moins de détails techniques au départ.';

  @override
  String get settingsMotion => 'Animations';

  @override
  String get motionSystem => 'Suivre le système';

  @override
  String get motionReduced => 'Réduites';

  @override
  String get motionNote =>
      'Les animations réduites suspendent l\'animation d\'ambiance. Les changements de risque restent toujours visibles.';

  @override
  String get settingsHaptics => 'Vibrations';

  @override
  String get hapticsOn => 'Activées';

  @override
  String get hapticsOff => 'Désactivées';

  @override
  String get settingsFamilyStatus => 'Alertes Family Shield';

  @override
  String get settingsNotificationState => 'Autorisation de notifications';

  @override
  String get notifStateGranted => 'Autorisée';

  @override
  String get notifStateDenied =>
      'Désactivée — à activer dans les réglages de l\'appareil';

  @override
  String get notifStateUnknown => 'Indéterminée';

  @override
  String get settingsNotificationNote =>
      'Le son et la remise des notifications sont contrôlés par les réglages de notification de votre appareil.';

  @override
  String get settingsOpenNotifSettings =>
      'Ouvrir les réglages de notifications';

  @override
  String get settingsHowItWorks => 'Comment ça marche';

  @override
  String get settingsAnalysisLangs =>
      'L\'analyse de risque de conversation prend actuellement en charge l\'anglais et l\'arabe égyptien. La langue de l\'interface de l\'app peut être changée indépendamment.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsLocalOnly =>
      'Votre nom, votre langue et vos préférences d\'apparence restent sur cet appareil.';

  @override
  String get msgFamilyShieldDisabled => 'Family Shield est désactivé.';

  @override
  String get msgNeedTrustedContact =>
      'Ajoutez quelqu\'un à votre Cercle de Confiance avant d\'envoyer une alerte Family Shield.';

  @override
  String msgDemoAlertBroadcast(int count) {
    return 'Alerte démo diffusée à $count membre(s) de la famille.';
  }

  @override
  String msgAlertAccepted(int count) {
    return 'Alerte acceptée pour livraison à $count membre(s) de la famille.';
  }

  @override
  String msgRelayRejected(int code) {
    return 'Le relais a rejeté l’alerte ($code).';
  }

  @override
  String msgServiceUnavailable(int code) {
    return 'Service d\'alerte indisponible ($code).';
  }

  @override
  String get msgNetworkAlert =>
      'Erreur réseau — l\'alerte n\'a pas pu être envoyée.';

  @override
  String get msgNetworkResponse =>
      'Erreur réseau — la réponse n\'a pas pu être envoyée.';

  @override
  String get msgChooseResponse =>
      'Choisissez Sûr ou Toujours suspect avant de répondre.';

  @override
  String get msgInvalidTarget =>
      'La cible de réponse n\'est pas un ID Family Shield valide.';

  @override
  String get msgDemoResponse =>
      'Démo — réponse simulée, rien n\'a quitté cet appareil.';

  @override
  String get msgFamilyUpdateSent => 'Mise à jour familiale envoyée.';

  @override
  String get msgCircleFull =>
      'Le Cercle de Confiance est plein (5 personnes). Retirez quelqu\'un d\'abord.';

  @override
  String get msgDuplicateContact =>
      'Cet ID Family Shield est déjà dans votre Cercle de Confiance.';

  @override
  String get msgNameRequired => 'Le nom est obligatoire.';

  @override
  String get msgInvalidShieldId =>
      'La cible de la réponse n’est pas un ID Family Shield valide.';

  @override
  String get msgPhoneTooLong => 'Le numéro de téléphone est trop long.';

  @override
  String get msgDemoReadOnly => 'Les contacts démo sont en lecture seule';

  @override
  String get msgPushSetupFailed =>
      'La configuration push a échoué sur cet appareil.';

  @override
  String get msgPushLinkFailed => 'Impossible de lier votre ID Family Shield.';

  @override
  String get msgPushEnableFailed =>
      'Impossible d\'activer les alertes push. Réessayez.';

  @override
  String get msgPushStateFailed => 'Impossible de lire l\'état push.';

  @override
  String get msgMicUnsupported =>
      'La capture micro n\'est pas prise en charge sur cette plateforme. Essayez le Mode Démo.';

  @override
  String get msgMicBlocked =>
      'L\'accès au micro est bloqué. Activez-le dans les réglages système, ou utilisez le Mode Démo.';

  @override
  String get msgMicDenied =>
      'L\'autorisation du micro a été refusée. Accordez-la pour utiliser Live Mic, ou utilisez le Mode Démo.';

  @override
  String get msgMicFailed =>
      'Le micro n\'a pas pu démarrer. Vérifiez l\'appareil et réessayez, ou utilisez le Mode Démo.';

  @override
  String get msgFileEmpty => 'Ce fichier semble vide.';

  @override
  String get msgFileTooLarge =>
      'Ce fichier est trop volumineux — enregistrements jusqu\'à 25 Mo acceptés.';

  @override
  String get msgFileTooLong =>
      'Cet enregistrement est trop long — jusqu\'à 15 minutes acceptées.';

  @override
  String get msgFileNoAudio =>
      'L\'enregistrement décodé ne contient aucun audio — rien à analyser.';

  @override
  String get msgEmptyTranscript =>
      'Le fournisseur a renvoyé une transcription vide.';

  @override
  String get msgTranscriptionFailed =>
      'Le fournisseur de transcription n\'a pas pu traiter l\'audio.';

  @override
  String get msgTranscriptionTimeout =>
      'La transcription a expiré — le résultat acoustique reste disponible.';

  @override
  String get msgCloudNotConfigured =>
      'La transcription cloud n\'est pas configurée dans cette version. L\'analyse acoustique reste disponible sur l\'appareil.';

  @override
  String get msgEnhancedLocked =>
      'La transcription améliorée d\'enregistrements est incluse avec Sentinel Shield. L\'analyse acoustique sur l\'appareil reste disponible.';

  @override
  String get msgSubsNotConfigured =>
      'Les abonnements ne sont pas configurés dans cette version.';

  @override
  String get msgSubsInitFailed => 'Impossible d\'initialiser les abonnements.';

  @override
  String get msgPlansLoadFailed =>
      'Impossible de charger les forfaits depuis la boutique.';

  @override
  String get msgPurchaseFailed => 'L\'achat n\'a pas pu être finalisé.';

  @override
  String get msgNoConnection =>
      'Pas de connexion — vérifiez votre réseau et réessayez.';

  @override
  String get msgStoreUnavailable =>
      'La boutique est indisponible pour l\'instant. Réessayez plus tard.';

  @override
  String get msgPurchaseNotAllowed =>
      'Les achats ne sont pas autorisés sur cet appareil ou ce compte.';

  @override
  String get msgPurchasePending => 'Le paiement est en attente d\'approbation.';

  @override
  String get msgRestoreFailed =>
      'Impossible de restaurer les achats pour l\'instant.';

  @override
  String get msgNoPaidPlans =>
      'Aucun forfait payant n\'est encore disponible dans cette boutique.';

  @override
  String get msgPurchasePendingActivation =>
      'L\'achat n\'a pas encore activé de forfait — cela peut prendre un moment. Utilisez Restaurer les achats pour revérifier.';

  @override
  String get msgDemoCheckoutFailed => 'Le paiement démo a échoué — réessayez.';

  @override
  String get msgTokenFailed =>
      'Impossible de préparer la transcription — réessayez.';

  @override
  String get reasonFinancial => 'Exigence de transfert financier détectée';

  @override
  String get reasonSecrecy => 'Pression au secret et à l\'isolement';

  @override
  String get reasonUrgency => 'Tactiques de manipulation par l\'urgence';

  @override
  String reasonImpersonation(String claim) {
    return 'Affirmation d\'usurpation d\'identité : « $claim »';
  }

  @override
  String get reasonAcoustic => 'Indicateurs d\'anomalie acoustique élevés';

  @override
  String get reasonCoordinated => 'Schéma d\'arnaque coordonné — amplifié';

  @override
  String get reasonNone => 'Aucun indicateur de menace significatif';

  @override
  String get actionContinueMonitoring => 'Continuer la surveillance';

  @override
  String get actionAdviseCaution =>
      'Conseiller la prudence — vérifier l\'identité de l\'appelant';

  @override
  String get actionEndCall =>
      'Terminer l\'appel immédiatement et alerter un contact de confiance';

  @override
  String get actionEndCallShort => 'Terminer l\'appel immédiatement';

  @override
  String get actionNoCodes =>
      'Ne partagez ni OTP, ni PIN, ni données bancaires';

  @override
  String get actionVerifyChannel =>
      'Vérifiez l\'appelant via un canal officiel';

  @override
  String get actionReport =>
      'Signalez le numéro à votre opérateur ou aux autorités';

  @override
  String get actionEnableFamily =>
      'Activez les alertes Family Shield pour vos proches';

  @override
  String get actionNoTimeOffers =>
      'N\'agissez pas sur des offres à durée limitée sous pression';

  @override
  String get evidenceImpersonation => 'Usurpation';

  @override
  String get evidenceMoney => 'Demande d\'argent';

  @override
  String get evidenceUrgency => 'Urgence';

  @override
  String get evidenceSecrecy => 'Secret';

  @override
  String get sourceLiveMic => 'Micro en direct';

  @override
  String get sourceLiveMicSession => 'Session micro en direct';

  @override
  String get sourceDemoAudio => 'Audio démo généré';

  @override
  String get sourceDemoTranscript => 'Transcription démo locale';

  @override
  String get sourceUserTranscript => 'Transcription fournie par l\'utilisateur';

  @override
  String get sourceUploadedRecording => 'Enregistrement téléversé';

  @override
  String get sourceRecording => 'Enregistrement';

  @override
  String get sourceAssemblyAiPrerecorded => 'AssemblyAI préenregistré';

  @override
  String get sourceAssemblyAiStreaming => 'AssemblyAI en direct';

  @override
  String get sourceNoneAcoustic => 'Aucune — analyse acoustique seule';

  @override
  String get callerUnknown => 'Appelant inconnu (+20 10 ••• ••42)';

  @override
  String get callerSuspicious => 'Contact suspect (+1 888 ••• 0112)';

  @override
  String get reportDisclaimer =>
      'Télémétrie forensique générée par IA. Pas une détermination légale ni judiciaire.';

  @override
  String get reportAnalysisPartial =>
      'Analyse : partielle — signaux acoustiques seuls';

  @override
  String reportAcousticScore(int score) {
    return 'Score d\'anomalie acoustique : $score/100';
  }

  @override
  String get reportConvNotAnalyzed =>
      'Les signaux de risque de la conversation n\'ont pas été analysés.';

  @override
  String reportRiskLine(String risk, int score) {
    return 'Risque : $risk — Score de menace : $score/100';
  }

  @override
  String reportIdLine(String id) {
    return 'ID : $id';
  }

  @override
  String reportTimeLine(String time) {
    return 'Heure : $time';
  }

  @override
  String reportCallerLine(String caller) {
    return 'Appelant : $caller';
  }

  @override
  String reportDurationLine(String duration) {
    return 'Durée : $duration';
  }

  @override
  String reportSignalsLine(String reasons) {
    return 'Signaux : $reasons';
  }

  @override
  String reportAudioSourceLine(String source) {
    return 'Source audio : $source';
  }

  @override
  String reportTranscriptionLine(String source) {
    return 'Transcription : $source';
  }

  @override
  String reportShaLine(String sha) {
    return 'SHA-256 audio : $sha';
  }

  @override
  String get elevatedAcousticSummary =>
      'Anomalies acoustiques élevées — signaux de risque de conversation non analysés';

  @override
  String get demoTranscript1 =>
      'C\'est urgent — agissez maintenant avant que l\'offre n\'expire.';

  @override
  String get demoTranscript2 =>
      'Ne le dites à personne tant que ce n\'est pas fait.';

  @override
  String get metricAcousticAnomaly => 'Score d’anomalie acoustique';

  @override
  String get recordingFormatsHint =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — jusqu’à 25 Mo ou 15 minutes.';

  @override
  String get recordingAcousticScoreLabel => 'Score d’anomalie acoustique';

  @override
  String get recordingVerifyNormalBody =>
      'Un score est un signal de risque, pas une preuve. Vérifiez l’interlocuteur via un numéro de confiance — jamais celui fourni dans l’enregistrement — avant de répondre à toute demande.';

  @override
  String familyVerifyKnownSender(String name) {
    return 'Appelez $name au numéro de confiance que vous avez enregistré — pas un numéro fourni par l’appelant suspect.';
  }

  @override
  String get familyVerifyUnknownSender =>
      'Vérifiez via un canal de confiance existant. N’agissez pas sur la seule base de l’alerte.';

  @override
  String get familyResolutionSafe => 'Sûr après vérification';

  @override
  String get familyResolutionStillSuspicious => 'Toujours suspect';

  @override
  String get familyResolutionUnresolved => 'Non résolu';

  @override
  String familyResolutionLabel(String status) {
    return 'Résolution : $status';
  }

  @override
  String get familyReceiverReady => 'Prêt à recevoir les alertes';

  @override
  String get familyReceiverShareNote =>
      'Partagez cet ID uniquement avec la personne dont vous souhaitez recevoir les alertes Family Shield.';

  @override
  String get familyShieldIdCopyTooltip => 'Copier l’ID Family Shield';

  @override
  String get msgFamilyDisabled => 'Family Shield est désactivé.';

  @override
  String msgAlertDelivered(int count) {
    return 'Alerte acceptée pour envoi à $count membre(s) de la famille.';
  }

  @override
  String get msgFamilyIdInvalid =>
      'L’ID Family Shield doit ressembler à vg_ suivi de 32 caractères hexadécimaux. Demandez à votre proche de le copier depuis son app (Réglages → Récepteur Family Shield).';

  @override
  String get msgMicStartFailed =>
      'Le microphone n’a pas pu démarrer. Vérifiez l’appareil et réessayez, ou utilisez le mode démo.';

  @override
  String get scoreUrgency => 'URGENCE';

  @override
  String get scoreFinancial => 'FINANCIER';

  @override
  String get scoreSecrecy => 'SECRET';

  @override
  String get demoBadgeCompact => 'DÉMO';

  @override
  String get postCallDemoAlertDesc =>
      'Mode démo — envoie une alerte simulée à des contacts fictifs ; aucune notification réelle n’est envoyée.';

  @override
  String get postCallAskTrustDesc =>
      'Demandez un second avis à un proche de confiance — envoyez-lui une alerte Family Shield.';

  @override
  String get recordingConversationAbsent =>
      'SIGNAL DE CONVERSATION · NON ANALYSÉ';

  @override
  String msgDemoAlertDelivered(int count) {
    return 'Alerte démo diffusée à $count membre(s) de la famille.';
  }

  @override
  String msgResponseRejected(int code) {
    return 'Le relais a rejeté la réponse ($code).';
  }

  @override
  String msgAlertUnavailable(int code) {
    return 'Service d’alerte indisponible ($code).';
  }

  @override
  String get msgAlertNetworkError =>
      'Erreur réseau — l’alerte n’a pas pu être envoyée.';

  @override
  String get msgResponseNetworkError =>
      'Erreur réseau — la réponse n’a pas pu être envoyée.';

  @override
  String get msgResolutionRequired =>
      'Choisissez Sûr ou Toujours suspect avant de répondre.';

  @override
  String get msgDemoResponseSent =>
      'Démo — réponse simulée, rien n’a quitté cet appareil.';

  @override
  String get pushAlertBodyHigh =>
      'Un appel à haut risque a été signalé sur un appareil surveillé. Vérifiez directement auprès de votre proche avant tout transfert de fonds.';

  @override
  String get pushAlertBodySuspicious =>
      'Un avertissement d’appel suspect a été signalé sur un appareil surveillé. Vérifiez directement auprès de votre proche avant tout transfert de fonds.';

  @override
  String get pushAlertBodyPartial =>
      'Des signaux acoustiques élevés ont été signalés dans un enregistrement sur un appareil surveillé. Les signaux de risque de conversation n’ont pas été analysés — vérifiez directement auprès de votre proche.';

  @override
  String get familyReceiverTestDeviceHint =>
      'vg_… identifiant externe de l’appareil de test';

  @override
  String get verifyStepHangup => 'Raccrochez — n’envoyez pas d’argent.';

  @override
  String familyUpdateIncidentId(String id) {
    return 'Incident $id';
  }

  @override
  String familyUpdateReceivedAt(String time) {
    return 'Reçu $time';
  }
}
