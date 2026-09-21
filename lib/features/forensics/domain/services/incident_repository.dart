import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../protection/domain/models/audio_forensic_metrics.dart';
import '../../../protection/domain/models/composite_threat_report.dart';
import '../../../protection/domain/models/semantic_threat_signals.dart';
import '../../../protection/domain/models/transcript_snippet.dart';
import '../models/incident_report.dart';

/// Contract for the forensic incident store.
abstract interface class IIncidentRepository {
  /// Persist a new incident.
  Future<void> saveIncident(IncidentReport incident);

  /// All recorded incidents, newest first.
  Future<List<IncidentReport>> getAllIncidents();

  /// Lookup by `INC-…` id.
  Future<IncidentReport?> getIncidentById(String id);

  /// Permanently remove one incident by id. Safe/idempotent for ids that
  /// do not exist.
  Future<void> deleteIncident(String id);

  /// Reactive view of the incident list so the history tab updates
  /// live when a call ends.
  ValueListenable<List<IncidentReport>> get incidents;
}

/// In-memory implementation seeded with representative history so the
/// Incidents tab is populated out of the box.
final class InMemoryIncidentRepository implements IIncidentRepository {
  InMemoryIncidentRepository({bool seed = true})
      : _incidents = ValueNotifier<List<IncidentReport>>(
          seed ? _seedData() : const [],
        );

  final ValueNotifier<List<IncidentReport>> _incidents;

  @override
  Future<void> saveIncident(IncidentReport incident) async {
    _incidents.value = [incident, ..._incidents.value];
  }

  @override
  Future<List<IncidentReport>> getAllIncidents() async => _incidents.value;

  @override
  Future<IncidentReport?> getIncidentById(String id) async {
    for (final i in _incidents.value) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<void> deleteIncident(String id) async {
    _incidents.value =
        _incidents.value.where((i) => i.id != id).toList(growable: false);
  }

  @override
  ValueListenable<List<IncidentReport>> get incidents => _incidents;

  static List<IncidentReport> _seedData() {
    final now = DateTime.now();
    return [
      IncidentReport(
        id: 'INC-2026-4417',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 22)),
        callerLabel: 'Unknown Caller (+20 10 ••• ••42)',
        callDurationSeconds: 214,
        audioDigestSha256:
            '9f2ac81b4e6d05f37c2a91d0e84b6f13a5c7d9e2b4f6081a3c5d7e9f0b2a4c6e',
        audioSourceLabel: 'Generated Demo Audio',
        transcriptionSourceLabel: 'Local Demo Transcript',
        peakRiskScore: 0.97,
        riskLevel: ThreatRiskLevel.highRisk,
        threatReasons: const [
          'Financial transfer demand detected',
          'Secrecy & isolation pressure',
          'Identity impersonation claim: "أخوك"',
          'Synthetic voice indicators elevated',
          'Coordinated scam pattern — amplified',
        ],
        acousticMetrics: const AudioForensicMetrics(
          spectralFlux: 0.04,
          spectralRolloffRatio: 0.07,
          zeroCrossingRate: 0.024,
          syntheticVoiceScore: 0.84,
        ),
        semanticSignals: const SemanticThreatSignals(
          urgencyScore: 1.0,
          financialDemandScore: 1.0,
          secrecyScore: 1.0,
          detectedKeywords: ['دلوقتي', 'بسرعة', 'حول', 'جنيه', 'محفظة', 'متقولش لحد'],
          impersonationClaims: ['أنا أخوك', 'أخوك'],
        ),
        transcriptSnippets: [
          TranscriptSnippet(
            speaker: 'Caller',
            text: 'ألو… أنا أخوك، الصوت متغير شوية عشان الخط',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 25)),
          ),
          TranscriptSnippet(
            speaker: 'Caller',
            text: 'حول لي 2,000 جنيه بسرعة على المحفظة',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 24)),
          ),
          TranscriptSnippet(
            speaker: 'Caller',
            text: 'ومتقولش لحد، الموضوع خطير وبيني وبينك',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 23)),
          ),
        ],
        recommendedActions: const [
          'End the call immediately',
          'Do not share OTPs, PINs or banking details',
          'Verify the caller through an official channel',
          'Report the number to your carrier or authorities',
        ],
      ),
      IncidentReport(
        id: 'INC-2026-4389',
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        callerLabel: 'Suspicious Contact (+1 888 ••• 0112)',
        callDurationSeconds: 87,
        audioDigestSha256:
            'b71f4c2d9a0e53f6c8b1d4a7e0f3b6c9d2a5e8f1b4c7d0a3e6f9b2c5d8a1e4f7',
        audioSourceLabel: 'Generated Demo Audio',
        transcriptionSourceLabel: 'Local Demo Transcript',
        peakRiskScore: 0.58,
        riskLevel: ThreatRiskLevel.suspicious,
        threatReasons: const [
          'Urgency manipulation tactics',
          'Secrecy & isolation pressure',
        ],
        acousticMetrics: const AudioForensicMetrics(
          spectralFlux: 0.71,
          spectralRolloffRatio: 0.78,
          zeroCrossingRate: 0.41,
          syntheticVoiceScore: 0.12,
        ),
        semanticSignals: const SemanticThreatSignals(
          urgencyScore: 0.8,
          financialDemandScore: 0.2,
          secrecyScore: 0.5,
          detectedKeywords: ['now', 'urgent', "don't tell"],
          impersonationClaims: [],
        ),
        transcriptSnippets: [
          TranscriptSnippet(
            speaker: 'Caller',
            text: 'This is urgent — act now before the offer expires.',
            timestamp: now.subtract(const Duration(days: 1, hours: 6)),
          ),
          TranscriptSnippet(
            speaker: 'Caller',
            text: "Don't tell anyone until it's confirmed.",
            timestamp: now.subtract(
                const Duration(days: 1, hours: 6) - const Duration(minutes: 1)),
          ),
        ],
        recommendedActions: const [
          'Verify the caller through an official channel',
          'Do not act on time-limited offers under pressure',
        ],
      ),
    ];
  }
}

