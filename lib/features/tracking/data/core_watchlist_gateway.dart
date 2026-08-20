import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/watchlist.dart';
import '../domain/watchlist_gateway.dart';

/// [WatchlistGateway] over the core's watchlist calls (UC-29, UC-30).
class CoreWatchlistGateway implements WatchlistGateway {
  /// Wraps [_core].
  const CoreWatchlistGateway(this._core);

  final CoreClient _core;

  @override
  Future<WatchlistBrowse> browse({required String credential}) async {
    final CoreJsonResponse response;
    try {
      // An empty filter is every watchlist, which is what the screen shows.
      response = await _core.watchlistsList('', credential);
    } on CoreCallException {
      return _unreadable();
    }

    if (!CoreStatusFamily.watchlist.isOk(response.status)) {
      return WatchlistBrowse.failed(
        failure: mapCoreStatus(CoreStatusFamily.watchlist, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    try {
      final rows = jsonDecode(json) as List<dynamic>;

      return WatchlistBrowse.loaded(
        watchlists: [
          for (final row in rows) _watchlistFrom(row as Map<String, dynamic>),
        ],
      );
    } on Object {
      return _unreadable();
    }
  }

  @override
  Future<WatchlistWrite> create({
    required String name,
    required String credential,
  }) => _write(
    () => _core.watchlistCreate(jsonEncode({'name': name}), credential),
  );

  @override
  Future<WatchlistWrite> delete({
    required String uuid,
    required String credential,
  }) => _write(() => _core.watchlistDelete(uuid, credential));

  @override
  Future<WatchlistWrite> addVideo({
    required String uuid,
    required String videoUuid,
    required String credential,
  }) => _write(
    () => _core.watchlistAddVideo(
      uuid,
      jsonEncode({'videoUuid': videoUuid}),
      credential,
    ),
  );

  @override
  Future<WatchlistWrite> removeVideo({
    required String uuid,
    required String videoUuid,
    required String credential,
  }) => _write(() => _core.watchlistRemoveVideo(uuid, videoUuid, credential));

  @override
  Future<WatchlistWrite> updateProgress({
    required String uuid,
    required String videoUuid,
    required WatchState state,
    required String credential,
    int? currentEpisode,
    int? totalEpisodes,
  }) => _write(
    () => _core.watchlistUpdateProgress(
      uuid,
      videoUuid,
      jsonEncode({
        'state': state.wireName,
        // Left out rather than sent as null: an absent episode is a movie's
        // progress, and an explicit null would be this application deciding
        // to clear a series' count.
        'currentEpisode': ?currentEpisode,
        'totalEpisodes': ?totalEpisodes,
      }),
      credential,
    ),
  );

  Future<WatchlistWrite> _write(
    Future<CoreJsonResponse> Function() call,
  ) async {
    final CoreJsonResponse response;
    try {
      response = await call();
    } on CoreCallException {
      return const WatchlistWrite.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.watchlist,
          code: WATCHLIST_ERR_OTHER,
        ),
      );
    }

    // Every alternative flow that is not local arrives here and is told apart
    // by the status the mapper reads: a name the core refused, a video it
    // already tracks, a record it does not have, and a rejected session.
    if (!CoreStatusFamily.watchlist.isOk(response.status)) {
      return WatchlistWrite.failed(
        failure: mapCoreStatus(CoreStatusFamily.watchlist, response.status),
      );
    }

    return const WatchlistWrite.done();
  }

  static Watchlist _watchlistFrom(Map<String, dynamic> row) {
    final items = row['items'];

    return Watchlist(
      uuid: row['uuid'] as String,
      name: row['name'] as String,
      items: [
        if (items is List<dynamic>)
          for (final item in items)
            if (item is Map<String, dynamic>) ?_progressFrom(item),
      ],
    );
  }

  /// The progress [row] describes, or `null` when the core answers a state
  /// this application does not know.
  ///
  /// Dropped rather than guessed: a state nobody can name is not one the
  /// interface could offer to change.
  static WatchProgress? _progressFrom(Map<String, dynamic> row) {
    final state = WatchState.fromWireName(row['state'] as String?);
    if (state == null) return null;

    return WatchProgress(
      watchlistUuid: row['watchlistUuid'] as String,
      videoUuid: row['videoUuid'] as String,
      state: state,
      currentEpisode: row['currentEpisode'] as int?,
      totalEpisodes: row['totalEpisodes'] as int?,
    );
  }

  WatchlistBrowse _unreadable() => const WatchlistBrowse.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.watchlist,
      code: WATCHLIST_ERR_OTHER,
    ),
  );
}
