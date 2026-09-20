/// Rolling transcript accumulator for streaming STT.
///
/// Streaming providers emit partial hypotheses (volatile) and final
/// segments (committed). This buffer keeps committed segments and the
/// latest partial separate, and exposes [analysisContext] — the joined
/// committed text plus the live partial — so scam phrases split across
/// STT chunk boundaries still resolve for the semantic engine.
final class TranscriptBuffer {
  final List<String> _committed = [];
  String _partial = '';

  /// All committed final segments, in arrival order.
  List<String> get committedSegments => List.unmodifiable(_committed);

  /// Latest uncommitted partial hypothesis.
  String get partial => _partial;

  /// Everything the semantic engine should see: committed segments
  /// plus the in-flight partial.
  String get analysisContext =>
      [..._committed, if (_partial.isNotEmpty) _partial].join(' ');

  /// Appends a finalized segment and clears the partial it resolved.
  void commit(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) _committed.add(trimmed);
    _partial = '';
  }

  /// Replaces the live partial hypothesis.
  void updatePartial(String text) => _partial = text.trim();

  /// Clears everything — session reset.
  void reset() {
    _committed.clear();
    _partial = '';
  }
}