/// Real local persistence — SharedPreferences-backed JSON. Incidents
/// survive app restart; only report metadata is stored (never audio).
/// Bounded at [maxIncidents], newest-first, deduped/upserted by id,
/// and corrupt rows are skipped on load rather than crashing.
final class PersistedIncidentRepository implements IIncidentRepository {
  PersistedIncidentRepository({
    SharedPreferences? prefs,
    int maxIncidents = 50,
  })  : _prefs = prefs,
        _maxIncidents = maxIncidents {
    _loadFuture = _doLoad();
  }

  static const _key = 'voxguard.incidents_v1';

  final SharedPreferences? _prefs;
  final int _maxIncidents;
  final ValueNotifier<List<IncidentReport>> _incidents =
      ValueNotifier<List<IncidentReport>>(const []);
  late final Future<void> _loadFuture;

  Future<void> _doLoad() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <IncidentReport>[];
      for (final row in decoded) {
        if (loaded.length >= _maxIncidents) break;
        if (row is! Map) continue;
        final report = IncidentReport.fromJson(
          Map<String, dynamic>.from(row),
        );
        if (report == null) continue; // corrupt row — skip safely
        if (loaded.any((i) => i.id == report.id)) continue;
        loaded.add(report);
      }
      _incidents.value = loaded;
    } catch (_) {
      _incidents.value = const []; // unreadable → honest empty history
    }
  }

  @override
  Future<List<IncidentReport>> getAllIncidents() async {
    await _loadFuture;
    return List.unmodifiable(_incidents.value);
  }

  @override
  Future<IncidentReport?> getIncidentById(String id) async {
    for (final i in await getAllIncidents()) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<void> saveIncident(IncidentReport incident) async {
    await _loadFuture;
    // Upsert by id — the same id never produces a duplicate entry.
    final list = _incidents.value.toList()
      ..removeWhere((i) => i.id == incident.id)
      ..insert(0, incident); // newest first
    while (list.length > _maxIncidents) {
      list.removeLast(); // bounded cap
    }
    _incidents.value = List.unmodifiable(list);
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([for (final i in list) i.toJson()]),
      );
    } catch (_) {
      // Persistence failure must not break the in-memory flow.
    }
  }

  @override
  Future<void> deleteIncident(String id) async {
    await _loadFuture;
    final list = _incidents.value.toList()..removeWhere((i) => i.id == id);
    _incidents.value = List.unmodifiable(list);
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([for (final i in list) i.toJson()]),
      );
    } catch (_) {
      // Persistence failure must not break the in-memory flow.
    }
  }

  @override
  ValueListenable<List<IncidentReport>> get incidents => _incidents;
}

/// Process-wide accessor for the incident store.
final class IncidentRepositoryLocator {
  IncidentRepositoryLocator._();

  static IIncidentRepository? _instance;

  /// Production default — real local persistence. A fresh install
  /// honestly shows an empty history (sample fixtures stay behind
  /// `InMemoryIncidentRepository` for demo/tests only).
  static IIncidentRepository get instance =>
      _instance ??= PersistedIncidentRepository();

  @visibleForTesting
  static set instance(IIncidentRepository repo) => _instance = repo;
}
