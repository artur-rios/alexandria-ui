import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/music_stats.dart';
import '../domain/stats_gateway.dart';

/// [StatsGateway] over the core's play history calls (play history design).
class CoreStatsGateway implements StatsGateway {
  /// Wraps [_core].
  const CoreStatsGateway(this._core);

  final CoreClient _core;

  @override
  Future<PlayRecorded> record({
    required String fileUuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.playRecord(
        jsonEncode({'fileUuid': fileUuid}),
        credential,
      );
    } on CoreCallException {
      return const PlayRecorded.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.play,
          code: PLAY_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.play.isOk(response.status)) {
      return PlayRecorded.failed(
        failure: mapCoreStatus(CoreStatusFamily.play, response.status),
      );
    }

    // The core answers the recorded play, and nothing reads it: what was
    // played is what the caller already had, and when is the core's to know.
    return const PlayRecorded.done();
  }

  @override
  Future<MusicStatsRead> read({
    required int limit,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.musicStats(
        jsonEncode({'limit': limit}),
        credential,
      );
    } on CoreCallException {
      return _unreadable();
    }

    if (!CoreStatusFamily.play.isOk(response.status)) {
      return MusicStatsRead.failed(
        failure: mapCoreStatus(CoreStatusFamily.play, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;

      return MusicStatsRead.loaded(
        stats: MusicStats(
          totalPlays: body['totalPlays'] as int,
          distinctTracks: body['distinctTracks'] as int,
          firstPlayedAt: _instant(body['firstPlayedAt']),
          lastPlayedAt: _instant(body['lastPlayedAt']),
          topTracks: [
            for (final row in body['topTracks'] as List<dynamic>)
              _trackFrom(row as Map<String, dynamic>),
          ],
          topArtists: [
            for (final row in body['topArtists'] as List<dynamic>)
              ArtistPlays(
                artist: (row as Map<String, dynamic>)['artist'] as String,
                plays: row['plays'] as int,
                tracks: row['tracks'] as int,
              ),
          ],
          topAlbums: [
            for (final row in body['topAlbums'] as List<dynamic>)
              AlbumPlays(
                album: (row as Map<String, dynamic>)['album'] as String,
                plays: row['plays'] as int,
                artist: row['artist'] as String?,
              ),
          ],
          topGenres: [
            for (final row in body['topGenres'] as List<dynamic>)
              GenrePlays(
                genre: (row as Map<String, dynamic>)['genre'] as String,
                plays: row['plays'] as int,
              ),
          ],
        ),
      );
    } on Object {
      // Broad by intent, as on every payload path in the sibling gateways: a
      // malformed document surfaces as FormatException and a wrongly-typed
      // field as TypeError.
      //
      // The whole read fails rather than dropping the row that could not be
      // parsed, unlike a listing: a ranking with a hole in it is a wrong
      // answer drawn as a confident one, where a listing missing a file is
      // visibly one file short.
      return _unreadable();
    }
  }

  TrackPlays _trackFrom(Map<String, dynamic> row) => TrackPlays(
    fileUuid: row['fileUuid'] as String,
    title: row['title'] as String,
    plays: row['plays'] as int,
    lastPlayedAt: DateTime.parse(row['lastPlayedAt'] as String),
    artist: row['artist'] as String?,
    album: row['album'] as String?,
  );

  /// An instant the core sent, or `null` when it sent none — which is what
  /// both ends of the window are when nothing has been played.
  DateTime? _instant(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  MusicStatsRead _unreadable() => const MusicStatsRead.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.play,
      code: PLAY_ERR_OTHER,
    ),
  );
}
