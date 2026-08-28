import 'package:freezed_annotation/freezed_annotation.dart';

import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/music_metadata.dart';

part 'playlist.freezed.dart';

/// One persisted playlist, without its tracks (playlists design section 1).
@freezed
abstract class Playlist with _$Playlist {
  /// Creates a playlist.
  const factory Playlist({required String uuid, required String name}) =
      _Playlist;
}

/// One track a playlist holds, at the position the core assigned it
/// (playlists design section 3).
///
/// [uuid] is the *entry's* own identity, never [file]'s: `playlist_entries`
/// deliberately carries no uniqueness constraint on the file it points at, so
/// the same track can appear as two distinct entries and only this uuid tells
/// them apart (playlists design section 2). Every remove and every move
/// addresses this uuid.
@freezed
abstract class PlaylistEntry with _$PlaylistEntry {
  /// Creates an entry.
  const factory PlaylistEntry({
    required String uuid,
    required CatalogFile file,

    /// The track's metadata, as the music area already reads it. `null` when
    /// the core answered no metadata for this file — a row a listener has
    /// not tagged yet, not a parse failure.
    MusicMetadata? metadata,
    required int position,

    /// Whether the file this entry points at is missing on disk.
    ///
    /// The entry stays in the list either way (playlists design section 5):
    /// dropping it here would delete curation work this application was
    /// never asked to discard.
    required bool missing,
  }) = _PlaylistEntry;
}

/// A playlist read back with its tracks, in the order the core sent them
/// (playlists design section 4).
///
/// The order is the core's to keep: this type carries [entries] exactly as
/// read, never re-sorted (BR-02).
@freezed
abstract class PlaylistView with _$PlaylistView {
  /// Creates a view.
  const factory PlaylistView({
    required Playlist playlist,
    required List<PlaylistEntry> entries,
  }) = _PlaylistView;
}

/// Why a playlist name cannot be sent (UC-31 AF-01 equivalent, playlists
/// design).
enum PlaylistNameError {
  /// Blank after trimming.
  empty,
}

/// What is wrong with [name], or `null` when it can be sent.
///
/// Only the check the core would make anyway, made here so an attempt that
/// cannot succeed never becomes one. Everything else about the name — length,
/// stray whitespace, NUL bytes — is the core's verdict alone (BR-02).
PlaylistNameError? validatePlaylistName(String name) =>
    name.trim().isEmpty ? PlaylistNameError.empty : null;
