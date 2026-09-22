import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show BuildContext;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme selection — three-way, persisted.
enum AppThemeMode { system, light, dark }

/// Curated accent families — deliberately a closed set; accents may
/// tint interactive surfaces but never the semantic safety colors.
enum AppAccent { periwinkle, softBlue, softViolet }

/// Text-size preset — a floor applied on top of the OS scale; the
/// effective scale is never below the OS accessibility setting.
enum AppTextSize { system, large, extraLarge }

/// Motion preference — `system` follows the OS, `reduced` forces
/// reduced motion app-wide. OS reduced-motion always wins either way.
enum AppMotionPref { system, reduced }

/// Haptic feedback preference.
enum AppHapticsPref { on, off }

/// Experience density — `guided` enlarges primary actions, adds
/// explicit guidance and de-emphasizes technical detail. Not an
/// age-based mode.
enum ExperienceMode { standard, guided }

/// Interface language — `system` follows the OS locale; the four
/// explicit options pin the UI regardless of device language.
enum AppLocaleOption { system, en, ar, es, fr }

/// Persistent, local-only app preferences.
///
/// Backed by SharedPreferences; every value is stored under a stable
/// non-localized ID so a public rename or translation change never
/// orphans a user's settings. Unknown/corrupt persisted values fall
/// back to defaults — startup must never crash on bad data.
///
/// Nothing here leaves the device: no account, no sync, and the
/// display name is never placed in Family Shield payloads.
final class AppPreferences extends ChangeNotifier {
  AppPreferences._(this._prefs);

