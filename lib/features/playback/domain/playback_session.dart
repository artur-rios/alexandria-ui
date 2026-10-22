/// A player the session can have running, which sign-out stops (UC-03 main
/// flow step 2).
///
/// The video player is the only one. FR-PL-08's one session at a time needs
/// nothing more while that holds: opening a video replaces whatever video was
/// playing. A second player would be registered here too, and opening either
/// would have to stop the other.
abstract interface class PlaybackSession {
  /// Whether it is running or holding a file open.
  bool get isActive;

  /// Stops it, recording whatever it has to record on the way out.
  Future<void> stop();
}
