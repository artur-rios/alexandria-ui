import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/watchlist.dart';
import '../domain/watchlist_gateway.dart';

/// The owner's watchlists and everything they track (UC-29, UC-30 step 2).
class WatchlistsController extends AsyncNotifier<List<Watchlist>> {
  @override
  Future<List<Watchlist>> build() async {
    final browse = await ref.read(watchlistGatewayProvider).browse();

    switch (browse) {
      case WatchlistBrowseLoaded(:final watchlists):
        return watchlists;

      case WatchlistBrowseFailed(:final failure):
        throw failure;
    }
  }

  /// Reads them again (AF-04's refresh).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// What the watchlists screen is reporting, if anything.
enum WatchlistNotice {
  /// Nothing.
  none,

  /// The video is already in that watchlist (UC-29 AF-03).
  alreadyTracked,

  /// The core has no such watchlist or video (AF-04).
  notFound,

  /// The core refused for a reason of its own.
  refused,
}

/// The watchlists screen's own state, beside the list itself (UC-29).
class WatchlistsState {
  /// Creates a state.
  const WatchlistsState({
    this.name = '',
    this.nameError,
    this.isCreating = false,
    this.notice = WatchlistNotice.none,
    this.refusal,
  });

  /// The name being typed into the create field.
  final String name;

  /// What local validation refused (AF-01).
  final WatchlistNameError? nameError;

  /// Whether a create is in flight.
  final bool isCreating;

  /// What the screen is reporting.
  final WatchlistNotice notice;

  /// The core's own reason, when it gave one.
  final Failure? refusal;

  /// A copy with the given changes.
  ///
  /// The mark, the notice, and the refusal are cleared rather than carried
  /// whenever they are not given: each belongs to one attempt.
  WatchlistsState copyWith({
    String? name,
    WatchlistNameError? nameError,
    bool? isCreating,
    WatchlistNotice notice = WatchlistNotice.none,
    Failure? refusal,
  }) => WatchlistsState(
    name: name ?? this.name,
    nameError: nameError,
    isCreating: isCreating ?? this.isCreating,
    notice: notice,
    refusal: refusal,
  );
}

/// Drives UC-29: creating watchlists and choosing what they track.
class WatchlistsForm extends Notifier<WatchlistsState> {
  @override
  WatchlistsState build() => const WatchlistsState();

  /// Records the name being typed, dropping the mark that was on it.
  void editName(String name) => state = state.copyWith(name: name);

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = state.copyWith();

  /// Creates a watchlist (main flow steps 1 and 2).
  Future<void> create() async {
    if (state.isCreating) return;

    // AF-01: marked, and the core is not called.
    final nameError = validateWatchlistName(state.name);
    if (nameError != null) {
      state = state.copyWith(nameError: nameError);
      return;
    }

    state = state.copyWith(isCreating: true);

    await _call(
      (gateway) => gateway.create(name: state.name.trim()),
      onDone: () => state = const WatchlistsState(),
      onFailure: (notice, failure) => state = state.copyWith(
        isCreating: false,
        notice: notice,
        refusal: failure,
      ),
    );
  }

  /// Adds [videoUuid] to [watchlistUuid] (main flow steps 3 and 4).
  ///
  /// AF-03 is answered before the call where the screen already knows the
  /// answer: a video the list is showing as tracked is not sent again.
  Future<void> addVideo({
    required String watchlistUuid,
    required String videoUuid,
  }) async {
    final watchlists = ref.read(watchlistsControllerProvider).value ?? const [];
    final target = watchlists
        .where((watchlist) => watchlist.uuid == watchlistUuid)
        .firstOrNull;

    if (target != null && target.tracks(videoUuid)) {
      state = state.copyWith(notice: WatchlistNotice.alreadyTracked);
      return;
    }

    await _call(
      (gateway) => gateway.addVideo(uuid: watchlistUuid, videoUuid: videoUuid),
    );
  }

  /// Removes it again (main flow step 5).
  Future<void> removeVideo({
    required String watchlistUuid,
    required String videoUuid,
  }) => _call(
    (gateway) => gateway.removeVideo(uuid: watchlistUuid, videoUuid: videoUuid),
  );

  /// Deletes a watchlist (main flow step 6).
  ///
  /// The confirmation is the screen's: it has to say that the videos are
  /// preserved before this is reached.
  Future<void> delete(String watchlistUuid) =>
      _call((gateway) => gateway.delete(uuid: watchlistUuid));

  /// Runs [call] and turns its answer into what the screen shows.
  Future<void> _call(
    Future<WatchlistWrite> Function(WatchlistGateway) call, {
    void Function()? onDone,
    void Function(WatchlistNotice, Failure?)? onFailure,
  }) async {
    final outcome = await call(ref.read(watchlistGatewayProvider));

    switch (outcome) {
      case WatchlistWriteDone():
        // The screen reads the core again rather than being patched here,
        // because the core is what holds the tracking.
        await ref.read(watchlistsControllerProvider.notifier).reload();
        (onDone ?? () => state = state.copyWith())();

      // AF-04: the watchlist or the video is gone, so the screen says so and
      // reads the core again — what it was showing is no longer true.
      case WatchlistWriteFailed(failure: final NotFoundFailure failure):
        await ref.read(watchlistsControllerProvider.notifier).reload();
        (onFailure ??
            (notice, failure) => state = state.copyWith(
              notice: notice,
              refusal: failure,
            ))(WatchlistNotice.notFound, failure);

      case WatchlistWriteFailed(:final failure):
        (onFailure ??
            (notice, failure) => state = state.copyWith(
              notice: notice,
              refusal: failure,
            ))(WatchlistNotice.refused, failure);
    }
  }
}
