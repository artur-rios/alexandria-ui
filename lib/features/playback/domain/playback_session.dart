/// Which player a session belongs to (FR-PL-08).
enum PlaybackMedium {
  /// The video player (UC-19).
  video,
}

/// One player, of which at most one may be running (FR-PL-08).
///
/// UC-19 AF-05 states the rule: starting one medium stops any other.
/// Registering players here rather than having each controller reach for the
/// others keeps that rule in one place, and is also the list sign-out stops.
abstract interface class PlaybackSession {
  /// Which player this is.
  PlaybackMedium get medium;

  /// Whether it is running or holding a file open.
  bool get isActive;

  /// Stops it, recording whatever it has to record on the way out.
  Future<void> stop();
}
