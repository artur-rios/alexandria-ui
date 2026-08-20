import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'watchlist.dart';

part 'watchlist_gateway.freezed.dart';

/// What browsing the watchlists produced (UC-29 main flow, UC-30 step 2).
@freezed
sealed class WatchlistBrowse with _$WatchlistBrowse {
  /// The core answered, possibly with nothing.
  const factory WatchlistBrowse.loaded({required List<Watchlist> watchlists}) =
      WatchlistBrowseLoaded;

  /// The core could not answer.
  const factory WatchlistBrowse.failed({required Failure failure}) =
      WatchlistBrowseFailed;
}

/// What a watchlist write produced (UC-29 steps 2, 4, 5 and 6).
@freezed
sealed class WatchlistWrite with _$WatchlistWrite {
  /// The core did it.
  const factory WatchlistWrite.done() = WatchlistWriteDone;

  /// The core refused (AF-03, AF-04, AF-06).
  const factory WatchlistWrite.failed({required Failure failure}) =
      WatchlistWriteFailed;
}

/// The core's watchlist operations (FR-TR-01 … FR-TR-07).
abstract interface class WatchlistGateway {
  /// Every watchlist and the progress of everything it tracks (FR-TR-04).
  Future<WatchlistBrowse> browse({required String credential});

  /// Creates a watchlist called [name] (FR-TR-01).
  Future<WatchlistWrite> create({
    required String name,
    required String credential,
  });

  /// Deletes the watchlist [uuid] identifies (FR-TR-02).
  ///
  /// The videos are untouched: what goes is the tracking, which is what the
  /// confirmation says before this is called.
  Future<WatchlistWrite> delete({
    required String uuid,
    required String credential,
  });

  /// Adds [videoUuid] to the watchlist [uuid] identifies (FR-TR-03).
  Future<WatchlistWrite> addVideo({
    required String uuid,
    required String videoUuid,
    required String credential,
  });

  /// Removes it again (FR-TR-04).
  Future<WatchlistWrite> removeVideo({
    required String uuid,
    required String videoUuid,
    required String credential,
  });

  /// Records how far through [videoUuid] the owner is, in this watchlist
  /// alone (FR-TR-05 … FR-TR-07, UC-30).
  Future<WatchlistWrite> updateProgress({
    required String uuid,
    required String videoUuid,
    required WatchState state,
    required String credential,
    int? currentEpisode,
    int? totalEpisodes,
  });
}
