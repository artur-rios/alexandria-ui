import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';

/// A [PlaylistGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakePlaylistGateway implements PlaylistGateway {
  /// Creates a gateway holding [playlists].
  FakePlaylistGateway({List<Playlist>? playlists})
    : playlists = [...?playlists];

  /// What a browse answers.
  final List<Playlist> playlists;

  /// What [browse] answers instead, when a test says so.
  PlaylistBrowse? browseOutcome;

  /// What [read] answers, by uuid.
  final Map<String, PlaylistRead> reads = {};

  /// Every uuid a read was actually made for, in order.
  ///
  /// [reads] is the stub *input* a test seeds before calling `read`; it says
  /// nothing about whether the gateway was ever asked. This is the record of
  /// what [read] was actually called with, which is what a "the core is
  /// never called" assertion has to check.
  final List<String> readsMade = [];

  /// What the next write answers, in order.
  ///
  /// A list rather than one outcome, so a test can have the core refuse once
  /// and accept the retry.
  final List<PlaylistWrite> writeOutcomes = [];

  /// Every name created, in order.
  final List<String> created = [];

  /// Every rename asked for, in order.
  final List<({String uuid, String name})> renamed = [];

  /// Every playlist deleted, in order.
  final List<String> deleted = [];

  /// Every batch of entries added, in order.
  final List<({String uuid, List<String> fileUuids})> entriesAdded = [];

  /// Every entry removed, in order.
  final List<({String uuid, String entryUuid})> entriesRemoved = [];

  /// Every move asked for, in order.
  final List<({String uuid, String entryUuid, int toIndex})> entriesMoved = [];

  @override
  Future<PlaylistBrowse> browse({required String credential}) async =>
      browseOutcome ?? PlaylistBrowse.loaded(playlists: playlists);

  @override
  Future<PlaylistRead> read({
    required String uuid,
    required String credential,
  }) async {
    readsMade.add(uuid);

    return reads[uuid] ??
        const PlaylistRead.failed(
          failure: Failure.notFound(
            family: CoreStatusFamily.playlist,
            code: PLAYLIST_ERR_NOT_FOUND,
          ),
        );
  }

  @override
  Future<PlaylistWrite> create({
    required String name,
    required String credential,
  }) async {
    created.add(name);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    playlists.add(Playlist(uuid: 'created-${playlists.length}', name: name));
    return const PlaylistWrite.done();
  }

  @override
  Future<PlaylistWrite> rename({
    required String uuid,
    required String name,
    required String credential,
  }) async {
    renamed.add((uuid: uuid, name: name));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    final index = playlists.indexWhere((p) => p.uuid == uuid);
    if (index >= 0) {
      playlists[index] = playlists[index].copyWith(name: name);
    }
    return const PlaylistWrite.done();
  }

  @override
  Future<PlaylistWrite> delete({
    required String uuid,
    required String credential,
  }) async {
    deleted.add(uuid);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    playlists.removeWhere((p) => p.uuid == uuid);
    return const PlaylistWrite.done();
  }

  @override
  Future<PlaylistWrite> addEntries({
    required String uuid,
    required List<String> fileUuids,
    required String credential,
  }) async {
    entriesAdded.add((uuid: uuid, fileUuids: fileUuids));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    return const PlaylistWrite.done();
  }

  @override
  Future<PlaylistWrite> removeEntry({
    required String uuid,
    required String entryUuid,
    required String credential,
  }) async {
    entriesRemoved.add((uuid: uuid, entryUuid: entryUuid));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    return const PlaylistWrite.done();
  }

  @override
  Future<PlaylistWrite> moveEntry({
    required String uuid,
    required String entryUuid,
    required int toIndex,
    required String credential,
  }) async {
    entriesMoved.add((uuid: uuid, entryUuid: entryUuid, toIndex: toIndex));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    return const PlaylistWrite.done();
  }
}
