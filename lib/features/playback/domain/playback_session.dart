/// Which player a session belongs to (FR-PL-08).
enum PlaybackMedium {
  /// The video player (UC-19).
  video,

  /// The persistent audio player (UC-20).
  audio,
}

/// One player, of which at most one may be running (FR-PL-08).
///
/// UC-19 AF-05 and UC-20 AF-05 are the same rule read from opposite ends —
/// starting one medium stops the other. Registering both here rather than
/// having each controller reach for the other keeps that rule in one place,
/// and lets UC-19 state it before UC-20's player exists.
abstract interface class PlaybackSession {
  /// Which player this is.
  PlaybackMedium get medium;

  /// Whether it is running or holding a file open.
  bool get isActive;

  /// Stops it, recording whatever it has to record on the way out.
  Future<void> stop();
}
