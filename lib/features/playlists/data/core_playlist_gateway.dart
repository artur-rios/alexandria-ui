import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/data/file_view_parser.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/playlist.dart';
import '../domain/playlist_gateway.dart';

/// [PlaylistGateway] over the core's playlist calls (playlists design).
///
/// The reading-list and collection gateways' shape, and deliberately not
/// shared with either: each is its own core family with its own status codes
/// and its own payload shape (IR-08).
class CorePlaylistGateway implements PlaylistGateway {
  /// Wraps [_core].
  const CorePlaylistGateway(this._core);

  final CoreClient _core;

  @override
  Future<PlaylistBrowse> browse({required String credential}) async {
    final CoreJsonResponse response;
    try {
      response = await _core.playlistsList(credential);
    } on CoreCallException {
      return _unreadableBrowse();
    }

    if (!CoreStatusFamily.playlist.isOk(response.status)) {
      return PlaylistBrowse.failed(
        failure: mapCoreStatus(CoreStatusFamily.playlist, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableBrowse();

    try {
      final rows = jsonDecode(json) as List<dynamic>;

      return PlaylistBrowse.loaded(
        playlists: [
          for (final row in rows) _playlistFrom(row as Map<String, dynamic>),
        ],
      );
    } on Object {
      // Broad by intent, as on every payload path in this gateway: a
      // malformed document surfaces as FormatException and a wrongly-typed
      // field as TypeError.
      return _unreadableBrowse();
    }
  }

  @override
  Future<PlaylistRead> read({
    required String uuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.playlistRead(uuid, credential);
    } on CoreCallException {
      return _unreadableRead();
    }

    if (!CoreStatusFamily.playlist.isOk(response.status)) {
      return PlaylistRead.failed(
        failure: mapCoreStatus(CoreStatusFamily.playlist, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableRead();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final playlist = _playlistFrom(body['playlist'] as Map<String, dynamic>);
      final rawEntries = body['entries'];
      if (rawEntries is! List) return _unreadableRead();

      return PlaylistRead.loaded(
        view: PlaylistView(
          playlist: playlist,
          // Rendered exactly in the order the core sent them (BR-02) — never
          // sorted by `position` or by anything else here. The core already
          // answers position order; re-sorting would only hide a core bug
          // that reordered them instead of surfacing it.
          entries: [
            for (final row in rawEntries)
              if (row is Map<String, dynamic>) ?_entryFrom(row),
          ],
        ),
      );
    } on Object {
      return _unreadableRead();
    }
  }

  @override
  Future<PlaylistWrite> create({
    required String name,
    required String credential,
  }) => _write(
    () => _core.playlistCreate(jsonEncode({'name': name}), credential),
  );

  @override
  Future<PlaylistWrite> rename({
    required String uuid,
    required String name,
    required String credential,
  }) => _write(
    () => _core.playlistRename(uuid, jsonEncode({'name': name}), credential),
  );

  @override
  Future<PlaylistWrite> delete({
    required String uuid,
    required String credential,
  }) => _write(() => _core.playlistDelete(uuid, credential));

  @override
  Future<PlaylistWrite> addEntries({
    required String uuid,
    required List<String> fileUuids,
    required String credential,
  }) => _write(
    () => _core.playlistAddEntries(
      uuid,
      jsonEncode({'fileUuids': fileUuids}),
      credential,
    ),
  );

  @override
  Future<PlaylistWrite> removeEntry({
    required String uuid,
    required String entryUuid,
    required String credential,
  }) => _write(() => _core.playlistRemoveEntry(uuid, entryUuid, credential));

  @override
  Future<PlaylistWrite> moveEntry({
    required String uuid,
    required String entryUuid,
    required int toIndex,
    required String credential,
  }) => _write(
    () => _core.playlistMoveEntry(
      uuid,
      entryUuid,
      jsonEncode({'toIndex': toIndex}),
      credential,
    ),
  );

  /// Runs [call] and turns the core's status into a [PlaylistWrite].
  ///
  /// A `DELETE`-shaped call answers `{}` on success — nothing to echo — so
  /// this never reads [CoreJsonResponse.json]; only the status matters.
  Future<PlaylistWrite> _write(Future<CoreJsonResponse> Function() call) async {
    final CoreJsonResponse response;
    try {
      response = await call();
    } on CoreCallException {
      return const PlaylistWrite.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.playlist,
          code: PLAYLIST_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.playlist.isOk(response.status)) {
      return PlaylistWrite.failed(
        failure: mapCoreStatus(CoreStatusFamily.playlist, response.status),
      );
    }

    return const PlaylistWrite.done();
  }

  static Playlist _playlistFrom(Map<String, dynamic> row) =>
      Playlist(uuid: row['uuid'] as String, name: row['name'] as String);

  /// The entry [row] describes, or `null` when its `file` is missing
  /// entirely or names a type this application does not know.
  ///
  /// The file and metadata parse from the same `FileView` shape every other
  /// listing answers (`file_view_parser.dart`), rather than a second parser
  /// written for this one caller.
  ///
  /// Dropping this one row rather than failing the whole [read] mirrors
  /// `fileFromFileView`'s own rule for a plain catalog listing: an
  /// unrecognized type belongs in no listing, and a core that grows a type
  /// must not make every playlist that happens to hold one of its files
  /// unreadable. This is deliberately narrower than [missing] — [missing]
  /// is the core's own verdict on a *known* file that has gone missing on
  /// disk, and that entry is always kept (playlists design section 5); what
  /// is dropped here is a row this application cannot parse as a file at
  /// all, which is a different failure the core has not (yet) named for us.
  static PlaylistEntry? _entryFrom(Map<String, dynamic> row) {
    final fileView = row['file'];
    if (fileView is! Map<String, dynamic>) return null;

    final file = fileFromFileView(fileView['file'] as Map<String, dynamic>);
    if (file == null) return null;

    final metadataMap = metadataFromFileView(fileView['metadata']);

    return PlaylistEntry(
      // The entry's own identity, distinct from `file.uuid`: a playlist may
      // hold the same track twice, and only this uuid tells the rows apart
      // (playlists design section 2).
      uuid: row['entryUuid'] as String,
      file: file,
      metadata: metadataMap.isEmpty
          ? null
          : MusicMetadata.fromDetails(metadataMap),
      position: (row['position'] as num).toInt(),
      missing: row['missing'] as bool? ?? false,
    );
  }

  PlaylistBrowse _unreadableBrowse() => const PlaylistBrowse.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.playlist,
      code: PLAYLIST_ERR_OTHER,
    ),
  );

  PlaylistRead _unreadableRead() => const PlaylistRead.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.playlist,
      code: PLAYLIST_ERR_OTHER,
    ),
  );
}
