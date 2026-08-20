import 'package:alexandria_desktop/features/tracking/domain/watchlist.dart';
import 'package:alexandria_desktop/features/tracking/domain/watchlist_gateway.dart';

/// A [WatchlistGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeWatchlistGateway implements WatchlistGateway {
  /// Creates a gateway holding [watchlists].
  FakeWatchlistGateway({List<Watchlist>? watchlists})
    : watchlists = [...?watchlists];

  /// What a browse answers.
  final List<Watchlist> watchlists;

  /// What [browse] answers instead, when a test says so.
  WatchlistBrowse? browseOutcome;

  /// What the next write answers, in order.
  final List<WatchlistWrite> writeOutcomes = [];

  /// Every name created, in order.
  final List<String> created = [];

  /// Every watchlist deleted, in order.
  final List<String> deleted = [];

  /// Every video added, in order.
  final List<({String watchlist, String video})> added = [];

  /// Every video removed, in order.
  final List<({String watchlist, String video})> removed = [];

  /// Every progress update, in order.
  final List<
    ({
      String watchlist,
      String video,
      WatchState state,
      int? currentEpisode,
      int? totalEpisodes,
    })
  >
  progressUpdates = [];

  @override
  Future<WatchlistBrowse> browse({required String credential}) async =>
      browseOutcome ?? WatchlistBrowse.loaded(watchlists: watchlists);

  @override
  Future<WatchlistWrite> create({
    required String name,
    required String credential,
  }) async {
    created.add(name);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    watchlists.add(Watchlist(uuid: 'created-${watchlists.length}', name: name));
    return const WatchlistWrite.done();
  }

  @override
  Future<WatchlistWrite> delete({
    required String uuid,
    required String credential,
  }) async {
    deleted.add(uuid);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    watchlists.removeWhere((watchlist) => watchlist.uuid == uuid);
    return const WatchlistWrite.done();
  }

  @override
  Future<WatchlistWrite> addVideo({
    required String uuid,
    required String videoUuid,
    required String credential,
  }) async {
    added.add((watchlist: uuid, video: videoUuid));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    _replace(
      uuid,
      (watchlist) => watchlist.copyWith(
        items: [
          ...watchlist.items,
          WatchProgress(
            watchlistUuid: uuid,
            videoUuid: videoUuid,
            state: WatchState.pending,
          ),
        ],
      ),
    );
    return const WatchlistWrite.done();
  }

  @override
  Future<WatchlistWrite> removeVideo({
    required String uuid,
    required String videoUuid,
    required String credential,
  }) async {
    removed.add((watchlist: uuid, video: videoUuid));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    _replace(
      uuid,
      (watchlist) => watchlist.copyWith(
        items: [
          for (final item in watchlist.items)
            if (item.videoUuid != videoUuid) item,
        ],
      ),
    );
    return const WatchlistWrite.done();
  }

  @override
  Future<WatchlistWrite> updateProgress({
    required String uuid,
    required String videoUuid,
    required WatchState state,
    required String credential,
    int? currentEpisode,
    int? totalEpisodes,
  }) async {
    progressUpdates.add((
      watchlist: uuid,
      video: videoUuid,
      state: state,
      currentEpisode: currentEpisode,
      totalEpisodes: totalEpisodes,
    ));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    _replace(
      uuid,
      (watchlist) => watchlist.copyWith(
        items: [
          for (final item in watchlist.items)
            if (item.videoUuid == videoUuid)
              item.copyWith(
                state: state,
                currentEpisode: currentEpisode,
                totalEpisodes: totalEpisodes,
              )
            else
              item,
        ],
      ),
    );
    return const WatchlistWrite.done();
  }

  void _replace(String uuid, Watchlist Function(Watchlist) change) {
    final index = watchlists.indexWhere((watchlist) => watchlist.uuid == uuid);
    if (index >= 0) watchlists[index] = change(watchlists[index]);
  }
}