  /// Production factory — hydrates from disk before first use.
  static Future<AppPreferences> load({SharedPreferences? prefs}) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    return AppPreferences._(_PrefsStore(store));
  }

  /// In-memory factory for tests — no disk I/O.
  @visibleForTesting
  factory AppPreferences.inMemory({
    bool setupCompleted = false,
    String? displayName,
    AppLocaleOption locale = AppLocaleOption.system,
    AppThemeMode themeMode = AppThemeMode.system,
    AppAccent accent = AppAccent.periwinkle,
    AppTextSize textSize = AppTextSize.system,
    AppMotionPref motion = AppMotionPref.system,
    AppHapticsPref haptics = AppHapticsPref.on,
    ExperienceMode experienceMode = ExperienceMode.standard,
  }) {
    final p = AppPreferences._(null);
    p._setupCompleted = setupCompleted;
    p._displayName = displayName;
    p._locale = locale;
    p._themeMode = themeMode;
    p._accent = accent;
    p._textSize = textSize;
    p._motion = motion;
    p._haptics = haptics;
    p._experienceMode = experienceMode;
    return p;
  }

  static const _kSetupCompleted = 'vg.pref.setup_completed';
  static const _kDisplayName = 'vg.pref.display_name';
  static const _kLocale = 'vg.pref.locale';
  static const _kThemeMode = 'vg.pref.theme_mode';
  static const _kAccent = 'vg.pref.accent';
  static const _kTextSize = 'vg.pref.text_size';
  static const _kMotion = 'vg.pref.motion';
  static const _kHaptics = 'vg.pref.haptics';
  static const _kExperience = 'vg.pref.experience_mode';

  /// Display-name bound — generous for real names, bounded for UI.
  static const int maxDisplayNameLength = 32;

  final _PrefsStore? _prefs;

  bool _setupCompleted = false;
  String? _displayName;
  AppLocaleOption _locale = AppLocaleOption.system;
  AppThemeMode _themeMode = AppThemeMode.system;
  AppAccent _accent = AppAccent.periwinkle;
  AppTextSize _textSize = AppTextSize.system;
  AppMotionPref _motion = AppMotionPref.system;
  AppHapticsPref _haptics = AppHapticsPref.on;
  ExperienceMode _experienceMode = ExperienceMode.standard;

  bool _hydrated = false;

  /// Reads persisted values once. Called at app start before runApp;
  /// in-memory instances skip I/O entirely.
  Future<void> init() async {
    if (_hydrated) return;
    _hydrated = true;
    final p = _prefs;
    if (p == null) return;
    _setupCompleted = await p.getBool(_kSetupCompleted) ?? false;
    _displayName = _sanitizeName(await p.getString(_kDisplayName));
    _locale = _enumById(AppLocaleOption.values,
        await p.getString(_kLocale), AppLocaleOption.system);
    _themeMode = _enumById(AppThemeMode.values,
        await p.getString(_kThemeMode), AppThemeMode.system);
    _accent = _enumById(AppAccent.values, await p.getString(_kAccent),
        AppAccent.periwinkle);
    _textSize = _enumById(AppTextSize.values,
        await p.getString(_kTextSize), AppTextSize.system);
    _motion = _enumById(AppMotionPref.values,
        await p.getString(_kMotion), AppMotionPref.system);
    _haptics = _enumById(AppHapticsPref.values,
        await p.getString(_kHaptics), AppHapticsPref.on);
    _experienceMode = _enumById(ExperienceMode.values,
        await p.getString(_kExperience), ExperienceMode.standard);
  }

  static T _enumById<T extends Enum>(
      List<T> values, String? stored, T fallback) {
    for (final v in values) {
      if (v.name == stored) return v;
    }
    return fallback;
  }

  static String? _sanitizeName(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length > maxDisplayNameLength
        ? trimmed.substring(0, maxDisplayNameLength)
        : trimmed;
  }

  // ── Getters ──────────────────────────────────────────────────────

  /// Whether first-run Welcome Setup (language + optional name) is done.
  bool get setupCompleted => _setupCompleted;

  /// Optional local-only display name — null when unset/empty.
  String? get displayName => _displayName;

  AppLocaleOption get localeOption => _locale;

  /// Resolved Flutter locale — null means follow the OS.
  Locale? get locale => switch (_locale) {
        AppLocaleOption.system => null,
        AppLocaleOption.en => const Locale('en'),
        AppLocaleOption.ar => const Locale('ar'),
        AppLocaleOption.es => const Locale('es'),
        AppLocaleOption.fr => const Locale('fr'),
      };

  AppThemeMode get themeMode => _themeMode;
  AppAccent get accent => _accent;
  AppTextSize get textSize => _textSize;
  AppMotionPref get motion => _motion;
  AppHapticsPref get haptics => _haptics;
  ExperienceMode get experienceMode => _experienceMode;

  /// Guided presentation — larger actions, clearer guidance.
  bool get isGuided => _experienceMode == ExperienceMode.guided;

  /// App-requested reduced motion — OR'd with the OS setting by the
  /// root MediaQuery override, so either source wins.
  bool get wantsReducedMotion => _motion == AppMotionPref.reduced;

  bool get hapticsEnabled => _haptics == AppHapticsPref.on;

  /// Minimum text-scale floor the app adds on top of the OS scale.
  /// `system` contributes nothing — the OS accessibility setting is
  /// always respected and never reduced.
  double get textScaleFloor => switch (_textSize) {
        AppTextSize.system => 1.0,
        AppTextSize.large => 1.18,
        AppTextSize.extraLarge => 1.35,
      };

  // ── Setters (persist + notify) ───────────────────────────────────

  Future<void> completeSetup() async {
    _setupCompleted = true;
    await _prefs?.setBool(_kSetupCompleted, true);
    notifyListeners();
  }

  /// Stores a trimmed display name, or clears it when empty.
  /// Never transmitted — local SharedPreferences only.
  Future<void> setDisplayName(String? raw) async {
    _displayName = _sanitizeName(raw);
    if (_displayName == null) {
      await _prefs?.remove(_kDisplayName);
    } else {
      await _prefs?.setString(_kDisplayName, _displayName!);
    }
    notifyListeners();
  }

  Future<void> setLocale(AppLocaleOption option) async {
    _locale = option;
    await _prefs?.setString(_kLocale, option.name);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setAccent(AppAccent accent) async {
    _accent = accent;
    await _prefs?.setString(_kAccent, accent.name);
    notifyListeners();
  }

  Future<void> setTextSize(AppTextSize size) async {
    _textSize = size;
    await _prefs?.setString(_kTextSize, size.name);
    notifyListeners();
  }

  Future<void> setMotion(AppMotionPref motion) async {
    _motion = motion;
    await _prefs?.setString(_kMotion, motion.name);
    notifyListeners();
  }

  Future<void> setHaptics(AppHapticsPref haptics) async {
    _haptics = haptics;
    await _prefs?.setString(_kHaptics, haptics.name);
    notifyListeners();
  }

  Future<void> setExperienceMode(ExperienceMode mode) async {
    _experienceMode = mode;
    await _prefs?.setString(_kExperience, mode.name);
    notifyListeners();
  }
}

/// Thin async storage seam so the preferences logic is testable
/// without a real SharedPreferences instance.
final class _PrefsStore {
  _PrefsStore(this._prefs);
  final SharedPreferences _prefs;

  Future<bool?> getBool(String k) async => _prefs.getBool(k);
  Future<String?> getString(String k) async => _prefs.getString(k);
  Future<void> setBool(String k, bool v) => _prefs.setBool(k, v);
  Future<void> setString(String k, String v) => _prefs.setString(k, v);
  Future<void> remove(String k) => _prefs.remove(k);
}

/// Guided-Mode lookup — presentation only. Guided Mode enlarges
/// primary actions, adds explicit guidance and keeps technical
/// evidence collapsed by default; it never changes risk behavior.
extension GuidedContext on BuildContext {
  bool get isGuided => AppPreferencesLocator.instance.isGuided;
}

/// Process-wide accessor — matches the codebase's locator style.
final class AppPreferencesLocator {
  AppPreferencesLocator._();

  static AppPreferences? _instance;

  /// Lazily creates an unhydrated instance — `init()` is called by
  /// app bootstrap before runApp; tests inject via [instance] setter.
  static AppPreferences get instance => _instance ??= AppPreferences._(null);

  /// Installs the shared instance — app bootstrap assigns the hydrated
  /// production store; tests assign in-memory instances.
  static set instance(AppPreferences prefs) => _instance = prefs;
}
