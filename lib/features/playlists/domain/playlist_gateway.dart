import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'playlist.dart';

part 'playlist_gateway.freezed.dart';

/// What browsing the playlists produced (playlists design, "Two tables").
@freezed
sealed class PlaylistBrowse with _$PlaylistBrowse {
  /// The core answered, possibly with nothing.
  const factory PlaylistBrowse.loaded({required List<Playlist> playlists}) =
      PlaylistBrowseLoaded;

  /// The core could not answer.
  const factory PlaylistBrowse.failed({required Failure failure}) =
      PlaylistBrowseFailed;
}

/// What reading one playlist back produced (playlists design section 4).
@freezed
sealed class PlaylistRead with _$PlaylistRead {
  /// The core answered with the playlist and its tracks, in position order.
  const factory PlaylistRead.loaded({required PlaylistView view}) =
      PlaylistReadLoaded;

  /// The core could not answer — including a playlist that does not exist.
  const factory PlaylistRead.failed({required Failure failure}) =
      PlaylistReadFailed;
}

/// What creating, renaming, deleting, or editing a playlist's tracks produced.
@freezed
sealed class PlaylistWrite with _$PlaylistWrite {
  /// The core did it.
  ///
  /// No echoed record: every write is followed by a fresh [PlaylistBrowse] or
  /// [PlaylistRead], which is the only place an order or a count can be
  /// trusted (BR-02).
  const factory PlaylistWrite.done() = PlaylistWriteDone;

  /// The core refused.
  const factory PlaylistWrite.failed({required Failure failure}) =
      PlaylistWriteFailed;
}

/// The core's playlist operations (playlists design).
abstract interface class PlaylistGateway {
  /// Every persisted playlist, without their tracks.
  ///
  /// The read that makes the rest reachable: every other operation addresses
  /// a uuid, and this is where those uuids come from.
  Future<PlaylistBrowse> browse({required String credential});

  /// The playlist [uuid] identifies, with its tracks in position order
  /// (playlists design section 3).
  Future<PlaylistRead> read({required String uuid, required String credential});

  /// Creates a named, empty playlist.
  Future<PlaylistWrite> create({
    required String name,
    required String credential,
  });

  /// Renames the playlist [uuid] identifies (playlists design section 7).
  Future<PlaylistWrite> rename({
    required String uuid,
    required String name,
    required String credential,
  });

  /// Deletes the playlist [uuid] identifies.
  ///
  /// The tracks it held are untouched: what goes is the playlist itself.
  Future<PlaylistWrite> delete({
    required String uuid,
    required String credential,
  });

  /// Appends [fileUuids] to the playlist [uuid] identifies, in the order
  /// given, as new positions after whatever the playlist already holds.
  ///
  /// One call for the whole batch, so adding an album sends one request
  /// rather than one per track.
  Future<PlaylistWrite> addEntries({
    required String uuid,
    required List<String> fileUuids,
    required String credential,
  });

  /// Removes the entry [entryUuid] identifies from the playlist [uuid]
  /// identifies.
  ///
  /// Addressed by the entry's own uuid, never by the file it points at: a
  /// playlist may hold the same track more than once, and only the entry's
  /// uuid tells them apart (playlists design section 2).
  Future<PlaylistWrite> removeEntry({
    required String uuid,
    required String entryUuid,
    required String credential,
  });

  /// Moves the entry [entryUuid] identifies to [toIndex] within the playlist
  /// [uuid] identifies.
  ///
  /// The core computes and renumbers the whole affected span in one
  /// transaction; this sends only the destination, never positions this
  /// application worked out itself (BR-02, playlists design "Risks").
  Future<PlaylistWrite> moveEntry({
    required String uuid,
    required String entryUuid,
    required int toIndex,
    required String credential,
  });
}
