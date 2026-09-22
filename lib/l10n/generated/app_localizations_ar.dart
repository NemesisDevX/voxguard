// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'VoxGuard';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get actionDone => 'تم';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionSkip => 'تخطي الآن';

  @override
  String get actionSkipSetup => 'تخطي';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionRemove => 'إزالة';

  @override
  String get actionCopy => 'نسخ';

  @override
  String get actionView => 'عرض';

  @override
  String get actionOpenSystemSettings => 'فتح إعدادات النظام';

  @override
  String get actionCopyId => 'نسخ المعرف';

  @override
  String get actionAddPerson => 'إضافة شخص';

  @override
  String get howItWorksTitle => 'كيف يعمل VoxGuard';

  @override
  String get exploreApp => 'استكشاف VoxGuard';

  @override
  String get unrecognizedIdentity => 'هوية VoxGuard غير معروفة';

  @override
  String get safecallIntro =>
      'يستمع VoxGuard عبر الميكروفون إلى أنماط صوتية وحوارية مريبة.';

  @override
  String get familyAlertUnknownSender =>
      'تنبيه Family Shield من هوية VoxGuard غير معروفة.';

  @override
  String get pushAlertTitle => '🚨 تنبيه VoxGuard Family Shield';

  @override
  String get incidentReportTitle => 'تقرير حادثة VoxGuard';

  @override
  String get recordingUnreadable =>
      'تعذّر على VoxGuard قراءة هذا التسجيل — قد يكون تالفًا أو بصيغة غير مدعومة.';

  @override
  String get recordingUndecodable =>
      'تعذّر على VoxGuard فكّ ترميز هذا التسجيل — قد لا تكون الصيغة مدعومة على هذا الجهاز.';

  @override
  String get recordingAnalyzerIntro =>
      'يفحص VoxGuard الشذوذات الصوتية، وعند اختيارك النسخ النصي، إشارات مخاطر المحادثة.';

  @override
  String get partialRecordingNote =>
      'لم تُحلَّل إشارات مخاطر المحادثة، لذا لا يستطيع VoxGuard إنتاج درجة تهديد كاملة.';

  @override
  String get enhancedModeLockedDesc =>
      'يضيف Sentinel Shield نسخًا نصيًا محسّنًا — يُرسَل التسجيل عبر مرحّل النسخ الخاص بـ VoxGuard فقط بعد اشتراكك. التحليل على الجهاز يبقى مجانيًا.';

  @override
  String get enhancedModeReadyDesc =>
      'لإنشاء نص مكتوب، سيُرسَل هذا التسجيل عبر مرحّل النسخ الخاص بـ VoxGuard إلى مزوّد تحويل الكلام إلى نص المُعدّ. لا يحتفظ VoxGuard بالتسجيل بشكل دائم.';

  @override
  String get onboardingSignalsBody =>
      'أثناء جلسة SafeCall التي تبدأها بنفسك، يستمع VoxGuard إلى إشارات الخطر — وليس يقين الهوية أبدًا — ويشرح ما سمعه بلغة واضحة.';

  @override
  String get onboardingNoInterception =>
      'لا يعترض VoxGuard مكالمات هاتفك الخلوية — جلسة الحماية دائمًا اختيارك.';

  @override
  String get onboardingFamilyBody =>
      'عندما تبدو المكالمة مريبة، يمكن لمن تثق بهم مساعدتك على القرار. تحصل كل نسخة من VoxGuard على معرف Family Shield مُبهم — يحفظه المقربون في دائرتهم الموثوقة لاستقبال تنبيهات الأمان الخاصة بك والرد عليها.';

  @override
  String get onboardingPrivacyMic =>
      'تُعالَج أصوات الميكروفون في الذاكرة أثناء الجلسة — لا يخزّن VoxGuard أي تسجيل صوتي أبدًا. يطلب Live Mic إذن الميكروفون فقط عندما تختاره؛ ويعمل وضع العرض بدونه.';

  @override
  String get onboardingPrivacyAlerts =>
      'تحمل تنبيهات Family Shield فقط معرف VoxGuard مُبهمًا ومرجع حادثة ومستوى خطر — لا صوت ولا نصوصًا ولا أسماء ولا أرقام هواتف أبدًا.';

  @override
  String get whyFlaggedTitle => 'لماذا أشار VoxGuard إلى هذه المكالمة';

  @override
  String get whyElevatedAcousticTitle =>
      'لماذا رصد VoxGuard إشارات صوتية مرتفعة';

  @override
  String get whyFlaggedRecordingTitle => 'لماذا أشار VoxGuard إلى هذا التسجيل';

  @override
  String get whyFlaggedCallTitle => 'لماذا أشار VoxGuard إلى هذه المكالمة';

  @override
  String get whyFlaggedItTitle => 'لماذا أشار VoxGuard إليها';

  @override
  String get welcomeTitle => 'طريقة أهدأ للرد.';

  @override
  String get welcomeSubtitle =>
      'يساعدك VoxGuard على التوقف والتحقق والبقاء مسيطرًا عندما تبدو المكالمة مريبة.';

  @override
  String get welcomeLanguageLabel => 'اختر لغتك';

  @override
  String get welcomeLanguageSystem => 'اتباع لغة الجهاز';

  @override
  String get welcomeNamePrompt => 'بماذا نناديك؟';

  @override
  String get welcomeNameHint => 'الاسم الأول أو اسم الدلع';

  @override
  String get welcomeNameNote => 'اختياري — يُحفظ على هذا الجهاز فقط.';

  @override
  String get welcomeContinue => 'متابعة';

  @override
  String get onboardingVoiceTitle => 'الصوت المألوف قد يكون مضللًا أيضًا.';

  @override
  String get onboardingVoiceBody1 =>
      'يستنسخ المحتالون الأصوات ويزوّرون الأرقام ويضغطون على من تحب. سماع صوت مألوف ليس دليلًا على هوية المتحدث.';

  @override
  String get onboardingVoiceBody2 =>
      'الاستعجال والسرية وضغط الدفع هي العلامات الحقيقية — وليس الصوت نفسه.';

  @override
  String get onboardingVoiceBody3 =>
      'معرف المتصل والصوت وحدهما لا يمكنهما إثبات الهوية أبدًا.';

  @override
  String get onboardingSignalsTitle => 'إشارتان. قرار بشري واحد.';

  @override
  String get onboardingSignalSemantic =>
      'إشارة المحادثة — الاستعجال ومطالب الدفع وضغط السرية فيما يُقال.';

  @override
  String get onboardingSignalAcoustic =>
      'إشارة الصوت — مؤشرات شذوذ؛ أسلوب مساعد تقديري وليس حكمًا جنائيًا.';

  @override
  String get onboardingSignalScore =>
      'درجة إشارة الخطر هي إشارة، وليست احتمال أن تكون المكالمة مزيفة.';

  @override
  String get onboardingVerifyTitle =>
      'عندما تشعر أن شيئًا ما خاطئ، تحقق بشكل مستقل.';

  @override
  String get onboardingVerifyBody =>
      'إشارة الخطر سبب للتوقف — وليست حكمًا. الخطوة الأقوى دائمًا بيدك:';

  @override
  String get onboardingVerifyStep1 =>
      'توقف — لا ترسل أموالًا أو رموزًا أو بيانات تحت الضغط أبدًا.';

  @override
  String get onboardingVerifyStep2 =>
      'أعد الاتصال بالشخص على رقم تثق به مسبقًا — وليس رقمًا أعطاك إياه المتصل.';

  @override
  String get onboardingVerifyStep3 =>
      'اتفق على عبارة أمان عائلية دون اتصال — اطلبها عندما تبدو المكالمة مريبة.';

  @override
  String get onboardingFamilyTitle => 'Family Shield: عيون إضافية تسندك.';

  @override
  String get onboardingFamilyBody1 =>
      'الأسماء وأرقام الهواتف الموثوقة تبقى على الجهاز الذي حفظها.';

  @override
  String get onboardingFamilyBody2 =>
      'إعداد دائرتك الموثوقة اختياري — يمكنك فعله لاحقًا من الإعدادات.';

  @override
  String get onboardingFamilyIdPending =>
      'يظهر معرف Family Shield هنا فور انتهاء التطبيق من الإعداد.';

  @override
  String onboardingYourId(String id) {
    return 'معرفك: $id';
  }

  @override
  String get familyShieldIdCopied => 'تم نسخ معرّف Family Shield';

  @override
  String get familyAlertsEnabled => 'تنبيهات العائلة مفعّلة';

  @override
  String get onboardingNotifOff =>
      'الإشعارات معطّلة — يمكنك تفعيلها لاحقًا من تطبيق الإعدادات على جهازك.';

  @override
  String get onboardingPushUnsupported =>
      'تنبيهات الدفع غير مدعومة على هذه المنصة.';

  @override
  String get onboardingPushNotConfigured =>
      'تنبيهات الدفع غير مُعدّة في هذا الإصدار.';

  @override
  String get onboardingEnablingNotif => 'جارٍ تفعيل الإشعارات…';

  @override
  String get onboardingEnableAlerts => 'تفعيل تنبيهات العائلة';

  @override
  String get onboardingPrivacyTitle => 'صوتك تحت سيطرتك.';

  @override
  String get onboardingPrivacyBody =>
      'عند إعداد النسخ السحابي، يتدفق الصوت المباشر إلى مزوّد النسخ المُعدّ لإنتاج نص للتحليل.';

  @override
  String get onboardingPrivacyLoop => 'دليل ← توقف ← تحقق ← أشخاص تثق بهم';

  @override
  String get onboardingPrivacyChoice =>
      'ابدأ جلسة SafeCall عندما تريد الحماية — أنت دائمًا من يختار Live Mic أو وضع العرض.';

  @override
  String get startupStoreError =>
      'تعذّر حفظ تقدّمك — ستظهر شاشة التهيئة مرة أخرى عند التشغيل التالي.';

  @override
  String get shieldStatusReady => 'VoxGuard جاهز';

  @override
  String get shieldSubtitle => 'حماية صوتية فورية في الاستعداد';

  @override
  String homeGreetingNamed(String name) {
    return 'سعداء برؤيتك، $name.';
  }

  @override
  String get quickActions => 'الحماية';

  @override
  String get startSafeCall => 'بدء SafeCall';

  @override
  String get startSafeCallDesc =>
      'مكالمة محمية داخل التطبيق مع قياسات تهديد مباشرة.';

  @override
  String get protectionCheckTitle => 'ابدأ فحص حماية';

  @override
  String get protectionCheckDesc =>
      'استخدم مكبر الصوت أو شغّل صوتًا مريبًا قريبًا — يستمع VoxGuard إلى إشارات الخطر.';

  @override
  String get protectionCheckCta => 'بدء SafeCall';

  @override
  String get analyzeRecording => 'تحليل تسجيل';

  @override
  String get analyzeRecordingDesc => 'افحص تسجيل مكالمة أو مذكرة صوتية محفوظة.';

  @override
  String get incidentLogTooltip => 'سجل الحوادث';

  @override
  String get familyShieldTitle => 'Family Shield';

  @override
  String get familyReadyWithCircle => 'الدائرة الموثوقة جاهزة';

  @override
  String get familyNeedsSetup => 'يحتاج إعدادًا';

  @override
  String get familyStatusHint => 'عيون إضافية عندما تبدو المكالمة مريبة.';

  @override
  String get navShield => 'الحماية';

  @override
  String get navIncidents => 'الحوادث';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get safeCallTitle => 'SafeCall';

  @override
  String get safeCallActive => 'جلسة حماية نشطة';

  @override
  String get unknownCaller => 'متصل غير معروف';

  @override
  String get maskedNumber => '+1 (•••) ••• ••42';

  @override
  String get endCall => 'إنهاء';

  @override
  String get endCallAndVerify => 'إنهاء المكالمة والتحقق';

  @override
  String get liveBadge => 'مباشر';

  @override
  String get signalSynthetic => 'مؤشرات الشذوذ الصوتي';

  @override
  String get signalUrgency => 'ضغط الاستعجال';

  @override
  String get signalFinancial => 'مطلب تحويل مالي';

  @override
  String get signalSecrecy => 'طلب السرية والعزل';

  @override
  String get statusNormal => 'طبيعي';

  @override
  String get statusElevated => 'مرتفع';

  @override
  String get bannerProtected => 'محمي';

  @override
  String get bannerProtectedDetail => 'كل الإشارات طبيعية — لا مؤشرات تهديد';

  @override
  String get bannerElevated => 'خطر مرتفع';

  @override
  String get bannerElevatedDetail => 'نمط مريب — مراقبة عن كثب';

  @override
  String get bannerThreat => 'رُصدت مكالمة عالية الخطورة';

  @override
  String get bannerThreatDetail => 'رُصدت أنماط انتحال هوية ومطالب مالية';

  @override
  String get threatScoreLabel => 'درجة التهديد';

  @override
  String get simulateScam => 'محاكاة احتيال';

  @override
  String get stopSimulation => 'إيقاف العرض';

  @override
  String get pauseHeadline => 'توقف قبل التصرف.';

  @override
  String get verifyBeforeYouAct => 'تحقق قبل أن تتصرف.';

  @override
  String get technicalDetails => 'تفاصيل تقنية';

  @override
  String get liveTranscript => 'النص المباشر';

  @override
  String get transcriptEmpty => 'يظهر النص هنا أثناء مكالمة محمية.';

  @override
  String get transcriptDemoPending => 'سيظهر نص العرض هنا.';

  @override
  String get transcriptListening => 'يستمع إلى الكلام…';

  @override
  String get transcriptNoLive => 'تحليل الصوت نشط — النسخ المباشر غير متاح.';

  @override
  String get speakerCaller => 'المتصل';

  @override
  String get speakerYou => 'أنت';

  @override
  String get safeCallPickerTitle => 'ابدأ جلسة حماية';

  @override
  String get modeLiveMic => 'الميكروفون المباشر';

  @override
  String get modeLiveMicDesc =>
      'حلّل صوت الميكروفون الحقيقي — مكالمات على السماعة الخارجية أو صوت يُشغَّل قريبًا.';

  @override
  String get modeLiveMicBadge => 'جلسة حقيقية';

  @override
  String get modeDemo => 'هجوم تجريبي';

  @override
  String get modeDemoDesc =>
      'شغّل سيناريو العرض المجهز — صوت مولّد ونص تجريبي. لا يوجد صوت حقيقي.';

  @override
  String get modeDemoBadge => 'عرض توضيحي';

  @override
  String get modeLiveBadgeShort => 'ميكروفون مباشر';

  @override
  String get modeDemoBadgeShort => 'عرض';

  @override
  String get modeDemoModeLabel => 'وضع العرض';

  @override
  String durationMinSec(int m, int ss) {
    return '$m:$ss';
  }

  @override
  String durationHourMinSec(int h, int mm, int ss) {
    return '$h:$mm:$ss';
  }

  @override
  String get lensBandSafe => 'آمن';

  @override
  String get lensBandCaution => 'حذر';

  @override
  String get lensBandHigh => 'خطر مرتفع';

  @override
  String get lensInterpSafe => 'الإشارات تبدو طبيعية — واصل الاستماع.';

  @override
  String get lensInterpCaution => 'شيء ما يبدو غريبًا — راقب الإشارات.';

  @override
  String get lensInterpHigh => 'توقف قبل التصرف.';

  @override
  String get lensRiskSignal => 'إشارة الخطر';

  @override
  String lensA11yPartial(int acoustic) {
    return 'إشارة جزئية — شذوذ صوتي $acoustic من 100. لم يُجرَ تحليل المحادثة.';
  }

  @override
  String lensA11yFull(String band, int score, int acoustic) {
    return 'إشارة الخطر $band، $score من 100. التحليل الصوتي $acoustic من 100.';
  }

  @override
  String get lensDemoAudio => 'صوت تجريبي';

  @override
  String get lensLayerConversation => 'المحادثة';

  @override
  String get lensLayerVoice => 'الصوتيات';

  @override
  String get lensNotAnalyzed => 'لم تُحلَّل';

  @override
  String get signalPartialState => 'صوتيات فقط';

  @override
  String get acousticAnomalyLabel => 'شذوذ صوتي';

  @override
  String get conversationNotAnalyzed => 'لم تُحلَّل إشارات مخاطر المحادثة.';

  @override
  String get acousticOnlyMonitoring =>
      'المراقبة الصوتية نشطة. تحليل المحادثة يتطلب نسخًا نصيًا.';

  @override
  String get bannerAcousticOnly =>
      'مراقبة صوتية فقط — إشارات المحادثة لم تُحلَّل';

  @override
  String get bannerAcousticElevated =>
      'شذوذ صوتي مرتفع — إشارات المحادثة لم تُحلَّل';

  @override
  String get acousticAnomalyElevatedNote => 'رُصدت مؤشرات شذوذ صوتي مرتفعة.';

  @override
  String get postCallEnded => 'انتهت جلسة الحماية';

  @override
  String get postCallReview => 'راجع الأدلة قبل اتخاذ أي إجراء آخر.';

  @override
  String get postCallPause => 'توقف.';

  @override
  String get postCallVerifyCta => 'تحقق بشكل مستقل';

  @override
  String get callSavedNumberHint => 'أعد الاتصال بالشخص على رقم تثق به مسبقًا.';

  @override
  String get verifyIdentityTitle => 'تحقق من الهوية';

  @override
  String get verifyIdentityBody =>
      'أعد الاتصال بالشخص على رقم تثق به مسبقًا — وليس الرقم الذي اتصل بك للتو.';

  @override
  String get callTrustedContact => 'اتصل بشخص موثوق';

  @override
  String get sendDemoFamilyAlert => 'إرسال تنبيه عائلي تجريبي';

  @override
  String get familyAlertSent => 'بُثّ التنبيه التجريبي إلى العائلة';

  @override
  String get familySafePhrase =>
      'نصيحة: اتفقوا على عبارة أمان عائلية دون اتصال — اطلبها من المتصل.';

  @override
  String get viewIncidentReport => 'عرض تقرير الحادثة';

  @override
  String get incidentLogged => 'سُجّلت مكالمة عالية الخطورة';

  @override
  String get postCallNoFlags =>
      'لم تُرصد أنماط عالية الخطورة أثناء هذه المكالمة.';

  @override
  String get postCallSessionSummary => 'ملخص الجلسة';

  @override
  String get postCallFamilyShield => 'Family Shield';

  @override
  String get postCallFamilyDemoNote =>
      'وضع العرض — يرسل تنبيهًا محاكى إلى جهات تجريبية؛ لا يصل أي إشعار حقيقي.';

  @override
  String get postCallFamilyPrompt =>
      'اطلب من شخص تثق به رأيًا ثانيًا — أرسل له تنبيه Family Shield.';

  @override
  String get postCallSendFamilyAlert => 'إرسال تنبيه عائلي';

  @override
  String get postCallSendFamilyAlertDesc =>
      'أرسل تنبيه Family Shield إلى أشخاص في دائرتك الموثوقة';

  @override
  String get verifyStepCall => 'اتصل بالشخص على رقم محفوظ وموثوق.';

  @override
  String get verifyStepPhrase =>
      'اطلب عبارة الأمان العائلية إن لم تكن متأكدًا.';

  @override
  String sheetScoreSummary(String headline, int score) {
    return '$headline درجة التهديد: $score/100.';
  }

  @override
  String get incidentsTitle => 'الحوادث';

  @override
  String get incidentEmptyTitle => 'لا حوادث مسجلة';

  @override
  String get incidentEmptyBody =>
      'ستظهر الجلسات المُشار إليها والتسجيلات المحلَّلة هنا كسجل أمان.';

  @override
  String get bandPartial => 'تحليل جزئي';

  @override
  String get bandHigh => 'خطر مرتفع';

  @override
  String get bandCritical => 'حرج / خطر مرتفع';

  @override
  String get bandSuspicious => 'مريب';

  @override
  String get bandSafe => 'آمن';

  @override
  String incidentPartialSummary(int score) {
    return 'شذوذ صوتي $score/100 — مخاطر المحادثة لم تُحلَّل';
  }

  @override
  String get incidentNoThreats => 'لا تهديدات كبيرة رُصدت';

  @override
  String incidentReasonsDetected(int count) {
    return '$count رُصدت';
  }

  @override
  String get incidentDeleteTitle => 'حذف هذه الحادثة؟';

  @override
  String incidentDeleteBody(String id) {
    return 'سيُحذف $id نهائيًا من هذا الجهاز. لا يمكن التراجع.';
  }

  @override
  String get incidentDeleteTooltip => 'حذف الحادثة';

  @override
  String get incidentDeleteFailed => 'تعذّر حذف هذا الحادث. حاول مرة أخرى.';

  @override
  String get incidentCopied => 'نُسخ تقرير الحادثة إلى الحافظة.';

  @override
  String get incidentFamilyResponses => 'ردود Family Shield';

  @override
  String familyMarkedSafe(String name) {
    return '$name اعتبر الوضع آمنًا';
  }

  @override
  String familyStillConcerned(String name) {
    return '$name ما زال قلقًا';
  }

  @override
  String get incidentRecommended => 'الخطوات التالية الموصى بها';

  @override
  String get incidentTechnicalEvidence => 'أدلة تقنية';

  @override
  String get incidentAudioSha => 'بصمة الصوت SHA-256';

  @override
  String get incidentAcousticSignals => 'إشارات الشذوذ الصوتي';

  @override
  String get metricSpectralFlux => 'التدفق الطيفي';

  @override
  String get metricSpectralRolloff => 'الانحدار الطيفي';

  @override
  String get metricZeroCrossing => 'معدل العبور الصفري';

  @override
  String get metricAcousticScore => 'درجة الشذوذ الصوتي';

  @override
  String get incidentSemanticSignals => 'إشارات التهديد الدلالي';

  @override
  String get semUrgency => 'الاستعجال';

  @override
  String get semFinancial => 'مالي';

  @override
  String get semSecrecy => 'السرية';

  @override
  String get incidentTranscriptTimeline => 'الجدول الزمني للنص';

  @override
  String get incidentNoTranscript => 'لم يُلتقط نص.';

  @override
  String get incidentBroadcast => 'بثّ إلى Family Shield';

  @override
  String get incidentBroadcastDemoNote => 'وضع العرض — لا يُرسَل إشعار حقيقي';

  @override
  String get incidentShare => 'مشاركة تقرير الحادثة';

  @override
  String incidentScoreLine(int score) {
    return '$score/100';
  }

  @override
  String get acousticAnomalyPrefix => 'شذوذ صوتي ';

  @override
  String get analyzeRecordingTitle => 'تحليل تسجيل';

  @override
  String get recordingStepTitle => 'حلّل تسجيل مكالمة أو مذكرة صوتية';

  @override
  String get recordingFormats =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — حتى 25 م.ب أو 15 دقيقة.';

  @override
  String get recordingChooseAudio => 'اختر صوتًا';

  @override
  String get recordingPrivacyLabel => 'الخصوصية';

  @override
  String get recordingKeepLocal => 'إبقاء الصوت على هذا الجهاز';

  @override
  String get recordingKeepLocalDesc =>
      'التحليل الصوتي يعمل محليًا. لا يُرفَع شيء.';

  @override
  String get recordingIncludeConversation => 'تضمين تحليل المحادثة';

  @override
  String get recordingCloudNotConfigured =>
      'النسخ السحابي غير مُعدّ في هذا الإصدار. التحليل الصوتي متاح على الجهاز.';

  @override
  String get recordingCancelAnalysis => 'إلغاء التحليل';

  @override
  String get recordingAnalyzeAction => 'تحليل التسجيل';

  @override
  String get recordingChooseDifferent => 'اختر ملفًا مختلفًا';

  @override
  String get recordingViewIncident => 'عرض تقرير الحادثة';

  @override
  String get recordingAnalyzeAnother => 'تحليل تسجيل آخر';

  @override
  String get recordingMetaFormat => 'الصيغة';

  @override
  String get recordingMetaSize => 'الحجم';

  @override
  String get recordingMetaDuration => 'المدة';

  @override
  String get recordingSentinelBadge => 'SENTINEL';

  @override
  String get recordingManualTranscript => 'إضافة نص مكتوب بدلًا من ذلك';

  @override
  String get recordingManualTranscriptLabel => 'نص مقدَّم من المستخدم';

  @override
  String get recordingManualTranscriptHint =>
      'ألصق نصًا لديك بالفعل — يبقى على هذا الجهاز.';

  @override
  String get recordingStagePreparing => 'تجهيز الصوت';

  @override
  String get recordingStageAcoustic => 'تحليل الإشارات الصوتية';

  @override
  String get recordingStageUploading => 'رفع للنسخ النصي';

  @override
  String get recordingStageTranscribing => 'نسخ المحادثة';

  @override
  String get recordingStageEvaluating => 'تقييم مخاطر المحادثة';

  @override
  String get recordingStageBuilding => 'بناء النتيجة';

  @override
  String get recordingThreatScore => 'درجة التهديد';

  @override
  String get recordingConvNotAnalyzed => 'إشارة المحادثة · لم تُحلَّل';

  @override
  String get recordingAcousticSignals => 'إشارات الشذوذ الصوتي';

  @override
  String get recordingAcousticScore => 'درجة الشذوذ الصوتي';

  @override
  String get recordingMetricFlux => 'التدفق الطيفي';

  @override
  String get recordingMetricRolloff => 'الانحدار الطيفي';

  @override
  String get recordingMetricZcr => 'معدل العبور الصفري';

  @override
  String get recordingTranscriptLabel => 'نص التسجيل';

  @override
  String get recordingVerifyTitle => 'تحقق قبل أن تتصرف';

  @override
  String get recordingVerifyBody =>
      'هذا فحص صوتي فقط — لم تُحلَّل المحادثة نفسها. لا تعتمد على نتيجة جزئية لاعتبار تسجيلٍ آمنًا: تحقق من المتحدث عبر قناة تثق بها مسبقًا.';

  @override
  String get stepPickRecording => 'اختر تسجيلًا';

  @override
  String get stepPrivacyDepth => 'اختر عمق الخصوصية';

  @override
  String get stepAnalyze => 'حلّل';

  @override
  String get stepResult => 'افهم النتيجة';

  @override
  String get familyAlertTitle => 'تنبيه Family Shield';

  @override
  String familyAlertAcoustic(String name) {
    return 'طلب منك $name التحقق من تحذير صوتي مرتفع من تسجيل.';
  }

  @override
  String familyAlertHighRisk(String name) {
    return 'قد يتعامل $name مع مكالمة عالية الخطورة.';
  }

  @override
  String familyAlertSuspicious(String name) {
    return 'تلقّى $name تحذير مكالمة مريبة من VoxGuard.';
  }

  @override
  String get familyMarkedSafeNote => 'عُدّ آمنًا بعد تحقق مستقل.';

  @override
  String get familyStillSuspiciousNote => 'ما زال مريبًا — واصل التحقق.';

  @override
  String familyUpdateFailed(String localCopy) {
    return '$localCopy تعذّر إرسال التحديث العائلي — تحقق من اتصالك.';
  }

  @override
  String get familyBandAlert => 'تنبيه';

  @override
  String get familyVerifyDirectly => 'تحقق مباشرة';

  @override
  String familyVerifyCall(String name) {
    return 'اتصل بـ $name على الرقم الموثوق الذي حفظته — وليس رقمًا قدّمه المتصل المريب.';
  }

  @override
  String get familyVerifyChannel =>
      'تحقق عبر قناة تثق بها مسبقًا. لا تتصرف بناءً على تعليمات التنبيه وحده.';

  @override
  String familyCallAction(String name) {
    return 'اتصل بـ $name';
  }

  @override
  String familyCallActionUnknown(String name) {
    return 'اتصل بـ $name';
  }

  @override
  String get familyCallContact => 'اتصل بجهة الاتصال';

  @override
  String get familyNoTrustedNumber =>
      'لا رقم موثوقًا محفوظًا. تواصل عبر رقم تثق به مسبقًا.';

  @override
  String get familyMarkSafe => 'اعتبار آمنًا';

  @override
  String get familyStillSuspicious => 'ما زال مريبًا';

  @override
  String get familyTipNoMoney => 'لا ترسل أموالًا أو بطاقات هدايا.';

  @override
  String get familyTipNoCodes => 'لا تشارك رموز OTP أو PIN أو بيانات بنكية.';

  @override
  String get familyTipChannel => 'تحقق عبر قناة مستقلة أخرى.';

  @override
  String get familyTipAuthorities =>
      'تواصل مع البنك أو شركة الاتصالات أو السلطات المحلية عند الحاجة.';

  @override
  String get familyDetailsTitle => 'التفاصيل';

  @override
  String familyDetailsBody(String incident, String time, String status) {
    return 'الحادثة $incident\nاستُلمت $time\n$status';
  }

  @override
  String get familyStatusSafe => 'آمن بعد التحقق';

  @override
  String get familyStatusSuspicious => 'ما زال مريبًا';

  @override
  String get familyStatusUnresolved => 'لم يُحسم';

  @override
  String get familyPrivacyNote =>
      'الخصوصية: شُاركت فقط هوية جهاز مُبهمة ومستوى خطر. لا صوت ولا نص ولا أسماء ولا أرقام هواتف في تنبيهات Family Shield.';

  @override
  String get familyUpdateTitle => 'تحديث Family Shield';

  @override
  String familyUpdateMarkedSafe(String who) {
    return '$who اعتبر الوضع آمنًا';
  }

  @override
  String familyUpdateConcerned(String who) {
    return '$who ما زال قلقًا';
  }

  @override
  String familyUpdateHumanNote(String incident) {
    return 'هذا تحديث تحقق بشري — لا يغيّر تقييم الذكاء الاصطناعي للخطر.\n\nالحادثة $incident';
  }

  @override
  String get familyAlertReceived => 'وصل تنبيه Family Shield';

  @override
  String get familyAlertFraming => 'شخص تعرفه يطلب رأيًا ثانيًا.';

  @override
  String get yourJudgment => 'حكمك أنت';

  @override
  String get humanResponseNote =>
      'مكالمتك هي التحقق — وليس التطبيق. اعتبار الوضع آمنًا أو مريبًا ردّ بشري؛ لا يغيّر تحليل الخطر.';

  @override
  String get familyReceiverTitle => 'مستقبل Family Shield';

  @override
  String get familyReceiverDesc =>
      'استقبل تنبيهًا عندما يواجه شخص في دائرتك الموثوقة مكالمة عالية الخطورة.';

  @override
  String get familyReceiverShareHint =>
      'شارك هذا المعرف فقط مع من تريد استقبال تنبيهات Family Shield منه.';

  @override
  String get familyReceiverEnable => 'تفعيل تنبيهات العائلة';

  @override
  String get familyReceiverOpenSettings => 'فتح إعدادات النظام';

  @override
  String get familyReceiverNotConfigured =>
      'إعداد الدفع غير متاح — ONESIGNAL_APP_ID غير مُعدّ في هذا الإصدار.';

  @override
  String get familyReceiverDevRecipient => 'DEV · مستلم تنبيه تجريبي';

  @override
  String get familyReceiverSetTest => 'تعيين مستلم تجريبي';

  @override
  String get familyStateReady => 'جاهز لاستقبال التنبيهات';

  @override
  String get familyStateRegistering => 'جارٍ التسجيل…';

  @override
  String get familyStateNeedPermission => 'إذن الإشعارات مطلوب';

  @override
  String get familyStateBlocked =>
      'الإشعارات محظورة — فعّلها من إعدادات النظام';

  @override
  String get familyStateNotConfigured => 'الدفع غير مُعدّ';

  @override
  String get familyStateUnsupported => 'غير مدعوم على هذه المنصة';

  @override
  String familyStateError(String detail) {
    return 'خطأ في التسجيل$detail';
  }

  @override
  String get familyShieldIdLabel => 'معرف Family Shield';

  @override
  String get familyShieldIdCopy => 'نسخ معرف Family Shield';

  @override
  String get familyShieldIdCopiedShort => 'تم نسخ معرف Family Shield';

  @override
  String get trustedCircleTitle => 'الدائرة الموثوقة';

  @override
  String trustedCircleCount(int count, String max) {
    return '$count من $max';
  }

  @override
  String get trustedCircleDesc =>
      'الأشخاص الذين تطلب منهم رأيًا ثانيًا. تصلهم التنبيهات عبر معرف Family Shield — أرقام الهواتف تبقى على هذا الجهاز.';

  @override
  String get trustedNoPhone => ' · بدون هاتف';

  @override
  String get trustedPhoneStored => ' · هاتف محفوظ';

  @override
  String get trustedPhoneNone => ' · بدون هاتف';

  @override
  String get trustedAddTitle => 'إضافة شخص موثوق';

  @override
  String get trustedEditTitle => 'تعديل شخص';

  @override
  String get trustedFindIdHint =>
      'يمكنهم إيجاد معرف Family Shield في تطبيقهم ضمن الإعدادات ← مستقبل Family Shield.';

  @override
  String get trustedNameField => 'الاسم';

  @override
  String get trustedShieldIdField => 'معرف Family Shield';

  @override
  String get trustedPhoneField => 'رقم هاتف موثوق (اختياري)';

  @override
  String get paywallTitle => 'إشارتان.\nقرار بشري واحد.';

  @override
  String get paywallSubtitle =>
      'VoxGuard يشير إلى الخطر — وأنت تتحقق. الخطط المدفوعة توسّع ما تراه الإشارتان.';

  @override
  String get securityBadge => 'الفوترة عبر متجر تطبيقاتك';

  @override
  String get demoStoreBadge => 'متجر تجريبي';

  @override
  String get demoStoreNotice => 'دفع محاكى — لن يحدث أي خصم حقيقي.';

  @override
  String get storeUnavailableNotice => 'الاشتراكات غير مُعدّة في هذا الإصدار.';

  @override
  String get monthly => 'شهري';

  @override
  String get annual => 'سنوي';

  @override
  String get mostPopular => 'الأكثر شيوعًا';

  @override
  String get upgradeNow => 'ترقية الآن';

  @override
  String get continueFree => 'المتابعة مجانًا';

  @override
  String get subscribeNow => 'اشترك';

  @override
  String get activateDemoPlan => 'تفعيل الخطة التجريبية';

  @override
  String get demoPlanActivated => 'فُعّلت الخطة التجريبية — لا خصم حقيقي';

  @override
  String get noPurchasesRestored => 'لا مشتريات نشطة.';

  @override
  String get terms => 'شروط الخدمة';

  @override
  String get privacy => 'سياسة الخصوصية';

  @override
  String get restore => 'استعادة المشتريات';

  @override
  String get upgradeTooltip => 'عرض الخطط';

  @override
  String get plansLoadError => 'تعذّر تحميل الخطط.';

  @override
  String get planNotAvailable => 'هذه الخطة غير متاحة في هذا المتجر.';

  @override
  String get prefSaveFailed => 'تعذّر حفظ هذا الإعداد — حاول مرة أخرى.';

  @override
  String planActivated(String name) {
    return 'فُعّل $name — ترقية الحماية';
  }

  @override
  String get planFreeLabel => 'مجاني';

  @override
  String get planNotAvailableShort => 'غير متاح';

  @override
  String get planFreeBadge => 'مجاني';

  @override
  String get planSentinelBadge => 'SENTINEL نشط';

  @override
  String get planFamilyBadge => 'FAMILY VAULT نشط';

  @override
  String get tierQuickCheck => 'Quick Check';

  @override
  String get tierQuickCheckTag => 'أدوات أمان محلية';

  @override
  String get tierQuickCheckF1 => 'مراقبة الشذوذ الصوتي عبر الميكروفون المباشر';

  @override
  String get tierQuickCheckF2 => 'تحليل التسجيلات على الجهاز';

  @override
  String get tierQuickCheckF3 => 'فحص نص يدوي — يُحلَّل محليًا';

  @override
  String get tierQuickCheckF4 => 'سجل حوادث محلي';

  @override
  String get tierQuickCheckF5 => 'استقبال تنبيهات Family Shield والرد عليها';

  @override
  String get tierSentinel => 'Sentinel Shield';

  @override
  String get tierSentinelTag => 'حماية واعية بالمحادثة';

  @override
  String get tierSentinelF1 => 'كل مزايا Quick Check';

  @override
  String get tierSentinelF2 =>
      'نسخ تلقائي للميكروفون المباشر وللتسجيلات المحسّن — عند إعداد البنية التحتية';

  @override
  String get tierSentinelF3 => 'تحليل مخاطر المحادثة المدعوم بالنص';

  @override
  String get tierSentinelF4 => 'درجة تهديد مدموجة متعددة الإشارات';

  @override
  String get tierFamily => 'Family Vault';

  @override
  String get tierFamilyTag => 'حلقة التحقق البشري';

  @override
  String get tierFamilyF1 => 'كل مزايا Sentinel Shield';

  @override
  String get tierFamilyF2 => 'إرسال تنبيهات Family Shield إلى دائرتك الموثوقة';

  @override
  String get tierFamilyF3 => 'حتى 5 جهات موثوقة محفوظة محليًا';

  @override
  String get tierFamilyF4 => 'ردود الأمان تعود إليك بخصوصية';

  @override
  String get familyVaultUnlocksAlerts =>
      'يتيح Family Vault إرسال تنبيهات أمان إلى دائرتك الموثوقة.';

  @override
  String get acousticProtectionActive =>
      'الحماية الصوتية نشطة. تحليل المحادثة المدعوم بالنص يُتاح مع Sentinel Shield.';

  @override
  String currentPlan(String tier) {
    return 'الخطة الحالية: $tier';
  }

  @override
  String get currentPlanDemo => ' (تجريبي)';

  @override
  String get viewPlans => 'عرض الخطط';

  @override
  String get manageSubscription => 'إدارة الاشتراك';

  @override
  String get purchasesRestored => 'استُعيدت المشتريات.';

  @override
  String get purchasesRestoreFailed => 'تعذّرت استعادة المشتريات الآن.';

  @override
  String get subscriptionSection => 'الاشتراك';

  @override
  String get demoStoreSection => 'متجر تجريبي';

  @override
  String get billingMonthly => 'شهري';

  @override
  String get billingAnnual => 'سنوي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSectionProfile => 'الملف الشخصي';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionSafety => 'الأمان والعائلة';

  @override
  String get settingsSectionNotifications => 'الإشعارات';

  @override
  String get settingsSectionSubscription => 'الاشتراك';

  @override
  String get settingsSectionAbout => 'حول والخصوصية';

  @override
  String get settingsDisplayName => 'الاسم المعروض';

  @override
  String get settingsDisplayNameNone => 'غير مُعيّن';

  @override
  String get settingsDisplayNameHint => 'بماذا نناديك؟';

  @override
  String get settingsDisplayNameNote =>
      'يُحفظ على هذا الجهاز فقط — لا يُشارَك أبدًا.';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get languageEn => 'English';

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEs => 'Español';

  @override
  String get languageFr => 'Français';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsAccent => 'لون مميز';

  @override
  String get accentPeriwinkle => 'زهري أرجواني';

  @override
  String get accentSoftBlue => 'أزرق هادئ';

  @override
  String get accentSoftViolet => 'بنفسجي هادئ';

  @override
  String get settingsTextSize => 'حجم النص';

  @override
  String get textSizeSystem => 'النظام';

  @override
  String get textSizeLarge => 'كبير';

  @override
  String get textSizeExtraLarge => 'كبير جدًا';

  @override
  String get textSizeNote =>
      'لن يكون أصغر من إعداد إمكانية الوصول في جهازك أبدًا.';

  @override
  String get settingsExperience => 'نمط العرض';

  @override
  String get experienceStandard => 'قياسي';

  @override
  String get experienceGuided => 'إرشادي';

  @override
  String get experienceGuidedDesc =>
      'أزرار أكبر وإرشاد أوضح وتفاصيل تقنية أقل في البداية.';

  @override
  String get settingsMotion => 'الحركة';

  @override
  String get motionSystem => 'اتباع النظام';

  @override
  String get motionReduced => 'مخفَّض';

  @override
  String get motionNote =>
      'الحركة المخفَّضة توقف الرسوم المحيطية. تغيّرات الخطر تبقى واضحة دائمًا.';

  @override
  String get settingsHaptics => 'الاهتزاز';

  @override
  String get hapticsOn => 'مفعّل';

  @override
  String get hapticsOff => 'متوقف';

  @override
  String get settingsFamilyStatus => 'تنبيهات Family Shield';

  @override
  String get settingsNotificationState => 'إذن الإشعارات';

  @override
  String get notifStateGranted => 'مسموح';

  @override
  String get notifStateDenied => 'متوقف — فعّله من إعدادات الجهاز';

  @override
  String get notifStateUnknown => 'غير محدد';

  @override
  String get settingsNotificationNote =>
      'صوت الإشعار وطريقة وصوله يتحكم بهما إعداد الإشعارات في جهازك.';

  @override
  String get settingsOpenNotifSettings => 'فتح إعدادات الإشعارات';

  @override
  String get settingsHowItWorks => 'كيف يعمل';

  @override
  String get settingsAnalysisLangs =>
      'تحليل مخاطر المحادثة يدعم حاليًا الإنجليزية والعربية المصرية. يمكن تغيير لغة واجهة التطبيق بشكل مستقل.';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get settingsLocalOnly =>
      'اسمك ولغتك وتفضيلات المظهر تبقى على هذا الجهاز.';

  @override
  String get msgFamilyShieldDisabled => 'Family Shield متوقف.';

  @override
  String get msgNeedTrustedContact =>
      'أضف شخصًا إلى دائرتك الموثوقة قبل إرسال تنبيه Family Shield.';

  @override
  String msgDemoAlertBroadcast(int count) {
    return 'بُثّ التنبيه التجريبي إلى $count من أفراد العائلة.';
  }

  @override
  String msgAlertAccepted(int count) {
    return 'قُبل التنبيه للتسليم إلى $count من أفراد العائلة.';
  }

  @override
  String msgRelayRejected(int code) {
    return 'رفض المُرحِّل التنبيه ($code).';
  }

  @override
  String msgServiceUnavailable(int code) {
    return 'خدمة التنبيهات غير متاحة ($code).';
  }

  @override
  String get msgNetworkAlert => 'خطأ في الشبكة — تعذّر إرسال التنبيه.';

  @override
  String get msgNetworkResponse => 'خطأ في الشبكة — تعذّر إرسال الرد.';

  @override
  String get msgChooseResponse => 'اختر آمن أو ما زال مريبًا قبل الرد.';

  @override
  String get msgInvalidTarget => 'هدف الرد ليس معرف Family Shield صالحًا.';

  @override
  String get msgDemoResponse => 'عرض — حُاكي الرد، لم يغادر شيء هذا الجهاز.';

  @override
  String get msgFamilyUpdateSent => 'تم إرسال التحديث العائلي.';

  @override
  String get msgCircleFull =>
      'الدائرة الموثوقة ممتلئة (5 أشخاص). أزل شخصًا أولًا.';

  @override
  String get msgDuplicateContact =>
      'معرف Family Shield هذا موجود في دائرتك الموثوقة.';

  @override
  String get msgNameRequired => 'الاسم مطلوب.';

  @override
  String get msgInvalidShieldId => 'هدف الرد ليس معرّف Family Shield صالحًا.';

  @override
  String get msgPhoneTooLong => 'رقم الهاتف طويل جدًا.';

  @override
  String get msgDemoReadOnly => 'جهات الاتصال التجريبية للقراءة فقط';

  @override
  String get msgPushSetupFailed => 'فشل إعداد الدفع على هذا الجهاز.';

  @override
  String get msgPushLinkFailed => 'تعذّر ربط معرف Family Shield.';

  @override
  String get msgPushEnableFailed => 'تعذّر تفعيل تنبيهات الدفع. حاول مجددًا.';

  @override
  String get msgPushStateFailed => 'تعذّرت قراءة حالة الدفع.';

  @override
  String get msgMicUnsupported =>
      'التقاط الميكروفون غير مدعوم على هذه المنصة. جرّب وضع العرض.';

  @override
  String get msgMicBlocked =>
      'الوصول إلى الميكروفون محظور. فعّله من إعدادات النظام، أو استخدم وضع العرض.';

  @override
  String get msgMicDenied =>
      'رُفض إذن الميكروفون. امنح الإذن لتشغيل Live Mic، أو استخدم وضع العرض.';

  @override
  String get msgMicFailed =>
      'فشل تشغيل الميكروفون. تحقق من الجهاز وأعد المحاولة، أو استخدم وضع العرض.';

  @override
  String get msgFileEmpty => 'يبدو أن هذا الملف فارغ.';

  @override
  String get msgFileTooLarge =>
      'هذا الملف كبير جدًا — تُدعم تسجيلات حتى 25 م.ب.';

  @override
  String get msgFileTooLong => 'هذا التسجيل طويل جدًا — تُدعم حتى 15 دقيقة.';

  @override
  String get msgFileNoAudio =>
      'فكّ ترميز التسجيل لم ينتج صوتًا — لا شيء للتحليل.';

  @override
  String get msgEmptyTranscript => 'أعاد المزوّد نصًا فارغًا.';

  @override
  String get msgTranscriptionFailed => 'تعذّر على مزوّد النسخ معالجة الصوت.';

  @override
  String get msgTranscriptionTimeout =>
      'انتهت مهلة النسخ — النتيجة الصوتية ما زالت متاحة.';

  @override
  String get msgCloudNotConfigured =>
      'النسخ السحابي غير مُعدّ في هذا الإصدار. التحليل الصوتي متاح على الجهاز.';

  @override
  String get msgEnhancedLocked =>
      'نسخ التسجيلات المحسّن مشمول في Sentinel Shield. التحليل الصوتي على الجهاز متاح دائمًا.';

  @override
  String get msgSubsNotConfigured => 'الاشتراكات غير مُعدّة في هذا الإصدار.';

  @override
  String get msgSubsInitFailed => 'تعذّر تهيئة الاشتراكات.';

  @override
  String get msgPlansLoadFailed => 'تعذّر تحميل الخطط من المتجر.';

  @override
  String get msgPurchaseFailed => 'تعذّر إتمام الشراء.';

  @override
  String get msgNoConnection => 'لا اتصال — تحقق من شبكتك وحاول مجددًا.';

  @override
  String get msgStoreUnavailable => 'المتجر غير متاح الآن. حاول لاحقًا.';

  @override
  String get msgPurchaseNotAllowed =>
      'المشتريات غير مسموحة على هذا الجهاز أو الحساب.';

  @override
  String get msgPurchasePending => 'الدفع بانتظار الموافقة.';

  @override
  String get msgRestoreFailed => 'تعذّرت استعادة المشتريات الآن.';

  @override
  String get msgNoPaidPlans => 'لا خطط مدفوعة متاحة في هذا المتجر بعد.';

  @override
  String get msgPurchasePendingActivation =>
      'لم يفعّل الشراء خطة بعد — قد يستغرق لحظة. استخدم استعادة المشتريات للتحقق مجددًا.';

  @override
  String get msgDemoCheckoutFailed => 'فشل الدفع التجريبي — حاول مجددًا.';

  @override
  String get msgTokenFailed => 'تعذّر تجهيز النسخ — حاول مجددًا.';

  @override
  String get reasonFinancial => 'رُصد مطلب تحويل مالي';

  @override
  String get reasonSecrecy => 'ضغط سرية وعزل';

  @override
  String get reasonUrgency => 'تكتيكات تلاعب بالاستعجال';

  @override
  String reasonImpersonation(String claim) {
    return 'ادعاء انتحال هوية: «$claim»';
  }

  @override
  String get reasonAcoustic => 'مؤشرات الشذوذ الصوتي مرتفعة';

  @override
  String get reasonCoordinated => 'نمط احتيال منسّق — مضخَّم';

  @override
  String get reasonNone => 'لا مؤشرات تهديد كبيرة';

  @override
  String get actionContinueMonitoring => 'مواصلة المراقبة';

  @override
  String get actionAdviseCaution => 'توخَّ الحذر — تحقق من هوية المتصل';

  @override
  String get actionEndCall => 'أنهِ المكالمة فورًا وأبلغ شخصًا موثوقًا';

  @override
  String get actionEndCallShort => 'أنهِ المكالمة فورًا';

  @override
  String get actionNoCodes => 'لا تشارك رموز OTP أو PIN أو بيانات بنكية';

  @override
  String get actionVerifyChannel => 'تحقق من المتصل عبر قناة رسمية';

  @override
  String get actionReport => 'أبلغ شركة الاتصالات أو السلطات عن الرقم';

  @override
  String get actionEnableFamily => 'فعّل تنبيهات Family Shield للأقارب';

  @override
  String get actionNoTimeOffers =>
      'لا تتصرف بناءً على عروض محدودة الوقت تحت الضغط';

  @override
  String get evidenceImpersonation => 'انتحال هوية';

  @override
  String get evidenceMoney => 'طلب مال';

  @override
  String get evidenceUrgency => 'استعجال';

  @override
  String get evidenceSecrecy => 'سرية';

  @override
  String get sourceLiveMic => 'ميكروفون مباشر';

  @override
  String get sourceLiveMicSession => 'جلسة ميكروفون مباشر';

  @override
  String get sourceDemoAudio => 'صوت تجريبي مولّد';

  @override
  String get sourceDemoTranscript => 'نص تجريبي محلي';

  @override
  String get sourceUserTranscript => 'نص مقدَّم من المستخدم';

  @override
  String get sourceUploadedRecording => 'تسجيل مرفوع';

  @override
  String get sourceRecording => 'تسجيل';

  @override
  String get sourceAssemblyAiPrerecorded => 'AssemblyAI مُسجَّل';

  @override
  String get sourceAssemblyAiStreaming => 'AssemblyAI مباشر';

  @override
  String get sourceNoneAcoustic => 'لا يوجد — تحليل صوتي فقط';

  @override
  String get callerUnknown => 'متصل غير معروف (+20 10 ••• ••42)';

  @override
  String get callerSuspicious => 'جهة مريبة (+1 888 ••• 0112)';

  @override
  String get reportDisclaimer =>
      'قياسات جنائية مولّدة بالذكاء الاصطناعي. ليست حكمًا قانونيًا أو قضائيًا.';

  @override
  String get reportAnalysisPartial => 'التحليل: جزئي — إشارات صوتية فقط';

  @override
  String reportAcousticScore(int score) {
    return 'درجة الشذوذ الصوتي: $score/100';
  }

  @override
  String get reportConvNotAnalyzed => 'لم تُحلَّل إشارات مخاطر المحادثة.';

  @override
  String reportRiskLine(String risk, int score) {
    return 'الخطر: $risk — درجة التهديد: $score/100';
  }

  @override
  String reportIdLine(String id) {
    return 'المعرف: $id';
  }

  @override
  String reportTimeLine(String time) {
    return 'الوقت: $time';
  }

  @override
  String reportCallerLine(String caller) {
    return 'المتصل: $caller';
  }

  @override
  String reportDurationLine(String duration) {
    return 'المدة: $duration';
  }

  @override
  String reportSignalsLine(String reasons) {
    return 'الإشارات: $reasons';
  }

  @override
  String reportAudioSourceLine(String source) {
    return 'مصدر الصوت: $source';
  }

  @override
  String reportTranscriptionLine(String source) {
    return 'النسخ: $source';
  }

  @override
  String reportShaLine(String sha) {
    return 'بصمة الصوت SHA-256: $sha';
  }

  @override
  String get elevatedAcousticSummary =>
      'شذوذات صوتية مرتفعة — إشارات مخاطر المحادثة لم تُحلَّل';

  @override
  String get demoTranscript1 => 'هذا عاجل — تصرف الآن قبل انتهاء العرض.';

  @override
  String get demoTranscript2 => 'لا تخبر أحدًا حتى ينتهي الأمر.';

  @override
  String get metricAcousticAnomaly => 'درجة الشذوذ الصوتي';

  @override
  String get recordingFormatsHint =>
      'WAV · MP3 · M4A/AAC · OGG/OPUS · FLAC — حتى 25 ميغابايت أو 15 دقيقة.';

  @override
  String get recordingAcousticScoreLabel => 'درجة الشذوذ الصوتي';

  @override
  String get recordingVerifyNormalBody =>
      'النتيجة مجرد إشارة خطر وليست دليلًا. تحقق من المتحدث عبر رقم تثق به مسبقًا — وليس رقمًا ورد في التسجيل — قبل تنفيذ أي طلب.';

  @override
  String familyVerifyKnownSender(String name) {
    return 'اتصل بـ$name على الرقم الموثوق الذي حفظته — وليس رقمًا قدّمه المتصل المشبوه.';
  }

  @override
  String get familyVerifyUnknownSender =>
      'تحقق عبر قناة تثق بها مسبقًا. لا تتصرف بناءً على التنبيه وحده.';

  @override
  String get familyResolutionSafe => 'آمن بعد التحقق';

  @override
  String get familyResolutionStillSuspicious => 'ما زال مشبوهًا';

  @override
  String get familyResolutionUnresolved => 'غير محسوم';

  @override
  String familyResolutionLabel(String status) {
    return 'الحالة: $status';
  }

  @override
  String get familyReceiverReady => 'جاهز لاستقبال التنبيهات';

  @override
  String get familyReceiverShareNote =>
      'شارك هذا المعرّف فقط مع من تريد استقبال تنبيهات Family Shield منه.';

  @override
  String get familyShieldIdCopyTooltip => 'نسخ معرّف Family Shield';

  @override
  String get msgFamilyDisabled => 'Family Shield معطّل.';

  @override
  String msgAlertDelivered(int count) {
    return 'تم قبول التنبيه للتسليم إلى $count من أفراد العائلة.';
  }

  @override
  String get msgFamilyIdInvalid =>
      'يجب أن يبدو معرّف Family Shield مثل vg_ متبوعة بـ32 حرفًا ست عشريًا. اطلب من فرد عائلتك نسخه من تطبيقه (الإعدادات ← مستقبل Family Shield).';

  @override
  String get msgMicStartFailed =>
      'تعذّر تشغيل الميكروفون. تحقق من الجهاز وأعد المحاولة، أو استخدم وضع العرض.';

  @override
  String get scoreUrgency => 'الاستعجال';

  @override
  String get scoreFinancial => 'مالي';

  @override
  String get scoreSecrecy => 'السرية';

  @override
  String get demoBadgeCompact => 'تجريبي';

  @override
  String get postCallDemoAlertDesc =>
      'وضع العرض — يرسل تنبيهًا محاكى إلى جهات تجريبية؛ لا يُرسَل أي إشعار حقيقي.';

  @override
  String get postCallAskTrustDesc =>
      'اطلب من شخص تثق به رأيًا ثانيًا — أرسل له تنبيه Family Shield.';

  @override
  String get recordingConversationAbsent => 'إشارة المحادثة · لم تُحلَّل';

  @override
  String msgDemoAlertDelivered(int count) {
    return 'بُثّ تنبيه تجريبي إلى $count من أفراد العائلة.';
  }

  @override
  String msgResponseRejected(int code) {
    return 'رفض المُرحِّل الرد ($code).';
  }

  @override
  String msgAlertUnavailable(int code) {
    return 'خدمة التنبيهات غير متاحة ($code).';
  }

  @override
  String get msgAlertNetworkError => 'خطأ في الشبكة — تعذّر إرسال التنبيه.';

  @override
  String get msgResponseNetworkError => 'خطأ في الشبكة — تعذّر إرسال الرد.';

  @override
  String get msgResolutionRequired =>
      'اختر «آمن» أو «ما زال مشبوهًا» قبل الرد.';

  @override
  String get msgDemoResponseSent =>
      'وضع العرض — تمت محاكاة الرد، ولم يغادر شيء هذا الجهاز.';

  @override
  String get pushAlertBodyHigh =>
      'رُصدت مكالمة عالية الخطورة على جهاز مراقَب. تحقق مباشرة مع قريبك قبل تحويل أي أموال.';

  @override
  String get pushAlertBodySuspicious =>
      'رُصد تحذير مكالمة مشبوهة على جهاز مراقَب. تحقق مباشرة مع قريبك قبل تحويل أي أموال.';

  @override
  String get pushAlertBodyPartial =>
      'رُصدت إشارات صوتية مرتفعة في تسجيل على جهاز مراقَب. إشارات خطر المحادثة لم تُحلَّل — تحقق مباشرة مع قريبك.';

  @override
  String get familyReceiverTestDeviceHint =>
      'vg_… المعرّف الخارجي لجهاز الاختبار';

  @override
  String get verifyStepHangup => 'أنهِ المكالمة — ولا ترسل أموالاً.';

  @override
  String familyUpdateIncidentId(String id) {
    return 'الواقعة $id';
  }

  @override
  String familyUpdateReceivedAt(String time) {
    return 'تم الاستلام $time';
  }
}
