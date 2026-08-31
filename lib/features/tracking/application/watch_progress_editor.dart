import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/counted_progress.dart';
import '../domain/watchlist.dart';
import '../domain/watchlist_gateway.dart';

/// The progress being edited, and which item it belongs to (UC-30).
class WatchProgressEditorState {
  /// Creates a state.
  const WatchProgressEditorState({
    this.watchlistUuid,
    this.videoUuid,
    this.state = WatchState.pending,
    this.episodes = const CountedProgressDraft(),
    this.currentError,
    this.totalError,
    this.rejection,
    this.isSaving = false,
  });

  /// The watchlist the progress belongs to, or `null` when nothing is open.
  ///
  /// The watchlist and not only the video: the same film in two lists has two
  /// progresses, and setting one leaves the other alone (AF-05).
  final String? watchlistUuid;

  /// The video.
  final String? videoUuid;

  /// The state the owner has chosen.
  final WatchState state;

  /// What they have typed into the episode fields.
  final CountedProgressDraft episodes;

  /// What local validation refused (AF-02).
  final CountedProgressError? currentError;

  /// And for the total.
  final CountedProgressError? totalError;

  /// What the core refused (AF-03, AF-04).
  final Failure? rejection;

  /// Whether the update is in flight.
  final bool isSaving;

  /// Whether an item is open for editing.
  bool get isOpen => watchlistUuid != null && videoUuid != null;

  /// Whether [progress] is the entry being edited.
  bool isEditing(WatchProgress progress) =>
      progress.watchlistUuid == watchlistUuid &&
      progress.videoUuid == videoUuid;

  /// A copy with the given changes.
  ///
  /// The marks and the rejection are cleared rather than carried whenever they
  /// are not given: each belongs to one attempt.
  WatchProgressEditorState copyWith({
    String? watchlistUuid,
    String? videoUuid,
    WatchState? state,
    CountedProgressDraft? episodes,
    CountedProgressError? currentError,
    CountedProgressError? totalError,
    Failure? rejection,
    bool? isSaving,
  }) => WatchProgressEditorState(
    watchlistUuid: watchlistUuid ?? this.watchlistUuid,
    videoUuid: videoUuid ?? this.videoUuid,
    state: state ?? this.state,
    episodes: episodes ?? this.episodes,
    currentError: currentError,
    totalError: totalError,
    rejection: rejection,
    isSaving: isSaving ?? this.isSaving,
  );
}

/// Drives UC-30: recording how far through something the owner is.
class WatchProgressEditor extends Notifier<WatchProgressEditorState> {
  @override
  WatchProgressEditorState build() => const WatchProgressEditorState();

  /// Opens [progress] for editing (main flow step 3).
  void open(WatchProgress progress) => state = WatchProgressEditorState(
    watchlistUuid: progress.watchlistUuid,
    videoUuid: progress.videoUuid,
    state: progress.state,
    episodes: CountedProgressDraft(
      current: progress.currentEpisode?.toString() ?? '',
      total: progress.totalEpisodes?.toString() ?? '',
    ),
  );

  /// Closes it, changing nothing.
  void close() => state = const WatchProgressEditorState();

  /// Chooses a watch state (main flow step 3, FR-TR-06).
  void chooseState(WatchState watchState) =>
      state = state.copyWith(state: watchState);

  /// Records the episode the owner is on (step 4).
  void editCurrentEpisode(String current) => state = state.copyWith(
    episodes: state.episodes.copyWith(current: current),
    totalError: state.totalError,
  );

  /// Records the total (step 4).
  void editTotalEpisodes(String total) => state = state.copyWith(
    episodes: state.episodes.copyWith(total: total),
    currentError: state.currentError,
  );

  /// Sends the update (main flow steps 5 and 6).
  ///
  /// [countsEpisodes] is whether this item is a series. A movie's episode
  /// fields are never shown (AF-01), so they are never sent either — an
  /// episode number on something nobody marked a series would be this
  /// application inventing the marking.
  Future<void> submit({required bool countsEpisodes}) async {
    if (state.isSaving || !state.isOpen) return;

    // AF-02: marked, and the core is not called.
    if (countsEpisodes) {
      final currentError = validateCurrentCount(state.episodes);
      final totalError = validateTotalCount(state.episodes);
      if (currentError != null || totalError != null) {
        state = state.copyWith(
          currentError: currentError,
          totalError: totalError,
        );
        return;
      }
    }

    state = state.copyWith(isSaving: true);

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) {
      state = state.copyWith(isSaving: false);
      return;
    }

    final outcome = await ref
        .read(watchlistGatewayProvider)
        .updateProgress(
          uuid: state.watchlistUuid!,
          videoUuid: state.videoUuid!,
          state: state.state,
          credential: credential,
          currentEpisode: countsEpisodes ? state.episodes.currentValue : null,
          totalEpisodes: countsEpisodes ? state.episodes.totalValue : null,
        );

    switch (outcome) {
      case WatchlistWriteDone():
        // Step 6: what the screen shows comes from the core, so it is read
        // again rather than patched here.
        await ref.read(watchlistsControllerProvider.notifier).reload();
        state = const WatchProgressEditorState();

      // AF-06: the session is discarded, which returns the owner to login.
      case WatchlistWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        state = const WatchProgressEditorState();

      // AF-04: the watchlist or the item is gone. The screen is read again,
      // and the editor closes over what is no longer there.
      case WatchlistWriteFailed(failure: final NotFoundFailure failure):
        await ref.read(watchlistsControllerProvider.notifier).reload();
        state = state.copyWith(isSaving: false, rejection: failure);

      // AF-03: the core refused the state. The stored progress is unchanged,
      // which is why nothing is reloaded — the screen is already showing what
      // the core holds.
      case WatchlistWriteFailed(:final failure):
        state = state.copyWith(isSaving: false, rejection: failure);
    }
  }
}
