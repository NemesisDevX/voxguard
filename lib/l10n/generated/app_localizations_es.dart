// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'PauseSignal';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionDone => 'Listo';

  @override
  String get actionContactAuthority =>
      'Contacta con el banco, la operadora o la autoridad correspondiente si es necesario';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionSkip => 'Omitir por ahora';

  @override
  String get actionSkipSetup => 'Omitir';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionView => 'Ver';

  @override
  String get actionOpenSystemSettings => 'Abrir ajustes del sistema';

  @override
  String get actionCopyId => 'Copiar ID';

  @override
  String get actionAddPerson => 'Añadir persona';

  @override
  String get howItWorksTitle => 'Cómo funciona PauseSignal';

  @override
  String get exploreApp => 'Explorar PauseSignal';

  @override
  String get unrecognizedIdentity =>
      'Una identidad de PauseSignal no reconocida';

  @override
  String get safecallIntro =>
      'PauseSignal escucha por tu micrófono patrones de voz y conversación sospechosos.';

  @override
  String get familyAlertUnknownSender =>
      'Alerta de Family Shield de una identidad de PauseSignal no reconocida.';

  @override
  String get pushAlertTitle => '🚨 Alerta de PauseSignal Family Shield';

  @override
  String get incidentReportTitle => 'Informe de incidente de PauseSignal';

  @override
  String get recordingUnreadable =>
      'PauseSignal no pudo leer esta grabación — puede estar dañada o en un formato no compatible.';

  @override
  String get recordingUndecodable =>
      'PauseSignal no pudo decodificar esta grabación — el formato puede no ser compatible con este dispositivo.';

  @override
  String get recordingAnalyzerIntro =>
      'PauseSignal examina anomalías acústicas y, cuando eliges transcripción, señales de riesgo en la conversación.';

  @override
  String get partialRecordingNote =>
      'No se analizaron las señales de riesgo de la conversación, por lo que PauseSignal no puede producir una Puntuación de Amenaza completa.';

  @override
  String get enhancedModeLockedDesc =>
      'Sentinel Shield añade transcripción mejorada — la grabación se envía por el relé de transcripción de PauseSignal solo tras tu consentimiento. El análisis en el dispositivo sigue siendo gratuito.';

  @override
  String get enhancedModeReadyDesc =>
      'Para crear una transcripción, esta grabación se enviará por el relé de transcripción de PauseSignal al proveedor de voz a texto configurado. PauseSignal no almacena la grabación permanentemente.';

  @override
  String get onboardingSignalsBody =>
      'Durante una sesión de SafeCall que inicias tú mismo, PauseSignal escucha señales de riesgo — nunca certeza de identidad — y explica lo que oyó en lenguaje claro.';

  @override
  String get onboardingNoInterception =>
      'PauseSignal no intercepta las llamadas celulares de tu teléfono — una sesión de protección siempre es tu elección.';

  @override
  String get onboardingFamilyBody =>
      'Cuando una llamada te parece extraña, las personas de confianza pueden ayudarte a decidir. Cada instalación de PauseSignal recibe un ID de Family Shield opaco — las personas de confianza lo guardan en su propio Círculo de Confianza para recibir tus alertas de seguridad privadas y responder.';

  @override
  String get onboardingPrivacyMic =>
      'El audio del micrófono se procesa en memoria mientras dura la sesión — PauseSignal nunca almacena una grabación de audio. Live Mic pide acceso al micrófono solo cuando tú lo eliges; el Modo Demo funciona sin él.';

  @override
  String get onboardingPrivacyAlerts =>
      'Las alertas de Family Shield llevan solo un ID opaco de PauseSignal, una referencia de incidente y un nivel de riesgo — nunca audio, transcripciones, nombres ni números de teléfono.';

  @override
  String get whyFlaggedTitle => 'Por qué PauseSignal marcó esta llamada';

  @override
  String get whyElevatedAcousticTitle =>
      'POR QUÉ PAUSESIGNAL DETECTÓ SEÑALES ACÚSTICAS ELEVADAS';

  @override
  String get whyFlaggedRecordingTitle =>
      'POR QUÉ PAUSESIGNAL MARCÓ ESTA GRABACIÓN';

  @override
  String get whyFlaggedCallTitle => 'POR QUÉ PAUSESIGNAL MARCÓ ESTA LLAMADA';

  @override
  String get whyFlaggedItTitle => 'POR QUÉ PAUSESIGNAL LA MARCÓ';

  @override
  String get welcomeTitle => 'Una forma más tranquila de contestar.';

  @override
  String get welcomeSubtitle =>
      'PauseSignal te ayuda a pausar, verificar y mantener el control cuando una llamada te parece extraña.';

  @override
  String get welcomeLanguageLabel => 'ELIGE TU IDIOMA';

  @override
  String get welcomeLanguageSystem => 'Seguir el idioma del dispositivo';

  @override
  String get welcomeNamePrompt => '¿Cómo te llamamos?';

  @override
  String get welcomeNameHint => 'Nombre o apodo';

  @override
  String get welcomeNameNote =>
      'Opcional — se guarda solo en este dispositivo.';

  @override
  String get welcomeContinue => 'Continuar';

  @override
  String get onboardingVoiceTitle => 'Una voz familiar aún puede ser engañosa.';

  @override
  String get onboardingVoiceBody1 =>
      'Los estafadores clonan voces, falsifican números y presionan a quienes quieres. Oír una voz familiar no prueba quién habla.';

  @override
  String get onboardingVoiceBody2 =>
      'La urgencia, el secretismo y la presión de pago son las verdaderas señales — no la voz misma.';

  @override
  String get onboardingVoiceBody3 =>
      'El identificador de llamadas y el sonido por sí solos nunca prueban la identidad.';

  @override
  String get onboardingSignalsTitle => 'Dos señales. Una decisión humana.';

  @override
  String get onboardingSignalSemantic =>
      'Señal de conversación — urgencia, exigencias de pago, presión de secretismo en lo que se dice.';

  @override
  String get onboardingSignalAcoustic =>
      'Señal acústica de voz — indicadores de anomalía; una heurística de apoyo, no un veredicto forense.';

  @override
  String get onboardingSignalScore =>
      'La puntuación de Señal de Riesgo es una señal, no la probabilidad de que una llamada sea falsa.';

  @override
  String get onboardingVerifyTitle =>
      'Cuando algo te parece raro, verifica por tu cuenta.';

  @override
  String get onboardingVerifyBody =>
      'Una señal de riesgo es motivo para pausar — no un veredicto. La mejor jugada siempre es tuya:';

  @override
  String get onboardingVerifyStep1 =>
      'Pausa — nunca envíes dinero, códigos ni datos bajo presión.';

  @override
  String get onboardingVerifyStep2 =>
      'Devuelve la llamada a un número en el que ya confías — nunca al que te dio quien llamó.';

  @override
  String get onboardingVerifyStep3 =>
      'Acuerda una frase de seguridad familiar fuera de línea — pídela cuando una llamada te parezca rara.';

  @override
  String get onboardingFamilyTitle => 'Family Shield: un segundo par de ojos.';

  @override
  String get onboardingFamilyBody1 =>
      'Los nombres y teléfonos de confianza permanecen en el dispositivo que los guardó.';

  @override
  String get onboardingFamilyBody2 =>
      'Configurar tu Círculo de Confianza es opcional — puedes hacerlo luego en Ajustes.';

  @override
  String get onboardingFamilyIdPending =>
      'Tu ID de Family Shield aparece aquí cuando la app termina de configurarse.';

  @override
  String onboardingYourId(String id) {
    return 'Tu ID: $id';
  }

  @override
  String get familyShieldIdCopied => 'ID de Family Shield copiado';

  @override
  String get familyAlertsEnabled => 'Alertas familiares activadas';

  @override
  String get onboardingNotifOff =>
      'Las notificaciones están desactivadas; puedes activarlas más tarde desde la app de Configuración del dispositivo.';

  @override
  String get onboardingPushUnsupported =>
      'Las alertas push no son compatibles con esta plataforma.';

  @override
  String get onboardingPushNotConfigured =>
      'Las alertas push no están configuradas en esta compilación.';

  @override
  String get onboardingEnablingNotif => 'Activando notificaciones…';

  @override
  String get onboardingEnableAlerts => 'Activar alertas familiares';

  @override
  String get onboardingPrivacyTitle => 'Tu voz está bajo tu control.';

  @override
  String get onboardingPrivacyBody =>
      'Cuando la transcripción en la nube está configurada, el audio en vivo se envía al proveedor de transcripción configurado para producir texto para el análisis.';

  @override
  String get onboardingPrivacyLoop =>
      'Evidencia → Pausa → Verifica → Personas de confianza';

  @override
  String get onboardingPrivacyChoice =>
      'Inicia una sesión de SafeCall cuando quieras protección — tú siempre eliges entre Live Mic y Modo Demo.';

  @override
  String get startupStoreError =>
      'No se pudo guardar tu progreso — la configuración aparecerá de nuevo en el próximo inicio.';

  @override
  String get shieldStatusReady => 'PauseSignal listo';

  @override
  String get shieldSubtitle => 'Defensa de voz en tiempo real en espera';

  @override
  String homeGreetingNamed(String name) {
    return 'Qué bueno verte, $name.';
  }

  @override
  String get quickActions => 'PROTECCIÓN';

  @override
  String get startSafeCall => 'Iniciar SafeCall';

  @override
  String get startSafeCallDesc =>
      'Llamada protegida en la app con telemetría de amenazas en vivo.';

  @override
  String get protectionCheckTitle => 'Iniciar una comprobación de protección';

  @override
  String get protectionCheckDesc =>
      'Usa el altavoz o reproduce audio sospechoso cerca — PauseSignal escucha señales de riesgo.';

  @override
  String get protectionCheckCta => 'Iniciar SafeCall';

  @override
  String get analyzeRecording => 'Analizar grabación';

  @override
  String get analyzeRecordingDesc =>
      'Revisa una grabación de llamada o nota de voz guardada.';

  @override
  String get incidentLogTooltip => 'Registro de incidentes';

  @override
  String get familyShieldTitle => 'Family Shield';

  @override
  String get familyReadyWithCircle => 'Círculo de Confianza listo';

  @override
  String get familyNeedsSetup => 'Requiere configuración';

  @override
  String get familyStatusHint =>
      'Un segundo par de ojos cuando una llamada te parece rara.';

  @override
  String get navShield => 'Proteger';

  @override
  String get navIncidents => 'Incidentes';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get safeCallTitle => 'SafeCall';

  @override
  String get safeCallActive => 'SESIÓN DE PROTECCIÓN ACTIVA';

  @override
  String get unknownCaller => 'Llamada desconocida';

  @override
  String get maskedNumber => '+1 (•••) ••• ••42';

  @override
  String get endCall => 'Terminar';

  @override
  String get endCallAndVerify => 'Terminar y verificar';

  @override
  String get liveBadge => 'EN VIVO';

  @override
  String get signalSynthetic => 'Indicadores de anomalía acústica';

  @override
  String get signalUrgency => 'Presión de urgencia';

  @override
  String get signalFinancial => 'Exigencia de transferencia';

  @override
  String get signalSecrecy => 'Pedido de secretismo y aislamiento';

  @override
  String get statusNormal => 'NORMAL';

  @override
  String get statusElevated => 'ELEVADO';

  @override
  String get bannerProtected => 'PROTEGIDO';

  @override
  String get bannerProtectedDetail =>
      'Todas las señales normales — sin indicadores de amenaza';

  @override
  String get bannerElevated => 'RIESGO ELEVADO';

  @override
  String get bannerElevatedDetail =>
      'Patrón sospechoso — monitoreando de cerca';

  @override
  String get bannerThreat => 'Llamada de alto riesgo detectada';

  @override
  String get bannerThreatDetail =>
      'Patrones de suplantación y exigencia financiera marcados';

  @override
  String get threatScoreLabel => 'Puntuación de amenaza';

  @override
  String get simulateScam => 'Simular estafa';

  @override
  String get stopSimulation => 'Detener demo';

  @override
  String get pauseHeadline => 'Pausa antes de actuar.';

  @override
  String get verifyBeforeYouAct => 'Verifica antes de actuar.';

  @override
  String get technicalDetails => 'DETALLES TÉCNICOS';

  @override
  String get liveTranscript => 'TRANSCRIPCIÓN EN VIVO';

  @override
  String get transcriptEmpty =>
      'La transcripción aparece aquí durante una llamada protegida.';

  @override
  String get transcriptDemoPending =>
      'La transcripción de demostración aparecerá aquí.';

  @override
  String get transcriptListening => 'Escuchando voz…';

  @override
  String get transcriptNoLive =>
      'Análisis de voz activo — transcripción en vivo no disponible.';

  @override
  String get speakerCaller => 'Quien llama';

  @override
  String get speakerYou => 'Tú';

  @override
  String get safeCallPickerTitle => 'Iniciar una sesión de protección';

  @override
  String get modeLiveMic => 'Micrófono en vivo';

  @override
  String get modeLiveMicDesc =>
      'Analiza audio real del micrófono: llamadas en altavoz o una voz reproducida cerca.';

  @override
  String get modeLiveMicBadge => 'SESIÓN REAL';

  @override
  String get modeDemo => 'Ataque de demostración';

  @override
  String get modeDemoDesc =>
      'Ejecuta el escenario de demostración — audio generado y transcripción de prueba. Nada es audio real.';

  @override
  String get modeDemoBadge => 'DEMOSTRACIÓN';

  @override
  String get modeLiveBadgeShort => 'MIC EN VIVO';

  @override
  String get modeDemoBadgeShort => 'DEMO';

  @override
  String get modeDemoModeLabel => 'MODO DEMO';

  @override
  String durationMinSec(int m, int ss) {
    return '$m:$ss';
  }

  @override
  String durationHourMinSec(int h, int mm, int ss) {
    return '$h:$mm:$ss';
  }

  @override
  String get lensBandSafe => 'SEGURO';

  @override
  String get lensBandCaution => 'PRECAUCIÓN';

  @override
  String get lensBandHigh => 'ALTO RIESGO';

  @override
  String get lensInterpSafe =>
      'Las señales se ven normales — sigue escuchando.';

  @override
  String get lensInterpCaution => 'Algo no encaja — observa las señales.';

  @override
  String get lensInterpHigh => 'Pausa antes de actuar.';

  @override
  String get lensRiskSignal => 'SEÑAL DE RIESGO';

  @override
  String lensA11yPartial(int acoustic) {
    return 'Señal parcial — anomalía acústica $acoustic de 100. Análisis de conversación no ejecutado.';
  }

  @override
  String lensA11yFull(String band, int score, int acoustic) {
    return 'Señal de riesgo $band, $score de 100. Análisis acústico $acoustic de 100.';
  }

  @override
  String get lensDemoAudio => 'AUDIO DEMO';

  @override
  String get lensLayerConversation => 'Conversación';

  @override
  String get lensLayerVoice => 'Acústica de voz';

  @override
  String get lensNotAnalyzed => 'sin analizar';

  @override
  String get signalPartialState => 'SOLO ACÚSTICA';

  @override
  String get acousticAnomalyLabel => 'ANOMALÍA ACÚSTICA';

  @override
  String get conversationNotAnalyzed =>
      'No se analizaron las señales de riesgo de la conversación.';

  @override
  String get acousticOnlyMonitoring =>
      'Monitoreo acústico activo. El análisis de conversación requiere transcripción.';

  @override
  String get bannerAcousticOnly =>
      'Solo monitoreo acústico — señales de conversación sin analizar';

  @override
  String get bannerAcousticElevated =>
      'Anomalía acústica elevada — señales de conversación sin analizar';

  @override
  String get acousticAnomalyElevatedNote =>
      'Se observaron indicadores de anomalía acústica elevados.';

  @override
  String get postCallEnded => 'Sesión de protección terminada';

  @override
  String get postCallReview =>
      'Revisa la evidencia antes de tomar otra acción.';

  @override
  String get postCallPause => 'Pausa.';

  @override
  String get postCallVerifyCta => 'Verificar por tu cuenta';

  @override
  String get callSavedNumberHint =>
      'Devuelve la llamada a un número en el que ya confías.';

  @override
  String get verifyIdentityTitle => 'Verificar identidad';

  @override
  String get verifyIdentityBody =>
      'Devuelve la llamada a un número en el que ya confías — nunca al número que acaba de llamarte.';

  @override
  String get callTrustedContact => 'Llamar a contacto de confianza';

  @override
  String get sendDemoFamilyAlert => 'Enviar alerta familiar demo';

  @override
  String get familyAlertSent => 'Alerta demo difundida a la familia';

  @override
  String get familySafePhrase =>
      'Consejo: acuerda una frase de seguridad familiar fuera de línea — pídela a quien llama.';

  @override
  String get viewIncidentReport => 'Ver informe de incidente';

  @override
  String get incidentLogged => 'Llamada de alto riesgo registrada';

  @override
  String get postCallNoFlags =>
      'No se marcaron patrones de alto riesgo durante esta llamada.';

  @override
  String get postCallSessionSummary => 'RESUMEN DE SESIÓN';

  @override
  String get postCallFamilyShield => 'FAMILY SHIELD';

  @override
  String get postCallFamilyDemoNote =>
      'Modo Demo — envía una alerta simulada a contactos demo; no se entrega ninguna notificación real.';

  @override
  String get postCallFamilyPrompt =>
      'Pide a alguien de confianza un segundo par de ojos — envíale una alerta de Family Shield.';

  @override
  String get postCallSendFamilyAlert => 'Enviar alerta familiar';

  @override
  String get postCallSendFamilyAlertDesc =>
      'Envía una alerta de Family Shield a personas de tu Círculo de Confianza';

  @override
  String get verifyStepCall =>
      'Llama a la persona a un número guardado y de confianza.';

  @override
  String get verifyStepPhrase =>
      'Pide tu frase de seguridad familiar si tienes dudas.';

  @override
  String sheetScoreSummary(String headline, int score) {
    return '$headline Puntuación de amenaza: $score/100.';
  }

  @override
  String get incidentsTitle => 'Incidentes';

  @override
  String get incidentEmptyTitle => 'No hay incidentes registrados';

  @override
  String get incidentEmptyBody =>
      'Las sesiones marcadas y grabaciones analizadas aparecerán aquí como registro de seguridad.';

  @override
  String get bandPartial => 'ANÁLISIS PARCIAL';

  @override
  String get bandHigh => 'ALTO RIESGO';

  @override
  String get bandCritical => 'CRÍTICO / ALTO RIESGO';

  @override
  String get bandSuspicious => 'SOSPECHOSO';

  @override
  String get bandSafe => 'SEGURO';

  @override
  String incidentPartialSummary(int score) {
    return 'Anomalía acústica $score/100 — riesgo de conversación sin analizar';
  }

  @override
  String get incidentNoThreats => 'Sin amenazas significativas detectadas';

  @override
  String incidentReasonsDetected(int count) {
    return '$count detectadas';
  }

  @override
  String get incidentDeleteTitle => '¿Eliminar este incidente?';

  @override
  String incidentDeleteBody(String id) {
    return '$id se eliminará permanentemente de este dispositivo. No se puede deshacer.';
  }

  @override
  String get incidentDeleteTooltip => 'Eliminar incidente';

  @override
  String get incidentDeleteFailed =>
      'No se pudo eliminar este incidente. Inténtalo de nuevo.';

  @override
  String get incidentCopied => 'Informe de incidente copiado al portapapeles.';

  @override
  String get incidentFamilyResponses => 'RESPUESTAS DE FAMILY SHIELD';

  @override
  String familyMarkedSafe(String name) {
    return '$name marcó la situación como segura';
  }

  @override
  String familyStillConcerned(String name) {
    return '$name sigue preocupado';
  }

  @override
  String get incidentRecommended => 'PRÓXIMOS PASOS RECOMENDADOS';

  @override
  String get incidentTechnicalEvidence => 'EVIDENCIA TÉCNICA';

  @override
  String get incidentAudioSha => 'SHA-256 DE AUDIO';

  @override
  String get incidentAcousticSignals => 'SEÑALES DE ANOMALÍA ACÚSTICA';

  @override
  String get metricSpectralFlux => 'Flujo espectral';

  @override
  String get metricSpectralRolloff => 'Corte espectral';

  @override
  String get metricZeroCrossing => 'Tasa de cruces por cero';

  @override
  String get metricAcousticScore => 'Puntuación de anomalía acústica';

  @override
  String get incidentSemanticSignals => 'SEÑALES DE AMENAZA SEMÁNTICA';

  @override
  String get semUrgency => 'URGENCIA';

  @override
  String get semFinancial => 'FINANCIERO';

  @override
  String get semSecrecy => 'SECRETISMO';

  @override
  String get incidentTranscriptTimeline => 'LÍNEA DE TIEMPO DE TRANSCRIPCIÓN';

  @override
  String get incidentNoTranscript => 'Sin transcripción capturada.';

  @override
  String get incidentBroadcast => 'Difundir a Family Shield';

  @override
  String get incidentBroadcastDemoNote =>
      'Modo Demo — no se envía ninguna notificación real';

  @override
  String get incidentShare => 'Compartir informe de incidente';

  @override
  String incidentScoreLine(int score) {
    return '$score/100';
  }

  @override
  String get acousticAnomalyPrefix => 'Anomalía acústica ';

  @override
  String get analyzeRecordingTitle => 'Analizar grabación';

  @override
  String get recordingStepTitle =>
      'Analiza una grabación de llamada o nota de voz';

  @override
  String get recordingFormats =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — hasta 25 MB o 15 minutos.';

  @override
  String get recordingChooseAudio => 'Elegir audio';

  @override
  String get recordingPrivacyLabel => 'PRIVACIDAD';

  @override
  String get recordingKeepLocal => 'Mantener audio en este dispositivo';

  @override
  String get recordingKeepLocalDesc =>
      'El análisis acústico se ejecuta localmente. Nada se sube.';

  @override
  String get recordingIncludeConversation => 'Incluir análisis de conversación';

  @override
  String get recordingCloudNotConfigured =>
      'La transcripción en la nube no está configurada en esta compilación. El análisis acústico sigue disponible en el dispositivo.';

  @override
  String get recordingCancelAnalysis => 'Cancelar análisis';

  @override
  String get recordingAnalyzeAction => 'Analizar grabación';

  @override
  String get recordingChooseDifferent => 'Elegir otro archivo';

  @override
  String get recordingViewIncident => 'Ver informe de incidente';

  @override
  String get recordingAnalyzeAnother => 'Analizar otra grabación';

  @override
  String get recordingMetaFormat => 'Formato';

  @override
  String get recordingMetaSize => 'Tamaño';

  @override
  String get recordingMetaDuration => 'Duración';

  @override
  String get recordingSentinelBadge => 'SENTINEL';

  @override
  String get recordingManualTranscript =>
      'Añadir texto de transcripción en su lugar';

  @override
  String get recordingManualTranscriptLabel =>
      'TRANSCRIPCIÓN PROPORCIONADA POR EL USUARIO';

  @override
  String get recordingManualTranscriptHint =>
      'Pega texto de transcripción que ya tengas — permanece en este dispositivo.';

  @override
  String get recordingStagePreparing => 'Preparando audio';

  @override
  String get recordingStageAcoustic => 'Analizando señales acústicas';

  @override
  String get recordingStageUploading => 'Subiendo para transcripción';

  @override
  String get recordingStageTranscribing => 'Transcribiendo conversación';

  @override
  String get recordingStageEvaluating => 'Evaluando riesgo de conversación';

  @override
  String get recordingStageBuilding => 'Construyendo resultado';

  @override
  String get recordingThreatScore => 'Puntuación de amenaza';

  @override
  String get recordingConvNotAnalyzed => 'SEÑAL DE CONVERSACIÓN · SIN ANALIZAR';

  @override
  String get recordingAcousticSignals => 'SEÑALES DE ANOMALÍA ACÚSTICA';

  @override
  String get recordingAcousticScore => 'Puntuación de anomalía acústica';

  @override
  String get recordingMetricFlux => 'Flujo espectral';

  @override
  String get recordingMetricRolloff => 'Corte espectral';

  @override
  String get recordingMetricZcr => 'Tasa de cruces por cero';

  @override
  String get recordingTranscriptLabel => 'TRANSCRIPCIÓN DE GRABACIÓN';

  @override
  String get recordingVerifyTitle => 'VERIFICA ANTES DE ACTUAR';

  @override
  String get recordingVerifyBody =>
      'Esta es una comprobación solo acústica — la conversación misma no fue analizada. Nunca confíes en un resultado parcial para decidir que una grabación es segura: verifica a quien habla por un canal en el que ya confíes.';

  @override
  String get stepPickRecording => 'ELIGE UNA GRABACIÓN';

  @override
  String get stepPrivacyDepth => 'ELIGE EL NIVEL DE PRIVACIDAD';

  @override
  String get stepAnalyze => 'ANALIZA';

  @override
  String get stepResult => 'ENTIENDE EL RESULTADO';

  @override
  String get familyAlertTitle => 'Alerta de Family Shield';

  @override
  String familyAlertAcoustic(String name) {
    return '$name te pidió verificar una advertencia acústica elevada de una grabación.';
  }

  @override
  String familyAlertHighRisk(String name) {
    return '$name puede estar lidiando con una llamada de alto riesgo.';
  }

  @override
  String familyAlertSuspicious(String name) {
    return '$name recibió una advertencia de llamada sospechosa de PauseSignal.';
  }

  @override
  String get familyMarkedSafeNote =>
      'Marcado como seguro tras verificación independiente.';

  @override
  String get familyStillSuspiciousNote =>
      'Sigue siendo sospechoso — continúa la verificación.';

  @override
  String familyUpdateFailed(String localCopy) {
    return '$localCopy No se pudo enviar la actualización familiar — revisa tu conexión.';
  }

  @override
  String get familyBandAlert => 'ALERTA';

  @override
  String get familyVerifyDirectly => 'Verifica directamente';

  @override
  String familyVerifyCall(String name) {
    return 'Llama a $name al número de confianza que guardaste — no a un número dado por quien llamó de forma sospechosa.';
  }

  @override
  String get familyVerifyChannel =>
      'Verifica por un canal en el que ya confíes. No actúes según instrucciones solo de la alerta.';

  @override
  String familyCallAction(String name) {
    return 'Llamar a $name';
  }

  @override
  String familyCallActionUnknown(String name) {
    return 'Llamar a $name';
  }

  @override
  String get familyCallContact => 'Llamar al contacto';

  @override
  String get familyNoTrustedNumber =>
      'Sin número de confianza guardado. Contáctales por un número en el que ya confíes.';

  @override
  String get familyMarkSafe => 'Marcar seguro';

  @override
  String get familyStillSuspicious => 'Sigue siendo sospechoso';

  @override
  String get familyTipNoMoney => 'No envíes dinero ni tarjetas de regalo.';

  @override
  String get familyTipNoCodes => 'No compartas OTP, PIN ni datos bancarios.';

  @override
  String get familyTipChannel => 'Verifica por otro canal independiente.';

  @override
  String get familyTipAuthorities =>
      'Contacta a su banco, operadora o autoridades locales si es necesario.';

  @override
  String get familyDetailsTitle => 'Detalles';

  @override
  String familyDetailsBody(String incident, String time, String status) {
    return 'Incidente $incident\nRecibido $time\n$status';
  }

  @override
  String get familyStatusSafe => 'Seguro tras verificación';

  @override
  String get familyStatusSuspicious => 'Sigue siendo sospechoso';

  @override
  String get familyStatusUnresolved => 'Sin resolver';

  @override
  String get familyPrivacyNote =>
      'Privacidad: solo se compartieron una identidad de dispositivo opaca y un nivel de riesgo. Las alertas de Family Shield no incluyen audio, transcripción, nombres ni números de teléfono.';

  @override
  String get familyUpdateTitle => 'Actualización de Family Shield';

  @override
  String familyUpdateMarkedSafe(String who) {
    return '$who marcó la situación como segura';
  }

  @override
  String familyUpdateConcerned(String who) {
    return '$who sigue preocupado';
  }

  @override
  String familyUpdateHumanNote(String incident) {
    return 'Esta es una actualización de verificación humana — no cambia la evaluación de riesgo de la IA.\n\nIncidente $incident';
  }

  @override
  String get familyAlertReceived => 'Alerta de Family Shield recibida';

  @override
  String get familyAlertFraming =>
      'Alguien que conoces pide un segundo par de ojos.';

  @override
  String get yourJudgment => 'TU CRITERIO';

  @override
  String get humanResponseNote =>
      'Tu llamada es la verificación — no la app. Marcar seguro o sospechoso es una respuesta humana; no cambia el análisis de riesgo.';

  @override
  String get familyReceiverTitle => 'Receptor de Family Shield';

  @override
  String get familyReceiverDesc =>
      'Recibe una alerta cuando alguien de tu círculo de confianza enfrente una llamada de alto riesgo.';

  @override
  String get familyReceiverShareHint =>
      'Comparte este ID solo con quien quieras recibir alertas de Family Shield.';

  @override
  String get familyReceiverEnable => 'Activar alertas familiares';

  @override
  String get familyReceiverOpenSettings => 'Abrir ajustes del sistema';

  @override
  String get familyReceiverNotConfigured =>
      'Configuración push no disponible — ONESIGNAL_APP_ID no configurado en esta compilación.';

  @override
  String get familyReceiverDevRecipient =>
      'DEV · Destinatario de alerta de prueba';

  @override
  String get familyReceiverSetTest => 'Establecer destinatario de prueba';

  @override
  String get familyStateReady => 'Listo para recibir alertas';

  @override
  String get familyStateRegistering => 'Registrando…';

  @override
  String get familyStateNeedPermission =>
      'Se necesita permiso de notificaciones';

  @override
  String get familyStateBlocked =>
      'Notificaciones bloqueadas — actívalas en los ajustes del sistema';

  @override
  String get familyStateNotConfigured => 'Push no configurado';

  @override
  String get familyStateUnsupported => 'No compatible con esta plataforma';

  @override
  String familyStateError(String detail) {
    return 'Error de registro$detail';
  }

  @override
  String get familyShieldIdLabel => 'ID de Family Shield';

  @override
  String get familyShieldIdCopy => 'Copiar ID de Family Shield';

  @override
  String get familyShieldIdCopiedShort => 'ID de Family Shield copiado';

  @override
  String get trustedCircleTitle => 'Círculo de Confianza';

  @override
  String trustedCircleCount(int count, String max) {
    return '$count de $max';
  }

  @override
  String get trustedCircleDesc =>
      'Las personas a quienes pedir un segundo par de ojos. Las alertas les llegan por ID de Family Shield — los números de teléfono permanecen en este dispositivo.';

  @override
  String get trustedNoPhone => ' · sin teléfono';

  @override
  String get trustedPhoneStored => ' · teléfono guardado';

  @override
  String get trustedPhoneNone => ' · sin teléfono';

  @override
  String get trustedAddTitle => 'Añadir persona de confianza';

  @override
  String get trustedEditTitle => 'Editar persona';

  @override
  String get trustedFindIdHint =>
      'Pueden encontrar su ID de Family Shield en su propia app en Ajustes → Receptor de Family Shield.';

  @override
  String get trustedNameField => 'Nombre';

  @override
  String get trustedShieldIdField => 'ID de Family Shield';

  @override
  String get trustedPhoneField => 'Teléfono de confianza (opcional)';

  @override
  String get paywallTitle => 'Dos señales.\nUna decisión humana.';

  @override
  String get paywallSubtitle =>
      'PauseSignal marca el riesgo — tú verificas. Los planes pagos amplían lo que las dos señales pueden ver.';

  @override
  String get securityBadge => 'Facturación gestionada por tu tienda de apps';

  @override
  String get demoStoreBadge => 'TIENDA DEMO';

  @override
  String get demoStoreNotice =>
      'Pago simulado — no ocurrirá ningún cargo real.';

  @override
  String get testStoreBadge => 'REVENUECAT TEST STORE';

  @override
  String get testStoreNotice =>
      'Las compras se procesan por la Test Store oficial de RevenueCat — verificadas por RevenueCat, sin cargos de dinero real.';

  @override
  String get storeUnavailableNotice =>
      'Las suscripciones no están configuradas en esta compilación.';

  @override
  String get monthly => 'Mensual';

  @override
  String get annual => 'Anual';

  @override
  String get mostPopular => 'MÁS POPULAR';

  @override
  String get upgradeNow => 'Mejorar ahora';

  @override
  String get continueFree => 'Continuar gratis';

  @override
  String get subscribeNow => 'Suscribirse';

  @override
  String get activateDemoPlan => 'Activar plan demo';

  @override
  String get demoPlanActivated => 'Plan demo activado — sin cargo real';

  @override
  String get noPurchasesRestored => 'No se encontraron compras activas.';

  @override
  String get terms => 'Términos de servicio';

  @override
  String get privacy => 'Política de privacidad';

  @override
  String get restore => 'Restaurar compras';

  @override
  String get upgradeTooltip => 'Ver planes';

  @override
  String get plansLoadError => 'No se pudieron cargar los planes.';

  @override
  String get planNotAvailable => 'Ese plan no está disponible en esta tienda.';

  @override
  String get prefSaveFailed =>
      'No se pudo guardar este ajuste — inténtalo de nuevo.';

  @override
  String planActivated(String name) {
    return '$name activado — protección mejorada';
  }

  @override
  String get planFreeLabel => 'Gratis';

  @override
  String get planNotAvailableShort => 'No disponible';

  @override
  String get planFreeBadge => 'NIVEL GRATIS';

  @override
  String get planSentinelBadge => 'SENTINEL ACTIVO';

  @override
  String get planFamilyBadge => 'FAMILY VAULT ACTIVO';

  @override
  String get tierQuickCheck => 'Quick Check';

  @override
  String get tierQuickCheckTag => 'Herramientas de seguridad locales';

  @override
  String get tierQuickCheckF1 =>
      'Monitoreo de anomalías acústicas por micrófono en vivo';

  @override
  String get tierQuickCheckF2 => 'Análisis de grabaciones en el dispositivo';

  @override
  String get tierQuickCheckF3 =>
      'Comprobación de transcripción manual — analizada localmente';

  @override
  String get tierQuickCheckF4 => 'Historial de incidentes local';

  @override
  String get tierQuickCheckF5 => 'Recibe y responde alertas de Family Shield';

  @override
  String get tierSentinel => 'Sentinel Shield';

  @override
  String get tierSentinelTag => 'Protección consciente de la conversación';

  @override
  String get tierSentinelF1 => 'Todo lo de Quick Check';

  @override
  String get tierSentinelF2 =>
      'Transcripción automática de Live Mic y de grabaciones mejorada — cuando la infraestructura está configurada';

  @override
  String get tierSentinelF3 =>
      'Análisis de riesgo de conversación respaldado por transcripción';

  @override
  String get tierSentinelF4 => 'Puntuación de amenaza fusionada multiseñal';

  @override
  String get tierFamily => 'Family Vault';

  @override
  String get tierFamilyTag => 'El ciclo de verificación humana';

  @override
  String get tierFamilyF1 => 'Todo lo de Sentinel Shield';

  @override
  String get tierFamilyF2 =>
      'Envía alertas de Family Shield a tu Círculo de Confianza';

  @override
  String get tierFamilyF3 =>
      'Hasta 5 contactos de confianza guardados localmente';

  @override
  String get tierFamilyF4 => 'Las respuestas de seguridad regresan en privado';

  @override
  String get familyVaultUnlocksAlerts =>
      'Family Vault te permite enviar alertas de seguridad a tu Círculo de Confianza.';

  @override
  String get acousticProtectionActive =>
      'Protección acústica activa. El análisis de conversación con transcripción se desbloquea con Sentinel Shield.';

  @override
  String currentPlan(String tier) {
    return 'Plan actual: $tier';
  }

  @override
  String get currentPlanDemo => ' (demo)';

  @override
  String get currentPlanTestStore => ' (tienda de prueba)';

  @override
  String get viewPlans => 'Ver planes';

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get purchasesRestored => 'Compras restauradas.';

  @override
  String get purchasesRestoreFailed =>
      'No se pudieron restaurar las compras ahora.';

  @override
  String get subscriptionSection => 'Suscripción';

  @override
  String get demoStoreSection => 'TIENDA DEMO';

  @override
  String get testStoreSection => 'REVENUECAT TEST STORE';

  @override
  String get billingMonthly => 'Mensual';

  @override
  String get billingAnnual => 'Anual';

  @override
  String get priceSuffixMonthly => '/mes';

  @override
  String get priceSuffixAnnual => '/año';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionProfile => 'PERFIL';

  @override
  String get settingsSectionAppearance => 'APARIENCIA';

  @override
  String get settingsSectionSafety => 'SEGURIDAD Y FAMILIA';

  @override
  String get settingsSectionNotifications => 'NOTIFICACIONES';

  @override
  String get settingsSectionSubscription => 'SUSCRIPCIÓN';

  @override
  String get settingsSectionAbout => 'ACERCA DE Y PRIVACIDAD';

  @override
  String get settingsDisplayName => 'Nombre para mostrar';

  @override
  String get settingsDisplayNameNone => 'Sin definir';

  @override
  String get settingsDisplayNameHint => '¿Cómo te llamamos?';

  @override
  String get settingsDisplayNameNote =>
      'Se guarda solo en este dispositivo — nunca se comparte.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageEn => 'English';

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEs => 'Español';

  @override
  String get languageFr => 'Français';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsAccent => 'Acento';

  @override
  String get accentPeriwinkle => 'Bígaro';

  @override
  String get accentSoftBlue => 'Azul suave';

  @override
  String get accentSoftViolet => 'Violeta suave';

  @override
  String get settingsTextSize => 'Tamaño de texto';

  @override
  String get textSizeSystem => 'Sistema';

  @override
  String get textSizeLarge => 'Grande';

  @override
  String get textSizeExtraLarge => 'Extra grande';

  @override
  String get textSizeNote =>
      'Nunca menor que el ajuste de accesibilidad de tu dispositivo.';

  @override
  String get settingsExperience => 'Experiencia';

  @override
  String get experienceStandard => 'Estándar';

  @override
  String get experienceGuided => 'Guiada';

  @override
  String get experienceGuidedDesc =>
      'Acciones más grandes, guía más clara, menos detalle técnico al inicio.';

  @override
  String get settingsMotion => 'Movimiento';

  @override
  String get motionSystem => 'Seguir sistema';

  @override
  String get motionReduced => 'Reducido';

  @override
  String get motionNote =>
      'El movimiento reducido pausa la animación ambiental. Los cambios de riesgo siempre son visibles.';

  @override
  String get settingsHaptics => 'Vibración';

  @override
  String get hapticsOn => 'Activada';

  @override
  String get hapticsOff => 'Desactivada';

  @override
  String get settingsFamilyStatus => 'Alertas de Family Shield';

  @override
  String get settingsNotificationState => 'Permiso de notificaciones';

  @override
  String get notifStateGranted => 'Permitido';

  @override
  String get notifStateDenied =>
      'Desactivado — actívalo en ajustes del dispositivo';

  @override
  String get notifStateUnknown => 'No determinado';

  @override
  String get settingsNotificationNote =>
      'El sonido y la entrega de notificaciones los controlan los ajustes de notificaciones de tu dispositivo.';

  @override
  String get settingsOpenNotifSettings => 'Abrir ajustes de notificaciones';

  @override
  String get settingsHowItWorks => 'Cómo funciona';

  @override
  String get settingsAnalysisLangs =>
      'El análisis de riesgo de conversación admite actualmente inglés y árabe egipcio. El idioma de la interfaz de la app puede cambiarse de forma independiente.';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsLocalOnly =>
      'Tu nombre, idioma y preferencias de apariencia permanecen en este dispositivo.';

  @override
  String get msgFamilyShieldDisabled => 'Family Shield está desactivado.';

  @override
  String get msgNeedTrustedContact =>
      'Añade a alguien a tu Círculo de Confianza antes de enviar una alerta de Family Shield.';

  @override
  String msgDemoAlertBroadcast(int count) {
    return 'Alerta demo difundida a $count familiar(es).';
  }

  @override
  String msgAlertAccepted(int count) {
    return 'Alerta aceptada para entrega a $count familiar(es).';
  }

  @override
  String msgRelayRejected(int code) {
    return 'El relé rechazó la alerta ($code).';
  }

  @override
  String msgServiceUnavailable(int code) {
    return 'Servicio de alertas no disponible ($code).';
  }

  @override
  String get msgNetworkAlert => 'Error de red — no se pudo enviar la alerta.';

  @override
  String get msgNetworkResponse =>
      'Error de red — no se pudo enviar la respuesta.';

  @override
  String get msgChooseResponse =>
      'Elige Seguro o Sigue siendo sospechoso antes de responder.';

  @override
  String get msgInvalidTarget =>
      'El destino de la respuesta no es un ID de Family Shield válido.';

  @override
  String get msgDemoResponse =>
      'Demo — respuesta simulada, nada salió de este dispositivo.';

  @override
  String get msgFamilyUpdateSent => 'Actualización familiar enviada.';

  @override
  String get msgCircleFull =>
      'El Círculo de Confianza está lleno (5 personas). Quita a alguien primero.';

  @override
  String get msgDuplicateContact =>
      'Ese ID de Family Shield ya está en tu Círculo de Confianza.';

  @override
  String get msgNameRequired => 'El nombre es obligatorio.';

  @override
  String get msgInvalidShieldId =>
      'El destino de la respuesta no es un ID de Family Shield válido.';

  @override
  String get msgPhoneTooLong => 'El número de teléfono es demasiado largo.';

  @override
  String get msgDemoReadOnly => 'Los contactos demo son de solo lectura';

  @override
  String get msgPushSetupFailed =>
      'La configuración push falló en este dispositivo.';

  @override
  String get msgPushLinkFailed => 'No se pudo vincular tu ID de Family Shield.';

  @override
  String get msgPushEnableFailed =>
      'No se pudieron activar las alertas push. Inténtalo de nuevo.';

  @override
  String get msgPushStateFailed => 'No se pudo leer el estado push.';

  @override
  String get msgMicUnsupported =>
      'La captura de micrófono no es compatible con esta plataforma. Prueba el Modo Demo.';

  @override
  String get msgMicBlocked =>
      'El acceso al micrófono está bloqueado. Actívalo en ajustes del sistema, o usa el Modo Demo.';

  @override
  String get msgMicDenied =>
      'Se denegó el permiso de micrófono. Concédelo para usar Live Mic, o usa el Modo Demo.';

  @override
  String get msgMicFailed =>
      'El micrófono no pudo iniciarse. Revisa el dispositivo y reintenta, o usa el Modo Demo.';

  @override
  String get msgFileEmpty => 'Ese archivo parece estar vacío.';

  @override
  String get msgFileTooLarge =>
      'Ese archivo es demasiado grande — se admiten grabaciones de hasta 25 MB.';

  @override
  String get msgFileTooLong =>
      'Esa grabación es demasiado larga — se admiten hasta 15 minutos.';

  @override
  String get msgFileNoAudio =>
      'La grabación decodificó sin audio — nada que analizar.';

  @override
  String get msgEmptyTranscript =>
      'El proveedor devolvió una transcripción vacía.';

  @override
  String get msgTranscriptionFailed =>
      'El proveedor de transcripción no pudo procesar el audio.';

  @override
  String get msgTranscriptionTimeout =>
      'La transcripción agotó el tiempo — el resultado acústico sigue disponible.';

  @override
  String get msgCloudNotConfigured =>
      'La transcripción en la nube no está configurada en esta compilación. El análisis acústico sigue disponible en el dispositivo.';

  @override
  String get msgEnhancedLocked =>
      'La transcripción mejorada de grabaciones está incluida con Sentinel Shield. El análisis acústico en el dispositivo sigue disponible.';

  @override
  String get msgSubsNotConfigured =>
      'Las suscripciones no están configuradas en esta compilación.';

  @override
  String get msgSubsInitFailed =>
      'No se pudieron inicializar las suscripciones.';

  @override
  String get msgPlansLoadFailed =>
      'No se pudieron cargar los planes de la tienda.';

  @override
  String get msgPurchaseFailed => 'No se pudo completar la compra.';

  @override
  String get msgNoConnection =>
      'Sin conexión — revisa tu red e inténtalo de nuevo.';

  @override
  String get msgStoreUnavailable =>
      'La tienda no está disponible ahora. Inténtalo más tarde.';

  @override
  String get msgPurchaseNotAllowed =>
      'Las compras no están permitidas en este dispositivo o cuenta.';

  @override
  String get msgPurchasePending => 'El pago está pendiente de aprobación.';

  @override
  String get msgRestoreFailed => 'No se pudieron restaurar las compras ahora.';

  @override
  String get msgNoPaidPlans =>
      'Aún no hay planes pagos disponibles en esta tienda.';

  @override
  String get msgPurchasePendingActivation =>
      'La compra aún no activó un plan — puede tardar un momento. Usa Restaurar compras para comprobar de nuevo.';

  @override
  String get msgDemoCheckoutFailed =>
      'El pago demo falló — inténtalo de nuevo.';

  @override
  String get msgTokenFailed =>
      'No se pudo preparar la transcripción — inténtalo de nuevo.';

  @override
  String get reasonFinancial =>
      'Exigencia de transferencia financiera detectada';

  @override
  String get reasonSecrecy => 'Presión de secretismo y aislamiento';

  @override
  String get reasonUrgency => 'Tácticas de manipulación por urgencia';

  @override
  String reasonImpersonation(String claim) {
    return 'Afirmación de suplantación de identidad: «$claim»';
  }

  @override
  String get reasonAcoustic => 'Indicadores de anomalía acústica elevados';

  @override
  String get reasonCoordinated => 'Patrón de estafa coordinado — amplificado';

  @override
  String get reasonNone => 'Sin indicadores de amenaza significativos';

  @override
  String get actionContinueMonitoring => 'Continuar monitoreando';

  @override
  String get actionAdviseCaution =>
      'Aconsejar precaución — verificar identidad de quien llama';

  @override
  String get actionEndCall =>
      'Terminar la llamada de inmediato y avisar a un contacto de confianza';

  @override
  String get actionEndCallShort => 'Terminar la llamada de inmediato';

  @override
  String get actionNoCodes => 'No compartas OTP, PIN ni datos bancarios';

  @override
  String get actionVerifyChannel =>
      'Verifica a quien llama por un canal oficial';

  @override
  String get actionReport => 'Reporta el número a tu operadora o autoridades';

  @override
  String get actionEnableFamily =>
      'Activa alertas de Family Shield para familiares';

  @override
  String get actionNoTimeOffers =>
      'No actúes ante ofertas de tiempo limitado bajo presión';

  @override
  String get evidenceImpersonation => 'Suplantación';

  @override
  String get evidenceMoney => 'Pedido de dinero';

  @override
  String get evidenceUrgency => 'Urgencia';

  @override
  String get evidenceSecrecy => 'Secretismo';

  @override
  String get sourceLiveMic => 'Micrófono en vivo';

  @override
  String get sourceLiveMicSession => 'Sesión de micrófono en vivo';

  @override
  String get sourceDemoAudio => 'Audio demo generado';

  @override
  String get sourceDemoTranscript => 'Transcripción demo local';

  @override
  String get sourceUserTranscript =>
      'Transcripción proporcionada por el usuario';

  @override
  String get sourceUploadedRecording => 'Grabación subida';

  @override
  String get sourceRecording => 'Grabación';

  @override
  String get sourceAssemblyAiPrerecorded => 'AssemblyAI pregrabado';

  @override
  String get sourceAssemblyAiStreaming => 'AssemblyAI en vivo';

  @override
  String get sourceNoneAcoustic => 'Ninguna — solo análisis acústico';

  @override
  String get callerUnknown => 'Llamada desconocida (+20 10 ••• ••42)';

  @override
  String get callerSuspicious => 'Contacto sospechoso (+1 888 ••• 0112)';

  @override
  String get reportDisclaimer =>
      'Telemetría forense generada por IA. No es una determinación legal ni judicial.';

  @override
  String get reportAnalysisPartial =>
      'Análisis: parcial — solo señales acústicas';

  @override
  String reportAcousticScore(int score) {
    return 'Puntuación de anomalía acústica: $score/100';
  }

  @override
  String get reportConvNotAnalyzed =>
      'No se analizaron las señales de riesgo de la conversación.';

  @override
  String reportRiskLine(String risk, int score) {
    return 'Riesgo: $risk — Puntuación de amenaza: $score/100';
  }

  @override
  String reportIdLine(String id) {
    return 'ID: $id';
  }

  @override
  String reportTimeLine(String time) {
    return 'Hora: $time';
  }

  @override
  String reportCallerLine(String caller) {
    return 'Quien llama: $caller';
  }

  @override
  String reportDurationLine(String duration) {
    return 'Duración: $duration';
  }

  @override
  String reportSignalsLine(String reasons) {
    return 'Señales: $reasons';
  }

  @override
  String reportAudioSourceLine(String source) {
    return 'Fuente de audio: $source';
  }

  @override
  String reportTranscriptionLine(String source) {
    return 'Transcripción: $source';
  }

  @override
  String reportShaLine(String sha) {
    return 'SHA-256 de audio: $sha';
  }

  @override
  String get elevatedAcousticSummary =>
      'Anomalías acústicas elevadas — señales de riesgo de conversación sin analizar';

  @override
  String get demoTranscript1 =>
      'Esto es urgente — actúa ahora antes de que expire la oferta.';

  @override
  String get demoTranscript2 => 'No le digas a nadie hasta que esté hecho.';

  @override
  String get metricAcousticAnomaly => 'Puntuación de anomalía acústica';

  @override
  String get recordingFormatsHint =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — hasta 25 MB o 15 minutos.';

  @override
  String get recordingAcousticScoreLabel => 'Puntuación de anomalía acústica';

  @override
  String get recordingVerifyNormalBody =>
      'Una puntuación es una señal de riesgo, no una prueba. Verifica a quien habla por un número que ya conozcas — nunca uno proporcionado en la grabación — antes de actuar ante cualquier petición.';

  @override
  String familyVerifyKnownSender(String name) {
    return 'Llama a $name al número de confianza que guardaste, no a un número que haya dado la persona sospechosa.';
  }

  @override
  String get familyVerifyUnknownSender =>
      'Verifica por un canal en el que ya confíes. No actúes solo por las instrucciones de la alerta.';

  @override
  String get familyResolutionSafe => 'Seguro tras verificación';

  @override
  String get familyResolutionStillSuspicious => 'Sigue siendo sospechoso';

  @override
  String get familyResolutionUnresolved => 'Sin resolver';

  @override
  String familyResolutionLabel(String status) {
    return 'Resolución: $status';
  }

  @override
  String get familyReceiverReady => 'Listo para recibir alertas';

  @override
  String get familyReceiverShareNote =>
      'Comparte este ID solo con quien quieras que reciba tus alertas de Family Shield.';

  @override
  String get familyShieldIdCopyTooltip => 'Copiar ID de Family Shield';

  @override
  String get msgFamilyDisabled => 'Family Shield está desactivado.';

  @override
  String msgAlertDelivered(int count) {
    return 'Alerta aceptada para entrega a $count miembro(s) de la familia.';
  }

  @override
  String get msgFamilyIdInvalid =>
      'El ID de Family Shield debe tener el formato vg_ seguido de 32 caracteres hexadecimales. Pide a tu familiar que lo copie desde su app (Ajustes → Receptor de Family Shield).';

  @override
  String get msgMicStartFailed =>
      'El micrófono no pudo iniciarse. Revisa el dispositivo y reintenta, o usa el modo demo.';

  @override
  String get scoreUrgency => 'URGENCIA';

  @override
  String get scoreFinancial => 'FINANCIERO';

  @override
  String get scoreSecrecy => 'SECRETO';

  @override
  String get demoBadgeCompact => 'DEMO';

  @override
  String get postCallDemoAlertDesc =>
      'Modo demo: envía una alerta simulada a contactos de prueba; no se entrega ninguna notificación real.';

  @override
  String get postCallAskTrustDesc =>
      'Pide una segunda opinión a alguien de confianza: envíale una alerta de Family Shield.';

  @override
  String get recordingConversationAbsent =>
      'SEÑAL DE CONVERSACIÓN · NO ANALIZADA';

  @override
  String msgDemoAlertDelivered(int count) {
    return 'Alerta de demo emitida a $count miembro(s) de la familia.';
  }

  @override
  String msgResponseRejected(int code) {
    return 'El relé rechazó la respuesta ($code).';
  }

  @override
  String msgAlertUnavailable(int code) {
    return 'Servicio de alertas no disponible ($code).';
  }

  @override
  String get msgAlertNetworkError =>
      'Error de red: no se pudo enviar la alerta.';

  @override
  String get msgResponseNetworkError =>
      'Error de red: no se pudo enviar la respuesta.';

  @override
  String get msgResolutionRequired =>
      'Elige Seguro o Sigue siendo sospechoso antes de responder.';

  @override
  String get msgDemoResponseSent =>
      'Demo: respuesta simulada, nada salió de este dispositivo.';

  @override
  String get pushAlertBodyHigh =>
      'Se marcó una llamada de alto riesgo en un dispositivo monitoreado. Verifica directamente con tu familiar antes de mover fondos.';

  @override
  String get pushAlertBodySuspicious =>
      'Se marcó una advertencia de llamada sospechosa en un dispositivo monitoreado. Verifica directamente con tu familiar antes de mover fondos.';

  @override
  String get pushAlertBodyPartial =>
      'Se marcaron señales acústicas elevadas en una grabación de un dispositivo monitoreado. Las señales de riesgo de la conversación no se analizaron: verifica directamente con tu familiar.';

  @override
  String get familyReceiverTestDeviceHint =>
      'vg_… id externo del dispositivo de prueba';

  @override
  String get verifyStepHangup => 'Cuelga — no envíes dinero.';

  @override
  String familyUpdateIncidentId(String id) {
    return 'Incidente $id';
  }

  @override
  String familyUpdateReceivedAt(String time) {
    return 'Recibido $time';
  }
}
