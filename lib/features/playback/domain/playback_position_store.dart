/// Where playback stopped in one file (System Requirements §4.10).
class PlaybackPosition {
  /// Creates a position.
  const PlaybackPosition({
    required this.fileUuid,
    required this.position,
    this.duration,
    required this.updatedAt,
  });

  /// The file this resume point belongs to.
  final String fileUuid;

  /// Where playback stopped.
  final Duration position;

  /// How long the file is, when the engine reported it.
  final Duration? duration;

  /// When it was last written.
  final DateTime updatedAt;
}

/// The resume positions, which are the application's rather than the core's
/// (FR-PL-09, System Requirements §4.10).
///
/// The core publishes no playback state, and BR-06 lets this application write
/// its own settings — so a resume point lives beside the theme and the
/// registered folders rather than in the catalog.
abstract interface class PlaybackPositionStore {
  /// The resume position for [fileUuid], or `null` when there is none.
  PlaybackPosition? positionFor(String fileUuid);

  /// Records where playback stopped.
  Future<void> record(PlaybackPosition position);

  /// Forgets [fileUuid]'s resume point.
  ///
  /// What starting over does, and what reaching the end of a file does: a
  /// finished file has no position left to resume from.
  Future<void> forget(String fileUuid);
}
