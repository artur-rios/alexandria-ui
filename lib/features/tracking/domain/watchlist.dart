import 'package:freezed_annotation/freezed_annotation.dart';

part 'watchlist.freezed.dart';

/// How far through a video the owner is (System Requirements §4.5).
enum WatchState {
  /// Not started.
  pending('pending'),

  /// Part way through.
  watching('watching'),

  /// Finished.
  watched('watched');

  const WatchState(this.wireName);

  /// The string the core uses.
  final String wireName;

  /// The state [wireName] names, or `null` when the core answers one this
  /// application does not know.
  static WatchState? fromWireName(String? wireName) {
    for (final state in WatchState.values) {
      if (state.wireName == wireName) return state;
    }
    return null;
  }
}

/// One video's progress inside one watchlist (System Requirements §4.5).
///
/// Inside one watchlist, deliberately: the same video tracked in two lists has
/// two progresses, and UC-30 AF-05 turns on exactly that.
@freezed
abstract class WatchProgress with _$WatchProgress {
  /// Creates a progress entry.
  const factory WatchProgress({
    required String watchlistUuid,
    required String videoUuid,
    required WatchState state,
    int? currentEpisode,
    int? totalEpisodes,
  }) = _WatchProgress;

  const WatchProgress._();

  /// Whether this entry counts episodes (FR-TR-07).
  bool get countsEpisodes => currentEpisode != null || totalEpisodes != null;
}

/// A watchlist and everything it tracks (FR-TR-01, FR-TR-04).
@freezed
abstract class Watchlist with _$Watchlist {
  /// Creates a watchlist.
  const factory Watchlist({
    required String uuid,
    required String name,
    @Default(<WatchProgress>[]) List<WatchProgress> items,
  }) = _Watchlist;

  const Watchlist._();

  /// The progress this list holds for [videoUuid], if it tracks it.
  WatchProgress? progressFor(String videoUuid) {
    for (final item in items) {
      if (item.videoUuid == videoUuid) return item;
    }
    return null;
  }

  /// Whether this list already tracks [videoUuid] (UC-29 AF-03).
  bool tracks(String videoUuid) => progressFor(videoUuid) != null;
}

/// Why a watchlist name cannot be sent (UC-29 AF-01, FR-TR-01).
enum WatchlistNameError {
  /// Blank after trimming.
  empty,
}

/// What is wrong with [name], or `null` when it can be sent (AF-01).
WatchlistNameError? validateWatchlistName(String name) =>
    name.trim().isEmpty ? WatchlistNameError.empty : null;
