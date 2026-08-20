/// How long a soft-deleted record stays restorable (UC-34, FR-LC-03).
///
/// The core's own default, and the core is the authority: it enforces the
/// window on every restore and every purge, and a configuration that widens or
/// narrows it there is not published through the FFI surface. This is
/// therefore what the view *counts down*, not what it decides by — a restore
/// the core refuses is still refused, and a purge it will not take yet is
/// still explained by its own answer (UC-35 AF-02).
const Duration retentionWindow = Duration(days: 30);

/// Where a deleted record stands in its retention window (FR-LC-03).
class Retention {
  /// Creates a standing.
  const Retention({required this.remaining});

  /// What [deletedAt] leaves, as of [now].
  ///
  /// A record the core answered without a timestamp has an unknown standing,
  /// which is not the same as an elapsed one: it is still offered for restore,
  /// and the core is what refuses if the window has in fact passed.
  factory Retention.since(DateTime? deletedAt, {required DateTime now}) =>
      Retention(
        remaining: deletedAt == null
            ? null
            : retentionWindow - now.difference(deletedAt),
      );

  /// How long is left, or `null` when it cannot be told.
  final Duration? remaining;

  /// Whether the window has run out (AF-02).
  bool get hasElapsed => remaining != null && remaining! <= Duration.zero;

  /// Whether the countdown can be shown at all.
  bool get isKnown => remaining != null;

  /// Whole days left, rounded up, so a record with an hour to go reads as one
  /// day rather than as none.
  int get daysRemaining {
    final left = remaining;
    if (left == null || left <= Duration.zero) return 0;

    return (left.inMinutes / Duration.minutesPerDay).ceil();
  }
}
