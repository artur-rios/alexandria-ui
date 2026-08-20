/// Something with a file open (UC-33 AF-04).
///
/// A player that is playing it, a viewer showing it, an editor holding it. The
/// confirmation warns about whichever of these has the file, and letting them
/// go is what the owner confirms — the same registry shape the one-player-at-a
/// -time rule uses, and for the same reason: neither the deletion nor the
/// player has to know the other exists.
abstract interface class FileHold {
  /// Whether this has the file [uuid] identifies open.
  bool holds(String uuid);

  /// Lets it go: stops the playback, closes the viewer or the editor.
  Future<void> release();
}
