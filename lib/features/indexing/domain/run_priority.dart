/// How hard a run should push (FR-FC-31).
///
/// Semantic rather than a thread count: the core maps each to a configured
/// concurrency, and this application has no business inventing a number.
enum RunPriority {
  /// The configured default pace.
  normal,

  /// Deliberately slower, so a large scan competes less with browsing and
  /// playback.
  low;

  /// How the core spells this on both its surfaces.
  String get wire => name;
}
